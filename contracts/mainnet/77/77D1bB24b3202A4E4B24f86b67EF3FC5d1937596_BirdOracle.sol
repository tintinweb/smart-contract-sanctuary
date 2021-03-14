pragma solidity 0.6.12;

/**
Bird On-chain Oracle to confirm rating with 50% consensus before update using the off-chain API https://www.bird.money/docs
*/

// © 2020 Bird Money
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract BirdOracle is Ownable {
    using SafeMath for uint256;

    BirdRequest[] public onChainRequests; //keep track of list of on-chain

    uint256 public minConsensus = 2; //minimum votes on an answer before confirmation
    uint256 public birdNest = 0; // birds in nest count i.e total trusted providers
    uint256 public trackId = 0; //current request id

    address[] public providers; //offchain oracle nodes
    mapping(address => uint256) statusOf; //offchain data provider address => TRUSTED or NOT

    //status of providers with respect to all requests
    uint8 constant NOT_TRUSTED = 0;
    uint8 constant TRUSTED = 1;
    uint8 constant WAS_TRUSTED = 2;

    //status of with respect to individual request
    uint8 constant NOT_VOTED = 0;
    uint8 constant VOTED = 2;

    /**
     * Bird Standard API Request
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

    mapping(address => uint256) private ratingOf; //saved ratings of eth addresses after consensus

    // Bird Standard API Request Off-Chain-Request from outside the blockchain
    event OffChainRequest(uint256 id, address ethAddress, string key);

    // To call when there is consensus on final result
    event UpdatedRequest(
        uint256 id,
        address ethAddress,
        string key,
        uint256 value
    );

    event ProviderAdded(address provider);
    event ProviderRemoved(address provider);

    modifier paymentApproved(address _ethAddressToQuery) {
        require(
            msg.sender == _ethAddressToQuery || isApproved(),
            "Please pay BIRD to BirdOracle"
        );
        _;
    }

    constructor(address _birdTokenAddr) public {
        birdToken = IERC20(_birdTokenAddr);
    }

    function addProvider(address _provider) public onlyOwner {
        require(statusOf[_provider] != TRUSTED, "Provider is already added.");

        if (statusOf[_provider] == NOT_TRUSTED) providers.push(_provider);
        statusOf[_provider] = TRUSTED;
        ++birdNest;

        emit ProviderAdded(_provider);
    }

    function removeProvider(address _provider) public onlyOwner {
        require(statusOf[_provider] == TRUSTED, "Provider is already removed.");

        statusOf[_provider] = WAS_TRUSTED;
        --birdNest;

        emit ProviderRemoved(_provider);
    }

    function newChainRequest(address _ethAddress, string memory _key)
        public
        paymentApproved(_ethAddress)
    {
        onChainRequests.push(
            BirdRequest({
                id: trackId,
                ethAddress: _ethAddress,
                key: _key,
                value: 0, // if resolved is true then read value
                resolved: false // if resolved is false then value do not matter
            })
        );

        //Off-Chain event trigger
        emit OffChainRequest(trackId, _ethAddress, _key);

        //update total number of requests
        trackId++;
    }

    //called by the Off-Chain oracle to record its answer
    function updatedChainRequest(uint256 _id, uint256 _response) public {
        BirdRequest storage req = onChainRequests[_id];

        require(
            req.resolved == false,
            "Error: Consensus is complete so you can not vote."
        );
        require(
            statusOf[msg.sender] == TRUSTED,
            "Error: You are not allowed to vote."
        );

        require(
            req.statusOf[msg.sender] == NOT_VOTED,
            "Error: You have already voted."
        );

        req.statusOf[msg.sender] = VOTED;
        uint256 thisAnswerVotes = ++req.votesOf[_response];

        if (thisAnswerVotes >= minConsensus) {
            req.resolved = true;
            req.value = _response;
            ratingOf[req.ethAddress] = _response;
            emit UpdatedRequest(req.id, req.ethAddress, req.key, req.value);
        }
    }

    function getRatingByAddress(address _ethAddress)
        public
        view
        paymentApproved(_ethAddress)
        returns (uint256)
    {
        return ratingOf[_ethAddress];
    }

    function getRating() public view returns (uint256) {
        return ratingOf[msg.sender];
    }

    //get trusted providers
    function getProviders() public view returns (address[] memory) {
        address[] memory trustedProviders = new address[](birdNest);
        uint256 t_i = 0;
        for (uint256 i = 0; i < providers.length; i++) {
            if (statusOf[providers[i]] == TRUSTED) {
                trustedProviders[t_i] = providers[i];
                t_i++;
            }
        }
        return trustedProviders;
    }

    IERC20 public birdToken;

    uint256 public priceToAccessOracle = 1 * 1e18; // rate of 30 days to access data is 1 BIRD
    mapping(address => uint256) public dueDateOf; // person/contract address => due date to pay for reading ratings

    //send payment to oracle to get facility to create requests and read ratings
    function sendPayment() public {
        address buyer = msg.sender;
        birdToken.transferFrom(buyer, address(this), priceToAccessOracle); // charge money from sender if he wants to access our oracle

        uint256 dueDate = dueDateOf[buyer];

        if (now < dueDate) {
            dueDateOf[buyer] = dueDate + 30 days;
        } else {
            dueDateOf[buyer] = now + 30 days;
        }
    }

    uint256 lastTimeRewarded = 0;

    function rewardProviders() public {
        //rewardProviders can be called once in a day
        uint256 timeAfterRewarded = now - lastTimeRewarded;
        require(
            timeAfterRewarded > 24 hours,
            "You can call reward providers once in 24 hrs"
        );

        //give 50% BIRD in this contract to owner and 50% to providers
        uint256 rewardToOwnerPercentage = 50; // 50% reward to owner and rest money to providers

        uint256 balance = birdToken.balanceOf(address(this));
        uint256 rewardToOwner = balance.mul(rewardToOwnerPercentage).div(100);
        uint256 rewardToProviders = balance - rewardToOwner;
        uint256 rewardToEachProvider = rewardToProviders.div(birdNest);

        birdToken.transfer(owner(), rewardToOwner);

        for (uint256 i = 0; i < providers.length; i++)
            if (statusOf[providers[i]] == TRUSTED)
                birdToken.transfer(providers[i], rewardToEachProvider);

        lastTimeRewarded = now;
    }

    function isApproved(address _addr) public view returns (bool) {
        return now < dueDateOf[_addr];
    }

    function isApproved() public view returns (bool) {
        return now < dueDateOf[msg.sender];
    }

    function setMinConsensus(uint256 _minConsensus) public onlyOwner {
        minConsensus = _minConsensus;
    }
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