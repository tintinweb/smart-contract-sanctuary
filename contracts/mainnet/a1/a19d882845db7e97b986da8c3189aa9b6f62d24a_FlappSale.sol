pragma solidity ^0.6.0;

import "./FLAPP.sol";

contract FlappSale {
    
    using SafeMath for uint256;
    
    address payable public owner;
    uint256 public price;
    uint256 public maxprice;
    uint256 public increment;
    uint256 public totalFlappsforSale;
    uint256 public remainingFlappsforSale;
    uint256 public maxperBuy;
    bool public parametersSet;
    FLAPP public flappcontract;
    
    
    mapping(address => uint256) tokensBought;
    
    event FlappsBought(address indexed buyer, uint256 indexed amount, uint256 indexed price);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner is allowed to access this function.");
        _;
    }
    
    constructor (address tokenAddress) public {
        
        flappcontract = FLAPP(tokenAddress);
        owner = msg.sender;
        
    }
    
    
    function setParameters(uint256 minprice, uint256 _maxprice, uint256 flappsforsale, uint256 _maxperBuy) onlyOwner public {
        require(parametersSet == false);
        price = minprice;
        maxprice = _maxprice;
        uint256 spread = maxprice - minprice;
        increment = spread / flappsforsale;
        totalFlappsforSale = flappsforsale;
        remainingFlappsforSale = totalFlappsforSale;
        maxperBuy = _maxperBuy;
        parametersSet = true;
    }
    
    receive() external payable {
        invest();
    }
    
    function invest() payable public{
        
        
        uint256 amount = msg.value;
        
    
        uint256 flaps = amount.div(price);
        
        require(flaps <= remainingFlappsforSale, "Not enough flaps for sale");
        require(flaps <= maxperBuy, "Your amount exceeds the limit per purchase");
        
        uint256 newprice = price.add(flaps.mul(increment));
        
        owner.transfer(address(this).balance);
        require(flappcontract.transfer(msg.sender, flaps));
        emit FlappsBought(msg.sender, flaps, price);
        remainingFlappsforSale -= flaps;
        price = newprice;


    }
    
    function endPresale() onlyOwner public {
        uint256 flaps = flappcontract.balanceOf(address(this));
        require(flappcontract.transfer(owner, flaps));
        remainingFlappsforSale = 0;
    }
    
    
}