pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
    function exists(uint256 tokenId) external view returns (bool);
}

/**
 * @title Crowdsale
 * @dev Crowdsale contract allowing investors to purchase the cell token with our ERC20 land tokens.
 * This contract implements such functionality in its most fundamental form and can be extended 
 * to provide additional functionality and/or custom behavior.
 */
contract Crowdsale is Context {
    using SafeMath for uint256;
    // The token being sold
    IERC721 private _cellToken;

    // The main token that you can buy cell with it
    IERC20 private _land;
    address private _tokenWallet;

    // Address where your paid land tokens are collected
    address payable private _wallet;

    // Amount of land token raised
    uint256 private _tokenRaised;

    // Amount of token to be pay for one ERC721 token
    uint256 private _landPerToken;

    // Max token count to be sale
    uint256 private _maxTokenCount;

    uint256 constant private CLD_RATE_10000 = 50000;
    uint256 constant private CLD_RATE_10000_30000 = 52000;
    uint256 constant private CLD_RATE_30000_70000 = 53000;
    uint256 constant private CLD_RATE_70000_200000 = 54500;
    uint256 constant private CLD_RATE_200000_500000 = 57000;
    uint256 constant private CLD_RATE_500000_up = 60000;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param tokenId uint256 ID of the token to be purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 tokenId);

    /**
     * @param wallet_ Address where collected tokens will be forwarded to
     * @param landToken_ Address of the Land token that you can buy with it
     * @param cellToken_ Address of the Cell token being sold
     * @param landPerToken_ tokens amount paid for purchase a Cell token
     */
    constructor (address payable wallet_, IERC20 landToken_, address tokenWallet_, IERC721 cellToken_, uint256 landPerToken_, uint256 maxTokenCoun_)
        public
    {
        require(wallet_ != address(0), "Crowdsale: wallet is the zero address");
        require(address(landToken_) != address(0), "Crowdsale: land token is the zero address");
        require(address(cellToken_) != address(0), "Crowdsale: cell token is the zero address");
        require(landPerToken_ > 0, "Crowdsale: token price must be greater than zero");
        require(maxTokenCoun_ > 0, "Crowdsale: max token count must be greater than zero");
        _wallet = wallet_;
        _land = landToken_;
        _tokenWallet = tokenWallet_;
        _cellToken = cellToken_;
        _landPerToken = landPerToken_;
        _maxTokenCount = maxTokenCoun_;
    }

    /**
     * @dev Fallback function revert your fund.
     * Only buy Cell token with Land token.
     */
    fallback() external payable {
        revert("Crowdsale: cannot accept any amount directly");
    }

    /**
     * @return The base token that you can buy with it
     */
    function land() public view returns (IERC20) {
        return _land;
    }

    /**
     * @return The token being sold.
     */
    function cellToken() public view returns (IERC721) {
        return _cellToken;
    }

    /**
     * @return Amount of Land token to be pay for a Cell token
     */
    function landPerToken() public view returns (uint256) {
        return _landPerToken;
    }

    /**
     * @return The address where tokens amounts are collected.
     */
    function wallet() public view returns (address) {
        return _wallet;
    }

    /**
     * @return The amount of Land token raised.
     */
    function tokenRaised() public view returns (uint256) {
        return _tokenRaised;
    }
    
    /**
     * @return The amount of Cell token can be sold.
     */
    function getMaxTokenCount() public view returns (uint256) {
        return _maxTokenCount;
    }

    /**
     * @dev Returns x and y where represent the position of the cell.
     */
    function cellById(uint256 tokenId) public pure returns (uint256 x, uint256 y){
        y = tokenId / 90;
        x = tokenId - (y * 90);
    }

    /**
     * @dev token purchase with pay Land tokens
     * @param beneficiary Recipient of the token purchase
     * @param tokenId uint256 ID of the token to be purchase
     */
    function buyToken(address beneficiary, uint256 tokenId) public payable{
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(_landPerToken <= _land.allowance(_msgSender(), address(this)), "Crowdsale: Not enough CLD allowance");
        require(tokenId < getMaxTokenCount(), "Crowdsale: tokenId must be less than max token count");
        (uint256 x, uint256 y) = cellById(tokenId);
        require(x < 38 || x > 53 || y < 28 || y > 43, "Crowdsale: tokenId should not be in the unsold range");
        require(!_cellToken.exists(tokenId), "Crowdsale: token already minted");
        uint256 balance = _land.balanceOf(_msgSender());
        if (_landPerToken <= balance){
            _land.transferFrom(_msgSender(), _wallet, _landPerToken);
        }
        else{
            require(msg.value > 0, "Crowdsale: Not enough CLD or ETH");
            uint256 newAmount = _getTokenAmount(msg.value);
            require(newAmount.add(balance) >= _landPerToken, "Crowdsale: Not enough CLD or ETH");
            _land.transferFrom(_tokenWallet, _msgSender(), newAmount);
            _land.transferFrom(_msgSender(), _wallet, _landPerToken);
            _wallet.transfer(msg.value);
        }
        _tokenRaised += _landPerToken;
        _cellToken.mint(beneficiary, tokenId);
        emit TokensPurchased(msg.sender, beneficiary, tokenId);
    }
    
    /**
     * @dev batch token purchase with pay our ERC20 tokens
     * @param beneficiary Recipient of the token purchase
     * @param tokenIds uint256 IDs of the token to be purchase
     */
    function buyBatchTokens(address beneficiary, uint256[] memory tokenIds) public payable{
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        uint256 tokenAmount = _landPerToken * tokenIds.length;
        require(tokenAmount <= _land.allowance(_msgSender(), address(this)), "Crowdsale: Not enough CLD allowance");
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(tokenIds[i] < getMaxTokenCount(), "Crowdsale: tokenId must be less than max token count");
            (uint256 x, uint256 y) = cellById(tokenIds[i]);
            require(x < 38 || x > 53 || y < 28 || y > 43, "Crowdsale: tokenId should not be in the unsold range");
            require(!_cellToken.exists(tokenIds[i]), "Crowdsale: token already minted");
        }
        uint256 balance = _land.balanceOf(_msgSender());
        if (tokenAmount <= balance){
            _land.transferFrom(_msgSender(), _wallet, tokenAmount);
        }
        else{
            require(msg.value > 0, "Crowdsale: Not enough CLD or ETH");
            uint256 newAmount = _getTokenAmount(msg.value);
            require(newAmount.add(balance) >= tokenAmount, "Crowdsale: Not enough CLD or ETH");
            _land.transferFrom(_tokenWallet, _msgSender(), newAmount);
            _land.transferFrom(_msgSender(), _wallet, tokenAmount);
            _wallet.transfer(msg.value);
        }
        
        _tokenRaised += tokenAmount;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _cellToken.mint(beneficiary, tokenIds[i]);
            emit TokensPurchased(msg.sender, beneficiary, tokenIds[i]);
        }
    }

    /**
     * @dev Overrides function in the Crowdsale contract to enable a custom phased distribution
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        if (weiAmount >= 10 * 1e18) {
            return weiAmount.mul(CLD_RATE_500000_up);
        } else if (weiAmount >= 4 * 1e18) {
            return weiAmount.mul(CLD_RATE_200000_500000);
        } else if (weiAmount >= 1400 * 1e15 ) {
            return weiAmount.mul(CLD_RATE_70000_200000);
        } else if (weiAmount >= 600 * 1e15) {
            return weiAmount.mul(CLD_RATE_30000_70000);
        } else if (weiAmount >= 200 * 1e15) {
            return weiAmount.mul(CLD_RATE_10000_30000);
        } else {
            return weiAmount.mul(CLD_RATE_10000);
        }
    }
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}