/**
 *Submitted for verification at Etherscan.io on 2021-04-08
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

interface StakingDistributor {
    function distribute() external returns ( bool );
}

interface IVault {
    function depositReserves( uint _amount ) external returns ( bool );
}

contract OlympusSalesLite {
    
    using SafeMath for uint;
    
    address public owner;

    address public constant SUSHISWAP_ROUTER_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    IUniswapV2Router02 public sushiswapRouter;

    uint public OHMToSell; // OHM sold per epoch ( 9 decimals )
    uint public minimumToReceive; // Minimum DAI from sale ( 18 decimals )
    uint public OHMToSellNextEpoch; // Setter to change OHMToSell

    uint public nextEpochBlock; 
    uint public epochBlockLength;

    address public OHM;
    address public DAI;
    address public stakingDistributor; // Receives new OHM
    address public vault; // Mints new OHM

    address public DAO; // Receives a share of new OHM
    uint public DAOShare; // % = ( 1 / DAOShare )

    bool public salesEnabled;

    constructor( 
        address _OHM, 
        address _DAI, 
        address _DAO,
        address _stakingDistributor, 
        address _vault, 
        uint _nextEpochBlock,
        uint _epochBlockLength,
        uint _OHMTOSell,
        uint _minimumToReceive,
        uint _DAOShare
    ) {
        owner = msg.sender;
        sushiswapRouter = IUniswapV2Router02( SUSHISWAP_ROUTER_ADDRESS );
        OHM = _OHM;
        DAI = _DAI;
        vault = _vault;

        OHMToSell = _OHMTOSell;
        OHMToSellNextEpoch = _OHMTOSell;
        minimumToReceive = _minimumToReceive;

        nextEpochBlock = _nextEpochBlock;
        epochBlockLength = _epochBlockLength;

        DAO = _DAO;
        DAOShare = _DAOShare;
        stakingDistributor = _stakingDistributor;
    }

    // Swaps OHM for DAI, then mints new OHM and sends to distributor
    // uint _triggerDistributor - triggers staking distributor if == 1
    function makeSale( uint _triggerDistributor ) external returns ( bool ) {
        require( salesEnabled, "Sales are not enabled" );
        require( block.number >= nextEpochBlock, "Not next epoch" );

        IERC20(OHM).approve( SUSHISWAP_ROUTER_ADDRESS, OHMToSell );
        sushiswapRouter.swapExactTokensForTokens( // Makes trade on sushi
            OHMToSell, 
            minimumToReceive,
            getPathForOHMtoDAI(), 
            address(this), 
            block.timestamp + 15
        );
        
        uint daiBalance = IERC20(DAI).balanceOf(address(this) );
        IERC20( DAI ).approve( vault, daiBalance );
        IVault( vault ).depositReserves( daiBalance ); // Mint OHM

        uint OHMToTransfer = IERC20(OHM).balanceOf( address(this) ).sub( OHMToSellNextEpoch );
        uint transferToDAO = OHMToTransfer.div( DAOShare );

        IERC20(OHM).transfer( stakingDistributor, OHMToTransfer.sub( transferToDAO ) ); // Transfer to staking
        IERC20(OHM).transfer( DAO, transferToDAO ); // Transfer to DAO

        nextEpochBlock = nextEpochBlock.add( epochBlockLength );
        OHMToSell = OHMToSellNextEpoch;

        if ( _triggerDistributor == 1 ) { 
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

    // Turns sales on or off
    function toggleSales() external returns ( bool ) {
        require( msg.sender == owner, "Only owner" );
        salesEnabled = !salesEnabled;
        return true;
    }

    // Sets sales rate one epoch ahead
    function setOHMToSell( uint _amount, uint _minimumToReceive ) external returns ( bool ) {
        require( msg.sender == owner, "Only owner" );
        OHMToSellNextEpoch = _amount;
        minimumToReceive = _minimumToReceive;
        return true;
    }

    // Sets the DAO profit share ( % = 1 / share_ )
    function setDAOShare( uint _share ) external returns ( bool ) {
        require( msg.sender == owner, "Only owner" );
        DAOShare = _share;
        return true;
    }

    function transferOwnership( address _newOwner ) external returns ( bool ) {
        require( msg.sender == owner, "Only owner" );
        owner = _newOwner;
        return true;
    }
}