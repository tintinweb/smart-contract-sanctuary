// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./DogeVikingMetaData.sol";
import "./lib/Ownable.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";

struct Exceptions {
    bool noHoldingLimit;
    bool noFees;
    bool noMaxTxAmount;
}

enum Token {ZERO, ONE}

contract DogeViking is DogeVikingMetaData, Ownable {
    // Supply *************************************************************

    uint256 private constant MAX_INT_VALUE = type(uint256).max;

    uint256 private constant _tokenSupply = 1e6 ether;

    uint256 private _reflectionSupply = (MAX_INT_VALUE -
        (MAX_INT_VALUE % _tokenSupply));

    // Taxes *************************************************************

    uint8 public liquidityFee = 20;

    uint8 private _previousLiquidityFee = liquidityFee;

    uint8 public dogeVikingPoolFee = 2;

    uint8 private _previousDogeVikingPoolFee = dogeVikingPoolFee;

    uint8 public txFee = 10;

    uint8 private _previousTxFee = txFee;

    uint256 private _totalTokenFees;

    // Wallets *************************************************************

    mapping(address => uint256) private _reflectionBalance;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) public previousSale;

    // Privileges *************************************************************

    mapping(address => Exceptions) public exceptions;

    // Constraints *************************************************************

    // 0.1% of the total supply
    uint256 public maxTxAmount = 1 * 1e3 ether;

    // 0.05% of the total supply
    uint256 public numberTokensSellToAddToLiquidity = 5 * 1e2 ether;

    // Starts at a very high value for the pre sale. Then it needs to be updated to 5 * 1e2 ether
    uint256 public sellLimitThreshold = 1000;

    // 0.1% of the total supply
    uint256 public maxHoldingAmount = 1 * 1e3 ether;

    uint256 public sellDelay = 30 seconds;

    uint256 public liquidityRatioBps = 50;

    // Events *************************************************************

    event SwapAndLiquefy(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapAndLiquefyStateUpdate(bool state);

    event UpdateRouter(address newRouter, address newPair);

    // State *************************************************************

    bool public isSwapAndLiquifyingEnabled = true;

    bool private _swapAndLiquifyingInProgress;

    // Addresses *************************************************************

    address public vikingPool;

    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2WETHPair;

    constructor(address routerAddress, address vikingPoolAddress) {
        _reflectionBalance[_msgSender()] = _reflectionSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);

        uniswapV2WETHPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        vikingPool = vikingPoolAddress;

        exceptions[owner()].noFees = true;
        exceptions[address(this)].noFees = true;
        exceptions[vikingPoolAddress].noFees = true;

        exceptions[owner()].noHoldingLimit = true;
        exceptions[address(this)].noHoldingLimit = true;
        exceptions[vikingPoolAddress].noHoldingLimit = true;
        exceptions[uniswapV2WETHPair].noHoldingLimit = true;

        emit Transfer(address(0), _msgSender(), _tokenSupply);
    }

    modifier lockTheSwap {
        _swapAndLiquifyingInProgress = true;
        _;
        _swapAndLiquifyingInProgress = false;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tokenSupply;
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return exceptions[account].noFees;
    }

    function _getRate() private view returns (uint256) {
        return _reflectionSupply / _tokenSupply;
    }

    function _reflectionFromToken(uint256 amount)
        private
        view
        returns (uint256)
    {
        require(
            _tokenSupply >= amount,
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
            _reflectionSupply >= reflectionAmount,
            "Cannot have a personal reflection amount larger than total reflection"
        );
        return reflectionAmount / _getRate();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tokenFromReflection(_reflectionBalance[account]);
    }

    function totalFees() external view returns (uint256) {
        return _totalTokenFees;
    }

    function _removeAllFees() private {
        if (liquidityFee == 0 && dogeVikingPoolFee == 0 && txFee == 0) return;

        _previousLiquidityFee = liquidityFee;
        _previousDogeVikingPoolFee = dogeVikingPoolFee;
        _previousTxFee = txFee;

        liquidityFee = 0;
        dogeVikingPoolFee = 0;
        txFee = 0;
    }

    function _restoreAllFees() private {
        liquidityFee = _previousLiquidityFee;
        dogeVikingPoolFee = _previousDogeVikingPoolFee;
        txFee = _previousTxFee;
    }

    function setSwapAndLiquifyingState(bool state) external onlyOwner() {
        isSwapAndLiquifyingEnabled = state;
        emit SwapAndLiquefyStateUpdate(state);
    }

    function _calculateFee(uint256 amount, uint8 fee)
        private
        pure
        returns (uint256)
    {
        return (amount * fee) / 100;
    }

    function _calculateTxFee(uint256 amount) private view returns (uint256) {
        return _calculateFee(amount, txFee);
    }

    function _calculateLiquidityFee(uint256 amount)
        private
        view
        returns (uint256)
    {
        return _calculateFee(amount, liquidityFee);
    }

    function _calculatePoolFee(uint256 amount) private view returns (uint256) {
        return _calculateFee(amount, dogeVikingPoolFee);
    }

    function _reflectFee(uint256 rfee, uint256 fee) private {
        _reflectionSupply -= rfee;
        _totalTokenFees += fee;
    }

    function _takeLiquidity(uint256 rAmount) private {
        _reflectionBalance[address(this)] =
            _reflectionBalance[address(this)] +
            rAmount;
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

        // Holders retribution
        uint256 rTax = _reflectionFromToken(_calculateTxFee(amount));

        // Pool retribution
        uint256 rPoolTax = _reflectionFromToken(_calculatePoolFee(amount));

        // Liquidity retribution
        uint256 rLiquidityTax =
            _reflectionFromToken(_calculateLiquidityFee(amount));

        // Since the recipient is also  excluded. We need to update his reflections and tokens.
        _reflectionBalance[recipient] =
            _reflectionBalance[recipient] +
            rAmount -
            rTax -
            rPoolTax -
            rLiquidityTax;

        _reflectionBalance[vikingPool] =
            _reflectionBalance[vikingPool] +
            rPoolTax;

        _takeLiquidity(rLiquidityTax);
        _reflectFee(
            rTax,
            _calculateTxFee(amount) +
                _calculatePoolFee(amount) +
                _calculateLiquidityFee(amount)
        );

        previousSale[sender] = block.timestamp;
        emit Transfer(
            sender,
            recipient,
            amount -
                _calculateLiquidityFee(amount) -
                _calculatePoolFee(amount) -
                _calculateTxFee(amount)
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
            owner(),
            block.timestamp
        );
    }

    function _swapAndLiquefy() private lockTheSwap {
        // split the contract token balance into halves
        uint256 half = numberTokensSellToAddToLiquidity / 2;
        uint256 otherHalf = numberTokensSellToAddToLiquidity - half;

        uint256 initialETHContractBalance = address(this).balance;

        // Buys ETH at current token price
        _swapTokensForEth(half);

        // This is to make sure we are only using ETH derived from the liquidity fee
        uint256 ethBought = address(this).balance - initialETHContractBalance;

        // Add liquidity to the pool
        _addLiquidity(otherHalf, ethBought);

        emit SwapAndLiquefy(half, ethBought, otherHalf);
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

        // Owner has no limits
        if (sender != owner() && recipient != owner()) {
            // Future utility contracts might need conduct large TXs.
            if (!exceptions[sender].noMaxTxAmount)
                require(
                    amount <= maxTxAmount,
                    "Transfer amount exceeds the maxTxAmount."
                );

            // Future utility contracts and EOA like exchanges should not have a holding limit
            if (!exceptions[recipient].noHoldingLimit) {
                require(
                    balanceOf(recipient) + amount <= maxHoldingAmount,
                    "Your holdings will pass the limit."
                );
            }

            // Should be limited to selling on pancake swap to protect holders or when it is this contract selling for the liquidity event
            if (
                (recipient == address(uniswapV2Router) ||
                recipient == address(uniswapV2WETHPair)) &&
                    sender != address(this) && !_swapAndLiquifyingInProgress
            ) {
                // Only whales get triggered
                if (balanceOf(sender) > sellLimitThreshold) {
                    address pair =
                        IUniswapV2Factory(uniswapV2Router.factory()).getPair(
                            address(this),
                            uniswapV2Router.WETH()
                        );

                    // If the pair with WETH exists. Sell orders above a certain percentage of the total liquidity will be refused.
                    if (pair != address(0)) {
                        address token0 = IUniswapV2Pair(pair).token0();

                        Token ourToken =
                            address(this) == token0 ? Token.ZERO : Token.ONE;

                        (uint256 reserve0, uint256 reserve1, ) =
                            IUniswapV2Pair(pair).getReserves();

                        if (
                            ourToken == Token.ZERO &&
                            reserve0 * liquidityRatioBps >= 10000
                        ) {
                            require(
                                (reserve0 * liquidityRatioBps) / 10000 >=
                                    amount,
                                "High price impact on PCS liquidity"
                            );
                        }

                        if (
                            ourToken == Token.ONE &&
                            reserve1 * liquidityRatioBps >= 10000
                        ) {
                            require(
                                (reserve1 * liquidityRatioBps) / 10000 >=
                                    amount,
                                "High price impact on PCS liquidity"
                            );
                        }
                    }

                    require(
                        block.timestamp - previousSale[sender] > sellDelay,
                        "You must wait to sell again."
                    );
                }
            }
        }

        // Condition 1: Make sure the contract has the enough tokens to liquefy
        // Condition 2: We are not in a liquefication event
        // Condition 3: Liquification is enabled
        // Condition 4: It is not the uniswapPair that is sending tokens

        if (
            balanceOf(address(this)) >= numberTokensSellToAddToLiquidity &&
            !_swapAndLiquifyingInProgress &&
            isSwapAndLiquifyingEnabled &&
            sender != address(uniswapV2WETHPair)
        ) _swapAndLiquefy();

        _transferToken(
            sender,
            recipient,
            amount,
            exceptions[sender].noFees || exceptions[recipient].noFees
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

    // ********************************* SETTERS *********************************

    function setLiquidityFee(uint8 amount) external onlyOwner() {
        require(amount <= 20, "The maximum amount allowed is 20%");
        liquidityFee = amount;
    }

    function setDogeVikingFundFee(uint8 amount) external onlyOwner() {
        require(amount <= 2, "The maximum amount allowed is 2%");
        dogeVikingPoolFee = amount;
    }

    function setTxFee(uint8 amount) external onlyOwner() {
        require(amount <= 10, "The maximum amount allowed is 5%");
        txFee = amount;
    }

    function setPoolAddress(address _address) external onlyOwner() {
        exceptions[vikingPool].noFees = false;
        exceptions[vikingPool].noMaxTxAmount = false;
        exceptions[vikingPool].noHoldingLimit = false;

        exceptions[_address].noFees = true;
        exceptions[_address].noMaxTxAmount = true;
        exceptions[_address].noHoldingLimit = true;

        vikingPool = _address;
    }

    function setNumberTokensSellToAddToLiquidity(uint256 _amount)
        external
        onlyOwner()
    {
        numberTokensSellToAddToLiquidity = _amount;
    }

    function updateRouter(address _router) external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);

        address pair =
            IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
                address(this),
                _uniswapV2Router.WETH()
            );

        if (pair == address(0)) {
            pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
                address(this),
                _uniswapV2Router.WETH()
            );
        }

        uniswapV2WETHPair = pair;
        uniswapV2Router = _uniswapV2Router;

        emit UpdateRouter(address(_uniswapV2Router), pair);
    }

    function excludeFromFees(address account) external onlyOwner() {
        exceptions[account].noFees = true;
    }

    function includeInFees(address account) external onlyOwner() {
        exceptions[account].noFees = false;
    }

    function removeHoldingLimit(address account) external onlyOwner() {
        exceptions[account].noHoldingLimit = true;
    }

    function addHoldinglimit(address account) external onlyOwner() {
        exceptions[account].noHoldingLimit = false;
    }

    function removeMaxTxAmount(address account) external onlyOwner() {
        exceptions[account].noMaxTxAmount = true;
    }

    function addMaxTxAmount(address account) external onlyOwner() {
        exceptions[account].noMaxTxAmount = false;
    }

    function setMaxHoldingAmount(uint256 _amount) external onlyOwner() {
        // 0.05% of total supply
        require(_amount >= 5 * 1e2 ether, "Please set a higher amount");
        // 0.5% of total supply
        require(_amount <= 5 * 1e3 ether, "Please set a lower amount");
        maxHoldingAmount = _amount;
    }

    function setMaxTxAmount(uint256 _amount) external onlyOwner() {
        // 0.05% of total supply
        require(_amount >= 5 * 1e2 ether, "Please set a higher amount");
        // 0.5% of total supply
        require(_amount <= 5 * 1e3 ether, "Please set a lower amount");
        maxTxAmount = _amount;
    }

    function setSellLimitThreshold(uint256 _amount) external onlyOwner() {
        // 0.05% of total supply
        require(_amount >= 5 * 1e2 ether, "Please set a higher amount");
        sellLimitThreshold = _amount;
    }

    function setSellDelay(uint256 _delay) external onlyOwner() {
        require(_delay <= 5 days, "The maximum delay is 5 days");
        require(_delay >= 30 minutes, "The minimum delay is 30 minutes");
        sellDelay = _delay;
    }

    function setliquidityRatioBps(uint256 _amount) external onlyOwner() {
        require(_amount >= 50, "The minimum bpd is 0.5%");
        require(_amount <= 200, "The maximum bpd is 2%");
        liquidityRatioBps = _amount;
    }

    // ********************************* Withdrawals *********************************

    function withdrawETH() external onlyOwner() {
        (bool success, ) =
            payable(owner()).call{value: address(this).balance}("");
        require(success, "Error withdrawing ETH");
    }

    function withdrawERC20(address _token, address _to)
        external
        onlyOwner()
        returns (bool sent)
    {
        require(
            _token != address(this),
            "You cannot withdraw this contract tokens."
        );
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        sent = IERC20(_token).transfer(_to, _contractBalance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IERC20MetaData.sol";

abstract contract DogeVikingMetaData is IERC20Metadata {
    /**
     *@dev The name of the token managed by the this smart contract.
     */
    string private constant _name = "Doge Viking";

    /**
     *@dev The symbol of the token managed by the this smart contract.
     */
    string private constant _symbol = "DVK";

    /**
     *@dev The decimals of the token managed by the this smart contract.
     */
    uint8 private constant _decimals = 9;

    /**
     *@dev It returns the name of the token.
     */
    function name() external pure override returns (string memory) {
        return _name;
    }

    /**
     *@dev It returns the symbol of the token.
     */
    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    /**
     *@dev It returns the decimal of the token.
     */
    function decimals() external pure override returns (uint8) {
        return _decimals;
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

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
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

