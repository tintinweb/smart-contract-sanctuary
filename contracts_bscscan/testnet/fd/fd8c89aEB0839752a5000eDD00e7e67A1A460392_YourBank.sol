// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./GildToken.sol";

// import "hardhat/console.sol";

contract YourBank {
    using SafeMath for uint256;

    uint256 public constant MAX_BORROW = 7000;
    uint256 public constant LIQUIDATE_BPS = 500;
    uint256 public appID;
    uint256 public borrowID;
    address public dev;
    address public router;
    GildToken public gildToken;

    struct LoanApplication {
        uint256 id;
        address owner;
        address loanToken;
        uint256 loanAmount;
        address[] availableCollateralTokens;
        uint256[] interestRates;
        uint256[] durations;
        bool openNewLoan;
    }

    struct Borrow {
        uint256 appID;
        address owner;
        address collateralToken;
        uint256 collateralAmount;
        uint256 borrowAmount;
        uint256 startBlock;
        uint256 interestRate;
        uint256 duration;
        uint256 dueDateBlock;
        uint256 lastPayBlock;
        bool open;
    }

    // appID => LoanApplication
    mapping(uint256 => LoanApplication) public loanApplications;

    // owner => LoanApplication []
    mapping(address => LoanApplication[]) public myLoanApplications;

    // borrowID = > Loan
    mapping(uint256 => Borrow) public borrows;

    // borrower address
    mapping(address => Borrow[]) public myBorrows;

    event CreateLoanApp(uint256 loanID);
    event UpdateLoanApp();
    event DepositLoan();
    event WithdrawLoan();
    event CreateBorrow(uint256 borrowID);
    event DepositCollateral();
    event WithdrawCollateral();
    event Repay(uint256 principal, uint256 interest);
    event Liquidate();

    constructor(
        address _router,
        address _dev,
        GildToken _gildToken
    ) {
        router = _router;
        appID = 0;
        borrowID = 0;
        dev = _dev;
        gildToken = _gildToken;
    }

    modifier transferToBank(address token, uint256 value) {
        if (token == address(0)) {
            require(msg.value == value, "r1");
        } else {
            IERC20(token).transferFrom(
                address(msg.sender),
                address(this),
                value
            );
        }
        _;
    }

    function isDuplicatedLoanApplication(address _loanToken)
        public
        view
        returns (bool)
    {
        LoanApplication[] memory myApps = myLoanApplications[msg.sender];
        uint256 length = myApps.length;
        for (uint256 i = 0; i < length; i++) {
            if (myApps[i].loanToken == _loanToken) {
                return true;
            }
        }
        return false;
    }

    function createLoanApp(
        address _loanToken,
        uint256 _loanAmount,
        address[] calldata _availableCollateralTokens,
        uint256[] calldata _interestRates,
        uint256[] calldata _durations
    ) public payable transferToBank(_loanToken, _loanAmount) {
        require(!isDuplicatedLoanApplication(_loanToken), "r1");
        require(_interestRates.length == _durations.length, "r2");
        appID++;
        LoanApplication memory app = LoanApplication(
            appID,
            msg.sender,
            _loanToken,
            _loanAmount,
            _availableCollateralTokens,
            _interestRates,
            _durations,
            true
        );

        loanApplications[appID] = app;
        myLoanApplications[msg.sender].push(app);

        emit CreateLoanApp(appID);
    }

    function updateLoanApp(
        uint256 _id,
        address[] calldata _availableCollateralTokens,
        uint256[] calldata _interestRates,
        uint256[] calldata _durations
    ) public {
        LoanApplication storage app = loanApplications[_id];
        require(app.id == _id, "r1");
        require(app.owner == msg.sender, "r2");
        require(_interestRates.length == _durations.length, "r3");

        app.availableCollateralTokens = _availableCollateralTokens;
        app.interestRates = _interestRates;
        app.durations = _durations;

        LoanApplication[] memory myApps = myLoanApplications[msg.sender];
        uint256 length = myApps.length;
        uint256 index;
        for (uint256 i = 0; i < length; i++) {
            if (myApps[i].id == _id) {
                index = i;
                break;
            }
        }

        myLoanApplications[msg.sender][index] = app;
        emit UpdateLoanApp();
    }

    function getLoanApplications(address user)
        public
        view
        returns (LoanApplication[] memory myApps)
    {
        myApps = myLoanApplications[user];
        return myApps;
    }

    function depositLoan(
        uint256 _id,
        address loanToken,
        uint256 amount
    ) public payable transferToBank(loanToken, amount) {
        LoanApplication storage app = loanApplications[_id];
        require(app.loanToken == loanToken, "r1");
        require(app.owner == msg.sender, "r2");
        app.loanAmount = app.loanAmount.add(amount);
        emit DepositLoan();
    }

    function withdrawLoan(uint256 _id, uint256 amount) public {
        LoanApplication storage app = loanApplications[_id];
        require(app.owner == msg.sender, "r1");
        app.loanAmount = app.loanAmount.sub(amount);
        require(IERC20(app.loanToken).transfer(app.owner, amount), "r2");
        emit WithdrawLoan();
    }

    function borrow(
        uint256 _appID,
        address _collateralToken,
        uint256 _collateralAmount,
        uint256 _borrowAmount,
        uint256 _interestRate,
        uint256 _duration
    ) public payable transferToBank(_collateralToken, _collateralAmount) {
        LoanApplication storage app = loanApplications[_appID];
        require(app.loanToken != address(0), "r1");
        bool valid = false;
        for (uint256 i = 0; i < app.interestRates.length; i++) {
            if (
                app.interestRates[i] == _interestRate &&
                app.durations[i] == _duration
            ) {
                valid = true;
                break;
            }
        }
        require(valid, "r2");
        valid = false;
        for (uint256 i = 0; i < app.availableCollateralTokens.length; i++) {
            if (app.availableCollateralTokens[i] == _collateralToken) {
                valid = true;
                break;
            }
        }
        require(valid, "r3");
        borrowID++;
        address[] memory path = new address[](2);
        path[0] = _collateralToken;
        path[1] = app.loanToken;
        uint256 collateralPrice = price(_collateralAmount, path);
        uint256 max = collateralPrice.mul(MAX_BORROW).div(10000);
        require(_borrowAmount <= max, "r4");
        Borrow memory b = Borrow(
            app.id,
            msg.sender,
            _collateralToken,
            _collateralAmount,
            _borrowAmount,
            block.number,
            _interestRate,
            _duration,
            block.number + _duration,
            block.number,
            true
        );
        borrows[borrowID] = b;
        myBorrows[msg.sender].push(b);
        app.loanAmount = app.loanAmount.sub(_borrowAmount);
        // fix my loan app later
        require(
            IERC20(app.loanToken).transfer(msg.sender, _borrowAmount),
            "r5"
        );
        emit CreateBorrow(borrowID);
    }

    function interestAmount(uint256 bid) public view returns (uint256) {
        Borrow memory b = borrows[bid];
        if (block.number <= b.lastPayBlock) return 0;
        uint256 timePast = block.number.sub(b.lastPayBlock);
        uint256 totalInterest = b.borrowAmount.mul(b.interestRate).div(10000);
        uint256 currentInterest = totalInterest.mul(timePast).div(b.duration);
        return currentInterest;
    }

    function repay(
        uint256 bid,
        address loanToken,
        uint256 amount
    ) public {
        Borrow storage b = borrows[bid];
        LoanApplication memory app = loanApplications[b.appID];
        require(app.loanToken == loanToken, "r1");
        uint256 interest = interestAmount(bid);
        uint256 principal = 0;
        if (amount == 0 || amount > b.borrowAmount.add(interest)) {
            amount = b.borrowAmount.add(interest);
            principal = b.borrowAmount;
            b.borrowAmount = 0;
        } else if (amount > interest) {
            principal = amount.sub(interest);
            b.borrowAmount = b.borrowAmount.sub(principal);
        }
        loanApplications[b.appID].loanAmount = app.loanAmount.add(amount);
        gildToken.mint(app.owner, amount);
        gildToken.mint(b.owner, amount);
        gildToken.mint(dev, amount);
        require(
            IERC20(loanToken).transferFrom(
                address(msg.sender),
                address(this),
                amount
            ),
            "r2"
        );
        emit Repay(principal, interest);
    }

    function applicationDetail(uint256 id)
        public
        view
        returns (
            address[] memory collateralTokens,
            uint256[] memory interestRates,
            uint256[] memory durations
        )
    {
        return (
            loanApplications[id].availableCollateralTokens,
            loanApplications[id].interestRates,
            loanApplications[id].durations
        );
    }

    function depositCollateral(
        uint256 bid,
        address collateralToken,
        uint256 amount
    ) public payable transferToBank(collateralToken, amount) {
        Borrow storage b = borrows[bid];
        b.collateralAmount = b.collateralAmount.add(amount);
        emit DepositCollateral();
    }

    function withdrawCollateral(uint256 bid, uint256 amount) public {
        Borrow storage b = borrows[bid];
        b.collateralAmount = b.collateralAmount.sub(amount);
        LoanApplication memory app = loanApplications[b.appID];
        address[] memory path = new address[](2);
        path[0] = b.collateralToken;
        path[1] = app.loanToken;
        uint256 collateralPrice = price(b.collateralAmount, path);
        uint256 r = risk(b.borrowAmount, collateralPrice);
        require(r / 1 ether <= 80, "r1");
        require(IERC20(b.collateralToken).transfer(msg.sender, amount), "r2");
        emit WithdrawCollateral();
    }

    function risk(uint256 borrowAmount, uint256 collateralPrice)
        public
        pure
        returns (uint256)
    {
        return borrowAmount.mul(100).mul(1e18).div(collateralPrice);
    }

    function borrowRisk(uint256 bid) public view returns (uint256) {
        Borrow memory b = borrows[bid];
        LoanApplication memory app = loanApplications[b.appID];
        address[] memory path = new address[](2);
        path[0] = b.collateralToken;
        path[1] = app.loanToken;
        uint256 collateralPrice = price(b.collateralAmount, path);
        return risk(b.borrowAmount, collateralPrice);
    }

    function liquidate(uint256 bid) public {
        Borrow storage b = borrows[bid];
        LoanApplication storage app = loanApplications[b.appID];
        address[] memory path = new address[](2);
        path[0] = b.collateralToken;
        path[1] = app.loanToken;
        uint256 collateralPrice = price(b.collateralAmount, path);
        uint256 r = risk(b.borrowAmount, collateralPrice);
        require(r / 1 ether >= 80, "r1");
        uint256 interest = interestAmount(bid);
        uint256 toOwner = b.borrowAmount.add(interest);
        uint256 liquidatorPrize = toOwner.mul(LIQUIDATE_BPS).div(10000);
        uint256 devFees = toOwner.mul(LIQUIDATE_BPS).div(10000);
        uint256 prize = liquidatorPrize.add(devFees);
        uint256 total = toOwner.add(prize);
        path = new address[](2);
        path[0] = b.collateralToken;
        path[1] = app.loanToken;
        IERC20(b.collateralToken).approve(router, type(uint256).max);
        uint256 totalSwap = swapCollateralTokenToLoanToken(total, path);
        IERC20(b.collateralToken).approve(router, 0);
        app.loanAmount = app.loanAmount.add(totalSwap);
        gildToken.mint(app.owner, 1 ether);
        gildToken.mint(b.owner, 1 ether);
        gildToken.mint(msg.sender, 1 ether);
        gildToken.mint(dev, 1 ether);
        if (totalSwap <= toOwner) return;

        liquidatorPrize = totalSwap.mul(LIQUIDATE_BPS).div(10000);
        devFees = totalSwap.mul(LIQUIDATE_BPS).div(10000);
        if (liquidatorPrize > 0) {
            IERC20(app.loanToken).transfer(
                address(msg.sender),
                liquidatorPrize
            );
        }
        if (devFees > 0) IERC20(app.loanToken).transfer(dev, devFees);

        b.open = false;
        emit Liquidate();
    }

    function price(uint256 amountIn, address[] memory path)
        internal
        view
        returns (uint256)
    {
        return IPancakeRouter02(router).getAmountsOut(amountIn, path)[1];
    }

    function swapCollateralTokenToLoanToken(
        uint256 amountLoanOut,
        address[] memory path
    ) internal returns (uint256) {
        return
            IPancakeRouter02(router).swapTokensForExactTokens(
                amountLoanOut,
                IPancakeRouter02(router).getAmountsIn(amountLoanOut, path)[0],
                path,
                address(this),
                block.timestamp + 60
            )[1];
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IPancakeRouter02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GildToken is ERC20, Ownable {
    constructor() ERC20("Gild, you get only when you work", "GILD") {
        _mint(msg.sender, 1 ether);
    }

    // onlyOwner = bank
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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