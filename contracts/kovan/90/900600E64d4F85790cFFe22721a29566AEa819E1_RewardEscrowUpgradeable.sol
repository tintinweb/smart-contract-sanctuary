/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts-upgradeable/access/[email protected]



pragma solidity ^0.8.0;


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


// File contracts/Interface/IAddressResolver.sol

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


// File contracts/Tools/CacheResolverUpgradeable.sol


pragma solidity ^0.8.0;

// Inheritance
// Internal References
contract CacheResolverUpgradeable is OwnableUpgradeable  {
    
    IAddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    function _cacheInit(address _resolver) internal initializer {
        resolver = IAddressResolver(_resolver);
    }

    /** ========== public view functions ========== */

    function resolverAddressesRequired() public view virtual returns (bytes32[] memory addresses)  {}


    /** ========== external mutative functions ========== */
    function rebuildCache() external {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination =
                resolver.requireAndGetAddress(name, string(abi.encodePacked("Resolver missing target: ", name)));
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }


    function setAddressResolver(address _resolver) external onlyOwner {
        require(_resolver != address(0), "the resolver is extremely important, so you must set a correct address");
        resolver = IAddressResolver(_resolver);
    }

    /** ========== external view functions ========== */
    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    /** ========== internal view functions ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second)
        internal
        pure
        returns (bytes32[] memory combination)
    {
        combination = new bytes32[](first.length + second.length);

        for (uint i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    function requireAndGetAddress(bytes32 name) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Missing address: ", name)));
        return _foundAddress;
    }

    /** ========== event ========== */

    event CacheUpdated(bytes32 name, address destination);
}


// File contracts/Interface/IToken.sol

interface IToken {
    function balanceOf(address account) external view returns (uint);

    function name() external view returns (string memory);

    function transfer(address account, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File contracts/Interface/ISystemStatus.sol

interface ISystemStatus {


    // global access list controller
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);


    // Be similar with the feature of requir(), the following function is used to check whether the section is active or not.
    function requireSystemActive() external view;

    function requireRewardPoolActive() external view;

    function requireCollectionTradingActive() external view;

    function requireActivitiesActive() external view;

    function requireStableCoinActive() external view;

    function requireDAOActive() external view;

    // status of key functions of each system section
    // function voterecordingActive() external view;

    function requireFunctionActive(bytes32 functionname, bytes32 section) external view returns (bool);


    // whether tbe system is upgrading or not
    function isSystemUpgrading() external view returns (bool);
    
    // check the details of suspension of each section.
    function getSuspensionStatus(bytes32 section) external view returns(
        bool suspend,
        uint reason,
        uint timestamp,
        address operator
    );

    function getFunctionSuspendstionStatus(bytes32 functionname, bytes32 section) external view returns(
        bool suspend,
        uint reason,
        uint timestamp,
        address operator
    );


}


// File contracts/Interface/IPortal.sol

interface IPortal {

    // read functions
    function getTotalLockedAmount() external view returns (uint);

    function getAccountBalancesLockedAmount(address account) external view returns (uint);

    function getAccountEscrowedLockedAmount(address account) external view returns (uint);

    function getbalanceOfEscrowedAndAvailableAmount(address account) external view returns (uint);

    function getAccountTotalLockedAmount(address account) external view returns (uint accountTotalLockedAmount);

    function getTransferableAmount(address account) external view returns (uint transferable);

    // write functions
    function enter(address player, uint value, bool enterall) external;

    function withdraw(address player, uint value, bool withdrawall) external;

    function getReward(address player, uint _rewardSaveDuration) external;

    function exit(address player, uint value, bool withdrawall, uint _rewardSaveDuration) external;

    function transferEscrowedToBalancesLocked(address account, uint amount) external;

    function updateAccountEscrowedAndAvailableAmount(address account, uint amount, bool add, bool sub) external;
}


// File contracts/Interface/IRewardState.sol

interface IRewardState {
    function getReward(address player, uint _rewardSaveDuration) external;

    function earned(address account) external view returns (uint256);

    function balanceOf(address account) external view returns (uint);

    function getRewardDistribution() external view returns (address);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);
}


// File contracts/Reward/RewardEscrowUpgradeable.sol


pragma solidity ^0.8.0;

