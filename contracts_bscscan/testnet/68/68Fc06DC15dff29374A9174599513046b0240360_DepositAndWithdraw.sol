/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

pragma solidity ^0.8.6;
//SPDX-License-Identifier:MIT

interface IBEP20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external;
    function transfer(address to, uint value) external;
    function transferFrom(address from, address to, uint value) external;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

contract DepositAndWithdraw{
    
    using SafeMath for uint256;
    
    IBEP20 public token;
    address public owner;
    
    uint256 idCounter;
    
    mapping(address => uint256[]) public userIds;
    mapping(address => mapping(uint256 => uint256)) public userDeposits;
    
    event Deposit(address indexed user, uint256 indexed amount, uint256 indexed id);
    event Withdraw(address indexed user, uint256 indexed amount, uint256 indexed id);
    
    constructor(address payable _owner, IBEP20 _token) {
        owner =_owner;
        token = _token;
    }
    
    function deposit(uint256 _amount) public {
        
        token.transferFrom(msg.sender, owner, _amount);
        userDeposits[msg.sender][++idCounter] = _amount;
        userIds[msg.sender].push(idCounter);
        
        emit Deposit(msg.sender, _amount, idCounter);
    }
    
    function withdraw(uint256 _id) public {
        uint256 balance = userDeposits[msg.sender][_id];
        require(balance > 0,"Deposit not exist");
        token.transferFrom(owner, msg.sender, balance);
        userDeposits[msg.sender][_id] = 0;
        
        emit Withdraw(msg.sender, balance, _id);
    }
    
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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