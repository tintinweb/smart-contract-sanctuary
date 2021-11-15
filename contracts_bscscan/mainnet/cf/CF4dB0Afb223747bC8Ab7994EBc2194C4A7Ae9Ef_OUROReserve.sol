// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./library.sol";

/**
 * @title OURO community reserve
 */
contract OUROReserve is IOUROReserve,Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using Address for address payable;
    using SafeMath for uint256;
    using SafeERC20 for IOUROToken;
    using SafeERC20 for IOGSToken;
    
    /** 
     * ======================================================================================
     * 
     * SHARED SETTINGS
     * 
     * ======================================================================================
     */

    // @dev ouro price 
    uint256 public ouroPrice = 1e18; // current ouro price, initially 1 OURO = 1 USDT
    uint256 public ouroPriceAtMonthStart = 1e18; // ouro price at the begining of a month, initially set to 1 USDT
    uint256 public constant OURO_PRICE_UNIT = 1e18; // 1 OURO = 1e18
    uint public ouroLastPriceUpdate = block.timestamp; 
    uint public ouroPriceResetPeriod = 30 days; // price limit reset mothly
    uint public ouroIssuePeriod = 30 days; // ouro issuance limit
    uint public appreciationLimit = 3; // 3 perce nt monthly OURO price appreciation limit

    // contracts
    address public constant usdtContract = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    IOUROToken public constant ouroContract = IOUROToken(0x11750386b3795ADDbF58BbD9f7412b203A97e55d);
    IOGSToken public constant ogsContract = IOGSToken(0xD7FF3EEaFB6A6Efd262f431D9090F2b2ae85d31C);
    IOURODist public ouroDistContact = IOURODist(0x7090D60c19F19b6B00C421619c07BeF3c0A0837e);
    address public constant unitroller = 0xfD36E2c2a6789Db23113685031d7F16329158384;
    address public constant xvsAddress = 0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63;
    IPancakeRouter02 public constant router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public lastResortFund;
    
    address immutable internal WETH = router.WETH();
    uint256 constant internal USDT_UNIT = 1e18;
    uint256 constant internal MAX_UINT256 = uint256(-1);
    
    // @dev montly OURO issuance schedule in 100k(1e5) OURO
    uint16 [] public issueSchedule = [1,10,30,50,70,100,150,200,300,400,500,650,800];
    uint256 internal constant issueUnit = 1e5 * OURO_PRICE_UNIT;
    
    // @dev scheduled issue from
    uint256 public immutable issueFrom = block.timestamp;
    
    // a struct to storge collateral asset info
    struct CollateralInfo {
        address token;
        address vTokenAddress;
        uint256 assetUnit; // usually 1e18
        uint256 lastPrice; // record latest collateral price
        AggregatorV3Interface priceFeed; // asset price feed for xxx/USDT
    }
    
    // all registered collaterals for OURO
    CollateralInfo [] private collaterals;
    
    // a mapping to track the balance of assets;
    mapping (address => uint256) private _assetsBalance;
    
    // whitelist for deposit assets 
    bool public whiteListEnabled;
    mapping (address => bool) private _whitelist;
    
    /**
     * ======================================================================================
     * 
     * VIEW FUNCTIONS
     * 
     * ======================================================================================
     */
     
    /**
     * @dev get specific collateral balance
     */
    function getAssetBalance(address token) external view returns(uint256) { return _assetsBalance[token]; }
    
    /**
     * @dev get specific collateral info
     */
    function getCollateral(address token) external view returns (
        address vTokenAddress,
        uint256 assetUnit, // usually 1e18
        uint256 lastPrice, // record latest collateral price
        AggregatorV3Interface priceFeed // asset price feed for xxx/USDT
    ) {
        (CollateralInfo memory collateral, bool valid) = _findCollateral(token);
        if (valid) {
            return (
                collateral.vTokenAddress,
                collateral.assetUnit,
                collateral.lastPrice,
                collateral.priceFeed
            );
        }
    }
            
    /** 
     * @dev get system defined OURO price
     */
    function getPrice() public view override returns(uint256) { return ouroPrice; }
    
    /**
     * @dev get asset price in USDT(decimal=8) for 1 unit of asset
     */
    function getAssetPrice(AggregatorV3Interface feed) public view returns(uint256) {
        // query price from chainlink
        (, int latestPrice, , , ) = feed.latestRoundData();

        // avert negative price
        require (latestPrice > 0, "invalid price");
        
        // return price corrected to USDT decimal
        // always align the price to USDT decimal, which is 1e18 on BSC and 1e6 on Ethereum
        return uint256(latestPrice)
                        .mul(USDT_UNIT)
                        .div(10**uint256(feed.decimals()));
    }
    
     /**
     * ======================================================================================
     * 
     * SYSTEM FUNCTIONS
     * 
     * ======================================================================================
     */
     
    receive() external payable {}

    // check whitelist
    modifier checkWhiteList() {
        if (whiteListEnabled) {
            require(_whitelist[msg.sender],"not in whitelist");
        }
        _;
    }
    
    constructor() public {
        lastResortFund = msg.sender;
        // approve xvs to router
        IERC20(xvsAddress).safeApprove(address(router), MAX_UINT256);
        // approve ogs to router
        IERC20(ogsContract).safeApprove(address(router), MAX_UINT256);
        // approve ouro to router
        IERC20(ouroContract).safeApprove(address(router), MAX_UINT256);
    }
    
    /**
     * @dev set fund of last resort address
     */
    function setLastResortFund(address account) external onlyOwner {
        lastResortFund = account;
        emit LastResortFundSet(account);
    }
    
    /**
     * @dev owner add new collateral
     */
    function newCollateral(
        address token, 
        address vTokenAddress,
        uint8 assetDecimal,
        AggregatorV3Interface priceFeed
        ) external onlyOwner
    {
        (, bool exist) = _findCollateral(token);
        require(!exist, "exist");
        
        uint256 currentPrice = getAssetPrice(priceFeed);
        
        // create collateral info 
        CollateralInfo memory info;
        info.token = token;
        info.vTokenAddress = vTokenAddress;
        info.assetUnit = 10 ** uint256(assetDecimal);
        info.lastPrice = currentPrice;
        info.priceFeed = priceFeed;

        collaterals.push(info);
        
        // approve ERC20 collateral to swap router & vToken
        if (address(token) != WETH) {
            IERC20(token).safeApprove(address(router), 0);
            IERC20(token).safeIncreaseAllowance(address(router), MAX_UINT256);
            
            IERC20(token).safeApprove(vTokenAddress, 0);
            IERC20(token).safeIncreaseAllowance(vTokenAddress, MAX_UINT256);
        }
        
        // enter markets
        address[] memory venusMarkets = new address[](1);
        venusMarkets[0] = vTokenAddress;
        IVenusDistribution(unitroller).enterMarkets(venusMarkets);

        // log
        emit NewCollateral(token);
    }
    
    /**
     * @dev owner remove collateral
     */
    function removeCollateral(address token) external onlyOwner {
        uint n = collaterals.length;
        for (uint i=0;i<n;i++) {
            if (collaterals[i].token == token){
                
                // found! revoke router & vToken allowance to 0
                if (address(token) != WETH) {
                    IERC20(token).safeApprove(address(router), 0);
                    IERC20(token).safeApprove(collaterals[i].vTokenAddress, 0);
                }
                
                // exit venus markets
                IVenusDistribution(unitroller).exitMarket(collaterals[i].vTokenAddress);
                
                // copy the last element [n-1] to [i],
                collaterals[i] = collaterals[n-1];
                // and pop out the last element
                collaterals.pop();
                
                // log
                emit RemoveCollateral(token);
                
                return;
            }
        } 
        
        revert("nonexistent");
    }
    
    /**
     * @dev owner reset allowance to maximum
     * to avert uint256 exhausting
     */
    function resetAllowances() external onlyOwner {
        uint n = collaterals.length;
        for (uint i=0;i<n;i++) {
            IERC20 token = IERC20(collaterals[i].token);
            if (address(token) != WETH) {
                // re-approve asset to venus
                token.safeApprove(address(router), 0);
                token.safeIncreaseAllowance(address(router), MAX_UINT256);
                
                token.safeApprove(collaterals[i].vTokenAddress, 0);
                token.safeIncreaseAllowance(collaterals[i].vTokenAddress, MAX_UINT256);
            }
        }
        
        // re-approve xvs to router
        IERC20(xvsAddress).safeApprove(address(router), 0);
        IERC20(xvsAddress).safeIncreaseAllowance(address(router), MAX_UINT256);
        
        // re-approve ogs to router
        IERC20(ogsContract).safeApprove(address(router), 0);
        IERC20(ogsContract).safeIncreaseAllowance(address(router), MAX_UINT256);
        
        // re-approve ouro to router
        IERC20(ouroContract).safeApprove(address(router), 0);
        IERC20(ouroContract).safeIncreaseAllowance(address(router), MAX_UINT256);
        
        // log
        emit AllowanceReset();
    }
         
     /**
      * @dev change ouro revenue distribution contract address
      * in case of severe bug
      */
     function changeOURODist(address newContract) external onlyOwner {
         ouroDistContact = IOURODist(newContract);
     }
    
    /**
     * @dev toggle deposit whitelist enabled
     */
    function toggleWhiteList() external onlyOwner {
        whiteListEnabled = whiteListEnabled?false:true;
    }
    
    /**
     * @dev set to whiteist
     */
    function setToWhiteList(address account, bool allow) external onlyOwner {
        _whitelist[account] = allow;
    }
    
    /**
     * ======================================================================================
     * 
     * OURO's collateral deposit & withdraw
     *
     * ======================================================================================
     */

    /**
     * @dev user deposit assets and receive OURO
     * @notice users need approve() assets to this contract
     * returns OURO minted
     */
    function deposit(address token, uint256 amountAsset) external override payable checkWhiteList returns (uint256 OUROMinted) {
        
        // locate collateral
        (CollateralInfo memory collateral, bool valid) = _findCollateral(token);
        require(valid, "invalid collateral");

        // for native token, replace amountAsset with use msg.value instead
        if (token == WETH) {
            amountAsset = msg.value;
        }
        
        // non-0 deposit check
        require(amountAsset > 0, "0 deposit");

        // get equivalent OURO value
        uint256 assetValueInOuro = _lookupAssetValueInOURO(collateral.priceFeed, collateral.assetUnit, amountAsset);
        
        // check periodical OURO issuance limit
        uint periodN = block.timestamp.sub(issueFrom).div(ouroIssuePeriod);
        if (periodN < issueSchedule.length) { // still in control
            require(assetValueInOuro + IERC20(ouroContract).totalSupply() 
                        <=
                    uint256(issueSchedule[periodN]).mul(issueUnit),
                    "limited"
            );
        }
        
        // transfer token assets to this contract
        // @notice for ERC20 assets, users need to approve() to this reserve contract 
        if (token != WETH) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amountAsset);
        }
                                        
        // mint OURO to sender
        IOUROToken(ouroContract).mint(msg.sender, assetValueInOuro);
        
        // update asset balance
        _assetsBalance[address(token)] += amountAsset;

        // finally we farm the assets received
        _supply(collateral.token, collateral.vTokenAddress, amountAsset);
        
        // log
        emit Deposit(msg.sender, assetValueInOuro);
        
        // returns OURO minted to user
        return assetValueInOuro;
    }
    
    /**
     * @dev farm the user's deposit
     */
    function _supply(address token, address vTokenAddress, uint256 amountAsset) internal {
        if (token == WETH) {
            IVBNB(vTokenAddress).mint{value: amountAsset}();
        } else {
            IVToken(vTokenAddress).mint(amountAsset);
        }
    }
    
    /**
     * @dev user swap his OURO back to assets
     * @notice users need approve() OURO assets to this contract
     */
    function withdraw(address token, uint256 amountAsset) external override returns (uint256 OUROTaken) {
        
        // locate collateral
        (CollateralInfo memory collateral, bool valid) = _findCollateral(token);
        require(valid, "not a collateral");
                                                    
        // check if we have sufficient assets to return to user
        uint256 assetBalance = _assetsBalance[address(token)];

        // perform OURO token burn
        if (assetBalance >= amountAsset) {
            // substract asset balance
            _assetsBalance[address(token)] -= amountAsset;
            
            // redeem assets
            _redeemSupply(collateral.token, collateral.vTokenAddress, amountAsset);
                    
            // sufficient asset satisfied! transfer user's equivalent OURO token to this contract directly
            uint256 assetValueInOuro = _lookupAssetValueInOURO(collateral.priceFeed, collateral.assetUnit, amountAsset);
            IERC20(ouroContract).safeTransferFrom(msg.sender, address(this), assetValueInOuro);
            OUROTaken = assetValueInOuro;
            
            // and burn OURO.
            IOUROToken(ouroContract).burn(assetValueInOuro);

        } else {
            // drain asset balance
            _assetsBalance[address(token)] = 0;
            
            // insufficient assets, redeem ALL
            _redeemSupply(collateral.token, collateral.vTokenAddress, assetBalance);

            // redeemed assets value in OURO
            uint256 redeemedAssetValueInOURO = _lookupAssetValueInOURO(collateral.priceFeed, collateral.assetUnit, assetBalance);
            
            // as we don't have enough assets to return to user
            // we buy extra assets from swaps with user's OURO
            uint256 extraAssets = amountAsset.sub(assetBalance);
    
            // find how many extra OUROs required to swap the extra assets out
            // path:
            //  (??? ouro) -> USDT -> collateral
            address[] memory path;
            if (token == usdtContract) {
                path = new address[](2);
                path[0] = address(ouroContract);
                path[1] = token;
            } else {
                path = new address[](3);
                path[0] = address(ouroContract);
                path[1] = usdtContract; // use USDT to bridge
                path[2] = token;
            }

            uint [] memory amounts = router.getAmountsIn(extraAssets, path);
            uint256 extraOuroRequired = amounts[0];
            
            // @notice user needs sufficient OURO to swap assets out
            // transfer total OURO to this contract, if user has insufficient OURO, the transaction will revert!
            uint256 totalOuroRequired = extraOuroRequired.add(redeemedAssetValueInOURO);
            ouroContract.safeTransferFrom(msg.sender, address(this), totalOuroRequired);
            OUROTaken = totalOuroRequired;
                 
            // a) OURO to burn (the swapped part has given out)
            IOUROToken(ouroContract).burn(redeemedAssetValueInOURO);
            
            // b) OURO to buy back assets
            // path:
            //  ouro-> (USDT) -> collateral
            if (token == WETH) {
                amounts = router.swapExactTokensForETH (
                    extraOuroRequired, 
                    0, 
                    path, 
                    address(this), 
                    block.timestamp.add(600)
                );
            } else {
                // swap out tokens out to OURO contract
                amounts = router.swapExactTokensForTokens(
                    extraOuroRequired, 
                    0, 
                    path, 
                    address(this), 
                    block.timestamp.add(600)
                );
            }
        }
        
        // finally we transfer the assets based on asset type back to user
        if (token == WETH) {
            uint256 value = address(this).balance < amountAsset? address(this).balance:amountAsset;
            msg.sender.sendValue(value);
        } else {
            uint256 value = IERC20(token).balanceOf(address(this)) < amountAsset? IERC20(token).balanceOf(address(this)):amountAsset;
            IERC20(token).safeTransfer(msg.sender, value);
        }
        
        // log withdraw
        emit Withdraw(msg.sender, address(token), amountAsset);
        
        // return OURO taken from user
        return OUROTaken;
    }
    
    /**
     * @dev redeem assets from farm
     */
    function _redeemSupply(address token, address vTokenAddress, uint256 amountAsset) internal {
        if (token == WETH) {
            IVBNB(vTokenAddress).redeemUnderlying(amountAsset);
        } else {
            IVToken(vTokenAddress).redeemUnderlying(amountAsset);
        }
    }

    /**
     * @dev find the given collateral info
     */
    function _findCollateral(address token) internal view returns (CollateralInfo memory, bool) {
        uint n = collaterals.length;
        for (uint i=0;i<n;i++) {
            if (collaterals[i].token == token){
                return (collaterals[i], true);
            }
        }
    }
    
    /**
     * @dev find the given asset value priced in OURO
     */
    function _lookupAssetValueInOURO(AggregatorV3Interface priceFeed, uint256 assetUnit, uint256 amountAsset) internal view returns (uint256 amountOURO) {
        // get lastest asset value in USDT
        uint256 assetUnitPrice = getAssetPrice(priceFeed);
        
        // compute total USDT value
        uint256 assetValueInUSDT = amountAsset
                                                    .mul(assetUnitPrice)
                                                    .div(assetUnit);
                                                    
        // convert asset USDT value to OURO value
        uint256 assetValueInOuro = assetValueInUSDT.mul(OURO_PRICE_UNIT)
                                                    .div(ouroPrice);
                                                    
        return assetValueInOuro;
    }

    /**
     * ======================================================================================
     * 
     * OURO's stablizer
     *
     * ======================================================================================
     */
     
    // 1. The system will only mint new OGS and sell them for collateral when the value of the 
    //    assets held in the pool is more than 3% less than the value of the issued OURO.
    // 2. The system will only use excess collateral in the pool to conduct OGS buy back and 
    //    burn when the value of the assets held in the pool is 3% higher than the value of the issued OURO
    uint public rebalanceThreshold = 3;
    uint public OGSbuyBackRatio = 70; // 70% to buy back OGS

    // record last Rebase time
    uint public lastRebaseTimestamp = block.timestamp;
    
    // rebase period
    uint public rebasePeriod = 1 days;

    // multiplier
    uint internal constant MULTIPLIER = 1e12;
    
    /**
     * @dev rebase entry
     * public method for all external caller
     */
    function rebase() public {
         // rebase period check
        require(block.timestamp > lastRebaseTimestamp + rebasePeriod, "aggressive rebase");
        
        // rebase collaterals
        _rebase();
                
        // update rebase time
        lastRebaseTimestamp = block.timestamp;
        
        // book keeping after rebase
        if (block.timestamp > ouroLastPriceUpdate + ouroPriceResetPeriod) {
            // record price at month begins
            ouroPriceAtMonthStart = ouroPrice;
            ouroLastPriceUpdate = block.timestamp;
        }

        // log
        emit Rebased(msg.sender);
    }
 
    /**
     * @dev rebase is the stability dynamics for OURO
     */
    function _rebase() internal {
        // get total collateral value priced in USDT
        uint256 totalCollateralValue = _getTotalCollateralValue();
        // get total issued OURO value priced in USDT
        uint256 totalIssuedOUROValue =              ouroContract.totalSupply()
                                                    .mul(getPrice())
                                                    .div(OURO_PRICE_UNIT);
        
        // compute values deviates
        if (totalCollateralValue >= totalIssuedOUROValue.mul(100+rebalanceThreshold).div(100)) {
            _handleExceesiveValue(totalCollateralValue, totalIssuedOUROValue);
          
        } else if (totalCollateralValue <= totalIssuedOUROValue.mul(100-rebalanceThreshold).div(100)) {
            // collaterals has less value to OURO value, mint new OGS to buy assets
            uint256 valueDeviates = totalIssuedOUROValue.sub(totalCollateralValue);
            
            // rebalance the collaterals
            _executeRebalance(false, valueDeviates);
        }
    }
    
    /**
     * @dev function to handle excessive value
     */
    function _handleExceesiveValue(uint256 totalCollateralValue, uint256 totalIssuedOUROValue) internal {
        // collaterals has excessive value to OURO value, 
        // 70% of the extra collateral would be used to BUY BACK OGS on secondary markets 
        // and conduct a token burn
        uint256 excessiveValue = totalCollateralValue.sub(totalIssuedOUROValue);
                                                    
        // check if price has already reached monthly limit 
        uint256 priceUpperLimit =               ouroPriceAtMonthStart
                                                .mul(100+appreciationLimit)
                                                .div(100);
                                        
        // conduct an ouro default price change                                
        if (ouroPrice < priceUpperLimit) {
            // However, since there is a 3% limit on how much the OURO Default Exchange Price can increase per month, 
            // only [100,000,000*0.03 = 3,000,000] USDT worth of excess assets can be utilized. This 3,000,000 USDT worth of 
            // assets will remain in the Reserve Pool, while the remaining [50,000,000-3,000,000=47,000,000] USDT worth 
            // of assets will be used for OGS buyback and burns. 
            
            // (limit - current ouro price) / current ouro price
            // eg : (1.03 - 1.01) / 1.01 = 0.0198
            uint256 ouroRisingSpace =           priceUpperLimit.sub(ouroPrice)  // non-negative substraction
                                                .mul(MULTIPLIER)
                                                .div(ouroPrice);

            // a) maxiumum values required to raise price to limit; (totalIssuedOUROValue * 0.0198)
            uint256 ouroApprecationValueLimit = ouroRisingSpace
                                                .mul(totalIssuedOUROValue)
                                                .div(MULTIPLIER);
            
            // b) maximum excessive value usable (30%)
            uint256 maximumUsableValue =        excessiveValue
                                                .mul(100-OGSbuyBackRatio)
                                                .div(100);
            
            // use the smaller one from a) & b) to appreciate OURO
            uint256 valueToAppreciate = ouroApprecationValueLimit < maximumUsableValue?ouroApprecationValueLimit:maximumUsableValue;
            
            // IMPORTANT: value appreciation:
            // ouroPrice = ouroPrice * (totalOUROValue + appreciateValue) / totalOUROValue
            ouroPrice =                         ouroPrice
                                                .mul(totalIssuedOUROValue.add(valueToAppreciate))
                                                .div(totalIssuedOUROValue);
            // log
            emit Appreciation(ouroPrice);
            
            // substract excessive value which has used to appreciate OURO price
            excessiveValue = excessiveValue.sub(valueToAppreciate);
        }
        
        // after price appreciation, if we still have excessive value
        // 1. to form an insurance fund (10%)
        // 2. conduct a ogs burn(90%)
        if (excessiveValue > 0) {
            // rebalance the collaterals
            _executeRebalance(true, excessiveValue);
        }
    }
    
    /**
     * @dev value deviates, execute buy back operations
     * valueDeviates is priced in USDT
     */
    function _executeRebalance(bool isExcessive, uint256 valueDeviates) internal {
        // step 1. sum total deviated collateral value 
        uint256 totalCollateralValueDeviated;
        for (uint i=0;i<collaterals.length;i++) {
            CollateralInfo storage collateral = collaterals[i];
            
            // check new price of the assets & omit those not deviated
            uint256 newPrice = getAssetPrice(collateral.priceFeed);
            if (isExcessive) {
                // omit assets deviated negatively
                if (newPrice < collateral.lastPrice) {
                    continue;
                }
            } else {
                // omit assets deviated positively
                if (newPrice > collateral.lastPrice) {
                    continue;
                }
            }
            
            // accumulate value in USDT
            totalCollateralValueDeviated += getAssetPrice(collateral.priceFeed)
                                                .mul(_assetsBalance[collateral.token])
                                                .div(collateral.assetUnit);
        }
        
        // step 2. buyback operations in pro-rata basis
        for (uint i=0;i<collaterals.length;i++) {
            CollateralInfo storage collateral = collaterals[i];
        
            // check new price of the assets & omit those not deviated
            uint256 newPrice = getAssetPrice(collateral.priceFeed);
            if (isExcessive) {
                // omit assets deviated negatively
                if (newPrice < collateral.lastPrice) {
                    continue;
                }
            } else {
                // omit assets deviated positively
                if (newPrice > collateral.lastPrice) {
                    continue;
                }
            }
            
            // calc slot value in USDT
            uint256 slotValue = getAssetPrice(collateral.priceFeed)
                                                .mul(_assetsBalance[collateral.token])
                                                .div(collateral.assetUnit);
            
            // calc pro-rata buy back value(in USDT) for this collateral
            uint256 slotBuyBackValue = slotValue.mul(valueDeviates)
                                                .div(totalCollateralValueDeviated);
                                
			// non zero check
			if (slotBuyBackValue > 0) {
                // execute different buyback operations
                if (isExcessive) {
                    _buybackOGS(
                        collateral.token, 
                        collateral.vTokenAddress,
                        collateral.assetUnit,
                        collateral.priceFeed,
                        slotBuyBackValue
                    );
                } else {
                    _buybackCollateral(
                        collateral.token, 
                        collateral.vTokenAddress,
                        collateral.assetUnit,
                        collateral.priceFeed,
                        slotBuyBackValue
                    );
                }
    		}
            
            // update the collateral price to lastest
            collateral.lastPrice = newPrice;
        }
    }

    /**
     * @dev get total collateral value in USDT
     */
    function _getTotalCollateralValue() internal view returns(uint256) {
        uint256 totalCollateralValue;
        for (uint i=0;i<collaterals.length;i++) {
            CollateralInfo storage collateral = collaterals[i];
            totalCollateralValue += getAssetPrice(collateral.priceFeed)
                                    .mul(_assetsBalance[collateral.token])
                                    .div(collateral.assetUnit);
        }
        
        return totalCollateralValue;
    }
    
    /**
     * @dev buy back OGS with collateral
     * 1. to form an insurance fund (50%)
     * 2. conduct a ogs burn(50%)
     */
    function _buybackOGS(address token ,address vTokenAddress, uint256 assetUnit, AggregatorV3Interface priceFeed, uint256 slotValue) internal {
        uint256 collateralToRedeem = slotValue
                                        .mul(assetUnit)
                                        .div(getAssetPrice(priceFeed));
        // accounting
        _assetsBalance[token] = _assetsBalance[token].sub(collateralToRedeem);
        
        // redeem supply from farming
        _redeemSupply(token, vTokenAddress, collateralToRedeem);
        uint256 redeemedAmount;
        if (token == WETH) {
            redeemedAmount = address(this).balance;
        } else {
            redeemedAmount = IERC20(token).balanceOf(address(this));
        }

        // split assets allocation
        uint256 assetToInsuranceFund = redeemedAmount.mul(50).div(100);
        uint256 assetToBuyBackOGS = redeemedAmount.sub(assetToInsuranceFund);
        
        // allocation a)
        // swap to USDT to form last resort insurance fund (50%)
        if (assetToInsuranceFund >0) {
            if (token != usdtContract) {
                address[] memory path;
                path = new address[](2);
                path[0] = token;
                path[1] = usdtContract;
                
                // swap USDT out
                if (token == WETH) {
                    router.swapExactETHForTokens{value:assetToInsuranceFund}(
                        0, 
                        path, 
                        address(this), 
                        block.timestamp.add(600)
                    );
                    
                } else {
                    router.swapExactTokensForTokens(
                        assetToInsuranceFund,
                        0, 
                        path, 
                        address(this), 
                        block.timestamp.add(600)
                    );
                }
            }
        }
        
        // transfer all USDT to last resort fund
        uint256 amountUSDT = IERC20(usdtContract).balanceOf(address(this));
        IERC20(usdtContract).safeTransfer(lastResortFund, amountUSDT);
        
        // allocation b)
        // conduct a ogs burn
        // the path to find how many OGS can be swapped
        // path:
        //  exact collateral -> USDT -> ??? OGS
        address[] memory path;
        if (token == usdtContract) {
            path = new address[](2);
            path[0] = token;
            path[1] = address(ogsContract);
        } else {
            path = new address[](3);
            path[0] = token;
            path[1] = usdtContract; // use USDT to bridge
            path[2] = address(ogsContract);
        }
        
        // swap OGS out
        uint [] memory amounts;
        if (assetToBuyBackOGS > 0) {
            if (token == WETH) {
                amounts = router.swapExactETHForTokens{value:assetToBuyBackOGS}(
                    0, 
                    path, 
                    address(this), 
                    block.timestamp.add(600)
                );
                
            } else {
                amounts =router.swapExactTokensForTokens(
                    assetToBuyBackOGS,
                    0, 
                    path, 
                    address(this), 
                    block.timestamp.add(600)
                );
            }
            
            // burn OGS
            ogsContract.burn(amounts[amounts.length - 1]);
                    
            // log
            emit OGSBurned(amounts[amounts.length - 1]);
        }
    }
    
    /**
     * @dev buy back collateral with OGS
     * slotValue is priced in USDT 
     */
    function _buybackCollateral(address token ,address vTokenAddress, uint256 assetUnit, AggregatorV3Interface priceFeed, uint256 slotValue) internal {
        uint256 collateralToBuyBack = slotValue
                                        .mul(assetUnit)
                                        .div(getAssetPrice(priceFeed));
                                             
        // the path to find how many OGS required to swap collateral out
        // path:
        //  (??? OGS) -> USDT -> collateral
        address[] memory path;
        if (token == usdtContract) {
            path = new address[](2);
            path[0] = address(ogsContract);
            path[1] = token;
        } else {
            path = new address[](3);
            path[0] = address(ogsContract);
            path[1] = usdtContract; // use USDT to bridge
            path[2] = token;
        }
        
        if (collateralToBuyBack > 0) {
            // calc amount OGS required to swap out given collateral
            uint [] memory amounts = router.getAmountsIn(collateralToBuyBack, path);
            uint256 ogsRequired = amounts[0];
                        
            // mint OGS to this contract to buy back collateral           
            // NOTE: ogs contract MUST authorized THIS contract the privilege to mint
            ogsContract.mint(address(this), ogsRequired);
    
            // the path to swap collateral out
            // path:
            //  (exact OGS) -> USDT -> collateral
            if (token == WETH) {
                amounts = router.swapExactTokensForETH(
                    ogsRequired,
                    0,
                    path, 
                    address(this), 
                    block.timestamp.add(600)
                );
            } else {
                amounts = router.swapExactTokensForTokens(
                    ogsRequired,
                    0, 
                    path, 
                    address(this), 
                    block.timestamp.add(600)
                );
            }
            
            uint256 swappedOut = amounts[amounts.length - 1];
            
            // as we brought back the collateral, farm the asset
            _supply(token, vTokenAddress, swappedOut);
            
            // accounting
            _assetsBalance[token] = _assetsBalance[token].add(swappedOut);
            
            // log
            emit CollateralBroughtBack(token, swappedOut);
        }
    }
    
    /**
     * ======================================================================================
     * 
     * OURO's farming revenue distribution
     *
     * ======================================================================================
     */

     /**
      * @dev a public function accessible to anyone to distribute revenue
      */
     function distributeRevenue() external {
         _distributeXVS();
         _distributeAssetRevenue();
                 
        // log 
        emit RevenueDistributed();
     }
     
     function _distributeXVS() internal {
        // get venus markets
        address[] memory venusMarkets = new address[](collaterals.length);
        for (uint i=0;i<collaterals.length;i++) {
            venusMarkets[i] = collaterals[i].vTokenAddress;
        }
        // claim venus XVS reward
        IVenusDistribution(unitroller).claimVenus(address(this), venusMarkets);

        // and exchange XVS to OGS
        address[] memory path = new address[](3);
        path[0] = xvsAddress;
        path[1] = usdtContract;
        path[2] = address(ogsContract);

        // swap all XVS to OGS
        uint256 xvsAmount = IERC20(xvsAddress).balanceOf(address(this));

        if (xvsAmount > 0) {
            // swap OGS out
            uint [] memory amounts = router.swapExactTokensForTokens(
                xvsAmount,
                0, 
                path, 
                address(this), 
                block.timestamp.add(600)
            );
            uint256 ogsAmountOut = amounts[amounts.length - 1];
    
            // burn OGS
            ogsContract.burn(ogsAmountOut);
        }
                
        // log
        emit XVSDist(xvsAmount);
     }
     
     function _distributeAssetRevenue() internal {   
        // distribute assets revenue 
        uint n = collaterals.length;
        for (uint i=0;i<n;i++) {
            CollateralInfo storage collateral = collaterals[i];
            // get underlying balance
            uint256 farmBalance = IVToken(collateral.vTokenAddress).balanceOfUnderlying(address(this));
            
            // revenue generated
            if (farmBalance > _assetsBalance[collateral.token]) {        
                // calc revenue
                uint256 revenue = farmBalance.sub(_assetsBalance[collateral.token]);
                // check liquidity
                (, uint liquidity,) = IVenusDistribution(unitroller).getAccountLiquidity(address(this));
            
                // prevent zero redeeming
                if (liquidity > 0 && revenue > 0) {
                    // redeem asset
                    IVToken(collateral.vTokenAddress).redeemUnderlying(revenue);

                    // get actual revenue redeemed
                    uint256 redeemedAmount;
                    if (collateral.token == WETH) {
                        redeemedAmount = address(this).balance;
                    } else {
                        redeemedAmount = IERC20(collateral.token).balanceOf(address(this));
                    }
                    
                    // transfer asset to ouro revenue distribution contract
                    if (collateral.token == WETH) {
                        payable(address(ouroDistContact)).sendValue(redeemedAmount);
                    } else {
                        IERC20(collateral.token).safeTransfer(address(ouroDistContact), redeemedAmount);
                    }
                    
                    // notify ouro revenue contract
                    ouroDistContact.revenueArrival(collateral.token, redeemedAmount);
                }
            }
        }
     }
    
    /**
     * ======================================================================================
     * 
     * OURO Reserve's events
     *
     * ======================================================================================
     */
     event Deposit(address account, uint256 ouroAmount);
     event Withdraw(address account, address token, uint256 assetAmount);
     event Appreciation(uint256 price);
     event Rebased(address account);
     event NewCollateral(address token);
     event RemoveCollateral(address token);
     event CollateralBroughtBack(address token, uint256 amount);
     event OGSBurned(uint ogsAmount);
     event AllowanceReset();
     event XVSDist(uint256 amount);
     event RevenueDistributed();
     event LastResortFundSet(address account);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        require((allowance(_msgSender(), spender) == 0) || (amount == 0), "ERC20: change allowance use increaseAllowance or decreaseAllowance instead");
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}



