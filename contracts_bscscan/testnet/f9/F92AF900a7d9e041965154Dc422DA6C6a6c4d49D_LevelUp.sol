/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier:MIT

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address payable private _owner;
    address payable private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
    }

    function transferOwnership(address payable newOwner)
        public
        virtual
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = payable(address(0));
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(
            block.timestamp > _lockTime,
            "Contract is locked until defined days"
        );
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = payable(address(0));
    }
}

interface IUniSwapV2Factory {
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

interface IUniSwapV2Pair {
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

interface IUniSwapV2Router01 {
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

interface IUniSwapV2Router02 is IUniSwapV2Router01 {
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

library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(address routerAddress, uint256 tokenAmount)
        internal
    {
        IUniSwapV2Router02 uniSwapV2Router = IUniSwapV2Router02(routerAddress);

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniSwapV2Router.WETH();

        // make the swap
        uniSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp + 300
        );
    }

    function swapETHForTokens(
        address routerAddress,
        address recipient,
        uint256 ethAmount
    ) internal {
        IUniSwapV2Router02 uniSwapV2Router = IUniSwapV2Router02(routerAddress);

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniSwapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uniSwapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: ethAmount
        }(
            0, // accept any amount of ETH
            path,
            address(recipient),
            block.timestamp + 300
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {
        IUniSwapV2Router02 uniSwapV2Router = IUniSwapV2Router02(routerAddress);

        // add the liquidity
        uniSwapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 300
        );
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

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

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}

// Protocol by team BloctechSolutions.com

contract LevelUp is Context, IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => uint256) public nextAvailableClaimDate;

    string private _name = "Level Up";
    string private _symbol = "LVLUP";
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 100 * 1e12 * 1e9;

    IUniSwapV2Router02 public uniSwapV2Router;
    address public uniSwapV2Pair;
    address payable public marketWallet;

    uint256 public _maxTxAmount = _totalSupply.mul(5).div(1000); // must be 0.5% percent per transaction
    uint256 public minTokenNumberToSell = _totalSupply.div(100000); // 0.001% max tx amount will trigger swap and add liquidity
    uint256 public rewardCycleBlock = 24 hours;
    uint256 public sellCoolDownDuration = 60 seconds;
    uint256 public sellCoolDownTriggeredAt;
    
    
    bool public swapAndLiquifyEnabled; // must be true to auto liquidate the pool
    bool public reflectionFeesdiabled; // fees are enabled by default
    bool inSwapAndLiquify = false;
    bool public _tradingOpen;   // must be true to enable trading

    uint256 public _poolFee = 80;   // 8% will be added to pool for ETH reward
    uint256 public _marketFee = 40; // 4% will go to the market address
    uint256 public _totalFeePerTx = 120;    // 12% by default
    uint256 public _totalSellFeePerTx = 250;    // 25% by defult

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived
    );

