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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
        return msg.data;
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IStake.sol";

contract Stake is Ownable, IStake {
    /// @notice Token amount staked on contract
    uint256 public totalStaked;
    /// @notice Token amount of reward pool
    uint256 public totalSupply;
    /// @notice Mapping of user adress to amount of staked tokens
    mapping(address => uint256) public usersStaked;
    /// @notice Deadline of stake period
    uint64 public stakeDeadline;
    /// @notice Deadline of lock period
    uint64 public lockDeadline;
    /// @notice Token that stake in contract
    IERC20 public token;

    /// @notice Check that time of period isn't out
    /// @param _deadline deadline of period
    modifier beforePeriodDeadline(uint256 _deadline) {
        require(block.timestamp <= _deadline, "[E-20]: Unable to exec during this time period");
        _;
    }

    /// @param _stakeDeadline deadline of the first(stake) period
    /// @param _lockDeadline deadline of the second period
    /// @param _tokenAddress address of token, that uses for stake
    constructor(
        uint64 _stakeDeadline,
        uint64 _lockDeadline,
        address _tokenAddress
    ) {
        require(_stakeDeadline < _lockDeadline, "Uncorrect timestamps");

        stakeDeadline = _stakeDeadline;
        lockDeadline = _lockDeadline;
        token = IERC20(_tokenAddress);
    }

    /// @notice function for stake tokens
    /// @param _amount amount of tokens to stake
    function stake(uint256 _amount) external override beforePeriodDeadline(stakeDeadline) {
        token.transferFrom(msg.sender, address(this), _amount);

        totalStaked += _amount;
        usersStaked[msg.sender] += _amount;
    }

    /// @notice fucntion for add tokens to reward pool
    /// @param _amount amount of tokens to add to reward pool
    function addSupply(uint256 _amount) external override beforePeriodDeadline(lockDeadline) {
        token.transferFrom(msg.sender, address(this), _amount);
        totalSupply += _amount;
    }

    /// @notice function to send reward and unstaked tokens to target account
    /// @param _target address to transfer reward and unstaked tokens
    function withdraw(address _target) external override {
        require(block.timestamp > lockDeadline, "[E-21]: Unable to exec during this time period");

        uint256 _senderStaked = usersStaked[_target];
        uint256 _reward = getWithdrawReward(_target);
        usersStaked[_target] = 0;


        totalSupply -= _reward;
        totalStaked -= _senderStaked;

        token.transfer(_target, _reward + _senderStaked);
    }

    /// @notice function to get mistakenly sent tokens from account
    /// @param _token IERC20 token, that will be send
    /// @param _to target address to send tokens
    /// @param _amount amount of tokens for send
    function transferOverTokens(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        if (address(_token) == address(token)) {
            uint256 _over = token.balanceOf(address(this)) - (totalStaked + totalSupply);

            if (_amount > _over) {
                _amount = _over;
            }

            token.transfer(_to, _amount);
        } else {
            _token.transfer(_to, _amount);
        }
    }

    /// @notice function for getting reward of user
    /// @param _target address of user
    /// @return value of reward
    function getWithdrawReward(address _target) public view returns (uint256) {
        return ((usersStaked[_target] * totalSupply) / totalStaked);
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStake {
    /// @notice function for stake tokens
    /// @param _amount amount of tokens to stake
    function stake(uint256 _amount) external;

    /// @notice fucntion for add tokens to reward pool
    /// @param _amount amount of tokens to add to reward pool
    function addSupply(uint256 _amount) external;

    /// @notice function to send reward and unstaked tokens to target account
    /// @param _target address to transfer reward and unstaked tokens
    function withdraw(address _target) external;

    /// @notice function to get mistakenly sent tokens from account
    /// @param _token IERC20 token, that will be send
    /// @param _to target address to send tokens
    /// @param _amount amount of tokens for send
    function transferOverTokens(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 10000
  },
  "evmVersion": "berlin",
  "libraries": {},
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