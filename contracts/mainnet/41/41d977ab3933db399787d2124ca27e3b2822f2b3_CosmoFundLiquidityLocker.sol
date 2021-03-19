/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract CosmoFundLiquidityLocker is Ownable {
    using SafeMath for uint256;

    string public constant url = "https://CosmoFund.space/";
    uint256 public constant shareDecimals = 18;
    uint256 public unlockTime = 1648825200;  // 2022-04-01T15:00:00.000Z = 1648825200

    event Balance(address indexed token, uint256 amount);
    event Deposited(address indexed token, uint256 amount);
    event Withdrawn(address indexed token, uint256 amount);


    function balanceOf(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function shareOf(address token) public view returns (uint256) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) return 0;
        uint256 total = IERC20(token).totalSupply();
        return balance.mul(1e18).div(total);
    }

    function deposit(address token, uint256 amount) public onlyOwner {
        bool isTransferred = IERC20(token).transferFrom(_msgSender(), address(this), amount);
        require(isTransferred, "Transfer failed");
        uint256 balance = IERC20(token).balanceOf(address(this));
        emit Deposited(token, amount);
        emit Balance(token, balance);
    }

    function withdraw(address token, uint256 amount) public onlyOwner {
        require(_getNow() > unlockTime, "Too early");
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 newBalance = balance.sub(amount, "Insufficient balance");
        bool isTransferred = IERC20(token).transfer(_msgSender(), amount);
        require(isTransferred, "Transfer failed");
        emit Withdrawn(token, amount);
        emit Balance(token, newBalance);
    }

    function withdrawAll(address token) public onlyOwner {
        require(_getNow() > unlockTime, "Too early");
        uint256 balance = IERC20(token).balanceOf(address(this));
        bool isTransferred = IERC20(token).transfer(_msgSender(), balance);
        require(isTransferred, "Transfer failed");
        emit Withdrawn(token, balance);
        emit Balance(token, 0);
    }

    function setUnlockTime(uint256 newUnlockTime) public onlyOwner {
        require(_getNow() < newUnlockTime, "Too early");
        require(unlockTime < newUnlockTime, "Too early");
        unlockTime = newUnlockTime;
    }

    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }
}