// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title User Whitelisting
/// @author Aman Ullah & Anns Khalid
/// @notice You can use this contract for only user Whitelisting
/// @dev All function calls are currently implemented without side effects

// import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./WhitelistingDeveloper.sol";

contract Whitelisting is WhitelistingDeveloper {
    struct UserWhitlisting {
        address wallet;
        bool kycVerified;
        bool fillerVerified;
        string userType;
        uint256 fillerExpiry;
        bool isActive;
        bool valid;
    }

    mapping(address => UserWhitlisting) public whiteListedUsers;

    address[] public userList;

    /**
     * @dev this function will add new user to whitelisting list
     * @param  _wallet will provide public address of new user
     * @param _kycVerified will contain kyc status of user
     * @param _fillerVerified will contain filler status of user
     * @param _userType will contain user type of user
     */

    function addWhitelistedUser(
        address _wallet,
        bool _kycVerified,
        bool _fillerVerified,
        string memory _userType
    ) public onlyDeveloper {
        UserWhitlisting storage newUser = whiteListedUsers[_wallet];
        require(_wallet != address(0), "Please provide valid address");
        require(
            newUser.wallet != _wallet,
            "Whitelisting: User is already added"
        );
        newUser.wallet = _wallet;
        newUser.kycVerified = _kycVerified;
        newUser.fillerVerified = _fillerVerified;
        newUser.userType = _userType;
        newUser.fillerExpiry = (block.timestamp + 60 * 86400);
        newUser.isActive = true;
        newUser.valid = true;
        userList.push(_wallet);
    }

    /**
    @dev this function will return the defined status of user
    @param _wallet contain address of user
    */
    function isWhitelisted(address _wallet) public view returns (uint256) {
        UserWhitlisting memory user = whiteListedUsers[_wallet];
        WhitelistAgent memory agent = agents[_wallet];

        if (Address.isContract(_wallet) && whitelistContracts[_wallet]) {
            return 120;
        }

        /* Wallet is Admin */
        if (admins[_wallet]) return 100;

        /* Wallet is Developer */
        if (developers[_wallet]) return 110;

        /* Wallet is user Agent  */
        if (agent.wallet == _wallet) {
            if (!agent.valid) return 404;
            else if (!agent.isActive) return 203;
            else if (agent.licenceExpiry < block.timestamp) return 200;
            else return 200;
        }
        if (user.wallet == _wallet) {
            if (!user.valid) return 404;
            else if (!user.isActive) return 303;
            else if (!user.kycVerified) return 302;
            else if (user.fillerExpiry < block.timestamp) return 300;
            else return 300;
        }
        return 404;
    }

    /**
    @dev this function will return data of whitelisted user
    @param _wallet contain address of user
     will return data associated with user like wallet, kycVerified,  fillerVerified , uintType , fillerExpiry , isActive, valid
     */
    function getWhitelistedUser(address _wallet)
        public
        view
        returns (
            address wallet,
            bool kycVerified,
            bool fillerVerified,
            string memory userType,
            uint256 fillerExpiry,
            bool isActive,
            bool valid
        )
    {
        require(
            _wallet != address(0),
            "Whitelisting: please Provide valid address "
        );
        UserWhitlisting storage user202 = whiteListedUsers[_wallet];
        return (
            user202.wallet,
            user202.kycVerified,
            user202.fillerVerified,
            user202.userType,
            user202.fillerExpiry,
            user202.isActive,
            user202.valid
        );
    }

    /**
    @dev this function will suspend users
    @param _wallet contains address of user
    */
    function suspendUser(address _wallet) public onlyDeveloper {
        require(_wallet != address(0), "Please Provide valid address");
        UserWhitlisting storage userInfo = whiteListedUsers[_wallet];
        userInfo.isActive = false;
    }

    function getUserStatus(address _wallet) public view returns (bool success) {
        require(_wallet != address(0), "Please Provide valid address");
        UserWhitlisting storage userInfo = whiteListedUsers[_wallet];
        return (userInfo.isActive);
    }

    /**
    @dev this function will update kyc status of user
    @param _wallet contains address of user
    @param _kycStatus contains kyc status
     */
    function updateKYC(address _wallet, bool _kycStatus) public onlyDeveloper {
        UserWhitlisting storage userInfo = whiteListedUsers[_wallet];
        userInfo.kycVerified = _kycStatus;
    }

    function getKycStatus(address _wallet)
        public
        view
        onlyDeveloper
        returns (bool)
    {
        require(_wallet != address(0), "Please Provide valid address");
        UserWhitlisting storage userInfo = whiteListedUsers[_wallet];
        return (userInfo.kycVerified);
    }

    function updateFillerStatus(address _wallet, uint256 _fillerExpiry)
        public
        onlyDeveloper
    {
        require(_wallet != address(0), "Please Provide valid address");
        UserWhitlisting storage userInfo = whiteListedUsers[_wallet];
        require(
            block.timestamp > userInfo.fillerExpiry,
            "Already a verified filler!"
        );
        userInfo.fillerExpiry = _fillerExpiry;
    }

    /**
     * @dev this function will check for user filler status accroding to defined timestamp
     * will return true or false
     * @param _wallet argument contain address of user
     */
    function getFillerStatus(address _wallet) external view returns (bool) {
        UserWhitlisting storage userInfo = whiteListedUsers[_wallet];
        return block.timestamp < userInfo.fillerExpiry;
    }

    /**
    @dev This function will remove user from  AKRU.CO platfrom
    @param _wallet contain address of user
    */
    function removeUser(address _wallet)
        public
        onlyDeveloper
        returns (bool success)
    {
        UserWhitlisting storage userInfo = whiteListedUsers[_wallet];
        require(userInfo.wallet != address(0), "Whitelisting : user not found");
        for (uint256 i; i < userList.length; i++) {
            if (userList[i] == _wallet) {
                delete (whiteListedUsers[_wallet]);
                delete (userList[i]);
                return true;
            }
        }
    }

    /**
     * @dev this function will return user data in seprate array
     * @return kyc_instance in bool,  filler_Expiry in unit256 , _userType in string , _isActive in bool, _userList in address
     */
    function getWhitelistedUsers()
        public
        view
        onlyAdmin
        returns (
            bool[] memory kyc_instance,
            uint256[] memory filler_Expiry,
            string[] memory _userType,
            bool[] memory _isActive,
            address[] memory _userList
        )
    {
        uint256 size = userList.length;
        bool[] memory kyc_Array = new bool[](size);
        uint256[] memory fillerExpiry_Array = new uint256[](size);
        string[] memory userType_Array = new string[](size);
        bool[] memory isActive_Array = new bool[](size);
        for (uint256 i; i < size; i++) {
            UserWhitlisting memory instanceUser = whiteListedUsers[userList[i]];
            kyc_Array[i] = instanceUser.kycVerified;
            fillerExpiry_Array[i] = instanceUser.fillerExpiry;
            userType_Array[i] = instanceUser.userType;
            isActive_Array[i] = instanceUser.isActive;
        }
        return (
            kyc_Array,
            fillerExpiry_Array,
            userType_Array,
            isActive_Array,
            userList
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract WhitelistingDeveloper is Context {
    // /**
    // * @dev this structure will store data of Developer
    // */
    // struct WhitelistDeveloper{
    //     address wallet;
    //     bool licence;
    //     uint256 licenceExpiry;
    //     bool valid;
    //     uint256 serviceFee;
    //     bool isActive;
    // }

    /**
     * @dev this structure will store data of Agent
     */
    struct WhitelistAgent {
        address wallet;
        uint256 licenceExpiry;
        bool valid;
        uint256 commission;
        bool isActive;
    }

    /* this mapping will store other types, specfic to developerAdmin roles */
    mapping(address => mapping(address => bytes32)) internal developerAdmins;
    /* this mapping will store admins address */
    mapping(address => bool) internal admins;
    /* this mapping will store developer  struct data */
    mapping(address => bool) internal developers;
    /* this mapping will store agents struct data  */
    mapping(address => WhitelistAgent) internal agents;

    /* will store whitelisted contracts */
    mapping(address => bool) internal whitelistContracts;

    /* for back up porpuse we will store all the mapping data in array */
    /* this array will store agentList address */
    address[] internal agentList;
    /* this array will store developerList address */
    address[] internal developerList;
    /* this array will store list of admins */
    address[] internal adminsList;
    /* will store list of contract address */
    address[] internal contractList;

    constructor() {
        admins[_msgSender()] = true;
        adminsList.push(_msgSender());
    }

    //modifier --admin
    modifier onlyAdmin() {
        require(admins[_msgSender()], "Whitelisting: Only admin allowed");
        _;
    }
    //modifier --developer
    modifier onlyDeveloper() {
        require(
            (isWhitelistedDeveloper(_msgSender()) || admins[_msgSender()]),
            "Whitelisting: Only developer is allowed"
        );
        _;
    }

    /**
    @dev add new developer
    @param _wallet address of developer
    */
    function addDeveloper(address _wallet) public onlyAdmin {
        require(_wallet != address(0), "Please provide valid address");
        developers[_wallet] = true;
    }

    /**
     * @dev this function will check that address provided is developer or not
     * @param _wallet this will contain address to be check for developer role.
     */
    function isWhitelistedDeveloper(address _wallet)
        public
        view
        returns (bool)
    {
        return developers[_wallet];
    }

    /**
    @dev removes already added developer
    @param _wallet address of developer
    */
    function removeDeveloper(address _wallet) public onlyAdmin {
        require(_wallet != address(0), "Please provide valid address");
        developers[_wallet] = false;
    }

    /**
    @dev add new developerAdmin
    @param _developerAdmin address of developerAdmin
    @param _role role of that developerAdmin in bytes32
    */
    function addDeveloperAdmin(address _developerAdmin, bytes32 _role)
        public
        onlyDeveloper
    {
        require(
            _developerAdmin != address(0),
            "DeveloperAdmin: Please provide valid address"
        );
        require(
            developerAdmins[_msgSender()][_developerAdmin] == bytes32(0x0),
            "DeveloperAdmin: Admin is already whitelisted"
        );

        developerAdmins[_msgSender()][_developerAdmin] = _role;
    }

    /**
    @dev removes already added developerAdmin
    @param _developerAdmin address of developerAdmin
    */
    function removeDeveloperAdmin(address _developerAdmin)
        public
        onlyDeveloper
    {
        require(
            _developerAdmin != address(0),
            "DeveloperAdmins: Please provide valid address"
        );
        delete (developerAdmins[_msgSender()][_developerAdmin]);
    }

    /**
    @dev removes already added developer & developerAdmin
    @param _developer address of developer
    @param _developerAdmin address of developerAdmin
    */
    function removeDeveloperAdmin(address _developer, address _developerAdmin)
        public
        onlyAdmin
    {
        require(
            _developerAdmin != address(0),
            "DeveloperAdmins: Please provide valid address"
        );
        delete developerAdmins[_developer][_developerAdmin];
    }

    /**
    @dev updates the role for developerAdmin
    @param _developerAdmin address of developerAdmin
    @param _updatedRole update the given role
     */
    function updateDeveloperAdminRole(
        address _developerAdmin,
        bytes32 _updatedRole
    ) public onlyDeveloper {
        require(
            _developerAdmin != address(0),
            "DeveloperAdmin: Please provide valid address"
        );
        require(
            developerAdmins[_msgSender()][_developerAdmin] != bytes32(0x0),
            "DeveloperAdmin: This user is not whitelisted"
        );
        developerAdmins[_msgSender()][_developerAdmin] = _updatedRole;
    }

    /**
     * @dev this function will check that address provided is admin or not
     * @param _developer this contains the address to be check for developer role
     * @param _developerAdmin this contains the address to be check for admin role
     */
    function isDeveloperAdminWhitelisted(
        address _developer,
        address _developerAdmin
    ) public view returns (bool success) {
        require(
            _developer != address(0) || _developerAdmin != address(0),
            "DeveloperAdmin: Please provide valid address"
        );
        if (developerAdmins[_developer][_developerAdmin] != bytes32(0x0))
            return true;
        else return false;
    }

    /**
       @dev this function will return role of admin in bytes32
        */
    function getDeveloperAdminRole(address _developerAdmin)
        public
        view
        returns (bytes32)
    {
        return developerAdmins[_msgSender()][_developerAdmin];
    }

    /**
     * @dev addAgent this function will register agent
     * @param _wallet contain address of agent
     * @param _licenseExpiry contain expiry date of licence
     * @param _commission contain commision of agent
     */
    function addAgent(
        address _wallet,
        uint256 _licenseExpiry,
        uint256 _commission
    ) public onlyDeveloper {
        require(_wallet != address(0), "Please provide valid address");
        WhitelistAgent storage newAgent = agents[_wallet];
        require(!newAgent.valid, "Agent is already added");
        newAgent.wallet = _wallet;
        newAgent.licenceExpiry = _licenseExpiry;
        newAgent.commission = _commission;
        newAgent.valid = true;
        newAgent.isActive = true;
        agentList.push(_wallet);
    }

    function getAgent(address _wallet)
        public
        view
        returns (
            address _walletAgent,
            uint256 _licenseExpiry,
            uint256 _commission,
            bool _valid,
            bool _isActive
        )
    {
        require(_wallet != address(0), "Please provide valid address");
        WhitelistAgent storage agent202 = agents[_wallet];
        return (
            agent202.wallet,
            agent202.licenceExpiry,
            agent202.commission,
            agent202.valid,
            agent202.isActive
        );
    }

    /**
     * @dev this function will susped agent
     * @param _wallet contain address of agent
     */
    function suspendAgent(address _wallet) public onlyDeveloper {
        WhitelistAgent storage agent = agents[_wallet];
        require(agent.valid, "Agent record not found");
        agent.valid = false;
    }

    /**
     * @dev this function will update hash of licence 
     * @param _wallet contain address of agent
     @param _licenseExpiry contain expiry date of licence
     */
    function updateLicenseExpiry(address _wallet, uint256 _licenseExpiry)
        public
        onlyDeveloper
    {
        WhitelistAgent storage agent = agents[_wallet];
        require(agent.valid, "Agent is suspended");
        agent.licenceExpiry = _licenseExpiry;
    }

    /**
     @dev this function would remove agent from platform
     @param _wallet contain address of agent
      */
    function removeAgent(address _wallet) public onlyDeveloper {
        WhitelistAgent storage agent = agents[_wallet];
        require(agent.valid, "Agent record not found");
        for (uint256 i = 0; i < agentList.length; i++) {
            if (agentList[i] == _wallet) {
                delete (agentList[i]);
                delete (agents[_wallet]);
            }
        }
    }

    /**
     @dev this function would update commission of agent 
     @param _wallet contain address of agent
     @param _commission contain updated value of agent commission
     */
    function updateAgentCommission(address _wallet, uint256 _commission)
        public
        onlyDeveloper
    {
        WhitelistAgent storage agent = agents[_wallet];
        require(!agent.valid, "Agent record not found");
        agent.commission = _commission;
    }

    /**
     @dev this function would check agent licence Validity
     @param _wallet contain address of agent 
     @return return true if licence is valid 
     */
    function isValidAgent(address _wallet) public view returns (bool) {
        WhitelistAgent storage agent = agents[_wallet];
        require(agent.valid, "Agent record not found");
        return (agent.licenceExpiry > block.timestamp);
    }

    /**
      @dev add admin
      @param _wallet contain address of admin
      */
    function addAdmin(address _wallet) public onlyAdmin {
        admins[_wallet] = true;
        adminsList.push(_wallet);
    }

    /**
      @dev this function will admin 
      @param _wallet contain address of admin
      */
    function removeAdmin(address _wallet) public onlyAdmin {
        for (uint256 i; i < adminsList.length; i++) {
            if (adminsList[i] == _wallet) {
                admins[_wallet] = false;
                delete adminsList[i];
            }
        }
    }

    /**
      @dev this funtion will return if the address is Admin
      @param _wallet address of user
       */
    function isAdmin(address _wallet) public view returns (bool) {
        return admins[_wallet];
    }

    /**
      @dev this funtion will add  address  of contract 
      @param _contractAddress address of contract
       */
    function addWhitelistContract(address _contractAddress)
        public
        onlyDeveloper
    {
        require(
            Address.isContract(_contractAddress),
            "Whitelisting: Not Contract Address"
        );
        require(
            !whitelistContracts[_contractAddress],
            "Whitelisting:  Contract is already whitelisted"
        );
        whitelistContracts[_contractAddress] = true;
        contractList.push(_contractAddress);
    }

    /**
      @dev this funtion will delete address  of contract from whitelist
      @param _contractAddress address of contract
       */
    function removeWhitelistContract(address _contractAddress)
        public
        onlyDeveloper
    {
        require(
            Address.isContract(_contractAddress),
            "Whitelisting: Not Contract Address"
        );
        require(
            whitelistContracts[_contractAddress],
            "contract address is not whitelisted"
        );

        for (uint256 i; i < contractList.length; i++) {
            if (contractList[i] == _contractAddress) {
                whitelistContracts[_contractAddress] = false;
                delete contractList[i];
            }
        }
    }

    /**
      @dev this funtion will return true if address   of contract is whitelisted
      @param _contractAddress address of contract
       */
    function isWhitelistContract(address _contractAddress)
        public
        view
        returns (bool)
    {
        require(
            Address.isContract(_contractAddress),
            "Whitelisting: Not Contract Address"
        );
        return whitelistContracts[_contractAddress];
    }

    /**
      @dev this funtion will return list of whitelisted contracts
       */
    function whitelistContractList()
        public
        view
        onlyAdmin
        returns (address[] memory)
    {
        return contractList;
    }

    /**
       @dev this function will return list of admins
        */
    function getAdmins() public view onlyAdmin returns (address[] memory) {
        return adminsList;
    }

    /**
       @dev this function will return list of admins
        */
    function getAgents() public view onlyAdmin returns (address[] memory) {
        return agentList;
    }

    /**
       @dev this function will return list of admins
        */
    function getDevelopers() public view onlyAdmin returns (address[] memory) {
        return developerList;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}