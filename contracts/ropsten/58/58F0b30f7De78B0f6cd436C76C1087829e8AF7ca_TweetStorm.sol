/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: TweetStorm.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;



interface Identity {
    function isWhitelisted(address account) external returns (bool);
}

interface GoodDollar {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IdentityGuard {
    function identity() view external returns(address);
}

contract TweetStorm is Ownable {
    // for overflow/underflow security
    using SafeMath for uint256;

    // external contracts
    GoodDollar public gdToken;
    Identity public idVerifyContract;

    // total count of tweetstorms
    uint256 public totalTweetstormCount = 0; // Tweetstorm ID
    // total amount of fee for submission.
    uint256 public feeGained = 0;

    // struct for each tweetstorm
    struct PromoterParam {
        string name;
        string tweetUrl;
        string shareText;
        string twitterUserName;
        string hashtag;
        uint256 bountyAmount;
        uint256 maxBounty;
        uint256 startTimeStamp;
        uint256 duration;
    }

    struct Tweetstorm {
        // parameters input by a promoter.
        PromoterParam param;

        // promoter address of the tweetstorm
        address promoter;

        // total claimed count which should be less than maxBounty
        uint256 claimedBounty;
        
        // additional image URL for promoter and tweetstorm
        string avatarUri;
        string tweetstormUri;
    }

    // mapping of all tweetstorms
    mapping(uint256 => Tweetstorm) public tweetstorms;
    
    // struct for paticipants
    struct Participate {
        bool paid;
        string tweetUrl;
    }
    // mapping of all participants of each tweetstorm
    mapping(uint256 => mapping(address => Participate)) public participations;

    // check for hash uniqueness of Tweet URL
    mapping(bytes32 => bool) public tweetUrlHash;

    // claimer address by Tweet URL hash
    mapping(bytes32 => address) public claimerByTweetUrlHash;

    // contructor of the contract. it requires the address of GoodDollar token contract.
    constructor(address gdTokenAddress){
        gdToken = GoodDollar(gdTokenAddress);
        idVerifyContract = Identity(IdentityGuard(gdTokenAddress).identity());
    }
    event Create(uint256 tweetstormId, Tweetstorm tweetstorm);

    // add a new tweetstorm for promotion of tweet
    function addTweetstorm(string memory _name, 
                        string memory _tweetUrl,
                        string memory _shareText,
                        string memory _twitterUserName,
                        string memory _hashtag,
                        uint256 _bountyAmount,
                        uint256 _maxBounty,
                        uint256 _startTimeStamp,
                        uint256 _duration,
                        string memory _avatarUri,
                        string memory _tweetstormUri) public returns(uint256) {
        // get a tweetstorm id for a new tweetstorm.
        uint256 tweetstormId = totalTweetstormCount ++;

        // setting parameters
        tweetstorms[tweetstormId].param.name = _name ;
        tweetstorms[tweetstormId].param.tweetUrl = _tweetUrl;
        tweetstorms[tweetstormId].param.shareText = _shareText;
        tweetstorms[tweetstormId].param.twitterUserName = _twitterUserName;
        tweetstorms[tweetstormId].param.hashtag = _hashtag;
        tweetstorms[tweetstormId].param.bountyAmount = _bountyAmount;
        tweetstorms[tweetstormId].param.maxBounty = _maxBounty;
        tweetstorms[tweetstormId].param.startTimeStamp = _startTimeStamp;
        tweetstorms[tweetstormId].param.duration = _duration;
        tweetstorms[tweetstormId].avatarUri = _avatarUri;
        tweetstorms[tweetstormId].tweetstormUri = _tweetstormUri;
        tweetstorms[tweetstormId].promoter = msg.sender;
        tweetstorms[tweetstormId].claimedBounty = 0;

        // G$ token transfer to this contract and fee calculation
        uint256 mul_count = _bountyAmount.mul(_maxBounty);
        uint256 _approveAmount = mul_count.mul(110).div(100);
        // transfer G$ token to this contract
        gdToken.transferFrom(msg.sender, address(this), _approveAmount);
        // increase total fee amount with this fee.
        feeGained = feeGained.add(_approveAmount.sub(mul_count));
        // emit Create(tweetstormId, _name, _tweetUrl, _shareText, _twitterUserName, _hashtag, _bountyAmount, _maxBounty, _startTimeStamp, _duration, _avatarUri, _tweetstormUri, msg.sender, 0);
        emit Create(tweetstormId, tweetstorms[tweetstormId]);

        return tweetstormId;
    }

    function withdrawFeeGained(address _to) public onlyOwner{
        gdToken.transfer(_to, feeGained);
        feeGained = 0;
    }
    
    event Tweet(uint256 tweetstormId, address promoterAddress, string tweetUrl);

    function submitTweet(uint256 tweetstormId, string memory _tweetUrl, bytes memory signedPermit) public {
        // verify signedPermit is digest (tweetstormid+tweetUrlHash) by tweetstormManager
        bytes32 hashPermit = keccak256(abi.encodePacked(_tweetUrl));
        bytes32 sigHash = keccak256(abi.encodePacked(hashPermit, tweetstormId));
        require (verifySignature(sigHash, signedPermit, owner()) == true, 'signed permit test error');

        // verify Tweetstorm is still active (in dates + didnt pass max bounties)
        uint256 startTimeStamp = tweetstorms[tweetstormId].param.startTimeStamp.div(1000);
        uint256 endTimeStamp = tweetstorms[tweetstormId].param.startTimeStamp.div(1000).add(tweetstorms[tweetstormId].param.duration.mul(1 days));
        require(startTimeStamp < uint256(block.timestamp), 'Tweetstorm is not started');
        require(endTimeStamp > uint256(block.timestamp), 'Tweetstorm ended');
        require(tweetstorms[tweetstormId].param.maxBounty > tweetstorms[tweetstormId].claimedBounty, 'verify Tweetstorm is still active_2');

        // verify tweet hash is unique and wasnt submitted
        require(tweetUrlHash[hashPermit] == false, 'tweet hash not unique');
        tweetUrlHash[hashPermit] = true;
        
        // verify msg.sender wasnt paid already
        require(participations[tweetstormId][msg.sender].paid == false, 'verify msg.sender wasnt paid already');

        // verify address is whitelisted on G$ Identity contract
        require(idVerifyContract.isWhitelisted(msg.sender), 'whitelist');

        // save msg.sender -> tweetUrl
        participations[tweetstormId][msg.sender].tweetUrl = _tweetUrl;

        //claimer address by Tweet URL hash// save tweetUrlHash -> msg.sender
        claimerByTweetUrlHash[hashPermit] = msg.sender;

        // sends bounty to address and marks him as paid
        gdToken.transfer(msg.sender, tweetstorms[tweetstormId].param.bountyAmount);
        participations[tweetstormId][msg.sender].paid = true;

        // increase claimed bounties counter for Tweetstorm
        tweetstorms[tweetstormId].claimedBounty ++;

        // emit event Tweet(tweetstormid, msg.sender, tweetUrl)
        emit Tweet(tweetstormId, msg.sender, _tweetUrl);
    }

    function verifySignature(bytes32 hash, bytes memory signature, address signer) internal pure returns (bool) {
        require(signature.length == 65, "Require correct length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature version not match");

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        address addr = ecrecover(prefixedHash, v, r, s);
        return addr == signer;
    }
}