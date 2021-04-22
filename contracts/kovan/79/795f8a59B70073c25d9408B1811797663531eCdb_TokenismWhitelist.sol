pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;


library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b)
        internal
        pure
        returns (int256)
    {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint256 minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint256 i = 0; i < minLength; i++)
            if (a[i] < b[i]) return -1;
            else if (a[i] > b[i]) return 1;
        if (a.length < b.length) return -1;
        else if (a.length > b.length) return 1;
        else return 0;
    }

    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return compare(_a, _b) == 0;
    }

    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string memory _haystack, string memory _needle)
        internal
        pure
        returns (int256)
    {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if (h.length < 1 || n.length < 1 || (n.length > h.length)) return -1;
        else if (h.length > (2**128 - 1))
            // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
            return -1;
        else {
            uint256 subindex = 0;
            for (uint256 i = 0; i < h.length; i++) {
                if (h[i] == n[0]) // found the first char of b
                {
                    subindex = 1;
                    while (
                        subindex < n.length &&
                        (i + subindex) < h.length &&
                        h[i + subindex] == n[subindex] // search until the chars don't match or until we reach the end of a or b
                    ) {
                        subindex++;
                    }
                    if (subindex == n.length) return int256(i);
                }
            }
            return -1;
        }
    }

    // function toBytes(address a) 
    //    internal
    //     pure
    //     returns (bytes memory) {
    // return abi.encodePacked(a);
    // }
}

pragma solidity ^0.5.0;

import "../utils/Context.sol";
import "../utils/stringUtils.sol";
import "openzeppelin-solidity/contracts/access/Roles.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

