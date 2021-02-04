/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Only owner can call this");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner || tx.origin == _owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function mint(address account, uint256 amount) external;
    
    function getUnderlying() external view returns (string memory);
    
    function getStrike() external view returns (uint);

    function getMaturity() external view returns (uint);
}


interface IPriceConsumerV3EthUsd {
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
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

contract Octopus is Ownable {
    using SafeMath for uint256;
    using SafeMath for int256;
    
    address usdtAddress = 0x1777cb74B2eF67BDC89864b8CeAce2d35ed30E96; // 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    
    IPriceConsumerV3EthUsd priceConsumer;
    IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 kiboToken;
    
    struct Seller {
        bool isValid;
        uint256 collateral;
        uint256 notional;
        bool claimed;
    }
    
    struct Option {
        bool isValid;
        uint256 etherPriceInUSDTAtMaturity;
        uint256 optionWorth;
        mapping(address => Seller) sellers;
    }
    
    mapping(address => Option) public options;
    
    event OptionPurchase(address indexed _option, address indexed buyer, uint256 weiNotional, uint256 usdCollateral, uint256 weiCollateral, uint256 premium);

    constructor(IPriceConsumerV3EthUsd _priceConsumer, address _kiboToken) {
        priceConsumer = _priceConsumer;
        kiboToken = IERC20(_kiboToken);
    }

    //Alice / Seller
    function sell(address _optionAddress, uint256 _weiNotional) payable public {
        require(options[_optionAddress].isValid, "Invalid option");
        require(IERC20(_optionAddress).getMaturity() < block.timestamp, "Expired option");
        
        (uint256 usdCollateral, uint256 weiCollateral) = calculateCollateral(_optionAddress, _weiNotional);
        
        require(msg.value >= weiCollateral, 'Invalid collateral');
        
        uint256 difference = msg.value - weiCollateral;
        if (difference > 0) {
            msg.sender.transfer(difference);
        }
        
        uint256 ethNotional = _weiNotional.div(1e18);
        IERC20(_optionAddress).mint(address(this), ethNotional);
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        
        seller.isValid = true;
        seller.collateral = seller.collateral.add(weiCollateral);
        seller.notional = seller.notional.add(ethNotional);
        
        //We sell the tokens for USDT in Uniswap, which is sent to the user
        uint256 premium = sellTokensInUniswap(_optionAddress, ethNotional); //TODO: Substract the fee before
        
        //We keep the collateral in USDT
        sellEthForUSDTInUniswap(weiCollateral);
        
        //We emit an event to be able to send KiboTokens offchain, according to the difference against the theoretical Premium
        emit OptionPurchase(_optionAddress, msg.sender, _weiNotional, usdCollateral, weiCollateral, premium);
    }
    
    //Bob / Buyer
    function buyWithEth(address _optionAddress) payable public {
        require(options[_optionAddress].isValid, "Invalid option");
        require(IERC20(_optionAddress).getMaturity() < block.timestamp, "Expired option");
        uint256 usdtAmount = sellEthForUSDTInUniswap(msg.value);
        buyTokensInUniswap(_optionAddress, usdtAmount);
    }
    
    //Bob / Buyer
    function buyWithUSDT(address _optionAddress, uint256 _usdtAmount) payable public {
        require(options[_optionAddress].isValid, "Invalid option");
        require(IERC20(_optionAddress).getMaturity() < block.timestamp, "Expired option");
        require(IERC20(usdtAddress).transferFrom(msg.sender, address(this), _usdtAmount), "Transfer failed");
        buyTokensInUniswap(_optionAddress, _usdtAmount);
    }
    
    function calculateCollateral(address _optionAddress, uint256 _notionalInWei) public view returns (uint256, uint256) {
        require(options[_optionAddress].isValid, "Invalid option");
        
        //Collateral = Strike * Notional (in ETH, not WEI)
        uint256 collateralInUSD = IERC20(_optionAddress).getStrike().mul(_notionalInWei);
        
        uint256 usdPriceOfEth = uint256(priceConsumer.getLatestPrice());
        
        //Collateral in ETH
        return (collateralInUSD, collateralInUSD.div(usdPriceOfEth));
    }
    
    function claimCollateralAtMaturityForSellers(address _optionAddress) public {
        require(options[_optionAddress].isValid, "Invalid option");
        require(options[_optionAddress].etherPriceInUSDTAtMaturity > 0, "Still not ready");
        
        // TODO: Can I get ETHER price at a certain date?
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        
        require(seller.isValid, "Seller not valid");
        require(!seller.claimed, "Already claimed");
        
        seller.claimed = true;
        
        uint256 optionWorth = options[_optionAddress].optionWorth;
        
        //TODO: Collateral in USD - notional in ETH * optionWorth 
        
        uint256 totalToReturn = seller.collateral - seller.notional.mul(optionWorth);
        
        require(IERC20(usdtAddress).transfer(msg.sender, totalToReturn), "Transfer failed");
    }
    
    function claimCollateralAtMaturityForBuyers(address _optionAddress, uint256 _numberOfTokens) public {
        require(options[_optionAddress].isValid, "Invalid option");
        require(options[_optionAddress].etherPriceInUSDTAtMaturity > 0, "Still not ready");
        
        require(IERC20(_optionAddress).transferFrom(msg.sender, address(this), _numberOfTokens), "Transfer failed");
        
        uint256 optionWorth = options[_optionAddress].optionWorth;
        
        uint256 totalToReturn = _numberOfTokens.mul(optionWorth);

        require(IERC20(usdtAddress).transfer(msg.sender, totalToReturn), "Transfer failed");
    }
    
    //Do I need to sort the addresses?
    function calculateCurrentPriceOfKToken(address _optionAddress) public returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = _optionAddress;
        uint[] memory amounts = uniswapRouter.getAmountsIn(1, path);
        return amounts[0];
    }
    
