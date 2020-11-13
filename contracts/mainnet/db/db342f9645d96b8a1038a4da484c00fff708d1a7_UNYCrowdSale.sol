pragma solidity ^0.6.0;

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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract UNYCrowdSale {
    using SafeMath for uint256;

    address private _owner;

    uint256[] private _phaseGoals = [
        8000000000000000000000,
        17000000000000000000000,
        27000000000000000000000
    ];
    uint256[] private _phasePrices = [40, 30, 20];

    uint8 private _phase = 0;
    uint256 private _raisedAmount = 0; // UNY sent
    bool private _isClose = false;

    IERC20 private _token;

    constructor (address tokenAddr) public {
        _owner = msg.sender;
        _token = IERC20(tokenAddr);
    }

    receive() external payable {
        require(_phase <= 2 && !_isClose, "Crowdfunding is closed");

        uint256 expected = msg.value.mul(_phasePrices[_phase]);
        uint256 totalAmount = _raisedAmount.add(expected);
        require(totalAmount <= _phaseGoals[2], "Not enough remaining tokens");

        _token.transfer(msg.sender, expected);

        _raisedAmount = _raisedAmount.add(expected);
        if (_phase < 2 && _raisedAmount >= _phaseGoals[_phase]) {
            _phase = _phase + 1;
        }
    }

    function setClose(bool status) public returns (bool) {
        require(msg.sender == _owner, "sender is not owner");

        _isClose = status;
        return true;
    }

    function withdrawETH(address payable recipient) public returns (bool) {
        require(msg.sender == _owner, "sender is not owner");

        uint256 balance = address(this).balance;
        if (balance > 0) {
            recipient.transfer(balance);
            return true;
        } else {
            return false;
        }
    }

    function withdrawUNY(address recipient) public returns (bool) {
        require(msg.sender == _owner, "sender is not owner");

        uint256 balance = _token.balanceOf(address(this));
        if (balance > 0) {
            _token.transfer(recipient, balance);
            return true;
        } else {
            return false;
        }
    }
}