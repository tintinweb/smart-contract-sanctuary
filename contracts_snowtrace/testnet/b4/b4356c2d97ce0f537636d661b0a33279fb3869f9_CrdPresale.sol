/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-04
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
}


contract CrdPresale is Owned {

    using SafeMath for uint256;

    bool public isPresaleOpen = true;
    uint public delayTime = 86400;
    uint public presaleStartTime;

    address public MIMTokenAddress = 0x130966628846BFd36ff31a822705796e8cb8C18D;//is address mainToken, MIM
    
    uint256 public minMIMLimit = 1 * (10 ** 18);
    uint256 public maxMIMLimit = 800 * (10 ** 18);
    uint256 public totalMIMAmount = 0;
    
    address public presaleTokenAddress;
    // uint256 public presaleTokenDecimal = 9;
    
    address private recipient;

    uint256 public tokenPrice = 1 * (10 ** 18);
    uint256 public tokenPriceDecimal = 18;

    uint256 public tokenSold = 0;

    mapping(address => bool) public whiteListed;
    mapping(address => bool) private participater;
    mapping(address => uint256) private _paidTotal;

    event Presale(uint amount);
    event claimed(address receiver, uint amount);

    constructor(address _recipient, address _presaleTokenAddress) {
        recipient = _recipient;
        presaleTokenAddress = _presaleTokenAddress;
    }

    function setMinMIMLimit(uint256 amount) external onlyOwner {
        minMIMLimit = amount;    
    }

    function setMaxMIMLimit(uint256 amount) external onlyOwner {
        maxMIMLimit = amount;    
    }

    function setPresaleTokenAddress(address _presaleTokenAddress) external onlyOwner {
        presaleTokenAddress = _presaleTokenAddress;
    }
    
    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function closePresale() external onlyOwner {
        
        isPresaleOpen = false;
    }

    function setPresaleStartTime(uint _presaleStartTime) external onlyOwner {
        presaleStartTime = _presaleStartTime;
    }

    function setDelayTime(uint _delayTime) external onlyOwner {
        delayTime = _delayTime;
    }

    function setTokenPriceInMIM(uint256 price) external onlyOwner {
        tokenPrice = price;
    }

    function setWhitelist(address[] memory addresses, bool value) public onlyOwner{
        for (uint i = 0; i < addresses.length; i++) {
            whiteListed[addresses[i]] = value;
        }
    }

    function buy(uint256 paidAmount) public {
        require(block.timestamp > presaleStartTime, "Presale is not open yet");

        if ( block.timestamp - presaleStartTime <= delayTime){
            require(whiteListed[msg.sender], "You were not registryed");
        }

        require(paidAmount >= minMIMLimit, "You need to sell at least some min amount");
        require(_paidTotal[msg.sender] + paidAmount <= maxMIMLimit, "It was over maxMiaLlimit");
        
        IERC20 token = IERC20(MIMTokenAddress);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= paidAmount, "Check the token allowance");
        token.transferFrom(msg.sender, recipient, paidAmount);

        uint tokenAmount = paidAmount.div(10**18).div(tokenPrice).mul(10**tokenPriceDecimal).mul(10**9);

        require(tokenAmount <= IERC20(presaleTokenAddress).balanceOf(address(this)), "Insufficient balance");
        IERC20(presaleTokenAddress).transfer(msg.sender, tokenAmount);
        
        _paidTotal[msg.sender] += paidAmount;
        participater[msg.sender] = true;
        tokenSold += tokenAmount;
        totalMIMAmount += paidAmount;

        emit Presale(paidAmount);
    }

    function getUnsoldTokens(address to) external onlyOwner {
        require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
        
        IERC20(presaleTokenAddress).transfer(to, IERC20(presaleTokenAddress).balanceOf(address(this)) );
    }
}