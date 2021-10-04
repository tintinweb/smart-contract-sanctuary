/**
 *Submitted for verification at polygonscan.com on 2021-10-04
*/

/**
 *Submitted for verification at Polygonscan.com on 2021-10-04
*/

pragma solidity ^0.4.26; // solhint-disable-line

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract poly_miner  {

    struct pool {
        address token;
        uint eggs_to_match_1miners;
        uint psn;
        uint psnh;
        mapping (address => uint256) hatcheryMiners;
        mapping (address => uint256) claimedEggs;
        mapping (address => uint256) lastHatch;
        mapping (address => address) referrals;
        uint256 marketEggs;
        bool initialized;
        bool isNative;
    }
    pool[] public pools;
    
    address public ceoAddress;
    address public ceoAddress2;

    constructor() public{
        ceoAddress=msg.sender;
        ceoAddress2=address(0xF829C8B626BC12e091f3C8e6456B68eB32863209);
        pool memory _newPool;
        _newPool.token = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a; // SUSHI 
        _newPool.eggs_to_match_1miners = 2592000; 
        _newPool.psn = 10000;
        _newPool.psnh = 5000;
        pools.push(_newPool);
    }
    function addPool(address _token, uint _eggs_to_match_1miners, uint _psn, uint _psnh, bool _isNative) public {
        require(msg.sender == ceoAddress);
        pool memory _newPool;
        _newPool.token = _token;
        _newPool.eggs_to_match_1miners = _eggs_to_match_1miners;
        _newPool.psn = _psn;
        _newPool.psnh = _psnh;
        _newPool.isNative = _isNative;
        
        pools.push(_newPool);
    }

    function hireMoreMiners(uint _pool, address ref) public {
        require(pools[_pool].initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        if(pools[_pool].referrals[msg.sender]==0 && pools[_pool].referrals[msg.sender]!=msg.sender) {
            pools[_pool].referrals[msg.sender]=ref;
        }
        uint256 eggsUsed=getMyEggs(_pool);
        uint256 newMiners=SafeMath.div(eggsUsed,pools[_pool].eggs_to_match_1miners);
        pools[_pool].hatcheryMiners[msg.sender]=SafeMath.add(pools[_pool].hatcheryMiners[msg.sender],newMiners);
        pools[_pool].claimedEggs[msg.sender]=0;
        pools[_pool].lastHatch[msg.sender]=now;
        
        //send referral eggs
        pools[_pool].claimedEggs[pools[_pool].referrals[msg.sender]]=SafeMath.add(pools[_pool].claimedEggs[pools[_pool].referrals[msg.sender]],SafeMath.div(eggsUsed,7));
        
        //boost market to nerf miners hoarding
        pools[_pool].marketEggs=SafeMath.add(pools[_pool].marketEggs,SafeMath.div(eggsUsed,5));
    }
    

    function takeProfit(uint _pool) public {
        require(pools[_pool].initialized);
        uint256 hasEggs=getMyEggs(_pool);
        uint256 eggValue=calculateEggSell(_pool,hasEggs);
        uint256 fee=devFee(eggValue);
        uint256 fee2=fee/2;
        pools[_pool].claimedEggs[msg.sender]=0;
        pools[_pool].lastHatch[msg.sender]=now;
        pools[_pool].marketEggs=SafeMath.add(pools[_pool].marketEggs,hasEggs);
        if(pools[_pool].isNative) {
            ceoAddress.transfer(fee2);
            ceoAddress2.transfer(fee-fee2);
            address(msg.sender).transfer(SafeMath.sub(eggValue, fee));
        } else {
            ERC20(pools[_pool].token).transfer(ceoAddress, fee2);
            ERC20(pools[_pool].token).transfer(ceoAddress2, fee-fee2);
            ERC20(pools[_pool].token).transfer(address(msg.sender), SafeMath.sub(eggValue,fee));
        }
    }
    

    function hireMiners(uint _pool, address ref, uint256 amount) public {
        require(pools[_pool].initialized);
        require(!pools[_pool].isNative);
        ERC20(pools[_pool].token).transferFrom(address(msg.sender), address(this), amount);
        
        uint256 balance = ERC20(pools[_pool].token).balanceOf(address(this));
        uint256 eggsBought=calculateEggBuy(_pool, amount,SafeMath.sub(balance,amount));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee=devFee(amount);
        uint256 fee2=fee/2;
        ERC20(pools[_pool].token).transfer(ceoAddress, fee2);
        ERC20(pools[_pool].token).transfer(ceoAddress2, fee-fee2);
        pools[_pool].claimedEggs[msg.sender]=SafeMath.add(pools[_pool].claimedEggs[msg.sender],eggsBought);
        hireMoreMiners(_pool, ref);
    }
    function hireMinersNative(uint _pool, address ref) public payable {
        require(pools[_pool].initialized);
        require(pools[_pool].isNative);
        require(msg.value > 0);
        
        uint256 amount = msg.value;
        
        uint256 balance = address(this).balance;
        uint256 eggsBought=calculateEggBuy(_pool, amount, SafeMath.sub(balance,amount));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee=devFee(amount);
        uint256 fee2=fee/2;
        
        ceoAddress.transfer(fee2);
        ceoAddress2.transfer(fee-fee2);
            
        pools[_pool].claimedEggs[msg.sender]=SafeMath.add(pools[_pool].claimedEggs[msg.sender],eggsBought);
        hireMoreMiners(_pool, ref);
    }
    

    //magic trade balancing algorithm
    function calculateTrade(uint _pool, uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(pools[_pool].psn,bs),SafeMath.add(pools[_pool].psnh,
                SafeMath.div(SafeMath.add(SafeMath.mul(pools[_pool].psn,rs),SafeMath.mul(pools[_pool].psnh,rt)),rt)));
    }
    
    
    function calculateEggSell(uint _pool,uint256 eggs) public view returns(uint256) {
        if(pools[_pool].isNative)
            return calculateTrade(_pool, eggs,pools[_pool].marketEggs,address(this).balance);
        else
            return calculateTrade(_pool, eggs,pools[_pool].marketEggs,ERC20(pools[_pool].token).balanceOf(address(this)));
    }
    function calculateEggBuy(uint _pool, uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(_pool, eth,contractBalance,pools[_pool].marketEggs);
    }
    function calculateEggBuySimple(uint _pool, uint256 eth) public view returns(uint256){
        if(pools[_pool].isNative)
            return calculateEggBuy(_pool, eth,address(this).balance);
        else
            return calculateEggBuy(_pool, eth,ERC20(pools[_pool].token).balanceOf(address(this)));
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedMarket(uint _pool, uint256 amount) public {
        require(!pools[_pool].isNative);
        ERC20(pools[_pool].token).transferFrom(address(msg.sender), address(this), amount);
        require(pools[_pool].marketEggs==0);
        pools[_pool].initialized=true;
        pools[_pool].marketEggs=259200000000;
    }
    function seedMarketNative(uint _pool) public payable {
        require(pools[_pool].isNative);
        require(pools[_pool].marketEggs==0);
        pools[_pool].initialized=true;
        pools[_pool].marketEggs=259200000000;
    }
    function getBalance(uint _pool) public view returns(uint256) {
        if(pools[_pool].isNative)
            return address(this).balance;
        else
            return ERC20(pools[_pool].token).balanceOf(address(this));
    }
    function getMyMiners(uint _pool) public view returns(uint256) {
        return pools[_pool].hatcheryMiners[msg.sender];
    }
    function getMyEggs(uint _pool) public view returns(uint256) {
        return SafeMath.add(pools[_pool].claimedEggs[msg.sender],getEggsSinceLastHatch(_pool, msg.sender));
    }
    function getEggsSinceLastHatch(uint _pool, address adr) public view returns(uint256) {
        uint256 secondsPassed=min(pools[_pool].eggs_to_match_1miners,SafeMath.sub(now,pools[_pool].lastHatch[adr]));
        return SafeMath.mul(secondsPassed,pools[_pool].hatcheryMiners[adr]);
    }
    function isNativePool(uint _pool) public view returns (bool) {
        return pools[_pool].isNative;
    }
    function lastHatch(uint _pool, address _who) public view returns(uint256){
        return pools[_pool].lastHatch[_who];
    }
    function hatcheryMiners(uint _pool, address _who) public view returns(uint256){
        return pools[_pool].hatcheryMiners[_who];
    }
    function claimedEggs(uint _pool, address _who) public view returns(uint256){
        return pools[_pool].claimedEggs[_who];
    }
    function referrals(uint _pool, address _who) public view returns(address){
        return pools[_pool].referrals[_who];
    }
    function eggs_to_match_1miners(uint _pool) public view returns(uint256){
        return pools[_pool].eggs_to_match_1miners;
    }
    function marketEggs(uint _pool) public view returns(uint256) {
        return pools[_pool].marketEggs;
    }
    function initialized(uint _pool) public view returns (bool) {
        return pools[_pool].initialized;
    }    

    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}