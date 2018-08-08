pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
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
    emit OwnershipTransferred(owner, newOwner);
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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract PreSale is Pausable {
    uint256 constant public INCREASE_RATE = 350000000000000; // 50c if ethereum is $700

    uint256 public eggsSold = 1987;
    mapping (address => uint32) public eggs;

    function PreSale() payable public {
    }

    event EggsPurchased(address indexed purchaser, uint256 value, uint32 quantity);
    
    event EggsRedeemed(address indexed sender, uint256 eggs);

    function bulkPurchageEgg() whenNotPaused payable public {
        require(msg.value >= (eggPrice() * 5 + INCREASE_RATE * 10));
        eggs[msg.sender] = eggs[msg.sender] + 5;
        eggsSold = eggsSold + 5;
        EggsPurchased(msg.sender, msg.value, 5);
    }
    
    function purchaseEgg() whenNotPaused payable public {
        require(msg.value >= eggPrice());

        eggs[msg.sender] = eggs[msg.sender] + 1;
        eggsSold = eggsSold + 1;
        
        EggsPurchased(msg.sender, msg.value, 1);
    }
    
    function redeemEgg(address targetUser) onlyOwner public returns(uint256) {
        require(eggs[targetUser] > 0);

        EggsRedeemed(targetUser, eggs[targetUser]);

        var userEggs = eggs[targetUser];
        eggs[targetUser] = 0;
        return userEggs;
    }

    function eggPrice() view public returns(uint256) {
        return (eggsSold + 1) * INCREASE_RATE;
    }

    function withdrawal() onlyOwner public {
        owner.transfer(this.balance);
    }
}