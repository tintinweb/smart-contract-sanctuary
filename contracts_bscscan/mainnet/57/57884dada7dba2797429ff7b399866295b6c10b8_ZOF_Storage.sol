/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {

    function balanceOf(address account) external view returns (uint256);

    function allowance(address _owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool ok);
}

contract ZOF_Storage {
    using SafeMath for uint256;

    IBEP20 private TOKEN;  
    IBEP20 private ALTOKEN;
    string public nameContract;
    address payable public owner;
    
    event tokensDep(address indexed user, uint256 amountDep, uint256 date);
    event tokensWith(address indexed user, uint256 amountWith, uint256 date);


    constructor(
        address _TOKEN 
    ) public {
        owner = msg.sender;
        TOKEN = IBEP20(_TOKEN);
        nameContract = "Storage Of ZO FUND";
    }


    function deposit(uint256 Amounts) public {
        uint256 amount = Amounts;
        TOKEN.transferFrom(msg.sender, address(this), amount);
        emit tokensDep(msg.sender, amount, now);
    }

    function withdrawZOF(uint256 Amounts) public {
        require(msg.sender == owner, "Only owner allowed");
        uint256 amount = Amounts.mul(10**18);
        require(TOKEN.balanceOf(address(this)) >= amount, "Insufficient balance");
        TOKEN.transfer(owner, amount);
        emit tokensWith(owner, amount, now);
    }


    function withdrawSelect(address payable SeTOKEN, uint256 Amounts) public {
        require(msg.sender == owner, "Only owner allowed");
        ALTOKEN = IBEP20(SeTOKEN);
        uint256 amount = Amounts.mul(10**18);
        require(ALTOKEN.balanceOf(address(this)) >= amount, "Insufficient balance");
        ALTOKEN.transfer(owner, amount);
        emit tokensWith(owner, amount, now);
    }


    function changeOwner(address payable _owner) public {
        require(msg.sender == owner, "Only owner allowed");
        owner = _owner;
    }
}