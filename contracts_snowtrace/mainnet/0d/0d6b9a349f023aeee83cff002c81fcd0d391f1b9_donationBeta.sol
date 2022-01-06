/**
 *Submitted for verification at snowtrace.io on 2022-01-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}


interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


abstract contract Owned {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


contract donationBeta is Owned {

    using SafeMath for uint256;

    struct UsersSaleInfo {
        address buyer;
        uint balance;
    }


    address public TokenAddress = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address public pTokenAddress;
    uint256 public pTokenDecimal = 9;
    address private recipient;
    uint256 public tokenSold = 0;
    uint256 public totalMIMAmount = 0;
    uint256 public minMimLimit = 50 * (10 ** 18);
    uint256 public tokenPrice = 1 * (10 ** 18);
    mapping(address => uint256) private _paidTotal;
    mapping(address => UsersSaleInfo) public usersSaleInfo; // This could be a mapping by address, but these numbered lockBoxes support possibility of multiple tranches per address

    event Presale(uint amount);
    event claimed(address receiver, uint amount);

    constructor(address _recipient, address _pTokenAddress) {
        recipient = _recipient;
        pTokenAddress = _pTokenAddress;
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function setPresaleTokenAddress(address _pTokenAddress) external onlyOwner {
        pTokenAddress = _pTokenAddress;
    }


    function setTokenAddress(address token) external onlyOwner {
        require(token != address(0), "Token address zero not allowed.");

        TokenAddress = token;
    }


    function setMinMimLimit(uint256 amount) external onlyOwner {
        minMimLimit = amount;    
    }


    function buy(uint256 paidAmount) public {
        require(paidAmount > minMimLimit, "You need to sell at least some min amount");
        IERC20 token = IERC20(TokenAddress);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= paidAmount, "Check the token allowance");
        token.transferFrom(msg.sender, recipient, paidAmount);

        uint tokenAmount = paidAmount.div(tokenPrice).mul(10**pTokenDecimal);
        if (usersSaleInfo[msg.sender].buyer == address(0)) {
            UsersSaleInfo memory l;
            l.buyer = msg.sender;
            l.balance = tokenAmount;
            usersSaleInfo[msg.sender] = l;
        }
        else {
            usersSaleInfo[msg.sender].balance += tokenAmount;
        }

        _paidTotal[msg.sender] += paidAmount;
        tokenSold += tokenAmount;
        totalMIMAmount += paidAmount;

        emit Presale(paidAmount);
    }


}