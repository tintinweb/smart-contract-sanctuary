pragma solidity ^0.4.22;


contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract DarkPool is Ownable {
    ERC20Basic hodl;
    uint public end;
    uint public raised;
    uint public cap;
    mapping(address => uint) public balances;
    event Deposit(address indexed beneficiary, uint value);
    event Withdraw(address indexed beneficiary, uint value);

    function () external payable whenActive {
        require(whitelisted(msg.sender), "for hodl owners only");
        raised += msg.value;
        balances[msg.sender] += msg.value;
        require(raised <= cap, "raised too much ether");
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(address beneficiary) external onlyOwner whenEnded {
        uint balance = address(this).balance;
        beneficiary.transfer(balance);
        emit Withdraw(beneficiary, balance);
    }
    
    function reclaimToken(ERC20Basic token) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }
    
    function whitelisted(address _address) public view returns (bool) {
        return hodl.balanceOf(_address) > 0;
    }
    
    function active() public view returns (bool) {
        return now < end;
    }
    
    modifier whenEnded() {
        require(!active());
        _;
    }
    
    modifier whenActive() {
        require(active());
        _;
    }
}

contract DarkPool1 is DarkPool {
    constructor() public {
        hodl = ERC20Basic(0x433e077D4da9FFC4b353C1Bf1eD69DAAc8f78aA5);
        end = 1524344400;
        cap = 600 ether;
    }
}