/**
 *Submitted for verification at Etherscan.io on 2021-07-19
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

contract StrategyCvxRenBTCV1 is StrategyBase {
    // want token
    address public constant renbtc = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    uint8 public want_decimals = 8;

    // convex staking constants
    address public stakingPool = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    uint256 public stakingPoolId = 6;
    address public constant rewardTokenCRV = 0xD533a949740bb3306d119CC777fa900bA034cd52; 
    address public constant rewardTokenCVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public rewardPool = 0x8E299C62EeD737a5d5a53539dF37b5356a27b07D;
	
    // curve constants
    address public constant curvePool = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
    address public constant rencrv = 0x49849C98ae39Fff122806C06791Fa73784FB3675;
		
    // slippage protection for one-sided ape in/out
    uint256 public slippageProtectionIn = 50; // max 0.5%
    uint256 public slippageProtectionOut = 50; // max 0.5%
    uint256 public constant DENOMINATOR = 10000;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public StrategyBase(renbtc, _governance, _strategist, _controller, _timelock)
    {		        
        IERC20(renbtc).safeApprove(curvePool, uint256(-1));
        IERC20(rencrv).safeApprove(curvePool, uint256(-1));
        IERC20(rencrv).safeApprove(stakingPool, uint256(-1));
        want_decimals = ERC20(renbtc).decimals();
    }

    // **** Views **** //
    
    function setSlippageProtection(uint256 _in, uint256 _out) public{
        require(msg.sender == governance, "!governance");
        require(_in < DENOMINATOR && _in > 0, "!_in");
        require(_out < DENOMINATOR && _out > 0, "!_out");
        slippageProtectionIn = _in;
        slippageProtectionOut = _out;
    }

    function setStakingPoolId(uint256 _poolId) public{
        require(msg.sender == governance, "!governance");
        stakingPoolId = _poolId;
    }

    function setStakingPool(address _pool) public{
        require(msg.sender == governance, "!governance");
        stakingPool = _pool;
        IERC20(rencrv).safeApprove(stakingPool, uint256(-1));
    }

    function setRewardPool(address _pool) public{
        require(msg.sender == governance, "!governance");
        rewardPool = _pool;
    }

    function _convertWantToBuyback(uint256 _lpAmount) internal override returns (address, uint256){
        require(_lpAmount > 0, '!_lpAmount');
		
        _swapUniswap(want, weth, _lpAmount);
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        return (weth, _weth);
    }

    function harvest() public override onlyBenignCallers {

        // Collects reward tokens
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
		
        uint256 _wethAmount = IERC20(weth).balanceOf(address(this));
        if (_wethAmount > 0){	
            uint256 _buybackLpAmount = _wethAmount.mul(performanceFee).div(performanceMax);
            if (buybackEnabled == true && _buybackLpAmount > 0){
                buybackAndNotify(weth, _buybackLpAmount);
            }
             
            _swapUniswap(weth, want, IERC20(weth).balanceOf(address(this)));
            uint256 _wantBal = IERC20(want).balanceOf(address(this));
            if (_wantBal > 0){
                lastHarvestBlock = block.number;
                lastHarvestInWant = _wantBal;
                deposit();
            }
        }
    }

    function deposit() public override {
        uint256 _wantAmt = IERC20(want).balanceOf(address(this));
        uint256 _expectedOut = _wantAmt.mul(1e18).div(virtualPriceToWant());
        uint256 _maxSlip = _expectedOut.mul(DENOMINATOR.sub(slippageProtectionIn)).div(DENOMINATOR);
        if (_wantAmt > 0 && checkSlip(_wantAmt, _maxSlip)) {
            uint256[2] memory amounts = [_wantAmt, 0];
            ICurveFi_2(curvePool).add_liquidity(amounts, _maxSlip);
        }
		
        uint256 _lpAmt = IERC20(rencrv).balanceOf(address(this));
        require(_lpAmt > 0, "!_lpAmt");
        ICvxBooster(stakingPool).depositAll(stakingPoolId, true);
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        if (_amount == 0){
            return 0;
        }
		
        uint256 _wantBefore = IERC20(want).balanceOf(address(this));
	
        uint256 requiredWant = estimateRequiredLP(_amount);
        requiredWant = requiredWant.mul(DENOMINATOR.add(slippageProtectionOut)).div(DENOMINATOR);// try to remove bit more
		
        uint256 _lpAmount = IERC20(rencrv).balanceOf(address(this));
        uint256 _withdrawFromStaking = _lpAmount < requiredWant? requiredWant.sub(_lpAmount) : 0;
			
        if (_withdrawFromStaking > 0){
            uint256 maxInStaking = ICvxBaseRewardPool(rewardPool).balanceOf(address(this));
            uint256 _toWithdraw = maxInStaking < _withdrawFromStaking? maxInStaking : _withdrawFromStaking;		
            ICvxBaseRewardPool(rewardPool).withdrawAndUnwrap(_toWithdraw, false);			
        }
		    	
        _lpAmount = IERC20(rencrv).balanceOf(address(this));
        if (_lpAmount > 0){
            requiredWant = requiredWant > _lpAmount?  _lpAmount : requiredWant;

            uint256 maxSlippage = requiredWant.mul(DENOMINATOR.sub(slippageProtectionOut)).div(DENOMINATOR);

            if (want_decimals < 18) {
                maxSlippage = maxSlippage.div(10**(uint256(uint8(18) - want_decimals)));
            }
            ICurveFi_2(curvePool).remove_liquidity_one_coin(requiredWant, 0, maxSlippage);
        }
		
        uint256 _wantAfter = IERC20(want).balanceOf(address(this));		
        return _wantAfter.sub(_wantBefore);
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external override returns (uint256 balance) {
        require(address(_asset) != want, 'wantToken');
        require(address(_asset) != rencrv, 'lpToken');
        balance = _withdrawNonWantAsset(_asset);
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
	
    function balanceOfPool() public override view returns (uint256){
        uint256 lpAmt = ICvxBaseRewardPool(rewardPool).balanceOf(address(this));
        lpAmt = lpAmt.add(IERC20(rencrv).balanceOf(address(this)));
        return crvLPToWant(lpAmt);
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