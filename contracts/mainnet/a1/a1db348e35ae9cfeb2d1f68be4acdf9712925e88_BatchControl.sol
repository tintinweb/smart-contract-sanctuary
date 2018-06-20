pragma solidity ^0.4.21;

contract holder {
    function onIncome() public payable; 
}

contract BatchControl {

    mapping (address => uint256) public allowed;
    address public owner;
    uint256 public price;
    holder public holderContract;

    event BUY(address buyer, uint256 amount, uint256 total);
    event HOLDER(address holder);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(uint256 _price) public {
        owner = msg.sender;
        allowed[owner] = 1000000;
        price = _price;
    }
    
    function withdrawal() public {
        owner.transfer(address(this).balance);
    }
    
    function buy(uint256 amount) payable public {
        uint256 total = price * amount;
        assert(total >= price);
        require(msg.value >= total);
        
        allowed[msg.sender] += amount;
        
        if (holderContract != address(0)) {
            holderContract.onIncome.value(msg.value)();
        }
        emit BUY(msg.sender, amount, allowed[msg.sender]);
    }
    
    function setPrice(uint256 _p) onlyOwner public {
        price = _p;
    }
    
    function setHolder(address _holder) onlyOwner public {
        holderContract = holder(_holder);
        
        emit HOLDER(_holder);
    }
}