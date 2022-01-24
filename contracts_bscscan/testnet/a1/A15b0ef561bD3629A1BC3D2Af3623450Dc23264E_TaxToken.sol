// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "ERC20.sol";
import "IERC20.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "IUniswapV2Router02.sol";
import "IUniswapV2Factory.sol";

contract TaxToken is Ownable, ERC20 {
    using SafeMath for uint256;

    uint256 public buyTax;
    uint256 public sellTax;
    uint256 public transferTax;

    uint256 public prevBuyTax;
    uint256 public prevSellTax;
    uint256 public prevTransferTax;

    uint256 public TotalReflections;
    uint256 public ContractTokenBalance;

    uint256 private supply = 1000000 * 10**18;
    uint256 private MAX = ~uint256(0);
    uint256 private accSupply = MAX - (MAX % supply);

    mapping(address => bool) private ExcludedFromReflections;
    mapping(address => bool) private ExcludedFromFee;
    address[] private _excludedRef;
    address[] private _excludedFee;
    mapping(address => uint256) private supplyBalance;
    mapping(address => uint256) private accSupplyBalance;
    IUniswapV2Router02 _uniswapRouter;
    address public immutable _uniswapPair;

    event Sell(address from, address to, uint256 amount);
    event Buy(address from, address to, uint256 amount);
    event NLTransfer(address from, address to, uint256 amount);

    constructor() ERC20("Safemoon", "SFM") {
        //making an instance of pancakeswap contract
        IUniswapV2Router02 _uniswapRouter02 = IUniswapV2Router02(
            0xDE2Db97D54a3c3B008a097B2260633E6cA7DB1AF
        );
        //making the pair
        _uniswapPair = IUniswapV2Factory(_uniswapRouter02.factory()).createPair(
                address(this),
                _uniswapRouter02.WETH()
            );
        _uniswapRouter = _uniswapRouter02;
        ExcludeFromFees(_msgSender());
        ExcludeFromFees(address(this));
        _mint(_msgSender(), 1000000 * 10**18);
        supplyBalance[_msgSender()] = supply;
        accSupplyBalance[_msgSender()] = accSupply;
    }

    function setAllTaxes(
        uint256 SellTax,
        uint256 BuyTax,
        uint256 TransferTax
    ) external onlyOwner {
        sellTax = SellTax;
        buyTax = BuyTax;
        transferTax = TransferTax;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (ExcludedFromReflections[account]) {
            return supplyBalance[account];
        }
        return accurateBalanceToNormalBalance(accSupplyBalance[account]);
    }

    function accurateBalanceToNormalBalance(uint256 balance)
        public
        view
        returns (uint256)
    {
        require(balance <= accSupply, "amount must be less than total supply!");
        return balance / getRate();
    }

    function getRate() public view returns (uint256) {
        (uint256 nSupply, uint256 aSupply) = getCurrentSupply();
        return aSupply / nSupply;
    }

    function getCurrentSupply() public view returns (uint256, uint256) {
        uint256 nSupply = supply;
        uint256 aSupply = accSupply;
        for (uint256 i = 0; i < _excludedRef.length; i++) {
            if (
                accSupplyBalance[_excludedRef[i]] > aSupply ||
                supplyBalance[_excludedRef[i]] > nSupply
            ) return (supply, accSupply);
            nSupply = nSupply.sub(supplyBalance[_excludedRef[i]]);
            aSupply = aSupply.sub(accSupplyBalance[_excludedRef[i]]);
        }
        if (aSupply < accSupply / supply) return (supply, accSupply);
        return (nSupply, aSupply);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        if (sender == _uniswapPair) emit Buy(sender, recipient, amount);
        if (recipient == _uniswapPair) emit Sell(sender, recipient, amount);
        if (sender != _uniswapPair && recipient != _uniswapPair)
            emit NLTransfer(sender, recipient, amount);

        uint256 senderBalance = balanceOf(sender);
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        bool takeFee = true;

        if (isExcludedFromFees(sender)) {
            takeFee = false;
        }

        _transferToken(sender, recipient, amount, takeFee);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _transferToken(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        //considering being excluded from reflections or not
        if (!takeFee) {
            DeleteFees();
        }

        if (isExcludedFromReflections(sender)) {
            _transferFromExcluded(sender, recipient, amount);
        }

        if (isExcludedFromReflections(recipient)) {
            _transferToExcluded(sender, recipient, amount);
        }

        if (
            isExcludedFromReflections(sender) &&
            isExcludedFromReflections(recipient)
        ) {
            _transferBothExcluded(sender, recipient, amount);
        }

        restoreFees();

        _transferStandard(sender, recipient, amount);
    }

    function DeleteFees() internal {
        prevBuyTax = buyTax;
        prevSellTax = sellTax;
        prevTransferTax = transferTax;
        buyTax = 0;
        sellTax = 0;
        transferTax = 0;
    }

    function restoreFees() internal {
        buyTax = prevBuyTax;
        sellTax = prevSellTax;
        transferTax = prevTransferTax;
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        (
            uint256 tAmount,
            uint256 nTransferAmount,
            uint256 nFee,
            uint256 aAmount,
            uint256 aTransferAmount,
            uint256 aFee
        ) = getValues(amount);

        supplyBalance[sender] = supplyBalance[sender].sub(tAmount);
        accSupplyBalance[sender] = accSupplyBalance[sender].sub(aAmount);
        accSupplyBalance[recipient] = accSupplyBalance[recipient].add(
            aTransferAmount
        );
        HandleFees(nFee, aFee);
        emit Transfer(sender, recipient, nTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        (
            ,
            uint256 nTransferAmount,
            uint256 nFee,
            uint256 aAmount,
            uint256 aTransferAmount,
            uint256 aFee
        ) = getValues(amount);

        accSupplyBalance[sender] = accSupplyBalance[sender].sub(aAmount);
        accSupplyBalance[recipient] = accSupplyBalance[recipient].add(
            aTransferAmount
        );
        supplyBalance[recipient] = supplyBalance[recipient].add(
            nTransferAmount
        );
        HandleFees(nFee, aFee);
        emit Transfer(sender, recipient, nTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        (
            uint256 tAmount,
            uint256 nTransferAmount,
            uint256 nFee,
            uint256 aAmount,
            uint256 aTransferAmount,
            uint256 aFee
        ) = getValues(amount);
        supplyBalance[sender] = supplyBalance[sender].sub(tAmount);
        accSupplyBalance[sender] = accSupplyBalance[sender].sub(aAmount);
        accSupplyBalance[recipient] = accSupplyBalance[recipient].add(
            aTransferAmount
        );
        supplyBalance[recipient] = supplyBalance[recipient].add(
            nTransferAmount
        );
        emit Transfer(sender, recipient, nTransferAmount);
        HandleFees(nFee, aFee);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        (
            ,
            uint256 nTransferAmount,
            uint256 nFee,
            uint256 aAmount,
            uint256 aTransferAmount,
            uint256 aFee
        ) = getValues(amount);
        accSupplyBalance[sender] = accSupplyBalance[sender].sub(aAmount);
        accSupplyBalance[recipient] = accSupplyBalance[recipient].add(
            aTransferAmount
        );
        emit Transfer(sender, recipient, nTransferAmount);
        HandleFees(nFee, aFee);
    }

    function isExcludedFromReflections(address account)
        public
        view
        returns (bool)
    {
        return ExcludedFromReflections[account];
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return ExcludedFromFee[account];
    }

    function ExcludeFromReflections(address account) public onlyOwner {
        ExcludedFromReflections[account] = true;
        _excludedRef.push(account);
    }

    function ExcludeFromFees(address account) public onlyOwner {
        ExcludedFromFee[account] = true;
        _excludedFee.push(account);
    }

    function IncludeInReflections(address account) public onlyOwner {
        require(
            ExcludedFromReflections[account] == true,
            "account is already included!"
        );
        for (uint256 i = 0; i < _excludedRef.length; i++) {
            if (_excludedRef[i] == account) {
                _excludedRef[i] = _excludedRef[_excludedRef.length - 1];
                supplyBalance[account] = 0;
                ExcludedFromReflections[account] = false;
                _excludedRef.pop();
                break;
            }
        }
    }

    function IncludeInFees(address account) public onlyOwner {
        ExcludedFromFee[account] = false;
    }

    function HandleFees(uint256 nFee, uint256 aFee) private {
        //Reflections(80% of fees)
        uint256 aReflections = ((aFee * 80) / 100);
        uint256 nReflections = ((nFee * 80) / 100);
        accSupply = accSupply - aReflections;
        TotalReflections = TotalReflections.add(nReflections);

        //Liquidity(20% of Fees)
        uint256 nAmountForLiquify = ((nFee * 20) / 100);
        uint256 aAmountForLiquify = ((aFee * 20) / 100);
        ContractTokenBalance = ContractTokenBalance + nAmountForLiquify;
        supplyBalance[address(this)] =
            supplyBalance[address(this)] +
            nAmountForLiquify;
        accSupplyBalance[address(this)] =
            accSupplyBalance[address(this)] +
            aAmountForLiquify;
    }

    function getValues(uint256 tAmount)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 nTransferAmount, uint256 nFee) = getnValues(tAmount);

        (uint256 aAmount, uint256 aTransferAmount, uint256 aFee) = getaValues(
            tAmount,
            nTransferAmount,
            nFee,
            getRate()
        );
        return (tAmount, nTransferAmount, nFee, aAmount, aTransferAmount, aFee);
    }

    function getnValues(uint256 tAmount)
        public
        view
        returns (uint256, uint256)
    {
        //nTransferAmount
        //nFee
        uint256 nFee = calculateTax(tAmount);
        uint256 nTransferAmount = tAmount.sub(nFee);
        return (nTransferAmount, nFee);
    }

    function getaValues(
        uint256 nAmount,
        uint256 nTransferAmount,
        uint256 nFee,
        uint256 rate
    )
        public
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 aAmount = nAmount.mul(rate);
        uint256 aTransferAmount = nTransferAmount.mul(rate);
        uint256 aFee = nFee.mul(rate);
        return (aAmount, aTransferAmount, aFee);
    }

    function calculateTax(uint256 tAmount) public view returns (uint256) {
        uint256 totalTax = buyTax + sellTax + transferTax;
        return (tAmount * totalTax) / 100;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";
import "SafeMath.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

pragma solidity >=0.6.2;

import "IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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