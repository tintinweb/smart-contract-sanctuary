/**
 *Submitted for verification at BscScan.com on 2021-07-19
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

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4);
}

enum Permission {
    Authorize,
    Unauthorize,
    LockPermissions,

    RetrieveTokens,
    AdjustVariables
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
    
    uint constant NUM_PERMISSIONS = 5; // always has to be adjusted when Permission element is added or removed
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

        permissionIndexToName[uint(Permission.Authorize)] = "Authorize";
        permissionIndexToName[uint(Permission.Unauthorize)] = "Unauthorize";
        permissionIndexToName[uint(Permission.LockPermissions)] = "LockPermissions";
        permissionIndexToName[uint(Permission.RetrieveTokens)] = "RetrieveTokens";
        permissionIndexToName[uint(Permission.AdjustVariables)] = "AdjustVariables";
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

struct Share {
    uint256 amount;
    uint256 totalExcluded;
    uint256 totalRealised;
}

interface IDividendDistributor {
    function shares(address shareholder) external returns (Share memory);
    function getUnpaidEarnings(address shareholder) external view returns (uint);
}

contract RSunFreeSwap is RSunAuth, IERC721Receiver {

    address public busdAdr = 0xbcca17a1e79Cb6Fcf2A5B7433e6fBCb7408Ca535;
    address public wbnbAdr = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address public rsunAdr = 0xB9930e78423c6148f3b94A9781af19785a0FFB16;
    address public nftAdr = 0xac563918F0ffE766c8B83e33D4744c1C4794cFC2;

    address public routerAdr = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address public distAdr = 0x066c5AB7d03924D586Ebb277A1097BC2CEB6964B;

    IDividendDistributor dist;
    IDEXRouter router;

    mapping(address => uint) public swappedBUSD;

    bool public isEnabledBUSD = true;
    bool public isEnabledBNB = true;
    uint public bnbSwappablePerNFT = 1 * 10 ** 16;

    constructor() RSunAuth(msg.sender) {
        router = IDEXRouter(routerAdr);
        dist = IDividendDistributor(distAdr);

        IBEP20(busdAdr).approve(routerAdr, ~uint(0));
    }

    function swapBUSDForRsunWithoutFees(uint busdAmt) external {
        require(isEnabledBUSD, "Feeless BUSD swapping is disabled");
        require(isEligibleForBUSD(msg.sender, busdAmt), "Not eligible for swapping this much BUSD for RSUN without fees");

        require(IBEP20(busdAdr).transferFrom(msg.sender, address(this), busdAmt), "Couldn't transfer BUSD to contract");

        address[] memory path = new address[](3);
        path[0] = busdAdr;
        path[1] = wbnbAdr;
        path[2] = rsunAdr;

        uint[] memory amounts = router.swapExactTokensForTokens(
            busdAmt,
            0, // no slippage required since a) BUSD/BNB liquidity is enormous and b) RSUN has high fees
            path,
            address(this),
            block.timestamp
        );

        swappedBUSD[msg.sender] += busdAmt;
        require(IBEP20(rsunAdr).transfer(msg.sender, amounts[2]), "Transfer to user failed");
    }

    function isEligibleForBUSD(address user, uint amount) internal returns (bool) {
        Share memory share = dist.shares(user);
        if (swappedBUSD[user] + amount > share.totalRealised + dist.getUnpaidEarnings(user)) {
            return false;
        }
        return true;
    }

    function swapBNBForRsunWithoutFees(uint nftId) external payable {
        require(isEnabledBNB, "Feeless NFT-based swapping is disabled");
        require(msg.value <= bnbSwappablePerNFT, "Not eligible for swapping this much BNB for RSUN without fees");

        IERC721(nftAdr).safeTransferFrom(msg.sender, address(this), nftId); // if user doesn't own the NFT, the function will revert

        address[] memory path = new address[](2);
        path[0] = wbnbAdr;
        path[1] = rsunAdr;

        uint[] memory amounts = router.swapExactETHForTokens{ value: msg.value }(
            0, // no slippage required since RSUN has high fees
            path,
            address(this),
            block.timestamp
        );

        require(IBEP20(rsunAdr).transfer(msg.sender, amounts[1]), "Transfer to user failed");
    }

    function setRsunAdr(address rsun_) external authorizedFor(Permission.AdjustVariables) {
        rsunAdr = rsun_;
    }

    function setBusdAdr(address busd_) external authorizedFor(Permission.AdjustVariables) {
        busdAdr = busd_;
    }
    
    function setWbnbAdr(address wbnb_) external authorizedFor(Permission.AdjustVariables) {
        wbnbAdr = wbnb_;
    }
    
    function setNFTAdr(address nft_) external authorizedFor(Permission.AdjustVariables) {
        nftAdr = nft_;
    }

    function setDistAdr(address dist_) external authorizedFor(Permission.AdjustVariables) {
        distAdr = dist_;
        dist = IDividendDistributor(dist_);
    }
   
    function setRouterAdr(address router_) external authorizedFor(Permission.AdjustVariables) {
        routerAdr = router_;
        router = IDEXRouter(router_);
    }

    function setBNBSwappablePerNFT(uint amt) external authorizedFor(Permission.AdjustVariables) {
        bnbSwappablePerNFT = amt;
    }

    function retrieveTokens(address token) external authorizedFor(Permission.RetrieveTokens) {
        require(IBEP20(token).transfer(msg.sender, IBEP20(token).balanceOf(address(this))), "Transfer failed");
    }

    function onERC721Received(address, address, uint, bytes calldata) public pure override returns (bytes4) {
        return 0x150b7a02;
    }
}