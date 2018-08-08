pragma solidity ^0.4.21;

// File: contracts/ownership/Ownable.sol

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

// File: contracts/KnowYourCustomer.sol

contract KnowYourCustomer is Ownable
{
    //
    // with this structure
    //
    struct Contributor {
        // kyc cleared or not
        bool cleared;

        // % more for the contributor bring on board in 1/100 of %
        // 2.51 % --> 251
        // 100% --> 10000
        uint16 contributor_get;

        // eth address of the referer if any - the contributor address is the key of the hash
        address ref;

        // % more for the referrer
        uint16 affiliate_get;
    }


    mapping (address => Contributor) public whitelist;
    //address[] public whitelistArray;

    /**
    *    @dev Populate the whitelist, only executed by whiteListingAdmin
    *  whiteListingAdmin /
    */

    function setContributor(address _address, bool cleared, uint16 contributor_get, uint16 affiliate_get, address ref) onlyOwner public{

        // not possible to give an exorbitant bonus to be more than 100% (100x100 = 10000)
        require(contributor_get<10000);
        require(affiliate_get<10000);

        Contributor storage contributor = whitelist[_address];

        contributor.cleared = cleared;
        contributor.contributor_get = contributor_get;

        contributor.ref = ref;
        contributor.affiliate_get = affiliate_get;

    }

    function getContributor(address _address) view public returns (bool, uint16, address, uint16 ) {
        return (whitelist[_address].cleared, whitelist[_address].contributor_get, whitelist[_address].ref, whitelist[_address].affiliate_get);
    }

    function getClearance(address _address) view public returns (bool) {
        return whitelist[_address].cleared;
    }
}