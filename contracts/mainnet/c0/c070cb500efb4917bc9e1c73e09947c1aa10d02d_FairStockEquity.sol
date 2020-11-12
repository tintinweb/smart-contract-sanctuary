pragma solidity ^0.5.0;

contract Context {
    constructor () internal {}
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}


pragma solidity ^0.5.0;

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


pragma solidity ^0.5.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

contract Governor is Context {
    address private _guardian;

    event GovernorTransferred(address indexed previousGuardian, address indexed newGuardian);

    constructor () internal {
        _guardian = _msgSender();
        emit GovernorTransferred(address(0), _guardian);
    }

    function governor() public view returns (address) {
        return _guardian;
    }

    modifier onlyGovernor() {
        require(isGovernor(), "Caller is not the governor!");
        _;
    }

    function isGovernor() public view returns (bool) {
        return _msgSender() == _guardian;
    }

    function transferGovernor(address newGovernor) public onlyGovernor {
        _transferGovernor(newGovernor);
    }

    function _transferGovernor(address newGovernor) internal {
        require(newGovernor != address(0), "New governor is the zero address!");
        emit GovernorTransferred(_guardian, newGovernor);
        _guardian = newGovernor;
    }
}

pragma solidity ^0.5.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;
}

pragma solidity ^0.5.5;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.16;

interface IUniswapV2Router02 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

pragma solidity ^0.5.16;

