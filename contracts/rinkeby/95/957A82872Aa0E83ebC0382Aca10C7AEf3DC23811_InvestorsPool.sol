// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

import "./TrustedContacts.sol";
import "./RecoverableErc20ByOwner.sol";
import "./interfaces/IInvestorsPool.sol";

contract InvestorsPool is
    IInvestorsPool,
    TrustedContacts,
    RecoverableErc20ByOwner
{
    struct State {
        uint128 totalStaked;
        uint128 historicalRewardRate;
    }

    struct Staker {
        uint256 amount;
        uint128 initialRewardRate;
        uint128 reward;
        uint256 claimedReward;
    }

    State public state;
    mapping(address => Staker) public stakers;

    address public immutable foundersPool;

    event Staked(address indexed owner, uint128 amount);
    event Rewarded(address indexed from, address indexed to, uint128 amount);
    event StakingBonusAccrued(address indexed staker, uint128 amount);

    constructor(address foundersPool_) {
        foundersPool = foundersPool_;
    }

    function stakeFrom(address owner, uint256 amount)
        external
        override
        onlyTrusted
    {
        _stakeFrom(owner, uint128(amount));
    }

    function _stakeFrom(address owner, uint128 amount) private {
        Staker storage staker = _updateStateAndStaker(owner);
        emit Staked(owner, amount);
        state.totalStaked += amount;
        staker.amount += amount;
    }

    function claimReward() external returns (uint256) {
        Staker storage staker = _updateStateAndStaker(_msgSender());
        assert(staker.reward >= staker.claimedReward);
        uint128 unclaimedReward = staker.reward - uint128(staker.claimedReward);
        _claimReward(staker, _msgSender(), _msgSender(), unclaimedReward);
        return unclaimedReward;
    }

    function claimRewardWithoutUpdate() external returns (uint256) {
        Staker storage staker = stakers[_msgSender()];
        assert(staker.reward >= staker.claimedReward);
        uint128 unclaimedReward = staker.reward - uint128(staker.claimedReward);
        _claimReward(staker, _msgSender(), _msgSender(), unclaimedReward);
        return unclaimedReward;
    }

    function _updateStateAndStaker(address stakerAddress)
        private
        returns (Staker storage staker)
    {
        _updateHistoricalRewardRate(0);
        staker = stakers[stakerAddress];

        uint128 unrewarded = uint128(
            ((state.historicalRewardRate - staker.initialRewardRate) *
                staker.amount) >> 40
        );
        emit StakingBonusAccrued(stakerAddress, unrewarded);

        staker.initialRewardRate = state.historicalRewardRate;
        staker.reward += unrewarded;
    }

    function _claimReward(
        Staker storage staker,
        address from,
        address to,
        uint128 amount
    ) private {
        assert(staker.reward >= staker.claimedReward);
        uint128 unclaimedReward = staker.reward - uint128(staker.claimedReward);
        require(amount <= unclaimedReward, "InvestorsPool: insufficient funds");
        emit Rewarded(from, to, amount);
        staker.claimedReward += amount;
        _sendEth(to, amount);
    }

    function getReward() external returns (uint256 unclaimedReward) {
        Staker memory staker = _updateStateAndStaker(_msgSender());
        assert(staker.reward >= staker.claimedReward);
        unclaimedReward = staker.reward - staker.claimedReward;
    }

    function _updateHistoricalRewardRate(uint256 currentTokenSupply) internal {
        if (currentTokenSupply == 0) return;
        if (state.totalStaked != 0) {
            uint128 additionalRewardRate = uint128(
                (currentTokenSupply << 40) / state.totalStaked
            );
            state.historicalRewardRate += additionalRewardRate;
        } else {
            _sendEth(foundersPool, currentTokenSupply);
        }
    }

    function totalStaked() external view returns (uint128) {
        return state.totalStaked;
    }

    function _sendEth(address recipient, uint256 value) internal {
        (bool success, ) = recipient.call{value: value}("");
        require(
            success,
            "InvestorsPool: unable to send value, recipient may have reverted"
        );
    }

    receive() external payable {
        _updateHistoricalRewardRate(msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ITrustedContacts {
    function isTrusted(address contract_) external view returns (bool);

    function addTrustedContract(address contract_) external;

    function removeTrustedContract(address contract_) external;

    event NewTrustedContract(address indexed contract_);
    event RemovedTrustedContract(address indexed contract_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IInvestorsPool {
    function stakeFrom(address owner, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITrustedContacts.sol";

/// @custom:security-contact [email protected]
abstract contract TrustedContacts is Ownable, ITrustedContacts {
    mapping(address => bool) private _isTrusted;

    function isTrusted(address contract_) public view override returns (bool) {
        return _isTrusted[contract_];
    }

    modifier onlyTrusted() {
        require(
            isTrusted(_msgSender()),
            "TrustedContacts: caller is not the trusted contact"
        );
        _;
    }

    function addTrustedContract(address contract_) public override onlyOwner {
        _isTrusted[contract_] = true;
        emit NewTrustedContract(contract_);
    }

    function removeTrustedContract(address contract_)
        public
        override
        onlyOwner
    {
        _isTrusted[contract_] = false;
        emit RemovedTrustedContract(contract_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev The contract is intendent to help recovering arbitrary ERC20 tokens
 * accidentally transferred to the contract address.
 */
abstract contract RecoverableErc20ByOwner is Ownable {
    function _getRecoverableAmount(address tokenAddress)
        internal
        view
        virtual
        returns (uint256)
    {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /**
     * @param tokenAddress ERC20 token's address to recover
     * @param amount to recover from contract's address
     * @param to address to receive tokens from the contract
     */
    function recoverFunds(
        address tokenAddress,
        uint256 amount,
        address to
    ) external virtual onlyOwner {
        uint256 recoverableAmount = _getRecoverableAmount(tokenAddress);
        require(
            amount <= recoverableAmount,
            "RecoverableByOwner: RECOVERABLE_AMOUNT_NOT_ENOUGH"
        );
        recoverErc20(tokenAddress, amount, to);
    }

    function recoverErc20(
        address tokenAddress,
        uint256 amount,
        address to
    ) private {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = tokenAddress.call(
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "RecoverableByOwner: TRANSFER_FAILED"
        );
    }
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