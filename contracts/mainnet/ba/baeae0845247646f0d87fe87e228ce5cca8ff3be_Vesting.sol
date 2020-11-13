pragma solidity 0.6.12;

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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract ERC20 {
    function totalSupply() external virtual view returns (uint256);
    function balanceOf(address account) external virtual view returns (uint256);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
    function allowance(address owner, address spender) external virtual view returns (uint256);
    function approve(address spender, uint256 amount) external virtual returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Vesting {
    using SafeMath for uint256;
    ERC20 token = ERC20(0xAeBCC16DDf84830A163079ea4BC1c5A82819B2fa);
    bool hasDeposited  = false;
    
    address owner;
    uint256 depositedAmount;
    uint256 withdrawnAmount = 0;
    uint256 finalBlock;
    uint256 vested_period;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }
    
    function deposit(uint256 amount, uint256 blocksUntilCompleted) public onlyOwner {
        require(!hasDeposited);
        
        token.transferFrom(msg.sender, address(this), amount);
        
        depositedAmount = amount;
        finalBlock = block.number.add(blocksUntilCompleted);

        vested_period = blocksUntilCompleted;
        
        hasDeposited = true;
    }
    
    function withdraw() public onlyOwner {
        require(hasDeposited);
        
        if(block.number > finalBlock){
            token.transfer(owner, token.balanceOf(address(this)));
            hasDeposited = false;
        } 
        else{
    	    uint256 numerator = depositedAmount.mul(vested_period.sub(finalBlock.sub(block.number)));
            uint256 allowedAmount = numerator.div(vested_period);
            uint256 toWithdraw = allowedAmount.sub(withdrawnAmount);
            
            token.transfer(owner, toWithdraw);
            
            withdrawnAmount = withdrawnAmount.add(toWithdraw);
        }
        
    }
}