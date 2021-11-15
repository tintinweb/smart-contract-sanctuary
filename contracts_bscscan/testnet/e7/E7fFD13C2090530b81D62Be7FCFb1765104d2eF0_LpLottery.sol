// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lottery {
    using SafeMath for uint256;

    uint256 private prizeValue;
    address private manager;
    uint256 private entriesRequired;
    uint256 private currentTicketId;
    bool private isActive;
    mapping(uint256 => address) allParticipants;

    constructor(uint256 _prizeValue, address _manager) {
        prizeValue = _prizeValue;
        entriesRequired = _prizeValue.div(10**18);
        manager = _manager;
        isActive = true;
    }

    function participate(uint256 _amount, address _particpant) public {
        require(entriesRequired != 0, "context is full");
        require(isActive, "context is not active anymore");

        uint256 _tickets = _amount.div(10**18);
        require(
            entriesRequired >= _tickets,
            "entree fee should be smaller than entries required"
        );
        for (uint256 i = 0; i < _tickets; i++) {
            allParticipants[currentTicketId] = _particpant;
            currentTicketId++;
        }
        entriesRequired = entriesRequired.sub(_tickets);
        emit PlayerParticipated(_particpant);
    }

    function declareWinner() public restricted returns(address){
        require(isActive,"Context is not active anymore");
        require(entriesRequired == 0, "context is not full yet");
        isActive = false;
        uint256 winnerTicketNo = random().mod(prizeValue.div(10**18));
        return allParticipants[winnerTicketNo];
    }

    function getEntriesRequired() public view returns(uint256){
        return entriesRequired;
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        prizeValue
                    )
                )
            );
    }

    function getPrizeValue() public view returns(uint256) {
        return prizeValue;
    }
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    event PlayerParticipated(
        address playerAddress
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PancakeClass.sol";
import "./Lottery.sol";

contract LpLottery is PancakeClass {
    address private admin;
    uint256 private lotteryId;
    mapping(uint256 => Lottery) public lotteryStructs;
    mapping(uint256 => bool) public lotteryWinnerDeclared;
    mapping(uint256 => address) private lotteryWinner;

    using SafeMath for uint256;

    constructor(
        address _routerAddres,
        address _tokenSafeMars,
        address _tokenBUSD
    ) PancakeClass(_routerAddres, _tokenSafeMars, _tokenBUSD) {
        admin = msg.sender;
    }

    function transferOwnership(address newManger) public restricted {
        admin=newManger;
    }

    function createContext(uint256 _prizeValue) public restricted {
       lotteryStructs[lotteryId] = new Lottery(_prizeValue, address(this));
       lotteryId++;
       emit LotteryCreated(lotteryId);
    }

    function declareWinner(uint256 _lotteryId) public restricted {
        require(!lotteryWinnerDeclared[_lotteryId], "Winner already declared");
        lotteryWinnerDeclared[_lotteryId] = true;
        address winner = lotteryStructs[_lotteryId].declareWinner();
        lotteryWinner[_lotteryId]=winner;
        uint256 tokensGetInSafemars = convertBUSDToSafeMars(lotteryStructs[_lotteryId].getPrizeValue());
        IERC20(tokenSafeMars).transfer(winner, tokensGetInSafemars);
    }

    function getEntriesRequired(uint256 _lotteryId) public view returns(uint256){
        return lotteryStructs[_lotteryId].getEntriesRequired();
    }

    function viewWinner(uint256 _lotteryId) public view returns(address) {
        require(lotteryWinnerDeclared[_lotteryId], "Winner is not declared yet");
        return lotteryWinner[_lotteryId];
    }

    function participateInBusd(uint256 _lotteryId, uint256 amount) public nonReentrant {
        IERC20(tokenBUSD).transferFrom(msg.sender, address(this), amount);

        uint256 entryFee = amount.mul(4).div(100);
        lotteryStructs[_lotteryId].participate(entryFee, msg.sender);
        uint256 stakingAmount = amount.sub(entryFee);
        stakeInBUSD(stakingAmount, msg.sender);
    }

    function participateInSafemars(uint256 _lotteryId, uint256 amount) public nonReentrant {
        uint256 initBalance = IERC20(tokenSafeMars).balanceOf(address(this));
        IERC20(tokenSafeMars).transferFrom(msg.sender, address(this), amount);
        amount = IERC20(tokenSafeMars).balanceOf(address(this)).sub(initBalance);
        
        uint256 entryFee = amount.mul(4).div(100);
        uint256 tokensGetInBusd = convertSafeMarsToBUSD(entryFee);
        lotteryStructs[_lotteryId].participate(tokensGetInBusd, msg.sender);

        uint256 stakingAmount = amount.sub(entryFee);
        stakeInSafeMars(stakingAmount, msg.sender);
    }

    function exit(uint256 _lotteryId) public nonReentrant {
        require(lotteryWinnerDeclared[_lotteryId], "Winner not declared");
        unstakeAllToSafeMars(msg.sender);
    }

    modifier restricted() {
        require(msg.sender == admin);
        _;
    }

    event LotteryCreated(
        uint256 lotteryId
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./PancakeInterfaces/IPancakeRouter02.sol";
import "./PancakeInterfaces/IPancakeFactory.sol";
import "./PancakeInterfaces/IPancakePair.sol";

contract PancakeClass is ReentrancyGuard {
    using SafeMath for uint256;

    IPancakeRouter02 public router;
    address public tokenSafeMars;
    address public tokenBUSD;

    struct UserBalance {
        uint256 balanceSafeMars;
        uint256 balanceBUSD;
        uint256 balanceLP;
    } mapping(address => UserBalance) internal allUserBalance;

    constructor(
        address _routerAddres,
        address _tokenSafeMars,
        address _tokenBUSD
    ) {
        router = IPancakeRouter02(_routerAddres);
        tokenSafeMars = _tokenSafeMars;
        tokenBUSD = _tokenBUSD;
    }

    function stakeInSafeMars(uint256 amount, address account) internal {
        uint256 oneHalf = amount.div(2);
        uint256 anoterHalf = amount.sub(oneHalf);
        uint256 tokensGet = _sellXGetY(tokenSafeMars, tokenBUSD, anoterHalf);

        _addLiquidity(oneHalf, tokensGet, account);
    }

    function stakeInBUSD(uint256 amount, address account) internal {
        uint256 oneHalf = amount.div(2);
        uint256 anoterHalf = amount.sub(oneHalf);
        uint256 tokensGet = _sellXGetY(tokenBUSD, tokenSafeMars, anoterHalf);

        _addLiquidity(tokensGet, oneHalf, account);
    }

    function unstakeAllToSafeMars(address account) internal {
        UserBalance storage usrBal = allUserBalance[account];
        (uint256 _amountSafeMars, uint256 _amountBUSD) = _removeLiquidity(usrBal.balanceLP);
        uint256 out = _sellXGetY(tokenBUSD, tokenSafeMars, _amountBUSD);
        usrBal.balanceBUSD = 0;
        usrBal.balanceSafeMars = 0;
        usrBal.balanceLP = 0;
        out = out.add(_amountSafeMars);
        IERC20(tokenSafeMars).transfer(account, out);
    }

    function convertBUSDToSafeMars(uint256 _amountIn) internal returns(uint256 amountOut) {
        return _sellXGetY(tokenBUSD, tokenSafeMars, _amountIn);
    }

    function convertSafeMarsToBUSD(uint256 _amountIn) internal returns(uint256 amountOut) {
        return _sellXGetY(tokenSafeMars, tokenBUSD, _amountIn);
    }

    function _addLiquidity(uint256 _amountSafeMars, uint256 _amountBUSD, address account) private {
        IERC20(tokenSafeMars).approve(address(router), _amountSafeMars);
        IERC20(tokenBUSD).approve(address(router), _amountBUSD);

        uint256 bal = IERC20(_getPairAddress()).balanceOf(address(this));
        router.addLiquidity(
            tokenSafeMars, 
            tokenBUSD, 
            _amountSafeMars, 
            _amountBUSD, 
            0, 
            0, 
            address(this), 
            block.timestamp + 360
        );
        uint256 bal2 = IERC20(_getPairAddress()).balanceOf(address(this));
        uint256 _liquidity = bal2.sub(bal);

        UserBalance storage usrBal = allUserBalance[account];
        usrBal.balanceLP = (usrBal.balanceLP).add(_liquidity);
    }

    function _removeLiquidity(uint256 _liquidity) private returns(uint256 _amountSafeMars, uint256 _amountBUSD) {
        IERC20(_getPairAddress()).approve(address(router), _liquidity);
        uint256 balY = IERC20(tokenSafeMars).balanceOf(address(this));
        (, _amountBUSD) = router.removeLiquidity(
            tokenSafeMars, 
            tokenBUSD, 
            _liquidity, 
            0, 
            0, 
            address(this), 
            block.timestamp + 360
        );
        uint256 balY2 = IERC20(tokenSafeMars).balanceOf(address(this));
        _amountSafeMars = balY2.sub(balY);
    }

    function _sellXGetY(address _tokenXAddress, address _tokenYAddress, uint256 _amountXIn) private returns(uint256 _amountYOut) {
        IERC20(_tokenXAddress).approve(address(router), _amountXIn);

        address[] memory path = new address[](2);
        path[0] = _tokenXAddress;
        path[1] = _tokenYAddress;

        uint256 balY = IERC20(_tokenYAddress).balanceOf(address(this));
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountXIn,
            0,
            path,
            address(this),
            block.timestamp + 60
        );
        uint256 balY2 = IERC20(_tokenYAddress).balanceOf(address(this));
        _amountYOut = balY2.sub(balY);
    }

    function _getPairAddress() private view returns(address) {
        IPancakeFactory factory = IPancakeFactory(router.factory());
        IPancakePair pair = IPancakePair(factory.getPair(tokenSafeMars, tokenBUSD));
        return address(pair);
    }

    function _isSafeMarsTokenA() private view returns(bool) {
        return (tokenSafeMars < tokenBUSD) ? true : false;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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

