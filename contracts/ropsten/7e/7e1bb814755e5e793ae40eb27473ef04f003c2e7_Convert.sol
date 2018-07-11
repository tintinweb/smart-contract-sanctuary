pragma solidity ^0.4.24;

contract Convert {
    
    address owner;
    uint256 public price = 50;
    
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    


    function setPrice(uint256 _price) onlyOwner public {
        price = _price;
    }

    function buy(address _addr) payable public {
        uint256 amount = msg.value / price * 100;
        ERC20token token = ERC20token(_addr);
        token.transfer(msg.sender, amount);
    }

    function sell(address _addr,uint256 _amount) public {
        uint256 ethAmount = _amount * price / 100 ether;
        ERC20token token = ERC20token(_addr);
        token.transferFrom(msg.sender, address(this),_amount);

        msg.sender.transfer(ethAmount); // 有漏洞
    }

    
    /* only read */
    
}

contract ERC20token {
    function transfer(address _to, uint256 _tokens) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _tokens) public  returns (bool success);
    
}