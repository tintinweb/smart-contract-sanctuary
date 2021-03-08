/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

/**
 *Submitted for verification at Etherscan.io on 2017-12-11
*/

pragma solidity 0.4.18;

contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  function Pausable() public {}

  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Test is Pausable, SafeMath {

  uint256 public totalSupply;

  mapping(address => uint) public balances;
  mapping (address => mapping (address => uint)) public allowed;

  string public constant name = "TEST";
  string public constant symbol = "TST";
  uint8 public constant decimals = 7;
  
  // custom properties
  bool public mintingFinished = false;
  uint256 public constant MINTING_LIMIT = 40000000 * 10000000;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  function Test() public {}

  function() public payable {
    revert();
  }

  function balanceOf(address _owner) public constant returns (uint256) {
    return balances[_owner];
  }

  function transfer(address _to, uint _value) public whenNotPaused returns (bool) {

    balances[msg.sender] = sub(balances[msg.sender], _value);
    balances[_to] = add(balances[_to], _value);

    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = add(balances[_to], _value);
    balances[_from] = sub(balances[_from], _value);
    allowed[_from][msg.sender] = sub(_allowance, _value);

    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value) public whenNotPaused returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256) {
    return allowed[_owner][_spender];
  }

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
    totalSupply = add(totalSupply, _amount);
    require(totalSupply <= MINTING_LIMIT);
    
    balances[_to] = add(balances[_to], _amount);
    Mint(_to, _amount);
    return true;
  }

  function finishMinting() public onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }


}