contract FairStockEquity is Ownable, Governor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct businessModule {
        address moduleAddress;
        uint256 running;
        uint256 mintRatio;
    }

    mapping(address => businessModule) public modulePool;

    IERC20[3] public tokens;

    uint256 public startTime;
    uint256 constant public stockIssueLimit = 10000 * (10 ** 18);
    uint256 public stockIssueRemain = stockIssueLimit;
    uint256 constant public tokenLockRatio = 5000;
    uint256 constant public tokenMainRatio = 10;
    mapping(address => uint256) public stockShares;
    uint256 public balanceMainSH = 0;
    uint256 public balanceLockSH = 0;

    mapping(address => bool) public depositTokens;
    mapping(address => mapping(address => uint256)) public depositPool;

    uint256 public profitPercentMT;
    uint256 public balanceMainMT = 0;
    uint256 public mintDegree;

    uint256 public profitPercentPJ;
    uint256 public balanceMainPJ = 0;

    IUniswapV2Router02 public uniswapV2Router02;
    address public dataSource;
    uint256 public gasFeeForCallback;

    event eSetToken(address tokenAddress, bool running);
    event eSetUniswapV2Router02(address previousUniswapV2Router02, address newUniswapV2Router02);
    event eSetDataSource(address previousDataSource, address newDataSource);
    event eSetProfitPercentMT(uint256 previousProfitPercentMT, uint256 newProfitPercentMT);
    event eSetProfitPercentPJ(uint256 previousProfitPercentTeam, uint256 newProfitPercentTeam);
    event eSetMintDegree(uint256 previousMintDegree, uint256 newMintDegree);
    event eSetModule(address previousModuleAddress, address newModuleAddress,
        uint256 previousModuleRunning, uint256 newModuleRunning,
        uint256 previousMintRatio, uint256 newMintRatio);

    event eInvest(address indexed user, uint256 stockAmount, uint256 timestamp);
    event eReduce(address indexed user, uint256 stockAmount, uint256 timestamp);
    event eBusiness(address indexed module, address indexed user,
        uint256 payAmount, uint256 bonusAmount, uint256 mintShare, uint256 profitMT, uint256 timestamp);
    event eDepositLPT(address indexed user, address token, uint256 lptAmount, uint256 timestamp);
    event eWithdrawLPT(address indexed user, address token, uint256 lptAmount, uint256 timestamp);
    event eWithdrawMT(address indexed user, uint256 gasForCallback, uint256 timestamp);
    event eWithdrawCallback(address indexed user, uint256 indexed tx, uint256 amount, uint256 timestamp);
    event eSwap(uint256 amountIn, uint256 timestamp);

    constructor (address _mainToken, address _lockToken, address _stockToken,
        address _uniswapV2Router02, address _dataSource, uint256 _startTime) public {

        tokens = [IERC20(_mainToken),
        IERC20(_lockToken),
        IERC20(_stockToken)];

        setUniswapV2Router02(_uniswapV2Router02);
        setDataSource(_dataSource);

        setGasFeeForCallback(10 ** 16);
        setMintDegree(10000);
        setProfitPercentMT(5000);
        setProfitPercentPJ(500);
        startTime = _startTime;
    }

    function() external payable {
    }

    modifier onlyDataSource() {
        require(_msgSender() == dataSource, "NOT DataSource!");
        _;
    }

    modifier checkStart(){
        require(block.timestamp > startTime, "not start");
        _;
    }

    function setStartTime(uint256 _startTime)
    public onlyOwner {
        require(_startTime > startTime, "wrong time!");
        startTime = _startTime;
    }

    function setLPT(address _tokenAddress, bool _running)
    public onlyOwner {
        depositTokens[_tokenAddress] = _running;
        emit eSetToken(_tokenAddress, _running);
    }

    function setGasFeeForCallback(uint256 _gasFeeForCallback)
    public onlyOwner {
        gasFeeForCallback = _gasFeeForCallback;
    }

    function setUniswapV2Router02(address _newUniswapV2Router02)
    public onlyOwner {
        emit eSetUniswapV2Router02(address(uniswapV2Router02), _newUniswapV2Router02);
        uniswapV2Router02 = IUniswapV2Router02(_newUniswapV2Router02);
    }

    function setDataSource(address _newDataSource)
    public onlyOwner {
        emit eSetDataSource(dataSource, _newDataSource);
        dataSource = _newDataSource;
    }

    function setModule(address moduleAddress, uint256 moduleRunning, uint256 mintRatio)
    public onlyOwner {
        emit eSetModule(modulePool[moduleAddress].moduleAddress, moduleAddress,
            modulePool[moduleAddress].running, moduleRunning,
            modulePool[moduleAddress].mintRatio, mintRatio);
        modulePool[moduleAddress] = businessModule(moduleAddress, moduleRunning, mintRatio);
    }

    function setMintDegree(uint256 _mintDegree)
    public onlyOwner {
        emit eSetMintDegree(mintDegree, _mintDegree);
        mintDegree = _mintDegree;
    }

    function setProfitPercentMT(uint256 _profitPercent)
    public onlyGovernor {
        emit eSetProfitPercentMT(profitPercentMT, _profitPercent);
        profitPercentMT = _profitPercent;
    }

    function setProfitPercentPJ(uint256 _profitPercent)
    public onlyGovernor {
        emit eSetProfitPercentPJ(profitPercentPJ, _profitPercent);
        profitPercentPJ = _profitPercent;
    }

    function getCostAmount(uint256 stockAmount)
    public view
    returns (uint256 _mainTokenAmount, uint256 _lockTokenAmount, uint256 _stockTokenAmount){
        uint256 stockTotalSupply = stockIssueLimit.sub(stockIssueRemain);
        if (stockTotalSupply > 0) {
            return (
            stockAmount.mul(balanceMainSH).div(stockTotalSupply),
            _getLockAmount(stockAmount),
            stockAmount.mul(tokens[2].balanceOf(address(this))).div(stockTotalSupply));
        }
        return (
        stockAmount.mul(tokenMainRatio),
        _getLockAmount(stockAmount),
        0);
    }

    function _getLockAmount(uint256 stockAmount)
    internal pure
    returns (uint256 _lockTokenAmount){
        return stockAmount.mul(tokenLockRatio);
    }

    function _getMintShareAmount(uint256 _availableAmount, uint256 _mintRatio)
    internal view returns (uint256 _mintShare){
        return _availableAmount.mul(_mintRatio).mul(mintDegree).div(1000000);
    }

    function invest(uint256 stockAmount)
    public checkStart {
        require(stockAmount > 0, "Cannot invest 0");
        require(stockIssueRemain >= stockAmount, "Have no enough stock!");
        (uint256 _mainTokenAmount,uint256 _lockTokenAmount,uint256 _stockTokenAmount) = getCostAmount(stockAmount);

        stockIssueRemain = stockIssueRemain.sub(stockAmount);

        balanceMainSH = balanceMainSH.add(_mainTokenAmount);
        balanceLockSH = balanceLockSH.add(_lockTokenAmount);

        tokens[0].safeTransferFrom(_msgSender(), address(this), _mainTokenAmount);
        tokens[1].safeTransferFrom(_msgSender(), address(this), _lockTokenAmount);
        if (_stockTokenAmount > 0) {
            tokens[2].safeTransferFrom(_msgSender(), address(this), _stockTokenAmount);
        }

        stockShares[_msgSender()] = stockShares[_msgSender()].add(stockAmount);

        emit eInvest(_msgSender(), stockAmount, block.timestamp);
    }

    function reduceShare(uint256 stockAmount)
    public checkStart {
        require(stockAmount > 0, "Cannot reduce 0");
        require(stockShares[_msgSender()] >= stockAmount, "You have no enough stock!");

        (uint256 mainTokeAmount, uint256 lockTokenAmount,uint256 stockTokenAmount) = getCostAmount(stockAmount);

        stockShares[_msgSender()] = stockShares[_msgSender()].sub(stockAmount);
        stockIssueRemain = stockIssueRemain.add(stockAmount);
        balanceMainSH = balanceMainSH.sub(mainTokeAmount);
        balanceLockSH = balanceLockSH.sub(lockTokenAmount);

        tokens[0].safeTransfer(_msgSender(), mainTokeAmount);
        tokens[1].safeTransfer(_msgSender(), lockTokenAmount);
        if (stockTokenAmount > 0) {
            tokens[2].safeTransfer(_msgSender(), stockTokenAmount);
        }

        emit eReduce(_msgSender(), stockAmount, block.timestamp);
    }

    function business(address user, uint256 payAmount, uint256 availableAmount, uint256 bonusAmount)
    public checkStart {
        require(payAmount > 0, "Illegal payAmount!");
        businessModule memory module = modulePool[_msgSender()];
        require(module.moduleAddress != address(0), "Illegal module!");
        require(module.running == 1, "Module is not running!");

        tokens[0].safeTransferFrom(_msgSender(), address(this), payAmount);

        uint256 profitSum = payAmount.mul(module.mintRatio).div(100);
        uint256 profitMT = 0;
        uint256 profitPJ = 0;
        profitMT = profitSum.mul(profitPercentMT).div(10000);
        profitPJ = profitSum.mul(profitPercentPJ).div(10000);

        require(balanceMainSH.add(payAmount) >= profitMT.add(profitPJ).add(bonusAmount), "Insufficient Balance!");

        balanceMainMT = balanceMainMT.add(profitMT);
        balanceMainPJ = balanceMainPJ.add(profitPJ);
        balanceMainSH = balanceMainSH.add(payAmount).sub(profitMT).sub(profitPJ).sub(bonusAmount);

        uint256 mintShareAmount = _getMintShareAmount(availableAmount, module.mintRatio);

        if (bonusAmount > 0) {
            tokens[0].safeTransfer(user, bonusAmount);
        }
        if (mintShareAmount > 0) {
            tokens[2].mint(user, mintShareAmount);
        }
        emit eBusiness(_msgSender(), user, payAmount, bonusAmount, mintShareAmount, profitMT, block.timestamp);
    }

    function depositLPT(address _token, uint256 _lptAmount)
    public checkStart {
        require(depositTokens[_token], "illegal token");
        require(_lptAmount > 0, "Cannot deposit 0");
        IERC20(_token).safeTransferFrom(_msgSender(), address(this), _lptAmount);
        depositPool[_msgSender()][_token] = depositPool[_msgSender()][_token].add(_lptAmount);
        emit eDepositLPT(_msgSender(), _token, _lptAmount, block.timestamp);
    }

    function withdrawLPT(address _token, uint256 _lptAmount)
    public checkStart {
        require(_lptAmount > 0, "Cannot withdraw 0");
        require(depositPool[_msgSender()][_token] >= _lptAmount, "Insufficient Balance!");
        depositPool[_msgSender()][_token] = depositPool[_msgSender()][_token].sub(_lptAmount);
        IERC20(_token).safeTransfer(_msgSender(), _lptAmount);
        emit eWithdrawLPT(_msgSender(), _token, _lptAmount, block.timestamp);
    }

    function withdrawMT()
    public payable checkStart {
        require(msg.value >= gasFeeForCallback, "Insufficient gas fee!");
        Address.toPayable(dataSource).transfer(msg.value);
        emit eWithdrawMT(_msgSender(), msg.value, block.timestamp);
    }

    function withdrawPJ()
    public onlyOwner checkStart {
        require(balanceMainPJ > 0, "Insufficient Balance!");
        uint256 amount = balanceMainPJ;
        balanceMainPJ = 0;
        tokens[0].safeTransfer(_msgSender(), amount);
    }

    function withdrawCallback(address _user, uint256 _tx, uint256 _amount)
    public onlyDataSource checkStart {
        require(_amount > 0, "Cannot withdraw 0");
        require(balanceMainMT >= _amount, "Insufficient Balance!");
        balanceMainMT = balanceMainMT.sub(_amount);
        tokens[0].safeTransfer(_user, _amount);
        emit eWithdrawCallback(_user, _tx, _amount, block.timestamp);
    }

    function swapMainToStock(
        uint256 amountIn,
        uint256 amountOutReduce,
        uint256 deadline)
    public onlyDataSource checkStart {
        require(balanceMainSH > stockIssueLimit &&
            amountIn <= balanceMainSH.sub(stockIssueLimit),
            "Insufficient Balance!");
        address[] memory path = new address[](2);
        path[0] = address(tokens[0]);
        path[1] = address(tokens[2]);

        uint[] memory amounts = uniswapV2Router02.getAmountsOut(amountIn, path);
        tokens[0].approve(address(uniswapV2Router02), amountIn);
        balanceMainSH = balanceMainSH.sub(amountIn);

        uniswapV2Router02.swapExactTokensForTokens(
            amountIn, amounts[1].mul(amountOutReduce).div(100),
            path, address(this), deadline);
        emit eSwap(amountIn, block.timestamp);
    }
}