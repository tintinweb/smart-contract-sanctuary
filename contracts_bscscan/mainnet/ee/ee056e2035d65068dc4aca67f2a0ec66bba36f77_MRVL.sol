pragma solidity 0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

contract MRVL is Context, IERC20, Ownable {

    mapping(address => uint) private _reflectionOwned;
    mapping(address => uint) private _actualOwned;
    mapping(address => mapping(address => uint)) private _allowances;

    mapping(address => Excluded) private _isExcluded;

    address[] private _excluded;

    uint constant public divider = 1e4;

    string constant private _name = 'Marvel Geek Coin';
    string constant private _symbol = 'MRVL';
    uint8 constant private _decimals = 18;

    uint constant private MAX = type(uint).max;
    uint constant private _actualTotal = 2500000000000 * (10 ** _decimals);
    uint private _reflectionTotal = (MAX - (MAX % _actualTotal));

    struct Excluded {
        bool fromFee;
        bool fromReward;
    }

    struct Fees {
        uint32 socialFee;
        uint32 previousSocialFee;
        uint32 lotteryFee;
        uint32 previousLotteryFee;
    }

    Fees public fees;

    event SentToWinner(address _winner, uint amount);
    event SocialFeeSet(uint fee);
    event LotteryFeeSet(uint fee);
    event ExcludedFromFee(address account);
    event IncludedInFee(address account);

    constructor(uint _lotteryFee, address _router) {
        // 5%
        setSocialFeePercent(500);
        setLotteryFeePercent(_lotteryFee);

        _reflectionOwned[_msgSender()] = _reflectionTotal;

        IUniswapV2Router02 _uniswapV2Router =
            IUniswapV2Router02(_router);

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcluded[owner()].fromFee = true;
        _isExcluded[address(this)].fromFee = true;
        _isExcluded[_uniswapV2Pair].fromFee = true;
        _isExcluded[_router].fromFee = true;
        excludeFromReward(address(this));
        excludeFromReward(_uniswapV2Pair);

        emit Transfer(address(0), _msgSender(), _actualTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint) {
        return _actualTotal;
    }

    function balanceOf(address account) public view override returns (uint) {
        if (_isExcluded[account].fromReward) return _actualOwned[account];
        return tokenFromReflection(_reflectionOwned[account]);
    }

    function transfer(address recipient, uint amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function deliver(uint actualAmount) external {
        address sender = _msgSender();
        require(
            !_isExcluded[sender].fromReward,
            "Excluded addresses cannot call this function"
        );
        (uint reflectionAmount, , , , ) = _getValues(actualAmount);
        _reflectionOwned[sender] = _reflectionOwned[sender] - reflectionAmount;
        _reflectionTotal = _reflectionTotal - reflectionAmount;
    }

    function reflectionFromToken(uint actualAmount, bool deductTransferFee)
        external
        view
        returns (uint)
    {
        require(actualAmount <= _actualTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint reflectionAmount, , , , ) = _getValues(actualAmount);
            return reflectionAmount;
        } else {
            (, uint reflectionTransferAmount, , , ) = _getValues(actualAmount);
            return reflectionTransferAmount;
        }
    }

    function tokenFromReflection(uint reflectionAmount)
        public
        view
        returns (uint)
    {
        require(
            reflectionAmount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );
        uint currentRate = _getRate();
        return reflectionAmount / currentRate;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account].fromReward;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account].fromReward, "Account is already excluded");
        if (_reflectionOwned[account] > 0) {
            _actualOwned[account] = tokenFromReflection(_reflectionOwned[account]);
        }
        _isExcluded[account].fromReward = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account].fromReward, "Account is already excluded");
        for (uint i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _actualOwned[account] = 0;
                _isExcluded[account].fromReward = false;
                _excluded.pop();
                break;
            }
        }
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcluded[account].fromFee;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcluded[account].fromFee = true;
        emit ExcludedFromFee(account);
    }

    function includeInFee(address account) external onlyOwner {
        _isExcluded[account].fromFee = false;
        emit IncludedInFee(account);
    }

    function setSocialFeePercent(uint _socialFee) public onlyOwner {
        require(_socialFee <= divider, 'Fee can not be more than 100%');
        fees.socialFee = uint32(_socialFee);
        emit SocialFeeSet(fees.socialFee);
    }

    function setLotteryFeePercent(uint _lotteryFee) public onlyOwner {
        require(_lotteryFee <= divider, 'Fee can not be more than 100%');
        fees.lotteryFee = uint32(_lotteryFee);
        emit LotteryFeeSet(fees.lotteryFee);
    }

    function _takeSocialFee(uint reflectionSocialFee) private {
        _reflectionTotal = _reflectionTotal - reflectionSocialFee;
    }

    function _takeLotteryFee(uint actualLottery) private {
        uint currentRate = _getRate();
        uint reflectionLottery = actualLottery * currentRate;
        _reflectionOwned[address(this)] = _reflectionOwned[address(this)] + reflectionLottery;
        if (_isExcluded[address(this)].fromReward)
            _actualOwned[address(this)] = _actualOwned[address(this)] + actualLottery;
    }

    function _calculateSocialFee(uint _amount) private view returns (uint) {
        return _amount * fees.socialFee / divider;
    }

    function _calculateLotteryFee(uint _amount) private view returns (uint) {
        return _amount * fees.lotteryFee / divider;
    }



    function _getValues(uint actualAmount)
        private
        view
        returns (
            uint,
            uint,
            uint,
            uint,
            uint
        )
    {
        (uint actualTransferAmount, uint actualSocialFee, uint actualLottery) =
            _getActualValues(actualAmount);
        (uint reflectionAmount, uint reflectionTransferAmount, uint reflectionSocialFee) =
            _getReflectedValues(actualAmount, actualSocialFee, actualLottery, _getRate());
        return (
            reflectionAmount,
            reflectionTransferAmount,
            reflectionSocialFee,
            actualTransferAmount,
            actualLottery
        );
    }

    function _getActualValues(uint actualAmount)
        private
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        uint actualSocialFee = _calculateSocialFee(actualAmount);
        uint actualLottery = _calculateLotteryFee(actualAmount);
        uint actualTransferAmount = actualAmount - actualSocialFee - actualLottery;
        return (actualTransferAmount, actualSocialFee, actualLottery);
    }

    function _getReflectedValues(
        uint actualAmount,
        uint actualSocialFee,
        uint actualLottery,
        uint currentRate
    )
        private
        pure
        returns (
            uint,
            uint,
            uint
        )
    {
        uint reflectionAmount = actualAmount * currentRate;
        uint reflectionSocialFee = actualSocialFee * currentRate;
        uint reflectionLottery = actualLottery * currentRate;
        uint reflectionTransferAmount = reflectionAmount - reflectionSocialFee - reflectionLottery;
        return (reflectionAmount, reflectionTransferAmount, reflectionSocialFee);
    }

    function _getRate() private view returns (uint) {
        (uint reflectionSupply, uint actualSupply) = _getCurrentSupply();
        return reflectionSupply / actualSupply;
    }

    function _getCurrentSupply() private view returns (uint, uint) {
        uint reflectionSupply = _reflectionTotal;
        uint actualSupply = _actualTotal;
        for (uint i = 0; i < _excluded.length; i++) {
            if (
                _reflectionOwned[_excluded[i]] > reflectionSupply ||
                _actualOwned[_excluded[i]] > actualSupply
            ) return (_reflectionTotal, _actualTotal);
            reflectionSupply = reflectionSupply - _reflectionOwned[_excluded[i]];
            actualSupply = actualSupply - _actualOwned[_excluded[i]];
        }
        if (reflectionSupply < _reflectionTotal / _actualTotal) return (_reflectionTotal, _actualTotal);
        return (reflectionSupply, actualSupply);
    }

    function sendToWinner(address _winner) external onlyOwner {
        uint amount = balanceOf(address(this));

        _transfer(address(this), _winner, amount);
        emit SentToWinner(_winner, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;

        if (_isExcluded[from].fromFee || _isExcluded[to].fromFee) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint amount,
        bool takeFee
    ) private {
        if (!takeFee) _removeAllFee();

        bool isSenderExcluded = _isExcluded[sender].fromReward;
        bool isRecipientExcluded = _isExcluded[recipient].fromReward;

        if (!isSenderExcluded && !isRecipientExcluded) {
            _transferStandard(sender, recipient, amount);
        } else if (!isSenderExcluded && isRecipientExcluded) {
            _transferToExcluded(sender, recipient, amount);
        } else if (isSenderExcluded && !isRecipientExcluded) {
            _transferFromExcluded(sender, recipient, amount);
        } else {
            _transferBothExcluded(sender, recipient, amount);
        }

        if (!takeFee) _restoreAllFee();
    }

    function _removeAllFee() private {
        if (fees.socialFee == 0 && fees.lotteryFee == 0) return;

        fees.previousSocialFee = fees.socialFee;
        fees.previousLotteryFee = fees.lotteryFee;

        fees.socialFee = 0;
        fees.lotteryFee = 0;
    }

    function _restoreAllFee() private {
        fees.socialFee = fees.previousSocialFee;
        fees.lotteryFee = fees.previousLotteryFee;
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint actualAmount
    ) private {
        (
            uint reflectionAmount,
            uint reflectionTransferAmount,
            uint reflectionSocialFee,
            uint actualTransferAmount,
            uint actualLottery
        ) = _getValues(actualAmount);
        _reflectionOwned[sender] = _reflectionOwned[sender] - reflectionAmount;
        _reflectionOwned[recipient] = _reflectionOwned[recipient] + reflectionTransferAmount;
        _takeLotteryFee(actualLottery);
        _takeSocialFee(reflectionSocialFee);
        emit Transfer(sender, recipient, actualTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint actualAmount
    ) private {
        (
            uint reflectionAmount,
            uint reflectionTransferAmount,
            uint reflectionSocialFee,
            uint actualTransferAmount,
            uint actualLottery
        ) = _getValues(actualAmount);
        _reflectionOwned[sender] = _reflectionOwned[sender] - reflectionAmount;
        _actualOwned[recipient] = _actualOwned[recipient] + actualTransferAmount;
        _reflectionOwned[recipient] = _reflectionOwned[recipient] + reflectionTransferAmount;
        _takeLotteryFee(actualLottery);
        _takeSocialFee(reflectionSocialFee);
        emit Transfer(sender, recipient, actualTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint actualAmount
    ) private {
        (
            uint reflectionAmount,
            uint reflectionTransferAmount,
            uint reflectionSocialFee,
            uint actualTransferAmount,
            uint actualLottery
        ) = _getValues(actualAmount);
        _actualOwned[sender] = _actualOwned[sender] - actualAmount;
        _reflectionOwned[sender] = _reflectionOwned[sender] - reflectionAmount;
        _reflectionOwned[recipient] = _reflectionOwned[recipient] + reflectionTransferAmount;
        _takeLotteryFee(actualLottery);
        _takeSocialFee(reflectionSocialFee);
        emit Transfer(sender, recipient, actualTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint actualAmount
    ) private {
        (
            uint reflectionAmount,
            uint reflectionTransferAmount,
            uint reflectionSocialFee,
            uint actualTransferAmount,
            uint actualLottery
        ) = _getValues(actualAmount);
        _actualOwned[sender] = _actualOwned[sender] - actualAmount;
        _reflectionOwned[sender] = _reflectionOwned[sender] - reflectionAmount;
        _actualOwned[recipient] = _actualOwned[recipient] + actualTransferAmount;
        _reflectionOwned[recipient] = _reflectionOwned[recipient] + reflectionTransferAmount;
        _takeLotteryFee(actualLottery);
        _takeSocialFee(reflectionSocialFee);
        emit Transfer(sender, recipient, actualTransferAmount);
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

