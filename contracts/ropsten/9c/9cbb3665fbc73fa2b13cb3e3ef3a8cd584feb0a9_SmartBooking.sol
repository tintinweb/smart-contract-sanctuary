pragma solidity ^0.4.19;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract SmartBooking is Ownable {
    /*
  * Potential statuses for the Package struct
  * 0: Open
  * 1: Cancelled
  */
  struct Package
  {
      uint256 package_id;
      uint start_time;
      uint end_time;
      uint quota;
      string description;
      uint256 price;
      uint8 status;
      address creator;
  }
  struct PackageBuyer
  {
      uint256 package_id;
      uint256 traveller_unique_id;
  }
  /*
  * Potential statuses for the Agency struct
  * 0: Group
  * 1: Day
  */
  struct Agency
  {
      uint8 enabled;
      uint index;
      uint8 agency_type;
  }
  mapping (address => Agency) private agencylist;
  address[] private agencyIndex;
  
  event AgencyAdded(
      address addr,
      uint8 enabled,
      uint index,
      uint8 agency_type
      );
  event PackageCreated(
      uint256 package_id,
      uint start_time,
      uint end_time,
      uint quota,
      string description,
      uint256 price
      );
  event PackageBought(
      uint256 package_id
      );
  event PackageCancelled(
      uint256 package_id
      );
  event BookedPackage(
      uint256 package_id, 
      uint256 traveller_unique_id
      );

    modifier onlyAgencyOrOwner() {
    require(msg.sender == owner || isAgency(msg.sender));
    _;
  }
  
  function isAgency (address userAddress) public constant returns (bool isIndeed) {
        if (agencyIndex.length == 0) return false;
        return (agencyIndex[agencylist[userAddress].index] == userAddress);
    }
    
  Package[] private packageList;
  mapping (uint256 => PackageBuyer[]) packageDetailList;

  /**
   * @dev Constructor
   */
  function SmartBooking() public {
  }


  // ------------------------------------------------------------------------------------------ //
  // INTERNAL FUNCTIONS
  // ------------------------------------------------------------------------------------------ //

  function areStringsEqual (bytes32 a, bytes32 b) private pure returns (bool) {
    // generate a hash for each string and compare them
    return keccak256(a) == keccak256(b);
  }


  // ------------------------------------------------------------------------------------------ //
  // FUNCTIONS TRIGGERING TRANSACTIONS
  // ------------------------------------------------------------------------------------------ //

  function addAgency(address userAddress) onlyOwner
  {
        if (!isAgency(userAddress)) {
            agencylist[userAddress].enabled = 1;
            agencylist[userAddress].agency_type = 1;
            agencylist[userAddress].index = agencyIndex.push(userAddress) - 1;
            AgencyAdded(userAddress,agencylist[userAddress].enabled,agencylist[userAddress].index,agencylist[userAddress].agency_type);
        }
  }
  function disableAgency(address userAddress) onlyOwner
  {
        if (isAgency(userAddress)) {
            agencylist[userAddress].enabled = 0;
        }
  }
  function enableAgency(address userAddress) onlyOwner
  {
        if (isAgency(userAddress)) {
            agencylist[userAddress].enabled = 1;
        }
  }
  
  function createPackage(
      uint start_time,
      uint end_time,
      uint quota,
      string description,
      uint256 price)
  public
  onlyAgencyOrOwner {
    Package memory packageToAdd;
    packageToAdd.start_time = start_time;
    packageToAdd.end_time = end_time;
    packageToAdd.quota = quota;
    packageToAdd.description = description;
    packageToAdd.price = price;
    packageToAdd.status = 0;
    packageToAdd.creator = msg.sender;
    uint len = packageList.push(packageToAdd);

    PackageCreated(
      len,
      start_time,
      end_time,
      quota,
      description,
      price
      );
  }
  
  function book(uint256 package_id, uint256 traveller_unique_id) onlyOwner
  {
      require(packageList[package_id].quota - packageDetailList[package_id].length > 0);
      PackageBuyer memory packageBuyerToAdd;
      packageBuyerToAdd.package_id = package_id;
      packageBuyerToAdd.traveller_unique_id = traveller_unique_id;
      uint len = packageDetailList[package_id].push(packageBuyerToAdd);
      BookedPackage(package_id,traveller_unique_id);
      if (packageList[package_id].quota - packageDetailList[package_id].length == 0)
      {
          packageList[package_id].status = 1;
      }
  }

  function getSoldCountOfPackage(uint packageid) public view onlyAgencyOrOwner returns(uint)
  {
      return (packageDetailList[packageid].length);
  }
  
  function countOpenPackage() internal view returns(uint) {
        uint counter = 0;
        for (uint i = 0; i < packageList.length; i++) {
            if (packageList[i].status == 0) {
                counter++;   
            }
        }

        return counter;
    }
  
  function getOpenPackageId() public constant returns(uint[])
  {
      uint[] memory v = new uint[](countOpenPackage());
        uint counter = 0;
        for (uint i = 0;i < packageList.length; i++) {
            if (packageList[i].status == 0) {
                v[counter] = i;
                counter++;
            }
        }
        return v;
  }
  
  function countOpenPackageOfOneAgency(address addr) internal view returns(uint) {
        uint counter = 0;
        for (uint i = 0; i < packageList.length; i++) {
            if (packageList[i].creator == addr) {
                counter++;   
            }
        }

        return counter;
    }
  
  function getOpenPackageIdOfOneAgency(address addr) public constant returns(uint[])
  {
      require(isAgency(addr));
      uint[] memory v = new uint[](countOpenPackageOfOneAgency(addr));
        uint counter = 0;
        for (uint i = 0;i < packageList.length; i++) {
            if (packageList[i].creator == addr) {
                v[counter] = i;
                counter++;
            }
        }
        return v;
  }
  
  function getPackageById(uint packageid) public constant returns (uint, uint, uint, string, uint256, uint, address)
  {
      require(packageid <= packageList.length);
      return (
          packageList[packageid].start_time, 
          packageList[packageid].end_time,
          packageList[packageid].quota,
          packageList[packageid].description,
          packageList[packageid].price,
          packageList[packageid].status,
          packageList[packageid].creator);
  }
  
  
}