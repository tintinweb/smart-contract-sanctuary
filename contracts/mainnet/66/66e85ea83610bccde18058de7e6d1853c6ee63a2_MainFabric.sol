pragma solidity ^0.4.21;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: contracts/MainFabric.sol

//import "./tokens/ERC20StandardToken.sol";
//import "./tokens/ERC20MintableToken.sol";
//import "./crowdsale/RefundCrowdsale.sol";

contract MainFabric is Ownable {

    using SafeMath for uint256;

    struct Contract {
        address addr;
        address owner;
        address fabric;
        string contractType;
        uint256 index;
    }

    struct Fabric {
        address addr;
        address owner;
        bool isActive;
        uint256 index;
    }

    struct Admin {
        address addr;
        address[] contratcs;
        uint256 numContratcs;
        uint256 index;
    }

    // ---====== CONTRACTS ======---
    /**
     * @dev Get contract object by address
     */
    mapping(address => Contract) public contracts;

    /**
     * @dev Contracts addresses list
     */
    address[] public contractsAddr;

    /**
     * @dev Count of contracts in list
     */
    function numContracts() public view returns (uint256)
    { return contractsAddr.length; }


    // ---====== ADMINS ======---
    /**
     * @dev Get contract object by address
     */
    mapping(address => Admin) public admins;

    /**
     * @dev Contracts addresses list
     */
    address[] public adminsAddr;

    /**
     * @dev Count of contracts in list
     */
    function numAdmins() public view returns (uint256)
    { return adminsAddr.length; }

    function getAdminContract(address _adminAddress, uint256 _index) public view returns (
        address
    ) {
        return (
            admins[_adminAddress].contratcs[_index]
        );
    }

    // ---====== FABRICS ======---
    /**
     * @dev Get fabric object by address
     */
    mapping(address => Fabric) public fabrics;

    /**
     * @dev Fabrics addresses list
     */
    address[] public fabricsAddr;

    /**
     * @dev Count of fabrics in list
     */
    function numFabrics() public view returns (uint256)
    { return fabricsAddr.length; }

    /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyFabric() {
        require(fabrics[msg.sender].isActive);
        _;
    }

    // ---====== CONSTRUCTOR ======---

    function MainFabric() public {

    }

    /**
     * @dev Add fabric
     * @param _address Fabric address
     */
    function addFabric(
        address _address
    )
    public
    onlyOwner
    returns (bool)
    {
        fabrics[_address].addr = _address;
        fabrics[_address].owner = msg.sender;
        fabrics[_address].isActive = true;
        fabrics[_address].index = fabricsAddr.push(_address) - 1;

        return true;
    }

    /**
     * @dev Remove fabric
     * @param _address Fabric address
     */
    function removeFabric(
        address _address
    )
    public
    onlyOwner
    returns (bool)
    {
        require(fabrics[_address].isActive);
        fabrics[_address].isActive = false;

        uint rowToDelete = fabrics[_address].index;
        address keyToMove   = fabricsAddr[fabricsAddr.length-1];
        fabricsAddr[rowToDelete] = keyToMove;
        fabrics[keyToMove].index = rowToDelete;
        fabricsAddr.length--;

        return true;
    }

    /**
     * @dev Create refund crowdsale
     * @param _address Fabric address
     */
    function addContract(
        address _address,
        address _owner,
        string _contractType
    )
    public
    onlyFabric
    returns (bool)
    {
        contracts[_address].addr = _address;
        contracts[_address].owner = _owner;
        contracts[_address].fabric = msg.sender;
        contracts[_address].contractType = _contractType;
        contracts[_address].index = contractsAddr.push(_address) - 1;

        if (admins[_owner].addr != _owner) {
            admins[_owner].addr = _owner;
            admins[_owner].index = adminsAddr.push(_owner) - 1;
        }

        admins[_owner].contratcs.push(contracts[_address].addr);
        admins[_owner].numContratcs++;

        return true;
    }
}