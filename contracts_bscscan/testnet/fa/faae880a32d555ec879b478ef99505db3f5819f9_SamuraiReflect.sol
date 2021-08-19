/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4);
}

enum Permission {
    Authorize,
    Unauthorize,
    LockPermissions,

    RetrieveTokens,
    AdjustVariables,
    RegisterNewMints
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
    
    uint constant NUM_PERMISSIONS = 6; // always has to be adjusted when Permission element is added or removed
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
        permissionNameToIndex["RetrieveTokens"] = uint(Permission.RetrieveTokens);
        permissionNameToIndex["AdjustVariables"] = uint(Permission.AdjustVariables);
        permissionNameToIndex["RegisterNewMints"] = uint(Permission.RegisterNewMints);

        permissionIndexToName[uint(Permission.Authorize)] = "Authorize";
        permissionIndexToName[uint(Permission.Unauthorize)] = "Unauthorize";
        permissionIndexToName[uint(Permission.LockPermissions)] = "LockPermissions";
        permissionIndexToName[uint(Permission.RetrieveTokens)] = "RetrieveTokens";
        permissionIndexToName[uint(Permission.AdjustVariables)] = "AdjustVariables";
        permissionIndexToName[uint(Permission.RegisterNewMints)] = "RegisterNewMints";
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

interface IERC721 {
    function ownerOf(uint tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;
    function balanceOf(address owner) external view returns (uint balance);
}

interface IERC721Enumerable is IERC721 {

