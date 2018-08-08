pragma solidity ^0.4.16;




contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);

    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);

    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
      uint256 c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
      // assert(b > 0); // Solidity automatically throws when dividing by 0
      uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
      return c;
    }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
      assert(b <= a);
      return a - b;
    }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      Transfer(msg.sender, _to, _value);
      return true;
    }

  function balanceOf(address _owner) constant returns (uint256 balance) {
      return balances[_owner];
    }
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
      var _allowance = allowed[_from][msg.sender];

      // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
      // require (_value <= _allowance);

      balances[_to] = balances[_to].add(_value);
      balances[_from] = balances[_from].sub(_value);
      allowed[_from][msg.sender] = _allowance.sub(_value);
      Transfer(_from, _to, _value);
      return true;
    }

  function approve(address _spender, uint256 _value) returns (bool) {

      // To change the approve amount you first have to reduce the addresses`
      //  allowance to zero by calling `approve(_spender, 0)` if it is not
      //  already 0 to mitigate the race condition described here:
      //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
      require((_value == 0) || (allowed[msg.sender][_spender] == 0));

      allowed[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);
      return true;
    }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }



}

contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
      owner = msg.sender;
    }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
      require(newOwner != address(0));
      owner = newOwner;
    }

}


contract Token is StandardToken, Ownable {
    using SafeMath for uint256;

  // start and end block where investments are allowed (both inclusive)
    uint256 public startBlock;
    uint256 public endBlock;
  // address where funds are collected
    address public wallet;

  // how many token units a buyer gets per wei
    uint256 public tokensPerEther;

  // amount of raised money in wei
    uint256 public weiRaised;

    uint256 public cap;
    uint256 public issuedTokens;
    string public name = "Realestateco.in";
    string public symbol = "REAL";
    uint public decimals = 4;
    uint public INITIAL_SUPPLY = 80000000000000;
    uint factor;
    bool internal isCrowdSaleRunning;
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function Token() {

        wallet = address(0x879bf61F63a8C58D802EC612Aa8E868882E532c6);
        tokensPerEther = 331;
        endBlock = block.number + 400000;

        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        startBlock = block.number;
        cap = INITIAL_SUPPLY;
        issuedTokens = 0;
        factor = 10**14;
        isCrowdSaleRunning = true;
        }

    // crowdsale entrypoint
    // fallback function can be used to buy tokens

  function () payable {
      buyTokens(msg.sender);
    }

  function stopCrowdSale() onlyOwner {
    isCrowdSaleRunning = false;
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable {
      require(beneficiary != 0x0);
      require(validPurchase());

      uint256 weiAmount = msg.value;
      // calculate token amount to be created
      uint256 tokens = weiAmount.mul(tokensPerEther).div(factor);


      // check if the tokens are more than the cap
      require(issuedTokens.add(tokens) <= cap);
      // update state
      weiRaised = weiRaised.add(weiAmount);
      issuedTokens = issuedTokens.add(tokens);

      forwardFunds();
      // transfer the token
      issueToken(beneficiary,tokens);
      TokenPurchase(msg.sender, beneficiary, msg.value, tokens);

    }

  // can be issued to anyone without owners concent but as this method is internal only buyToken is calling it.
  function issueToken(address beneficiary, uint256 tokens) internal {

      balances[owner] = balances[owner].sub(tokens);
      balances[beneficiary] = balances[beneficiary].add(tokens);
    }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
      // to normalize the input
      wallet.transfer(msg.value);

    }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
      uint256 current = block.number;
      bool withinPeriod = current >= startBlock && current <= endBlock;
      bool nonZeroPurchase = msg.value != 0;
      return withinPeriod && nonZeroPurchase && isCrowdSaleRunning;
    }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
      return (block.number > endBlock) && isCrowdSaleRunning;
    }

}