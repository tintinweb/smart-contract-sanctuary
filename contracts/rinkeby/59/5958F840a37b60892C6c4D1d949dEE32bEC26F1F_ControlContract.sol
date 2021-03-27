// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./interfaces/ICommunity.sol";
import "./lib/StringUtils.sol";

contract ControlContract is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using MathUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    using StringUtils for *;
    
    ICommunity communityAddress;
    
    struct Operation {
        address addr;
        string method;
        string params;
        uint256 minimum;
        uint256 fraction;
        EnumerableSetUpgradeable.AddressSet endorsedAccounts;
        bool proceed;
        string proceededRole;
        bool success;
        bytes msg;
        bool exists;
    }
    
    uint256 internal groupTimeoutActivity;
    
    uint256 internal currentGroupIndex;
    uint256 private maxGroupIndex;
    
    
    mapping(string => uint256) roleIDs;
    uint256 private lastRoleIndex;
    
    // mapping(bytes32 => EnumerableSetUpgradeable.UintSet) invokeAllowed;
    // mapping(bytes32 => EnumerableSetUpgradeable.UintSet) endorseAllowed;
    
    struct Method {
        address addr;
        string method;
        uint256 minimum;
        uint256 fraction;
        bool exists;
        EnumerableSetUpgradeable.UintSet invokeRolesAllowed;
        EnumerableSetUpgradeable.UintSet endorseRolesAllowed;
    }
    mapping(bytes32 => Method) methods;
    

    uint256 internal fractionDiv; //  = 1e10
    
    struct Group {
        uint256 index;
        uint256 lastSeenTime;
        EnumerableSetUpgradeable.UintSet invokeRoles;
        EnumerableSetUpgradeable.UintSet endorseRoles;
        mapping(uint256 => Operation) operations;
        mapping(uint40 => uint256) pairWeiInvokeId;
        bool active;
    }

    mapping(uint256 => Group) internal groups;
    
    struct GroupRolesSetting {
        string invokeRole;
        string endorseRole;
    }
    
    //----------------------------------------------------
    // modifiers section 
    //----------------------------------------------------
    modifier canInvoke(
        address tokenAddr, 
        string memory method, 
        address sender
    ) 
    {
        bool s = false;
        bytes32 k = keccak256(abi.encodePacked(tokenAddr,method));
        string[] memory roles = ICommunity(communityAddress).getRoles(sender);
        for (uint256 i = 0; i < roles.length; i++) {
            if (methods[k].invokeRolesAllowed.contains(roleIDs[roles[i]])) {
                s = true;
            }
        }
        require(s == true, "Sender has not in Invoke role");
        _;
    }
    
    //----------------------------------------------------
    // events section 
    //----------------------------------------------------
    event OperationInvoked(uint256 indexed invokeID, uint40 invokeIDWei,  address tokenAddr, string method, string params);
    event OperationEndorsed(uint256 indexed invokeID, uint40 invokeIDWei);
    event OperationExecuted(uint256 indexed invokeID, uint40 invokeIDWei);
    event HeartBeat(uint256 groupIndex, uint256 time);
    event CurrentGroupIndexChanged(uint256 from, uint256 to, uint256 time);
  
    //----------------------------------------------------
    // external section 
    //----------------------------------------------------
    receive() external payable {
        
        heartbeat();
        
        uint256 invokeID = groups[currentGroupIndex].pairWeiInvokeId[uint40(msg.value)];
        _endorse(invokeID);
    }
    
    //----------------------------------------------------
    // public section 
    //----------------------------------------------------
    /**
     * @dev here invokeRole can equal endorseRole withih one group but can't be in other groups
     * @param communityAddr community address
     * @param groupRoles tuples of GroupRolesSetting
     */
    function init(
        ICommunity communityAddr,
        GroupRolesSetting[] memory groupRoles
    )
        public 
        initializer
    {
        __Ownable_init();
        __ReentrancyGuard_init();
        
        communityAddress = communityAddr;
        
        groupTimeoutActivity = 2_592_000; // 30 days
        lastRoleIndex = 0;
        fractionDiv = 1e10;
        
        /*
        [   //  invokeRole         endorseRole
            [Role#1Group#1,Role#5Group#1],
            [Role#2Group#2,Role#6Group#2],
            [Role#3Group#3,Role#7Group#3],
            [Role#4Group#4,Role#8Group#4]
        ]
        */
        
        require(
            (address(communityAddr) != address(0)) && 
            (address(communityAddr).isContract()), 
            "Community address can not be zero"
        );
        require(groupRoles.length > 0, "need at least one group");
        
        currentGroupIndex = 0;
        maxGroupIndex = groupRoles.length;
        for (uint256 i = 0; i < groupRoles.length; i++) {
            require(
                (roleExists(groupRoles[i].invokeRole) == false) &&
                (roleExists(groupRoles[i].endorseRole) == false) &&
                (
                    keccak256(abi.encodePacked(groupRoles[i].invokeRole)) != keccak256(abi.encodePacked(groupRoles[i].endorseRole))
                ),
                "Role is already exists or invokeRole equal endorseRole"
            );
            
            groups[i].index = maxGroupIndex;
            groups[i].lastSeenTime = block.timestamp;
            groups[i].invokeRoles.add(roleAdd(groupRoles[i].invokeRole));
            groups[i].endorseRoles.add(roleAdd(groupRoles[i].endorseRole));
            
        }
    }
    
    /**
     * @param tokenAddr address of external token
     * @param method method of external token that would be executed
     * @param params params of external token's method
     * @return invokeID identificator
     */
    function invoke(
        address tokenAddr,
        string memory method,
        string memory params
    )
        public 
        canInvoke(tokenAddr, method, _msgSender())
        returns(uint256 invokeID, uint40 invokeIDWei)
    {
        bytes32 k = keccak256(abi.encodePacked(tokenAddr,method));
        require(methods[k].exists == true, "Such method does not exists");
        
        heartbeat();
        
        invokeID = generateInvokeID();
        invokeIDWei = uint40(invokeID);
        
        groups[currentGroupIndex].pairWeiInvokeId[invokeIDWei] = invokeID;
        
        emit OperationInvoked(invokeID, invokeIDWei, tokenAddr, method, params);
        
        groups[currentGroupIndex].operations[invokeID].addr = methods[k].addr;
        groups[currentGroupIndex].operations[invokeID].method = methods[k].method;
        groups[currentGroupIndex].operations[invokeID].params = params;
        groups[currentGroupIndex].operations[invokeID].minimum = methods[k].minimum;
        groups[currentGroupIndex].operations[invokeID].fraction = methods[k].fraction;
        
        groups[currentGroupIndex].operations[invokeID].exists = true;
        
    }
    
    /**
     * @param invokeID invoke identificator
     */
    function endorse(
        uint256 invokeID
    ) 
        public
    {
        heartbeat();
        _endorse(invokeID);
    }

    /**
     * @param tokenAddr token's address
     * @param method hexademical method's string
     * @param invokeRoleName invoke rolename
     * @param invokeRoleName endorse rolename
     * @param minimum  minimum
     * @param fraction fraction value mul by 1e10
     */
    function addMethod(
        address tokenAddr,
        string memory method,
        string memory invokeRoleName,
        string memory endorseRoleName,
        uint256 minimum,
        uint256 fraction
    )
        public 
        onlyOwner 
    {
        bytes32 k = keccak256(abi.encodePacked(tokenAddr,method));
        
        require(roleExists(invokeRoleName), "Rolename does not exists");
        require(roleExists(endorseRoleName), "Rolename does not exists");
        
        // require(methods[k].exists == false, "Such method has already registered");
        if (methods[k].exists == false) {

        } else {
            require(
                (methods[k].minimum == minimum) && (methods[k].fraction == fraction), 
                "Such method has already registered with another minimum and fraction"
            );
        }
        
        
        
        
        
        methods[k].exists = true;
        methods[k].addr = tokenAddr;
        methods[k].method = method;
        methods[k].minimum = minimum;
        methods[k].fraction = fraction;
        methods[k].invokeRolesAllowed.add(roleIDs[invokeRoleName]);
        methods[k].endorseRolesAllowed.add(roleIDs[endorseRoleName]);
        
    }

    /**
     * prolonging user current group ownership. 
     * or transferring to next if previous expired
     * or restore previous if user belong to group which index less then current
     */
    function heartbeat(
    ) 
        public
    {
    
        uint256 len = 0;
        uint256 ii = 0;
        
        string[] memory roles = ICommunity(communityAddress).getRoles(_msgSender());
        for (uint256 i = 0; i < maxGroupIndex; i++) {
            for (uint256 j = 0; j < roles.length; j++) {
                if (
                    groups[i].invokeRoles.contains(roleIDs[roles[j]]) ||
                    groups[i].endorseRoles.contains(roleIDs[roles[j]])
                ) {
                    len = len.add(1);
                }
          }
        }
        
        uint256[] memory userRoleIndexes = new uint256[](len);
        for (uint256 i = 0; i < maxGroupIndex; i++) {
            for (uint256 j = 0; j < roles.length; j++) {
                if (
                    groups[i].invokeRoles.contains(roleIDs[roles[j]]) ||
                    groups[i].endorseRoles.contains(roleIDs[roles[j]])
                ) {
                    
                    userRoleIndexes[ii] = i;
                    ii = ii.add(1);
                }
            }
        }
        
        uint256 expectGroupIndex = getExpectGroupIndex();

        bool isBreak = false;
        uint256 itGroupIndex;

        for (uint256 i = 0; i <= expectGroupIndex; i++) {
            for (uint256 j = 0; j < userRoleIndexes.length; j++) { 
                if (i == userRoleIndexes[j]) {
                    itGroupIndex = i;
                    isBreak = true;
                    break;
                }
            }
            if (isBreak) {
                break;
            }
        }

        if (isBreak) {
            if (currentGroupIndex != itGroupIndex) {
                emit CurrentGroupIndexChanged(currentGroupIndex, itGroupIndex, block.timestamp);
            }
            currentGroupIndex = itGroupIndex;
            groups[itGroupIndex].lastSeenTime = block.timestamp;
            
            HeartBeat(currentGroupIndex, block.timestamp);
        } else {
            revert("Sender is out of current owner group");
        }

    }
    
    
    /**
     * @return index expected groupIndex.
     */
    function getExpectGroupIndex(
    ) 
        public 
        view 
        returns(uint256 index) 
    {

        index = currentGroupIndex;
        if (groups[currentGroupIndex].lastSeenTime.add(groupTimeoutActivity) < block.timestamp) {
            index = currentGroupIndex.add(
                (block.timestamp.sub(groups[currentGroupIndex].lastSeenTime)).div(groupTimeoutActivity)
            );
            if (maxGroupIndex < index) {
                index = maxGroupIndex;
            }
        }
    }
    
    //----------------------------------------------------
    // internal section 
    //----------------------------------------------------
    /**
     * @param value value that need to find
     * @param arr source uint256[] array
     * @return ret true if value is exists in uint256[] array
     */
    function isExistsInArray(
        uint256 value, 
        uint256[] memory arr
    ) 
        internal 
        pure 
        returns(bool ret) 
    {
        ret = false;
        for (uint256 i = 0; i < arr.length; i++) {
            if (value == arr[i]) {
                ret = true;
                break;
            }
        }
    }
    
    
    /**
     * @param invokeID invoke identificator
     */
    function _endorse(
        uint256 invokeID
    ) 
        internal
        nonReentrant()
    {
        require(groups[currentGroupIndex].operations[invokeID].exists == true, "Such invokeID does not exist");
        string[] memory roles = getEndorsedRoles(groups[currentGroupIndex].operations[invokeID].addr, groups[currentGroupIndex].operations[invokeID].method, _msgSender());
        require(roles.length > 0, "Sender has not in Endorse role");
        require(groups[currentGroupIndex].operations[invokeID].endorsedAccounts.contains(_msgSender()) == false, "Sender is already endorse this transaction");
        require(groups[currentGroupIndex].operations[invokeID].proceed == false, "Transaction have already executed");
        
        groups[currentGroupIndex].operations[invokeID].endorsedAccounts.add(_msgSender());
        
        emit OperationEndorsed(invokeID, uint40(invokeID));
        
        uint256 memberCount;
        for (uint256 i = 0; i < roles.length; i++) {
            memberCount = ICommunity(communityAddress).memberCount(roles[i]);
            if (
                groups[currentGroupIndex].operations[invokeID].endorsedAccounts.length() >= 
                groups[currentGroupIndex].operations[invokeID].minimum.max(
                    memberCount.mul(groups[currentGroupIndex].operations[invokeID].fraction).div(fractionDiv))
            ) {
                groups[currentGroupIndex].operations[invokeID].proceed = true;
                (
                    groups[currentGroupIndex].operations[invokeID].success, 
                    groups[currentGroupIndex].operations[invokeID].msg
                ) = groups[currentGroupIndex].operations[invokeID].addr.call(
                    (
                        string(abi.encodePacked(
                            groups[currentGroupIndex].operations[invokeID].method, 
                            groups[currentGroupIndex].operations[invokeID].params
                        ))
                    ).fromHex()
                );
                emit OperationExecuted(invokeID, uint40(invokeID));
            }
        }
    }
 
    
    /**
     * getting all endorse roles by sender's address and expected pair contract/method
     * 
     * @param tokenAddr token's address
     * @param method hexademical method's string
     * @param sender sender address
     * @return endorse roles 
     */
    function getEndorsedRoles(
        address tokenAddr, 
        string memory method, 
        address sender
    ) 
        internal 
        view 
        returns(string[] memory) 
    {
        string[] memory roles = ICommunity(communityAddress).getRoles(sender);
        uint256 len;

        for (uint256 i = 0; i < roles.length; i++) {
            if (methods[keccak256(abi.encodePacked(tokenAddr,method))].endorseRolesAllowed.contains(roleIDs[roles[i]])) {
                len = len.add(1);
            }
        }
        string[] memory list = new string[](len);
        uint256 j = 0;
        for (uint256 i = 0; i < roles.length; i++) {
            if (methods[keccak256(abi.encodePacked(tokenAddr,method))].endorseRolesAllowed.contains(roleIDs[roles[i]])) {
                list[j] = roles[i];
                j = j.add(1);
            }
        }
        return list;
    }
    
    /**
     * adding role to general list
     * 
     * @param roleName role name
     * 
     * @return index true if was added and false if already exists
     */
    function roleAdd(
        string memory roleName
    ) 
        internal 
        returns(uint256 index) 
    {
        if (roleIDs[roleName] == 0) {
            lastRoleIndex = lastRoleIndex.add(1);
            roleIDs[roleName] = lastRoleIndex;
            index = lastRoleIndex;
        } else {
            index = roleIDs[roleName];
        }
    }
    
    /**
     * @param roleName role name
     * @return ret true if roleName exists in general list
     */
    function roleExists(
        string memory roleName
    ) 
        internal 
        view
        returns(bool ret) 
    {
        ret = (roleIDs[roleName] == 0) ? false : true;
    }
    
    /**
     * generating pseudo-random id used as invoke identificator
     * @return invoke identificator
     */
    function generateInvokeID(
    ) 
        internal 
        view 
        returns(uint256) 
    {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp, 
            block.difficulty, 
            msg.sender
        )));    
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ICommunity {
    function memberCount(string calldata role) external view returns(uint256);
    function getRoles(address member)external view returns(string[] memory);
    function getMember(string calldata role) external view returns(address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringUtils {
    
    /**
     * convert string to bytes32
     * @param source string variable
     */
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    
    /**
     * convert bytes32 to string
     * @param _bytes32 bytes32 variable
     */
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
    
    /**
     * convert string to lowercase
     */
    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
    // Convert an hexadecimal character to their value
    function fromHexChar(uint8 c) internal pure returns (uint8 ret) {
        if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
            ret = c - uint8(bytes1('0'));
        } else
        if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
            ret = 10 + c - uint8(bytes1('a'));
        } else
        if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
            ret = 10 + c - uint8(bytes1('A'));
        }
    }
    
    // Convert an hexadecimal string to raw bytes
    function fromHex(string memory s) internal pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i=0; i<ss.length/2; ++i) {
            r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
                        fromHexChar(uint8(ss[2*i+1])));
        }
        return r;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
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