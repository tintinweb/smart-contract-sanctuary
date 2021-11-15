// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IPayrLink.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ETHFactory is Ownable {
    string public name;         // Factory Name

    struct TransactionInfo {
        uint256 id;             // Transaction ID
        address from;           // Address Which has sent
        bytes32 toHash;          // Hash of recipient's Address
        uint256 amount;         // Transaction amount
        uint256 timestamp;      // Transaction time
        uint8 status;           // Released or pending - 0: pending, 1: available, 2: finished, 3: Canceled
    }

    TransactionInfo[] public transactions;
    uint256 public currentId;

    mapping (address => uint256) private balances;              // Available balance which can be withdrawn
    mapping (address => uint256[]) private pendingFrom;         // Transaction IDs in escrow service from sender's address
    mapping (bytes32 => uint256[]) private pendingTo;            // Transaction IDs in escrow service to receipent's hash

    uint256 public poolId;                      // Pool id on PayrLink
    IPayrLink payrLink;
    uint256 public feePercent = 80;                         // 1 = 0.01 %

    event SendTransaction(address from, uint256 amount, uint256 timestamp);
    event ReleaseFund(address from, uint256 amount, uint256 timestamp);
    event GetFund(address from, uint256 amount, uint256 timestamp);
    event CancelTransaction(address from, uint256 amount, uint256 timestamp);
    event Deposit(address from, uint256 amount);
    event Withdraw(address to, uint256 amount);

    /**
        @notice Initialize ERC20 token and Factory name
        @param _name Factory name
        @param _payrlink Interface of PayrLink
     */
    constructor(string memory _name, IPayrLink _payrlink) {
        name = _name;
        payrLink = _payrlink;
    }

    /**
        @notice Get balance of sender
     */
    function balanceOf() external view returns(uint256) {
        return balances[msg.sender];
    }

    function pendingFromIds() external view returns (uint256[] memory) {
        return pendingFrom[msg.sender];
    }

    function pendingToIds() external view returns (uint256[] memory) {
        bytes32 toHash = keccak256(abi.encodePacked(msg.sender));
        return pendingTo[toHash];
    }

    function updateFeePercent(uint256 _feePercent) external onlyOwner {
        feePercent = _feePercent;
    }

    /**
        @notice Deposit ETH to the contract
     */
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
        @notice Update pool id of PayrLink
        @param _pid New pool id
     */
    function updatePoolId (uint256 _pid) external onlyOwner {
        poolId = _pid;
    }

    /**
        @notice Withdraw ETH from the contract
        @param amount ETH amount to withdraw
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Withdraw amount exceed");
        address payable receipient = payable(msg.sender);
        balances[msg.sender] -= amount;
        receipient.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    /**
        @notice Send ETH to a receipient's address(hashed) via Escrow service
        @param _toHash Hash of the receipient's address
        @param _amount ETH amount to send
     */
    function send(bytes32 _toHash, uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "Withdraw amount exceed");
        balances[msg.sender] -= _amount;

        transactions.push(TransactionInfo(currentId, msg.sender, _toHash, _amount, block.timestamp, 0));
        pendingFrom[msg.sender].push(currentId);
        pendingTo[_toHash].push(currentId);

        currentId ++;
        emit SendTransaction(msg.sender, _amount, block.timestamp);
    }

    /**
        @notice Release the fund of an Escrow transaction, will be called by sender
        @param _id Transaction ID
     */
    function release(uint256 _id) external {
        require(transactions[_id].from == msg.sender && transactions[_id].status < 1, "Invalid owner");
        transactions[_id].status = 1;
        emit ReleaseFund(transactions[_id].from, transactions[_id].amount, transactions[_id].timestamp);
    }

    function removeFromPending(uint256 _id) internal {
        address sender = transactions[_id].from;
        bytes32 toHash = transactions[_id].toHash;
        // Remove transaction id from pendingFrom array
        uint256 pendingLen = pendingFrom[sender].length;
        for (uint256 i = 0 ; i < pendingLen ; i ++) {
            if (pendingFrom[sender][i] == _id) {
                pendingFrom[sender][i] = pendingFrom[sender][pendingLen - 1];
                pendingFrom[sender].pop();
                break;
            }
        }

        // Remove transaction id from pendingTo array
        pendingLen = pendingTo[toHash].length;
        for (uint256 i = 0 ; i < pendingLen ; i ++) {
            if (pendingTo[toHash][i] == _id) {
                pendingTo[toHash][i] = pendingTo[toHash][pendingLen - 1];
                pendingTo[toHash].pop();
                break;
            }
        }
    }

    /**
        @notice Get the fund which has been available in Escrow, will be called by receipient
        @param _id Transaction ID
     */
    function getFund(uint256 _id) external {
        bytes32 toHash = keccak256(abi.encodePacked(msg.sender));

        require(transactions[_id].toHash == toHash, "Invalid receipient");
        require(transactions[_id].status == 1, "Funds are not released");

        transactions[_id].status = 2;

        removeFromPending(_id);

        uint256 fee = transactions[_id].amount * feePercent / 10000;
        payable(address(payrLink)).transfer(fee);
        payrLink.addReward(poolId, fee);

        balances[msg.sender] += transactions[_id].amount - fee;

        emit GetFund(transactions[_id].from, transactions[_id].amount, transactions[_id].timestamp);
    }

    function cancel(uint256 _id) external {
        bytes32 toHash = keccak256(abi.encodePacked(msg.sender));

        require(transactions[_id].toHash == toHash, "Invalid receipient");
        require(transactions[_id].status == 0, "Funds are not pending");

        transactions[_id].status = 3;      // canceled

        removeFromPending(_id);

        balances[transactions[_id].from] += transactions[_id].amount;

        emit CancelTransaction(transactions[_id].from, transactions[_id].amount, transactions[_id].timestamp);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPayrLink {
    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many PAYR the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 poolToken;               // Address of ERC20 token contract. ETH is 0x0
        address factory;                // Address of Factory
        uint256 totalReward;            // Total reward of the pool
        uint256 accERC20PerShare;       // Accumulated ERC20s per share, times 1e36.
        uint256 totalDeposited;         // Total deposited PAYR to the pool
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    function poolLength() external view returns (uint256);
    function addReward (uint256 _pid, uint256 _amount) external;
    function deposited(uint256 _pid, address _user) external view returns (uint256);
    function pending(uint256 _pid, address _user) external view returns (uint256);
    function massUpdatePools() external;
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;

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
    constructor () {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

