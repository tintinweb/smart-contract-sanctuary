//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "../interfaces/IXVIX.sol";
import "../interfaces/IBurnVault.sol";
import "../interfaces/IGmtIou.sol";

contract GmtSwap is ReentrancyGuard {
    using SafeMath for uint256;

    uint256 constant PRECISION = 1000000;

    bool public isInitialized;
    bool public isSwapActive = true;

    address public xvix;
    address public uni;
    address public xlge;
    address public gmtIou;
    address public weth;
    address public dai;
    address public wethDaiUni;
    address public wethXvixUni;
    address public allocator;
    address public burnVault;

    uint256 public gmtPrice;
    uint256 public xlgePrice;
    uint256 public minXvixPrice;
    uint256 public unlockTime;

    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "GmtSwap: forbidden");
        _;
    }

    function initialize(
        address[] memory _addresses,
        uint256 _gmtPrice,
        uint256 _xlgePrice,
        uint256 _minXvixPrice,
        uint256 _unlockTime
    ) public onlyGov {
        require(!isInitialized, "GmtSwap: already initialized");
        isInitialized = true;

        xvix = _addresses[0];
        uni = _addresses[1];
        xlge = _addresses[2];
        gmtIou = _addresses[3];

        weth = _addresses[4];
        dai = _addresses[5];
        wethDaiUni = _addresses[6];
        wethXvixUni = _addresses[7];

        allocator = _addresses[8];
        burnVault = _addresses[9];

        gmtPrice = _gmtPrice;
        xlgePrice = _xlgePrice;
        minXvixPrice = _minXvixPrice;
        unlockTime = _unlockTime;
    }

    function setGov(address _gov) public onlyGov {
        gov = _gov;
    }

    function extendUnlockTime(uint256 _unlockTime) public onlyGov {
        require(_unlockTime > unlockTime, "GmtSwap: invalid unlockTime");
        unlockTime = _unlockTime;
    }

    function withdraw(address _token, uint256 _tokenAmount, address _receiver) public onlyGov {
        require(block.timestamp > unlockTime, "GmtSwap: unlockTime not yet passed");
        IERC20(_token).transfer(_receiver, _tokenAmount);
    }

    function swap(
        address _token,
        uint256 _tokenAmount,
        uint256 _allocation,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public nonReentrant {
        require(isSwapActive, "GmtSwap: swap is no longer active");
        require(_tokenAmount > 0, "GmtSwap: invalid tokenAmount");
        require(_allocation > 0, "GmtSwap: invalid gmtAllocation");

        _verifyAllocation(msg.sender, _allocation, _v, _r, _s);
        (uint256 transferAmount, uint256 mintAmount) = getSwapAmounts(
            msg.sender, _token, _tokenAmount, _allocation);
        require(transferAmount > 0, "GmtSwap: invalid transferAmount");
        require(mintAmount > 0, "GmtSwap: invalid mintAmount");

        IXVIX(xvix).rebase();
        IERC20(_token).transferFrom(msg.sender, address(this), transferAmount);

        if (_token == xvix) {
            IERC20(_token).approve(burnVault, transferAmount);
            IBurnVault(burnVault).deposit(transferAmount);
        }

        IGmtIou(gmtIou).mint(msg.sender, mintAmount);
    }

    function endSwap() public onlyGov {
        isSwapActive = false;
    }

    function getSwapAmounts(
        address _account,
        address _token,
        uint256 _tokenAmount,
        uint256 _allocation
    ) public view returns (uint256, uint256) {
        require(_token == xvix || _token == uni || _token == xlge, "GmtSwap: unsupported token");
        uint256 tokenPrice = getTokenPrice(_token);

        uint256 transferAmount = _tokenAmount;
        uint256 mintAmount = _tokenAmount.mul(tokenPrice).div(gmtPrice);

        uint256 gmtIouBalance = IERC20(gmtIou).balanceOf(_account);
        uint256 maxMintAmount = _allocation.sub(gmtIouBalance);

        if (mintAmount > maxMintAmount) {
            mintAmount = maxMintAmount;
            // round up the transferAmount
            transferAmount = mintAmount.mul(gmtPrice).mul(10).div(tokenPrice).add(9).div(10);
        }

        return (transferAmount, mintAmount);
    }

    function getTokenPrice(address _token) public view returns (uint256) {
        if (_token == xlge) {
            return xlgePrice;
        }
        if (_token == xvix) {
            return getXvixPrice();
        }
        if (_token == uni) {
            return getUniPrice();
        }
        revert("GmtSwap: unsupported token");
    }

    function getEthPrice() public view returns (uint256) {
        uint256 wethBalance = IERC20(weth).balanceOf(wethDaiUni);
        uint256 daiBalance = IERC20(dai).balanceOf(wethDaiUni);
        return daiBalance.mul(PRECISION).div(wethBalance);
    }

    function getXvixPrice() public view returns (uint256) {
        uint256 ethPrice = getEthPrice();
        uint256 wethBalance = IERC20(weth).balanceOf(wethXvixUni);
        uint256 xvixBalance = IERC20(xvix).balanceOf(wethXvixUni);
        uint256 price = wethBalance.mul(ethPrice).div(xvixBalance);
        if (price < minXvixPrice) {
            return minXvixPrice;
        }
        return price;
    }

    function getUniPrice() public view returns (uint256) {
        uint256 ethPrice = getEthPrice();
        uint256 wethBalance = IERC20(weth).balanceOf(wethXvixUni);
        uint256 supply = IERC20(wethXvixUni).totalSupply();
        return wethBalance.mul(ethPrice).mul(2).div(supply);
    }

    function _verifyAllocation(
        address _account,
        uint256 _allocation,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private view {
        bytes32 message = keccak256(abi.encodePacked(
            "GmtSwap:GmtAllocation",
            _account,
            _allocation
        ));
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            message
        ));

        require(
            allocator == ecrecover(messageHash, _v, _r, _s),
            "GmtSwap: invalid signature"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

pragma solidity 0.6.12;

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
contract ReentrancyGuard {
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

    constructor () internal {
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

pragma solidity 0.6.12;

interface IXVIX {
    function setGov(address gov) external;
    function normalDivisor() external view returns (uint256);
    function maxSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address account, uint256 amount) external returns (bool);
    function toast(uint256 amount) external returns (bool);
    function rebase() external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IBurnVault {
    function deposit(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IGmtIou {
    function mint(address account, uint256 amount) external returns (bool);
}