/**
 *Submitted for verification at snowtrace.io on 2021-11-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

/**

 * Standard SafeMath, stripped down to just add/sub/mul/div

*/

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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

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
interface IMasterChef {
    function transferOwnership(address newOwner) external; 
}

interface IARC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IDEXRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external payable returns (uint amountA, uint amountB, uint liquidity);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract AvacosTimelockAndLiquidityAdder {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    
    IDEXRouter public router;
    
    address private WAVAX;
    address public dev;
    address public token_address;
    address public MasterChef;
    
    uint256 public MinAmountToLiquidity;
    uint256 public unlockTimestamp;


    constructor (address _token_address, address _router) {
        dev = msg.sender;
        token_address = address(_token_address);
        router = IDEXRouter(_router);
        WAVAX = router.WAVAX();
        IARC20(token_address).approve(_router, uint256(-1));
    }
    

    // Dev can Update UnlockTimestamp but 1 Day is Minimum.
    function updateUnlockTimestamp(uint8 _days) external {
        require(msg.sender == dev, 'Access denied');
        require(_days > 0, 'Minimum 1 Day to claim back Ownership');  // Minimum 1. Day to claim back the Ownership!
        unlockTimestamp = block.timestamp + 60 * 60 * 24 * _days; 
    }
    
    
    // If unwanted tokens land here, there is the possibility to send them with the transferFrom function.
    function approveToken(address _token, address _spender) public {
        require(msg.sender == dev, 'Access denied');
        IARC20(_token).approve(_spender, uint256(-1));
    }

    // Here the masterchef address can be set.
    function setMasterChef(address _MasterChefAddress) public {
        require(msg.sender == dev, 'Access denied');
        MasterChef = _MasterChefAddress;  
    }
    
    function setMinAmountToLiquidity(uint256 _amount) public {
        require(msg.sender == dev, 'Access denied');
        MinAmountToLiquidity = _amount;
    }
    
    function shouldLiquidy() public view returns (bool){
        uint256 balance = IARC20(token_address).balanceOf(address(this));
        if (balance > MinAmountToLiquidity){
            return true;
        }
        return false;
    }
    
    function getTokenBalance(address _token) public view returns (uint256) {
        return IARC20(_token).balanceOf(address(this));
    }
    
    function changeDev(address _dev) public {
        require(msg.sender == dev, 'Access denied');
        dev = _dev;
    }
    
    function changeMasterChefOwner(address _dev) public {
        require(msg.sender == dev, 'Access denied');
        require(block.timestamp > unlockTimestamp, "Masterchef under Timelock");
        IMasterChef(MasterChef).transferOwnership(_dev);
    }
    
    // All Avaco tokens on this address will be added to liquity here.
    function liquidityAdding() public {
        bool should = shouldLiquidy();
        if (should) {
            uint256 amountToSwap = IARC20(token_address).balanceOf(address(this)).div(2);
            AVAXliquidityAdd(amountToSwap); // 50% of all tokens on This address get in AVAX liquidity Pool.
            USDCliquidityAdd(amountToSwap); // 50% of all tokens on This address get in USDC liquidity Pool.
        }
        
    }
    

    function AVAXliquidityAdd(uint256 _amountToSwap) internal {
        uint256 amountToSwap = _amountToSwap.div(2);
        address[] memory path = new address[](2);
        path[0] = token_address;
        path[1] = WAVAX;
        uint256 balanceBefore = IARC20(WAVAX).balanceOf(address(this));
        
        router.swapExactTokensForTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountWAVAX = IARC20(WAVAX).balanceOf(address(this)).sub(balanceBefore);
        router.addLiquidity(
            token_address,
            WAVAX,
            amountToSwap,
            amountWAVAX,
            0,
            0,
            address(0x000000000000000000000000000000000000dEaD), // received LP Supply get instand to DEAD address!
            block.timestamp
        );
    }

    function USDCliquidityAdd(uint256 _amountToSwap) internal {
        uint256 amountToSwap = _amountToSwap.div(2);
        address USDC = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
        address[] memory path = new address[](2);
        path[0] = token_address;
        path[1] = USDC;
        uint256 balanceBefore = IARC20(USDC).balanceOf(address(this));
        
        router.swapExactTokensForTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountUSDC= IARC20(USDC).balanceOf(address(this)).sub(balanceBefore);
        router.addLiquidity(
            token_address,
            USDC,
            amountToSwap,
            amountUSDC,
            0,
            0,
            address(0x000000000000000000000000000000000000dEaD), // received LP Supply get instand to DEAD address!
            block.timestamp
        );
    }

}