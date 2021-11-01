// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "BoringBatchable.sol";
import "BoringOwnable.sol";
import "IERC20.sol";
import "ISettV3.sol";
import "BoringERC20.sol";
import "PausableUpgradeable.sol";

// DIFFERENT RATES OF EMISSIONS PER BLOCK PER SETT

// NOTE: when adding a vault for the first time, if its lpSupply is zero but badgerPerBlock > 0, there are badgers lost till the lpSupply > 0

contract BadgerTreeV3 is BoringBatchable, BoringOwnable, PausableUpgradeable {
    using BoringERC20 for IERC20;

    /// @notice Info of each sett.
    struct SettInfo {
        uint64 lastRewardBlock; // the last block when the reward p were updated
        uint64 endingBlock; // ending timestamp for current reward cycle
        uint128[] accTokenPerShare; // number of tokens accumulated per share till lastRewardBlock
        uint128[] tokenPerBlock; // number of reward token per block
        address[] rewardTokens; // address of all the reward tokens
    }

    address public scheduler;
    address public pauser;

    /// @notice Info of each sett. settAddress => settInfo
    mapping(address => SettInfo) public settInfo;

    /// @notice rewardDebt of a user for a particular token in a sett. settAddress => userAddress => token => rewardDebt
    mapping(address => mapping(address => mapping(address => int256)))
        public rewardDebts;

    uint64 private constant PRECISION = 1e12;

    event Deposit(address indexed user, address indexed sett, uint256 amount);
    event Withdraw(address indexed user, address indexed sett, uint256 amount);
    event Transfer(
        address indexed from,
        address indexed to,
        address indexed sett,
        uint256 amount
    );
    event Claimed(
        address indexed user,
        address indexed token,
        address indexed sett,
        uint256 amount,
        uint256 timestamp,
        uint256 blockNumber
    );
    event SettAddition(address indexed settAddress, address[] rewardTokens);
    event RewardTokenAddition(address indexed settAddress, address reward);
    event NewRewardsCycle(
        address indexed settAddress,
        uint256 startBlock,
        uint256 endBlock,
        address[] rewards,
        uint128[] amounts
    );
    event UpdateSett(
        address indexed settAddress,
        uint64 lastRewardBlock,
        uint256 lpSupply,
        uint128[] accTokenPerShare
    );

    constructor(address _scheduler, address _pauser) {
        scheduler = _scheduler;
        pauser = _pauser;
    }

    /// @notice set the scheduler who will schedule the rewards
    function setScheduler(address _scheduler) external {
        _onlyScheduler();
        scheduler = _scheduler;
    }

    /// @notice set the pauser who will pause the rewards
    function setPauser(address _pauser) external {
        _onlyPauser();
        pauser = _pauser;
    }

    function pause() external {
        _onlyPauser();
        _pause();
    }

    function unpause() external {
        _onlyPauser();
        _unpause();
    }

    /// @notice add a new sett to the rewards contract
    /// @param _settAddress contract address of the sett
    /// @param _rewardTokens array of the other reward tokens excluding BADGER
    function add(address _settAddress, address[] memory _rewardTokens)
        public
        onlyOwner
    {
        settInfo[_settAddress] = SettInfo({
            lastRewardBlock: 0,
            accTokenPerShare: new uint128[](_rewardTokens.length),
            tokenPerBlock: new uint128[](_rewardTokens.length),
            endingBlock: 0,
            rewardTokens: _rewardTokens
        });

        emit SettAddition(_settAddress, _rewardTokens);
    }

    /// @notice add a new reward token to a particular sett
    /// @param _settAddress address of the sett for which to add a new reward token
    /// @param _reward address of the reward token to add
    function addRewardToken(address _settAddress, address _reward) public onlyOwner {
        SettInfo storage sett = settInfo[_settAddress];
        _cycleNotOver(sett.endingBlock);
        sett.rewardTokens.push(_reward);
        sett.accTokenPerShare.push(0);
        sett.tokenPerBlock.push(0);

        emit RewardTokenAddition(_settAddress, _reward);
    }

    /// @notice add the sett rewards for the current cycle
    /// @param _settAddress address of the vault for which to add rewards
    /// @param _blocks number of blocks for which this cycle should last
    /// @param _amounts array containing amount of each reward Token. _amounts[0] must be the badger amount. therefore _amounts.length = sett.rewardTokens.length + 1
    function addSettRewards(
        address _settAddress,
        uint64 _blocks,
        uint128[] memory _amounts
    ) external {
        _onlyScheduler();
        SettInfo storage sett = settInfo[_settAddress];
        _cycleNotOver(sett.endingBlock);
        updateSett(_settAddress);
        sett.lastRewardBlock = uint64(block.number);
        sett.endingBlock = sett.lastRewardBlock + _blocks;
        // set the total rewardTokens of this sett for current cycle
        // this is used later to calculate the tokenToBadger Ratio for claiming rewards
        for (uint256 i = 0; i < _amounts.length; i++) {
            sett.tokenPerBlock[i] = uint128(_amounts[i] / _blocks);
        }

        emit NewRewardsCycle(
            _settAddress,
            block.number,
            sett.endingBlock,
            sett.rewardTokens,
            _amounts
        );
    }

    /// @notice View function to see all pending rewards on frontend.
    /// @param _settAddress The contract address of the sett
    /// @param _user Address of user.
    /// @return pending amount of all rewards. allPending[0] will be the badger rewards. rest will be the rewards for other tokens
    function pendingRewards(address _settAddress, address _user)
        external
        view
        returns (uint256[] memory)
    {
        SettInfo memory sett = settInfo[_settAddress];
        uint256 n = sett.rewardTokens.length;
        uint256[] memory allPending = new uint256[](n);

        uint64 currBlock = uint64(block.number);
        if (block.number > sett.endingBlock) {
            // this will happen most probably when updateSett is called on addSettRewards
            currBlock = sett.endingBlock;
        }

        uint256 blocks = currBlock - sett.lastRewardBlock;
        uint256 lpSupply = IERC20(_settAddress).totalSupply();
        uint256 userBal = IERC20(_settAddress).balanceOf(_user);

        for (uint256 i = 0; i < n; i++) {
            int256 rewardDebt = rewardDebts[_settAddress][_user][
                sett.rewardTokens[i]
            ];
            uint256 accTokenPerShare = sett.accTokenPerShare[i];
            if (currBlock > sett.lastRewardBlock && lpSupply != 0) {
                uint256 tokenReward = blocks * sett.tokenPerBlock[i];
                accTokenPerShare =
                    accTokenPerShare +
                    ((tokenReward * PRECISION) / lpSupply);
            }
            int256 accumulatedToken = int256(
                (userBal * accTokenPerShare) / PRECISION
            );
            uint256 pendingToken = uint256(accumulatedToken - rewardDebt);

            allPending[i] = pendingToken;
        }

        return allPending;
    }

    /// @notice Update reward variables of the given sett.
    /// @param _settAddress The address of the set
    /// @return sett Returns the sett that was updated.
    function updateSett(address _settAddress)
        public
        returns (SettInfo memory sett)
    {
        sett = settInfo[_settAddress];
        uint64 currBlock = uint64(block.number);
        if (block.number > sett.endingBlock) {
            // this will happen most probably when updateSett is called on addSettRewards
            currBlock = sett.endingBlock;
        }
        if (currBlock > sett.lastRewardBlock) {
            uint256 lpSupply = IERC20(_settAddress).totalSupply();
            if (lpSupply > 0) {
                uint256 blocks = currBlock - sett.lastRewardBlock;
                for (uint256 i = 0; i < sett.rewardTokens.length; i++) {
                    uint256 tokenReward = blocks * sett.tokenPerBlock[i];
                    sett.accTokenPerShare[i] += uint128(
                        (tokenReward * PRECISION) / lpSupply
                    );
                }
            }
            sett.lastRewardBlock = currBlock;
            settInfo[_settAddress] = sett;
            emit UpdateSett(
                _settAddress,
                sett.lastRewardBlock,
                lpSupply,
                sett.accTokenPerShare
            );
        }
    }

    // should be called only by vault
    // well can be called by anyone tbh but doesn't make sense if anybody else calls it
    function notifyTransfer(
        uint256 _amount,
        address _from,
        address _to
    ) public {
        SettInfo memory sett = settInfo[msg.sender];

        uint256 t = sett.rewardTokens.length;
        int128[] memory tokenDebts = new int128[](t);

        for (uint256 i = 0; i < t; i++) {
            tokenDebts[i] = int128(
                int256((_amount * sett.accTokenPerShare[i]) / PRECISION)
            );
        }

        if (_from == address(0)) {
            // notifyDeposit
            for (uint256 i = 0; i < t; i++) {
                rewardDebts[msg.sender][_to][
                    sett.rewardTokens[i]
                ] += tokenDebts[i];
            }

            emit Deposit(_to, msg.sender, _amount);
        } else if (_to == address(0)) {
            // notifyWithdraw
            for (uint256 i = 0; i < t; i++) {
                rewardDebts[msg.sender][_from][
                    sett.rewardTokens[i]
                ] -= tokenDebts[i];
            }

            emit Withdraw(_from, msg.sender, _amount);
        } else {
            // transfer between users
            for (uint256 i = 0; i < t; i++) {
                rewardDebts[msg.sender][_to][
                    sett.rewardTokens[i]
                ] += tokenDebts[i];
                rewardDebts[msg.sender][_from][
                    sett.rewardTokens[i]
                ] -= tokenDebts[i];
            }

            emit Transfer(_from, _to, msg.sender, _amount);
        }
    }

    /// @notice Harvest badger rewards for a vault sender to `to`
    /// @param _settAddress The address of the sett
    /// @param _to Receiver of BADGER rewards
    /// @param _rewardIndexes addresses of the reward tokens to claim
    function claim(
        address _settAddress,
        address _to,
        uint256[] memory _rewardIndexes
    ) public whenNotPaused {
        SettInfo memory sett = updateSett(_settAddress);
        uint256 userBal = IERC20(_settAddress).balanceOf(msg.sender);

        address reward;
        for (uint256 j = 0; j < _rewardIndexes.length; j++) {
            reward = sett.rewardTokens[_rewardIndexes[j]];
            int256 accumulatedToken = int256(
                (userBal * sett.accTokenPerShare[_rewardIndexes[j]]) / PRECISION
            );
            uint256 pendingToken = uint256(
                accumulatedToken - rewardDebts[_settAddress][msg.sender][reward]
            );

            // add it to reward Debt
            rewardDebts[_settAddress][msg.sender][reward] = accumulatedToken;

            // Interactions
            require(pendingToken != 0, "No pending rewards");
            IERC20(reward).safeTransfer(_to, pendingToken);

            emit Claimed(
                _to,
                reward,
                _settAddress,
                pendingToken,
                block.timestamp,
                block.number
            );
        }
    }

    /// @notice function to transfer any remaining tokens from the contract to the scheduler
    /// @param _tokens address of the tokens to transfer
    /// @param _amounts amounts of each token respectively
    function sweepDust( address[] memory _tokens, uint[] memory _amounts) external {
        _onlyScheduler();
        for (uint i =0; i < _tokens.length ; i ++) {
            IERC20(_tokens[i]).transfer(msg.sender, _amounts[i]);
        }
    }

    /// INTERNAL FUNCTIONS
    function _onlyScheduler() internal view {
        require(msg.sender == scheduler, "Not Scheduler");
    }

    function _onlyPauser() internal view {
        require(msg.sender == pauser, "Not Pauser");
    }

    function _cycleNotOver(uint64 _endingBlock) internal view {
        require(block.number > _endingBlock, "Rewards cycle not over");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// WARNING!!!
// Combining BoringBatchable with msg.value can cause double spending issues
// https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/

import "IERC20.sol";

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(
        address to,
        uint256 amount
    ) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISettV3 {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _shares) external;
    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while(i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }
    
    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    } 

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "ContextUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.9.0;

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
        require(
            _initializing || _isConstructor() || !_initialized,
            "Initializable: contract is already initialized"
        );

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}