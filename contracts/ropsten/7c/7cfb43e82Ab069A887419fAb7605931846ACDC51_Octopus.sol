// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "ERC20.sol";
import "SafeERC20.sol";
import "Ownable.sol";


interface IOption {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function mint(address account, uint256 amount) external;
    
    function getUnderlying() external view returns (uint8);
    
    function getStrike() external view returns (uint);

    function getExpiresOn() external view returns (uint);
    
    function isPut() external view returns (bool);
}

interface IPriceConsumer {
    function getLatestPrice() external view returns (int);
}

interface IUniswapV2Router02 {
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
      
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
      
    function WETH() external returns (address); 
    
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
    
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    
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
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
}

interface CErc20 {
    function balanceOf(address owner) external view returns (uint256);

    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface CEth {
    function balanceOf(address owner) external view returns (uint256);
    
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function transfer(address recipient, uint256 amount) external returns (bool);
}


contract Octopus is Ownable {
    IPriceConsumer priceConsumerETH = IPriceConsumer(0x17A8402bF6BeA74535c9ff69648EBb6Ede7399e3);
    IPriceConsumer priceConsumerwBTC = IPriceConsumer(0x48B895Fd679596236747D8e9E8Af9c32b77BFD7F);
    IPriceConsumer priceConsumerPolygon = IPriceConsumer(0xa25dda2d9224A4CdA8A8E639B131564F30396244);

    IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 kiboToken =  IERC20(0xF096C24D20528bD45aC555F3c0cbf4F781316556);
    ERC20 usdtToken = ERC20(0x8464c1368711F3A44d876e4359A8F67758609430);
    ERC20 wBTCToken = ERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    ERC20 polygonToken = ERC20(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0);

    address payable cETH = payable(0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8);
    address cUSDT = 0xF6958Cf3127e62d3EB26c79F4f45d3F3b2CcdeD4;
    address cwBTC = 0xF6958Cf3127e62d3EB26c79F4f45d3F3b2CcdeD4;

    struct Seller {
        bool isValid;
        uint256 collateral; //This is in USDT for PUT and in the underlying for CALL
        uint256 notional;
        bool claimed;
        uint256 cTokens;
    }
    
    struct Option {
        bool isValid;
        uint256 assetPriceInUSDTAtMaturity;
        uint256 optionWorth;
        mapping(address => Seller) sellers;
    }
    
    uint8 constant ETH = 1;
    uint8 constant WBTC = 2;
    uint8 constant POLYGON = 3;
    
    mapping(address => Option) options;
    mapping(address => uint256) public kiboRewards;

    uint256 public totalETHFees;
    uint256 public totalUSDTFees;

    event OptionPurchase(address indexed option, address indexed buyer, uint256 weiNotional, uint256 usdtCollateral, uint256 premium);
    event RewardsIncreased(address indexed beneficiary, uint256 total);
    event RewardsWithdrawn(address indexed beneficiary, uint256 total);
    event ReturnedToSeller(address indexed option, address indexed seller, uint256 totalUSDTReturned, uint256 collateral, uint256 notional);
    event ReturnedToBuyer(address indexed option, address indexed buyer, uint256 totalUSDTReturned, uint256 _numberOfTokens);
    event OptionFinalPriceSet(address indexed option, uint256 assetPriceInUsdt, uint256 optionWorthInUsdt);

    function sell(address _optionAddress, uint256 _weiNotional) payable external {
        require(options[_optionAddress].isValid, "Invalid option");
        require(IOption(_optionAddress).getExpiresOn() > block.timestamp, "Expired option");
        
        uint256 difference;
        uint256 usdCollateral;
        uint256 feesToCollect;

        Seller storage seller = options[_optionAddress].sellers[msg.sender];

        if (IOption(_optionAddress).isPut()) {
            usdCollateral = calculateCollateralForPut(_optionAddress, _weiNotional);
            SafeERC20.safeTransferFrom(usdtToken, msg.sender, address(this), usdCollateral);
            seller.cTokens += supplyErc20ToCompound(usdtToken, cUSDT, usdCollateral);
        } else {
            require(msg.value >= _weiNotional, 'Invalid collateral');
            difference = msg.value - _weiNotional;
            if (difference > 0) {
                payable(msg.sender).transfer(difference);
            }
            seller.cTokens += supplyEthToCompound(cETH, _weiNotional);
        }   
        
        IOption(_optionAddress).mint(address(this), _weiNotional);
        
        //We sell the tokens for USDT in Uniswap, which is sent to the user
        uint256 premium = sellTokensInUniswap(_optionAddress, _weiNotional);
        
        if (IOption(_optionAddress).isPut()) {
            feesToCollect = usdCollateral / 100;
            seller.collateral += usdCollateral - feesToCollect;
            totalUSDTFees += feesToCollect;
        } else {
            feesToCollect = _weiNotional / 100;
            seller.collateral += _weiNotional - feesToCollect;
            totalETHFees += feesToCollect;
        }

        seller.isValid = true;
        seller.notional += _weiNotional;
        
        //We emit an event to be able to send KiboTokens offchain, according to the difference against the theoretical Premium
        emit OptionPurchase(_optionAddress, msg.sender, _weiNotional, usdCollateral, premium);
    }
    
    function calculateCollateralForPut(address _optionAddress, uint256 _notionalInWei) public view returns (uint256) {
        require(options[_optionAddress].isValid, "Invalid option");
        return IOption(_optionAddress).getStrike() * _notionalInWei * 1e6 / 1e18;
    }
    
    function claimCollateralAtMaturityForSellers(address _optionAddress) external {
        require(options[_optionAddress].isValid, "Invalid option");
        require(options[_optionAddress].assetPriceInUSDTAtMaturity > 0, "Still not ready");
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        
        require(seller.isValid, "Seller not valid");
        require(!seller.claimed, "Already claimed");
        
        uint256 totalToReturn = getHowMuchToClaimForSellers(_optionAddress, msg.sender);
        require(totalToReturn > 0, 'Nothing to return');
        
        seller.claimed = true;

        if (IOption(_optionAddress).isPut()) {
            CErc20 cToken = CErc20(cUSDT);
            uint256 interests = seller.cTokens * cToken.exchangeRateCurrent() - seller.collateral;

            uint256 redeemResult = redeemCErc20Tokens(totalToReturn + interests, true, cUSDT);
            require(redeemResult == 0, "An error occurred");

            SafeERC20.safeTransfer(usdtToken, msg.sender, totalToReturn + interests);
        } else {
            CEth cToken = CEth(cETH);
            uint256 interests = seller.cTokens * cToken.exchangeRateCurrent() - seller.collateral;
            uint256 redeemResult = redeemCEth(totalToReturn + interests, true, cETH);
            require(redeemResult == 0, "An error occurred");

            payable(msg.sender).transfer(totalToReturn);
        }
        
        emit ReturnedToSeller(_optionAddress, msg.sender, totalToReturn, seller.collateral, seller.notional);
    }
    
    function getHowMuchToClaimForSellers(address _optionAddress, address _seller) public view returns (uint256) {
        Seller memory seller = options[_optionAddress].sellers[_seller];
        if (seller.claimed) {
            return 0;
        }
        uint256 optionWorth = options[_optionAddress].optionWorth;
        uint256 amountToSubstract;
        
        if (IOption(_optionAddress).isPut()) {
            amountToSubstract = seller.notional * optionWorth / 1e18;
        } else {
            uint256 optionWorthInEth = optionWorth * 1e18 / (options[_optionAddress].assetPriceInUSDTAtMaturity * 1e6);
            amountToSubstract = seller.notional * optionWorthInEth / 1e18;
        }
        return seller.collateral - amountToSubstract;
    }
    
    function getHowMuchToClaimForBuyers(address _optionAddress, uint256 _numberOfTokens) public view returns (uint256) {
        uint256 optionWorth = options[_optionAddress].optionWorth;
        if (IOption(_optionAddress).isPut()) {
            return _numberOfTokens * optionWorth / 1e18;
        } else {
            uint256 optionWorthInEth = optionWorth * 1e18 / (options[_optionAddress].assetPriceInUSDTAtMaturity * 1e6);
            return _numberOfTokens * optionWorthInEth / 1e18;
        }
    }
    
    function claimCollateralAtMaturityForBuyers(address _optionAddress, uint256 _numberOfTokens) external {
        require(options[_optionAddress].isValid, "Invalid option");
        require(options[_optionAddress].assetPriceInUSDTAtMaturity > 0, "Still not ready");
        require(_numberOfTokens > 0, "Invalid number of tokens");
        
        require(IERC20(_optionAddress).transferFrom(msg.sender, address(this), _numberOfTokens), "Transfer failed");
        
        uint256 totalToReturn = getHowMuchToClaimForBuyers(_optionAddress, _numberOfTokens);
        
        if (IOption(_optionAddress).isPut()) {
            //I take the amount from the Compound pool first
            uint256 redeemResult = redeemCErc20Tokens(totalToReturn, false, cUSDT);
            require(redeemResult == 0, "An error occurred");

            SafeERC20.safeTransfer(usdtToken, msg.sender, totalToReturn);
        } else {
            //I take the amount from the Compound pool first
            uint256 redeemResult = redeemCEth(totalToReturn, false, cETH);
            require(redeemResult == 0, "An error occurred");

            payable(msg.sender).transfer(totalToReturn);
        }

        emit ReturnedToBuyer(_optionAddress, msg.sender, totalToReturn, _numberOfTokens);
    }
    
    function withdrawKiboTokens() external {
        require(kiboRewards[msg.sender] > 0, "Nothing to withdraw");
        uint256 total = kiboRewards[msg.sender];
        kiboRewards[msg.sender] = 0;
        SafeERC20.safeTransfer(kiboToken, msg.sender, total);
        emit RewardsWithdrawn(msg.sender, total);
    }

    // Public functions
    
    // Returns the amount in USDT if you sell 1 KiboToken in Uniswap
    function getKiboSellPrice() external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(kiboToken);
        path[1] = address(usdtToken);
        uint[] memory amounts = uniswapRouter.getAmountsOut(1e18, path);
        return amounts[1];
    }
    
