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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract Whitelisting is Ownable {
    mapping(address => bool) public isInvestorApproved;

    event Approved(address indexed investor);
    event Disapproved(address indexed investor);

    function approveInvestor(address toApprove) public onlyOwner {
        isInvestorApproved[toApprove] = true;
        Approved(toApprove);
    }

    function approveInvestorsInBulk(address[] toApprove) public onlyOwner {
        for (uint i=0; i<toApprove.length; i++) {
            isInvestorApproved[toApprove[i]] = true;
            Approved(toApprove[i]);
        }
    }

    function disapproveInvestor(address toDisapprove) public onlyOwner {
        delete isInvestorApproved[toDisapprove];
        Disapproved(toDisapprove);
    }

    function disapproveInvestorsInBulk(address[] toDisapprove) public onlyOwner {
        for (uint i=0; i<toDisapprove.length; i++) {
            delete isInvestorApproved[toDisapprove[i]];
            Disapproved(toDisapprove[i]);
        }
    }
}