interface IOGSToken is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
    function setMintable(address account, bool allow) external;
}

interface IOUROToken is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
    function setMintable(address account, bool allow) external;
}

interface IOUROReserve {
    function getPrice() external view returns(uint256);
    function deposit(address token, uint256 amountAsset) external payable returns (uint256 OUROMinted);
    function withdraw(address token, uint256 amountAsset) external returns(uint256 OUROTaken);
}

interface IOURODist {
    function revenueArrival(address token, uint256 assetAmount) external;
    function resetAllowance(address token) external;
}

interface IVenusDistribution {
    function oracle() external view returns (address);

    function enterMarkets(address[] memory _vtokens) external;
    function exitMarket(address _vtoken) external;
    function getAssetsIn(address account) external view returns (address[] memory);

    function markets(address vTokenAddress) external view returns (bool, uint, bool);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);

    function claimVenus(address holder, address[] memory vTokens) external;
    function venusSpeeds(address) external view returns (uint);
}

interface IWBNB is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

interface IVBNB {
    function totalSupply() external view returns (uint);

    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow() external payable;

    function balanceOfUnderlying(address owner) external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function totalBorrowsCurrent() external returns (uint);

    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);
    function borrowRatePerBlock() external view returns (uint);
}

interface IVToken is IERC20 {
    function underlying() external returns (address);

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);

    function balanceOfUnderlying(address owner) external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function totalBorrowsCurrent() external returns (uint);

    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);
    function borrowRatePerBlock() external view returns (uint);
}

