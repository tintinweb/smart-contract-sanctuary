// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./TokenSale.sol";

contract Crowdsale is Ownable, TokenSale {}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function getOwner() external view returns (address);

    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    function transfer(address dst, uint256 amount) external returns (bool success);
    function mint(address dst, uint256 amount) external returns (bool success);
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);
    function approve(address spender, uint256 amount) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address public owner = msg.sender;
    address payable public teamCollector = payable(msg.sender);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: Only owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, owner);
    }

    function setTeamCollector(address payable newTeamCollector) external onlyOwner {
        teamCollector = newTeamCollector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./TokenSaleProxy.sol";
import "./TokenSaleInfo.sol";

contract TokenSale is Ownable {
    event PurchasedToken(
        uint saleId,
        IERC20 token,
        uint256 inAmount,
        uint256 outAmount
    );

    event TokenSaleCreated(
        uint saleId,
        address proxy,
        IERC20 token
    );

    using SafeMath for uint256;

    TokenSaleInfo[] private _info;

    function getTokenSaleInfo(uint saleId) public view returns (TokenSaleInfo memory) {
        return _info[saleId];
    }

    function addTokenSaleNow(
        uint _price, 
        IERC20 _token, 
        address payable _collector,
        uint _endVia,
        uint256 _amount
    ) public returns (uint index, address proxyAddr) {
        return addTokenSale(block.timestamp, block.timestamp + _endVia, _price, _token, _amount, _collector);
    }

    function addTokenSale(
        uint _startTime, 
        uint _endTime, 
        uint _price, 
        IERC20 _token,
        uint256 _amount,
        address payable _collector
    ) public returns (uint index, address proxyAddr) {
            
        _info.push(TokenSaleInfo(
            _startTime,
            _endTime,
            _price,
            _token,
            _amount,
            _collector,
            msg.sender
        ));
        index = _info.length - 1;

        _token.transferFrom(msg.sender, address(this), _amount);

        TokenSaleProxy tsp = new TokenSaleProxy(index, address(this));
        proxyAddr = address(tsp);
        emit TokenSaleCreated(index, proxyAddr, _token);
    }

    function buyToken(uint saleId, address recipient) payable external {
        require(block.timestamp > _info[saleId].startTime, "TokenSale: SALE_NOT_STARTED");
        require(block.timestamp < _info[saleId].endTime, "TokenSale: SALE_END");

        uint256 tokens = msg.value;
        tokens = tokens.mul(_info[saleId].price);
        tokens = tokens.div(10**(18 - _info[saleId].token.decimals()));

        _info[saleId].amount = _info[saleId].amount.sub(tokens);
        _info[saleId].token.transfer(recipient, tokens);

        uint amount = msg.value;
        amount = amount.sub(amount.div(100));

        _info[saleId].collector.transfer(amount);
        emit PurchasedToken(saleId, _info[saleId].token, msg.value, tokens);
    }

    function withdraw() external {
        teamCollector.transfer(address(this).balance);
    }

    function withdrawToken(uint saleId, uint256 amount, address recipient) external {
        require(_info[saleId].creator == msg.sender, "TokenSale: NOT_CREATOR");
        require(_info[saleId].token.balanceOf(address(this)) >= amount, "TokenSale: INSUFFICIENT_BALANCE");
        require(_info[saleId].amount <= amount, "TokenSale: Invalid amount");
        
        _info[saleId].token.transfer(recipient, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

struct TokenSaleInfo {
    uint startTime;
    uint endTime;
    uint price;
    IERC20 token;
    uint amount;
    address payable collector;
    address creator;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenSale.sol";
import "./TokenSaleInfo.sol";

contract TokenSaleProxy {
    TokenSale ts = TokenSale(msg.sender);
    uint saleId;

    constructor(uint _saleId, address _tokenSale) {
        ts = TokenSale(_tokenSale);
        saleId = _saleId;
    }

    receive() payable external {
        TokenSaleInfo memory tsi = ts.getTokenSaleInfo(saleId);
        uint256 balance = tsi.token.balanceOf(address(this));
        if(balance > 0) {
            tsi.token.transfer(address(ts), balance);
        }
        ts.buyToken{value: msg.value}(saleId, msg.sender);
    }
}

