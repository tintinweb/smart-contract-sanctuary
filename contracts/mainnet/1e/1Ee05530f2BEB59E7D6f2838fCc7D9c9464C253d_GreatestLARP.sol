//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TokenRecover.sol";

/// @dev the BotToken interface
abstract contract BotToken {
    function lastMintedToken() external view virtual returns (uint256);

    function mint(address user) external virtual returns (uint256);

    function transferOwnership(address newOwner) public virtual;
}

/// @dev the StatueToken interface
abstract contract StatueToken {
    function lastMintedToken() external view virtual returns (uint256);

    function mint(address user) external virtual returns (uint256);

    function transferOwnership(address newOwner) public virtual;
}

/// @title GreatestLARP Factory Contract
/// @author jaxcoder, ghostffcode
/// @notice Factory LARP NFT Contract
/// @dev factory contract to handle the levels, thresholds and
///     minting of the NFTs.
contract GreatestLARP is Ownable {
    using SafeMath for uint256;
    address payable immutable gitcoin;

    struct Token {
        address tokenAddress;
        uint256 thresholdBots;
        uint256 thresholdStatues;
        uint256 price;
        uint256 inflationRate;
        uint256 totalSupply;
    }

    mapping(uint256 => Token) tokenMap;
    mapping(uint256 => Token) statueMap;

    uint256 public totalTokens;
    uint256 public totalStatues;

    /// @dev checks to make sure the level passed in is valid
    modifier isValidLevel(uint256 level) {
        // level is between 1 and totalTokens Count
        require(level > 0, "Invalid level selected");
        require(level <= totalTokens, "Invalid level selected");
        require(level <= totalStatues, "Invalid level selected");
        _;
    }

    constructor(
        BotToken[] memory tokens,
        StatueToken[] memory statueTokens,
        uint256[] memory thresholdBots,
        uint256[] memory thresholdStatues,
        uint256 startPriceBot,
        uint256 startPriceStatue,
        uint256[] memory inflationRatesStatues,
        uint256[] memory inflationRatesBots
    ) {
        gitcoin = payable(address(0xde21F729137C5Af1b01d73aF1dC21eFfa2B8a0d6));

        require(
            tokens.length == thresholdBots.length,
            "Mismatch length of tokens and threshold"
        );

        require(
            statueTokens.length == thresholdStatues.length,
            "Mismatch length of tokens and threshold"
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            // increment tokens count
            totalTokens += 1;

            // add token to tokenMap
            tokenMap[totalTokens] = Token({
                tokenAddress: address(tokens[i]),
                thresholdBots: thresholdBots[i],
                thresholdStatues: 0,
                price: startPriceBot,
                totalSupply: 300,
                inflationRate: inflationRatesBots[i]
            });
        }

        for (uint256 i = 0; i < statueTokens.length; i++) {
            // increment tokens count
            totalStatues += 1;

            // add token to tokenMap
            statueMap[totalStatues] = Token({
                tokenAddress: address(statueTokens[i]),
                thresholdBots: 0,
                thresholdStatues: thresholdStatues[i],
                price: startPriceStatue,
                totalSupply: 5,
                inflationRate: inflationRatesStatues[i]
            });
        }
    }

    /// @dev A function that can be called from Etherscan to lower
    ///      the price of all items for that level by 10%.
    /// @param _level pass the level you want to lower the price for
    function whompwhomp(uint256 _level) public isValidLevel(_level) onlyOwner {
        tokenMap[_level].price = tokenMap[_level].price.sub(
            tokenMap[_level].price.mul(10).div(100)
        );
        statueMap[_level].price = statueMap[_level].price.sub(
            statueMap[_level].price.mul(10).div(100)
        );
    }

    /// @dev Returns the latest price for selected level
    /// @param _level level number
    /// @return latest price for selected level
    function lastestPriceForTokenLevel(uint256 _level)
        public
        view
        isValidLevel(_level)
        returns (uint256)
    {
        return tokenMap[_level].price;
    }

    /// @dev Returns the latest price for selected level
    /// @param _level level number
    /// @return latest price for selected level
    function lastestPriceForStatueLevel(uint256 _level)
        public
        view
        isValidLevel(_level)
        returns (uint256)
    {
        return statueMap[_level].price;
    }

    /// @dev returns a details array of uints for the Bot levels
    function getDetailForTokenLevels()
        public
        view
        returns (uint256[5][] memory)
    {
        uint256[5][] memory levels = new uint256[5][](totalTokens);

        for (uint256 i = 1; i <= totalTokens; i++) {
            uint256[5] memory levelInfo;
            levelInfo[0] = tokenMap[i].price;
            levelInfo[1] = tokenMap[i].thresholdBots;
            levelInfo[2] = tokenMap[i].totalSupply;
            levelInfo[3] = BotToken(tokenMap[i].tokenAddress).lastMintedToken();
            levelInfo[4] = tokenMap[i].totalSupply - levelInfo[3];

            // push levelInfo into levels
            levels[i - 1] = levelInfo;
        }

        return levels;
    }

    /// @dev returns a details array of uints for the Statue levels
    function getDetailForStatueLevels()
        public
        view
        returns (uint256[5][] memory)
    {
        uint256[5][] memory levels = new uint256[5][](totalTokens);

        for (uint256 i = 1; i <= totalStatues; i++) {
            uint256[5] memory levelInfo;
            levelInfo[0] = statueMap[i].price;
            levelInfo[1] = statueMap[i].thresholdStatues;
            levelInfo[2] = statueMap[i].totalSupply;
            levelInfo[3] = StatueToken(statueMap[i].tokenAddress)
                .lastMintedToken();
            levelInfo[4] = statueMap[i].totalSupply - levelInfo[3];

            // push levelInfo into levels
            levels[i - 1] = levelInfo;
        }

        return levels;
    }

    /// @dev request to mint a Bot NFT
    /// @param level pass the level to route the mint
    /// @return the id of the NFT
    function requestMint(uint256 level)
        public
        payable
        isValidLevel(level)
        returns (uint256)
    {
        BotToken levelToken = BotToken(tokenMap[level].tokenAddress);

        // check if threshold for previous token has been reached
        if (level > 1) {
            uint256 previousLevel = level - 1;
            require(
                BotToken(tokenMap[previousLevel].tokenAddress)
                    .lastMintedToken() >= tokenMap[previousLevel].thresholdBots,
                "You can't continue until the previous level threshold is reached"
            );
        }

        // compare value and price
        require(msg.value >= tokenMap[level].price, "NOT ENOUGH");

        // store the old price
        uint256 currentPrice = tokenMap[level].price;

        // update the price of the token
        tokenMap[level].price = (currentPrice * tokenMap[level].inflationRate)
            .div(1000);

        // make sure there are available tokens for this level
        require(
            levelToken.lastMintedToken() <= tokenMap[level].totalSupply,
            "Minting completed for this level"
        );

        // mint token
        uint256 id = levelToken.mint(msg.sender);

        // send ETH to gitcoin multisig
        (bool success, ) = gitcoin.call{value: currentPrice}("");
        require(success, "could not send");

        // send the refund
        uint256 refund = msg.value.sub(currentPrice);
        if (refund > 0) {
            (bool refundSent, ) = msg.sender.call{value: refund}("");
            require(refundSent, "Refund could not be sent");
        }

        return id;
    }

    /// @dev request to mint a statue NFT
    /// @param level pass the level to route the mint
    /// @return the id of the NFT
    function requestMintStatue(uint256 level)
        public
        payable
        isValidLevel(level)
        returns (uint256)
    {
        StatueToken levelToken = StatueToken(statueMap[level].tokenAddress);

        // check if threshold for previous token has been reached
        if (level > 1) {
            uint256 previousLevel = level - 1;
            require(
                StatueToken(statueMap[previousLevel].tokenAddress)
                    .lastMintedToken() >=
                    statueMap[previousLevel].thresholdStatues,
                "You can't continue until the previous level threshold is reached"
            );
        }

        // compare value and price
        require(msg.value >= statueMap[level].price, "NOT ENOUGH");

        // store the old price
        uint256 currentPrice = statueMap[level].price;

        // update the price of the token
        statueMap[level].price = (currentPrice * 1350).div(1000);

        // make sure there are available tokens for this level
        require(
            levelToken.lastMintedToken() <= statueMap[level].totalSupply,
            "Minting completed for this level"
        );

        // mint token
        uint256 id = levelToken.mint(msg.sender);

        // send ETH to gitcoin multisig
        (bool success, ) = gitcoin.call{value: currentPrice}("");
        require(success, "could not send");

        // send the refund
        uint256 refund = msg.value.sub(currentPrice);
        if (refund > 0) {
            (bool refundSent, ) = msg.sender.call{value: refund}("");
            require(refundSent, "Refund could not be sent");
        }

        return id;
    }

    /// @dev transfer ownership of ERC-721 token contracts
    /// @param to address of the new owner
    function transferTokenOwnership(address to) public onlyOwner {
        require(
            to != 0x0000000000000000000000000000000000000000,
            "cannot make balck hole owner"
        );
        for (uint256 i = 1; i <= totalTokens; i++) {
            BotToken(tokenMap[i].tokenAddress).transferOwnership(to);
        }
    }

    /// @dev transfer ownership of ERC-721 token contracts
    /// @param to address of the new owner
    function transferStatueOwnership(address to) public onlyOwner {
        require(
            to != 0x0000000000000000000000000000000000000000,
            "cannot make balck hole owner"
        );
        for (uint256 i = 1; i <= totalStatues; i++) {
            StatueToken(statueMap[i].tokenAddress).transferOwnership(to);
        }
    }
}

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TokenRecover
 * @dev Allow to recover any ERC20 sent into the contract for error
 */
contract TokenRecover is Ownable {
    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
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