  function totalSupply() external view returns (uint);
  function tokenOfOwnerByIndex(address owner, uint index)
    external
    view
    returns (uint tokenId);
  function tokenByIndex(uint index) external view returns (uint);
}

interface ISamuraiRising is IERC721Enumerable { }

contract SamuraiReflect is RSunAuth, IERC721Receiver {

    address public busdAdr = 0xbcca17a1e79Cb6Fcf2A5B7433e6fBCb7408Ca535;
    address public samuraiAdr = 0xfC21dB4a88075d88c87BE662A0f17cF5167a1Ea7;

    ISamuraiRising samurai;

    uint public reflectionBalance;
    uint public totalDividend;
    mapping(uint => uint) lastDividendAt;

    uint public lastContractBalance;

    event SingleClaim(uint tokenId, uint amount);
    event BatchClaim(uint[] tokenIds, uint amount);
    event Reflected(uint amount);
    event DebugLog(string message, uint value);

    constructor() RSunAuth(msg.sender) {
        samurai = ISamuraiRising(samuraiAdr);
    }

    function currentRate() public view returns (uint) {
        uint supply = samurai.totalSupply();
        if (supply == 0) return 0;
        return reflectionBalance / supply;
    }

    function claimRewards() public {
        claimRewards(msg.sender);
    }

    function claimRewards(address user) public {
        uint startGas = gasleft();
        emit DebugLog("claimRewards entered. empty gas test: ", gasleft() - startGas);

        startGas = gasleft();
        uint count = samurai.balanceOf(user);
        emit DebugLog("claimRewards: samurai.balanceOf: ", gasleft() - startGas);

        startGas = gasleft();
        require(count > 0, "User has 0 samurai");
        emit DebugLog("claimRewards: require: ", gasleft() - startGas);

        startGas = gasleft();
        updateRewards();
        emit DebugLog("claimRewards: first updateRewards: ", gasleft() - startGas);

        startGas = gasleft();
        uint[] memory tokenIds = new uint[](count);
        uint total = 0;
        
        for (uint i = 0; i < count; i++) {
            uint startGasLoop = gasleft();
            uint tokenId = samurai.tokenOfOwnerByIndex(user, i);
            emit DebugLog("claimRewards: samurai.tokenOfOwnerByIndex: ", gasleft() - startGasLoop);
            
            startGasLoop = gasleft();
            total += getReflectionBalance(tokenId);
            emit DebugLog("claimRewards: total += getReflectionBalance: ", gasleft() - startGasLoop);

            startGasLoop = gasleft();
            tokenIds[i] = tokenId;
            emit DebugLog("claimRewards: total += tokenIds[i] = tokenId: ", gasleft() - startGasLoop);

            startGasLoop = gasleft();
            lastDividendAt[tokenId] = totalDividend;
            emit DebugLog("claimRewards: lastDividendAt[tokenId] = totalDividend: ", gasleft() - startGasLoop);
        }

        emit DebugLog("claimRewards: entire loop: ", gasleft() - startGas);

        startGas = gasleft();
        require(IBEP20(busdAdr).transfer(user, total), "Transfer failed");
        emit DebugLog("claimRewards: transfer: ", gasleft() - startGas);

        startGas = gasleft();
        updateRewards();
        emit DebugLog("claimRewards: second updateRewards: ", gasleft() - startGas);

        startGas = gasleft();
        emit BatchClaim(tokenIds, total);
        emit DebugLog("claimRewards: emit BatchClaim: ", gasleft() - startGas);
    }

    function getReflectionBalances() public view returns (uint) {
        return _getReflectionBalances(msg.sender);
    }

    function _getReflectionBalances(address user) internal view returns (uint) {
        uint count = samurai.balanceOf(user);
        uint total = 0;

        for (uint i = 0; i < count; i++) {
            uint tokenId = samurai.tokenOfOwnerByIndex(user, i);
            total += getReflectionBalance(tokenId);
        }

        return total;
    }

    function claimReward(uint tokenId) public {
        address owner_ = samurai.ownerOf(tokenId);
        require(owner_ == msg.sender, "Only owner can claim");

        updateRewards();

        uint balance = getReflectionBalance(tokenId);
        require(IBEP20(busdAdr).transfer(owner_, balance), "Transfer failed");
        
        updateRewards();
        lastDividendAt[tokenId] = totalDividend;

        emit SingleClaim(tokenId, balance);
    }

    function getReflectionBalance(uint tokenId) public view returns (uint) {
        return totalDividend - lastDividendAt[tokenId];
    }

    function reflectDividend(uint amount) public returns (bool) {
        uint totalSupply = samurai.totalSupply();
        if (totalSupply == 0 || amount == 0) { return false; }

        reflectionBalance  = reflectionBalance + amount;
        totalDividend = totalDividend + (amount / totalSupply);

        emit Reflected(amount);
        return true;
    }

    function updateRewards() public {
        uint tokenBalance = IBEP20(busdAdr).balanceOf(address(this));

        if (tokenBalance == lastContractBalance) { return; }
        else if (tokenBalance > lastContractBalance) {
            // since this function is always called before and after every claim, lastContractBalance should always be up to date so this call shouldn't be able to miss any added balances 
            if (!reflectDividend(tokenBalance - lastContractBalance)) {
                return; 
            }
        }

        lastContractBalance = tokenBalance;
    }

    function registerNewMint(uint tokenId) external authorizedFor(Permission.RegisterNewMints) {
        lastDividendAt[tokenId] = totalDividend;
    }

    function setBusdAdr(address busd_) external authorizedFor(Permission.AdjustVariables) {
        busdAdr = busd_;
    }
    
    function setSamuraiAdr(address samuraiAdr_) external authorizedFor(Permission.AdjustVariables) {
        samuraiAdr = samuraiAdr_;
        samurai = ISamuraiRising(samuraiAdr_);
    }
    
    // use only in rare cases, could lead to some people being unable to get out the correct rewards
    function setLastDividendAt(uint tokenId, uint amount) external authorizedFor(Permission.AdjustVariables) {
        lastDividendAt[tokenId] = amount;
    }

    function retrieveTokens(address token) external authorizedFor(Permission.RetrieveTokens) {
        require(IBEP20(token).transfer(msg.sender, IBEP20(token).balanceOf(address(this))), "Transfer failed");
    }

    function retrieveBNB() external authorizedFor(Permission.RetrieveTokens) {
        (bool success,) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success, "Failed to retrieve BNB");
    }

    function onERC721Received(address, address, uint, bytes calldata) public pure override returns (bytes4) {
        return 0x150b7a02;
    }
}