    // Returns the amount in USDT if you buy 1 KiboToken in Uniswap
    function getKiboBuyPrice() external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(usdtToken);
        path[1] = address(kiboToken);
        uint[] memory amounts = uniswapRouter.getAmountsIn(1e18, path);
        return amounts[0];
    }
    
    // Internal functions
    
    function sellTokensInUniswap(address _optionAddress, uint256 _tokensAmount) internal returns (uint256)  {
        address[] memory path = new address[](2);
        path[0] = _optionAddress;
        path[1] = address(usdtToken);
        IERC20(_optionAddress).approve(address(uniswapRouter), _tokensAmount);
        // TODO: uint256[] memory amountsOutMin = uniswapRouter.getAmountsOut(_tokensAmount, path);
        // Use amountsOutMin[1]
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(_tokensAmount, 0, path, msg.sender, block.timestamp);
        return amounts[1];
    }
    
    function createPairInUniswap(address _optionAddress, uint256 _totalTokens, uint256 _totalUSDT) internal returns (uint amountA, uint amountB, uint liquidity) {
        uint256 allowance = usdtToken.allowance(address(this), address(uniswapRouter));
        if (allowance > 0 && allowance < _totalUSDT) {
            SafeERC20.safeApprove(usdtToken, address(uniswapRouter), 0);
        }
        if (allowance == 0) {
            SafeERC20.safeApprove(usdtToken, address(uniswapRouter), _totalUSDT);
        }
        IERC20(_optionAddress).approve(address(uniswapRouter), _totalTokens);
        (amountA, amountB, liquidity) = uniswapRouter.addLiquidity(_optionAddress, address(usdtToken), _totalTokens, _totalUSDT, 0, 0, msg.sender, block.timestamp);
    }

    //Admin functions
    
    function _addKiboRewards(address _beneficiary, uint256 _total) external onlyOwner {
        kiboRewards[_beneficiary] += _total;
        emit RewardsIncreased(_beneficiary, _total);
    }
    
    function _deactivateOption(address _optionAddress) external onlyOwner {
        require(options[_optionAddress].isValid, "Already not activated");
        options[_optionAddress].isValid = false;
    }
    
    function _activatePutOption(address _optionAddress, uint256 _usdtCollateral, uint256 _uniswapInitialUSDT, uint256 _uniswapInitialTokens, bool _createPair) external onlyOwner {
        require(IOption(_optionAddress).getExpiresOn() > block.timestamp, "Expired option");
        require(!options[_optionAddress].isValid, "Already activated");
        require(_usdtCollateral > 0, "Collateral cannot be zero");
        require(_uniswapInitialUSDT > 0, "Uniswap USDT cannot be zero");
        require(_uniswapInitialTokens > 0, "Uniswap tokens cannot be zero");
        require(IOption(_optionAddress).isPut(), "Option is not PUT");

        options[_optionAddress].isValid = true;

        IOption(_optionAddress).mint(address(this), _uniswapInitialTokens);
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        seller.collateral = _usdtCollateral;
        seller.isValid = true;
        seller.notional = _uniswapInitialTokens;
        
        SafeERC20.safeTransferFrom(usdtToken, msg.sender, address(this), _uniswapInitialUSDT + _usdtCollateral);
        seller.cTokens += supplyErc20ToCompound(usdtToken, cUSDT, _usdtCollateral);

        if (_createPair) {
            createPairInUniswap(_optionAddress, _uniswapInitialTokens, _uniswapInitialUSDT);
        }
    }
    
    function _activateEthCallOption(address _optionAddress, uint256 _uniswapInitialUSDT, uint256 _uniswapInitialTokens, bool _createPair) external payable onlyOwner {
        require(IOption(_optionAddress).getExpiresOn() > block.timestamp, "Expired option");
        require(!options[_optionAddress].isValid, "Already activated");
        require(msg.value > 0, "Collateral cannot be zero");
        require(_uniswapInitialUSDT > 0, "Uniswap USDT cannot be zero");
        require(_uniswapInitialTokens > 0, "Uniswap tokens cannot be zero");
        require(!IOption(_optionAddress).isPut(), "Option is not CALL");
        require(IOption(_optionAddress).getUnderlying() == ETH, "Wrong underlying");

        options[_optionAddress].isValid = true;

        IOption(_optionAddress).mint(address(this), _uniswapInitialTokens);
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        seller.collateral = msg.value;
        seller.isValid = true;
        seller.notional = _uniswapInitialTokens;
        
        seller.cTokens += supplyEthToCompound(cETH, msg.value);

        SafeERC20.safeTransferFrom(usdtToken, msg.sender, address(this), _uniswapInitialUSDT);
        
        if (_createPair) {
            createPairInUniswap(_optionAddress, _uniswapInitialTokens, _uniswapInitialUSDT);
        }
    }
    
    function _activatewBTCCallOption(address _optionAddress, uint256 _collateral, uint256 _uniswapInitialUSDT, uint256 _uniswapInitialTokens, bool _createPair) external payable onlyOwner {
        require(IOption(_optionAddress).getExpiresOn() > block.timestamp, "Expired option");
        require(!options[_optionAddress].isValid, "Already activated");
        require(_collateral > 0, "Collateral cannot be zero");
        require(_uniswapInitialUSDT > 0, "Uniswap USDT cannot be zero");
        require(_uniswapInitialTokens > 0, "Uniswap tokens cannot be zero");
        require(!IOption(_optionAddress).isPut(), "Option is not CALL");
        require(IOption(_optionAddress).getUnderlying() == WBTC, "Wrong underlying");

        options[_optionAddress].isValid = true;

        IOption(_optionAddress).mint(address(this), _uniswapInitialTokens);
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        seller.collateral = _collateral;
        seller.isValid = true;
        seller.notional = _uniswapInitialTokens;
        
        seller.cTokens += supplyErc20ToCompound(wBTCToken, cwBTC, _collateral);

        SafeERC20.safeTransferFrom(wBTCToken, msg.sender, address(this), _collateral);
        SafeERC20.safeTransferFrom(usdtToken, msg.sender, address(this), _uniswapInitialUSDT);
        
        if (_createPair) {
            createPairInUniswap(_optionAddress, _uniswapInitialTokens, _uniswapInitialUSDT);
        }
    }
    
    function _activatePolygonCallOption(address _optionAddress, uint256 _collateral, uint256 _uniswapInitialUSDT, uint256 _uniswapInitialTokens, bool _createPair) external payable onlyOwner {
        require(IOption(_optionAddress).getExpiresOn() > block.timestamp, "Expired option");
        require(!options[_optionAddress].isValid, "Already activated");
        require(_collateral > 0, "Collateral cannot be zero");
        require(_uniswapInitialUSDT > 0, "Uniswap USDT cannot be zero");
        require(_uniswapInitialTokens > 0, "Uniswap tokens cannot be zero");
        require(!IOption(_optionAddress).isPut(), "Option is not CALL");
        require(IOption(_optionAddress).getUnderlying() == POLYGON, "Wrong underlying");

        options[_optionAddress].isValid = true;

        IOption(_optionAddress).mint(address(this), _uniswapInitialTokens);
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        seller.collateral = _collateral;
        seller.isValid = true;
        seller.notional = _uniswapInitialTokens;
        
        SafeERC20.safeTransferFrom(polygonToken, msg.sender, address(this), _collateral);
        SafeERC20.safeTransferFrom(usdtToken, msg.sender, address(this), _uniswapInitialUSDT);
        
        if (_createPair) {
            createPairInUniswap(_optionAddress, _uniswapInitialTokens, _uniswapInitialUSDT);
        }
    }
    
    function _setFinalPriceAtMaturity(address _optionAddress) external onlyOwner {
        require(options[_optionAddress].isValid, "Invalid option");
        require(options[_optionAddress].assetPriceInUSDTAtMaturity == 0, "Already set");
        require(IOption(_optionAddress).getExpiresOn() < block.timestamp, "Still not expired");
        
        uint8 underlying = IOption(_optionAddress).getUnderlying();
        uint256 strike = IOption(_optionAddress).getStrike();
        
        uint256 spotPrice;
        
        if (underlying == ETH) {
            //Gets the price in WEI for 1 usdtToken
            uint256 usdPriceOfEth = uint256(priceConsumerETH.getLatestPrice());
            //I need the price in USDT for 1 ETH
            spotPrice = uint256(1 ether) / usdPriceOfEth;
        }
        if (underlying == WBTC) {
            uint256 usdPriceOfAsset = uint256(priceConsumerwBTC.getLatestPrice());
            spotPrice = 1e8 / usdPriceOfAsset;
        }
        if (underlying == POLYGON) {
            uint256 usdPriceOfAsset = uint256(priceConsumerPolygon.getLatestPrice());
            spotPrice = 1e18 / usdPriceOfAsset;
        }
        else {
            revert();
        }
        
        uint256 optionWorth = 0;
        
        bool isPut = IOption(_optionAddress).isPut();
    
        if (isPut && spotPrice < strike) {
            optionWorth = strike - spotPrice;
        }
        else if (!isPut && spotPrice > strike) {
            optionWorth = spotPrice - strike;
        }
        
        options[_optionAddress].assetPriceInUSDTAtMaturity = spotPrice;
        options[_optionAddress].optionWorth = optionWorth * 1e6;
        
        emit OptionFinalPriceSet(_optionAddress, spotPrice, optionWorth);
    }
    
    function _withdrawUSDTFees() external onlyOwner {
        require(totalUSDTFees > 0, 'Nothing to claim');
        uint256 amount = totalUSDTFees;
        totalUSDTFees = 0;
        SafeERC20.safeTransfer(usdtToken, msg.sender, amount);
    }
    
    function _withdrawETHFees() external onlyOwner {
        require(totalETHFees > 0, 'Nothing to claim');
        uint256 amount = totalETHFees;
        totalETHFees = 0;
        payable(msg.sender).transfer(amount);
    }

    function _withdrawKibo(uint256 _amount) external onlyOwner {
        SafeERC20.safeTransfer(kiboToken, msg.sender, _amount);
    }
    
    function getOption(address _optionAddress) external view returns (bool _isValid, bool _isPut, uint256 _assetPriceInUSDTAtMaturity, uint256 _optionWorth) {
        return (options[_optionAddress].isValid, IOption(_optionAddress).isPut(), options[_optionAddress].assetPriceInUSDTAtMaturity, options[_optionAddress].optionWorth);
    }
    
    function getSeller(address _optionAddress, address _seller) external view returns (bool _isValid, uint256 _collateral, uint256 _notional, bool _claimed, uint256 _cTokens) {
        Seller memory seller = options[_optionAddress].sellers[_seller];
        return (seller.isValid, seller.collateral, seller.notional, seller.claimed, seller.cTokens);
    }

    //Compound
    
     function supplyEthToCompound(address payable _cEtherContract, uint256 _total)
        internal
        returns (uint256)
    {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        uint256 balance = cToken.balanceOf(address(this));

        cToken.mint{value:_total, gas: 250000}();
        return cToken.balanceOf(address(this)) - balance;
    }
    
    function supplyErc20ToCompound(
        ERC20 _erc20Contract,
        address _cErc20Contract,
        uint256 _numTokensToSupply
    ) internal returns (uint) {
        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        uint256 balance = cToken.balanceOf(address(this));

        // Approve transfer on the ERC20 contract
        SafeERC20.safeApprove(_erc20Contract, _cErc20Contract, _numTokensToSupply);

        // Mint cTokens
        cToken.mint(_numTokensToSupply);
        
        uint256 newBalance = cToken.balanceOf(address(this));

        return newBalance - balance;
    }
    
    function redeemCErc20Tokens(
        uint256 amount,
        bool redeemType,
        address _cErc20Contract
    ) internal returns (uint256) {
        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        // `amount` is scaled up, see decimal table here:
        // https://compound.finance/docs#protocol-math

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        return redeemResult;
    }

    function redeemCEth(
        uint256 amount,
        bool redeemType,
        address _cEtherContract
    ) internal returns (uint256) {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        // `amount` is scaled up by 1e18 to avoid decimals

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        // Error codes are listed here:
        // https://compound.finance/docs/ctokens#ctoken-error-codes
        return redeemResult;
    }

    receive() external payable {
        revert();
    }
}