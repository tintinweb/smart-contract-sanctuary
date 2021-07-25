/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

pragma solidity 0.6.12;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
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
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface UniswapRouterV2 {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IController {
    function vaults(address) external view returns (address);
    function devfund() external view returns (address);
    function treasury() external view returns (address);
}

interface IMasterchef {
    function notifyBuybackReward(uint256 _amount) external;
}

abstract contract StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    // caller whom this strategy trust 
    mapping(address => bool) public benignCallers;

    // Perfomance fee 30% to buyback
    uint256 public performanceFee = 30000;
    uint256 public constant performanceMax = 100000;
    
    uint256 public treasuryFee = 0;
    uint256 public constant treasuryMax = 100000;

    uint256 public devFundFee = 0;
    uint256 public constant devFundMax = 100000;

    // delay yield profit realization
    uint256 public delayBlockRequired = 1000;
    uint256 public lastHarvestBlock;
    uint256 public lastHarvestInWant;

    // buyback ready
    bool public buybackEnabled = true;
    address public constant mmToken = 0xa283aA7CfBB27EF0cfBcb2493dD9F4330E0fd304;
    address public constant masterChef = 0xf8873a6080e8dbF41ADa900498DE0951074af577;

    // Tokens
    address public want;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // User accounts
    address public governance;
    address public controller;
    address public strategist;
    address public timelock;

    address public constant univ2Router2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    constructor(address _want, address _governance, address _strategist, address _controller, address _timelock) public {
        require(_want != address(0));
        require(_governance != address(0));
        require(_strategist != address(0));
        require(_controller != address(0));
        require(_timelock != address(0));

        want = _want;
        governance = _governance;
        strategist = _strategist;
        controller = _controller;
        timelock = _timelock;
    }

    modifier onlyBenevolent {
        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-3074.md#allowing-txorigin-as-signer
        require(msg.sender == governance || msg.sender == strategist);
        _;
    }
    
    modifier onlyBenignCallers {
        require(msg.sender == governance || msg.sender == strategist || benignCallers[msg.sender]);
        _;
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public virtual view returns (uint256);

    function balanceOf() public view returns (uint256) {
        uint256 delayReduction = 0;
        uint256 currentBlock = block.number;
        if (delayBlockRequired > 0 && lastHarvestInWant > 0 && currentBlock.sub(lastHarvestBlock) < delayBlockRequired){
            uint256 diffBlock = lastHarvestBlock.add(delayBlockRequired).sub(currentBlock);
            delayReduction = lastHarvestInWant.mul(diffBlock).mul(1e18).div(delayBlockRequired).div(1e18);
        }
        return balanceOfWant().add(balanceOfPool()).sub(delayReduction);
    }

    function setBenignCallers(address _caller, bool _enabled) external{
        require(msg.sender == governance, "!governance");
        benignCallers[_caller] = _enabled;
    }

    function setDelayBlockRequired(uint256 _delayBlockRequired) external {
        require(msg.sender == governance, "!governance");
        delayBlockRequired = _delayBlockRequired;
    }

    function setDevFundFee(uint256 _devFundFee) external {
        require(msg.sender == timelock, "!timelock");
        devFundFee = _devFundFee;
    }

    function setTreasuryFee(uint256 _treasuryFee) external {
        require(msg.sender == timelock, "!timelock");
        treasuryFee = _treasuryFee;
    }

    function setPerformanceFee(uint256 _performanceFee) external {
        require(msg.sender == timelock, "!timelock");
        performanceFee = _performanceFee;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setBuybackEnabled(bool _buybackEnabled) external {
        require(msg.sender == governance, "!governance");
        buybackEnabled = _buybackEnabled;
    }
    
    function deposit() public virtual;

    function withdraw(IERC20 _asset) external virtual returns (uint256 balance);
    
    function _withdrawNonWantAsset(IERC20 _asset) internal returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
				
        uint256 _feeDev = _amount.mul(devFundFee).div(devFundMax);
        uint256 _feeTreasury = _amount.mul(treasuryFee).div(treasuryMax);

        address _vault = IController(controller).vaults(address(want));

        if (buybackEnabled == true && (_feeDev > 0 || _feeTreasury > 0)) {
            (address _buybackPrinciple, uint256 _buybackAmount) = _convertWantToBuyback(_feeDev.add(_feeTreasury));
            buybackAndNotify(_buybackPrinciple, _buybackAmount);
        }

        IERC20(want).safeTransfer(_vault, _amount.sub(_feeDev).sub(_feeTreasury));
    }
	
    function buybackAndNotify(address _buybackPrinciple, uint256 _buybackAmount) internal {
        if (buybackEnabled == true && _buybackAmount > 0) {
            _swapUniswap(_buybackPrinciple, mmToken, _buybackAmount);
            uint256 _mmBought = IERC20(mmToken).balanceOf(address(this));
            IERC20(mmToken).safeTransfer(masterChef, _mmBought);
            IMasterchef(masterChef).notifyBuybackReward(_mmBought);
        }
    }

    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawSome(balanceOfPool());
        balance = IERC20(want).balanceOf(address(this));
        address _vault = IController(controller).vaults(address(want));
        IERC20(want).safeTransfer(_vault, balance);
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);	
	
    function _convertWantToBuyback(uint256 _lpAmount) internal virtual returns (address, uint256);
    
    function harvest() public virtual;
    
    function figureOutPath(address _from, address _to, uint256 _amount) public view returns (bool useSushi, address[] memory swapPath){
        address[] memory path;
        address[] memory sushipath;
        
        path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        
        if (_to == mmToken && buybackEnabled == true) {
            sushipath = new address[](2);
            sushipath[0] = _from;
            sushipath[1] = _to;
        }

        uint256 _sushiOut = sushipath.length > 0? UniswapRouterV2(sushiRouter).getAmountsOut(_amount, sushipath)[sushipath.length - 1] : 0;
        uint256 _uniOut = sushipath.length > 0? UniswapRouterV2(univ2Router2).getAmountsOut(_amount, path)[path.length - 1] : 1;

        bool useSushi = _sushiOut > _uniOut? true : false;		
        address[] memory swapPath = useSushi ? sushipath : path;
		
        return (useSushi, swapPath);
    }
	
    function _swapUniswap(address _from, address _to, uint256 _amount) internal {
        (bool useSushi, address[] memory swapPath) = figureOutPath(_from, _to, _amount);
        address _router = useSushi? sushiRouter : univ2Router2;
        _swapUniswapWithDetailConfig(_from, _to, _amount, 1, swapPath, _router);
        
    }
	
    function _swapUniswapWithDetailConfig(address _from, address _to, uint256 _amount, uint256 _amountOutMin, address[] memory _swapPath, address _router) internal {
        require(IERC20(_from).balanceOf(address(this)) >= _amount, '!notEnoughtAmountIn');
        if (_amount > 0){			
            IERC20(_from).safeApprove(_router, 0);
            IERC20(_from).safeApprove(_router, _amount);
            UniswapRouterV2(_router).swapExactTokensForTokens(_amount, _amountOutMin, _swapPath, address(this), now);
        }
    }
}

