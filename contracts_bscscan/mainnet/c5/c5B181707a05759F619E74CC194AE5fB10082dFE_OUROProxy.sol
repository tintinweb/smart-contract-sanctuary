// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./library.sol";

/**
 * @title OURO proxy
 */
contract OUROProxy is IOUROReserve, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using Address for address payable;
    using SafeMath for uint256;

    uint256 public preserve = 5;
    uint public ouroIssuePeriod = 30 days; // ouro issuance limit
    uint256 constant internal MAX_UINT256 = uint256(-1);

    uint256 constant public issueFrom = 1641353203; // from reserve contract; 
    address public ouroReserve = 0x8739aBC0be4f271A5f4faC825BebA798Ee03f0CA;
    address ouroContract = 0x0a4FC79921f960A4264717FeFEE518E088173a79;
    address immutable internal WBNB = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E).WETH();

    // @dev montly OURO issuance schedule in 100k(1e5) OURO
    uint256 public constant OURO_PRICE_UNIT = 1e18; // 1 OURO = 1e18
    uint16 [] public issueSchedule = [1,10,30,50,70,100,150,200,300,400,500,650,800];
    uint256 internal constant issueUnit = 1e5 * OURO_PRICE_UNIT;

    receive() external payable {}

    // preserve certain percentage of OURO when issuance is limited
    function setPreserve(uint256 newPreserve) external onlyOwner {
        require(newPreserve >= 0 && newPreserve <= 100);
        preserve = newPreserve;
    }

    /** 
     * @dev reset allowance for proxy to ouro reserve
     */
    function resetAllowance(address token) external {
       IERC20(token).safeApprove(ouroReserve, 0); 
       IERC20(token).safeIncreaseAllowance(ouroReserve, MAX_UINT256);
       // log
       emit ResetAllowance(token);
    }

    /**
     * @dev deposit adapter before issuance limit removed
     */
    function deposit(address token, uint256 amountAsset, uint256 minAmountOuro) external override payable nonReentrant returns (uint256 OUROMinted) {
        // issuance quota check
        (,uint256 assetUnit,,AggregatorV3Interface priceFeed) = IOUROReserve(ouroReserve).getCollateral(token);
        uint256 assetValueInOuro = _lookupAssetValueInOURO(priceFeed, assetUnit, amountAsset);

        uint periodN = block.timestamp.sub(issueFrom).div(ouroIssuePeriod);
        if (periodN < issueSchedule.length) { // still in control
            require (assetValueInOuro.add(IERC20(ouroContract).totalSupply()) 
                        <=
                    uint256(issueSchedule[periodN]).mul(issueUnit).mul(100-preserve).div(100),
                    "limited"
            );
        }

        // approval of assets to reserve
        if (token != WBNB) {
            if (IERC20(token).allowance(address(this), address(ouroReserve)) == 0) {
                IERC20(token).safeIncreaseAllowance(address(ouroReserve), MAX_UINT256);
            }
        }

        // right now, we can mint OURO until (100-preserve)/100 of issuance limit
        
        // bridge token assets to ouro reserve
        //  asset: caller -> proxy -> ouro reserve
        //  ouro: ouro reserve -> proxy -> caller
        if (token == WBNB) {
            OUROMinted = IOUROReserve(ouroReserve).deposit{value:msg.value}(token, amountAsset, minAmountOuro);
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amountAsset);
            OUROMinted = IOUROReserve(ouroReserve).deposit(token, amountAsset, minAmountOuro);
        }

        // transfer all OURO to sender
        IERC20(ouroContract).safeTransfer(msg.sender, IERC20(ouroContract).balanceOf(address(this)));
    }
        
    function withdraw(address token, uint256 amountAsset, uint256 maxAmountOuro) external override nonReentrant returns(uint256 OUROTaken) {
        // CAP amountAsset to maximum available in reserve
        uint256 reserveBalance = IOUROReserve(ouroReserve).getAssetBalance(token);
        amountAsset = amountAsset > reserveBalance ? reserveBalance : amountAsset;

        // check corresponding OURO amount
        (,uint256 assetUnit,,AggregatorV3Interface priceFeed) = IOUROReserve(ouroReserve).getCollateral(token);
        uint256 assetValueInOuro = _lookupAssetValueInOURO(priceFeed, assetUnit, amountAsset);

        // transfer OURO from msg.sender to proxy
        IERC20(ouroContract).safeTransferFrom(msg.sender, address(this), assetValueInOuro);

        // OURO approval to reserve
        if (IERC20(ouroContract).allowance(address(this), address(ouroReserve)) == 0) {
            IERC20(ouroContract).safeIncreaseAllowance(address(ouroReserve), MAX_UINT256);
        }

        // withdraw assets to proxy
        OUROTaken = IOUROReserve(ouroReserve).withdraw(token, amountAsset, maxAmountOuro);

        // transfer all assets
        if (token == WBNB) {
            msg.sender.sendValue(address(this).balance);
        } else {
            IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }

        // just in case
        if (IERC20(ouroContract).balanceOf(address(this)) > 0) {
            IERC20(ouroContract).safeTransfer(msg.sender, IERC20(ouroContract).balanceOf(address(this)));
        }
    }
    
    function getPrice() external override view returns(uint256) { return IOUROReserve(ouroContract).getPrice(); }
    function getAssetBalance(address token) external override view returns(uint256) { return IOUROReserve(ouroContract).getAssetBalance(token); }
    function getAssetPrice(AggregatorV3Interface feed) external override view returns(uint256) {return IOUROReserve(ouroContract).getAssetPrice(feed); }

    function getCollateral(address token) external override view returns (
        address vTokenAddress,
        uint256 assetUnit, // usually 1e18
        uint256 lastPrice, // record latest collateral price
        AggregatorV3Interface priceFeed // asset price feed for xxx/USDT
    ) {
        return IOUROReserve(ouroContract).getCollateral(token);
    }

    function getOuroIn(uint256 amount, address token) external override view returns(uint256) { return IOUROReserve(ouroContract).getOuroIn(amount,token); }
    function getAssetsIn(uint256 amountOURO, address token) external override view returns(uint256){ return IOUROReserve(ouroContract).getAssetsIn(amountOURO,token); }

    /**
     * @dev find the given asset value priced in OURO
     */
    function _lookupAssetValueInOURO(AggregatorV3Interface priceFeed, uint256 assetUnit, uint256 amountAsset) internal view returns (uint256 amountOURO) {
        // get lastest asset value in USD
        uint256 assetUnitPrice = IOUROReserve(ouroReserve).getAssetPrice(priceFeed);
        
        // compute total USD value
        uint256 assetValueInUSD = amountAsset
                                                    .mul(assetUnitPrice)
                                                    .div(assetUnit);
                                                    
        // convert asset USD value to OURO value
        uint256 assetValueInOuro = assetValueInUSD.mul(OURO_PRICE_UNIT)
                                                    .div(IOUROReserve(ouroReserve).getPrice());
                                                    
        return assetValueInOuro;
    }

    /**
     * ======================================================================================
     * 
     * OURO Proxy events
     *
     * ======================================================================================
     */
    event ResetAllowance(address token);
}