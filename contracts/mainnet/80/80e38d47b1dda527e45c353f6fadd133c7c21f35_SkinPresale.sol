pragma solidity ^0.4.18;

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

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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

contract SkinPresale is Pausable {

    // Record number of packages each account buy
    mapping (address => uint256) public accountToBoughtNum;

    // Total number of packages for presale
    uint256 public totalSupplyForPresale = 10000;

    // Number of packages each account can buy
    uint256 public accountBuyLimit = 100;

    // Remaining packages for presale
    uint256 public remainPackage = 10000;

    // Event
    event BuyPresale(address account);

    function buyPresale() payable external whenNotPaused {
        address account = msg.sender;

        // Check account limit
        require(accountToBoughtNum[account] + 1 < accountBuyLimit);

        // Check total presale limit
        require(remainPackage > 0);

        // Check enough money
        uint256 price = 20 finney + (10000 - remainPackage) / 500 * 10 finney;
        require(msg.value >= price);

        // Perform purchase
        accountToBoughtNum[account] += 1;
        remainPackage -= 1;

        // Fire event
        BuyPresale(account);
    }

    function withdrawETH() external onlyOwner {
        owner.transfer(this.balance);
    }

}