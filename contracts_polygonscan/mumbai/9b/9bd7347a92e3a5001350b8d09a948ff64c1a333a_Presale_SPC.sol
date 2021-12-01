/**
 *Submitted for verification at polygonscan.com on 2021-11-30
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


contract Presale_SPC is Owned {

    using SafeMath for uint256;

    struct UsersSaleInfo {
        address buyer;
        uint balance;
    }

    bool public isPresaleOpen = false;

    address public miaTokenAddress = 0xa3Fa99A148fA48D14Ed51d610c367C61876997F1
;
    address public pTokenAddress;
    uint256 public pTokenDecimal = 9;
    address private recipient;

    uint256 public tokenSold = 0;
    uint256 public totalMIAAmount = 0;

    uint256 public minMiaLimit = 5 * (10 ** 18);
    uint256 public maxMiaLimit = 1000 * (10 ** 18);
    uint256 public tokenPrice = 1 * (10 ** 9);

    mapping(address=>bool) public whiteListed;
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

    function startPresale() external onlyOwner {
        require(!isPresaleOpen, "Presale is open");
        
        isPresaleOpen = true;
    }

    function closePrsale() external onlyOwner {
        require(isPresaleOpen, "Presale is not open yet.");
        
        isPresaleOpen = false;
    }

    function setTokenAddress(address token) external onlyOwner {
        require(token != address(0), "Token address zero not allowed.");

        miaTokenAddress = token;
    }

    function setTokenPriceInMia(uint256 price) external onlyOwner {
        tokenPrice = price;
    }

    function setMinMiaLimit(uint256 amount) external onlyOwner {
        minMiaLimit = amount;    
    }

    function setMaxMiaLimit(uint256 amount) external onlyOwner {
        maxMiaLimit = amount;    
    }

    function setWhitelist(address[] memory addresses, bool value) public onlyOwner{
        for (uint i = 0; i < addresses.length; i++) {
            whiteListed[addresses[i]] = value;
        }
    }

    function buy(uint256 paidAmount) public {
        require(isPresaleOpen, "Presale is not open yet");
        require(whiteListed[msg.sender] == true);
        require(paidAmount > minMiaLimit, "You need to sell at least some min amount");
        require(_paidTotal[msg.sender] + paidAmount <= maxMiaLimit);

        IERC20 token = IERC20(miaTokenAddress);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= paidAmount, "Check the token allowance");
        token.transferFrom(msg.sender, recipient, paidAmount);

        uint tokenAmount = paidAmount.div(tokenPrice).mul(10**pTokenDecimal);

        require(tokenAmount >= IERC20(pTokenAddress).balanceOf(address(this)), "Insufficient balance");
        IERC20(pTokenAddress).transfer(msg.sender, tokenAmount);

        _paidTotal[msg.sender] += paidAmount;
        tokenSold += tokenAmount;
        totalMIAAmount += paidAmount;

        emit Presale(paidAmount);
    }

    function getUnsoldTokens(address to) external onlyOwner {
        require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
        
        IERC20(pTokenAddress).transfer(to, IERC20(pTokenAddress).balanceOf(address(this)) );
    }
}