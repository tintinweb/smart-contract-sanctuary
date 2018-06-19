pragma solidity ^0.4.18;

//credit given to original creator of the cornfarm contract and the original taxman contract
//to view how many of a specific token you have in the contract use the userInventory option in MEW.
//First address box copy paste in your eth address.  Second address box is the contract address of the Ethercraft item you want to check.    
//WorkDone = # of that token you have in the farm contract * 10^18.


interface CornFarm
{
    function buyObject(address _beneficiary) public payable;
}

interface Corn
{
    function transfer(address to, uint256 value) public returns (bool);
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

contract FreeTaxManFarmer {
    using SafeMath for uint256;
    
    bool private reentrancy_lock = false;

    struct tokenInv {
      uint256 workDone;
    }
    
    mapping(address => mapping(address => tokenInv)) public userInventory;
    
    modifier nonReentrant() {
        require(!reentrancy_lock);
        reentrancy_lock = true;
        _;
        reentrancy_lock = false;
    }
    
    function pepFarm(address item_shop_address, address token_address, uint256 buy_amount) nonReentrant external {
        for (uint8 i = 0; i < buy_amount; i++) {
            CornFarm(item_shop_address).buyObject(this);
        }
        userInventory[msg.sender][token_address].workDone = userInventory[msg.sender][token_address].workDone.add(uint256(buy_amount * 10**18));
    }
    
    function reapFarm(address token_address) nonReentrant external {
        require(userInventory[msg.sender][token_address].workDone > 0);
        Corn(token_address).transfer(msg.sender, userInventory[msg.sender][token_address].workDone);
        userInventory[msg.sender][token_address].workDone = 0;
    }

}