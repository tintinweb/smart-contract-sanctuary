/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

/**
 * PUMPkin token
 * FTM rewards!
 * https://t.me/PUMPkinOfficial
 */
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/b̴a̵b̴y̴ ̵a̵r̴e̶n̷a̵/pull/522
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703cb̴a̴b̶y̷ ̴a̷r̶e̴n̶a̴ ̶c̶o̵p̴y̴3b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function allPairs(uint) external view returns (address lpPair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract DividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 ftm = IERC20(0xAD29AbB318791D579433D831ed122aFeAf29dcfe); // Binance wrapped FTM
    IUniswapV2Router02 router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 18;

	uint256 public minPeriod = 1 minutes;
    uint256 public minDistribution = 1 * (10 ** 17);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
            ? IUniswapV2Router02(_router)
            : IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable {
        uint256 balanceBefore = ftm.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(ftm);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = ftm.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            ftm.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function claimMyDividends(address a) external onlyToken {
        distributeDividend(a);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function getTotalDistributed() public view returns(uint256) {
        return totalDistributed;
    }

	function recover() external onlyToken {
		payable(msg.sender).transfer(address(this).balance);
	}
}

contract Pumpkin is IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) _owned;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _isExcludedFromFee;
    mapping (address => bool) isDividendExempt;

    bool private presaleCheck = false;
    mapping (address => bool) private _isSniper;
    mapping (address => bool) private _liquidityHolders;

    uint256 private startingSupply = 100_000_000;

    uint8 private _decimals = 9;
    uint256 private _total = startingSupply * (10 ** uint256(_decimals));

    string constant _name = "PUMPkin";
    string constant _symbol = "PUMP";

    uint256 public _liquidityFee = 200;
    uint256 public _reflectionFee = 400;
    uint256 public _marketingFee = 200;
    uint256 public _totalFee = _liquidityFee + _reflectionFee + _marketingFee;
    uint256 public _liquidityFeeSell = 400;
    uint256 public _reflectionFeeSell = 800;
    uint256 public _marketingFeeSell = 400;
    uint256 public _totalFeeSell = _liquidityFeeSell + _reflectionFeeSell + _marketingFeeSell;
    uint256 public masterTaxDivisor = 10000;
    bool public walletToWalletTax = false;

    IUniswapV2Router02 public dexRouter;
    address public lpPair;

    // PCS ROUTER
    address private _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    //address private _routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // Testnet

    address private WBNB;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;
    address payable private _marketingWallet = payable(0xEDA6A33D4B854216dAf6D11910cbD14aF3990D71);

    // Max TX amount is 1% of the total supply.
    uint256 private maxTxPercent = 10;
    uint256 private maxTxDivisor = 1000;
    uint256 private _maxTxAmount = (_total * maxTxPercent) / maxTxDivisor;
    uint256 private _previousMaxTxAmount = _maxTxAmount;
    // Maximum wallet size is 1% of the total supply.
    uint256 private maxWalletPercent = 10;
    uint256 private maxWalletDivisor = 1000;
    uint256 private _maxWalletSize = (_total * maxWalletPercent) / maxWalletDivisor;
    uint256 private _previousMaxWalletSize = _maxWalletSize;

    uint256 targetLiquidity = 100;
    uint256 targetLiquidityDenominator = 100;

    DividendDistributor reflector = new DividendDistributor(_routerAddress);
    address public reflectorAddress = address(reflector);
    uint256 reflectorGas = 600666;

    bool public swapAndLiquifyEnabled = true;
    bool public processReflect = true;
    uint256 public swapThreshold = _total / 20000;
    uint256 public swapAmount = swapThreshold;
    bool inSwap;

    bool private sniperProtection = true;
    bool public _hasLiqBeenAdded = false;
    uint256 private _liqAddBlock = 0;
    uint256 private _liqAddStamp = 0;
    uint256 private immutable snipeBlockAmt = 3;
    uint256 public snipersCaught = 0;
	bool private gasLimitEnabled = true;
    uint256 private antiSniperGasLimit = 19 gwei;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amount);
    event SniperCaught(address sniperAddress);

    constructor() payable {
        _owned[msg.sender] = _total;

        dexRouter = IUniswapV2Router02(_routerAddress);
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        WBNB = dexRouter.WETH();

        reflector = new DividendDistributor(_routerAddress);
        reflectorAddress = address(reflector);

        _isExcludedFromFee[owner()] = true;
		_liquidityHolders[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        isDividendExempt[lpPair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[burnAddress] = true;
        isDividendExempt[ZERO] = true;

        approveMax(_routerAddress);

        emit Transfer(ZERO, msg.sender, _total);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) { return _total; }
    function decimals() external view override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _owned[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) public returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transfer(sender, recipient, amount);
    }

    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }

    function removeSniper(address account) external onlyOwner() {
        require(_isSniper[account]);
        _isSniper[account] = false;
        snipersCaught--;
    }

    function addSniper(address account) external onlyOwner() {
        require(!_isSniper[account], "Already registered as sniper");
		require(_liqAddBlock > 0 && block.number - _liqAddBlock < 125, "Too late");
        _isSniper[account] = true;
        snipersCaught++;
        emit SniperCaught(account);
    }

    function setSniperProtectionEnabled(bool enabled) external onlyOwner() {
        sniperProtection = enabled;
    }

    function setDividendExcluded(address holder, bool enabled) public onlyOwner {
        require(holder != address(this) && holder != lpPair);
        isDividendExempt[holder] = enabled;
        if (enabled) {
            reflector.setShare(holder, 0);
        } else {
            reflector.setShare(holder, _owned[holder]);
        }
    }

    function setExcludeFromFees(address account, bool enabled) public onlyOwner {
        _isExcludedFromFee[account] = enabled;
    }

    function setTaxes(uint256 liquidityFee, uint256 reflectionFee, uint256 marketingFee, uint256 divisor) external onlyOwner {
        require(_totalFee < masterTaxDivisor / 3);
        _liquidityFee = liquidityFee;
        _reflectionFee = reflectionFee;
        _marketingFee = marketingFee;
        _totalFee = liquidityFee + reflectionFee + marketingFee;
        masterTaxDivisor = divisor;
    }

    function setTaxesSales(uint256 liquidityFee, uint256 reflectionFee, uint256 marketingFee, uint256 divisor) external onlyOwner {
        require(_totalFee < masterTaxDivisor / 3);
        _liquidityFeeSell = liquidityFee;
        _reflectionFeeSell = reflectionFee;
        _marketingFeeSell = marketingFee;
        _totalFeeSell = liquidityFee + reflectionFee + marketingFee;
        masterTaxDivisor = divisor;
    }

    function setMarketingWallet(address payable newWallet) external onlyOwner {
        _marketingWallet = payable(newWallet);
    }

    function setSwapBackSettings(bool _enabled, bool processReflectEnabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        processReflect = processReflectEnabled;
    }

    function setSwapThreshold(uint256 percent, uint256 divisor) external onlyOwner() {
        swapThreshold = _total.mul(percent).div(divisor);
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setReflectionCriteria(uint256 _minPeriod, uint256 _minReflection, uint256 minReflectionMultiplier) external onlyOwner {
        _minReflection = _minReflection * 10**minReflectionMultiplier;
        reflector.setDistributionCriteria(_minPeriod, _minReflection);
    }

    function setReflectorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        reflectorGas = gas;
    }

    function setSwapAmount(uint256 percent, uint256 divisor) external onlyOwner {
        swapAmount = _total.mul(percent).div(divisor);
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _total - balanceOf(burnAddress) - balanceOf(ZERO);
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy * balanceOf(lpPair) * 2 / getCirculatingSupply();
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function claimMyDividends() external {
        reflector.claimMyDividends(msg.sender);
    }

    function getTotalReflected() external view returns (uint256) {
        return reflector.getTotalDistributed();
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner() {
        _maxTxAmount = _total.mul(percent).div(divisor);
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner() {
        _maxWalletSize = _total.mul(percent).div(divisor);
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != burnAddress
            && to != address(0)
            && from != address(this);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (_hasLimits(from, to)) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            if (to != _routerAddress 
                && to != lpPair
            ) {
                uint256 contractBalanceRecepient = balanceOf(to);
                require(contractBalanceRecepient + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
            }
        }

        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        // Wallet to wallet taxation.
        if (!walletToWalletTax && from != lpPair && to != lpPair) {
            takeFee = false;
        }

        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function _finalizeTransfer(address from, address to, uint256 amount, bool takeFee) internal returns (bool) {
        // Failsafe, disable the whole system if needed.
        if (sniperProtection) {
            // If sender is a sniper address, reject the transfer.
            if (isSniper(from) || isSniper(to)) {
                revert("Sniper rejected.");
            }

            // Check if this is the liquidity adding tx to startup.
            if (!_hasLiqBeenAdded) {
                _checkLiquidityAdd(from, to);
                    if (!_hasLiqBeenAdded && _hasLimits(from, to)) {
                        revert("Only owner can transfer at this time.");
                    }
            } else {
                if (_liqAddBlock > 0 
                    && from == lpPair 
                    && _hasLimits(from, to)
                ) {
                    if (block.number - _liqAddBlock < snipeBlockAmt) {
                        _isSniper[to] = true;
                        snipersCaught++;
                        emit SniperCaught(to);
                    }
                    if (block.number - _liqAddBlock < (snipeBlockAmt + 3) && (!gasLimitEnabled || tx.gasprice >= antiSniperGasLimit)) {
                        revert("Try again later.");
                    }
                }
            }
        }

        _owned[from] = _owned[from].sub(amount, "Insufficient Balance");

        if (inSwap) {
            return _basicTransfer(from, to, amount);
        }

        uint256 contractTokenBalance = _owned[address(this)];
        if (contractTokenBalance >= swapAmount) {
            contractTokenBalance = swapAmount;
		}

        if (!inSwap
            && from != lpPair
            && swapAndLiquifyEnabled
            && contractTokenBalance >= swapThreshold
        ) {
            swapBack(contractTokenBalance);
        }

        uint256 amountReceived = amount;

        if (takeFee) {
            amountReceived = takeTaxes(from, to, amount);
        }

        _owned[to] = _owned[to].add(amountReceived);

        if (processReflect) {
            processTokenReflect(from, to);
        }

        emit Transfer(from, to, amountReceived);
        return true;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != lpPair
            && !inSwap
            && swapAndLiquifyEnabled
            && _owned[address(this)] >= swapThreshold;
    }

    function processTokenReflect(address from, address to) internal {
        // Process TOKEN Reflect.
        if (!isDividendExempt[from]) {
            try reflector.setShare(from, _owned[from]) {} catch {}
        }
        if (!isDividendExempt[to]) {
            try reflector.setShare(to, _owned[to]) {} catch {}
        }
        try reflector.process(reflectorGas) {} catch {}
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _owned[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !_isExcludedFromFee[sender];
    }

    function getTotalFee(bool isSale) public view returns (uint256) {
        if (isSale) {
            return _totalFeeSell;
        }
        return _totalFee;
    }

    function takeTaxes(address sender, address to, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount * getTotalFee(to == lpPair) / masterTaxDivisor;
        _owned[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function swapBack(uint256 numTokensToSwap) internal swapping {
        uint256 amountToLiquify = ((numTokensToSwap * _liquidityFeeSell) / _totalFeeSell) / 2;
        uint256 amountToSwap = numTokensToSwap - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance;
        uint256 amountBNBLiquidity = ((amountBNB * _liquidityFeeSell) / _totalFeeSell) / 2;
        uint256 amountBNBReflection = ((amountBNB - amountBNBLiquidity) * _reflectionFeeSell) / (_marketingFeeSell + _reflectionFeeSell);
        uint256 amountBNBMarketing = amountBNB - (amountBNBReflection + amountBNBLiquidity);
        _marketingWallet.transfer(amountBNBMarketing);

        if (amountToLiquify > 0) {
            dexRouter.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                _marketingWallet,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        } else {
            amountBNBReflection += amountBNBLiquidity;
        }

        try reflector.deposit{value: amountBNBReflection}() {} catch {}
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _hasLiqBeenAdded = true;
            _liqAddBlock = block.number;
            _liqAddStamp = block.timestamp;

            swapAndLiquifyEnabled = true;
        }
    }

    function setWalletToWalletTax(bool state) external onlyOwner {
        walletToWalletTax = state;
    }

	function migrateReflector(address r) external onlyOwner {
		reflector.recover();
		reflector = DividendDistributor(r);
		reflector.deposit{value: address(this).balance}();
	}

	function migrateReflectorEmergency(address r) external onlyOwner {
		reflector = DividendDistributor(r);
	}

	function setGasLimit(bool enabled, uint256 limit) external onlyOwner {
		gasLimitEnabled = enabled;
    	antiSniperGasLimit = limit;
	}

	function rescue() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}