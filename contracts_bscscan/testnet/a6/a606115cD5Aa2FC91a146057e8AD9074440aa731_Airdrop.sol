/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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
        _transferOwnership(address(0));
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Airdrop is Context, Ownable{
    using SafeMath for uint256;

    mapping (address => bool) public _isEligible;
    mapping(address => bool) public _hasClaimed;

    uint256 public airdropAmount;
    address public kishimoto;
    uint256 public totalEligibleUser = 0;

    constructor(uint256 _airdropAmount, address _kishimoto) {
        airdropAmount = _airdropAmount;
        kishimoto = _kishimoto;
    }

    function updateEligibility(address account, bool isEligible) external onlyOwner() {
        require(_isEligible[account] != isEligible, "eligibilty is already set to this");
        _isEligible[account] = isEligible;
        if(isEligible){
            totalEligibleUser = totalEligibleUser.add(1);
        } else{
            totalEligibleUser = totalEligibleUser.sub(1);
        }
    }

    function setMultipleEligible(address[] memory accounts) external onlyOwner() {
        uint256 count = accounts.length;
        totalEligibleUser = totalEligibleUser.add(count);
        for(uint256 i = 0; i< count; i++) {
            _isEligible[accounts[i]] = true;
        }
    }

    function claim() external {
        require(_isEligible[_msgSender()], "Not eligible for Airdrop");
        require(!_hasClaimed[_msgSender()], "Already claimed");

        _hasClaimed[_msgSender()] = true;

        IERC20(kishimoto).transfer(_msgSender(),airdropAmount);
    }

    function withdrawUnclaimedToken(address to, uint256 amount) external onlyOwner() {
        IERC20(kishimoto).transfer(to,amount);
    }

    function updateAirdropAmount(uint256 amount) external onlyOwner() {
        airdropAmount = amount;
    }

}