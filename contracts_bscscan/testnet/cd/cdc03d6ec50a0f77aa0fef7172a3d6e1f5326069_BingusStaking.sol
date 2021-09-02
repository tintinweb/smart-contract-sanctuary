/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

// SPDX-License-Identifier: MIT
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

interface IAuth {
    function authorizeFor(address adr, string memory permissionName) external;
    function authorizeForMultiplePermissions(address adr, string[] calldata permissionNames) external;
    function authorizeForAllPermissions(address adr) external;
}

enum Permission {
    Authorize,
    Unauthorize,
    LockPermissions,

    AdjustVariables,
    RetrieveTokens
}

/**
 * Allows for contract ownership along with multi-address authorization for different permissions
 */
abstract contract Auth is IAuth {
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
        permissionNameToIndex["AdjustVariables"] = uint(Permission.AdjustVariables);
        permissionNameToIndex["RetrieveTokens"] = uint(Permission.RetrieveTokens);

        permissionIndexToName[uint(Permission.Authorize)] = "Authorize";
        permissionIndexToName[uint(Permission.Unauthorize)] = "Unauthorize";
        permissionIndexToName[uint(Permission.LockPermissions)] = "LockPermissions";
        permissionIndexToName[uint(Permission.AdjustVariables)] = "AdjustVariables";
        permissionIndexToName[uint(Permission.RetrieveTokens)] = "RetrieveTokens";
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
    function authorizeFor(address adr, string memory permissionName) public override {
        authorizedFor(Permission.Authorize);
        uint permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = true;
        emit AuthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Authorize address for multiple permissions
     */
    function authorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public override {
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
    function authorizeForAllPermissions(address adr) public override {
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

interface IBingusStaking {
    function getTotalStaked() external view returns (uint);
    function getTotalRewards() external view returns (uint);
    function getCumulativeRewardsPerLP() external view returns (uint);
    function getTotalRealised() external view returns (uint);
    function getLastContractBalance() external view returns (uint);
    function getAccuracyFactor() external view returns (uint);

    function getStake(address staker) external view returns (uint);
    function getEarnings(address staker) external returns (uint);
    
    function stake(uint amount) external;
    function unstake(uint amount) external;
    
    function getPairAddress() external view returns (address);
    function getTokenAddress() external view returns (address);
    
    event Realised(address account, uint amount);
    event Staked(address account, uint amount);
    event Unstaked(address account, uint amount);
    
    event FeesDistributed(address account, uint amount);
}

contract BingusStaking is Auth, IBingusStaking {
    uint _accuracyFactor = 10 ** 20; // Bingus only has 9 decimals, unlike the LP so we need to overcompensate. shouldn't be able to overflow, cause that's at 10^77
    
    IBEP20 _pair;
    bool _pairInitialized;

    IBEP20 _token;
    bool _tokenInitialized;

    struct Stake {
        uint LP; // Amount of LP tokens staked
        uint128 excludedAmt; // Amount of staking rewards to exclude from returns (if claimed or staked after)
        uint128 realised; // realised rewards
    }

    mapping (address => Stake) public stakes;
    
    uint _totalLP;
    uint _rewardsPerLP; // always inflated by _accuracyFactor because it would be too small otherwise for accurate divisions
    uint _totalRealised;
    uint _lastContractBalance;

    bool public contractsAllowedToStake;

    constructor() Auth(msg.sender) {
        _pair = IBEP20(0xbcca17a1e79Cb6Fcf2A5B7433e6fBCb7408Ca535);
        _pairInitialized = true;

        _token = IBEP20(0x480c1C5EBCa764AD72F37Da63272E12767FB45eB);
        _tokenInitialized = true;
    }

    /**
     * Total LP tokens staked
     */
    function getTotalStaked() external override view returns (uint) {
        return _totalLP;
    }

    /**
     * Total rewards realised and to be realised
     */
    function getTotalRewards() external override view tokenInitialized returns (uint) {
        return _totalRealised + _token.balanceOf(address(this));
    }

    /**
     * Total rewards per LP cumulatively, inflated by _accuracyFactor
     */
    function getCumulativeRewardsPerLP() external override view returns (uint) {
        return _rewardsPerLP;
    }
    
    /**
     * Total amount of transaction fees sent or to be sent to stakers
     */
    function getTotalRealised() external override view returns (uint) {
        return _totalRealised;
    }

    /**
     * The last balance the contract had
     */
    function getLastContractBalance() external override view returns (uint) {
        return _lastContractBalance;
    }

    /**
     * Total amount of transaction fees sent or to be sent to stakers
     */
    function getAccuracyFactor() external override view returns (uint) {
        return _accuracyFactor;
    }

    /**
     * Returns amount of LP that address has staked
     */
    function getStake(address account) public override view returns (uint) {
        return stakes[account].LP;
    }
    
    /**
     * Returns total earnings (realised + unrealised)
     */
    function getEarnings(address staker) external override view returns (uint) {
        return stakes[staker].realised + earnt(staker); // realised gains plus outstanding earnings
    }
    
    /**
     * Returns unrealised earnings
     */
    function getUnrealisedEarnings(address staker) external view returns (uint) {
        return earnt(staker);
    }
    
    /**
     * Stake LP tokens to earn a share of the 4% tx fee
     */
    function stake(uint amount) external override onlyNonContract pairInitialized {
        _stake(msg.sender, amount);
    }
    
    /**
     * Unstake LP tokens
     */
    function unstake(uint amount) external override pairInitialized {
        _unstake(msg.sender, amount);
    }
    
    /**
     * Return Cake-LP pair address
     */
    function getPairAddress() external view override returns (address) {
        return address(_pair);
    }
    
    /**
     * Return reward token address
     */
    function getTokenAddress() external view override returns (address) {
        return address(_token);
    }
    
    /**
     * Convert unrealised staking gains into actual balance
     */
    function realise() public {
        _realise(msg.sender);
    }
    
    /**
     * Realises outstanding staking rewards into balance
     */
    function _realise(address account) internal tokenInitialized {
        _updateRewards();

        uint128 amount = uint128(earnt(account));

        if (getStake(account) == 0 || amount == 0) {
            return;
        }

        stakes[account].realised += amount;
        stakes[account].excludedAmt += amount;
        _totalRealised += amount;

        require(_token.transfer(account, amount), "Couldn't transfer realised amount to holder.");

        _updateRewards();

        emit Realised(account, amount);
    }
    
    /**
     * Calculate current outstanding staking gains
     */
    function earnt(address account) internal view returns (uint) {
        uint rewardsWithExcluded = (stakes[account].LP * _rewardsPerLP) / _accuracyFactor;
        if (stakes[account].LP == 0 || rewardsWithExcluded <= stakes[account].excludedAmt) { return 0; }

        uint availableFees = rewardsWithExcluded - stakes[account].excludedAmt;
        return availableFees;
    }
    
    /**
     * Stake amount LP from account
     */
    function _stake(address account, uint amount) internal pairInitialized tokenInitialized {
        require(amount > 0, "You can't stake 0 tokens.");
        
        _realise(account);

        // add to current address' stake
        stakes[account].LP += amount;
        stakes[account].excludedAmt += uint128(_rewardsPerLP * amount / _accuracyFactor);
        _totalLP += amount;

        require(_pair.transferFrom(account, address(this), amount), "LP Tokens couldn't be transferred to staking contract. Make sure the allowance is high enough."); // transfer LP tokens from account

        emit Staked(account, amount);
    }
    
    /**
     * Unstake amount for account
     */
    function _unstake(address account, uint amount) internal pairInitialized tokenInitialized {
        require(stakes[account].LP >= amount, "You can't unstake more tokens than you have staked."); // ensure sender has staked more than or equal to requested amount
        
        _realise(account); // realise staking gains
        
        // remove stake
        stakes[account].LP -= amount;
        stakes[account].excludedAmt -= uint128(_rewardsPerLP * amount / _accuracyFactor);
        _totalLP -= amount;

        // send LP tokens back
        require(_pair.transfer(account, amount), "LP Tokens couldn't be transferred back to holder.");
        
        emit Unstaked(account, amount);
    }

    function _distribute(uint amount) internal returns(bool) {
        if (_totalLP == 0 || amount == 0) { return false; } // this check failing shouldn't revert the entire transaction so it's not a require()

        _rewardsPerLP += amount * _accuracyFactor / _totalLP;
        return true;
    }

    function _updateRewards() internal tokenInitialized {
        uint tokenBalance = _token.balanceOf(address(this));

        if (tokenBalance == _lastContractBalance) { return; }
        else if (tokenBalance > _lastContractBalance) {
            // since this function is always called before and after every realisation, _lastContractBalance should always be up to date so this call shouldn't be able to miss any added balances
            if(!_distribute(tokenBalance - _lastContractBalance)) {
                return; // this way, _lastContractBalance isn't updated which means that there's nothing lost in case _totalLP is 0
            }
        }

        _lastContractBalance = tokenBalance;
    }

    /**
     * Require pair address to be set
     */
    modifier pairInitialized() { require(_pairInitialized, "Pair isn't initalized."); _; }

    /**
     * Require token address to be set
     */
    modifier tokenInitialized() { require(_tokenInitialized, "Token isn't initialized."); _; }

    /**
     * Block contracts from calling a function, only allow user wallets
     */
    modifier onlyNonContract() {
        if (!contractsAllowedToStake) {
            require(tx.origin == msg.sender);
            address a = msg.sender;
            uint32 size;
            assembly {
                size := extcodesize(a)
            }
            require(size == 0);
        }

        _;
    }

    /**
     * Set the pair address.
     * Doesn't allow changing whilst LP is staked (as this would prevent stakers getting their LP back)
     */
    function setPairAddress(address pair) external {
        authorizedFor(Permission.AdjustVariables);
        require(_totalLP == 0, "Cannot change pair whilst there is LP staked");
        _pair = IBEP20(pair);
        _pairInitialized = true;
    }

    /**
     * Set the token address.
     * Doesn't allow changing whilst LP is staked
     */
    function setTokenAddress(address token) external {
        authorizedFor(Permission.AdjustVariables);
        require(_totalLP == 0, "Cannot change pair whilst there is LP staked");
        _token = IBEP20(token);
        _tokenInitialized = true;
    }

    /**
     * Set the accuracy factor
     */
    function setAccuracyFactor(uint newFactor) external {
        authorizedFor(Permission.AdjustVariables);
        _rewardsPerLP = _rewardsPerLP * newFactor / _accuracyFactor; // switch _rewardsPerLP to be inflated by the new factor instead
        _accuracyFactor = newFactor;
    }

    /**
     * Set contracts being allowed to stake
     */
    function setContractsAllowedToStake(bool allowed) external {
        authorizedFor(Permission.AdjustVariables);
        contractsAllowedToStake = allowed;
    }

    /**
     * Withdraw tokens in case some got stuck in the contract e.g. by switching the token address
     * Warning: if this function is executed on the current token there should be a migration to a different contract, since it will probably cause issues in withdrawal math
     */
    function emergencyWithdrawTotalBalanceOfToken(address tokenAddress) external tokenInitialized {
        authorizedFor(Permission.RetrieveTokens);

        IBEP20 token;
        if (tokenAddress == address(_token)) {
            token = _token;
            _rewardsPerLP = 0;
        } else {
            token = IBEP20(tokenAddress);
        }
        uint bal = token.balanceOf(address(this));
        
        require(token.transfer(msg.sender, bal), "Transfer to owner failed.");
    }
}