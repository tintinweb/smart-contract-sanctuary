/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

//SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

interface IReferralManager {
    event Register(address UserAcc, string UserID, string ReferrerID);
    event UserChangeAddress(
        address FromAddress,
        address ToAddress,
        uint256 ChangeDate
    );
    event VerifyNewAddress(
        address FromAddress,
        address ToAddress,
        uint256 VerifyDate
    );
    event RevokeChangeAddress(
        address FromAddress,
        address ToAddress,
        uint256 RevokeDate
    );

    function register(string memory referrerId) external returns (bool);

    function registerID(string memory newUserId, address payable newUserAcc)
        external
        returns (bool);

    function referByAddr(address userAddress) external view returns (address);

    function usersInfo(address userAddress)
        external
        view
        returns (
            string memory,
            address,
            uint256,
            string memory
        );

    function refersInfo(string memory refersID)
        external
        view
        returns (
            string memory,
            address,
            uint256,
            bool,
            bool
        );

    function contractInfo()
        external
        view
        returns (
            uint32,
            uint256,
            uint256,
            string memory,
            bool,
            bool,
            address
        );

    function userChangeAddr(address newAddress) external payable returns (bool);

    function revokeChangeAddr() external returns (bool);

    function verifyChangeAddr(address oldAddress) external returns (bool);