    event ClaimEthSuccessfully(
        address recipient,
        uint256 ethReceived,
        uint256 nextAvailableClaimDate
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address payable _marketWallet) {
        marketWallet = _marketWallet;
        _balances[owner()] = _totalSupply;

        IUniSwapV2Router02 _uniSwapV2Router = IUniSwapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
        // Create a uniswap pair for this new token
        uniSwapV2Pair = IUniSwapV2Factory(_uniSwapV2Router.factory()).createPair(
            address(this),
            _uniSwapV2Router.WETH()
        );

        // set the rest of the contract variables
        uniSwapV2Router = _uniSwapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
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
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
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
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "LVLUP: transfer amount exceeds allowance"
            )
        );
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
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "LVLUP: decreased allowance below zero"
            )
        );
        return true;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    // for 1% input 100
    function setMaxTxPercent(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = _totalSupply.mul(maxTxAmount).div(10000);
    }

    function setMinTokenNumberToSell(uint256 _amount) public onlyOwner {
        minTokenNumberToSell = _amount;
    }

    function setExcludeFromMaxTx(address _address, bool value)
        public
        onlyOwner
    {
        _isExcludedFromMaxTx[_address] = value;
    }

    function setRewardCycleBlock(uint256 _newCycle) public onlyOwner {
        rewardCycleBlock = _newCycle;
    }

    function setSellCoolDownDuration(uint256 _newDuration) public onlyOwner {
        sellCoolDownDuration = _newDuration;
    }

    function setFeePercent(uint256 poolFee, uint256 marketFee, uint256 sellFee) external onlyOwner {
        _poolFee = poolFee;
        _marketFee = marketFee;
        _totalFeePerTx = poolFee.add(marketFee);
        _totalSellFeePerTx = sellFee;
    }

    function enableTrading() external onlyOwner {
        require(!_tradingOpen,"LVLUP: Already enabled");
        _tradingOpen = true;
        swapAndLiquifyEnabled = true;

        emit SwapAndLiquifyEnabledUpdated(true);
    }

    function setSwapAndLiquifyEnabled(bool _state) public onlyOwner {
        swapAndLiquifyEnabled = _state;
        emit SwapAndLiquifyEnabledUpdated(_state);
    }

    function setReflectionFees(bool _state) external onlyOwner {
        reflectionFeesdiabled = _state;
    }

    function setMarketAddress(address payable _marketAddress)
        external
        onlyOwner
    {
        marketWallet = _marketAddress;
    }

    function changeRouter(IUniSwapV2Router02 _router, address _pair)
        external
        onlyOwner
    {
        uniSwapV2Router = _router;
        uniSwapV2Pair = _pair;
    }

    //to receive ETH from uniSwapV2Router when swapping
    receive() external payable {}

    function totalFeePerTx(uint256 tAmount) internal view returns (uint256) {
        uint256 percentage = tAmount.mul(_poolFee.add(_marketFee)).div(1e3);
        return percentage;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "LVLUP: approve from the zero address");
        require(spender != address(0), "LVLUP: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "LVLUP: transfer from the zero address");
        require(to != address(0), "LVLUP: transfer to the zero address");
        require(amount > 0, "LVLUP: transfer amount must be greater than zero");
        require(balanceOf(from) >= amount,"LVLUP: not enough balance");

        if (
            !_isExcludedFromMaxTx[from] &&
            !_isExcludedFromMaxTx[to] // by default false
        ) {
            require(
                amount <= _maxTxAmount,
                "LVLUP: Transfer amount exceeds the maxTxAmount."
            );

            if (!_tradingOpen) {
                require(
                    from != uniSwapV2Pair && to != uniSwapV2Pair,
                    "LVLUP: Trading is not enabled"
                );
            }

            if(to == uniSwapV2Pair){
                require(sellCoolDownTriggeredAt.add(sellCoolDownDuration) < block.timestamp,
                "LVLUP: wait for selling cool down"
                );
                sellCoolDownTriggeredAt = block.timestamp;
            }
        }

        // swap and liquify
        swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to] ||
            reflectionFeesdiabled
        ) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);

            emit Transfer(sender, recipient, amount);
        }else if(recipient == uniSwapV2Pair){
            uint256 _totalFee = amount.mul(_totalSellFeePerTx).div(1e3);
            uint256 transferAmount = amount.sub(_totalFee);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(transferAmount);
            _takeBothFee(amount);

            emit Transfer(sender, recipient, transferAmount);
        } else {
            uint256 _totalFee = amount.mul(_totalFeePerTx).div(1e3);
            uint256 transferAmount = amount.sub(_totalFee);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(transferAmount);
            _takeBothFee(amount);

            emit Transfer(sender, recipient, transferAmount);
        }
    }

    function _takeBothFee(uint256 tAmount) internal {
        uint256 totalFee = tAmount.mul(_marketFee.add(_poolFee)).div(1e3);
        _balances[address(this)] = _balances[address(this)].add(totalFee);

        emit Transfer(_msgSender(), address(this), totalFee);
    }

    function calculateEthReward(address ofAddress)
        public
        view
        returns (uint256)
    {
        uint256 remainingSupply = uint256(_totalSupply)
            .sub(balanceOf(address(0)))
            .sub(balanceOf(0x000000000000000000000000000000000000dEaD))
            .sub(balanceOf(address(uniSwapV2Pair))); // exclude burned wallet
        // exclude liquidity wallet

        uint256 reward = address(this)
            .balance
            .mul(balanceOf(address(ofAddress)))
            .div(100)
            .div(remainingSupply);
        return reward;
    }

    function claimEthReward() public isHuman nonReentrant {
        require(
            !address(msg.sender).isContract(),
            "LVLUP: Contract can not call this function"
        );
        require(
            nextAvailableClaimDate[msg.sender] <= block.timestamp,
            "LVLUP: next claim not reached"
        );
        require(
            balanceOf(msg.sender) >= 0,
            "LVLUP: must own LVLUP to claim reward"
        );

        uint256 reward = calculateEthReward(msg.sender);
        payable(msg.sender).transfer(reward);

        // update rewardCycleBlock
        nextAvailableClaimDate[msg.sender] =
            block.timestamp +
            getRewardCycleBlock();

        emit ClaimEthSuccessfully(
            msg.sender,
            reward,
            nextAvailableClaimDate[msg.sender]
        );
    }

    function getRewardCycleBlock() public view returns (uint256) {
        return rewardCycleBlock;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function swapAndLiquify(address from, address to) private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool shouldSell = contractTokenBalance >= minTokenNumberToSell;

        if (
            !inSwapAndLiquify &&
            shouldSell &&
            from != uniSwapV2Pair &&
            swapAndLiquifyEnabled &&
            !(from == address(this) && to == address(uniSwapV2Pair)) // swap 1 time
        ) {
            // only sell for minTokenNumberToSell, decouple from _maxTxAmount

            contractTokenBalance = minTokenNumberToSell;
            // approve contract
            _approve(
                address(this),
                address(uniSwapV2Router),
                contractTokenBalance
            );

            // split the contract balance into 2 pieces

            uint256 initialBalance = address(this).balance;

            // now is to lock into pool
            Utils.swapTokensForEth(
                address(uniSwapV2Router),
                contractTokenBalance
            );

            // how much ETH did we just swap into?

            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the swap creates

            uint256 deltaBalance = address(this).balance.sub(initialBalance);
            uint256 totalPercent = _marketFee.add(_poolFee);
            uint256 _marketPercent = _marketFee.mul(1e4).div(totalPercent);

            marketWallet.transfer(deltaBalance.mul(_marketPercent).div(1e4));

            emit SwapAndLiquify(
                contractTokenBalance,
                deltaBalance
            );
        }
    }
}