    //Is it correct to use 1?
    function calculateCurrentPriceOfKiboToken() public returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = address(kiboToken);
        uint[] memory amounts = uniswapRouter.getAmountsIn(1, path);
        return amounts[0];
    }
    
    // Internal functions
    
    function buyTokensInUniswap(address _optionAddress, uint256 _tokensAmount) internal returns (uint256)  {
        address[] memory path = new address[](2);
        path[0] = usdtAddress;
        path[1] = _optionAddress;
        IERC20(usdtAddress).approve(address(uniswapRouter), _tokensAmount);
        uint256[] memory amountsOutMin = uniswapRouter.getAmountsOut(_tokensAmount, path);
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(_tokensAmount, amountsOutMin[0], path, msg.sender, block.timestamp);
        return amounts[0];
    }
    
    function sellTokensInUniswap(address _optionAddress, uint256 _tokensAmount) internal returns (uint256)  {
        address[] memory path = new address[](2);
        path[0] = _optionAddress;
        path[1] = usdtAddress;
        IERC20(_optionAddress).approve(address(uniswapRouter), _tokensAmount);
        uint256[] memory amountsOutMin = uniswapRouter.getAmountsOut(_tokensAmount, path);
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(_tokensAmount, amountsOutMin[0], path, msg.sender, block.timestamp);
        return amounts[0];
    }
    
    function sellEthForUSDTInUniswap(uint256 _amount) public returns (uint256)  {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = usdtAddress;
        uint[] memory amounts = uniswapRouter.swapETHForExactTokens(_amount, path, address(this), block.timestamp);
        return amounts[0];
    }
    
    function createPairInUniswap(address _optionAddress, uint256 _totalTokens, uint256 _totalUSDT) public returns (uint amountA, uint amountB, uint liquidity) {
        IERC20(usdtAddress).approve(address(uniswapRouter), _totalUSDT);
        IERC20(_optionAddress).approve(address(uniswapRouter), _totalTokens);
        (amountA, amountB, liquidity) = uniswapRouter.addLiquidity(_optionAddress, usdtAddress, _totalTokens, _totalUSDT, 0, 0, msg.sender, block.timestamp);
    }

    //Admin functions
    
    function _deactivateOption(address _optionAddress) public onlyOwner {
        require(options[_optionAddress].isValid, "Already not activated");
        options[_optionAddress].isValid = false;
    }
    
    function _activateOption(address _optionAddress, uint256 _collateral, uint256 _uniswapInitialWei, uint256 _uniswapInitialTokens) public payable onlyOwner {
        require(IERC20(_optionAddress).getMaturity() < block.timestamp, "Expired option");
        require(!options[_optionAddress].isValid, "Already activated");
        require(msg.value == _collateral.add(_uniswapInitialWei), "Invalid value");
        
        options[_optionAddress].isValid = true;

        IERC20(_optionAddress).mint(address(this), _uniswapInitialTokens);
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        
        seller.isValid = true;
        seller.collateral = _collateral;
        seller.notional = 0;
    
        uint256 totalUSDT = sellEthForUSDTInUniswap(_uniswapInitialWei);
        
        createPairInUniswap(_optionAddress, _uniswapInitialTokens, totalUSDT);
    }
    
    function _activateOption2(address _optionAddress, uint256 _collateral, uint256 _uniswapInitialWei, uint256 _uniswapInitialTokens) public payable onlyOwner {
        require(IERC20(_optionAddress).getMaturity() < block.timestamp, "Expired option");
        require(!options[_optionAddress].isValid, "Already activated");
        require(msg.value == _collateral.add(_uniswapInitialWei), "Invalid value");
        
        options[_optionAddress].isValid = true;

        IERC20(_optionAddress).mint(address(this), _uniswapInitialTokens);
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        
        seller.isValid = true;
        seller.collateral = _collateral;
        seller.notional = 0;
    
        uint256 totalUSDT = sellEthForUSDTInUniswap(_uniswapInitialWei);
        
        //createPairInUniswap(_optionAddress, _uniswapInitialTokens, totalUSDT);
    }
    
    function _activateOption3(address _optionAddress, uint256 _collateral, uint256 _uniswapInitialWei, uint256 _uniswapInitialTokens) public payable onlyOwner {
        require(IERC20(_optionAddress).getMaturity() < block.timestamp, "Expired option");
        require(!options[_optionAddress].isValid, "Already activated");
        require(msg.value == _collateral.add(_uniswapInitialWei), "Invalid value");
        
        options[_optionAddress].isValid = true;

        IERC20(_optionAddress).mint(address(this), _uniswapInitialTokens);
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        
        seller.isValid = true;
        seller.collateral = _collateral;
        seller.notional = 0;
    
        //uint256 totalUSDT = sellEthForUSDTInUniswap(_uniswapInitialWei);
        
        //createPairInUniswap(_optionAddress, _uniswapInitialTokens, totalUSDT);
    }
    
    function _setEthFinalPriceAtMaturity(address _optionAddress) public onlyOwner {
        require(options[_optionAddress].isValid, "Invalid option");
        require(options[_optionAddress].etherPriceInUSDTAtMaturity == 0, "Already set");
        require(IERC20(_optionAddress).getMaturity() > block.timestamp, "Still not expired");
        
        uint256 usdPriceOfEth = uint256(priceConsumer.getLatestPrice());
        uint256 optionWorth = IERC20(_optionAddress).getStrike().sub(usdPriceOfEth);

        options[_optionAddress].etherPriceInUSDTAtMaturity = usdPriceOfEth;
        options[_optionAddress].optionWorth = optionWorth;
    }

    function _withdrawETH(uint256 _amount) public onlyOwner {
        msg.sender.transfer(_amount);
    }
    
    function _withdrawUSDT(uint256 _amount) public onlyOwner {
        require(IERC20(usdtAddress).transfer(msg.sender, _amount), "Transfer failed");
    }

    receive() external payable {
        revert();
    }
    
}