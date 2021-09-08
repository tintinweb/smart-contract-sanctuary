/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: https://github.com/lendroidproject/protocol.2.0/blob/master/LICENSE.md


// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.7.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.7.0;

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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts/heartbeat/Pacemaker.sol

pragma solidity 0.7.5;



/** @title Pacemaker
    @author Lendroid Foundation
    @notice Smart contract based on which various events in the Protocol take place
    @dev Audit certificate : Pending
*/


// solhint-disable-next-line
abstract contract Pacemaker {

    using SafeMath for uint256;
    uint256 constant public HEART_BEAT_START_TIME = 1607212800;// 2020-12-06 00:00:00 UTC (UTC +00:00)
    uint256 constant public EPOCH_PERIOD = 8 hours;

    /**
        @notice Displays the epoch which contains the given timestamp
        @return uint256 : Epoch value
    */
    function epochFromTimestamp(uint256 timestamp) public pure virtual returns (uint256) {
        if (timestamp > HEART_BEAT_START_TIME) {
            return timestamp.sub(HEART_BEAT_START_TIME).div(EPOCH_PERIOD).add(1);
        }
        return 0;
    }

    /**
        @notice Displays timestamp when a given epoch began
        @return uint256 : Epoch start time
    */
    function epochStartTimeFromTimestamp(uint256 timestamp) public pure virtual returns (uint256) {
        if (timestamp <= HEART_BEAT_START_TIME) {
            return HEART_BEAT_START_TIME;
        } else {
            return HEART_BEAT_START_TIME.add((epochFromTimestamp(timestamp).sub(1)).mul(EPOCH_PERIOD));
        }
    }

    /**
        @notice Displays timestamp when a given epoch will end
        @return uint256 : Epoch end time
    */
    function epochEndTimeFromTimestamp(uint256 timestamp) public pure virtual returns (uint256) {
        if (timestamp < HEART_BEAT_START_TIME) {
            return HEART_BEAT_START_TIME;
        } else if (timestamp == HEART_BEAT_START_TIME) {
            return HEART_BEAT_START_TIME.add(EPOCH_PERIOD);
        } else {
            return epochStartTimeFromTimestamp(timestamp).add(EPOCH_PERIOD);
        }
    }

    /**
        @notice Calculates current epoch value from the block timestamp
        @dev Calculates the nth 8-hour window frame since the heartbeat's start time
        @return uint256 : Current epoch value
    */
    function currentEpoch() public view virtual returns (uint256) {
        return epochFromTimestamp(block.timestamp);// solhint-disable-line not-rely-on-time
    }

}

// File: contracts/auctions/IRandomMinter.sol

pragma solidity 0.7.5;


/**
 * @dev Required interface of an AuctionTokenProbabilityDistribution compliant contract.
 */
interface IRandomMinter {
    function mintWithRandomness(uint256 randomResult, address to) external returns(
        address newTokenAddress, uint256 newTokenId, uint256 feePercentage);

    function transferOwnership(address newOwner) external;

    function currentOwner() external view returns (address);
}

// File: contracts/auctions/season2/IERC721WhaleStreetSeason2.sol

pragma solidity 0.7.5;


/**
 * @dev Required interface of an ERC721WhaleStreet compliant contract.
 */
interface IERC721WhaleStreetSeason2 {
    function setBaseURI(string memory baseURI_) external;
    function mint(address to) external;
    function transferOwnership(address newOwner) external;
    function getNextTokenId() external view returns (uint256);
    function currentTokenId() external view returns (uint256);
}

// File: contracts/auctions/season2/KeyMinter2.sol

pragma solidity 0.7.5;








