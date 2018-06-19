pragma solidity ^0.4.18;

/**************************
 * SATURN ICO smart contract *
 **************************/

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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


contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);

  function name() constant returns (string _name);
  function symbol() constant returns (string _symbol);
  function decimals() constant returns (uint8 _decimals);
  function totalSupply() constant returns (uint256 _supply);

  function transfer(address to, uint value) returns (bool ok);
  function transfer(address to, uint value, bytes data) returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event ERC223Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
}

contract ContractReceiver {
  function tokenFallback(address _from, uint _value, bytes _data);
}

contract ERC223Token is ERC223 {
  using SafeMath for uint;

  mapping(address => uint) balances;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;


  // Function to access name of token .
  function name() constant returns (string _name) {
      return name;
  }
  // Function to access symbol of token .
  function symbol() constant returns (string _symbol) {
      return symbol;
  }
  // Function to access decimals of token .
  function decimals() constant returns (uint8 _decimals) {
      return decimals;
  }
  // Function to access total supply of tokens .
  function totalSupply() constant returns (uint256 _totalSupply) {
      return totalSupply;
  }

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) returns (bool success) {
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}

  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value) returns (bool success) {

    //standard function transfer similar to ERC20 transfer with no _data
    //added due to backwards compatibility reasons
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}

//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        if(length>0) {
            return true;
        }
        else {
            return false;
        }
    }

  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    Transfer(msg.sender, _to, _value);
    ERC223Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    ContractReceiver reciever = ContractReceiver(_to);
    reciever.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value);
    ERC223Transfer(msg.sender, _to, _value, _data);
    return true;
  }


  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}

contract TokenSale is ContractReceiver {
  using SafeMath for uint256;

  bool    public active = false;
  address public tokenAddress;
  uint256 public hardCap;
  uint256 public sold;

  // 1 eth = 50,000 SATURN
  uint256 private priceDiv = 2000000000;
  address private stn;
  address private owner;
  address private treasury;

  struct Ref {
    uint256 amount;
    uint256 rewardDiv;
    uint256 etherAmount;
  }

  mapping(address => Ref) private referrals;

  event Activated(uint256 time);
  event Finished(uint256 time);
  event Purchase(address indexed purchaser, uint256 amount);
  event Referral(address indexed referrer, uint256 amount);

  function TokenSale(address token, address presaleToken, address ethRecepient, uint256 cap) public {
    tokenAddress  = token;
    stn           = presaleToken;
    owner         = msg.sender;
    treasury      = ethRecepient;
    hardCap       = cap;
  }

  function tokenFallback(address _from, uint _value, bytes /* _data */) public {
    if (active && msg.sender == stn) {
      stnExchange(_from, _value);
    } else {
      if (msg.sender != tokenAddress) { revert(); }
      if (active) { revert(); }
      if (_value != hardCap) { revert(); }

      active = true;
      Activated(now);
    }
  }

  function stnExchange(address buyer, uint256 value) private {
    uint256 purchasedAmount = value.mul(50000);
    if (purchasedAmount == 0) { revert(); } // not enough STN sent
    if (purchasedAmount > hardCap - sold) { revert(); } // too much STN sent

    sold += purchasedAmount;

    ERC223 token = ERC223(tokenAddress);
    token.transfer(buyer, purchasedAmount);
    Purchase(buyer, purchasedAmount);
  }

  function refAmount(address user) constant public returns (uint256 amount) {
    return referrals[user].amount;
  }

  function refPercentage(address user) constant public returns (uint256 percentage) {
    uint256 rewardDiv = referrals[user].rewardDiv;
    if (rewardDiv == 0)   { return 1; }
    if (rewardDiv == 100) { return 1; }
    if (rewardDiv == 50)  { return 2; }
    if (rewardDiv == 20)  { return 5; }
    if (rewardDiv == 10)  { return 10; }
  }

  function () external payable {
    processPurchase(0x0);
  }

  function processPurchase(address referrer) payable public {
    if (!active) { revert(); }
    if (msg.value == 0) { revert(); }

    uint256 purchasedAmount = msg.value.div(priceDiv);
    if (purchasedAmount == 0) { revert(); } // not enough ETH sent
    if (purchasedAmount > hardCap - sold) { revert(); } // too much ETH sent

    sold += purchasedAmount;
    treasury.transfer(msg.value);

    ERC223 token = ERC223(tokenAddress);
    token.transfer(msg.sender, purchasedAmount);
    Purchase(msg.sender, purchasedAmount);
    processReferral(referrer, purchasedAmount, msg.value);
  }

  function processReferral(address referrer, uint256 tokenAmount, uint256 etherAmount) private returns (bool success) {
    if (referrer == 0x0) { return true; }
    Ref memory ref = referrals[referrer];
    if (ref.rewardDiv == 0) { ref.rewardDiv = 100; } // on your first referral you get 1%
    uint256 referralAmount = tokenAmount.div(ref.rewardDiv);
    if (referralAmount == 0) { return true; }
    // cannot pay more than the contract has itself
    if (referralAmount > hardCap - sold) { referralAmount = hardCap - sold; }
    ref.amount = ref.amount.add(referralAmount);
    ref.etherAmount = ref.etherAmount.add(etherAmount);

    // ugly block of code that handles variable referral commisions
    if (ref.etherAmount > 5 ether)   { ref.rewardDiv = 50; } // 2% from 5 eth
    if (ref.etherAmount > 10 ether)  { ref.rewardDiv = 20; } // 5% from 10 eth
    if (ref.etherAmount > 100 ether) { ref.rewardDiv = 10; } // 10% from 100 eth
    // end referral updates

    sold += referralAmount;
    referrals[referrer] = ref; // update the mapping and store our changes
    ERC223 token = ERC223(tokenAddress);
    token.transfer(referrer, referralAmount);
    Referral(referrer, referralAmount);
    return true;
  }

  function endSale() public {
    // only the creator of the smart contract can end the crowdsale
    if (msg.sender != owner) { revert(); }
    // can only stop an active crowdsale
    if (!active) { revert(); }
    _end();
  }

  function _end() private {
    // if there are any tokens remaining - return them to the treasury
    if (sold < hardCap) {
      ERC223 token = ERC223(tokenAddress);
      token.transfer(treasury, hardCap.sub(sold));
    }
    active = false;
    Finished(now);
  }
}