interface ICurveFi_2 {
    function get_virtual_price() external view returns (uint256);
    function calc_token_amount(uint256[2] calldata amounts, bool deposit) external view returns (uint256);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external;
}

interface ICvxBaseRewardPool {
    function getReward(address _account, bool _claimExtras) external returns(bool);
    function earned(address account) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);
}

interface ICvxMinter {
    function reductionPerCliff() external view returns (uint256);
    function totalCliffs() external view returns (uint256);
    function maxSupply() external view returns (uint256);
}

interface ICvxBooster {
    function depositAll(uint256 _pid, bool _stake) external returns(bool);
}

interface AggregatorV3Interface {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

}

interface IUnitVaultParameters{
	function tokenDebtLimit(address asset) external view returns (uint);
}

interface IUnitVault{
	function calculateFee(address asset, address user, uint amount) external view returns (uint);
	function getTotalDebt(address asset, address user) external view returns (uint);
	function debts(address asset, address user) external view returns (uint);
	function collaterals(address asset, address user) external view returns (uint);
	function tokenDebts(address asset) external view returns (uint);
}

interface IUnitCDPManager {
	function exit(address asset, uint assetAmount, uint usdpAmount) external returns (uint);
	function join(address asset, uint assetAmount, uint usdpAmount) external;
	function oracleRegistry() external view returns (address);
	function liquidationPrice_q112(address asset, address owner) external view returns (uint);
}

