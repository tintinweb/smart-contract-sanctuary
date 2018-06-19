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



contract Curatable is Ownable {
  address public curator;


  event CurationRightsTransferred(address indexed previousCurator, address indexed newCurator);


  /**
   * @dev The Curatable constructor sets the original `curator` of the contract to the sender
   * account.
   */
  function Curatable() public {
    owner = msg.sender;
    curator = owner;
  }


  /**
   * @dev Throws if called by any account other than the curator.
   */
  modifier onlyCurator() {
    require(msg.sender == curator);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newCurator The address to transfer ownership to.
   */
  function transferCurationRights(address newCurator) public onlyOwner {
    require(newCurator != address(0));
    CurationRightsTransferred(curator, newCurator);
    curator = newCurator;
  }

}

contract Whitelist is Curatable {
    mapping (address => bool) public whitelist;


    function Whitelist() public {
    }


    function addInvestor(address investor) external onlyCurator {
        require(investor != 0x0 && !whitelist[investor]);
        whitelist[investor] = true;
    }


    function removeInvestor(address investor) external onlyCurator {
        require(investor != 0x0 && whitelist[investor]);
        whitelist[investor] = false;
    }


    function isWhitelisted(address investor) constant external returns (bool result) {
        return whitelist[investor];
    }

}