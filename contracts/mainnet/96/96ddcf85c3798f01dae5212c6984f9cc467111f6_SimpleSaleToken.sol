pragma solidity ^0.4.18;

/*
    Overflow protected math functions
*/
contract SafeMath {
    /**
        constructor
    */
    function SafeMath() public {
    }

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) pure internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}


// Token standard API
// https://github.com/ethereum/EIPs/issues/20

contract iERC20Token {
  function totalSupply() public constant returns (uint supply);
  function balanceOf( address who ) public constant returns (uint value);
  function allowance( address owner, address spender ) public constant returns (uint remaining);

  function transfer( address to, uint value) public returns (bool ok);
  function transferFrom( address from, address to, uint value) public returns (bool ok);
  function approve( address spender, uint value ) public returns (bool ok);

  event Transfer( address indexed from, address indexed to, uint value);
  event Approval( address indexed owner, address indexed spender, uint value);
}

contract ReverseRegistrar {
  function claim(address owner) public returns (bytes32 node);
}


contract SimpleSaleToken is iERC20Token, SafeMath {

  event PaymentEvent(address indexed from, uint amount);
  event TransferEvent(address indexed from, address indexed to, uint amount);
  event ApprovalEvent(address indexed from, address indexed to, uint amount);

  string  public symbol;
  string  public name;
  bool    public isLocked;
  uint    public decimals;
  uint    public tokenPrice;
  uint           tokenSupply;
  uint           tokensRemaining;
  uint    public contractSendGas = 100000;
  address public owner;
  address public beneficiary;
  mapping (address => uint) balances;
  mapping (address => mapping (address => uint)) approvals;  //transfer approvals, from -> to
  // namehash(&#39;addr.reverse&#39;)
  //bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
  address constant ENS_REVERSE_REGISTRAR = 0x9062C0A6Dbd6108336BcBe4593a3D1cE05512069;

  modifier ownerOnly {
    require(msg.sender == owner);
    _;
  }

  modifier unlockedOnly {
    require(!isLocked);
    _;
  }

  modifier duringSale {
    require(tokenPrice != 0 && tokensRemaining > 0);
    _;
  }

  //this is to protect from short-address attack. use this to verify size of args, especially when an address arg preceeds
  //a value arg. see: https://www.reddit.com/r/ethereum/comments/63s917/worrysome_bug_exploit_with_erc20_token/dfwmhc3/
  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length >= size + 4);
    _;
  }

  //
  //constructor
  //
  function SimpleSaleToken() public {
    owner = msg.sender;
    beneficiary = msg.sender;
    //so we can set a name
    //ReverseRegistrar registrar = ReverseRegistrar(ens.owner(ADDR_REVERSE_NODE));
    //registrar.claim(msg.sender);
    ReverseRegistrar(ENS_REVERSE_REGISTRAR).claim(msg.sender);
  }


  //
  // ERC-20
  //

  function totalSupply() public constant returns (uint supply) {
    //if tokenSupply was not limited then we would use safeAdd...
    supply = tokenSupply + tokensRemaining;
  }

  function transfer(address _to, uint _value) public onlyPayloadSize(2*32) returns (bool success) {
    //prevent wrap
    if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      TransferEvent(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }


  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3*32) public returns (bool success) {
    //prevent wrap:
    if (balances[_from] >= _value && approvals[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
      balances[_from] -= _value;
      balances[_to] += _value;
      approvals[_from][msg.sender] -= _value;
      TransferEvent(_from, _to, _value);
      return true;
    } else {
      return false;
    }
  }


  function balanceOf(address _owner) public constant returns (uint balance) {
    balance = balances[_owner];
  }


  function approve(address _spender, uint _value) public onlyPayloadSize(2*32) returns (bool success) {
    approvals[msg.sender][_spender] = _value;
    ApprovalEvent(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return approvals[_owner][_spender];
  }

  //
  // END ERC20
  //


  //
  // default payable function.
  //
  function () public payable duringSale {
    uint _quantity = msg.value / tokenPrice;
    if (_quantity > tokensRemaining)
       _quantity = tokensRemaining;
    require(_quantity >= 1);
    uint _cost = safeMul(_quantity, tokenPrice);
    uint _refund = safeSub(msg.value, _cost);
    balances[msg.sender] = safeAdd(balances[msg.sender], _quantity);
    tokenSupply = safeAdd(tokenSupply, _quantity);
    tokensRemaining = safeSub(tokensRemaining, _quantity);
    if (_refund > 0)
        msg.sender.transfer(_refund);
    PaymentEvent(msg.sender, msg.value);
  }

  function setName(string _name, string _symbol) public ownerOnly {
    name = _name;
    symbol = _symbol;
  }


  //if decimals = 3, and you want 1 ETH/token, then pass in _tokenPrice = 0.001 * (wei / ether)
  function setBeneficiary(address _beneficiary, uint _decimals, uint _tokenPrice, uint _tokensRemaining) public ownerOnly unlockedOnly {
    beneficiary = _beneficiary;
    decimals = _decimals;
    tokenPrice = _tokenPrice;
    tokensRemaining = _tokensRemaining;
  }

  function lock() public ownerOnly {
    require(beneficiary != 0 && tokenPrice != 0);
    isLocked = true;
  }

  function endSale() public ownerOnly {
    require(beneficiary != 0);
    //beneficiary is most likely a contract...
    if (!beneficiary.call.gas(contractSendGas).value(this.balance)())
      revert();
    tokensRemaining = 0;
  }

  function tune(uint _contractSendGas) public ownerOnly {
    contractSendGas = _contractSendGas;
  }

  //for debug
  //only available before the contract is locked
  function haraKiri() public ownerOnly unlockedOnly {
    selfdestruct(owner);
  }

}