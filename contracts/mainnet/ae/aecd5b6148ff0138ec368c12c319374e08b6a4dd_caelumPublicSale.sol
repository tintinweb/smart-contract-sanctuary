/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.4.25;


library SafeMath {

  function add(uint a, uint b) internal pure returns (uint c) {

    c = a + b;

    require(c >= a);

  }

  function sub(uint a, uint b) internal pure returns (uint c) {

    require(b <= a);

    c = a - b;

  }

  function mul(uint a, uint b) internal pure returns (uint c) {

    c = a * b;

    require(a == 0 || c / a == b);

  }

  function div(uint a, uint b) internal pure returns (uint c) {

    require(b > 0);

    c = a / b;

  }

}

contract caelumPublicSale {
    using SafeMath for uint;
    
    
    uint public ethPrice;
    uint public lastPriceChange;
    uint public maxCap = 750000000000000000000;
    uint bought;
    bool public isRunning = true;
    uint public endDate;
    
    address[] candidates;
    mapping(address => uint) public balances;
    mapping(address => uint) public balances_clmp;
    
    address private owner;
    
    uint public promoUsers = 0;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        ethPrice = 600000000000000;
        lastPriceChange = now;
        endDate = now + 180 days;
        owner = msg.sender;
    }
    
    
    /**
     *  Minimal funding solution. The user get&#39;s added to our list, who will be inserted on mainnet genesis block.
     *  A minimum of 250000000000000000 Wei is required (0.25 ETH) to participate.
     */
    function purchase() public payable returns (bool success) {
        
        require(isRunning, &#39;unning issie&#39;);
        require(now < endDate, &#39;date isse&#39;);
        require(bought.add(msg.value) <= maxCap, &#39;cap issue&#39;);
        
        require(msg.value > 0);
        require(msg.value >= 250000000000000000);
        
        
        if (balances_clmp[msg.sender] == 0) {
            candidates.push(msg.sender);
        }
        
        if (promoUsers < 5 ) {
            if (getRatio(msg.value) == 50000) {
                balances_clmp[msg.sender] += getRatio(msg.value).add(25000);
                promoUsers++;
            }
        } else {
            balances_clmp[msg.sender] += getRatio(msg.value);
            
        }
        
        balances[msg.sender] += msg.value;
        bought = bought + msg.value;
        
        return true;
    }
    
    
    /**  
     *  Allows the developer to change the USD ratio with limitations:
     * 
     *  Limits: Max 10% up or down of current value 
     *  Limits: Can be executed once every 3 days to counteract price fluctuations
     * 
     */
    
    function setEtherRatio(uint RatioInWei) onlyOwner public {
        require (lastPriceChange < (now - 3 days));
        
        uint _min = getMinPrice();
        uint _max = getMaxPrice();
        
        require (RatioInWei >= _min && RatioInWei <= _max);
        ethPrice = RatioInWei;
    }
    
    function closeContract() onlyOwner public {
        require(isRunning);
        isRunning = false;
    }
    
    function getMaxPrice() public view returns(uint MaxWei) {
        uint max = ethPrice.div(10);
        return ethPrice.add(max);
    }
    
    function getMinPrice() public view returns (uint MinWei) {
        uint max = ethPrice.div(10);
        return ethPrice.sub(max);
    }
    
    function getCandidates() public view returns(address[]) {
        return candidates;
    }
    
    function getRatio(uint valInWei) public view returns(uint) {
        return valInWei / ethPrice;
    }
    
    function withdraw(uint amount) public onlyOwner returns(bool) {
        require(amount <= address(this).balance);
        owner.transfer(amount);
        return true;
    }
}