    function changeAddrInfo(address userAddr)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256
        );

    function adminAccess(address adminAcc) external view returns (bool);

    function operatorAccess(address operatorAcc) external view returns (bool);

    function setAdmin(address adminAcc, bool access) external;

    function setOperator(address operatorAcc, bool access) external;

    function setRewardActive(address userAddress, bool activate) external;
}

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;

        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(
            _initializing ? _isConstructor() : !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status = _NOT_ENTERED;

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract ReferralManager is IReferralManager, Initializable, ReentrancyGuard {
    using Address for address;

    // Info of each Registered user.
    struct UserInfo {
        address payable userAcc; // User Address.
        address oldAcc; // User Old Address.
        string userId; // User Unique ID.
        string referrerId; // Referrer ID.
        uint256 registerDate; // Register Date.
        uint256 referredCount; // referrer_address -> num_of_referred
        bool excludedReferrer; // Addresses that excluded from referral
        bool rewardActive; // Address status for received referral bonus
        bool changeAddr; // Change Address Request
    }

    // Info of each users that stakes LP tokens.
    mapping(string => UserInfo) private userInfo;
    // Info of each users unique ID
    mapping(address => string) private userId;
    // Change new user record
    mapping(address => address) private changeAddrTo;
    // Change new user record
    mapping(address => address) private changeAddrFrom;
    // Change new user record
    mapping(address => uint256) private addrRevokeTime;
    // Contract Admin
    mapping(address => bool) private admin;
    // Contract Operator
    mapping(address => bool) private operator;

    string private constant NAME = "Referral Manager";
    string private constant VERSION = "1.0.0";
    string private genesisId;
    address private _owner;
    uint32 private totalUsers;
    uint256 private changeAddrFee = 500 finney;
    uint256 private revokeTime = 300; //1209600;
    bool private paused;
    bool private changeAddrPaused;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(admin[msg.sender], "Admin::caller is not an admin");
        _;
    }

    /**
     * @dev Throws if called by any account other than the operator.
     */
    modifier onlyOperator() {
        require(operator[msg.sender], "Operator::caller is not an operator");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function init(string memory GenesisID, address payable GenesisAcc)
        public
        initializer
    {
        GenesisID = upper(GenesisID);
        userId[GenesisAcc] = GenesisID;
        UserInfo storage none = userInfo["REPLACE"];
        none.userId = "REPLACE";
        none.registerDate = 1;
        UserInfo storage genesis = userInfo[GenesisID];
        genesis.userAcc = GenesisAcc;
        genesis.userId = GenesisID;
        genesis.referrerId = GenesisID;
        genesis.registerDate = block.timestamp;
        genesis.rewardActive = true;
        genesisId = GenesisID;
        operator[msg.sender] = true;
        admin[GenesisAcc] = true;
        admin[msg.sender] = true;
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        operator[_owner] = false;
        operator[newOwner] = true;
        admin[_owner] = false;
        admin[newOwner] = true;
        _owner = newOwner;
    }

    // register using referrarID
    function register(string memory referrerId)
        public
        override
        nonReentrant
        returns (bool)
    {
        referrerId = upper(referrerId);
        UserInfo storage user = userInfo[userId[msg.sender]];
        UserInfo storage refer = userInfo[referrerId];
        require(!paused, "Referral::Registration Paused");
        require(!refer.excludedReferrer, "Referral::Referrer Blacklisted");
        require(refer.userAcc != address(0), "Referral::Referrer Not Exist");
        require(
            refer.userAcc != msg.sender,
            "Referral::Forbidden Refer Yourself"
        );
        require(user.registerDate <= 0, "Referral::Already Registered");
        require(
            addrRevokeTime[msg.sender] == 0,
            "Referral::Address cannot use for register"
        );
        // Register New User
        string memory userIdCreated = _getUserId();
        userId[msg.sender] = userIdCreated;
        UserInfo storage newuser = userInfo[userIdCreated];
        newuser.userAcc = msg.sender;
        newuser.userId = userIdCreated;
        newuser.referrerId = refer.userId;
        newuser.registerDate = block.timestamp;
        refer.referredCount += 1;
        totalUsers += 1;
        emit Register(newuser.userAcc, newuser.userId, newuser.referrerId);
        return true;
    }

    // register using custom userID (onlyadmin)
    function registerID(string memory createUserId, address payable newUserAcc)
        public
        override
        onlyAdmin
        nonReentrant
        returns (bool)
    {
        string memory newUserId = upper(createUserId);
        UserInfo storage checkId = userInfo[newUserId];
        UserInfo storage user = userInfo[userId[newUserAcc]];
        UserInfo storage refer = userInfo[userId[msg.sender]];
        require(newUserAcc != address(0), "Referral::User is Zero Address");
        require(!paused, "Referral::Registration Paused");
        require(!refer.excludedReferrer, "Referral::Referrer Blacklisted");
        require(refer.userAcc != address(0), "Referral::Referrer Not Exist");
        require(
            refer.userAcc != newUserAcc,
            "Referral::Forbidden Refer Yourself"
        );
        require(user.registerDate <= 0, "Referral::Already Registered");
        require(checkId.registerDate <= 0, "Referral::UserID Already Exists");
        require(
            addrRevokeTime[newUserAcc] == 0,
            "Referral::Address cannot use for register"
        );
        // Register New User
        userId[newUserAcc] = newUserId;
        UserInfo storage newuser = userInfo[newUserId];
        newuser.userAcc = newUserAcc;
        newuser.userId = newUserId;
        newuser.referrerId = refer.userId;
        newuser.registerDate = block.timestamp;
        refer.referredCount += 1;
        totalUsers += 1;
        emit Register(newuser.userAcc, newuser.userId, newuser.referrerId);
        return true;
    }

    // Generate UserID
    function _getUserId() internal view returns (string memory) {
        bool userExist = true;
        uint8 num = 1;
        while (userExist) {
            string memory createId = string(
                abi.encodePacked(_toString(num), "XL", _toString(block.number))
            );
            UserInfo memory checkuser = userInfo[createId];
            if (
                keccak256(bytes(checkuser.userId)) != keccak256(bytes(createId))
            ) {
                return createId;
            }
            num++;
        }
    }

    // string uppercase function
    function upper(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    // string uppercase function
    function _upper(bytes1 _b1) internal pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    // convert uint to string type
    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // view referrer address for referred user
    function referByAddr(address userAddress)
        public
        view
        override
        returns (address ReferBy)
    {
        UserInfo memory user = userInfo[userId[userAddress]];
        UserInfo memory refer = userInfo[user.referrerId];
        return refer.userAcc;
    }

    // view users Status
    function usersInfo(address userAddress)
        public
        view
        override
        returns (
            string memory UserID,
            address UserAddress,
            uint256 RegisterDate,
            string memory ReferrerID
        )
    {
        UserInfo memory user = userInfo[userId[userAddress]];
        return (user.userId, user.userAcc, user.registerDate, user.referrerId);
    }

    // view referrers info
    function refersInfo(string memory refersID)
        public
        view
        override
        returns (
            string memory ReferrerID,
            address ReferrerAddress,
            uint256 ReferredCount,
            bool ExcludedReferrer,
            bool RewardActive
        )
    {
        refersID = upper(refersID);
        UserInfo memory refer = userInfo[refersID];
        return (
            refer.userId,
            refer.userAcc,
            refer.referredCount,
            refer.excludedReferrer,
            refer.rewardActive
        );
    }

    // change user address to new address
    function userChangeAddr(address newAddress)
        public
        payable
        override
        returns (bool)
    {
        UserInfo storage user = userInfo[userId[msg.sender]];
        UserInfo memory cNewAddr = userInfo[userId[newAddress]];
        require(!changeAddrPaused, "Referral::change addr paused");
        require(!user.excludedReferrer, "Referral::caller addr Blacklist");
        require(user.userAcc == msg.sender, "Referral::ur addr not registered");
        require(!user.changeAddr, "Referral::already request");
        require(cNewAddr.registerDate <= 0, "Referral::new addr already used");
        require(
            addrRevokeTime[newAddress] == 0,
            "Referral::Address cannot use for register"
        );
        admin[msg.sender]
            ? Address.sendValue(msg.sender, msg.value)
            : require(
                msg.value >= changeAddrFee,
                "Referral::BNB fee below required amount"
            );
        UserInfo memory genesis = userInfo[genesisId];
        Address.sendValue(genesis.userAcc, msg.value);
        user.changeAddr = true;
        changeAddrTo[msg.sender] = newAddress;
        changeAddrFrom[newAddress] = msg.sender;
        addrRevokeTime[msg.sender] = block.timestamp;
        addrRevokeTime[newAddress] = block.timestamp;
        emit UserChangeAddress(
            changeAddrFrom[newAddress],
            changeAddrTo[msg.sender],
            block.timestamp
        );
        return true;
    }

    // revoke permit of change address
    function revokeChangeAddr() public override returns (bool) {
        require(
            changeAddrTo[msg.sender] != address(0),
            "Referral::Nothing to revoke"
        );
        UserInfo storage user = userInfo[userId[msg.sender]];
        user.changeAddr = false;
        changeAddrFrom[changeAddrTo[msg.sender]] = address(0);
        addrRevokeTime[changeAddrTo[msg.sender]] = 0;
        addrRevokeTime[msg.sender] = 0;
        emit RevokeChangeAddress(
            msg.sender,
            changeAddrTo[msg.sender],
            block.timestamp
        );
        changeAddrTo[msg.sender] = address(0);
        return true;
    }

    // verify change address from new address
    function verifyChangeAddr(address oldAddress)
        public
        override
        returns (bool)
    {
        UserInfo memory checkUser = userInfo[userId[oldAddress]];
        require(
            changeAddrTo[oldAddress] == msg.sender && checkUser.changeAddr,
            "Referral::not permitted"
        );
        uint256 endTime = addrRevokeTime[oldAddress] + revokeTime;
        uint256 RevokeTimeLeft = endTime >= block.timestamp
            ? endTime - block.timestamp
            : 0;
        require(RevokeTimeLeft == 0, "Referral::not yet");
        UserInfo storage user = userInfo[userId[oldAddress]];
        userId[msg.sender] = user.userId;
        user.userAcc = msg.sender;
        user.oldAcc = oldAddress;
        userId[oldAddress] = upper("REPLACE");
        user.changeAddr = false;
        addrRevokeTime[msg.sender] = 0;
        emit VerifyNewAddress(oldAddress, msg.sender, block.timestamp);
        return true;
    }

    // view verify address info
    function changeAddrInfo(address newAddr)
        public
        view
        override
        returns (
            address ChangeAddrFrom,
            address ChangeAddrTo,
            uint256 ChangeDate,
            uint256 RevokeTimeLeft
        )
    {
        ChangeAddrFrom = changeAddrFrom[newAddr];
        ChangeAddrTo = changeAddrTo[ChangeAddrFrom];
        ChangeDate = addrRevokeTime[ChangeAddrFrom];
        uint256 endTime = addrRevokeTime[ChangeAddrFrom] + revokeTime;
        RevokeTimeLeft = endTime >= block.timestamp
            ? endTime - block.timestamp
            : 0;
    }

    // view Contract Info
    function contractInfo()
        public
        view
        override
        returns (
            uint32 TotalUsers,
            uint256 ChangeAddrFee,
            uint256 RevokeTime,
            string memory GenesisID,
            bool RegisterPaused,
            bool ChangeAddrPaused,
            address Owner
        )
    {
        return (
            totalUsers,
            changeAddrFee,
            revokeTime,
            genesisId,
            paused,
            changeAddrPaused,
            _owner
        );
    }

    // check admin access for this contract
    function adminAccess(address adminAcc) public view override returns (bool) {
        return admin[adminAcc];
    }

    // set or update admin access for this contract
    function setAdmin(address adminAcc, bool activate)
        public
        override
        onlyOwner
    {
        admin[adminAcc] = activate;
        UserInfo storage user = userInfo[userId[adminAcc]];
        user.rewardActive = true;
    }

    // view admin access bool
    function operatorAccess(address operatorAcc)
        public
        view
        override
        returns (bool)
    {
        return operator[operatorAcc];
    }

    // set or update operator access for this contract
    function setOperator(address newOperatorAcc, bool access)
        public
        override
        onlyOperator
    {
        require(newOperatorAcc != _owner, "Referral::owner??");
        operator[newOperatorAcc] = access;
    }

    // update referral reward status by operator
    function setRewardActive(address userAddress, bool activate)
        public
        override
        onlyOperator
    {
        if (!admin[userAddress]) {
            UserInfo storage user = userInfo[userId[userAddress]];
            user.rewardActive = activate;
        }
    }

    // update status for registration
    function setRegisterStatus(bool _paused) public onlyOwner {
        paused = _paused;
    }

    // update time for revoke change address
    function setRevokeTime(uint256 RevokeTime) public onlyOwner {
        revokeTime = RevokeTime;
    }

    // restrict address account for refer new user
    function setBlacklist(address userAcc, bool status) public onlyAdmin {
        require(!admin[userAcc], "Admin::Cannot blacklist admin address");
        require(!operator[userAcc], "Admin::Cannot blacklist operator address");
        UserInfo storage user = userInfo[userId[userAcc]];
        user.excludedReferrer = status;
        user.rewardActive = false;
    }
}