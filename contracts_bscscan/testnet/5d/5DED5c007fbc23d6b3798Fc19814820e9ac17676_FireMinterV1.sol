// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./FireToken.sol";
import "./lib/Ownable.sol";

contract FireMinterV1 is Ownable {
    event TokenCreated(address indexed token, address indexed owner);

    uint256 public fee = 1 ether;

    uint8 public maxTaxFee = 10;

    uint8 public maxLiquidityFee = 10;

    uint8 public maxFundFee = 3;

    uint256 public minimumStartingLiquidity = 1 ether;

    function setFee(uint256 _fee) external onlyOwner() {
        fee = _fee;
    }

    function _pay(address payable _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "FME:7");
    }

    function withdraw() external onlyOwner() {
        _pay(payable(owner()), address(this).balance);
    }

    function setMaxTaxFee(uint8 _amount) external onlyOwner() {
        maxTaxFee = _amount;
    }

    function setMaxLiquidityFee(uint8 _amount) external onlyOwner() {
        maxLiquidityFee = _amount;
    }

    function setMaxFundFee(uint8 _amount) external onlyOwner() {
        maxFundFee = _amount;
    }

    function setMinimumStartingLiquidity(uint256 _amount) external onlyOwner() {
        minimumStartingLiquidity = _amount;
    }

    modifier createTokenGuard(
        CreateToken memory _token,
        uint256 _initialLiquidityAmount
    ) {
        require(_token.taxFee <= maxTaxFee, "FME:1");
        require(_token.liquidityFee <= maxLiquidityFee, "FME:2");
        require(_token.fundFee <= maxFundFee, "FME:3");
        require(_token.supply > _token.maxTxAmount, "FME:4");
        require(msg.value > fee + minimumStartingLiquidity, "FME:5");
        require(_initialLiquidityAmount > 0, "FME:6");
        _;
    }

    function createToken(
        CreateToken memory _token,
        address _newOwner,
        address _fund,
        uint256 _initialLiquidityAmount
    )
        external
        payable
        createTokenGuard(_token, _initialLiquidityAmount)
        returns (address)
    {
        FireToken token = new FireToken(
            _token,
            _initialLiquidityAmount,
            _newOwner,
            _fund
        );

        _pay(payable(token), msg.value - fee);

        token.initialize();

        token.transferOwnership(_newOwner);

        emit TokenCreated(address(token), _newOwner);
        return address(this);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./lib/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC20MetaData.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";

struct Token {
    string name;
    string symbol;
    uint8 decimals;
    uint256 supply;
    uint256 reflectionSupply;
    uint256 totalTokenFees;
    uint8 taxFee;
    uint8 liquidityFee;
    uint8 fundFee;
    uint256 maxTxAmount;
    uint256 numberTokensSellToAddToLiquidity;
}

struct CreateToken {
    string name;
    string symbol;
    uint8 decimals;
    uint256 supply;
    uint8 taxFee;
    uint8 liquidityFee;
    uint8 fundFee;
    uint256 maxTxAmount;
    uint256 numberTokensSellToAddToLiquidity;
}

contract FireToken is IERC20, IERC20Metadata, Ownable {
    Token token;

    event SwapAndLiquefy(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapAndLiquefyStateUpdate(bool state);

    mapping(address => uint256) private _reflectionBalance;

    mapping(address => bool) private _isExcludedFromFees;

    mapping(address => mapping(address => uint256)) private _allowances;

    bool public isSwapAndLiquifyingEnabled;

    bool private _swapAndLiquifyingInProgress;

    bool public startTrading;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2WETHPair;

    address public immutable fund;

    uint8 private _prevFundFee;
    uint8 private _prevTaxFee;
    uint8 private _prevLiquidityFee;

    uint256 initialLiquidityAmount;
    bool onlyOnce;

    bool public immutable isFireToken = true;

    constructor(
        CreateToken memory _token,
        uint256 _initialLiquidityAmount,
        address _newOwner,
        address _fund
    ) {
        uint256 MAX_INT_VALUE = type(uint256).max;

        token.name = _token.name;
        token.symbol = _token.symbol;
        token.decimals = _token.decimals;
        token.supply = _token.supply;
        token.reflectionSupply = (MAX_INT_VALUE -
            (MAX_INT_VALUE % _token.supply));
        token.taxFee = _token.taxFee;
        token.maxTxAmount = _token.maxTxAmount;
        token.numberTokensSellToAddToLiquidity = _token
        .numberTokensSellToAddToLiquidity;
        token.liquidityFee = _token.liquidityFee;
        token.fundFee = _token.fundFee;

        _reflectionBalance[_newOwner] =
            token.reflectionSupply -
            _reflectionFromToken(_initialLiquidityAmount);
        _reflectionBalance[address(this)] = _reflectionFromToken(
            _initialLiquidityAmount
        );

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        );

        uniswapV2WETHPair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        fund = _fund;

        initialLiquidityAmount = _initialLiquidityAmount;

        _isExcludedFromFees[_newOwner] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[_fund] = true;

        emit Transfer(address(0), _newOwner, _token.supply);
    }

    function initialize() external {
        assert(!onlyOnce);
        startTrading = true;
        onlyOnce = true;
        _addLiquidity(initialLiquidityAmount, address(this).balance);
        startTrading = false;
    }

    function name() public view override returns (string memory) {
        return token.name;
    }

    function symbol() public view override returns (string memory) {
        return token.symbol;
    }

    function decimals() public view override returns (uint8) {
        return token.decimals;
    }

    modifier lockTheSwap {
        _swapAndLiquifyingInProgress = true;
        _;
        _swapAndLiquifyingInProgress = false;
    }

    function totalSupply() external view override returns (uint256) {
        return token.supply;
    }

    function _getRate() private view returns (uint256) {
        return token.reflectionSupply / token.supply;
    }

    function _reflectionFromToken(uint256 amount)
        private
        view
        returns (uint256)
    {
        require(
            token.supply >= amount,
            "You cannot own more tokens than the total token supply"
        );
        return amount * _getRate();
    }

    function _tokenFromReflection(uint256 reflectionAmount)
        private
        view
        returns (uint256)
    {
        require(
            token.reflectionSupply >= reflectionAmount,
            "Cannot have a personal reflection amount larger than total reflection"
        );
        return reflectionAmount / _getRate();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tokenFromReflection(_reflectionBalance[account]);
    }

    function totalFees() external view returns (uint256) {
        return token.totalTokenFees;
    }

    function deliver(uint256 amount) public {
        address sender = _msgSender();
        uint256 reflectionAmount = _reflectionFromToken(amount);
        _reflectionBalance[sender] =
            _reflectionBalance[sender] -
            reflectionAmount;
        token.reflectionSupply -= reflectionAmount;
        token.totalTokenFees += amount;
    }

    function _removeAllFees() private {
        if (token.taxFee == 0 && token.liquidityFee == 0 && token.fundFee == 0)
            return;

        _prevFundFee = token.fundFee;
        _prevLiquidityFee = token.liquidityFee;
        _prevTaxFee = token.taxFee;

        token.taxFee = 0;
        token.liquidityFee = 0;
        token.fundFee = 0;
    }

    function _restoreAllFees() private {
        token.taxFee = _prevTaxFee;
        token.liquidityFee = _prevLiquidityFee;
        token.fundFee = _prevFundFee;
    }

    function enableSwapAndLiquifyingState() external onlyOwner() {
        isSwapAndLiquifyingEnabled = true;
        emit SwapAndLiquefyStateUpdate(true);
    }

    function _calculateFee(uint256 amount, uint8 fee)
        private
        pure
        returns (uint256)
    {
        return (amount * fee) / 100;
    }

    function _calculateTaxFee(uint256 amount) private view returns (uint256) {
        return _calculateFee(amount, token.taxFee);
    }

    function _calculateLiquidityFee(uint256 amount)
        private
        view
        returns (uint256)
    {
        return _calculateFee(amount, token.liquidityFee);
    }

    function _calculateFundFee(uint256 amount) private view returns (uint256) {
        return _calculateFee(amount, token.fundFee);
    }

    function _reflectFee(uint256 rfee, uint256 fee) private {
        token.reflectionSupply -= rfee;
        token.totalTokenFees += fee;
    }

    function _takeLiquidity(uint256 amount) private {
        _reflectionBalance[address(this)] =
            _reflectionBalance[address(this)] +
            _reflectionFromToken(amount);
    }

    receive() external payable {}

    function _transferToken(
        address sender,
        address recipient,
        uint256 amount,
        bool removeFees
    ) private {
        if (removeFees) _removeAllFees();

        uint256 rAmount = _reflectionFromToken(amount);

        _reflectionBalance[sender] = _reflectionBalance[sender] - rAmount;

        uint256 rTax = _reflectionFromToken(_calculateTaxFee(amount));

        uint256 rFundTax = _reflectionFromToken(_calculateFundFee(amount));

        uint256 rLiquidityTax = _reflectionFromToken(
            _calculateLiquidityFee(amount)
        );

        _reflectionBalance[recipient] =
            _reflectionBalance[recipient] +
            rAmount -
            rTax -
            rFundTax -
            rLiquidityTax;

        _reflectionBalance[fund] = _reflectionBalance[fund] + rFundTax;

        _takeLiquidity(rLiquidityTax);
        _reflectFee(
            rTax,
            _calculateTaxFee(amount) +
                _calculateFundFee(amount) +
                _calculateLiquidityFee(amount)
        );

        emit Transfer(
            sender,
            recipient,
            amount -
                _calculateLiquidityFee(amount) -
                _calculateFundFee(amount) -
                _calculateTaxFee(amount)
        );

        // Restores all fees if they were disabled.
        if (removeFees) _restoreAllFees();
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function _swapAndLiquefy() private lockTheSwap() {
        // split the contract token balance into halves
        uint256 half = token.numberTokensSellToAddToLiquidity / 2;
        uint256 otherHalf = token.numberTokensSellToAddToLiquidity - half;

        uint256 initialETHContractBalance = address(this).balance;

        // Buys ETH at current token price
        _swapTokensForEth(half);

        // This is to make sure we are only using ETH derived from the liquidity fee
        uint256 ethBought = address(this).balance - initialETHContractBalance;

        // Add liquidity to the pool
        _addLiquidity(otherHalf, ethBought);

        emit SwapAndLiquefy(half, ethBought, otherHalf);
    }

    function enableTrading() external onlyOwner() {
        startTrading = true;
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function excludeFromFees(address account) external onlyOwner() {
        _isExcludedFromFees[account] = true;
    }

    function includeInFees(address account) external onlyOwner() {
        _isExcludedFromFees[account] = false;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(
            sender != address(0),
            "ERC20: Sender cannot be the zero address"
        );
        require(
            recipient != address(0),
            "ERC20: Recipient cannot be the zero address"
        );
        require(amount > 0, "Transfer amount must be greater than zero");
        if (sender != owner() && recipient != owner()) {
            require(
                amount <= token.maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

            require(startTrading, "Nice try :)");
        }

        // Condition 1: Make sure the contract has the enough tokens to liquefy
        // Condition 2: We are not in a liquefication event
        // Condition 3: Liquification is enabled
        // Condition 4: It is not the uniswapPair that is sending tokens

        if (
            balanceOf(address(this)) >=
            token.numberTokensSellToAddToLiquidity &&
            !_swapAndLiquifyingInProgress &&
            isSwapAndLiquifyingEnabled &&
            sender != address(uniswapV2WETHPair)
        ) _swapAndLiquefy();

        _transferToken(
            sender,
            recipient,
            amount,
            _isExcludedFromFees[sender] || _isExcludedFromFees[recipient]
        );
    }

    function _approve(
        address owner,
        address beneficiary,
        uint256 amount
    ) private {
        require(
            beneficiary != address(0),
            "The burn address is not allowed to receive approval for allowances."
        );
        require(
            owner != address(0),
            "The burn address is not allowed to approve allowances."
        );

        _allowances[owner][beneficiary] = amount;
        emit Approval(owner, beneficiary, amount);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address beneficiary, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), beneficiary, amount);
        return true;
    }

    function transferFrom(
        address provider,
        address beneficiary,
        uint256 amount
    ) external override returns (bool) {
        _transfer(provider, beneficiary, amount);
        _approve(
            provider,
            _msgSender(),
            _allowances[provider][_msgSender()] - amount
        );
        return true;
    }

    function allowance(address owner, address beneficiary)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][beneficiary];
    }

    function increaseAllowance(address beneficiary, uint256 amount)
        external
        returns (bool)
    {
        _approve(
            _msgSender(),
            beneficiary,
            _allowances[_msgSender()][beneficiary] + amount
        );
        return true;
    }

    function decreaseAllowance(address beneficiary, uint256 amount)
        external
        returns (bool)
    {
        _approve(
            _msgSender(),
            beneficiary,
            _allowances[_msgSender()][beneficiary] - amount
        );
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

pragma solidity ^0.8.4;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUniswapV2Router01 {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

pragma solidity ^0.8.4;

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

pragma solidity ^0.8.4;

import "./Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}