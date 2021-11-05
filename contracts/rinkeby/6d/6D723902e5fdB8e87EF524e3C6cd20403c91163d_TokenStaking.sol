// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ITokenStaking.sol";

/**
 * @dev Implementation of the {ITokenStaking} interface.
 * @author Ahmed Ali Bhatti <github.com/ahmedali8>
 *
 * Note: Deployer will be the {owner}.
 */
contract TokenStaking is ITokenStaking, Ownable, ReentrancyGuard {
    /**
     * @dev See {ITokenStaking-totalValueLocked}.
     */
    uint256 public override totalValueLocked;

    /**
     * @dev See {ITokenStaking-apy}.
     */
    uint256 public override apy;

    // Token Instance
    IERC20 public token;

    /**
     * @dev See {ITokenStaking-userInfos}.
     *
     * user address -> stakeNum -> UserInfo struct
     *
     */
    mapping(address => mapping(uint256 => UserInfo)) public override userInfos;

    /**
     * @dev See {ITokenStaking-stakeNums}.
     *
     * user address -> stakeNum
     *
     */
    mapping(address => uint256) public override stakeNums;

    // private stakeNum to manage multiple stakes of a person.
    mapping(address => uint256) private __stakeNums;

    /**
     * @dev Sets the values for {token} and {apy}.
     *
     * {apy} changes with {changeAPY}.
     *
     */
    constructor(address _tokenAddress, uint256 _apy) {
        token = IERC20(_tokenAddress);
        apy = _apy; // 12% apy -> 12 * 1e18
    }

    /**
     * @dev Fallback function.
     */
    receive() external payable {
        emit RecieveTriggered(_msgSender(), msg.value);
    }

    /**
     * @dev See {ITokenStaking-balanceOf}.
     */
    function balanceOf(address _account, uint256 _stakeNum)
        public
        view
        override
        returns (uint256)
    {
        return userInfos[_account][_stakeNum].amount;
    }

    /**
     * @dev See {ITokenStaking-stakeExists}.
     */
    function stakeExists(address _beneficiary, uint256 _stakeNum)
        public
        view
        override
        returns (bool)
    {
        return balanceOf(_beneficiary, _stakeNum) != 0 ? true : false;
    }

    /**
     * @dev See {ITokenStaking-calculateReward}.
     */
    function calculateReward(address _beneficiary, uint256 _stakeNum)
        public
        view
        override
        returns (uint256 _reward)
    {
        UserInfo memory _user = userInfos[_beneficiary][_stakeNum];
        if (totalValueLocked == 0) return 0;

        uint256 _secs = _calculateSecs(block.timestamp, _user.lastUpdated);
        _reward = (_secs * _user.amount * apy) / (31536000 * 1e20);
    }

    /**
     * @dev See {ITokenStaking-contractTokenBalance}.
     */
    function contractTokenBalance() public view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev See {ITokenStaking-stake}.
     *
     * Emits a {Staked} event indicating the stake details.
     *
     * Requirements:
     *
     * - `_amount` should be zero.
     * - stake should not already exist.
     *
     */
    function stake(uint256 _amount) public override {
        require(_amount > 0, "stake amount not valid");

        uint256 _stakeNums = __stakeNums[_msgSender()];
        uint256 _stakeNum;

        if (_stakeNums == 0) {
            // user is coming for first time
            _stakeNum = 1;
        } else {
            // add 1 in his previous stake
            _stakeNum = _stakeNums + 1;
        }

        require(!stakeExists(_msgSender(), _stakeNum), "stake already exists");

        _updateUserInfo(ActionType.Stake, _msgSender(), _stakeNum, _amount, 0);

        // Transfer the tokens to this contract
        token.transferFrom(address(_msgSender()), address(this), _amount);

        emit Staked(_msgSender(), _amount, _stakeNum);
    }

    /**
     * @dev See {ITokenStaking-unstake}.
     *
     * Emits a {Unstaked} event indicating the unstake details.
     *
     * Requirements:
     *
     * - `_stakeNum` should be valid.
     * - reward should exist for the `_stakeNum`.
     *
     */
    function unstake(uint256 _stakeNum) public override {
        _stakeExists(_msgSender(), _stakeNum);

        uint256 _amount = balanceOf(_msgSender(), _stakeNum);
        uint256 _reward = calculateReward(_msgSender(), _stakeNum);

        require(_reward != 0, "reward cannot be zero");

        _updateUserInfo(
            ActionType.Unstake,
            _msgSender(),
            _stakeNum,
            _amount,
            _reward
        );

        // Transfer staked amount and reward to user
        token.transfer(_msgSender(), _amount + _reward);

        emit Unstaked(_msgSender(), _amount, _reward, _stakeNum);
    }

    /**
     * @dev See {ITokenStaking-changeAPY}.
     *
     * Emits a {APYChanged} event indicating the {apy} is changed.
     *
     * Requirements:
     *
     * - `_apy` should not be zero.
     * - caller must be {owner}.
     *
     */
    function changeAPY(uint256 _apy) public override onlyOwner {
        require(_apy != 0, "apy cannot be zero");
        apy = _apy; // 12% apy -> 12 * 1e18
        emit APYChanged(_apy);
    }

    /**
     * @dev See {ITokenStaking-withdrawContractFunds}.
     *
     * Emits a {OwnerWithdrawFunds} event indicating the withdrawal of all funds.
     *
     * Requirements:
     *
     * - `_amount` should be less than or equal to contract balance.
     * - caller must be {owner}.
     *
     */
    function withdrawContractFunds(uint256 _amount) public override onlyOwner {
        require(
            _amount <= contractTokenBalance(),
            "amount exceeds contract balance"
        );
        token.transfer(_msgSender(), _amount);
        emit OwnerWithdrawFunds(_msgSender(), _amount);
    }

    /**
     * @dev See {ITokenStaking-destructContract}.
     *
     * Requirements:
     *
     * - caller must be {owner}.
     *
     */
    function destructContract() public override onlyOwner {
        token.transfer(_msgSender(), token.balanceOf(address(this)));
        selfdestruct(payable(_msgSender()));
    }

    /**
     * @dev Internal function to calculate number of seconds.
     */
    function _calculateSecs(uint256 _to, uint256 _from)
        internal
        pure
        returns (uint256)
    {
        return _to - _from;
    }

    /**
     * @dev Internal function to determine if stake exists.
     *
     * Requirements:
     *
     * - `_stakeNum` cannot be zero.
     * - user must have a stake.
     * - user amount cannot be zero.
     *
     */
    function _stakeExists(address _beneficiary, uint256 _stakeNum)
        internal
        view
    {
        UserInfo memory _user = userInfos[_beneficiary][_stakeNum];
        require(_stakeNum != 0, "StakeNum does not exist");
        require(stakeNums[_beneficiary] != 0, "User does not have any stake");
        require(_user.amount > 0, "User staked amount cannot be 0");
    }

    /**
     * @dev Internal function to update user info.
     *
     * Requirements:
     *
     * - caller cannot re-enter a transaction.
     *
     */
    function _updateUserInfo(
        ActionType _actionType,
        address _beneficiary,
        uint256 _stakeNum,
        uint256 _amount,
        uint256 _reward
    ) internal nonReentrant {
        UserInfo storage user = userInfos[_beneficiary][_stakeNum];

        user.lastUpdated = block.timestamp;

        if (_actionType == ActionType.Stake) {
            stakeNums[_beneficiary] = _stakeNum;
            __stakeNums[_beneficiary] = _stakeNum;
            totalValueLocked = totalValueLocked + _amount;
            user.amount = _amount;
            user.rewardPaid = 0;
        }

        if (_actionType == ActionType.Unstake) {
            stakeNums[_beneficiary] = stakeNums[_beneficiary] - 1;
            totalValueLocked = totalValueLocked - _amount;
            user.amount = 0;
            user.rewardPaid = _reward;
        }
    }
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
pragma solidity ^0.8.9;

/**
 * @dev Interface of the TokenStaking.
 * @author Ahmed Ali Bhatti <github.com/ahmedali8>
 *
 * Note: Deployer will be the {owner}.
 */
interface ITokenStaking {
    /**
     * @dev User custom datatype.
     *
     * `amount` - How many tokens user has provided.
     * `rewardPaid` - How much reward is paid to user.
     * `lastUpdated` - When did he staked his amount.
     */
    struct UserInfo {
        uint256 amount;
        uint256 rewardPaid;
        uint256 lastUpdated;
    }

    /**
     * @dev Action type enum.
     */
    enum ActionType {
        Stake,
        Unstake
    }

    /**
     * @dev Emitted when some ether is received from fallback.
     */
    event RecieveTriggered(address user, uint256 amount);

    /**
     * @dev Emitted when a `user` stakes `amount` tokens.
     */
    event Staked(address indexed user, uint256 amount, uint256 stakeNum);

    /**
     * @dev Emitted when a `user` unstakes `amount` tokens and `reward`.
     */
    event Unstaked(
        address indexed user,
        uint256 amount,
        uint256 reward,
        uint256 stakeNum
    );

    /**
     * @dev Emitted when a {owner} withdraws funds.
     */
    event OwnerWithdrawFunds(address indexed beneficiary, uint256 amount);

    /**
     * @dev Emitted when a {apy} is changed.
     */
    event APYChanged(uint256 apy);

    /**
     * @dev Returns the total value locked in contract.
     */
    function totalValueLocked() external view returns (uint256);

    /**
     * @dev Returns the {apy} value.
     */
    function apy() external view returns (uint256);

    /**
     * @dev Returns the values of {UserInfo}.
     */
    function userInfos(address, uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev Returns the number of stakes of an address.
     */
    function stakeNums(address) external view returns (uint256);

    /**
     * @dev Returns the staked balance of a `_account` having corresponding `_stakeNum`.
     */
    function balanceOf(address _account, uint256 _stakeNum)
        external
        view
        returns (uint256);

    /**
     * @dev Returns a boolean value if stake exists of a `_beneficiary` with `_stakeNum`.
     */
    function stakeExists(address _beneficiary, uint256 _stakeNum)
        external
        view
        returns (bool);

    /**
     * @dev Returns the reward amount of a `_beneficiary` with `_stakeNum`.
     */
    function calculateReward(address _beneficiary, uint256 _stakeNum)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the total token balance of this contract.
     */
    function contractTokenBalance() external view returns (uint256);

    /**
     * @dev Stakes `_amount` amount of tokens in this contract.
     *
     * Emits a {Staked} event.
     */
    function stake(uint256 _amount) external;

    /**
     * @dev Unstakes the stake having `_stakeNum`.
     *
     * Emits a {Unstaked} event.
     */
    function unstake(uint256 _stakeNum) external;

    /**
     * @dev Sets {apy} to `_apy`.
     *
     * Note that caller must be {owner}.
     *
     * Emits a {APYChanged} event.
     */
    function changeAPY(uint256 _apy) external;

    /**
     * @dev Allows {owner} to withdraw all funds from this contract.
     *
     * Note that caller must be {owner}.
     *
     * Emits a {OwnerWithdrawFunds} event.
     */
    function withdrawContractFunds(uint256 _amount) external;

    /**
     * @dev Destructs this contract and transfers all funds to {owner}.
     *
     * Note that caller must be {owner}.
     *
     */
    function destructContract() external;
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