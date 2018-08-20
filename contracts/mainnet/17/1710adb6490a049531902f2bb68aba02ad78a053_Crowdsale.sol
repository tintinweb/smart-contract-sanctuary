pragma solidity ^0.4.13;

library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

interface token {
    function transfer(address receiver, uint amount);
    function balanceOf(address) returns (uint256);
}

contract Crowdsale {
    address public beneficiary;
    address master;
    uint public tokenBalance;
    uint public amountRaised;
    uint start_time;
    uint public price;
    uint public offChainTokens;
    uint public minimumSpend;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    event FundTransfer(address backer, uint amount, bool isContribution);
    bool public paused;

    address public contlength;  // Remove

    modifier isPaused() { if (paused == true) _; }
    modifier notPaused() { if (paused == false) _; }
    modifier isMaster() { if (msg.sender == master) _; }
    

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function Crowdsale() {

        offChainTokens = 0;
        amountRaised = 0;
        tokenBalance = 30000000;  //Change
        minimumSpend = 0.01 * 1 ether;
        beneficiary = 0x0677f6a5383b10dc4ac253b4d56d8f69df76f548;   
        start_time = now;
        tokenReward = token(0xfACfB7aaD014f30f06E67cBeE8d3308C69aeD37a);    
        master =  0x69F8C1604f27475AF9f872E07c2E6a56b485DAcf;
        paused = false;
        price = 953584813430000;
    }

    /**
     * Fallback function
    **/

    function () payable notPaused {

        uint amount = msg.value;
        amountRaised += amount;
        tokenBalance = SafeMath.sub(tokenBalance, SafeMath.div(amount, price));
        if (tokenBalance < offChainTokens ) { revert(); }
        if (amount <  minimumSpend) { revert(); }
        tokenReward.transfer(msg.sender, SafeMath.div(amount * 1 ether, price));
        FundTransfer(msg.sender, amount, true);
        balanceOf[msg.sender] += amount;
        
    }

    function safeWithdrawal() isMaster {

      tokenReward.transfer(beneficiary, tokenReward.balanceOf(this));
      if (beneficiary.send(amountRaised)) {
          FundTransfer(beneficiary, amountRaised, false);
          tokenReward.transfer(beneficiary, tokenReward.balanceOf(this));
          tokenBalance = 0;
      }
    }

    function pause() notPaused isMaster {
      paused = true;
    }

    function unPause() isPaused isMaster {
      paused = false;
    }

    function updatePrice(uint _price) isMaster {
      price = _price;
    }

    function updateMinSpend(uint _minimumSpend) isMaster {
      minimumSpend = _minimumSpend;
    }

    function updateOffChainTokens(uint _offChainTokens) isMaster {
        offChainTokens = _offChainTokens;
    }

}