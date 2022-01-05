// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// Interfaces
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVolmexReward.sol";
import "./interfaces/IVolmexToken.sol";

contract VolmexReward is Ownable {
    event Vested(address indexed beneficiary, uint256 time, uint256 value);
    event VestingEntryCreated(
        address indexed beneficiary,
        uint256 time,
        uint256 value,
        uint256 duration,
        uint256 entryID
    );
    event SetVolmexToken(address indexed volmexToken);

    IVolmexToken public volmexToken;

    mapping(address => mapping(uint256 => VestingEntries.VestingEntry))
        public vestingSchedules;

    mapping(address => uint256[]) internal accountVestingEntryIDs;

    /*Counter for new vesting entry ids. */
    uint256 public nextEntryId = 1;

    mapping(address => uint256) internal totalEscrowedAccountBalance;

    mapping(address => uint256) public totalVestedAccountBalance;

    uint256 public totalEscrowedBalance;

    /* Max escrow duration */
    uint256 public constant MAX_DURATION = 2 * 52 weeks; // Default max 2 years duration

    constructor(IVolmexToken _volmextoken) {
        volmexToken = _volmextoken;
    }

    /* ========== SETTER ========== */

    /**
     * @notice set the volmex contract address as we need to transfer VOL when the user vests
     */
    function setVolmexToken(IVolmexToken _volmextoken)
        external
        onlyOwner
    {
        volmexToken = _volmextoken;

        emit SetVolmexToken(address(volmexToken));
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice A simple alias to totalEscrowedAccountBalance: provides ERC20 balance integration.
     */
    function balanceOf(address account) public view returns (uint256) {
        return totalEscrowedAccountBalance[account];
    }

    /**
     * @notice The number of vesting dates in an account's schedule.
     */
    function totalVestingEntries(address account)
        external
        view
        returns (uint256)
    {
        return accountVestingEntryIDs[account].length;
    }

    /**
     * @notice Get the vesting detail of an account entryId.
     */
    function getVestingEntry(address account, uint256 entryID)
        external
        view
        returns (uint64 endTime, uint256 escrowAmount)
    {
        endTime = vestingSchedules[account][entryID].endTime;
        escrowAmount = vestingSchedules[account][entryID].escrowAmount;
    }

    /**
     * @notice Get the vesting schedule of an account.
     */
    function getVestingSchedules(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (VestingEntries.VestingEntryWithID[] memory) {
        uint256 endIndex = index + pageSize;

        // If index starts after the endIndex return no results
        if (endIndex <= index) {
            return new VestingEntries.VestingEntryWithID[](0);
        }

        // If the page extends past the end of the accountVestingEntryIDs, truncate it.
        if (endIndex > accountVestingEntryIDs[account].length) {
            endIndex = accountVestingEntryIDs[account].length;
        }

        uint256 n = endIndex - index;
        VestingEntries.VestingEntryWithID[]
            memory vestingEntries = new VestingEntries.VestingEntryWithID[](n);
        for (uint256 i; i < n; i++) {
            uint256 entryID = accountVestingEntryIDs[account][i + index];

            VestingEntries.VestingEntry memory entry = vestingSchedules[
                account
            ][entryID];

            vestingEntries[i] = VestingEntries.VestingEntryWithID({
                endTime: uint64(entry.endTime),
                escrowAmount: entry.escrowAmount,
                entryID: entryID
            });
        }
        return vestingEntries;
    }

    /**
     * @notice Get the vesting detail of an account entryIds.
     */
    function getAccountVestingEntryIDs(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (uint256[] memory) {
        uint256 endIndex = index + pageSize;

        // If the page extends past the end of the accountVestingEntryIDs, truncate it.
        if (endIndex > accountVestingEntryIDs[account].length) {
            endIndex = accountVestingEntryIDs[account].length;
        }
        if (endIndex <= index) {
            return new uint256[](0);
        }

        uint256 n = endIndex - index;
        uint256[] memory page = new uint256[](n);
        for (uint256 i; i < n; i++) {
            page[i] = accountVestingEntryIDs[account][i + index];
        }
        return page;
    }

    /**
     * @notice Get the vesting quantity of an account entryIds.
     */
    function getVestingQuantity(address account, uint256[] calldata entryIDs)
        external
        view
        returns (uint256 total)
    {
        for (uint256 i = 0; i < entryIDs.length; i++) {
            VestingEntries.VestingEntry memory entry = vestingSchedules[
                account
            ][entryIDs[i]];

            /* Skip entry if escrowAmount == 0 */
            if (entry.escrowAmount != 0) {
                uint256 quantity = _claimableAmount(entry);

                /* add quantity to total */
                total = total + quantity;
            }
        }
    }

    /**
     * @notice Get the vesting entry amount of an account entryId which is claimable.
     */
    function getVestingEntryClaimable(address account, uint256 entryID)
        external
        view
        returns (uint256)
    {
        VestingEntries.VestingEntry memory entry = vestingSchedules[account][
            entryID
        ];
        return _claimableAmount(entry);
    }

    /**
     * @return vesting entry amount of an account entryId which is claimable.
     */
    function _claimableAmount(VestingEntries.VestingEntry memory _entry)
        internal
        view
        returns (uint256)
    {
        uint256 quantity;
        if (_entry.escrowAmount != 0) {
            /* Escrow amounts claimable if block.timestamp equal to or after entry endTime */
            quantity = block.timestamp >= _entry.endTime
                ? _entry.escrowAmount
                : 0;
        }
        return quantity;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * Vest escrowed amounts that are claimable
     * Allows users to vest their vesting entries based on msg.sender
     */

    function vest(uint256[] calldata entryIDs) external {
        uint256 total;
        for (uint256 i = 0; i < entryIDs.length; i++) {
            VestingEntries.VestingEntry storage entry = vestingSchedules[
                msg.sender
            ][entryIDs[i]];

            /* Skip entry if escrowAmount == 0 already vested */
            if (entry.escrowAmount != 0) {
                uint256 quantity = _claimableAmount(entry);

                /* update entry to remove escrowAmount */
                if (quantity > 0) {
                    entry.escrowAmount = 0;
                }

                /* add quantity to total */
                total = total + quantity;
            }
        }

        /* Transfer vested tokens. Will revert if total > totalEscrowedAccountBalance */
        if (total != 0) {
            _transferVestedTokens(msg.sender, total);
        }
    }

    /**
     * @notice Add a new vesting entry at a given time and quantity to an account's schedule.
     * @dev A call to this should accompany a previous successful call to volmex.transfer(rewardEscrow, amount),
     * to ensure that when the funds are withdrawn, there is enough balance.
     * @param account The account to append a new vesting entry to.
     * @param quantity The quantity of VOL that will be escrowed.
     * @param duration The duration that VOL will be emitted.
     */
    function appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) external onlyOwner {
        _appendVestingEntry(account, quantity, duration);
    }

    /**
     * @notice Add a new vesting entry of multiple users in a batch at a given time and quantity to an account's schedule.
     * @dev A call to this should accompany a previous successful call to volmex.transfer(rewardEscrow, amount),
     * to ensure that when the funds are withdrawn, there is enough balance.
     * @param _recipients array of addresses of users to append a new batch entry
     * @param _quantities The quantity of VOL that will be escrowed.
     * @param _duration The duration that VOL will be emitted.
     */
    function appendBatchVestingEntry(
        address[] memory _recipients,
        uint256[] memory _quantities,
        uint256 _duration
    ) external onlyOwner {
        _appendBatchVestingEntry(_recipients, _quantities, _duration);
    }

    /* Transfer vested tokens and update totalEscrowedAccountBalance, totalVestedAccountBalance */
    function _transferVestedTokens(address _account, uint256 _amount) internal {
        _reduceAccountEscrowBalances(_account, _amount);
        totalVestedAccountBalance[_account] =
            totalVestedAccountBalance[_account] +
            _amount;
        IVolmexToken(volmexToken).transfer(_account, _amount);
        emit Vested(_account, block.timestamp, _amount);
    }

    function _reduceAccountEscrowBalances(address _account, uint256 _amount)
        internal
    {
        // Reverts if amount being vested is greater than the account's existing totalEscrowedAccountBalance
        totalEscrowedBalance = totalEscrowedBalance - _amount;
        totalEscrowedAccountBalance[_account] =
            totalEscrowedAccountBalance[_account] -
            _amount;
    }

    /* ========== INTERNALS ========== */

    function _appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) internal {
        /* No empty or already-passed vesting entries allowed. */
        require(
            duration > 0 && duration <= MAX_DURATION,
            "VolmexReward: Cannot escrow with 0 duration OR above MAX_DURATION"
        );

        /* The provided quantity should be greater than zero */
        require(
            quantity > 0,
            "VolmexReward: Quantity cannot be zero"
        );

        /* There must be enough balance in the contract to provide for the vesting entry. */
        totalEscrowedBalance = totalEscrowedBalance + quantity;
        require(
            totalEscrowedBalance <=
                IVolmexToken(volmexToken).balanceOf(address(this)),
            "VolmexReward: Must be enough balance in the contract to provide for the vesting entry"
        );
        /* Escrow the tokens for duration. */
        uint256 endTime = block.timestamp + duration;

        /* Add quantity to account's escrowed balance */
        totalEscrowedAccountBalance[account] =
            totalEscrowedAccountBalance[account] +
            quantity;

        uint256 entryID = nextEntryId;
        vestingSchedules[account][entryID] = VestingEntries.VestingEntry({
            endTime: uint64(endTime),
            escrowAmount: quantity
        });

        accountVestingEntryIDs[account].push(entryID);

        /* Increment the next entry id. */
        nextEntryId = nextEntryId + 1;

        emit VestingEntryCreated(
            account,
            block.timestamp,
            quantity,
            duration,
            entryID
        );
    }

    function _appendBatchVestingEntry(
        address[] memory _recipients,
        uint256[] memory _quantities,
        uint256 _duration
    ) internal {
        uint256 endTime = block.timestamp + _duration;
        require(
            _recipients.length == _quantities.length,
            "VolmexReward: Length of arrays of recepients, and quantities must be equal"
        );
        require(
            _duration > 0 && _duration <= MAX_DURATION,
            "VolmexReward: Cannot escrow with 0 duration OR above MAX_DURATION"
        );
        uint256 totalEscrow;
        for (uint256 j = 0; j < _recipients.length; j++) {
            require(
                _quantities[j] != 0,
                "VolmexReward: Quantity cannot be zero"
            );
            totalEscrow = totalEscrow + _quantities[j];
        }
        totalEscrowedBalance += totalEscrow;

        require(
            totalEscrowedBalance <=
                IVolmexToken(volmexToken).balanceOf(address(this)),
            "VolmexReward: Must be enough balance in the contract to provide for the vesting entry"
        );
        for (uint256 k = 0; k < _recipients.length; k++) {
            totalEscrowedAccountBalance[_recipients[k]] =
                totalEscrowedAccountBalance[_recipients[k]] +
                _quantities[k];

            uint256 entryID = nextEntryId;
            vestingSchedules[_recipients[k]][entryID] = VestingEntries
                .VestingEntry({
                    endTime: uint64(endTime),
                    escrowAmount: _quantities[k]
                });

            accountVestingEntryIDs[_recipients[k]].push(entryID);

            /* Increment the next entry id. */
            nextEntryId = nextEntryId + 1;

            emit VestingEntryCreated(
                _recipients[k],
                block.timestamp,
                _quantities[k],
                _duration,
                entryID
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import './IVolmexToken.sol';

library VestingEntries {
    struct VestingEntry {
        uint64 endTime;
        uint256 escrowAmount;
    }
    struct VestingEntryWithID {
        uint64 endTime;
        uint256 escrowAmount;
        uint256 entryID;
    }
}

interface IVolmexReward {
    // Views
    function balanceOf(address account) external view returns (uint);

    function totalVestingEntries(address account) external view returns (uint);

    function totalEscrowedAccountBalance(address account) external view returns (uint);

    function totalVestedAccountBalance(address account) external view returns (uint);

    function getVestingQuantity(address account, uint256[] calldata entryIDs) external view returns (uint);

    function getVestingSchedules(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (VestingEntries.VestingEntryWithID[] memory);

    function getAccountVestingEntryIDs(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (uint256[] memory);

    function getVestingEntryClaimable(address account, uint256 entryID) external view returns (uint);

    function getVestingEntry(address account, uint256 entryID) external view returns (uint64, uint256);

    // Mutative functions
    function vest(uint256[] calldata entryIDs) external;

    function appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) external;

    function setVolmexTokenAddress(IVolmexToken _volmextoken) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IVolmexToken {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}