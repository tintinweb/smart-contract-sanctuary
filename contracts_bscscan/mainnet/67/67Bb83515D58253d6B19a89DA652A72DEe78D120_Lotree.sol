/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Context {
    constructor() {}

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IPancakeFactory {
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

interface IPancakePair {
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

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

contract Lotree is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint8;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address[] private holdersForLottery;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public PANCAKESWAP_ROUTER_ADDRESS;

    IPancakeRouter02 public pancakeswapRouter;
    address public pancakeswapPair;

    address public lotteryWallet = 0xe800eaC7Da3FB9C4c3EdE024A133915Ba4a9ACCa;
    uint8 public lotteryFeePercentage = 2;
    uint256 public lastTimeLotteryInEpochSeconds;
    uint256 public timeToLotteryInSeconds = 18000;

    uint8 public transactionFeePercentage = 2;
    bool public autoAddToLiquidity = true;

    address public transactionFeesWallet =
        0xB016E7bAdf1184E7632aC1aF25f9478601f26538;
    bool public sendTransactionFeesToAdminWallet = false;

    event AddToLiquidityPool(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapTokensForEth(uint256 tokenAmount, uint256 ethAmount);

    constructor() {
        _name = "Lotree";
        _symbol = "LOTREE";
        _decimals = 9;
        _totalSupply = 1000000000000 * 10**_decimals;
        _balances[_msgSender()] = _totalSupply;

        PANCAKESWAP_ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

        pancakeswapRouter = IPancakeRouter02(PANCAKESWAP_ROUTER_ADDRESS);
        pancakeswapPair = IPancakeFactory(pancakeswapRouter.factory())
        .createPair(address(this), pancakeswapRouter.WETH());

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    receive() external payable {}

    function getOwner() external view override returns (address) {
        return owner();
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
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
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function burn(uint256 amount) external returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) external returns (bool) {
        _burnFrom(account, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(
            amount > 0,
            "Amount to be transferred must be greater than zero"
        );

        uint256 transactionFee = transactionFeePercentage.mul(amount).div(100);
        uint256 lotteryFee = lotteryFeePercentage.mul(amount).div(100);

        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );

        // Exclude some wallets from winning the lottery
        if (
            _balances[recipient] == 0 &&
            recipient != pancakeswapPair &&
            recipient != address(this)
        ) {
            holdersForLottery.push(recipient);
        }

        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);

        // When buying
        // Don't run when the liquidity pool is sending to the owner (when owner is withdrawing the liquidity)
        // Don't run when it's the contract address
        if (
            sender == pancakeswapPair &&
            recipient != owner() &&
            recipient != address(this)
        ) {
            if (autoAddToLiquidity) {
                addToLiquidityPool(recipient, transactionFee);
            }

            if (sendTransactionFeesToAdminWallet) {
                _balances[recipient] = _balances[recipient].sub(transactionFee, "BEP20: transaction fees exceed balance");
                _balances[transactionFeesWallet] = _balances[
                    transactionFeesWallet
                ]
                .add(transactionFee);
            }

            transferToLotteryWinner(recipient);

            transferToLotteryWallet(recipient, lotteryFee);
        }
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );

        _balances[address(0)] = _balances[address(0)].add(amount);

        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = 0;
        _allowances[owner][spender] = amount;
        
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "BEP20: burn amount exceeds allowance"
            )
        );
    }

    function addToLiquidityPool(address sender, uint256 amount) internal {
        _transfer(sender, address(this), amount);
        _approve(address(this), address(pancakeswapRouter), amount);

        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);

        uint256 ethAmount = swapTokensForEth(half);

        pancakeswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            otherHalf,
            0,
            0,
            owner(),
            block.timestamp
        );

        emit AddToLiquidityPool(half, ethAmount, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) internal returns (uint256) {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapRouter.WETH();

        pancakeswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 ethAmount = address(this).balance.sub(initialBalance, "BEP20: initial balance exceeds current balance");

        emit SwapTokensForEth(tokenAmount, ethAmount);

        return ethAmount;
    }

    function transferToLotteryWallet(address sender, uint256 amount) private {
        _balances[sender] = _balances[sender].sub(amount, "BEP20: lottery fee exceeds balance");
        _balances[lotteryWallet] = _balances[lotteryWallet].add(amount);

        emit Transfer(sender, lotteryWallet, amount);
    }

    function generateRandomNumber() private view returns (uint256) {
        uint256 random = uint256(
            uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender()))) %
                holdersForLottery.length
        );
        return random;
    }

    function pickALotteryWinner() private view returns (address) {
        uint256 randomNumber = generateRandomNumber();
        return holdersForLottery[randomNumber];
    }

    function transferToLotteryWinner(address sender) private {
        if (lastTimeLotteryInEpochSeconds == 0) {
            lastTimeLotteryInEpochSeconds = block.timestamp;
        }

        if (
            lastTimeLotteryInEpochSeconds != 0 &&
            block.timestamp <
            lastTimeLotteryInEpochSeconds.add(timeToLotteryInSeconds)
        ) {
            return;
        }

        address winner = pickALotteryWinner();

        if (sender == winner) {
            _balances[winner] = _balances[winner].add(_balances[lotteryWallet]);

            emit Transfer(lotteryWallet, winner, _balances[lotteryWallet]);

            _balances[lotteryWallet] = 0;
        }
    }

    function updatePancakeswapRouterAddress(address newRouterAddress)
        public
        onlyOwner
        returns (address)
    {
        pancakeswapRouter = IPancakeRouter02(newRouterAddress);
        pancakeswapPair = IPancakeFactory(pancakeswapRouter.factory())
        .createPair(address(this), pancakeswapRouter.WETH());

        PANCAKESWAP_ROUTER_ADDRESS = newRouterAddress;
        pancakeswapPair = pancakeswapPair;

        return PANCAKESWAP_ROUTER_ADDRESS;
    }

    function updateTransactionFeePercentage(uint8 newPercentage)
        public
        onlyOwner
        returns (uint8)
    {
        transactionFeePercentage = newPercentage;
        return transactionFeePercentage;
    }

    function updateLotteryFeePercentage(uint8 newPercentage)
        public
        onlyOwner
        returns (uint8)
    {
        lotteryFeePercentage = newPercentage;
        return lotteryFeePercentage;
    }

    function updateTimeToLotteryInSeconds(uint256 newTime)
        public
        onlyOwner
        returns (uint256)
    {
        timeToLotteryInSeconds = newTime;
        return timeToLotteryInSeconds;
    }

    function setAutoAddToLiquidity(bool enabled)
        public
        onlyOwner
        returns (bool)
    {
        autoAddToLiquidity = enabled;
        return autoAddToLiquidity;
    }

    function updateLotteryWallet(address newWallet)
        public
        onlyOwner
        returns (address)
    {
        lotteryWallet = newWallet;
        return lotteryWallet;
    }

    function updateTransactionFeesWallet(address newWallet)
        public
        onlyOwner
        returns (address)
    {
        transactionFeesWallet = newWallet;
        return transactionFeesWallet;
    }

    function updateSendTransactionFeesToAdminWallet(bool enabled)
        public
        onlyOwner
        returns (bool)
    {
        sendTransactionFeesToAdminWallet = enabled;
        return sendTransactionFeesToAdminWallet;
    }
}