pragma solidity ^0.4.18;

// File: contracts/TokenController.sol

/** The interface for a token contract to notify a controller of every transfers. */
contract TokenController {
    bytes4 public constant INTERFACE = bytes4(keccak256("TokenController"));

    function allowTransfer(address _sender, address _from, address _to, uint256 _value, bytes _purpose) public returns (bool);
}


// Basic examples

contract YesController is TokenController {
    function allowTransfer(address /* _sender */, address /* _from */, address /* _to */, uint256 /* _value */, bytes /* _purpose */)
        public returns (bool)
    {
        return true; // allow all transfers
    }
}


contract NoController is TokenController {
    function allowTransfer(address /* _sender */, address /* _from */, address /* _to */, uint256 /* _value */, bytes /* _purpose */)
        public returns (bool)
    {
        return false; // veto all transfers
    }
}

// File: contracts/zeppelin-solidity/contracts/ownership/Ownable.sol

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/SaleController.sol

/** Forbid trading, but allow transfers from a seller and from the owner.
    Setting to 0 effectively pauses the sale.
*/
contract SaleController is TokenController, Ownable {

    address public seller = 0;

    /** @dev `owner` can change the `seller`. */
    function changeSeller(address _newSeller)
        onlyOwner public
    {
        seller = _newSeller;
    }

    /** @dev Allow transfers from the `seller` and the `owner`, but nobody else. No state changes. */
    function allowTransfer(address /* _sender */, address _from, address /* _to */, uint256 /* _value */, bytes /* _purpose */)
        public returns (bool)
    {
        return _from == seller || _from == owner;
    }

}