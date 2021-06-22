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


// File contracts/Interface/IRewardState.sol

interface IRewardState {
    function getReward(address player, uint _rewardSaveDuration) external;

    function earned(address account) external view returns (uint256);

    function balanceOf(address account) external view returns (uint);

    function getRewardDistribution() external view returns (address);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);
}


// File contracts/Interface/IRewardEscrowUpgradeable.sol

interface IRewardEscrowUpgradeable {

    // read functions
    function accountEscrowedEndTime(address account, uint index) external view returns (uint);

    function accountEscorwedAmount(address account, uint index) external view returns (uint);

    function accountReleasedAcquiredTime(address account) external view returns (uint);

    function accountReleasedTotalReleasedAmount(address account) external view returns (uint);

    function escrowedTokenBalanceOf(address account) external view returns(uint amount);

    // write functions
    function appendEscrowEntry(address account, uint amount, uint duration) external;

    function release(address receiver, bool keepLocked) external;
}


// File contracts/Portal.sol


pragma solidity ^0.8.0;

// Inheritance

// Internal References




contract Portal is OwnableUpgradeable,CacheResolverUpgradeable {
    

    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_TOKEN = "Token";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_REWARDSTATE = "RewardState";
    bytes32 private constant CONTRACT_REWARDESCROWUPGRADEABLE = "RewardEscrowUpgradeable";

    function resolverAddressesRequired() public view override returns (bytes32[] memory) {
        bytes32[] memory addresses = new bytes32[](4);
        addresses[0] = CONTRACT_TOKEN;
        addresses[1] = CONTRACT_SYSTEMSTATUS;
        addresses[2] = CONTRACT_REWARDSTATE;
        addresses[3] = CONTRACT_REWARDESCROWUPGRADEABLE;
        return addresses;
    }

    function token() internal view returns (IToken) {
        return IToken(requireAndGetAddress(CONTRACT_TOKEN));
    }
    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function rewardState() internal view returns (IRewardState) {
        return IRewardState(requireAndGetAddress(CONTRACT_REWARDSTATE));
    }
        
    function rewardEscrowUpgradeable() internal view returns (IRewardEscrowUpgradeable) {
        return IRewardEscrowUpgradeable(requireAndGetAddress(CONTRACT_REWARDESCROWUPGRADEABLE));
    }
 

    /* ========== variables ========== */
    uint internal totalLockedAmount;
    
    mapping (address => uint) internal accountBalancesLockedAmount;

    mapping (address => uint) internal accountEscrowedLockedAmount;

    mapping (address => uint) internal accountEscrowedAndAvailableAmount;

    function portal_init(address _resolver) external initializer {
        __Ownable_init();
        _cacheInit(_resolver);
        accountEscrowedAndAvailableAmount[_msgSender()] = 0;
    }

    /** ========== public view functions ========== */
    function getTotalLockedAmount() public view returns (uint) {
        return totalLockedAmount;
    }

    function getAccountBalancesLockedAmount(address account) public view returns (uint) {
        return accountBalancesLockedAmount[account];
    }

    function getAccountEscrowedLockedAmount(address account) public view returns (uint) {
        return accountEscrowedLockedAmount[account];
    }

    function getbalanceOfEscrowedAndAvailableAmount(address account) public view returns (uint) {
        return accountEscrowedAndAvailableAmount[account];
    }

    function getAccountTotalLockedAmount(address account) public view returns (uint accountTotalLockedAmount) {
        uint balancesLockedAmount = getAccountBalancesLockedAmount(account);
        uint escrowedLockedAmount = getAccountEscrowedLockedAmount(account);
        accountTotalLockedAmount = balancesLockedAmount + escrowedLockedAmount;

        return accountTotalLockedAmount;
    }


    /** ========== public mutative functions ========== */

    /*
     * @description: stake value to get an attendace rate and a NFT.
     * @dev update user's attendace rate which will be save in the state contract.
     * @param value the amount to stake
     */
    function enter(address player, uint value, bool enterall) public {
        // get user's available token to enter the ecosystem including the escrowed amount
        (uint accountTotalAvailableAmount, uint balanceOfuser, uint balanceOfEscrowed) = _remaininigAvailaleAmount(player);

        require(value <= accountTotalAvailableAmount, "you don't have enough token to enter");

        // register user's token and lock registered amount
        _registerPortalLock(player, balanceOfuser, balanceOfEscrowed, value, enterall);

        emit entered(player, value, enterall);
    }

    /*
     * @description: withdraw value which users enter with.
     * @dev update user's attendace rate and 
     * @param {*}
     */
    function withdrow(address player, uint value, bool withdrawall) public {

        // get user's locked token to withdraw
        (uint balancesLockedAmount, uint escrowedLockedAmount) = _getAccountLockedAmount(player);

        // remove locked token register
        _removeRegisterPortalLock(player, balancesLockedAmount, escrowedLockedAmount, value, withdrawall);

        emit withdrawn(player, value, withdrawall);
    }

    function getReward(address player, uint _rewardSaveDuration) public {
        rewardState().getReward(player, _rewardSaveDuration);
    }

    function exit(address player, uint value, bool withdrawall, uint _rewardSaveDuration) public {
        withdrow(player, value, withdrawall);
        getReward(player, _rewardSaveDuration);
    }


    /** ========== external mutative function ========== */
    function transferEscrowedToBalancesLocked(address account, uint amount) external onlyRewardEscrow {
        _updateAccountEscrowedLockedAmount(account, amount, false, true);
        _updateAccountBalancesLockedAmount(account, amount, true, false);

        emit transferredEscrowedToBalancesLocked(account, amount);
    }

    // update account escrowed token available quota
    function updateAccountEscrowedAndAvailableAmount(address account, uint amount, bool add, bool sub) external onlyRewardEscrow {
        require(add != sub, "not allowed to be the same");
        

        if(add == true) {
            accountEscrowedAndAvailableAmount[account] = accountEscrowedAndAvailableAmount[account] + amount;
        }

        if(sub == true) {
            require(accountEscrowedAndAvailableAmount[account] >= amount, "you don't have enough escrowed token");
            accountEscrowedAndAvailableAmount[account] = accountEscrowedAndAvailableAmount[account] - amount;
        }
    }

    /** ========== external view function ========== */

    function getTransferableAmount(address account) external view returns (uint transferable) {

        // transferable token will be only calculated from balances of user, excluding escrowed token,
        // becasue escrowed token is not allowed to transfer between wallet.
        uint acountlockedamount = accountBalancesLockedAmount[account];
        uint balanceOf = token().balanceOf(account);

        if( balanceOf <= acountlockedamount) {
            transferable = 0;
        } else {
            transferable = balanceOf - acountlockedamount;
        }
    }

    /** ========== internal mutative functions ========== */

    function _registerPortalLock(
        address player,
        uint balanceOfuser,
        uint balanceOfEscrowed,
        uint value,
        bool enterall
    ) internal {
        
        if(enterall == true) {
            _updateAccountBalancesLockedAmount(player, balanceOfuser, true, false);
            _updateAccountEscrowedLockedAmount(player, balanceOfEscrowed, true, false);
            
        }
        
        // if user doesn't enter all token, system will preferentially enter all escorwed available token
        if(enterall == false) {
            if(value >= balanceOfEscrowed) {
                uint _resttoken = value - balanceOfEscrowed;
                _updateAccountEscrowedLockedAmount(player, balanceOfEscrowed, true, false);
                _updateAccountBalancesLockedAmount(player, _resttoken, true, false);
            }

            if(value < balanceOfEscrowed) {
                _updateAccountEscrowedLockedAmount(player, value, true, false);
            }
        }

    }

    function _removeRegisterPortalLock(
        address player,
        uint balancesLockedAmount, 
        uint escrowedLockedAmount, 
        uint value, 
        bool withdrawall
        ) internal {

            if(withdrawall == true) {
                _updateAccountBalancesLockedAmount(player, balancesLockedAmount, false, true);
                _updateAccountEscrowedLockedAmount(player, escrowedLockedAmount, false, true);
            }

            if(withdrawall == false) {
                if(value > escrowedLockedAmount) {
                    uint _resttoken = value - escrowedLockedAmount;
                    _updateAccountEscrowedLockedAmount(player, escrowedLockedAmount, false, true);
                    _updateAccountBalancesLockedAmount(player, _resttoken, false, true);
                }

                if(value < escrowedLockedAmount) {
                    _updateAccountEscrowedLockedAmount(player, value, false, true);
                }
            }
    }

    // update account escrowed and locked token
    function _updateAccountEscrowedLockedAmount(address account, uint updatingLockedAmount, bool add, bool sub) internal {
        require(add != sub, "not allowed to be the same");

        if(add == true) {
            require(accountEscrowedAndAvailableAmount[account] >= updatingLockedAmount, "There are not enough available amount to lock");
            accountEscrowedLockedAmount[account] += updatingLockedAmount;
            accountEscrowedAndAvailableAmount[account] -= updatingLockedAmount;

            totalLockedAmount += updatingLockedAmount;
        }

        if(sub == true) {
            require(accountEscrowedLockedAmount[account] >= updatingLockedAmount, "There are not enough locked amount to sub");
            accountEscrowedLockedAmount[account] -= updatingLockedAmount;
            accountEscrowedAndAvailableAmount[account] += updatingLockedAmount;

            totalLockedAmount -= updatingLockedAmount;
        }
    } 

    // update account balances locked token
    function _updateAccountBalancesLockedAmount(address account, uint updatingLockedAmount, bool add, bool sub) internal {
        require(add != sub, "not allowed to be the same");

        if(add == true) {
            accountBalancesLockedAmount[account] += updatingLockedAmount;

            totalLockedAmount += updatingLockedAmount;
        }

        if(sub == true) {
            accountBalancesLockedAmount[account] -= updatingLockedAmount;

            totalLockedAmount -= updatingLockedAmount;
        }
    }

    /** ========== internal view functions ========== */

    function _remaininigAvailaleAmount(address account) internal view returns (
        uint accountTotalAvailableAmount,
        uint balanceOfuser,
        uint balanceOfEscrowed
    ) {
        balanceOfuser = token().balanceOf(account);
        balanceOfEscrowed = accountEscrowedAndAvailableAmount[account];
        accountTotalAvailableAmount = balanceOfuser + balanceOfEscrowed;
        return (accountTotalAvailableAmount, balanceOfuser, balanceOfEscrowed);
    }

    function _getAccountLockedAmount(address account) internal view returns (
        uint balancesLockedAmount,
        uint escrowedLockedAmount
    ) {
        balancesLockedAmount = getAccountBalancesLockedAmount(account);
        escrowedLockedAmount = getAccountEscrowedLockedAmount(account);

        return (balancesLockedAmount, escrowedLockedAmount);
    }

    /** ========== modifier ========== */
    modifier onlyRewardEscrow() {
        require(address(rewardEscrowUpgradeable()) == _msgSender(), "only rewardEscrow contract can access");
        _;
    }

    /** ========== event ========== */
    event transferredEscrowedToBalancesLocked(address indexed account, uint indexed amount);
    event entered(address indexed player, uint indexed value, bool indexed enterall);
    event withdrawn(address indexed player, uint indexed value, bool indexed withdrawall);
}