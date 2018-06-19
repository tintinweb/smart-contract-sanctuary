pragma solidity ^0.4.13;

/**
 * EthercraftFarm Front-end:
 * https://mryellow.github.io/ethercraft_farm_ui/
 */

contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
  }

}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
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
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Destructible is Ownable {

  function Destructible() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ShopInterface
{
    ERC20Basic public object;
    function buyObject(address _beneficiary) public payable;
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract TokenDestructible is Ownable {

  function TokenDestructible() public payable { }

  /**
   * @notice Terminate contract and refund to owner
   * @param tokens List of addresses of ERC20 or ERC20Basic token contracts to
   refund.
   * @notice The called token contracts could try to re-enter this contract. Only
   supply token contracts you trust.
   */
  function destroy(address[] tokens) onlyOwner public {

    // Transfer tokens to owner
    for (uint256 i = 0; i < tokens.length; i++) {
      ERC20Basic token = ERC20Basic(tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

    // Transfer Eth to owner and terminate contract
    selfdestruct(owner);
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract EthercraftFarm is Ownable, ReentrancyGuard, Destructible, TokenDestructible, Pausable {
    using SafeMath for uint8;
    using SafeMath for uint256;

    /**
     * EthercraftFarm Front-end:
     * https://mryellow.github.io/ethercraft_farm_ui/
     */

    event Prepped(address indexed shop, address indexed object, uint256 iterations);
    event Reapped(address indexed object, uint256 balance);

    mapping (address => mapping (address => uint256)) public balanceOfToken;
    mapping (address => uint256) public totalOfToken;

    function() payable public {
        //owner.transfer(msg.value);
    }

    function prep(address _shop, uint8 _iterations) nonReentrant whenNotPaused external {
        require(_shop != address(0));

        uint256 _len = 1;
        if (_iterations > 1)
            _len = uint256(_iterations);

        require(_len > 0);
        ShopInterface shop = ShopInterface(_shop);
        for (uint256 i = 0; i < _len.mul(100); i++)
            shop.buyObject(this);

        address object = shop.object();
        balanceOfToken[msg.sender][object] = balanceOfToken[msg.sender][object].add(uint256(_len.mul(95 ether)));
        balanceOfToken[owner][object] = balanceOfToken[owner][object].add(uint256(_len.mul(5 ether)));
        totalOfToken[object] = totalOfToken[object].add(uint256(_len.mul(100 ether)));

        Prepped(_shop, object, _len);
    }

    function reap(address _object) nonReentrant external {
        require(_object != address(0));
        require(balanceOfToken[msg.sender][_object] > 0);

        // Retrieve any accumulated ETH.
        if (msg.sender == owner)
            owner.transfer(this.balance);

        uint256 balance = balanceOfToken[msg.sender][_object];
        balance = balance.sub(balance % (1 ether)); // Round to whole token
        ERC20Basic(_object).transfer(msg.sender, balance);
        balanceOfToken[msg.sender][_object] = 0;
        totalOfToken[_object] = totalOfToken[_object].sub(balance);

        Reapped(_object, balance);
    }

    // Recover tokens sent in error
    function transferAnyERC20Token(address _token, uint256 _value) external onlyOwner returns (bool success) {
        require(_token != address(0));
        require(_value > 0);
        // Whatever remains after subtracting those in vaults
        require(_value <= ERC20Basic(_token).balanceOf(this).sub(this.totalOfToken(_token)));

        // Retrieve any accumulated ETH.
        if (msg.sender == owner)
            owner.transfer(this.balance);

        return ERC20Basic(_token).transfer(owner, _value);
    }

}