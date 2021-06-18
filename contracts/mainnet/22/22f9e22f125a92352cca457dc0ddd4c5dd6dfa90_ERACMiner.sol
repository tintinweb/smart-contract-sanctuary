/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

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



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}



pragma solidity ^0.8.0;


/**
 * @title Interface for other's contracts use
 * @dev This functions will be called by other's contracts
 */
interface IERAC {
    /**
     * @dev Query the TokenId(ERAC) list for the specified account.
     *
     */
    function getTokenIds(address owner) external view returns (uint256[] memory);
}


/**
 * @title Interface for other's contracts use
 * @dev This functions will be called by other's contracts
 */
interface INERA {
    /**
     * @dev Mining for NERA tokens.
     *
     */
    function mint(address to, uint256 amount) external returns (bool);
}


contract ERACMiner is Ownable {

    // the NERA contract address(Special note: need to wait for the NERA contract deployment, get the address and replace, then compile and deploy this contract)
    address private constant _NERA_CONTRACT_ADDRESS = address(0x6b1218D1a79b06a811dc54E745C51d8cDF666c1d);

    // the ERAC contract address(Special note: need to wait for the ERAC contract deployment, get the address and replace, then compile and deploy this contract)
    address private constant _ERAC_CONTRACT_ADDRESS = address(0x30E4812AC46992F3A53A9e7D3CF37cDAdc1f4145);

    using SafeMath for uint256;
    // Produce time control
    // The timestamp (counting the total seconds elapsed since 1970-01-01 00:00:00[UTC zero zone] )
    // now start timestamp is 2021-04-16 00:00:00[UTC zero zone] or 2021-04-16 08:00:00(Beijing Time)
    uint256 private constant _startTimestamp = 1618531200;
    uint256 private constant _mintPeriod = 70839360; //819.9d * 24h * 3600s;
    uint256 private constant _endTimestamp = _startTimestamp + _mintPeriod;

    // Mapping from tokenId to total amount of this tokenId that withdrawed
    mapping(uint256 => uint256) private _withdrawalAmount;

    /**
     * @dev Throws if called by an invalid ERAC token id.
     */
    modifier isValidTokenId(uint256 tokenId)
    {
        require(tokenId >= 1 && tokenId <= 10000, "ERACMiner: operator an invalid ERAC tokenId");
        _;
    }


    /**
     * @dev Give any valid ERAC's token id return level(1-9)
     */
    function _getLevel(uint256 id)
    private
    pure
    isValidTokenId(id)
    returns (uint256)
    {
        return id > 6000 ? 1 : (id > 4000 ? 2 : (id > 3000 ? 3 : (id > 2000 ? 4 : (id > 1000 ? 5 : (id > 300 ? 6 : (id > 100 ? 7 : (id > 10 ? 8 : 9)))))));
    }


    /**
     * @dev Query the balanceOf NERAs remaining for an ERAC (wei)
     */
    function balanceOfERAC(uint256 tokenId)
    public
    view
    isValidTokenId(tokenId)
    returns (uint256)
    {
        uint256 nSeconds = block.timestamp - _startTimestamp;
        if (nSeconds <= 0) return 0;
        if (nSeconds >= _mintPeriod) nSeconds = _mintPeriod;
        // Produce speed of levels
        uint16[10] memory levelEveryDayMiningNum = [0, 3, 7, 13, 18, 22, 38, 175, 390, 4384];
        return nSeconds * (10 ** 18) * levelEveryDayMiningNum[_getLevel(tokenId)] / 86400 - _withdrawalAmount[tokenId];
    }

    /**
     * @dev Query the balanceOf NERAs remaining for an account (wei)
     */
    function balanceOfAccount(address owner)
    public
    view
    returns (uint256)
    {
        uint256[] memory tokenIds = IERAC(_ERAC_CONTRACT_ADDRESS).getTokenIds(owner);
        if (tokenIds.length == 0) return 0;
        uint256 totalBalance = 0;
        for (uint i = 0; i < tokenIds.length; ++i) {
            totalBalance = totalBalance.add(balanceOfERAC(tokenIds[i]));
        }
        return totalBalance;
    }


    /**
     * @dev withdraw
     */
    function withdraw()
    public
    returns (bool)
    {
        //Reference of ERAC contract call
        uint256[] memory tokenIds = IERAC(_ERAC_CONTRACT_ADDRESS).getTokenIds(msg.sender);
        require(tokenIds.length > 0, "ERACMiner: message sender has no ERAC token");

        uint256 withdrawBalance = 0;
        for (uint i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            uint256 balanceOfThis = balanceOfERAC(tokenId);
            if (balanceOfThis > 0) {
                _withdrawalAmount[tokenId] = _withdrawalAmount[tokenId].add(balanceOfThis);
                withdrawBalance = withdrawBalance.add(balanceOfThis);
            }
        }

        require(withdrawBalance > 0, "ERACMiner: since last withdraw has no new NERA produce");
        //Reference of NERA contract call
        require(INERA(_NERA_CONTRACT_ADDRESS).mint(msg.sender, withdrawBalance), "ERACMiner: mint failed.");

        return true;
    }
}