contract TokenismAdminWhitelist is Context {
    using Roles for Roles.Role;
    Roles.Role private _managerWhitelisteds;

    //  Add multiple admins option
     mapping(address => string) public admins;
     // add Multiple Banks aption
     mapping(address => string) public banks;

     address superAdmin;
     address feeAddress;

     //  Setting FeeStatus and fee Percent by Tokenism
    //  uint8 feeStatus;
    //  uint8 feePercent;
    bool public accreditationCheck = true;

    struct whitelistInfoManager {
        address wallet;
        string role;
        bool valid;
    }

    mapping(address => whitelistInfoManager) whitelistManagers;

     constructor() public {
        // admin = _msgSender();
        
        admins[_msgSender()] = "superAdmin";
        superAdmin = msg.sender;
       
    }
    function addSuperAdmin(address _superAdmin) public {

         require(msg.sender == superAdmin, "Only super admin can add admin");
         admins[_superAdmin] = "superAdmin";
         admins[superAdmin] = "dev";
         superAdmin = _superAdmin;
        
    }

    modifier onlyAdmin() {
       require(
          StringUtils.equal(admins[_msgSender()], "superAdmin") ||
          StringUtils.equal(admins[_msgSender()], "dev") ||
          StringUtils.equal(admins[_msgSender()], "fee") ||
          StringUtils.equal(admins[_msgSender()], "admin"),
                "Only admin is allowed"
        );
         _;
    }

    modifier onlyManager() {
    require(
            isWhitelistedManager(_msgSender()) || 
             StringUtils.equal(admins[_msgSender()], "superAdmin") ||
             StringUtils.equal(admins[_msgSender()], "dev") ||
             StringUtils.equal(admins[_msgSender()], "fee") ||
             StringUtils.equal(admins[_msgSender()], "admin"),
            "TokenismAdminWhitelist: caller does not have the Manager role"
        );
        _;
    }
    // Update Accredential Status
    function updateAccreditationCheck(bool status) public onlyManager {
        accreditationCheck = status;
    }

    // Roles
    function addWhitelistedManager(address _wallet, string memory _role)
        public
        onlyAdmin
    {
        require(
            StringUtils.equal(_role, "finance") ||
            StringUtils.equal(_role, "signer") ||
                StringUtils.equal(_role, "assets"),
            "TokenismAdminWhitelist: caller does not have the Manager role"
        );

        whitelistInfoManager storage newManager = whitelistManagers[_wallet];

        _managerWhitelisteds.add(_wallet);
        newManager.wallet = _wallet;
        newManager.role = _role;
        newManager.valid = true;
    }

    function getManagerRole(address _wallet)
        public
        view
        returns (string memory)
    {
        whitelistInfoManager storage m = whitelistManagers[_wallet];
        return m.role;
    }

    function updateRoleManager(address _wallet, string memory _role)
        public
        onlyAdmin
    {
         require(
            StringUtils.equal(_role, "finance") ||
            StringUtils.equal(_role, "signer") ||
                StringUtils.equal(_role, "assets"),
            "TokenismAdminWhitelist: Invalid  Manager role"
        );
        whitelistInfoManager storage m = whitelistManagers[_wallet];
        m.role = _role;
    }

    function isWhitelistedManager(address _wallet) public view returns (bool) {
        whitelistInfoManager memory m = whitelistManagers[_wallet];

        if (  StringUtils.equal(admins[_wallet], "superAdmin") ||
              StringUtils.equal(admins[_wallet], "dev") ||
              StringUtils.equal(admins[_wallet], "fee") ||
             StringUtils.equal(admins[_wallet], "admin")) return true;
        else if (!m.valid) return false;
        else return true;
    }

    // Only Super Admin
    function removeWhitelistedManager(address _wallet) public onlyAdmin {
        _managerWhitelisteds.remove(_wallet);
        whitelistInfoManager storage m = whitelistManagers[_wallet];
        m.valid = false;
    }

    function transferOwnership(address  _newAdmin)
        public
        returns (bool)
    {
        // admin = _newAdmin;
        require(_msgSender() == superAdmin, "Only super admin can add admin");
         admins[_newAdmin] = "superAdmin";
         admins[superAdmin] = "";
         superAdmin = _newAdmin;

        return true;
    }
    function addAdmin(address  _newAdmin, string memory _role)
    public
    onlyAdmin
    returns (bool)
    {
        
    require(_msgSender() == superAdmin || Address.isContract(_newAdmin) , "Only super admin can add admin");
    require(
              StringUtils.equal(_role, "dev") ||
              StringUtils.equal(_role, "fee") ||
              StringUtils.equal(_role, "admin"),
             "undefind admin role"
             );
        admins[_newAdmin] = _role;
        return true;
    }


 function addBank(address  _newBank, string memory _role)
    public
    onlyAdmin
    returns (bool)
    {
        
    require(_msgSender() == superAdmin || Address.isContract(_newBank) , "Only super admin can add admin");
    require(
              StringUtils.equal(_role, "bank") ,
             "undefind bank role"
             );
        banks[_newBank] = _role;
        return true;
    }

   // Function Add Fee Address 
   function addFeeAddress(address _feeAddress) public {
       require(_msgSender() == superAdmin, "Only super admin can add Fee Address");
      feeAddress = _feeAddress;
   }
   function getFeeAddress()public view returns(address){
       return feeAddress;
   } 

    // // Fee On off functionality
    // function setFeeStatus(uint8 option) public returns(bool){ // Fee option must be 0, 1
    //     require(msg.sender == superAdmin, "Only SuperAdmin on off fee");
    //     require(option == 1 || option == 0, "Wrong option call only 1 for on and 0 for off");
    //     require(feePercent > 0, "addPlatformFee! You must have set platform fee to on fee");
    //     feeStatus = option;
    //     return true;
    // }
    // // Get Fee Status
    //     return feeStatus;
    // }
    // // Add Fee Percent or change Fee Percentage on Tokenism Platform
    // function addPlatformFee(uint8 _fee)public returns(bool){
    //     require(msg.sender == superAdmin, "Only SuperAmin change Platform Fee");
    //     require(_fee > 0 && _fee < 100, "Wrong Percentage!  Fee must be greater 0 and less than 100");
    //     feePercent = _fee;
    //     return true;

    // }
    //  return feePercent;
    // }
    function isAdmin(address _calle)public view returns(bool) {
        if(StringUtils.equal(admins[_calle] , "superAdmin") ||
             StringUtils.equal(admins[_calle] , "dev") ||
             StringUtils.equal(admins[_calle] , "fee") ||
             StringUtils.equal(admins[_calle] , "admin")){
                 return true;
             }
             return false;
        //  return admins[_calle];   
    }
    function isSuperAdmin(address _calle) public view returns(bool){
        if(StringUtils.equal(admins[_calle] , "superAdmin")){
            return true;
        }
        return false;
    }

    function isBank(address _calle) public view returns(bool){
        if(StringUtils.equal(banks[_calle] , "bank")){
            return true;
        }
        return false;
    }
   function isManager(address _calle)public returns(bool) {
        whitelistInfoManager memory m = whitelistManagers[_calle];
        return m.valid;
   }
}

