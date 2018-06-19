pragma solidity ^0.4.19;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AtomicSwap {
  struct Swap {
    uint expiration;
    address initiator;
    address participant;
    uint256 value;
    bool isToken;
    address token;
    bool exists;
  }

  // maps the redeemer and bytes20 hash to a swap    
  mapping(address => mapping(bytes20 => Swap)) public swaps;

  function initiate(uint _expiration, bytes20 _hash, address _participant, address _token, bool _isToken, uint256 _value) payable public {
    Swap storage s = swaps[_participant][_hash];
    // make sure you aren&#39;t overwriting a pre-existing swap
    // (so the original initiator can&#39;t rewrite the terms)
    require (s.exists == false);
    // don&#39;t allow the creation of already expired swaps
    require (now < _expiration);

    if (_isToken) {
      // require that the sender has allowed the tokens to be withdrawn from their account
      ERC20 token = ERC20(_token);
      require(token.allowance(msg.sender, this) == _value);
      token.transferFrom(msg.sender, this, _value);
    }
    // create the new swap
    swaps[_participant][_hash] = Swap(_expiration, msg.sender, _participant, _isToken ? _value : msg.value, _isToken, _token, true);
  }

  function redeem(bytes32 _secret) public {
    // get a swap from the mapping. we can do it directly because there is no way to 
    // fake the secret.
    bytes20 hash = ripemd160(_secret);
    Swap storage s = swaps[msg.sender][hash];
    
    // make sure the swap was not redeemed or refunded
    require(s.exists);
    // make sure the swap did not expire already
    require(now < s.expiration);
    
    // clean up and send
    s.exists = false;
    if (s.isToken) {
      ERC20 token = ERC20(s.token);
      token.transfer(msg.sender, s.value);
    } else {
      msg.sender.transfer(s.value);
    }
  }

  function refund(bytes20 _hash, address _participant) public {
    Swap storage s = swaps[_participant][_hash];
    // don&#39;t allow refund if swap did not expire
    require(now > s.expiration);
    // don&#39;t allow refunds if the caller is not the initator
    require(msg.sender == s.initiator);
    // make sure the swap was not redeemed or refunded
    require(s.exists);

    s.exists = false;
    if (s.isToken) {
      ERC20 token = ERC20(s.token);
      token.transfer(msg.sender, s.value);
    } else {
      msg.sender.transfer(s.value);
    }
  }
}