abstract contract StrategyUnitBase is StrategyBase {
    // Unit Protocol module: https://github.com/unitprotocol/core/blob/master/CONTRACTS.md	
    address public constant cdpMgr01 = 0x0e13ab042eC5AB9Fc6F43979406088B9028F66fA;
    address public constant unitVault = 0xb1cFF81b9305166ff1EFc49A129ad2AfCd7BCf19;		
    address public constant unitVaultParameters = 0xB46F8CF42e504Efe8BEf895f848741daA55e9f1D;	
    address public constant debtToken = 0x1456688345527bE1f37E9e627DA0837D6f08C925;
    address public constant eth_usd = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    // sub-strategy related constants
    address public collateral;
    uint256 public collateralDecimal = 1e18;
    address public unitOracle;
    uint256 public collateralPriceDecimal = 1;
    bool public collateralPriceEth = false;
	
    // configurable minimum collateralization percent this strategy would hold for CDP
    uint256 public minRatio = 150;
    // collateralization percent buffer in CDP debt actions
    uint256 public ratioBuff = 200;
    uint256 public constant ratioBuffMax = 10000;

    constructor(
        address _collateral,
        uint256 _collateralDecimal,
        address _collateralOracle,
        uint256 _collateralPriceDecimal,
        bool _collateralPriceEth,
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_want, _governance, _strategist, _controller, _timelock)
    {
        require(_want == _collateral, '!mismatchWant');
		    
        collateral = _collateral;   
        collateralDecimal = _collateralDecimal;
        unitOracle = _collateralOracle;
        collateralPriceDecimal = _collateralPriceDecimal;
        collateralPriceEth = _collateralPriceEth;		
		
        IERC20(collateral).safeApprove(unitVault, uint256(-1));
        IERC20(debtToken).safeApprove(unitVault, uint256(-1));
    }

    // **** Modifiers **** //
	
    modifier onlyCDPInUse {
        uint256 collateralAmt = getCollateralBalance();
        require(collateralAmt > 0, '!zeroCollateral');
		
        uint256 debtAmt = getDebtBalance();
        require(debtAmt > 0, '!zeroDebt');		
        _;
    }
	
    function getCollateralBalance() public view returns (uint256) {
        return IUnitVault(unitVault).collaterals(collateral, address(this));
    }
	
    function getDebtBalance() public view returns (uint256) {
        return IUnitVault(unitVault).getTotalDebt(collateral, address(this));
    }	
	
    function getDebtWithoutFee() public view returns (uint256) {
        return IUnitVault(unitVault).debts(collateral, address(this));
    }		
	
    function getDueFee() public view returns (uint256) {
        uint256 totalDebt = getDebtBalance();
        uint256 borrowed = getDebtWithoutFee();
        return totalDebt > borrowed? totalDebt.sub(borrowed) : 0;
    }	

    // **** Getters ****
	
    function debtLimit() public view returns (uint256){
        return IUnitVaultParameters(unitVaultParameters).tokenDebtLimit(collateral);
    }
	
    function debtUsed() public view returns (uint256){
        return IUnitVault(unitVault).tokenDebts(collateral);
    }
	
    function balanceOfPool() public override view returns (uint256){
        return getCollateralBalance();
    }

    function collateralValue(uint256 collateralAmt) public view returns (uint256){
        uint256 collateralPrice = getLatestCollateralPrice();
        return collateralAmt.mul(collateralPrice).mul(1e18).div(collateralDecimal).div(collateralPriceDecimal);// debtToken in 1e18 decimal
    }

    function currentRatio() public onlyCDPInUse view returns (uint256) {	    
        uint256 collateralAmt = collateralValue(getCollateralBalance()).mul(100);
        uint256 debtAmt = getDebtBalance();		
        return collateralAmt.div(debtAmt);
    } 
    
    // if borrow is true (for lockAndDraw): return (maxDebt - currentDebt) if positive value, otherwise return 0
    // if borrow is false (for redeemAndFree): return (currentDebt - maxDebt) if positive value, otherwise return 0
    function calculateDebtFor(uint256 collateralAmt, bool borrow) public view returns (uint256) {
        uint256 maxDebt = collateralAmt > 0? collateralValue(collateralAmt).mul(ratioBuffMax).div(_getBufferedMinRatio(ratioBuffMax)) : 0;
		
        uint256 debtAmt = getDebtBalance();
		
        uint256 debt = 0;
        
        if (borrow && maxDebt >= debtAmt){
            debt = maxDebt.sub(debtAmt);
        } else if (!borrow && debtAmt >= maxDebt){
            debt = debtAmt.sub(maxDebt);
        }
        
        return (debt > 0)? debt : 0;
    }
	
    function _getBufferedMinRatio(uint256 _multiplier) internal view returns (uint256){
        return minRatio.mul(_multiplier).mul(ratioBuffMax.add(ratioBuff)).div(ratioBuffMax).div(100);
    }

    function borrowableDebt() public view returns (uint256) {
        uint256 collateralAmt = getCollateralBalance();
        return calculateDebtFor(collateralAmt, true);
    }

    function requiredPaidDebt(uint256 _redeemCollateralAmt) public view returns (uint256) {
        uint256 totalCollateral = getCollateralBalance();
        uint256 collateralAmt = _redeemCollateralAmt >= totalCollateral? 0 : totalCollateral.sub(_redeemCollateralAmt);
        return calculateDebtFor(collateralAmt, false);
    }

    // **** sub-strategy implementation ****
    function _convertWantToBuyback(uint256 _lpAmount) internal virtual override returns (address, uint256);
	
    function _depositUSDP(uint256 _usdpAmt) internal virtual;
	
    function _withdrawUSDP(uint256 _usdpAmt) internal virtual;
	
    // **** Oracle (using chainlink) ****
	
    function getLatestCollateralPrice() public view returns (uint256){
        require(unitOracle != address(0), '!_collateralOracle');	
		
        (,int price,,,) = AggregatorV3Interface(unitOracle).latestRoundData();
		
        if (price > 0){		
            int ethPrice = 1;
            if (collateralPriceEth){
               (,ethPrice,,,) = AggregatorV3Interface(eth_usd).latestRoundData();// eth price from chainlink in 1e8 decimal		
            }
            return uint256(price).mul(collateralPriceDecimal).mul(uint256(ethPrice)).div(1e8).div(collateralPriceEth? 1e18 : 1);
        } else{
            return 0;
        }
    }

    // **** Setters ****
	
    function setMinRatio(uint256 _minRatio) external onlyBenevolent {
        minRatio = _minRatio;
    }	
	
    function setRatioBuff(uint256 _ratioBuff) external onlyBenevolent {
        ratioBuff = _ratioBuff;
    }
	
    // **** Unit Protocol CDP actions ****
	
    function addCollateralAndBorrow(uint256 _collateralAmt, uint256 _usdpAmt) internal {   
        require(_usdpAmt.add(debtUsed()) < debtLimit(), '!exceedLimit');
        IUnitCDPManager(cdpMgr01).join(collateral, _collateralAmt, _usdpAmt);		
    } 
	
    function repayAndRedeemCollateral(uint256 _collateralAmt, uint _usdpAmt) internal { 
        IUnitCDPManager(cdpMgr01).exit(collateral, _collateralAmt, _usdpAmt);     		
    } 

    // **** State Mutation functions ****
	
    function keepMinRatio() external onlyCDPInUse onlyBenignCallers {		
        uint256 requiredPaidback = requiredPaidDebt(0);
        if (requiredPaidback > 0){
            _withdrawUSDP(requiredPaidback);
			
            uint256 _actualPaidDebt = IERC20(debtToken).balanceOf(address(this));
            uint256 _debtBal = _actualPaidDebt;
            uint256 _fee = getDueFee();
			
            require(_actualPaidDebt > _fee, '!notEnoughForFee');	
            _actualPaidDebt = _actualPaidDebt.sub(_fee);// unit protocol will charge fee first
            _actualPaidDebt = _capMaxDebtPaid(_actualPaidDebt);			
			
            require(_debtBal >= _actualPaidDebt.add(_fee), '!notEnoughRepayment');
            repayAndRedeemCollateral(0, _actualPaidDebt);
        }
    }
	
    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {	
            uint256 _newDebt = calculateDebtFor(_want.add(getCollateralBalance()), true);
            if (_newDebt > 0){
                addCollateralAndBorrow(_want, _newDebt);
                uint256 wad = IERC20(debtToken).balanceOf(address(this));
                _depositUSDP(_newDebt > wad? wad : _newDebt);
            }
        }
    }
	
    // to avoid repay all debt
    function _capMaxDebtPaid(uint256 _actualPaidDebt) internal view returns(uint256){
        uint256 _maxDebtToRepay = getDebtWithoutFee().sub(ratioBuffMax);
        return _actualPaidDebt >= _maxDebtToRepay? _maxDebtToRepay : _actualPaidDebt;
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        if (_amount == 0){
            return _amount;
        }
		
        _withdrawUnderlyingDebt(_amount);
		
        bool _fullWithdraw = _amount >= balanceOfPool();
        uint256 _wantBefore = IERC20(want).balanceOf(address(this));
        if (!_fullWithdraw){
            uint256 _actualPaidDebt = IERC20(debtToken).balanceOf(address(this));
            uint256 _debtBal = _actualPaidDebt;
            uint256 _fee = getDueFee();
		
            require(_actualPaidDebt > _fee, '!notEnoughForFee');				
            _actualPaidDebt = _actualPaidDebt.sub(_fee); // unit protocol will charge fee first
            _actualPaidDebt = _capMaxDebtPaid(_actualPaidDebt);
			
            require(_debtBal >= _actualPaidDebt.add(_fee), '!notEnoughRepayment');
            repayAndRedeemCollateral(_amount, _actualPaidDebt);			
        }else{
            require(IERC20(debtToken).balanceOf(address(this)) >= getDebtBalance(), '!notEnoughFullRepayment');
            repayAndRedeemCollateral(_amount, getDebtBalance());
            require(getDebtBalance() == 0, '!leftDebt');
            require(getCollateralBalance() == 0, '!leftCollateral');
        }
		
        uint256 _wantAfter = IERC20(want).balanceOf(address(this));		
        return _wantAfter.sub(_wantBefore);
    }
	
    function _withdrawUnderlyingDebt(uint256 _amount) internal {	        
        uint256 requiredPaidback = requiredPaidDebt(_amount);		
        if (requiredPaidback > 0){
            _withdrawUSDP(requiredPaidback);
        }
    }
    
}

