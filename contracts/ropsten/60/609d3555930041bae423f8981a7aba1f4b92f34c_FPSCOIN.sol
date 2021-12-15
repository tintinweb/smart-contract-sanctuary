/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// File: FPSCOIN smart contract.sol



pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

interface ILosslessController {
    function beforeTransfer(address sender, address recipient, uint256 amount) external;

    function beforeTransferFrom(address msgSender, address sender, address recipient, uint256 amount) external;

    function beforeApprove(address sender, address spender, uint256 amount) external;

    function beforeIncreaseAllowance(address msgSender, address spender, uint256 addedValue) external;

    function beforeDecreaseAllowance(address msgSender, address spender, uint256 subtractedValue) external;

    function afterApprove(address sender, address spender, uint256 amount) external;

    function afterTransfer(address sender, address recipient, uint256 amount) external;

    function afterTransferFrom(address msgSender, address sender, address recipient, uint256 amount) external;

    function afterIncreaseAllowance(address sender, address spender, uint256 addedValue) external;

    function afterDecreaseAllowance(address sender, address spender, uint256 subtractedValue) external;
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
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}
 
contract FPSCOIN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "FPSCOIN";
    string private constant _symbol = "FPSCOIN";
    uint8 private constant _decimals = 18;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping (address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _taxFee = 25;
    uint256 private _teamFee = 45;
    mapping(uint256 => uint256) private daysToPercent;
    mapping(address => uint256) private firstBuyTime;
    mapping(address => uint256) private firstsell;    // date of sell
    mapping(address => uint256) private numberOfDays;
    address payable private _marketingAddress;
    address payable private _liquidityAddress;
    address payable private _devAddress;
    address payable private _teamAddress;
    address payable private _rewardAndtouranementAddress;
    address payable private _privateSellAddress;
    address payable private _airdropsAddress;
    address payable private _publicSaleAddress;
    address payable private _chikenWinnerAddress;
    address payable private _reserveForFuturesExchangesAddress;
     //lossless Declair
    address public recoveryAdmin;
    address private recoveryAdminCanditate;
    bytes32 private recoveryAdminKeyHash;
    address public admin;
    uint256 public timelockPeriod;
    uint256 public losslessTurnOffTimestamp;
    bool public isLosslessTurnOffProposed;
    bool public isLosslessOn = true;
    ILosslessController private lossless;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event RecoveryAdminChangeProposed(address indexed candidate);
    event RecoveryAdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event LosslessTurnOffProposed(uint256 turnOffDate);
    event LosslessTurnedOff();
    event LosslessTurnedOn();
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private liquidityAdded = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private _maxTxAmount = _tTotal;
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor (address payable marketingAddress, address payable devAddress, address payable rewardAndtouranementAddress, address payable privateSellAddress, address payable airdropsAddress, address payable reserveForFuturesExchangesAddress, address payable chikenWinnerAddress, address payable liquidityAddress, address admin_, address recoveryAdmin_, uint256 timelockPeriod_, address lossless_)  {
        _marketingAddress = marketingAddress;
        _devAddress = devAddress;
        _rewardAndtouranementAddress = rewardAndtouranementAddress;
        _privateSellAddress = privateSellAddress;
        _airdropsAddress = airdropsAddress;
        _reserveForFuturesExchangesAddress = reserveForFuturesExchangesAddress;
        _chikenWinnerAddress = chikenWinnerAddress;
        _liquidityAddress = liquidityAddress;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_devAddress] = true;
        _isExcludedFromFee[_rewardAndtouranementAddress] = true;
        _isExcludedFromFee[_privateSellAddress] = true;
        _isExcludedFromFee[_airdropsAddress] = true;
        _isExcludedFromFee[_reserveForFuturesExchangesAddress] = true;
        _isExcludedFromFee[_chikenWinnerAddress] = true;
        _isExcludedFromFee[_liquidityAddress] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
        //lossless constructor
        admin = admin_;
        recoveryAdmin = recoveryAdmin_;
        timelockPeriod = timelockPeriod_;
        lossless = ILosslessController(lossless_);
    }
    //lossless modifier
     modifier lssAprove(address spender, uint256 amount) {
        if (isLosslessOn) {
            lossless.beforeApprove(_msgSender(), spender, amount);
            _;
            lossless.afterApprove(_msgSender(), spender, amount);
        } else {
            _;
        }
    }

    modifier lssTransfer(address recipient, uint256 amount) {
        if (isLosslessOn) {
            lossless.beforeTransfer(_msgSender(), recipient, amount);
            _;
            lossless.afterTransfer(_msgSender(), recipient, amount);
        } else {
            _;
        }
    }

    modifier lssTransferFrom(address sender, address recipient, uint256 amount) {
        if (isLosslessOn) {
            lossless.beforeTransferFrom(_msgSender(),sender, recipient, amount);
            _;
            lossless.afterTransferFrom(_msgSender(), sender, recipient, amount);
        } else {
            _;
        }
    }

    modifier lssIncreaseAllowance(address spender, uint256 addedValue) {
        if (isLosslessOn) {
            lossless.beforeIncreaseAllowance(_msgSender(), spender, addedValue);
            _;
            lossless.afterIncreaseAllowance(_msgSender(), spender, addedValue);
        } else {
            _;
        }
    }

    modifier lssDecreaseAllowance(address spender, uint256 subtractedValue) {
        if (isLosslessOn) {
            lossless.beforeDecreaseAllowance(_msgSender(), spender, subtractedValue);
            _;
            lossless.afterDecreaseAllowance(_msgSender(), spender, subtractedValue);
        } else {
            _;
        }
    }

    modifier onlyRecoveryAdmin() {
        require(_msgSender() == recoveryAdmin, "LERC20: Must be recovery admin");
        _;
    }
    
    //lossless management
    
    function getAdmin() external view returns (address) {
        return admin;
    }

    function transferOutBlacklistedFunds(address[] calldata from) external {
        require(_msgSender() == address(lossless), "LERC20: Only lossless contract");
        for (uint i = 0; i < from.length; i++) {
            _transfer(from[i], address(lossless), balanceOf(from[i]));
        }
    }

    function setLosslessAdmin(address newAdmin) public onlyRecoveryAdmin {
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function transferRecoveryAdminOwnership(address candidate, bytes32 keyHash) public onlyRecoveryAdmin {
        recoveryAdminCanditate = candidate;
        recoveryAdminKeyHash = keyHash;
        emit RecoveryAdminChangeProposed(candidate);
    }

    function acceptRecoveryAdminOwnership(bytes memory key) external {
        require(_msgSender() == recoveryAdminCanditate, "LERC20: Must be canditate");
        require(keccak256(key) == recoveryAdminKeyHash, "LERC20: Invalid key");
        emit RecoveryAdminChanged(recoveryAdmin, recoveryAdminCanditate);
        recoveryAdmin = recoveryAdminCanditate;
    }

    function proposeLosslessTurnOff() public onlyRecoveryAdmin {
        losslessTurnOffTimestamp = block.timestamp + timelockPeriod;
        isLosslessTurnOffProposed = true;
        emit LosslessTurnOffProposed(losslessTurnOffTimestamp);
    }

    function executeLosslessTurnOff() public onlyRecoveryAdmin {
        require(isLosslessTurnOffProposed, "LERC20: TurnOff not proposed");
        require(losslessTurnOffTimestamp <= block.timestamp, "LERC20: Time lock in progress");
        isLosslessOn = false;
        isLosslessTurnOffProposed = false;
        emit LosslessTurnedOff();
    }

    function executeLosslessTurnOn() public onlyRecoveryAdmin {
        isLosslessTurnOffProposed = false;
        isLosslessOn = true;
        emit LosslessTurnedOn();
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
    
        function totalSupply() public pure override returns (uint256) {
            return _tTotal;
        }
    
        function balanceOf(address account) public view override returns (uint256) {
            return tokenFromReflection(_rOwned[account]);
        }
    
        function transfer(address recipient, uint256 amount) public override lssTransfer(recipient, amount)  returns (bool) {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
        
        function allowance(address owner, address spender) public view override returns (uint256) {
            return _allowances[owner][spender];
        }
    
        function approve(address spender, uint256 amount) public virtual override lssAprove(spender, amount) returns (bool) {
        require((amount == 0) || (_allowances[_msgSender()][spender] == 0), "LERC20: Cannot change non zero allowance");
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
        function transferFrom(address sender, address recipient, uint256 amount) public override lssTransferFrom(sender, recipient, amount) returns (bool) {
            _transfer(sender, recipient, amount);
            _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
            return true;
        }
        
        function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
            require(rAmount <= _rTotal,"Amount must be less than total reflections");
            uint256 currentRate = _getRate();
            return rAmount.div(currentRate);
        }
        
        function removeAllFee() private {
        if (_taxFee == 0 && _teamFee == 0) return;
        _taxFee = 0;
        _teamFee = 0;
        }
    
        function restoreAllFee() private {
        _taxFee = 3;
        _teamFee = 7;
        }
        
        function setFee(uint256 multiplier) private {
        _taxFee =25-((multiplier.mul(3).div(5) ))  ; 
        _teamFee =45-((multiplier.mul(63).div(50) )); 
        }
        
        function _approve(address owner, address spender, uint256 amount) private {
            require(owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");
            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
        
        
    
        function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if (from != owner() && to != owner()) {
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] ) {
                require(tradingOpen);
                require(amount <= _maxTxAmount);
                require(firstBuyTime[to]<block.timestamp);
                _teamFee = 7;
                _taxFee = 3;
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                require(amount <= balanceOf(uniswapV2Pair).mul(3).div(100) && amount <= _maxTxAmount); // Price impact
                numberOfDays[from]= firstsell[from]-firstBuyTime[from];
                if (numberOfDays[from] <(30 days)){
                    setFee(numberOfDays[from]);
                 }
                else {
                _teamFee = 7 ;
                _taxFee = 3 ;
                        }
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee;
        }
        
         function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
            _approve(address(this), address(uniswapV2Router), tokenAmount);
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
        }
        
        function sendETHToFee(uint256 amount) private {
            _marketingAddress.transfer(amount.div(5));
            _devAddress.transfer(amount.div(5));
            _teamAddress.transfer(amount.div(5));
            _rewardAndtouranementAddress.transfer(amount.div(5));
            _chikenWinnerAddress.transfer(amount.div(5));
        }
        
        function openTrading() public onlyOwner {
            require(liquidityAdded);
            tradingOpen = true;
        }
        
     function addLiquidity() external onlyOwner() {
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            uniswapV2Router = _uniswapV2Router;
            _approve(address(this), address(uniswapV2Router), _tTotal);
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
            uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
            swapEnabled = true;
            liquidityAdded = true;
            _maxTxAmount = 3000000000 * 10**9;
            IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
        }    

    function manualswap() external {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
    
    function setSwapEnabled(bool enabled) external onlyOwner(){
            swapEnabled = enabled;
        }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    
    receive() external payable {}

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _taxFee, _teamFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 teamFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(teamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }
}