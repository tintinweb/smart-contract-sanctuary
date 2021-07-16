pragma solidity 0.6.12;

// © 2020 Bird Money
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Unlockable.sol";

/// @title Oracle service to find rating of any ethereum address
/// @author Bird Money
/// @notice Bird On-chain Oracle to confirm rating with consensus before update using the off-chain API. for details https://www.bird.money/docs
/// @dev reward to node providers is a list. rewards = [reward1, reward2, reward3, ...]
contract BirdOracle is Unlockable {
    using SafeMath for uint256;
    /**
     * @dev Bird Standard API Request
     * id: "1"
     * ethAddress: address(0xcF01971DB0CAB2CBeE4A8C21BB7638aC1FA1c38c)
     * key: "bird_rating"
     * value: 400000000000000000   // 4.0
     * resolved: true / false
     * votesOf: 000000010000=> 2  (specific answer => number of votes of that answer)
     * statusOf: 0xcf021.. => VOTED
     */

    struct BirdRequest {
        uint256 id;
        address ethAddress;
        string key;
        uint256 value;
        bool resolved;
        mapping(uint256 => uint256) votesOf; //specific answer => number of votes of that answer
        mapping(address => uint256) statusOf; //offchain data provider address => VOTED or NOT
    }

    /// @notice keep track of list of on-chain requestes
    BirdRequest[] public onChainRequests;

    /// @notice minimum votes on an answer before confirmation
    uint256 public minConsensus = 2;

    /// @notice birds in nest count i.e total trusted providers
    uint256 public totalTrustedProviders = 0;

    /// @notice current request id
    uint256 public currRequestId = 0;

    // all offchain oracle nodes i.e trusted and may be some are not trusted
    address[] private providers;

    /// @notice offchain data provider address => TRUSTED or NOT
    mapping(address => uint256) public statusOf;

    // offchain data provider address => (onPortion => no of answers) casted
    mapping(address => mapping(uint256 => uint256)) private answersGivenBy;

    /// @notice offchain data provider answers, onPortion => total no of answers
    mapping(uint256 => uint256) public totalAnswersGiven;

    // status of providers with respect to all requests
    uint8 private constant NOT_TRUSTED = 0;
    uint8 private constant TRUSTED = 1;
    uint8 private constant WAS_TRUSTED = 2;

    // status of with respect to individual request
    uint8 private constant NOT_VOTED = 0;
    uint8 private constant VOTED = 2;

    mapping(address => uint256) private ratingOf; //saved ratings of eth addresses after consensus

    uint256 private onPortion = 1; // portion means portions of answers or group of answers, portion id from 0,1,2,.. to n

    /// @notice the token in which the reward is given
    IERC20 public rewardToken;

    /// @notice  Bird Standard API Request Off-Chain-Request from outside the blockchain
    event OffChainRequest(uint256 id, address ethAddress, string key);

    /// @notice  To call when there is consensus on final result
    event UpdatedRequest(
        uint256 id,
        address ethAddress,
        string key,
        uint256 value
    );

    /// @notice when an off-chain data provider is added
    event ProviderAdded(address provider);

    /// @notice when an off-chain data provider is removed
    event ProviderRemoved(address provider);

    /// @notice When min consensus value changes
    /// @param minConsensus minimum number of votes required to accept an answer from offchain data providers
    event MinConsensusChanged(uint256 minConsensus);

    /// @notice When a node provider withdraw his reward
    /// @param _provider the node provider i.e off-chain data provider
    /// @param _accReward the amount of reward collected by node provider
    event RewardWithdrawn(address _provider, uint256 _accReward);

    constructor(address _rewardTokenAddr) public {
        rewardToken = IERC20(_rewardTokenAddr);
    }

    /// @notice add any address as off-chain data provider to trusted providers list
    /// @param _provider the address which is added
    function addProvider(address _provider) external onlyOwner {
        require(statusOf[_provider] != TRUSTED, "Provider is already added.");

        if (statusOf[_provider] == NOT_TRUSTED) providers.push(_provider);
        statusOf[_provider] = TRUSTED;
        totalTrustedProviders = totalTrustedProviders.add(1);

        emit ProviderAdded(_provider);
    }

    /// @notice remove any address as off-chain data provider from trusted providers list
    /// @param _provider the address which is removed
    function removeProvider(address _provider) external onlyOwner {
        require(statusOf[_provider] == TRUSTED, "Provider is already removed.");

        statusOf[_provider] = WAS_TRUSTED;
        totalTrustedProviders = totalTrustedProviders.sub(1);

        emit ProviderRemoved(_provider);
    }

    /// @notice Bird Standard API Request Off-Chain-Request from outside the blockchain
    /// @param _ethAddress the address which rating is required to read from offchain
    /// @param _key its tells offchain data providers from any specific attributes
    function newChainRequest(address _ethAddress, string memory _key) external {
        require(bytes(_key).length > 0, "String with 0 length no allowed");

        onChainRequests.push(
            BirdRequest({
                id: currRequestId,
                ethAddress: _ethAddress,
                key: _key,
                value: 0, // if resolved is true then read value
                resolved: false // if resolved is false then value do not matter
            })
        );

        //Off-Chain event trigger
        emit OffChainRequest(currRequestId, _ethAddress, _key);

        //update total number of requests
        currRequestId = currRequestId.add(1);
    }

    /// @notice called by the Off-Chain oracle to record its answer
    /// @param _id the request id
    /// @param _response the answer to query of this request id
    function updatedChainRequest(uint256 _id, uint256 _response) external {
        BirdRequest storage req = onChainRequests[_id];
        address sender = msg.sender;

        require(
            !req.resolved,
            "Error: Consensus is complete so you can not vote."
        );

        require(
            statusOf[sender] == TRUSTED,
            "Error: You are not allowed to vote."
        );

        require(
            req.statusOf[sender] == NOT_VOTED,
            "Error: You have already voted."
        );

        answersGivenBy[sender][onPortion] = answersGivenBy[sender][onPortion]
        .add(1);

        totalAnswersGiven[onPortion] = totalAnswersGiven[onPortion].add(1);

        req.statusOf[sender] = VOTED;
        req.votesOf[_response] = req.votesOf[_response].add(1);
        uint256 thisAnswerVotes = req.votesOf[_response];

        if (thisAnswerVotes >= minConsensus) {
            req.resolved = true;
            req.value = _response;
            ratingOf[req.ethAddress] = _response;
            emit UpdatedRequest(req.id, req.ethAddress, req.key, req.value);
        }
    }

    /// @notice get rating of any address
    /// @param _ethAddress the address which rating is required to read from offchain
    /// @return the required rating of any ethAddress
    function getRatingByAddress(address _ethAddress)
        external
        view
        returns (uint256)
    {
        return ratingOf[_ethAddress];
    }

    /// @notice get rating of caller address
    /// @return the required rating of caller
    function getRatingOfCaller() external view returns (uint256) {
        return ratingOf[msg.sender];
    }

    /// @notice get rating of trusted providers to show on ui
    /// @return the trusted providers list
    function getProviders() external view returns (address[] memory) {
        address[] memory trustedProviders = new address[](
            totalTrustedProviders
        );
        uint256 t_i = 0;
        uint256 totalProviders = providers.length;
        for (uint256 i = 0; i < totalProviders; i = i.add(1)) {
            if (statusOf[providers[i]] == TRUSTED) {
                trustedProviders[t_i] = providers[i];
                t_i = t_i.add(1);
            }
        }
        return trustedProviders;
    }

    /// @notice owner can set reward token according to the needs
    /// @param _minConsensus minimum number of votes required to accept an answer from offchain data providers
    function setMinConsensus(uint256 _minConsensus) external onlyOwner {
        minConsensus = _minConsensus;
        emit MinConsensusChanged(_minConsensus);
    }

    /// @notice owner can reward providers with USDT or any ERC20 token
    /// @param _totalSentReward the amount of tokens to be equally distributed to all trusted providers
    function rewardProviders(uint256 _totalSentReward) external onlyOwner {
        require(_totalSentReward != 0, "Can not give ZERO reward.");
        rewards[onPortion] = _totalSentReward;
        onPortion = onPortion.add(1);
        rewardToken.transferFrom(owner(), address(this), _totalSentReward);
    }

    mapping(address => uint256) private lastRewardPortionOf;

    // stores the list of rewards given by owner
    // answers are divided in portions, (uint256 => uint256) means (answersPortionId => ownerAddedRewardForThisPortion)
    mapping(uint256 => uint256) private rewards;

    /// @notice any node provider can call this method to withdraw his reward
    function withdrawReward() public {
        withdrawReward(onPortion);
    }

    /// @notice any node provider can call this method to withdraw his reward
    /// @param _portions amount of reward blocks from which you want to get your reward
    function withdrawReward(uint256 _portions) public {
        address sender = msg.sender;
        require(statusOf[sender] == TRUSTED, "You can not withdraw reward.");

        uint256 lastRewardedPortion = lastRewardPortionOf[sender];
        uint256 toRewardPortion = lastRewardedPortion.add(_portions);
        if (toRewardPortion > onPortion) toRewardPortion = onPortion;
        lastRewardPortionOf[sender] = toRewardPortion;
        uint256 accReward = getAccReward(lastRewardedPortion, toRewardPortion);
        rewardToken.transfer(sender, accReward);
        emit RewardWithdrawn(sender, accReward);
    }

    /// @notice any node provider can call this method to see his reward
    /// @return reward of a node provider
    function seeReward(address _sender) public view returns (uint256) {
        return seeReward(_sender, onPortion);
    }

    /// @notice any node provider can call this method to see his reward
    /// @param _portions amount of reward portions from which you want to see your reward
    /// @return reward of a provider on given number of answers portions
    function seeReward(address _sender, uint256 _portions)
        public
        view
        returns (uint256)
    {
        uint256 lastRewardedPortion = lastRewardPortionOf[_sender];
        uint256 toRewardPortion = lastRewardedPortion.add(_portions);
        if (toRewardPortion > onPortion) toRewardPortion = onPortion;
        return getAccReward(lastRewardedPortion, toRewardPortion);
    }

    function getAccReward(uint256 lastRewardedPortion, uint256 toRewardPortion)
        private
        view
        returns (uint256)
    {
        address sender = msg.sender;
        uint256 accReward = 0;
        for (
            uint256 onThisPortion = lastRewardedPortion;
            onThisPortion < toRewardPortion;
            onThisPortion = onThisPortion.add(1)
        ) {
            if (totalAnswersGiven[onThisPortion] > 0)
                accReward = accReward.add(
                    rewards[onThisPortion]
                    .mul(answersGivenBy[sender][onThisPortion])
                    .div(totalAnswersGiven[onThisPortion])
                );
        }

        return accReward;
    }

    /// @notice owner calls this function to see how much reward should he give to node providers
    /// @return total no of answers given in this portion of answers
    function getTotalAnswersGivenAfterReward() public view returns (uint256) {
        return totalAnswersGiven[onPortion];
    }

    /// @notice owner calls this function to see how much reward he gave to node providers
    /// @return list of rewards given by owner
    function rewardsGivenTillNow() public view returns (uint256[] memory) {
        uint256[] memory rewardsGiven = new uint256[](onPortion);
        for (uint256 i = 1; rewards[i] != 0; i = i.add(1)) {
            rewardsGiven[i] = rewards[i];
        }
        return rewardsGiven;
    }

    /// @notice get total answers given by some provider
    /// @param _provider the off-chain data provider
    /// @return total answers given by some provider
    function totalAnswersGivenByProvider(address _provider)
        public
        view
        returns (uint256)
    {
        uint256 totalAnswersGivenByThisProvider = 0;
        for (
            uint256 onThisPortion = 0;
            onThisPortion < onPortion;
            onThisPortion = onThisPortion.add(1)
        )
            totalAnswersGivenByThisProvider = totalAnswersGivenByThisProvider
            .add(answersGivenBy[_provider][onThisPortion]);

        return totalAnswersGivenByThisProvider;
    }

    /// @notice get total answers given by all providers
    /// @return total answers given by all providers
    function totalAnswersGivenByAllProviders() public view returns (uint256) {
        uint256 theTotalAnswersGiven = 0;
        for (
            uint256 onThisPortion = 0;
            onThisPortion < onPortion;
            onThisPortion = onThisPortion.add(1)
        )
            theTotalAnswersGiven = theTotalAnswersGiven.add(
                totalAnswersGiven[onThisPortion]
            );

        return theTotalAnswersGiven;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Oracle service to find rating of any ethereum address
/// @author Bird Money
/// @dev this contract is made to avoid locking of any ERC20 token and Ether
abstract contract Unlockable is Ownable {
    /// @dev owner can take out any locked tokens in contract
    /// @param token the token owner wants to take out from contract
    /// @param amount amount of tokens
    event OwnerWithdraw(IERC20 token, uint256 amount);

    /// @dev owner can take out any locked tokens in contract
    /// @param amount amount of tokens
    event OwnerWithdrawETH(uint256 amount);

    /// @dev owner can take out any locked tokens in contract
    /// @param _amount amount of tokens
    function withdrawETHFromContract(uint256 _amount)
        external
        virtual
        onlyOwner
    {
        msg.sender.transfer(_amount);
        emit OwnerWithdrawETH(_amount);
    }

    /// @dev owner can take out any locked tokens in contract
    /// @param _token the token owner wants to take out from contract
    /// @param _amount amount of tokens
    function withdrawAnyTokenFromContract(IERC20 _token, uint256 _amount)
        external
        virtual
        onlyOwner
    {
        _token.transfer(msg.sender, _amount);
        emit OwnerWithdraw(_token, _amount);
    }

    fallback() external payable {}

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}