contract StrategyUnitWETHV1 is StrategyUnitBase {
    // strategy specific
    address public constant weth_collateral = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public constant weth_collateral_decimal = 1e18;
    uint8 public want_decimals = 18;
    address public constant weth_oracle = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    uint256 public constant weth_price_decimal = 1;
    bool public constant weth_price_eth = false;
    bool public harvestToRepay = false;
	
    // farming in usdp3crv 
    address public constant usdp3crv = 0x7Eb40E450b9655f4B3cC4259BCC731c63ff55ae6;
    address public constant curvePool = 0x42d7025938bEc20B69cBae5A77421082407f053A;	

    // convex staking constants
    address public stakingPool = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    uint256 public stakingPoolId = 28;
    address public constant rewardTokenCRV = 0xD533a949740bb3306d119CC777fa900bA034cd52; 
    address public constant rewardTokenCVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public rewardPool = 0x24DfFd1949F888F91A0c8341Fc98a3F280a782a8;
    
    // slippage protection for one-sided ape in/out
    uint256 public slippageRepayment = 500; // max 5%
    uint256 public slippageProtectionIn = 50; // max 0.5%
    uint256 public slippageProtectionOut = 50; // max 0.5%
    uint256 public constant DENOMINATOR = 10000;

    constructor(address _governance, address _strategist, address _controller, address _timelock) 
        public StrategyUnitBase(
            weth_collateral,
            weth_collateral_decimal,
            weth_oracle,
            weth_price_decimal,
            weth_price_eth,
            weth_collateral,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        // approve for Curve pool and DEX
        IERC20(debtToken).safeApprove(curvePool, uint256(-1));
        IERC20(usdp3crv).safeApprove(curvePool, uint256(-1));        
        IERC20(usdp3crv).safeApprove(stakingPool, uint256(-1));		
        want_decimals = ERC20(weth_collateral).decimals();
    }
	
    // **** Setters ****
    
    function setSlippageProtection(uint256 _in, uint256 _out) public{
        require(msg.sender == governance, "!governance");
        require(_in < DENOMINATOR && _in > 0, "!_in");
        require(_out < DENOMINATOR && _out > 0, "!_out");
        slippageProtectionIn = _in;
        slippageProtectionOut = _out;
    }
    
    function setSlippageRepayment(uint256 _repaymentSlippage) public{
        require(msg.sender == governance, "!governance");
        require(_repaymentSlippage < DENOMINATOR && _repaymentSlippage > 0, "!_repaymentSlippage");
        slippageRepayment = _repaymentSlippage;
    }

    function setStakingPoolId(uint256 _poolId) public{
        require(msg.sender == governance, "!governance");
        stakingPoolId = _poolId;
    }

    function setStakingPool(address _pool) public{
        require(msg.sender == governance, "!governance");
        stakingPool = _pool;
        IERC20(usdp3crv).safeApprove(stakingPool, uint256(-1));
    }

    function setRewardPool(address _pool) public{
        require(msg.sender == governance, "!governance");
        rewardPool = _pool;
    }

    function setHarvestToRepay(bool _repay) public{
        require(msg.sender == governance, "!governance");
        harvestToRepay = _repay;
    }
	
    // **** State Mutation functions ****	 

    function _convertWantToBuyback(uint256 _lpAmount) internal override returns (address, uint256){
        return (weth_collateral, _lpAmount);
    }	
	
    function harvest() public override onlyBenevolent {

        // Collects reward tokens
        _convertRewards();
		
        uint256 _wethAmount = IERC20(weth).balanceOf(address(this));
        if (_wethAmount > 0){
            // only repay debt to skip reinvest in case of migration            
            if (harvestToRepay){
                _swapRewardsToDebt(_wethAmount, 1);
                return;
            }
		
            // Repay debt first
            uint256 dueFee = getDueFee();
            if (dueFee > 0){		
                uint256 _swapIn = calcToSwappedForFeeRepayment(dueFee, _wethAmount);			
                _swapRewardsToDebt(_swapIn, dueFee);
				
                require(IERC20(debtToken).balanceOf(address(this)) >= dueFee, '!notEnoughRepaymentDuringHarvest');
				
                uint256 debtTotalBefore = getDebtBalance();
                repayAndRedeemCollateral(0, dueFee);
                require(getDebtBalance() < debtTotalBefore, '!repayDebtDuringHarvest');
            }	

            // Buyback and Reinvest
            _wethAmount = IERC20(weth).balanceOf(address(this));	
            if (_wethAmount > 0){				
                uint256 _buybackLpAmount = _wethAmount.mul(performanceFee).div(performanceMax);
                if (buybackEnabled == true && _buybackLpAmount > 0){
                    buybackAndNotify(weth, _buybackLpAmount);
                }
             
                uint256 _wantBal = IERC20(want).balanceOf(address(this));
                if (_wantBal > 0){
                    lastHarvestBlock = block.number;
                    lastHarvestInWant = _wantBal;
                    deposit();
                }
            }
        }
    }
	
    function _convertRewards() internal {
        ICvxBaseRewardPool(rewardPool).getReward(address(this), true);
		
        uint256 _rewardCRV = IERC20(rewardTokenCRV).balanceOf(address(this));
        uint256 _rewardCVX = IERC20(rewardTokenCVX).balanceOf(address(this));

        if (_rewardCRV > 0) {
            address[] memory _swapPath = new address[](2);
            _swapPath[0] = rewardTokenCRV;
            _swapPath[1] = weth;
            _swapUniswapWithDetailConfig(rewardTokenCRV, weth, _rewardCRV, 1, _swapPath, sushiRouter);
        }

        if (_rewardCVX > 0) {
            address[] memory _swapPath = new address[](2);
            _swapPath[0] = rewardTokenCVX;
            _swapPath[1] = weth;
            _swapUniswapWithDetailConfig(rewardTokenCVX, weth, _rewardCVX, 1, _swapPath, sushiRouter);
        }
    }
	
    function _swapRewardsToDebt(uint256 _swapIn, uint256 _debtOutMin) internal {
        address[] memory _swapPath = new address[](2);
        _swapPath[0] = weth;
        _swapPath[1] = debtToken;
        _swapUniswapWithDetailConfig(weth, debtToken, _swapIn, _debtOutMin, _swapPath, sushiRouter);
    }
	
    function calcToSwappedForFeeRepayment(uint256 _dueFee, uint256 _toSwappedCurBal) public view returns (uint256){
        (,int ethPrice,,,) = AggregatorV3Interface(eth_usd).latestRoundData();// eth price from chainlink in 1e8 decimal
        uint256 toSwapped = _dueFee.mul(ERC20(weth).decimals()).mul(1e8).div(uint256(ethPrice)).div(ERC20(debtToken).decimals());
        uint256 _swapIn = toSwapped.mul(DENOMINATOR.add(slippageRepayment)).div(DENOMINATOR);
        _swapIn = _swapIn > _toSwappedCurBal ? _toSwappedCurBal : _swapIn;
        return _swapIn;
    }
	
    function _depositUSDP(uint256 _usdpAmt) internal override{	
        uint256 _wantAmt = IERC20(debtToken).balanceOf(address(this));
        uint256 _expectedOut = _wantAmt.mul(1e18).div(virtualPriceToWant());
        uint256 _maxSlip = _expectedOut.mul(DENOMINATOR.sub(slippageProtectionIn)).div(DENOMINATOR);
        if (_wantAmt > 0 && checkSlip(_wantAmt, _maxSlip)) {
            uint256[2] memory amounts = [_wantAmt, 0];
            ICurveFi_2(curvePool).add_liquidity(amounts, _maxSlip);
        }
		
        uint256 _lpAmt = IERC20(usdp3crv).balanceOf(address(this));
        require(_lpAmt > 0, "!_lpAmt");
        ICvxBooster(stakingPool).depositAll(stakingPoolId, true);
    }
	
    function _withdrawUSDP(uint256 _usdpAmt) internal override {
        if (_usdpAmt == 0){
            return;
        }
	
        uint256 requiredWant = estimateRequiredLP(_usdpAmt);
        requiredWant = requiredWant.mul(DENOMINATOR.add(slippageProtectionOut)).div(DENOMINATOR);// try to remove bit more
		
        uint256 _lpAmount = IERC20(usdp3crv).balanceOf(address(this));
        uint256 _withdrawFromStaking = _lpAmount < requiredWant? requiredWant.sub(_lpAmount) : 0;
			
        if (_withdrawFromStaking > 0){
            uint256 maxInStaking = ICvxBaseRewardPool(rewardPool).balanceOf(address(this));
            uint256 _toWithdraw = maxInStaking < _withdrawFromStaking? maxInStaking : _withdrawFromStaking;		
            ICvxBaseRewardPool(rewardPool).withdrawAndUnwrap(_toWithdraw, false);			
        }
		    	
        _lpAmount = IERC20(usdp3crv).balanceOf(address(this));
        if (_lpAmount > 0){
            requiredWant = requiredWant > _lpAmount?  _lpAmount : requiredWant;

            uint256 maxSlippage = requiredWant.mul(DENOMINATOR.sub(slippageProtectionOut)).div(DENOMINATOR);

            if (want_decimals < 18) {
                maxSlippage = maxSlippage.div(10**(uint256(uint8(18) - want_decimals)));
            }
            ICurveFi_2(curvePool).remove_liquidity_one_coin(requiredWant, 0, maxSlippage);
        }
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external override returns (uint256 balance) {
        require(usdp3crv != address(_asset), "!usdp3crv");
        require(debtToken != address(_asset), "!usdp");
        return _withdrawNonWantAsset(_asset);
    }

    // **** Views ****	
	
    function balanceOfCrvLPToken() public view returns (uint256){
        uint256 lpAmt = ICvxBaseRewardPool(rewardPool).balanceOf(address(this));
        lpAmt = lpAmt.add(IERC20(usdp3crv).balanceOf(address(this)));
        return lpAmt;
    }
	
    function balanceOfDebtToken() public view returns (uint256){
        uint256 lpAmt = balanceOfCrvLPToken();
        return crvLPToWant(lpAmt);
    }
	
    function virtualPriceToWant() public view returns (uint256) {
        if (want_decimals < 18){
            return ICurveFi_2(curvePool).get_virtual_price().div(10 ** (uint256(uint8(18) - want_decimals)));
        }else{
            return ICurveFi_2(curvePool).get_virtual_price();
        }
    }
	
    function estimateRequiredLP(uint256 _wantAmt) public view returns (uint256) {
        return _wantAmt.mul(1e18).div(virtualPriceToWant());
    }
	
    function checkSlip(uint256 _wantAmt, uint256 _maxSlip) public view returns (bool){
        uint256[2] memory amounts = [_wantAmt, 0];
        return ICurveFi_2(curvePool).calc_token_amount(amounts, true) >= _maxSlip;
    }
	
    function crvLPToWant(uint256 _lpAmount) public view returns (uint256) {
        if (_lpAmount == 0){
            return 0;
        }
        uint256 virtualOut = virtualPriceToWant().mul(_lpAmount).div(1e18);
        return virtualOut; 
    }   

    // only include CRV earned
    function getHarvestable() public view returns (uint256) {
        return ICvxBaseRewardPool(rewardPool).earned(address(this));
    }
	
    // https://etherscan.io/address/0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b#code#L1091
    function mintableCVX(uint256 _amount) public view returns (uint256) {
        uint256 _toMint = 0;
        uint256 supply = IERC20(rewardTokenCVX).totalSupply();
        uint256 cliff = supply.div(ICvxMinter(rewardTokenCVX).reductionPerCliff());
        uint256 totalCliffs = ICvxMinter(rewardTokenCVX).totalCliffs();
        if (cliff < totalCliffs){
            uint256 reduction = totalCliffs.sub(cliff);
            _amount = _amount.mul(reduction).div(totalCliffs);
            uint256 amtTillMax = ICvxMinter(rewardTokenCVX).maxSupply().sub(supply);
            if (_amount > amtTillMax){
                _amount = amtTillMax;
            }
            _toMint = _amount;
        }
        return _toMint;
    }

    function getHarvestableCVX() public view returns (uint256) {
        uint256 _crvEarned = getHarvestable();
        return mintableCVX(_crvEarned);
    }
}