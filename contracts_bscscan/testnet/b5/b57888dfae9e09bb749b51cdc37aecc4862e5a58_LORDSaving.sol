/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

/*
OVERLORD - The World's First NFT-Integrated Mobile RPG

Website: https://overlord.world
Announcements: https://t.me/OverlordAnn
Telegram: https://t.me/overlordbsc
Twitter: https://twitter.com/overlordbsc
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "add: +");

        return c;
    }

    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "sub: -");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "mul: *");

        return c;
    }

    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "div: /");
    }

    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "mod: %");
    }

    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
}

// y = f(x)

// 5 = f(10)
// 185 = f(365)
//y = A^x - X
//y = 1.87255 + 0.2985466*x + 0.001419838*x^2


interface SavingInterface {
    function votingPowerOf(address acc, uint256 until) external view returns(uint256);
}

contract LORDSaving is Ownable, SavingInterface {
    using SafeMath for uint256;
    IERC20 public LORD;

    bool isClosed = false;

    // quadratic reward curve constants
    // a + b*x + c*x^2
    uint256 public A = 187255; // 1.87255
    uint256 public B = 29854;  // 0.2985466*x
    uint256 public C = 141;    // 0.001419838*x^2

    uint256 public maxDays = 365;
    uint256 public minDays = 0;

    uint256 public totalSaved = 0;
    uint256 public totalRewards = 0;

    uint256 public earlyExit = 0;

    struct SaveInfo {
        uint256 reward;
        uint256 initial;
        uint256 payday;
        uint256 startday;
    }

    mapping (address=>SaveInfo) public saves;

    constructor(address _LORD) public {
        LORD = IERC20(_LORD);
    }

    function deposit(uint256 _amount, uint256 _days) public {
        require(_days > minDays, "less than minimum saving period");
        require(_days < maxDays, "more than maximum saving period");
        require(saves[msg.sender].payday == 0, "already saved");
        require(_amount > 100, "amount to small");
        require(!isClosed, "saving is closed");

        // calculate reward
        uint256 _reward = calculateReward(_amount, _days);

        // contract must have funds to keep this commitment
        require(LORD.balanceOf(address(this)) > totalOwedValue().add(_reward).add(_amount), "insufficient contract bal");

        require(LORD.transferFrom(msg.sender, address(this), _amount), "transfer failed");

        saves[msg.sender].payday = block.timestamp.add(_days * (1 days));
        saves[msg.sender].reward = _reward;
        saves[msg.sender].startday = block.timestamp;
        saves[msg.sender].initial = _amount;

        // update stats
        totalSaved = totalSaved.add(_amount);
        totalRewards = totalRewards.add(_reward);
    }

    function withdraw() public {
        require(owedBalance(msg.sender) > 0, "nothing to withdraw");
        require(block.timestamp > saves[msg.sender].payday.sub(earlyExit), "too early");

        uint256 owed = saves[msg.sender].reward.add(saves[msg.sender].initial);

        // update stats
        totalSaved = totalSaved.sub(saves[msg.sender].initial);
        totalRewards = totalRewards.sub(saves[msg.sender].reward);

        saves[msg.sender].initial = 0;
        saves[msg.sender].reward = 0;
        saves[msg.sender].payday = 0;
        saves[msg.sender].startday = 0;

        require(LORD.transfer(msg.sender, owed), "transfer failed");
    }

    function calculateReward(uint256 _amount, uint256 _days) public view returns (uint256) {
        uint256 _multiplier = _quadraticRewardCurveY(_days);
        uint256 _AY = _amount.mul(_multiplier);
        return _AY.div(10000000);

    }

    // a + b*x + c*x^2
    function _quadraticRewardCurveY(uint256 _x) public view returns (uint256) {
        uint256 _bx = _x.mul(B);
        uint256 _x2 = _x.mul(_x);
        uint256 _cx2 = C.mul(_x2);
        return A.add(_bx).add(_cx2);
    }

    // helpers:
    function totalOwedValue() public view returns (uint256) {
        return totalSaved.add(totalRewards);
    }

    function owedBalance(address acc) public view returns(uint256) {
        return saves[acc].initial.add(saves[acc].reward);
    }

    function votingPowerOf(address acc, uint256 until) external override view returns(uint256) {
        if (saves[acc].payday > until) {
            return 0;
        }

        return owedBalance(acc);
    }

    // owner functions:
    function setLimits(uint256 _minDays, uint256 _maxDays) public onlyOwner {
        minDays = _minDays;
        maxDays = _maxDays;
    }

    function setCurve(uint256 _A, uint256 _B, uint256 _C) public onlyOwner {
        A = _A;
        B = _B;
        C = _C;
    }

    function setEarlyExit(uint256 _earlyExit) public onlyOwner {
        require(_earlyExit < 2880000, "too big");
        close(true);
        earlyExit = _earlyExit;
    }

    function close(bool closed) public onlyOwner {
        isClosed = closed;
    }

    function ownerRewithdraw(uint256 _amount) public onlyOwner {
        require(_amount < LORD.balanceOf(address(this)).sub(totalOwedValue()), "cannot withdraw owed funds");
        LORD.transfer(msg.sender, _amount);
    }

    function flushBNB() public onlyOwner {
        uint256 bal = address(this).balance.sub(1);
        msg.sender.transfer(bal);
    }

}