// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICVNX.sol";
import "./ICVNXStake.sol";

/// @notice CVNX token contract.
contract CVNXStake is ICVNXStake, Ownable {
    /// @notice Emit when token staked.
    event Staked(uint256 indexed amount, address accountAddress);
    /// @notice Emit when token unstaked.
    event Unstaked(uint256 indexed amount, address accountAddress, uint256 indexed timestamp);

    /// @notice CVNX token address.
    ICVNX public cvnxToken;

    mapping(address => Stake[]) accountToStakes;
    mapping(address => uint256) accountToStaked;

    /// @notice Governance contract created in constructor.
    constructor(address _cvnxToken) {
        cvnxToken = ICVNX(_cvnxToken);
    }

    /// @notice Stake (lock) tokens for period.
    /// @param _amount Token amount
    /// @param _address Token holder address
    /// @param _endTimestamp End  of lock period (seconds)
    function stake(uint256 _amount, address _address, uint256 _endTimestamp) external override onlyOwner {
        require(_amount > 0, "[E-57] - Amount can't be a zero.");
        require(_endTimestamp > block.timestamp, "[E-58] - End timestamp should be more than current timestamp.");
        require(_address != address(0), "[E-59] - Zero address.");

        uint256 _accountToStaked = accountToStaked[_address];

        Stake memory _stake = Stake(_amount, _endTimestamp);

        cvnxToken.transferFrom(_address, address(this), _amount);

        accountToStaked[_address] = _accountToStaked + _amount;
        accountToStakes[_address].push(_stake);

        emit Staked(_amount, _address);
    }

    /// @notice Unstake (unlock) all available for unlock tokens.
    function unstake() external override {
        uint256 _accountToStaked = accountToStaked[msg.sender];
        uint256 _unavailableToUnstake;

        for (uint256 i = 0; i < accountToStakes[msg.sender].length; i++) {
            if (accountToStakes[msg.sender][i].endTimestamp > block.timestamp) {
                _unavailableToUnstake += accountToStakes[msg.sender][i].amount;
            }
        }

        uint256 _toUnstake = _accountToStaked - _unavailableToUnstake;

        require(_toUnstake > 0, "[E-46] - Nothing to unstake.");

        accountToStaked[msg.sender] -= _toUnstake;
        cvnxToken.transfer(msg.sender, _toUnstake);

        emit Unstaked(_toUnstake, msg.sender, block.timestamp);
    }

    /// @notice Return list of stakes for address.
    /// @param _address Token holder address
    function getStakesList(address _address) external view override onlyOwner returns(Stake[] memory stakes) {
        return accountToStakes[_address];
    }

    /// @notice Return total stake amount for address.
    /// @param _address Token holder address
    function getStakedAmount(address _address) external view override returns(uint256) {
        return accountToStaked[_address];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

/// @notice ICVNXStake interface for CVNXStake contract.
interface ICVNXStake {
    struct Stake {
        uint256 amount;
        uint256 endTimestamp;
    }

    /// @notice Stake (lock) tokens for period.
    /// @param _amount Token amount
    /// @param _address Token holder address
    /// @param _endTimestamp End  of lock period (seconds)
    function stake(uint256 _amount, address _address, uint256 _endTimestamp) external;

    /// @notice Unstake (unlock) all available for unlock tokens.
    function unstake() external;

    /// @notice Return list of stakes for address.
    /// @param _address Token holder address
    function getStakesList(address _address) external view returns(Stake[] memory stakes);

    /// @notice Return total stake amount for address.
    /// @param _address Token holder address
    function getStakedAmount(address _address) external view returns(uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice ICVNX interface for CVNX contract.
interface ICVNX is IERC20 {
    /// @notice Mint new CVNX tokens.
    /// @param _account Address that receive tokens
    /// @param _amount Tokens amount
    function mint(address _account, uint256 _amount) external;

    /// @notice Lock tokens on holder balance.
    /// @param _tokenOwner Token holder
    /// @param _tokenAmount Amount to lock
    function lock(address _tokenOwner, uint256 _tokenAmount) external;

    /// @notice Unlock tokens on holder balance.
    /// @param _tokenOwner Token holder
    /// @param _tokenAmount Amount to lock
    function unlock(address _tokenOwner, uint256 _tokenAmount) external;

    /// @notice Swap CVN to CVNX tokens
    /// @param _amount Token amount to swap
    function swap(uint256 _amount) external returns (bool);

    /// @notice Transfer stuck tokens
    /// @param _token Token contract address
    /// @param _to Receiver address
    /// @param _amount Token amount
    function transferStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;

    /// @notice Set CVNXGovernance contract.
    /// @param _address CVNXGovernance contract address
    function setCvnxGovernanceContract(address _address) external;

    /// @notice Set limit params.
    /// @param _percent Percentage of the total balance available for transfer
    /// @param _limitAmount Max amount available for transfer
    /// @param _period Lock period when user can't transfer tokens
    function setLimit(uint256 _percent, uint256 _limitAmount, uint256 _period) external;

    /// @notice Add address to 'from' whitelist
    /// @param _newAddress New address
    function addFromWhitelist(address _newAddress) external;

    /// @notice Remove address from 'from' whitelist
    /// @param _oldAddress Old address
    function removeFromWhitelist(address _oldAddress) external;

    /// @notice Add address to 'to' whitelist
    /// @param _newAddress New address
    function addToWhitelist(address _newAddress) external;

    /// @notice Remove address from 'to' whitelist
    /// @param _oldAddress Old address
    function removeToWhitelist(address _oldAddress) external;

    /// @notice Change limit activity status.
    function changeLimitActivityStatus() external;
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

