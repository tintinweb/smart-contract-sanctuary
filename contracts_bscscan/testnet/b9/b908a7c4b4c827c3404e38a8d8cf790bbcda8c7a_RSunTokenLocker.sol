/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

enum Permission {
    Authorize,
    Unauthorize,
    LockPermissions,

    WithdrawBNBOrBUSD
}

/**
 * Allows for contract ownership along with multi-address authorization for different permissions
 */
abstract contract RSunAuth {
    struct PermissionLock {
        bool isLocked;
        uint64 expiryTime;
    }

    address public owner;
    mapping(address => mapping(uint => bool)) private authorizations; // uint is permission index
    
    uint constant NUM_PERMISSIONS = 4; // always has to be adjusted when Permission element is added or removed
    mapping(string => uint) permissionNameToIndex;
    mapping(uint => string) permissionIndexToName;

    mapping(uint => PermissionLock) lockedPermissions;

    constructor(address owner_) {
        owner = owner_;
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[owner_][i] = true;
        }

        // a permission name can't be longer than 32 bytes
        permissionNameToIndex["Authorize"] = uint(Permission.Authorize);
        permissionNameToIndex["Unauthorize"] = uint(Permission.Unauthorize);
        permissionNameToIndex["LockPermissions"] = uint(Permission.LockPermissions);
        permissionNameToIndex["WithdrawBNBOrBUSD"] = uint(Permission.WithdrawBNBOrBUSD);

        permissionIndexToName[uint(Permission.Authorize)] = "Authorize";
        permissionIndexToName[uint(Permission.Unauthorize)] = "Unauthorize";
        permissionIndexToName[uint(Permission.LockPermissions)] = "LockPermissions";
        permissionIndexToName[uint(Permission.WithdrawBNBOrBUSD)] = "WithdrawBNBOrBUSD";
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownership required."); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorizedFor(Permission permission) {
        require(!lockedPermissions[uint(permission)].isLocked, "Permission is locked.");
        require(isAuthorizedFor(msg.sender, permission), string(abi.encodePacked("Not authorized. You need the permission ", permissionIndexToName[uint(permission)]))); _;
    }

    /**
     * Authorize address for one permission
     */
    function authorizeFor(address adr, string memory permissionName) public authorizedFor(Permission.Authorize) {
        uint permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = true;
        emit AuthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Authorize address for multiple permissions
     */
    function authorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public authorizedFor(Permission.Authorize) {
        for (uint i; i < permissionNames.length; i++) {
            uint permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = true;
            emit AuthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    /**
     * Remove address' authorization
     */
    function unauthorizeFor(address adr, string memory permissionName) public authorizedFor(Permission.Unauthorize) {
        require(adr != owner, "Can't unauthorize owner");

        uint permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = false;
        emit UnauthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Unauthorize address for multiple permissions
     */
    function unauthorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public authorizedFor(Permission.Unauthorize) {
        require(adr != owner, "Can't unauthorize owner");

        for (uint i; i < permissionNames.length; i++) {
            uint permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = false;
            emit UnauthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorizedFor(address adr, string memory permissionName) public view returns (bool) {
        return authorizations[adr][permissionNameToIndex[permissionName]];
    }

    /**
     * Return address' authorization status
     */
    function isAuthorizedFor(address adr, Permission permission) public view returns (bool) {
        return authorizations[adr][uint(permission)];
    }

    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        address oldOwner = owner;
        owner = adr;
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[oldOwner][i] = false;
            authorizations[owner][i] = true;
        }
        emit OwnershipTransferred(oldOwner, owner);
    }

    /**
     * Get the index of the permission by its name
     */
    function getPermissionNameToIndex(string memory permissionName) public view returns (uint) {
        return permissionNameToIndex[permissionName];
    }
    
    /**
     * Get the time the timelock expires
     */
    function getPermissionUnlockTime(string memory permissionName) public view returns (uint) {
        return lockedPermissions[permissionNameToIndex[permissionName]].expiryTime;
    }

    /**
     * Check if the permission is locked
     */
    function isLocked(string memory permissionName) public view returns (bool) {
        return lockedPermissions[permissionNameToIndex[permissionName]].isLocked;
    }

    /*
     *Locks the permission from being used for the amount of time provided
     */
    function lockPermission(string memory permissionName, uint64 time) public virtual authorizedFor(Permission.LockPermissions) {
        uint permIndex = permissionNameToIndex[permissionName];
        uint64 expiryTime = uint64(block.timestamp) + time;
        lockedPermissions[permIndex] = PermissionLock(true, expiryTime);
        emit PermissionLocked(permissionName, permIndex, expiryTime);
    }
    
    /*
     * Unlocks the permission if the lock has expired 
     */
    function unlockPermission(string memory permissionName) public virtual {
        require(block.timestamp > getPermissionUnlockTime(permissionName) , "Permission is locked until the expiry time.");
        uint permIndex = permissionNameToIndex[permissionName];
        lockedPermissions[permIndex].isLocked = false;
        emit PermissionUnlocked(permissionName, permIndex);
    }

    event PermissionLocked(string permissionName, uint permissionIndex, uint64 expiryTime);
    event PermissionUnlocked(string permissionName, uint permissionIndex);
    event OwnershipTransferred(address from, address to);
    event AuthorizedFor(address adr, string permissionName, uint permissionIndex);
    event UnauthorizedFor(address adr, string permissionName, uint permissionIndex);
}

contract RSunTokenLocker is RSunAuth {

    uint public lockPrice = 1 * 10 ** 17; // 0.1 BNB
    address public BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    struct Lock {
        address owner;
        address tokenAdr;
        uint48 startTime; // tens of millions of years, probably enough
        uint48 duration;
        uint48 endTime; // just for convenience, no gas needed
        uint112 amount; // same max amount as pancake can handle in its code so it's unlikely for there to be many projects this wouldn't be enough for
        bool isVested;
        uint48 lastWithdrawn; // only for vested
    }

    Lock[] public locks;
    mapping(address => uint[]) public ownerToIndex;

    event TokensLocked(address owner_, uint112 amount, uint48 duration, bool isVested);
    event TokensUnlocked(address owner_, uint112 amount);
    event LockOwnershipTransferred(address oldOwner, address newOwner, uint index);

    constructor() RSunAuth(msg.sender) {}

    function lockTokens(address tokenAdr, uint112 amount, uint48 duration, bool isVested, address owner_) public payable {
        require(msg.value == lockPrice, "Incorrect payment");
        Lock memory lock;
        
        lock.tokenAdr = tokenAdr; // 160 bit
        lock.startTime = uint48(block.timestamp); // 208 bit
        lock.duration = duration; // 256 bit
        
        lock.endTime = lock.startTime + lock.duration; // 48 bit
        lock.amount = uint112(amount); // 160 bit
        lock.isVested = isVested; // 168 bit
        lock.lastWithdrawn = lock.startTime; // 216 bit

        lock.owner = owner_; // 160 bit

        locks.push(lock);
        ownerToIndex[owner_].push(locks.length - 1);

        require(IBEP20(tokenAdr).transferFrom(msg.sender, address(this), amount), "Transfer failed. Check your allowance.");
        emit TokensLocked(owner_, amount, duration, isVested);
    }

    function transferLockOwnership(uint lockIndex, address newOwner) public {
        require(lockIndex < locks.length, "Lock index out of bounds");
        require(locks[lockIndex].owner == msg.sender, "Only the lock's owner can transfer ownership");

        locks[lockIndex].owner = newOwner;

        ownerToIndex[newOwner].push(lockIndex);

        removeLockOwnership(lockIndex);

        emit LockOwnershipTransferred(msg.sender, newOwner, lockIndex);
    }

    function withdrawTokens(uint lockIndex) public {
        Lock memory lock = locks[lockIndex];
        require(lock.owner == msg.sender, "Only the owner can withdraw tokens");
        
        if (!lock.isVested) {
            require(block.timestamp >= lock.endTime, "Lock hasn't ended yet.");
        }

        uint timestampClamped = block.timestamp > lock.endTime ? lock.endTime : block.timestamp;
        uint amount = lock.isVested ? lock.amount * (timestampClamped - lock.lastWithdrawn) / lock.duration : lock.amount;

        if (lock.isVested && block.timestamp < lock.endTime) {
            locks[lockIndex].lastWithdrawn = uint48(block.timestamp);
        } else {
            removeLockOwnership(lockIndex);
        }

        require(IBEP20(lock.tokenAdr).transfer(msg.sender, amount), "Transfer failed");
        emit TokensUnlocked(lock.owner, uint112(amount));
    }

    function removeLockOwnership(uint lockIndex) internal {
        uint[] memory lockIdsOwner = ownerToIndex[msg.sender];

        uint index = ~uint(0);
        for (uint256 i = 0; i < lockIdsOwner.length; i++) {
            if (lockIdsOwner[i] == lockIndex) {
                index = i;
            }
        }

        if (index != ~uint(0)) {
            ownerToIndex[msg.sender][index] = lockIdsOwner[lockIdsOwner.length - 1];
            ownerToIndex[msg.sender].pop();
        }
    }

    function withdrawFees() public authorizedFor(Permission.WithdrawBNBOrBUSD) {
        (bool success,) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success, "Failed to send BNB");
    }

    function withdrawBUSD() public authorizedFor(Permission.WithdrawBNBOrBUSD) {
        require(IBEP20(BUSD).transfer(msg.sender, IBEP20(BUSD).balanceOf(address(this))), "Failed to send BUSD");
    }
}