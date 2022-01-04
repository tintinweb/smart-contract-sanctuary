pragma solidity 0.8.6;


import "IERC777.sol";
import "ReentrancyGuard.sol";
import "IERC777Recipient.sol";
import "IERC1820Registry.sol";
import "IStakeManager.sol";
import "IOracle.sol";
import "Shared.sol";


contract StakeManager is IStakeManager, Shared, ReentrancyGuard, IERC777Recipient {

    uint public constant STAN_STAKE = 10000 * _E_18;
    uint public constant BLOCKS_IN_EPOCH = 100;
    bytes private constant _stakingIndicator = "staking";

    IOracle private immutable _oracle;
    // AUTO ERC777
    IERC777 private _AUTO;
    bool private _AUTOSet = false;
    IERC1820Registry constant private _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256('ERC777TokensRecipient');
    uint private _totalStaked = 0;
    // Needed so that receiving AUTO is rejected unless it's indicated
    // that's it's used for staking and therefore not an accident (protect users)
    Executor private _executor;
    mapping(address => uint) private _stakerToStakedAmount;
    address[] private _stakes;


    // Pasted for convenience here, defined in IStakeManager
    // struct Executor{
    //     address addr;
    //     uint96 forEpoch;
    // }


    event Staked(address staker, uint amount);
    event Unstaked(address staker, uint amount);


    constructor(IOracle oracle) {
        _oracle = oracle;
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }


    function setAUTO(IERC777 AUTO) external {
        require(!_AUTOSet, "SM: AUTO already set");
        _AUTOSet = true;
        _AUTO = AUTO;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function getOracle() external view override returns (IOracle) {
        return _oracle;
    }

    function getAUTOAddr() external view override returns (address) {
        return address(_AUTO);
    }

    function getTotalStaked() external view override returns (uint) {
        return _totalStaked;
    }

    function getStake(address staker) external view override returns (uint) {
        return _stakerToStakedAmount[staker];
    }

    function getStakes() external view override returns (address[] memory) {
        return _stakes;
    }

    function getStakesLength() external view override returns (uint) {
        return _stakes.length;
    }

    function getStakesSlice(uint startIdx, uint endIdx) external view override returns (address[] memory) {
        address[] memory slice = new address[](endIdx - startIdx);
        uint sliceIdx = 0;
        for (uint stakeIdx = startIdx; stakeIdx < endIdx; stakeIdx++) {
            slice[sliceIdx] = _stakes[stakeIdx];
            sliceIdx++;
        }

        return slice;
    }

    function getCurEpoch() public view override returns (uint96) {
        return uint96((block.number / BLOCKS_IN_EPOCH) * BLOCKS_IN_EPOCH);
    }

    function getExecutor() external view override returns (Executor memory) {
        return _executor;
    }

    function isCurExec(address addr) external view override returns (bool) {
        // So that the storage is only loaded once
        Executor memory ex = _executor;
        if (ex.forEpoch == getCurEpoch()) {
            if (ex.addr == addr) {
                return true;
            } else {
                return false;
            }
        }
        // If there're no stakes, allow anyone to be the executor so that a random
        // person can bootstrap the network and nobody needs to be sent any coins
        if (_stakes.length == 0) { return true; }

        return false;
    }

    function getUpdatedExecRes() public view override returns (uint96 epoch, uint randNum, uint idxOfExecutor, address exec) {
        epoch = getCurEpoch();
        // So that the storage is only loaded once
        uint stakesLen = _stakes.length;
        // If the executor is out of date and the system already has stake,
        // choose a new executor. This will do nothing if the system is starting
        // and allow someone to stake without needing there to already be existing stakes
        if (_executor.forEpoch != epoch && stakesLen > 0) {
            // -1 because blockhash(seed) in Oracle will return 0x00 if the
            // seed == this block's height
            randNum = _oracle.getRandNum(epoch - 1);
            idxOfExecutor = randNum % stakesLen;
            exec = _stakes[idxOfExecutor];
        }
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Staking                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function updateExecutor() external override nonReentrant noFish returns (uint, uint, uint, address) {
        return _updateExecutor();
    }

    function isUpdatedExec(address addr) external override nonReentrant noFish returns (bool) {
        // So that the storage is only loaded once
        Executor memory ex = _executor;
        if (ex.forEpoch == getCurEpoch()) {
            if (ex.addr == addr) {
                return true;
            } else {
                return false;
            }
        } else {
            (, , , address exec) = _updateExecutor();
            if (exec == addr) { return true; }
        }
        if (_stakes.length == 0) { return true; }

        return false;
    }

    // The 1st stake/unstake of an epoch shouldn't change the executor, otherwise
    // a staker could precalculate the effect of how much they stake in order to
    // game the staker selection algo
    function stake(uint numStakes) external nzUint(numStakes) nonReentrant updateExec noFish override {
        uint amount = numStakes * STAN_STAKE;
        _stakerToStakedAmount[msg.sender] += amount;
        // So that the storage is only loaded once
        IERC777 AUTO = _AUTO;

        // Deposit the coins
        uint balBefore = AUTO.balanceOf(address(this));
        AUTO.operatorSend(msg.sender, address(this), amount, "", _stakingIndicator);
        // This check is a bit unnecessary, but better to be paranoid than r3kt
        require(AUTO.balanceOf(address(this)) - balBefore == amount, "SM: transfer bal check failed");

        for (uint i; i < numStakes; i++) {
            _stakes.push(msg.sender);
        }

        _totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint[] calldata idxs) external nzUintArr(idxs) nonReentrant updateExec noFish override {
        uint amount = idxs.length * STAN_STAKE;
        require(amount <= _stakerToStakedAmount[msg.sender], "SM: not enough stake, peasant");

        for (uint i = 0; i < idxs.length; i++) {
            require(_stakes[idxs[i]] == msg.sender, "SM: idx is not you");
            require(idxs[i] < _stakes.length, "SM: idx out of bounds");
            // Update stakes by moving the last element to the
            // element we're wanting to delete (so it doesn't leave gaps, which is
            // necessary for the _updateExecutor algo)
            _stakes[idxs[i]] = _stakes[_stakes.length-1];
            _stakes.pop();
        }
        
        _stakerToStakedAmount[msg.sender] -= amount;
        _AUTO.send(msg.sender, amount, _stakingIndicator);
        _totalStaked -= amount;
        emit Unstaked(msg.sender, amount);
    }

    function _updateExecutor() private returns (uint96 epoch, uint randNum, uint idxOfExecutor, address exec) {
        (epoch, randNum, idxOfExecutor, exec) = getUpdatedExecRes();
        if (exec != _ADDR_0) {
            _executor = Executor(exec, epoch);
        }
    }

    modifier updateExec() {
        // Need to update executor at the start of stake/unstake as opposed to the
        // end of the fcns because otherwise, for the 1st stake/unstake tx in an
        // epoch, someone could influence the outcome of the executor by precalculating
        // the outcome based on how much they stake and unfairly making themselves the executor
        _updateExecutor();
        _;
    }

    // Ensure the contract is fully collateralised every time
    modifier noFish() {
        _;
        // >= because someone could send some tokens to this contract and disable it if it was ==
        require(_AUTO.balanceOf(address(this)) >= _totalStaked, "SM: something fishy here");
    }

    function tokensReceived(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external override {
        require(msg.sender == address(_AUTO), "SM: non-AUTO token");
        require(keccak256(_operatorData) == keccak256(_stakingIndicator), "SM: sending by mistake");
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

pragma solidity 0.8.6;


import "IOracle.sol";


/**
* @title    StakeManager
* @notice   A lightweight Proof of Stake contract that allows
*           staking of AUTO tokens. Instead of a miner winning
*           the ability to produce a block, the algorithm selects
*           a staker for a period of 100 blocks to be the executor.
*           the executor has the exclusive right to execute requests
*           in the Registry contract. The Registry checks with StakeManager
*           who is allowed to execute requests at any given time
* @author   Quantaf1re (James Key)
*/
interface IStakeManager {

    struct Executor{
        address addr;
        uint96 forEpoch;
    }


    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Getters                         //
    //                                                          //
    //////////////////////////////////////////////////////////////
    
    function getOracle() external view returns (IOracle);

    function getAUTOAddr() external view returns (address);

    function getTotalStaked() external view returns (uint);

    function getStake(address staker) external view returns (uint);

    /**
     * @notice  Returns the array of stakes. Every element in the array represents
     *          `STAN_STAKE` amount of AUTO tokens staked for that address. Addresses
     *          can be in the array arbitrarily many times
     */
    function getStakes() external view returns (address[] memory);

    /**
     * @notice  The length of `_stakes`, i.e. the total staked when multiplied by `STAN_STAKE`
     */
    function getStakesLength() external view returns (uint);

    /**
     * @notice  The same as getStakes except it returns only part of the array - the
     *          array might grow so large that retrieving it costs more gas than the
     *          block gas limit and therefore brick the contract. E.g. for an array of
     *          x = [4, 5, 6, 7], x[1, 2] returns [5], the same as lists in Python
     * @param startIdx  [uint] The starting index from which to start getting the slice (inclusive)
     * @param endIdx    [uint] The ending index from which to start getting the slice (exclusive)
     */
    function getStakesSlice(uint startIdx, uint endIdx) external view returns (address[] memory);

    /**
     * @notice  Returns the current epoch. Goes in increments of 100. E.g. the epoch
     *          for 420 is 400, and 42069 is 42000
     */
    function getCurEpoch() external view returns (uint96);

    /**
     * @notice  Returns the currently stored Executor - which might be old,
     *          i.e. for a previous epoch
     */
    function getExecutor() external view returns (Executor memory);

    /**
     * @notice  Returns whether `addr` is the current executor for this epoch. If the executor
     *          is outdated (i.e. for a previous epoch), it'll return false regardless of `addr`
     * @param addr  [address] The address to check
     * @return  [bool] Whether or not `addr` is the current executor for this epoch
     */
    function isCurExec(address addr) external view returns (bool);

    /**
     * @notice  Returns what the result of updating the executor would be, but doesn't actually
     *          make any changes
     * @return epoch    Returns the relevant variables for determining the new executor if the executor
     *          can be updated currently. It can only be updated currently if the stored executor
     *          is for a previous epoch, and there is some stake in the system. If the executor
     *          can't be updated currently, then everything execpt `epoch` will return 0
     */
    function getUpdatedExecRes() external view returns (uint96 epoch, uint randNum, uint idxOfExecutor, address exec);

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Staking                         //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Updates the executor. Calls `getUpdatedExecRes` to know. Makes the changes
     *          only if the executor can be updated
     * @return  Returns the relevant variables for determining the new executor if the executor
     *          can be updated currently
     */
    function updateExecutor() external returns (uint, uint, uint, address);

    /**
     * @notice  Checks if the stored executor is for the current epoch - if it is,
     *          then it returns whether `addr` is the current exec or not. If the epoch
     *          is old, then it updates the executor, then returns whether `addr` is the
     *          current executor or not. If there's no stake in the system, returns true
     * @param addr  [address] The address to check
     * @return  [bool] Returns whether or not `addr` is the current, updated executor
     */
    function isUpdatedExec(address addr) external returns (bool);

    /**
     * @notice  Stake a set amount of AUTO tokens. A set amount of tokens needs to be used
     *          so that a random number can be used to look up a specific index in the array.
     *          We want the staker to be chosen proportional to their stake, which requires
     *          knowing their stake in relation to everyone else. If you could stake any
     *          amount of AUTO tokens, then the contract would have to store that amount
     *          along with the staker and, crucially, would require iteration over the
     *          whole array. E.g. if the random number in this PoS system was 0.2, then
     *          you could calculate the amount of proportional stake that translates to.
     *          If the total stakes was 10^6, then whichever staker in the array at token
     *          position 200,000 would be the winner, but that requires going through every
     *          piece of staking info in the first part of the array in order to calculate
     *          the running cumulative and know who happens to have the slot where the
     *          cumulative stake is 200,000. This has problems when the staking array is
     *          so large that it costs more than the block gas limit to iterate over, which
     *          would brick the contract, but also just generally costs alot of gas. Having
     *          a set amount of AUTO tokens means you already know everything about every
     *          element in the array therefore don't need to iterate over it.
     *          Calling this will add the caller to the array. Calling this will first try
     *          and set the executor so that the caller can't precalculate and affect the outcome
     *          by deciding the size of `numStakes`
     * @param numStakes  [uint] The number of `STAN_STAKE` to stake and therefore how many
     *          slots in the array to add the user to
     */
    function stake(uint numStakes) external;

    /**
     * @notice  Unstake AUTO tokens. Calling this will first try and set the executor so that
     *          the caller can't precalculate and affect the outcome by deciding the size of
     *          `numStakes`
     * @dev     Instead of just deleting the array slot, this takes the last element, copies
     *          it to the slot being unstaked, and pops off the original copy of the replacement
     *          from the end of the array, so that there are no gaps left, such that 0x00...00
     *          can never be chosen as an executor
     * @param idxs  [uint[]] The indices of the user's slots, in order of which they'll be
     *              removed, which is not necessariy the current indices. E.g. if the `_staking`
     *              array is [a, b, c, b], and `idxs` = [1, 3], then i=1 will first get
     *              replaced by i=3 and look like [a, b, c], then it would try and replace i=3
     *              by the end of the array...but i=3 no longer exists, so it'll revert. In this
     *              case, `idxs` would need to be [1, 1], which would result in [a, c]. It's
     *              recommended to choose idxs in descending order so that you don't have to
     *              take account of this behaviour - that way you can just use indexes
     *              as they are already without alterations
     */
    function unstake(uint[] calldata idxs) external;
}

pragma solidity 0.8.6;


import "IPriceOracle.sol";


interface IOracle {
    // Needs to output the same number for the whole epoch
    function getRandNum(uint salt) external view returns (uint);

    function getPriceOracle() external view returns (IPriceOracle);

    function getAUTOPerETH() external view returns (uint);

    function getGasPriceFast() external view returns (uint);

    function setPriceOracle(IPriceOracle newPriceOracle) external;

    function defaultPayIsAUTO() external view returns (bool);

    function setDefaultPayIsAUTO(bool newDefaultPayIsAUTO) external;
}

pragma solidity 0.8.6;


interface IPriceOracle {

    function getAUTOPerETH() external view returns (uint);

    function getGasPriceFast() external view returns (uint);
}

pragma solidity 0.8.6;


/**
* @title    Shared contract
* @notice   Holds constants and modifiers that are used in multiple contracts
* @dev      It would be nice if this could be a library, but modifiers can't be exported :(
* @author   Quantaf1re (James Key)
*/
abstract contract Shared {
    address constant internal _ADDR_0 = address(0);
    uint constant internal _E_18 = 10**18;


    /// @dev    Checks that a uint isn't nonzero/empty
    modifier nzUint(uint u) {
        require(u != 0, "Shared: uint input is empty");
        _;
    }

    /// @dev    Checks that a uint array isn't nonzero/empty
    modifier nzUintArr(uint[] calldata arr) {
        require(arr.length > 0, "Shared: uint arr input is empty");
        _;
    }
}