// Inheritance
// Internal References
contract RewardEscrowUpgradeable is OwnableUpgradeable, CacheResolverUpgradeable {

    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_TOKEN = "Token"; 
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_PORTAL = "Portal";
    bytes32 private constant CONTRACT_REWARDSTATE = "RewardState";

    function resolverAddressesRequired() public view override returns (bytes32[] memory) {
        bytes32[] memory addresses = new bytes32[](4);
        addresses[0] = CONTRACT_TOKEN;
        addresses[1] = CONTRACT_SYSTEMSTATUS;
        addresses[2] = CONTRACT_PORTAL;
        addresses[3] = CONTRACT_REWARDSTATE;
        return addresses;
    }

    function token() internal view returns (IToken) {
        return IToken(requireAndGetAddress(CONTRACT_TOKEN));
    }

    function systemStatue() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function portal() internal view returns (IPortal) {
        return IPortal(requireAndGetAddress(CONTRACT_PORTAL));
    }

    function rewardState() internal view returns (IRewardState) {
        return IRewardState(requireAndGetAddress(CONTRACT_REWARDSTATE));
    }

    /** variables */

    /** Escrow Related Variables */ 

    // detail of an escrow event
    struct accountEscrowed {
        uint escrowedEndTime;
        uint escrowedAmount;
    }
    // an account's escrowed token recording
    mapping (address => mapping(uint => accountEscrowed)) public accountEscrowedEvent;

    // an account's escrow event entries
    mapping (address => uint256[]) public accountEscrowedEntries;

    // an account's total Escrowed token amount
    mapping(address => uint256) public accountTotalEscrowedBalance;

    // total Escrowedtoken in this Escrow Contract
    uint public totalEscrowedBalance;

    // users are not allowed to escrow too much which may encounter unbounded iteration over release
    uint public max_escrowNumber;

    // num of all escrow events in this Escrow Contract and it can be used to generate the next escrow event of an account
    uint public nextEntry;

    /** Vest Related Variables */ 

    // detail of an vest event
    struct accountReleased {
        uint releasedAcquiredTime;
        uint totalReleasedAmount;
    }

    // an account's total Released token amount
    mapping(address => accountReleased) public accountTotalReleasedBalance;

    // duration
    uint public max_escrowduration;

    uint public min_escrowduration;

    //todo the max_escrowduration and min_escrowduration can be defined in RewardState.

    function escrow_init(address _resolver, uint _max_escrowNumber, uint _min_escrowduration, uint _max_escrowduration) external initializer {
        _cacheInit(_resolver);
        __Ownable_init();
        nextEntry = 1;
        max_escrowNumber = _max_escrowNumber;
        min_escrowduration = _min_escrowduration;
        max_escrowduration = _max_escrowduration;
    }


    /** ========== public view functions ========== */
    function accountEscrowedEndTime(address account, uint index) public view returns (uint) {
        return accountEscrowedEvent[account][index].escrowedEndTime;
    }

    function accountEscorwedAmount(address account, uint index) public view returns (uint) {
        return accountEscrowedEvent[account][index].escrowedAmount;
    }

    function accountReleasedAcquiredTime(address account) public view returns (uint) {
        return accountTotalReleasedBalance[account].releasedAcquiredTime;
    }

    function accountTotalReleasedAmount(address account) public view returns (uint) {
        return accountTotalReleasedBalance[account].totalReleasedAmount;
    }

    /** ========== external mutative functions ========== */

    function release(address receiver, bool keepLocked) external {
        uint total;
        uint amount;
        for (uint i = 0; i < _accountEscrowednum(receiver); i++) {
            accountEscrowed storage entry = accountEscrowedEvent[receiver][accountEscrowedEntries[receiver][i]];

            /* Skip entry if escrowAmount == 0 already released */
            if (entry.escrowedAmount != 0) {
                amount = _claimableAmount(entry);

                /* update entry to remove escrowAmount */
                if (amount > 0) {
                    entry.escrowedAmount = 0;
                }

                /* add quantity to total */
                total = total + amount;
            }
        }
            if(total != 0) {
            _release(receiver, amount, keepLocked);
        }
    }

    /*
     * @description: the function call will be limited by another contract of this system for restricting users add escrow entries at their will.
     * @param account the account to append a new escrow entry
     * @param amount escrowed amount 
     * @param duration user can customize the duration but need to accord with min duration and max duration
     */    
    function appendEscrowEntry(address account, uint amount, uint duration) external onlyInternalContract {
        require(account != address(0), "null address is not allowed");

        _appendEscrowEntry(account, amount, duration);

    }

    /** ========== OnlyOwner external mutative functions ========== */

    function updateDuration(uint min_escrowduration_, uint max_escrowduration_) external onlyOwner {
        min_escrowduration = min_escrowduration_;
        max_escrowduration = max_escrowduration_;
    }

    /** ========== external view functions ========== */
    
    function escrowedTokenBalanceOf(address account) external view returns(uint amount) {
        return accountTotalEscrowedBalance[account];
    }

    /** ========== internal mutative functions ========== */

    function _release(address receiver, uint _amount, bool keepLocked) internal {
        require(_amount <= token().balanceOf(address(this)), "there are not enough token to release");

        uint escrowedandlockedAmount = portal().getAccountEscrowedLockedAmount(receiver);
        if(escrowedandlockedAmount > 0) {

            // if user choose to keep locked token locked, 
            // transfer the Locked token Escrowed from balances
            if(keepLocked == true) {
                if(_amount <= escrowedandlockedAmount) {
                    portal().transferEscrowedToBalancesLocked(receiver, _amount);
                }

                if(_amount > escrowedandlockedAmount) {
                    uint _resttoken = _amount - escrowedandlockedAmount;
                    portal().transferEscrowedToBalancesLocked(receiver, escrowedandlockedAmount);

                    portal().updateAccountEscrowedAndAvailableAmount(receiver, _resttoken, false, true);
                    token().transfer(receiver, _resttoken);
                }

            }

            // if user choose to withdraw all token even though there are locked part
            // withdraw escrowedandlockedAmount from portal
            if(keepLocked == false) {
                if(_amount > escrowedandlockedAmount) {
                    portal().withdraw(receiver, escrowedandlockedAmount, false);
                    uint _resttoken = _amount - escrowedandlockedAmount;
                    token().transfer(receiver, _resttoken);
                }

                if(_amount <= escrowedandlockedAmount) {
                    portal().withdraw(receiver, escrowedandlockedAmount, false);
                }
            }

        }
        
        // if there aren't token locked in portal, transfer directly
        if(escrowedandlockedAmount == 0) {
            token().transfer(receiver, _amount);
        }

        // update state in RewardEscrow
        _reduceAccountEscrowedBalance(receiver, _amount);
        _updateAccountReleasedEntry(receiver, _amount);
        emit released(receiver, _amount);
    }


    //todo user can choose to vest their token which is not staked into the contract or vest those have been staked into contract. 
    //     if the vesting token have been staked into contract that maybe I need to provide a new function that vest and stake the token immediately.

    function _appendEscrowEntry(address account, uint _amount, uint _duration) internal {
        require(_duration >= min_escrowduration && _duration <= max_escrowduration, "you must set the duration between allowed duration");
        require(_accountEscrowednum(account) <= max_escrowNumber, "you have escrowed too much, we suggest you wait for your first escrowed token released");
        uint duration = _duration * 1 days;

        // update user's available lockable escrowed token
        portal().updateAccountEscrowedAndAvailableAmount(account, _amount, true, false);

        _addAccountEscrowedBalance(account, _amount);

        uint EndTime = block.timestamp + duration;
        uint entryID = nextEntry;

        accountEscrowedEvent[account][entryID] = accountEscrowed({escrowedEndTime: EndTime, escrowedAmount:_amount});
        accountEscrowedEntries[account].push(entryID);

        nextEntry = nextEntry + 1;

        emit appendedEscrowEntry(account, _amount, duration);
        
    }

    //todo add a internal function to calculate the locked reward of token, the longer they lock, the more they get. 
    //     and the function call is not from this contract, it will call a reward contract to modify some variables to calculate the reward.
    //     but this reward calculation will be confused becase all of the confirmed reward have been lock in this contract. If there is a new reward
    //     from this lock duration that will need to create a new escrow event. That will generate new confusion.


    function _addAccountEscrowedBalance(address account, uint _amount) internal {
        totalEscrowedBalance = totalEscrowedBalance + _amount;
        accountTotalEscrowedBalance[account] = accountTotalEscrowedBalance[account] + _amount;
    }

    function _reduceAccountEscrowedBalance(address account, uint _amount) internal {
        totalEscrowedBalance = totalEscrowedBalance - _amount;
        accountTotalEscrowedBalance[account] = accountTotalEscrowedBalance[account] - _amount;
    }

    function _updateAccountReleasedEntry(address account, uint amount) internal {
        accountReleased storage entry = accountTotalReleasedBalance[account];
        uint currentAmount = entry.totalReleasedAmount;
        entry.releasedAcquiredTime = block.timestamp;
        entry.totalReleasedAmount = currentAmount + amount;
    }

    /** ========== internal view functions ========== */

    function _claimableAmount(accountEscrowed memory _entry) internal view returns (uint) {
        uint256 amount;
        if (_entry.escrowedAmount != 0) {
            /* Escrow amounts claimable if block.timestamp equal to or after entry endTime */
            amount = block.timestamp >= _entry.escrowedEndTime ? _entry.escrowedAmount : 0;
        }
        return amount;
    }


    function _accountEscrowednum(address account) internal view returns (uint num) {
        return num = accountEscrowedEntries[account].length;
    }

    /** ========== modifier ========== */


    modifier onlyInternalContract {
        require(address(rewardState()) == _msgSender(), "only allow internal contract to access");
        _;
    }
    //todo add a modifier to limit the function call of appendEscrowEntry must from a pointed contract
    //todo add a modifier to limit the function call of vest must from authorized user or the owner
 
    /** ========== event ========== */
    event released(address indexed receiver, uint indexed amount);
    event appendedEscrowEntry(address indexed account, uint indexed amount, uint indexed duration);

}