// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {Ownable} from "../lib/Ownable.sol";
import {SafeMath} from "../lib/SafeMath.sol";
import {SafeERC20} from "../lib/SafeERC20.sol";

import {IERC20} from "../token/IERC20.sol";

contract WaitlistBatch is Ownable {

    /* ========== Types ========== */

    struct Batch {
        uint256 totalSpots;
        uint256 filledSpots;
        uint256 batchStartTimestamp;
        uint256 depositAmount;
        bool claimable;
    }

    struct UserBatchInfo {
        bool hasParticipated;
        uint256 batchNumber;
        uint256 depositAmount;
    }

    /* ========== Variables ========== */

    address public moderator;

    IERC20 public depositCurrency;

    uint256 public nextBatchNumber;

    mapping (uint256 => mapping (address => uint256)) public userDepositMapping;

    mapping (uint256 => Batch) public batchMapping;

    mapping (address => uint256) public userBatchMapping;

    mapping (address => bool) public blacklist;

    /* ========== Events ========== */

    event AppliedToBatch(
        address indexed user,
        uint256 batchNumber,
        uint256 amount
    );

    event NewBatchAdded(
        uint256 totalSpots,
        uint256 batchStartTimestamp,
        uint256 depositAmount,
        uint256 batchNumber
    );

    event BatchTimestampChanged(
        uint256 batchNumber,
        uint256 batchStartTimstamp
    );

    event BatchTotalSpotsUpdated(
        uint256 batchNumber,
        uint256 newTotalSpots
    );

    event BatchClaimsEnabled(
        uint256[] batchNumbers
    );

    event TokensReclaimed(
        address user,
        uint256 amount
    );

    event TokensReclaimedBlacklist(
        address user,
        uint256 amount
    );

    event TokensTransfered(
        address tokenAddress,
        uint256 amount,
        address destination
    );

    event RemovedFromBlacklist(
        address user
    );

    event AddedToBlacklist(
        address user
    );

    event ModeratorSet(
        address user
    );

    /* ========== Modifiers ========== */

    modifier onlyModerator() {
        require(
            msg.sender == moderator,
            "WaitlistBatch: caller is not moderator"
        );
        _;
    }

    /* ========== Constructor ========== */

    constructor(address _depositCurrency) public {
        depositCurrency = IERC20(_depositCurrency);

        // Set the next batch number to 1 to avoid some complications
        // caused by batch number 0
        nextBatchNumber = 1;
    }

    /* ========== Public Getters ========== */

    function getBatchInfoForUser(
        address _user
    )
        public
        view
        returns (UserBatchInfo memory)
    {
        uint256 participatingBatch = userBatchMapping[_user];

        return UserBatchInfo({
            hasParticipated: participatingBatch > 0,
            batchNumber: participatingBatch,
            depositAmount: userDepositMapping[participatingBatch][_user]
        });
    }

    function getTotalNumberOfBatches()
        public
        view
        returns (uint256)
    {
        return nextBatchNumber - 1;
    }

    /* ========== Public Functions ========== */

    function applyToBatch(
        uint256 _batchNumber
    )
        public
    {
        require(
            _batchNumber > 0 && _batchNumber < nextBatchNumber,
            "WaitlistBatch: batch does not exist"
        );

        // Check if user already applied to a batch
        UserBatchInfo memory batchInfo = getBatchInfoForUser(msg.sender);
        require(
            !batchInfo.hasParticipated,
            "WaitlistBatch: cannot apply to more than one batch"
        );

        Batch storage batch = batchMapping[_batchNumber];

        require(
            batch.filledSpots < batch.totalSpots,
            "WaitlistBatch: batch is filled"
        );

        require(
            currentTimestamp() >= batch.batchStartTimestamp,
            "WaitlistBatch: cannot apply before the start time"
        );

        batch.filledSpots++;

        userDepositMapping[_batchNumber][msg.sender] = batch.depositAmount;
        userBatchMapping[msg.sender] = _batchNumber;

        SafeERC20.safeTransferFrom(
            depositCurrency,
            msg.sender,
            address(this),
            batch.depositAmount
        );

        emit AppliedToBatch(
            msg.sender,
            _batchNumber,
            batch.depositAmount
        );
    }

    function reclaimTokens()
        public
    {
        UserBatchInfo memory batchInfo = getBatchInfoForUser(msg.sender);

        require(
            batchInfo.hasParticipated,
            "WaitlistBatch: user did not participate in a batch"
        );

        require(
            batchInfo.depositAmount > 0,
            "WaitlistBatch: there are no tokens to reclaim"
        );

        Batch memory batch = batchMapping[batchInfo.batchNumber];

        require(
            batch.claimable,
            "WaitlistBatch: the tokens are not yet claimable"
        );

        userDepositMapping[batchInfo.batchNumber][msg.sender] -= batchInfo.depositAmount;

        SafeERC20.safeTransfer(
            depositCurrency,
            msg.sender,
            batchInfo.depositAmount
        );

        if (blacklist[msg.sender] == true) {
            emit TokensReclaimedBlacklist(
                msg.sender,
                batchInfo.depositAmount
            );
        } else {
            emit TokensReclaimed(
                msg.sender,
                batchInfo.depositAmount
            );
        }
    }

    /* ========== Admin Functions ========== */

    /**
     * @dev Adds a new batch to the `batchMapping` and increases the
     *      count of `totalNumberOfBatches`
     */
    function addNewBatch(
        uint256 _totalSpots,
        uint256 _batchStartTimestamp,
        uint256 _depositAmount
    )
        public
        onlyOwner
    {
        require(
            _batchStartTimestamp >= currentTimestamp(),
            "WaitlistBatch: batch start time cannot be in the past"
        );

        require(
            _depositAmount > 0,
            "WaitlistBatch: deposit amount cannot be 0"
        );

        require(
            _totalSpots > 0,
            "WaitlistBatch: batch cannot have 0 spots"
        );

        Batch memory batch = Batch(
            _totalSpots,
            0,
            _batchStartTimestamp,
            _depositAmount,
            false
        );

        batchMapping[nextBatchNumber] = batch;
        nextBatchNumber = nextBatchNumber + 1;

        emit NewBatchAdded(
            _totalSpots,
            _batchStartTimestamp,
            _depositAmount,
            nextBatchNumber - 1
        );
    }

    function changeBatchStartTimestamp(
        uint256 _batchNumber,
        uint256 _newStartTimestamp
    )
        public
        onlyOwner
    {
        require(
            _batchNumber > 0 && _batchNumber < nextBatchNumber,
            "WaitlistBatch: batch does not exit"
        );

        require(
            _newStartTimestamp >= currentTimestamp(),
            "WaitlistBatch: batch start time cannot be in the past"
        );

        Batch storage batch = batchMapping[_batchNumber];
        batch.batchStartTimestamp = _newStartTimestamp;

        emit BatchTimestampChanged(
            _batchNumber,
            _newStartTimestamp
        );
    }

    function changeBatchTotalSpots(
        uint256 _batchNumber,
        uint256 _newSpots
    )
        public
        onlyOwner
    {
        require(
            _batchNumber > 0 && _batchNumber < nextBatchNumber,
            "WaitlistBatch: the batch does not exist"
        );

        Batch storage batch = batchMapping[_batchNumber];

        require(
            currentTimestamp() < batch.batchStartTimestamp,
            "WaitlistBatch: the batch start date already passed"
        );

        require(
            batch.totalSpots < _newSpots,
            "WaitlistBatch: cannot change total spots to a smaller or equal number"
        );

        batch.totalSpots = _newSpots;

        emit BatchTotalSpotsUpdated(
            _batchNumber,
            _newSpots
        );
    }

    function enableClaims(
        uint256[] memory _batchNumbers
    )
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _batchNumbers.length; i++) {
            uint256 batchNumber = _batchNumbers[i];

            require(
                batchNumber > 0 && batchNumber < nextBatchNumber,
                "WaitlistBatch: the batch does not exist"
            );

            Batch storage batch = batchMapping[batchNumber];

            require(
                batch.claimable == false,
                "WaitlistBatch: batch has already claimable tokens"
            );

            batch.claimable = true;
        }

        emit BatchClaimsEnabled(_batchNumbers);
    }

    function transferTokens(
        address _tokenAddress,
        uint256 _amount,
        address _destination
    )
        public
        onlyOwner
    {
        SafeERC20.safeTransfer(
            IERC20(_tokenAddress),
            _destination,
            _amount
        );

        emit TokensTransfered(
            _tokenAddress,
            _amount,
            _destination
        );
    }

    function setModerator(
        address _user
    )
        public
        onlyOwner
    {
        moderator = _user;

        emit ModeratorSet(_user);
    }

    /* ========== Moderator Functions ========== */

    function addToBlacklist(
        address _user
    )
        public
        onlyModerator
    {
        blacklist[_user] = true;

        emit AddedToBlacklist(_user);
    }

    function removeFromBlacklist(
        address _user
    )
        public
        onlyModerator
    {
        blacklist[_user] = false;

        emit RemovedFromBlacklist(_user);
    }

    /* ========== Dev Functions ========== */

    function currentTimestamp()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.5.16;

import {IERC20} from "../token/IERC20.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library SafeERC20 {
    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        /* solium-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        /* solium-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        /* solium-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(
                0x23b872dd,
                from,
                to,
                value
            )
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TRANSFER_FROM_FAILED"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    )
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        external
        returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

{
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}