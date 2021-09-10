/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "hardhat/console.sol";

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
abstract contract EpicAuth {
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

interface IEpicHeroNFT is IERC721Enumerable {
    function packIdOfToken(uint id) external view returns (uint);
}

contract EpicHeroReflect is EpicAuth, IERC721Receiver {

    address public wbnbAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public epicHeroNFTAddress = 0xD451CAe2D30A4aE855237a0Bab79b9340d4b3c75;

    IEpicHeroNFT EpicHeroNFT;

    uint128 public totalDividend; // uint128 is enough for over 300,000,000,000,000,000,000 WBNB per EpicHeroNFT

    uint public totalReflected;
    uint public totalEpicHero;

    mapping(uint => uint) public dividends;

    uint public lastContractBalance;

    event SingleClaim(uint tokenId, uint amount);
    event BatchClaim(address user, uint numTokens, uint amount);
    event Reflected(uint amount);
    event DebugLog(string message, uint value);

    constructor() EpicAuth(msg.sender) {
        EpicHeroNFT = IEpicHeroNFT(epicHeroNFTAddress);

        initializeMints();
    }

    function currentRate() public view returns (uint) {
        uint supply = totalEpicHero;
        if (supply == 0) return 0;
        return totalReflected / supply;
    }

    function claimAllRewards() external {
        claimAllRewards(msg.sender);
    }

    function claimAllRewards(address user) public {
        uint count = EpicHeroNFT.balanceOf(user);
        require(count > 0, "User has 0 EpicHeroNFT");

        updateRewards();

        uint total = 0;
        for (uint i = 0; i < count; i++) {
            uint tokenId = EpicHeroNFT.tokenOfOwnerByIndex(user, i);
            uint unrealized = getUnrealizedReward(tokenId);

            if (unrealized > 0) {
                total += unrealized;
                setDividend(tokenId, totalDividend, uint128(dividends[tokenId] >> 128) + uint128(unrealized));
            }
        }

        require(IBEP20(wbnbAddress).transfer(user, total), "Transfer failed");

        updateRewards();

        emit BatchClaim(user, count, total);
    }

    function claimReward(uint tokenId) public {
        address owner_ = EpicHeroNFT.ownerOf(tokenId);
        require(owner_ == msg.sender, "Only owner can claim");

        updateRewards();

        uint unrealized = getUnrealizedReward(tokenId);
        require(unrealized > 0, "Balance is 0");

        require(IBEP20(wbnbAddress).transfer(owner_, unrealized), "Transfer failed");

        updateRewards();
        setDividend(tokenId, totalDividend, uint128(dividends[tokenId] >> 128) + uint128(unrealized));

        emit SingleClaim(tokenId, unrealized);
    }

    function getAllUnrealizedRewards() public view returns (uint) {
        return getAllUnrealizedRewards(msg.sender);
    }

    function getAllUnrealizedRewards(address user) public view returns (uint) {
        uint count = EpicHeroNFT.balanceOf(user);
        uint total = 0;

        for (uint i = 0; i < count; i++) {
            uint tokenId = EpicHeroNFT.tokenOfOwnerByIndex(user, i);
            total += getUnrealizedReward(tokenId);
        }

        return total;
    }

    function getUnrealizedReward(uint tokenId) public view returns (uint) {
        uint lastDiv = uint128(dividends[tokenId]); // just get the latter 128 bit
        if (lastDiv == 0) return 0; // that means it's not registered in the contract

        return totalDividend - lastDiv;
    }

    function getRealizedRewards(address user) public view returns (uint) {
        uint count = EpicHeroNFT.balanceOf(user);
        uint total = 0;

        for (uint i = 0; i < count; i++) {
            uint tokenId = EpicHeroNFT.tokenOfOwnerByIndex(user, i);
            total += getRealizedReward(tokenId);
        }

        return total;
    }

    function getRealizedReward(uint tokenId) public view returns (uint) {
        return uint(uint128(dividends[tokenId] >> 128));
    }

    function reflectDividend(uint amount) internal returns (bool) {
        uint totalSupply = totalEpicHero;
        if (totalSupply == 0 || amount == 0) { return false; }

        totalReflected = totalReflected + amount;
        totalDividend = uint128(totalDividend + (amount / totalSupply)); // no accuracy factor needed since it's 18+ divided by 4 digits

        emit Reflected(amount);
        return true;
    }

    function updateRewards() public {
        uint tokenBalance = IBEP20(wbnbAddress).balanceOf(address(this));

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
        require(dividends[tokenId] == 0, "Token already registered");

        if (totalDividend == 0) {
            dividends[tokenId] = 1; // to distinguish EpicHeroNFT added before the first reflection from unregistered EpicHeroNFT
        } else {
            dividends[tokenId] = totalDividend;
        }

        totalEpicHero++;
    }

    function batchRegisterMints(uint[] memory tokenIds) external authorizedFor(Permission.RegisterNewMints) {
        bool hasDuplicate;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];

            if (dividends[tokenId] != 0) {
                hasDuplicate = true;
                break;
            }

            if (totalDividend == 0) {
                dividends[tokenId] = 1; // to distinguish EpicHeroNFT added before the first reflection from unregistered EpicHeroNFT
            } else {
                dividends[tokenId] = totalDividend;
            }
        }

        require(!hasDuplicate, "Contains already registered token(s)");

        totalEpicHero += tokenIds.length;
    }

    function initializeMints() internal {
        uint supply = EpicHeroNFT.totalSupply();

        if (supply > 1000) supply = 1000; // max gas limit

        for (uint256 i = 0; i < supply; i++) {
            dividends[i] = 1; // to distinguish EpicHeroNFT added before the first reflection from unregistered EpicHeroNFT
        }

        totalEpicHero = supply;
    }

    function setWbnbAddress(address _newAddress) external authorizedFor(Permission.AdjustVariables) {
        wbnbAddress = _newAddress;
    }

    function setEpicHeroNFTAddress(address _newAddress) external authorizedFor(Permission.AdjustVariables) {
        epicHeroNFTAddress = _newAddress;
        EpicHeroNFT = IEpicHeroNFT(_newAddress);
    }

    // use only in emergencies, could lead to some people being unable to get out the correct rewards
    function teamSetDividend(uint tokenId, uint128 lastDividendAt, uint128 realized) external authorizedFor(Permission.AdjustVariables) {
        setDividend(tokenId, lastDividendAt, realized);
    }

    // use only in emergencies, could lead to some people being unable to get out the correct rewards
    function retrieveTokens(address token, uint amount) external authorizedFor(Permission.RetrieveTokens) {
        require(IBEP20(token).transfer(msg.sender, amount), "Transfer failed");
    }

    function retrieveBNB(uint amount) external authorizedFor(Permission.RetrieveTokens) {
        (bool success,) = payable(msg.sender).call{ value: amount }("");
        require(success, "Failed to retrieve BNB");
    }

    function onERC721Received(address, address, uint, bytes calldata) public pure override returns (bytes4) {
        return 0x150b7a02;
    }

    function setDividend(uint index, uint lastDividendAt, uint realized) internal {
        uint256 div = lastDividendAt;
        div |= realized << 128;
        dividends[index] = div;
    }
}