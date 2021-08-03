pragma solidity ^0.5.16;

import "./BEP20Token.sol";

contract BMFTokenSale{
    address payable private owner;
    
    IBEP20 BMF = IBEP20(0x4c0Ea638e95A5FB7D85b453b944caf8c668e198D);
    uint public tokenPrice;
    uint public tokensSold;
    address[] public buyers;
    uint public maxbuy;
    uint public minbuy;
    
    mapping (address => uint) public buyamount;
    mapping (address => bool) public hasBuyed;
    
    event Sell(address _buyer, uint _amount);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setMaxBuy(uint _maxbuy) public onlyOwner {
        require (msg.sender == owner);
        maxbuy = _maxbuy;
    }
    
     function setMinBuy(uint _minbuy) public onlyOwner {
        require (msg.sender == owner);
        minbuy = _minbuy;
    }
    
    function setTokenPrice(uint _tokenPrice) public onlyOwner {
        require (msg.sender == owner);
        tokenPrice = _tokenPrice;
    }
    
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    
    function buyTokens(uint _numberOfTokens) public payable {
        require(msg.value == mul(_numberOfTokens, tokenPrice));
        require(BMF.balanceOf(address(this)) >= _numberOfTokens);
        require(buyamount[msg.sender] <= maxbuy);
        require(_numberOfTokens >= minbuy);
        
        if((buyamount[msg.sender] + _numberOfTokens) > maxbuy) {
            revert("The purchase amount cannot more than Max Buy");
        } else {
            buyamount[msg.sender] = buyamount[msg.sender] + _numberOfTokens;
        }
        
        if(!hasBuyed[msg.sender]) {
            buyers.push(msg.sender);
        }
        
        tokensSold += _numberOfTokens;
        hasBuyed[msg.sender] = true;
        
        emit Sell(msg.sender, _numberOfTokens);
    }
    
    function transfer() public onlyOwner {
        require (msg.sender == owner);
        uint balance = address(this).balance;
        owner.transfer(balance);
    }
    
    function distribute() public onlyOwner {
        require (msg.sender == owner);
        for (uint i=0; i < buyers.length; i++) {
            address recipient = buyers[i];
            uint balance = mul(buyamount[recipient], 10**18);
            if(balance > 0) {
                BMF.transfer(recipient, balance);
            }
        }
    }
    
    function endSale () public onlyOwner {
        require (msg.sender == owner);
        require (BMF.transfer(owner, BMF.balanceOf(address(this))));
        
        selfdestruct(owner);
    }
}