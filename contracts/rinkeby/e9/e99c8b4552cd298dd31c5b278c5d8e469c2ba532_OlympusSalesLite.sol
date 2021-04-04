/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.4;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface DAIDistributor {
    function distribute() external returns ( bool );
}

interface StakingDistributor {
    function distribute() external returns ( bool );
}

interface IVault {
    function depositReserves( uint amount_, address reserveToken_ ) external returns ( bool );
}

contract OlympusSalesLite {
    
    using SafeMath for uint;
    
    address public owner;

    address public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapRouter;

    uint public OHMToSell;
    uint public minimumRaise;
    uint public OHMToSellNextEpoch;

    uint public nextEpochBlock;
    uint public epochBlockLength;

    address public OHM;
    address public DAI;
    address public stakingDistributor;
    address public vault;

    bool public salesEnabled;
    bool public triggerDistributor;

    constructor( 
        address OHM_, 
        address DAI_, 
        address stakingDistributor_, 
        address vault_, 
        uint nextEpochBlock_,
        uint epochBlockLength_,
        uint OHMTOSell_ 
    ) {
        owner = msg.sender;
        uniswapRouter = IUniswapV2Router02( UNISWAP_ROUTER_ADDRESS );
        OHM = OHM_;
        DAI = DAI_;
        vault = vault_;
        OHMToSell = OHMTOSell_;
        OHMToSellNextEpoch = OHMToSell;
        stakingDistributor = stakingDistributor_;
        nextEpochBlock = nextEpochBlock_;
        epochBlockLength = epochBlockLength_;
        triggerDistributor = false;
    }

    function makeSale() external returns ( bool ) {
        require( salesEnabled, "Sales are not enabled" );
        require( block.number >= nextEpochBlock, "Not next epoch" );
        nextEpochBlock = nextEpochBlock.add( epochBlockLength );

        IERC20(OHM).approve( UNISWAP_ROUTER_ADDRESS, OHMToSell );
        uniswapRouter.swapExactTokensForTokens( // Makes trade on sushi
            OHMToSell, 
            minimumRaise,
            getPathForOHMtoDAI(), 
            address(this), 
            block.timestamp + 15
        );
        
        uint DAIBalance = IERC20( DAI ).balanceOf(address(this) );

        IERC20( DAI ).approve( vault, DAIBalance );
        IVault( vault ).depositReserves( DAIBalance, DAI ); // Mint OHM

        IERC20(OHM).transfer( stakingDistributor, IERC20(OHM).balanceOf(address(this)).sub( OHMToSellNextEpoch ) ); // Transfer to staking

        OHMToSell = OHMToSellNextEpoch;

        if ( triggerDistributor ) { 
            StakingDistributor( stakingDistributor ).distribute(); // Distribute epoch rebase
        }
        return true;
    }

    function getPathForOHMtoDAI() private view returns ( address[] memory ) {
        address[] memory path = new address[](2);
        path[0] = OHM;
        path[1] = DAI;
        
        return path;
    }

    function toggleSales() external returns ( bool ) {
        require( msg.sender == owner, "Only owner" );
        salesEnabled = !salesEnabled;
        return true;
    }

    function setOHMToSell( uint amount_, uint minimumRaise_ ) external returns ( bool ) {
        require( msg.sender == owner, "Only owner" );
        OHMToSellNextEpoch = amount_;
        minimumRaise = minimumRaise_;
        return true;
    }

    function toggleTriggerDistributor() external returns ( bool ) {
        require( msg.sender == owner, "Only owner" );
        triggerDistributor = !triggerDistributor;
        return true;
    }

    function transferOwnership( address newOwner_ ) external returns ( bool ) {
        require( msg.sender == owner, "Only owner" );
        owner = newOwner_;
        return true;
    }
}