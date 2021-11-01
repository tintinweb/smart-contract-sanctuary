/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-27
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

contract ETERNAL_CAKE_MINER {
    function buyEggs(address ref, uint256 amount) public;
    function hatchEggs(address ref) public;
}

contract CAKE_TOKEN {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract FLOKY_INU {  
    address public token;   

    address public miner;

    bool public linked = false;
    
    ETERNAL_CAKE_MINER public minerInstance;
    CAKE_TOKEN public tokenInstance;

    constructor() public{
        token = 0xed24fc36d5ee211ea25a80239fb8c4cfd80f12ee;                 
        tokenInstance = CAKE_TOKEN(token);                   
    }

    function buyAndCompound () public {
        uint256 balance = ERC20(token).balanceOf(address(this));
        uint256 bounty = calcBounty(balance);
        balance = SafeMath.sub(balance,bounty);
        minerInstance.buyEggs(0, balance);
        ERC20(token).transfer(msg.sender, bounty);
    }

    function compound () public {        
        minerInstance.hatchEggs(0);
    }

    function calcBounty(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),10000);
    }

    function getBounty() public view returns(uint256) {
        return calcBounty(ERC20(token).balanceOf(address(this)));
    }

    function linkMiner(address minerContract) public{
      require(linked==false);
      miner = minerContract;
      minerInstance = ETERNAL_CAKE_MINER(miner);
      tokenInstance.approve(miner, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
      linked = true;
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