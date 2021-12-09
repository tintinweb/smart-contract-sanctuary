/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

//SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

interface IReferralManager {
    event Register(address UserAcc, string UserID, string ReferrerID);

    function register(string memory referrerId) external returns (bool);

    function registerVIP(string memory newUserId, address newUserAcc)
        external
        returns (bool);

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
            uint32,
            string memory,
            bool
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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract ReferralManager is IReferralManager, ReentrancyGuard {
    using Address for address;

    // Info of each Registered user.
    struct UserInfo {
        address userAcc; // User Address.
        string userId; // User Unique ID.
        string referrerId; // Referrer ID.
        uint256 registerDate; // Register Date.
        uint256 referredCount; // referrer_address -> num_of_referred
        bool excludedReferrer; // Addresses that excluded from referral
        bool rewardActive; // Address status for received referral bonus
    }

    // Info of each users unique ID
    mapping(address => string) private userId;
    // Info of each users that stakes LP tokens.
    mapping(string => UserInfo) private userInfo;
    // Contract Admin
    mapping(address => bool) private admin;
    // Contract Operator
    mapping(address => bool) private operator;

    address private _owner;
    uint32 private version = 1;
    uint32 private totalUsers;
    string private genesisId;
    bool private paused;

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

    constructor(address GenesisAcc, string memory GenesisID) public {
        GenesisID = upper(GenesisID);
        userId[GenesisAcc] = GenesisID;
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
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

    // Register to Referral Manager with referrarID
    function register(string memory referrerId)
        public
        override
        nonReentrant
        returns (bool)
    {
        require(!paused, "ReferralManager::Registration Paused");
        referrerId = upper(referrerId);
        UserInfo storage user = userInfo[userId[msg.sender]];
        UserInfo storage refer = userInfo[referrerId];
        require(
            !refer.excludedReferrer,
            "ReferralManager::Referrer Blacklisted"
        );
        require(
            refer.userAcc != address(0),
            "ReferralManager::Referrer Not Exist"
        );
        require(
            refer.userAcc != msg.sender,
            "ReferralManager::Forbidden Refer Yourself"
        );
        require(user.registerDate == 0, "ReferralManager::Already Registered");
        // Register New User
        string memory userIdCreated = _getUserId();
        userId[msg.sender] = userIdCreated;
        UserInfo storage newuser = userInfo[userIdCreated];
        newuser.userAcc = address(msg.sender);
        newuser.userId = userIdCreated;
        newuser.referrerId = refer.userId;
        newuser.registerDate = block.timestamp;
        refer.referredCount += 1;
        totalUsers += 1;
        emit Register(newuser.userAcc, newuser.userId, newuser.referrerId);
        return true;
    }

    // Register to Referral Manager with referrar
    function registerVIP(string memory createUserId, address newUserAcc)
        public
        override
        onlyAdmin
        nonReentrant
        returns (bool)
    {
        require(!paused, "ReferralManager::Registration Paused Try Next Time");
        string memory newUserId = upper(createUserId);
        UserInfo storage checkId = userInfo[newUserId];
        UserInfo storage user = userInfo[userId[newUserAcc]];
        UserInfo storage refer = userInfo[userId[msg.sender]];
        require(
            !refer.excludedReferrer,
            "ReferralManager::Referrer Blacklisted"
        );
        require(
            refer.userAcc != address(0),
            "ReferralManager::Referrer Not Exist"
        );
        require(
            refer.userAcc != newUserAcc,
            "ReferralManager::Forbidden Refer Yourself"
        );
        require(user.registerDate == 0, "ReferralManager::Already Registered");
        require(
            checkId.registerDate == 0,
            "ReferralManager::UserID Already Exists"
        );
        // Register New User
        userId[newUserAcc] = newUserId;
        UserInfo storage newuser = userInfo[newUserId];
        newuser.userAcc = address(newUserAcc);
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

    // String uppercase function
    function upper(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    // String uppercase function
    function _upper(bytes1 _b1) internal pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    // Convert uint to string type
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

    // Users Status
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

    // Referrer Status
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

    // View Referral Reward Percent
    function contractInfo()
        public
        view
        override
        returns (
            uint32 Version,
            uint32 TotalUsers,
            string memory GenesisID,
            bool RegisterPaused
        )
    {
        return (version, totalUsers, genesisId, paused);
    }

    // Check admin access for this contract
    function adminAccess(address adminAcc) public view override returns (bool) {
        return admin[adminAcc];
    }

    // Update admin access for this contract
    function setAdmin(address adminAcc, bool activate)
        public
        override
        onlyOwner
    {
        admin[adminAcc] = activate;
        UserInfo storage user = userInfo[userId[adminAcc]];
        user.rewardActive = true;
    }

    function operatorAccess(address operatorAcc)
        public
        view
        override
        returns (bool)
    {
        return operator[operatorAcc];
    }

    function setOperator(address newOperatorAcc, bool access)
        public
        override
        onlyOperator
    {
        require(newOperatorAcc != _owner, "ReferralManager::owner??");
        operator[newOperatorAcc] = access;
    }

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

    function setRegisterStatus(bool _paused) public onlyOwner {
        paused = _paused;
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