contract KeyMinter2 is IRandomMinter, Pacemaker, Ownable {

    using SafeMath for uint256;
    using Address for address;

    enum Rarity { REGULAR, UNIQUE, LEGENDARY }

    mapping(Rarity => uint256) public daoTreasuryFeePercentages;

    mapping(uint256 => address) public artists;

    mapping(address => IERC721WhaleStreetSeason2[]) public artistAuctionTokens;

    uint256 public constant SEASON_START_EPOCH = 823;
    uint256 public constant EPOCHS_PER_WEEK = 21;

    // solhint-disable-next-line func-visibility
    constructor() {
        daoTreasuryFeePercentages[Rarity.REGULAR] = 50;
        daoTreasuryFeePercentages[Rarity.UNIQUE] = 25;
        daoTreasuryFeePercentages[Rarity.LEGENDARY] = 5;
    }

    function setArtistAndAuctionTokens(uint256 artistIndex, address[4] memory addresses) external onlyOwner {
        require(addresses[0] != address(0), "{setArtistAndAuctionTokens} : invalid artist address");
        require(addresses[1].isContract(), "{setArtistAndAuctionTokens} : invalid common auctionTokenAddress");
        require(addresses[2].isContract(), "{setArtistAndAuctionTokens} : invalid rare auctionTokenAddress");
        require(addresses[3].isContract(), "{setArtistAndAuctionTokens} : invalid legendary auctionTokenAddress");
        artists[artistIndex] = addresses[0];
        artistAuctionTokens[addresses[0]] = [IERC721WhaleStreetSeason2(addresses[1]),
            IERC721WhaleStreetSeason2(addresses[2]),
            IERC721WhaleStreetSeason2(addresses[3])
        ];
    }

    function transferERC721Ownership(address tokenAddress, address newOwner) external onlyOwner {
        require(tokenAddress.isContract(), "{transferERC721Ownership} : invalid tokenAddress");
        require(newOwner != address(0), "{transferERC721Ownership} : invalid newOwner");
        // transfer ownership of ERC721 token to newOwner
        IERC721WhaleStreetSeason2(tokenAddress).transferOwnership(newOwner);
    }

    function currentOwner() external view override returns (address) {
        return owner();
    }

    function mintWithRandomness(uint256 randomResult, address to) public onlyOwner override returns (
        address newTokenAddress, uint256 newTokenId, uint256 feePercentage) {
        require((randomResult > 0) && (randomResult <= 100), "Invalid randomResult");
        address artistAddress;
        IERC721WhaleStreetSeason2 auctionToken;
        // get artist
        uint256 epochInCurrentWeek = currentEpoch().sub(SEASON_START_EPOCH).mod(EPOCHS_PER_WEEK);
        if (epochInCurrentWeek < 6) {
            artistAddress = artists[0];// Pxlq
        } else if (epochInCurrentWeek >= 6 && epochInCurrentWeek < 15) {
            artistAddress = artists[1];// Arturo Sandoval
        } else {
            artistAddress = artists[2];// 38 per Mille
        }
        require(artistAddress != address(0), "artistAddress is zero");
        require(artistAuctionTokens[artistAddress].length == 3, "invalid artistAuctionTokens count for artistAddress");
        if (randomResult < 15) {
            auctionToken = artistAuctionTokens[artistAddress][2];
            feePercentage = daoTreasuryFeePercentages[Rarity.LEGENDARY];
        } else if (randomResult >= 15 && randomResult < 50) {
            auctionToken = artistAuctionTokens[artistAddress][1];
            feePercentage = daoTreasuryFeePercentages[Rarity.UNIQUE];
        } else {
            auctionToken = artistAuctionTokens[artistAddress][0];
            feePercentage = daoTreasuryFeePercentages[Rarity.REGULAR];
        }
        newTokenAddress = address(auctionToken);
        require(newTokenAddress != address(0), "auctionToken address is zero");
        newTokenId = auctionToken.getNextTokenId();
        auctionToken.mint(to);
    }

    function transferOwnership(address newOwner) public override(IRandomMinter, Ownable) onlyOwner {
        require(newOwner != address(0), "{transferOwnership} : invalid new owner");
        super.transferOwnership(newOwner);
    }

}