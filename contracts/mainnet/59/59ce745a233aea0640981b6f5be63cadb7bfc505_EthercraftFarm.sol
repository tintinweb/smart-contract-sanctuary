pragma solidity ^0.4.13;

/**
 * EthercraftFarm Front-end:
 * https://mryellow.github.io/ethercraft_farm_ui/
 */

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

contract ShopInterface
{
    ObjectInterface public object;
    function buyObject(address _beneficiary) public payable;
}

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

contract EthercraftFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // TODO: Could be private with getter only allowing senders balance lookup.
    mapping (address => mapping (address => uint256)) public tokenBalanceOf;

    function() payable public {
        //owner.transfer(msg.value);
    }

    function prep(address _shop, uint8 _iterations) nonReentrant external {
        require(_shop != address(0));

        uint8 _len = 1;
        if (_iterations > 1)
            _len = _iterations;

        ShopInterface shop = ShopInterface(_shop);
        for (uint8 i = 0; i < _len * 100; i++) {
            shop.buyObject(this);
        }

        ObjectInterface object = ObjectInterface(shop.object());
        tokenBalanceOf[msg.sender][object] = tokenBalanceOf[msg.sender][object].add(uint256(_len * 99 ether));
        tokenBalanceOf[owner][object] = tokenBalanceOf[owner][object].add(uint256(_len * 1 ether));
    }

    function reap(address _object) nonReentrant external {
        require(_object != address(0));
        require(tokenBalanceOf[msg.sender][_object] > 0);

        // Retrieve any accumulated ETH.
        if (msg.sender == owner)
            owner.transfer(this.balance);

        ObjectInterface(_object).transfer(msg.sender, tokenBalanceOf[msg.sender][_object]);
        tokenBalanceOf[msg.sender][_object] = 0;
    }

}

contract ObjectInterface
{
    function transfer(address to, uint256 value) public returns (bool);
}