pragma solidity ^0.5.0;
import "../utils/Context.sol";
import "./TokenismAdminWhitelist.sol";
import "openzeppelin-solidity/contracts/access/Roles.sol";

contract TokenismWhitelist is Context, TokenismAdminWhitelist {
    using Roles for Roles.Role;
    Roles.Role private _userWhitelisteds;
    mapping(string=> bool) symbolsDef;

    struct  whitelistInfo {
        bool valid;
        address wallet;
        bool kycVerified;
        bool accredationVerified;
        uint256 accredationExpiry;
        uint256 taxWithholding;
        string  userType;
        bool suspend;
    }
    mapping(address => whitelistInfo) public whitelistUsers;
    address[] public userList;

    // userTypes = Basic || Premium
    function addWhitelistedUser(address _wallet, bool _kycVerified, bool _accredationVerified, uint256 _accredationExpiry) public onlyManager {
        if(_accredationVerified)
            require(_accredationExpiry >= block.timestamp, "accredationExpiry: Accredation Expiry time is before current time");

        _userWhitelisteds.add(_wallet);
        whitelistInfo storage newUser = whitelistUsers[_wallet];

        newUser.valid = true;
        newUser.suspend = false;
        newUser.taxWithholding = 0;

        newUser.wallet = _wallet;
        newUser.kycVerified = _kycVerified;
        newUser.accredationExpiry = _accredationExpiry;
        newUser.accredationVerified = _accredationVerified;
        newUser.userType = "Basic";
        // maintain whitelist user list
        userList.push(_wallet);
    }

    function getWhitelistedUser(address _wallet) public view returns (address, bool, bool, uint256, uint256){
        whitelistInfo memory u = whitelistUsers[_wallet];
        return (u.wallet, u.kycVerified, u.accredationExpiry >= block.timestamp, u.accredationExpiry, u.taxWithholding);
    }

    function updateKycWhitelistedUser(address _wallet, bool _kycVerified) public onlyManager {
        whitelistInfo storage u = whitelistUsers[_wallet];
        u.kycVerified = _kycVerified;
    }

    function updateAccredationWhitelistedUser(address _wallet, uint256 _accredationExpiry) public onlyManager {
        require(_accredationExpiry >= block.timestamp, "accredationExpiry: Accredation Expiry time is before current time");

        whitelistInfo storage u = whitelistUsers[_wallet];
        u.accredationExpiry = _accredationExpiry;
    }

    function updateTaxWhitelistedUser(address _wallet, uint256 _taxWithholding) public onlyManager {
        whitelistInfo storage u = whitelistUsers[_wallet];
        u.taxWithholding = _taxWithholding;
    }

    function suspendUser(address _wallet) public onlyManager {
        whitelistInfo storage u = whitelistUsers[_wallet];
        u.suspend = true;
    }

    function activeUser(address _wallet) public onlyManager {
        whitelistInfo storage u = whitelistUsers[_wallet];
        u.suspend = false;
    }

    function updateUserType(address _wallet, string memory _userType) public onlyManager {
        require(
            StringUtils.equal(_userType , 'Basic') || StringUtils.equal(_userType , 'Premium')
        , "Please Enter Valid User Type");
        whitelistInfo storage u = whitelistUsers[_wallet];
        u.userType = _userType;
    }

// Check user status
    function isWhitelistedUser(address wallet) public view returns (uint) {
        whitelistInfo storage u = whitelistUsers[wallet];
    whitelistInfoManager memory m = whitelistManagers[wallet];

       /* Wallet is Super Admin */
      if(StringUtils.equal(admins[wallet], "superAdmin")) return 100;

       /* Wallet is Fee Admin */
        if(StringUtils.equal(admins[wallet], "fee"))   return 110;

         /* Wallet is Dev Admin */
        if(StringUtils.equal(admins[wallet], "dev"))   return 111;

         /* Wallet is Simple Admin */
        if(StringUtils.equal(admins[wallet], "admin")) return 112;

        /* Wallet is Manager Finance */
        if(StringUtils.equal(m.role, "finance"))     return 120;

         /* Wallet is Manager asset */
         if(StringUtils.equal(m.role, "assets"))  return 121;

           /* Wallet is Manager asset */
         if(StringUtils.equal(m.role, "signer"))  return 122;
         
           /* Wallet is Manager asset */
         if(StringUtils.equal(banks[wallet], "bank"))  return 130;
         
        // /* Any type of Manager */
        // if(isWhitelistedManager(wallet)) return 200;

        /* Wallet is not Added */
        else if(!u.valid) return 404;

        /* If User is Suspendid */
        else if(u.suspend) return 401;

        /* Wallet KYC Expired */
        else if(!u.kycVerified) return 400;

        /* If Accredation check is false then Send 200 */
        else if(!accreditationCheck) return 200;

        /* Wallet AML Expired */
        else if(u.accredationExpiry <= block.timestamp)
            return 201;

        /* Wallet is Whitelisted */
        else return 200;
    }

    function removeWhitelistedUser(address _wallet) public onlyManager {
        _userWhitelisteds.remove(_wallet);
        whitelistInfo storage u = whitelistUsers[_wallet];
        u.valid = false;
    }

    /* Symbols Deployed Add to Contract */
    function addSymbols(string calldata _symbols)
        external
        // onlyManager
        returns(bool){
            if(symbolsDef[_symbols] == true)
                return false;
            else{
                symbolsDef[_symbols]=true;
                return true;
            }
        }
    // On destroy Symbol Removed
    function removeSymbols(string calldata _symbols)
        external
        // onlyManager
        returns(bool){
            if(symbolsDef[_symbols] == true)
            symbolsDef[_symbols] = false;
            return true;


        }

    function closeTokenismWhitelist() public {
      require(StringUtils.equal(admins[_msgSender()], "superAdmin"), "only superAdmin can destroy Contract");
    selfdestruct(msg.sender);
    } 


    function storedAllData()public view onlyAdmin returns(
        address[] memory _userList,
        bool[] memory _validity,
        bool[] memory _kycVery,
        bool[] memory _accredationVery,
        uint256[] memory _accredationExpir,
        uint256[] memory _taxWithHold,
        uint256[] memory _userTypes
        )
        {

            uint size = userList.length;

        bool[] memory validity = new bool[](size);
        bool[] memory kycVery = new bool[](size);
        bool[] memory accredationVery = new bool[](size);
        uint256[] memory accredationExpir = new uint256[](size);
        uint256[] memory taxWithHold = new uint256[](size);
        uint256[] memory userTypes = new uint256[](size);
            uint i;
            for(i=0; i<userList.length; i++){
                        if(whitelistUsers[userList[i]].valid){
                            validity[i]= true;
                        }
                        else{
                        validity[i]=false;   
                        }
                    if(whitelistUsers[userList[i]].kycVerified)
                    {
                    kycVery[i] = true;
                    }
                    else{
                    kycVery[i] = false;
                    }
                    if(whitelistUsers[userList[i]].accredationVerified)
                    {
                    accredationVery[i] = true;
                    }
                    else{
                    accredationVery[i] = false;
                    }
                    accredationExpir[i] = (whitelistUsers[userList[i]].accredationExpiry);
                    taxWithHold[i] = (whitelistUsers[userList[i]].taxWithholding);
                    if(StringUtils.equal(whitelistUsers[userList[i]].userType, "Basic")){
                        userTypes[i] = 20; 
                    }
                    else
                    userTypes[i] = 100;
            }
            return (userList,validity, kycVery,accredationVery, accredationExpir, taxWithHold,userTypes);
        }



    function userType(address _caller) public view returns(bool){
        if(StringUtils.equal(whitelistUsers[_caller].userType, "Premium"))
        return true;
        return false;
    }
}

pragma solidity ^0.5.2;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

pragma solidity ^0.5.2;

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "petersburg",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}