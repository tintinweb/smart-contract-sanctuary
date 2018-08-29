pragma solidity 0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9df9fcebf8ddfcf6f2f0fffcb3fef2f0">[email&#160;protected]</a>
// released under Apache 2.0 licence
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Registry is Ownable {

    struct ModuleForSale {
        uint price;
        bytes32 sellerUsername;
        bytes32 moduleName;
        address sellerAddress;
        bytes4 licenseId;
    }

    mapping(string => uint) internal moduleIds;
    mapping(uint => ModuleForSale) public modules;

    uint public numModules;
    uint public version;

    // ------------------------------------------------------------------------
    // Constructor, establishes ownership because contract is owned
    // ------------------------------------------------------------------------
    constructor() public {
        numModules = 0;
        version = 1;
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens (just in case)
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

    // ------------------------------------------------------------------------
    // Lets a user list a software module for sale in this registry
    // ------------------------------------------------------------------------
    function listModule(uint price, bytes32 sellerUsername, bytes32 moduleName, string usernameAndProjectName, bytes4 licenseId) public {
        // make sure input params are valid
        require(price != 0 && sellerUsername != "" && moduleName != "" && bytes(usernameAndProjectName).length != 0 && licenseId != 0);

        // make sure the name isn&#39;t already taken
        require(moduleIds[usernameAndProjectName] == 0);

        numModules += 1;
        moduleIds[usernameAndProjectName] = numModules;

        ModuleForSale storage module = modules[numModules];

        module.price = price;
        module.sellerUsername = sellerUsername;
        module.moduleName = moduleName;
        module.sellerAddress = msg.sender;
        module.licenseId = licenseId;
    }

    // ------------------------------------------------------------------------
    // Get the ID number of a module given the username and project name of that module
    // ------------------------------------------------------------------------
    function getModuleId(string usernameAndProjectName) public view returns (uint) {
        return moduleIds[usernameAndProjectName];
    }

    // ------------------------------------------------------------------------
    // Get info stored for a module by id
    // ------------------------------------------------------------------------
    function getModuleById(
        uint moduleId
    ) 
        public 
        view 
        returns (
            uint price, 
            bytes32 sellerUsername, 
            bytes32 moduleName, 
            address sellerAddress, 
            bytes4 licenseId
        ) 
    {
        ModuleForSale storage module = modules[moduleId];
        

        if (module.sellerAddress == address(0)) {
            return;
        }

        price = module.price;
        sellerUsername = module.sellerUsername;
        moduleName = module.moduleName;
        sellerAddress = module.sellerAddress;
        licenseId = module.licenseId;
    }

    // ------------------------------------------------------------------------
    // get info stored for a module by name
    // ------------------------------------------------------------------------
    function getModuleByName(
        string usernameAndProjectName
    ) 
        public 
        view
        returns (
            uint price, 
            bytes32 sellerUsername, 
            bytes32 moduleName, 
            address sellerAddress, 
            bytes4 licenseId
        ) 
    {
        uint moduleId = moduleIds[usernameAndProjectName];
        if (moduleId == 0) {
            return;
        }
        ModuleForSale storage module = modules[moduleId];

        price = module.price;
        sellerUsername = module.sellerUsername;
        moduleName = module.moduleName;
        sellerAddress = module.sellerAddress;
        licenseId = module.licenseId;
    }

    // ------------------------------------------------------------------------
    // Edit a module listing
    // ------------------------------------------------------------------------
    function editModule(uint moduleId, uint price, address sellerAddress, bytes4 licenseId) public {
        // Make sure input params are valid
        require(moduleId != 0 && price != 0 && sellerAddress != address(0) && licenseId != 0);

        ModuleForSale storage module = modules[moduleId];

        // prevent editing an empty module (effectively listing a module)
        require(
            module.price != 0 && module.sellerUsername != "" && module.moduleName != "" && module.licenseId != 0 && module.sellerAddress != address(0)
        );

        // require that sender is the original module lister, or the contract owner
        // the contract owner clause lets us recover a module listing if a dev loses access to their privkey
        require(msg.sender == module.sellerAddress || msg.sender == owner);

        module.price = price;
        module.sellerAddress = sellerAddress;
        module.licenseId = licenseId;
    }
}