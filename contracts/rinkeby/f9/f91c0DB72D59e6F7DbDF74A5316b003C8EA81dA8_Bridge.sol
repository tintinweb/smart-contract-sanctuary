/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

pragma solidity ^0.5.0;

interface IMCS {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function mint (address to, uint256 quantity) external;
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

contract Bridge {
    using SafeMath for uint256;
    mapping (address => bool) public IS_RELAYER;
    address public TOKEN_ADDRESS;
    
    event Deposit(address indexed sender, uint256 quantity, uint256 targetChain);
    event Release(address indexed receiver, uint256 quantity, uint256 originChain);
    
    modifier RelayerOnly () {
        require (IS_RELAYER[msg.sender], "Only Relayer can do");
        _;
    }
    
    constructor (address tokenAddress, address relayer) public {
        TOKEN_ADDRESS = tokenAddress;
        IS_RELAYER[relayer] = true;
    }

    function depositToken (uint256 quantity, uint256 targetChain) public {
        IMCS tokenObj = IMCS(TOKEN_ADDRESS);
        
        uint256 balanceBefore = tokenObj.balanceOf(address(this));
        tokenObj.transferFrom(msg.sender, address(this), quantity);
        uint256 balanceAfter = tokenObj.balanceOf(address(this));
        require(balanceBefore + quantity == balanceAfter, "Old token isnt arrived");
        
        emit Deposit(msg.sender, quantity, targetChain);
    }
    
    function releaseTokens (address[] memory to, uint256[] memory quantity, uint256[] memory originChain) public RelayerOnly {
        uint256 totalDemand = 0;
        for(uint8 i=0; i < to.length; i++){
            totalDemand = totalDemand.add(quantity[i]);
        }
        
        IMCS tokenObj = IMCS(TOKEN_ADDRESS);
        uint256 tokenBalance = tokenObj.balanceOf(address(this));
        if(tokenBalance < totalDemand){
            uint256 mintQuantity = totalDemand - tokenBalance;
            tokenObj.mint(address(this), mintQuantity);
        }
        
        for(uint8 i=0; i < to.length; i++){
            tokenObj.transfer(to[i], quantity[i]);
            emit Release(to[i], quantity[i], originChain[i]);
        }
    }
}