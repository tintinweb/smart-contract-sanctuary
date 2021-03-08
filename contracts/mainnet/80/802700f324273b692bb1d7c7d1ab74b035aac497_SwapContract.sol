/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

//SPDX-License-Identifier: GNU GPLv3
pragma solidity ^0.7.0;

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

contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SwapContract is Ownable {
    using SafeMath for uint256;

    IERC20 public OldToken;
    IERC20 public NewToken;
    uint256 public Decimals;

    uint BasisPoints = 10**9;

    constructor(address OldTokenAddress, address NewTokenAddress ) public{
         OldToken = IERC20(OldTokenAddress);
        NewToken = IERC20(NewTokenAddress);
        Decimals = 9;
    }

    function withdraw(IERC20 token) public onlyOwner {
        token.transfer(address(owner()), token.balanceOf(address(this)));
    }

    function swapTokens() hasApprovedTransfer public {

        uint tokenBalance = OldToken.balanceOf(msg.sender);
        uint totalSupply = OldToken.totalSupply();
        uint supplyPercentage = tokenBalance.mul(BasisPoints).div(totalSupply);
        require(supplyPercentage > 0, "Must have larger balance to swap");

        uint approvedTokenAmount = OldToken.allowance(msg.sender, address(this));
        require(approvedTokenAmount >= tokenBalance, "Insufficient Tokens approved for transfer");

        uint newTokenSupply = NewToken.totalSupply();
        uint supplyTokenBasis = newTokenSupply.div(BasisPoints);
        uint tokensToTransfer = supplyTokenBasis * supplyPercentage;

        uint newTokenBalance = NewToken.balanceOf(address(this));
        require(tokensToTransfer <= newTokenBalance, "Insufficient Tokens tokens on contract to swap");

        require(OldToken.transferFrom(msg.sender, address(this), tokenBalance));
        NewToken.transfer(msg.sender, tokensToTransfer);
    }

    modifier hasApprovedTransfer() {
        require(OldToken.allowance(msg.sender, address(this)) > 0, "Tokens not approved for transfer");
        _;
    }
}