/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

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

interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

enum Permission {
    Authorize,
    Unauthorize,
    LockPermissions,

    AdjustVariables,
    RetrieveTokens,

    SetReward
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
        permissionNameToIndex["AdjustVariables"] = uint(Permission.AdjustVariables);
        permissionNameToIndex["RetrieveTokens"] = uint(Permission.RetrieveTokens);
        permissionNameToIndex["SetReward"] = uint(Permission.SetReward);

        permissionIndexToName[uint(Permission.Authorize)] = "Authorize";
        permissionIndexToName[uint(Permission.Unauthorize)] = "Unauthorize";
        permissionIndexToName[uint(Permission.LockPermissions)] = "LockPermissions";
        permissionIndexToName[uint(Permission.AdjustVariables)] = "AdjustVariables";
        permissionIndexToName[uint(Permission.RetrieveTokens)] = "RetrieveTokens";
        permissionIndexToName[uint(Permission.SetReward)] = "SetReward";
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownership required."); _;
    }

    /**
     * Function to require caller to be authorized
     */
    function authorizedFor(Permission permission) internal view {
        require(!lockedPermissions[uint(permission)].isLocked, "Permission is locked.");
        require(isAuthorizedFor(msg.sender, permission), string(abi.encodePacked("Not authorized. You need the permission ", permissionIndexToName[uint(permission)])));
    }

    /**
     * Authorize address for one permission
     */
    function authorizeFor(address adr, string memory permissionName) public {
        authorizedFor(Permission.Authorize);
        uint permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = true;
        emit AuthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Authorize address for multiple permissions
     */
    function authorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public {
        authorizedFor(Permission.Authorize);
        for (uint i; i < permissionNames.length; i++) {
            uint permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = true;
            emit AuthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    /**
     * Authorize address for all permissions
     */
    function authorizeForAllPermissions(address adr) public {
        authorizedFor(Permission.Authorize);
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[adr][i] = true;
        }
    }

    /**
     * Remove address' authorization
     */
    function unauthorizeFor(address adr, string memory permissionName) public {
        authorizedFor(Permission.Unauthorize);
        require(adr != owner, "Can't unauthorize owner");

        uint permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = false;
        emit UnauthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Unauthorize address for multiple permissions
     */
    function unauthorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public {
        authorizedFor(Permission.Unauthorize);
        require(adr != owner, "Can't unauthorize owner");

        for (uint i; i < permissionNames.length; i++) {
            uint permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = false;
            emit UnauthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    /**
     * Unauthorize address for all permissions
     */
    function unauthorizeForAllPermissions(address adr) public {
        authorizedFor(Permission.Unauthorize);
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[adr][i] = false;
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
    function lockPermission(string memory permissionName, uint64 time) public virtual {
        authorizedFor(Permission.LockPermissions);

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

interface IMysteriousCrates {
    function mintCrate(address user, uint[] memory cardIds) external;
}

interface ILandCrates {
    function mintHillCrate(uint16 numCrates) external payable;
    function mintMountainCrate(uint16 numCrates) external payable;
    function mintCoastCrate(uint16 numCrates) external payable;
    function getAllCratesOfUser(address user) external view returns(uint[] memory crateIds);
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function balanceOf(address owner) external view returns (uint balance);
    function approve(address to, uint tokenId) external;
    function totalSupply() external view returns (uint);
}

/**
 * https://risingsun.finance/
 */
contract BKRewards is RSunAuth, IERC721Receiver {
    IMysteriousCrates public samuraiCrates;
    ILandCrates public landCrates;
    IBEP20 public influence;
    IBEP20 public risingsun;

    uint public samuraiCrateLimit = 75;
    uint public infCrateLimit = 500;
    uint public landCouponLimit = 100;

    enum LandType { Hill, Mountain, Coast }

    mapping(address => uint) public availableSamCrates;
    mapping(address => uint[]) public availableINFCrates;
    mapping(address => uint) public availableLandCoupons;

    event SamuraiCrateClaimed(address indexed user);
    event INFCrateClaimed(address indexed user, uint amount, uint index);
    event LandCrateClaimed(address indexed user, LandType _landType);

    constructor(address _samuraiCrates, address _landCrates, address _influence, address _risingsun) RSunAuth(msg.sender) {
        samuraiCrates = IMysteriousCrates(_samuraiCrates);
		landCrates = ILandCrates(_landCrates);
        influence = IBEP20(_influence);
        risingsun = IBEP20(_risingsun);

        risingsun.approve(_landCrates, type(uint256).max);
    }

    function getAvailableINFCrates(address _user) external view returns(uint[] memory) {
        return availableINFCrates[_user];
    } 

    // CLAIM FUNCTIONS

    /**
     * Claim a 0* Samurai crate.
     */
    function claimSamuraiCrate() external {
        require(availableSamCrates[msg.sender] > 0, "no Samurai crates claimable");

        availableSamCrates[msg.sender] -= 1;

        uint[] memory cardIds = new uint[](3);
        cardIds[0] = 5000;
        cardIds[1] = 5000;
        cardIds[2] = 5000;

        // INTERACTIONS
        samuraiCrates.mintCrate(msg.sender, cardIds);
        
        emit SamuraiCrateClaimed(msg.sender);
    }

    /**
     * Claim an INF Crate to receive a random amount of INF.
     */
    function claimINFCrate() external {
        uint infCratesLen = availableINFCrates[msg.sender].length;
        require(infCratesLen > 0, "no INF crates claimable");

        uint amount = availableINFCrates[msg.sender][infCratesLen - 1];
        availableINFCrates[msg.sender].pop();

        // INTERACTIONS
        require(influence.transfer(msg.sender, amount), "failed to transfer INF");

        emit INFCrateClaimed(msg.sender, amount, infCratesLen - 1);
    }

    function claimHillCoupon() external payable {
        claimLandCoupon(LandType.Hill);
    }

    function claimMountainCoupon() external payable {
        claimLandCoupon(LandType.Mountain);
    }

    function claimCoastCoupon() external payable {
        claimLandCoupon(LandType.Coast);
    }

    /**
     * Claim a land coupon to receive a land crate with the RSUN fee discounted.
     */
    function claimLandCoupon(LandType _landType) public payable {
        require(availableLandCoupons[msg.sender] > 0, "no Land coupons claimable");

        availableLandCoupons[msg.sender] -= 1;

        // INTERACTIONS
        uint totalSupply = landCrates.totalSupply();

        if (_landType == LandType.Hill) {
            landCrates.mintHillCrate{value: msg.value}(1);
        } else if (_landType == LandType.Mountain) {
            landCrates.mintMountainCrate{value: msg.value}(1);
        } else if (_landType == LandType.Coast) {
            landCrates.mintCoastCrate{value: msg.value}(1);
        }

        landCrates.safeTransferFrom(address(this), msg.sender, totalSupply);
        
        emit LandCrateClaimed(msg.sender, _landType);
    }
    
    // SET REWARD FUNCTIONS

    function incrementSamuraiCrate(address[] memory _addresses) external {
        authorizedFor(Permission.SetReward);
        require(_addresses.length <= samuraiCrateLimit, "too many samurai");

        for (uint i = 0; i < _addresses.length; i++) {
            availableSamCrates[_addresses[i]]++;
        }
    }

    function incrementINFCrate(address[] memory _addresses, uint[] memory _amounts) external {
        authorizedFor(Permission.SetReward);
        require(_addresses.length <= infCrateLimit, "too many INF crates");
        require(_addresses.length == _amounts.length, "addresses and amounts are different lengths");

        for (uint i = 0; i < _addresses.length; i++) {
            availableINFCrates[_addresses[i]].push(_amounts[i]);
        }
    }

    function incrementLandCoupon(address[] memory _addresses) external {
        authorizedFor(Permission.SetReward);
        require(_addresses.length <= landCouponLimit, "too many land crates");

        for (uint i = 0; i < _addresses.length; i++) {
            availableLandCoupons[_addresses[i]]++;
        }
    }

    function mintSamuraiCrates(address[] memory _addresses) external {
        authorizedFor(Permission.SetReward);
        require(_addresses.length <= samuraiCrateLimit, "too many samurai");

        uint[] memory cardIds = new uint[](3);
        cardIds[0] = 5000;
        cardIds[1] = 5000;
        cardIds[2] = 5000;

        // INTERACTIONS
        for (uint i = 0; i < _addresses.length; i++) {
            samuraiCrates.mintCrate(_addresses[i], cardIds);
        }
    }

    function setIncrementLimits(uint _samuraiCrateLimit, uint _infCrateLimit, uint _landCouponLimit) external {
        authorizedFor(Permission.AdjustVariables);
        samuraiCrateLimit = _samuraiCrateLimit;
        infCrateLimit = _infCrateLimit;
        landCouponLimit = _landCouponLimit;
    }

    function retrieveTokens(address token, uint amount) external {
        authorizedFor(Permission.RetrieveTokens);
        require(IBEP20(token).transfer(msg.sender, amount), "Transfer failed");
    }

    function retrieveBNB(uint amount) external {
        authorizedFor(Permission.RetrieveTokens);
        (bool success,) = payable(msg.sender).call{ value: amount }("");
        require(success, "Failed to retrieve BNB");
    }

    function onERC721Received(address, address, uint, bytes calldata) public pure override returns (bytes4) {
        return 0x150b7a02;
    }

    receive() external payable {}
}