// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Vesting is Ownable {
    IERC20 public token;

    bool public TGEStarted;
    uint256 public constant WEEKS = 7 days;
    uint256 public constant MONTHS = 30 days;

    uint256 public startTimestamp;

    struct Round {
        uint256 roundID;
        uint256 lockPeriod;
        uint256 period;
        uint256 timeUnit;
        uint256 onTGE;
        uint256 afterUnlock;
        uint256 afterUnlockDenominator;
    }

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        transferOwnership(msg.sender);

        round_['seed'] = Round({
            roundID: 0,
            lockPeriod: MONTHS,
            period: 12 * MONTHS,
            timeUnit: MONTHS, //Time of withdraw should be in seconds.
            onTGE: 0,
            afterUnlock: 5,
            afterUnlockDenominator: 100
        });

        round_['private'] = Round({
            roundID: 1,
            lockPeriod: MONTHS,
            period: 12 * MONTHS,
            timeUnit: MONTHS, //Time of withdraw should be in seconds.
            onTGE: 8,
            afterUnlock: 0,
            afterUnlockDenominator: 100
        });

        round_['public'] = Round({
            roundID: 2,
            lockPeriod: 2 * WEEKS,
            period: 8 * WEEKS,
            timeUnit: 1 seconds, //Time of withdraw should be in seconds.
            onTGE: 30,
            afterUnlock: 0,
            afterUnlockDenominator: 100
        });
    }

    // Mapping to initialise Rounds (string) with token release.
    mapping(string => Round) public round_;
    // Mapping to check the amount of balance already claimed
    mapping(address => uint256) public BalanceClaimed;
    // Mapping to see how much token allocated for address for a specific round.
    mapping(string => mapping(address => uint256)) public TotalTokenAllocations;

    /**
    * @dev grants tokens to whitelisted accounts with respect to rounds.
           One account can be part of multiple accounts. This is only valid when TGE has not started.
           For any account re-specification, a new transaction should be sent.
    * @param _round: string input specifying round name
    * @param _accounts: With respect to one _round, the whitelisted account is initialised with tokens.
    * @param _amount: Amount initialised w.r.t. to account address for rounds
    */
    function grantToken(
        string memory _round,
        address[] memory _accounts,
        uint256[] memory _amount
    ) external TGENotStarted onlyOwner {
        bytes32 keccakSeed = keccak256(abi.encodePacked('seed'));
        bytes32 keccakPrivate = keccak256(abi.encodePacked('private'));
        bytes32 keccakPublic = keccak256(abi.encodePacked('public'));

        require(
            keccakSeed == keccak256(abi.encodePacked(_round)) ||
                keccakPrivate == keccak256(abi.encodePacked(_round)) ||
                keccakPublic == keccak256(abi.encodePacked(_round)),
            'Such round does not exist'
        );
        require(_accounts.length == _amount.length, 'Wrong inputs');

        uint256 length = _accounts.length;
        for (uint256 i = 0; i < length; i++) {
            require(_accounts[i] != address(0), 'The account cannot be zero');
            TotalTokenAllocations[_round][_accounts[i]] = _amount[i];
        }
    }

    /**
     * @dev As the timelapses, per second, the address, i.e. msg.sender can claim transaction
     */
    event Claimed(uint256, address, uint256);

    function claim() public TGEisStarted {
        uint256 claimed_ = claimed(msg.sender);
        require(claimed_ > 0, 'You dont have any tokens to claim.');
        require(
            token.balanceOf(address(this)) > claimed_,
            'Vesting contract doesnt have enough tokens'
        );
        BalanceClaimed[msg.sender] += claimed_;
        token.transfer(msg.sender, claimed_);
        emit Claimed(block.timestamp, msg.sender, claimed_);
    }

    /**
     * @dev User can check the amount available to claim from the timelapsed.
     * @param user: address for user to check available amount
     */
    function claimed(address user) public view TGEisStarted returns (uint256 amount) {
        uint256 total = claimedInCategory(user, 'seed') +
            claimedInCategory(user, 'private') +
            claimedInCategory(user, 'public') -
            BalanceClaimed[user];
        return total;
    }

    /**
     * @dev User can check the amount available to claim from the timelapsed for specific amount.
     * @param user: address for user to check available amount
     * @param categoryName: string name of the round
     */
    function claimedInCategory(address user, string memory categoryName)
        public
        view
        TGEisStarted
        returns (uint256 amount)
    {
        Round memory round = round_[categoryName];
        uint256 vestingTime;
        if (block.timestamp > round.period + startTimestamp) vestingTime = round.period;
        else vestingTime = block.timestamp - startTimestamp;
        //getting bank of user on category
        uint256 bank = TotalTokenAllocations[categoryName][user];
        //calculating onTGE reward
        uint256 rewardTGE = (bank * round.onTGE) / round.afterUnlockDenominator;
        //checking is round.onTGE is incorrect
        if (rewardTGE > bank) return bank;
        //if cliff isn't passed return only rewardTGE
        if (round.lockPeriod >= vestingTime) return rewardTGE;
        //calculcating amount on unlock after cliff
        uint256 amountOnUnlock = (bank * round.afterUnlock) /
            round.afterUnlockDenominator;

        uint256 timePassedRounded = ((vestingTime - round.lockPeriod) / round.timeUnit) *
            round.timeUnit;
        if (amountOnUnlock + rewardTGE > bank) return bank;
        uint256 amountAfterUnlock = ((bank - amountOnUnlock - rewardTGE) *
            timePassedRounded) / (round.period - round.lockPeriod);

        uint256 reward = rewardTGE + amountOnUnlock + amountAfterUnlock;
        if (reward > bank) return bank;
        return reward;
    }

    /**
     * @dev _address can check the total i.e. aggregated amount for specific address. Only owner
     * @param _address: address for user to check available amount
     */
    function totalTokensAllocated(address _address) public view returns (uint256) {
        uint256 totalTokens = TotalTokenAllocations['seed'][_address] +
            TotalTokenAllocations['private'][_address] +
            TotalTokenAllocations['public'][_address];

        return totalTokens;
    }

    /**
     * @dev Initialising TGE for starting claiming for token holders. Restricted to Only Contract Owner
     */
    function startTGE() external TGENotStarted onlyOwner {
        TGEStarted = true;
        startTimestamp = block.timestamp;
    }

    modifier TGEisStarted() {
        require(TGEStarted == true, 'TGE Not started');
        _;
    }

    modifier TGENotStarted() {
        require(TGEStarted == false, 'TGE Already started');
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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