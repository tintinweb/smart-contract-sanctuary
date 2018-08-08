pragma solidity ^0.4.17;

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
  constructor() public {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract iPromo {
    function massNotify(address[] _owners) public;
    function transferOwnership(address newOwner) public;
}

/**
* Distribute promo tokens parallel
*   negligible, +3k gas cost / tx
*   500 address ~ 1.7M gas
* author: thesved, viktor.tabori at etheal dot com
*/
contract EthealPromoDistribute is Ownable {
    mapping (address => bool) public admins;
    iPromo public token;

    // constructor
    constructor(address _promo) public {
        token = iPromo(_promo);
    }

    // set promo token
    function setToken(address _promo) onlyOwner public {
        token = iPromo(_promo);
    }

    // transfer ownership of token
    function passToken(address _promo) onlyOwner public {
        require(_promo != address(0));
        require(address(token) != address(0));

        token.transferOwnership(_promo);
    }

    // set admins
    function setAdmin(address[] _admins, bool _v) onlyOwner public {
        for (uint256 i = 0; i<_admins.length; i++) {
            admins[ _admins[i] ] = _v;
        }
    }

    // notify
    function massNotify(address[] _owners) external {
        require(admins[msg.sender] || msg.sender == owner);
        token.massNotify(_owners);
    }
}