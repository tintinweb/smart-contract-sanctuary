/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

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
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
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

contract Balancer {
    constructor() public {
    }
}

interface FTPAntiBot {
    function scanAddress(address _address, address _safeAddress, address _origin) external returns (bool);
    function registerBlock(address _recipient, address _sender) external;
}

contract DownDogeToken is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint256 internal _tokenTotal = 1000000000000 * 10**9;
    string private _name = "DownDogeToken";
    string private _symbol = "DDT";
    uint8 private _decimals = 9;

    uint256 private _banCount = 0;

    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal _reflectionTotal = (MAX - (MAX % _tokenTotal));

    mapping (address => bool) private _bots;
    mapping(address => bool) isExcludedFromFee;
    mapping(address => bool) internal _isExcluded;
    address[] internal _excluded;
    
    //@dev The fee contains two decimal places so 350 = 3.5%
    uint256 public _feeDecimal = 2;
    uint256 public _charityFee = 200;

    uint256 public _rebalanceCallerFee = 800;

    uint256 public _burnFeeTotal;
    uint256 public _charityFeeTotal;

    bool public tradingEnabled = false;
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public rebalanceEnalbed = true;
    bool public antibotEnabled = true;
    
    uint256 public minTokensBeforeSwap = 5;
    uint256 public minEthBeforeSwap = 5;
    
    uint256 public liquidityAddedAt;

    uint256 public lastRebalance = block.timestamp ;
    uint256 public rebalanceInterval = 33 minutes;
    
    FTPAntiBot private AntiBot;
    IUniswapV2Router02 public  uniswapV2Router;
    address public  uniswapV2Pair;
    address public balancer;

    address payable private _charity = payable(0x92b9D1b665f3dA8862e8A74083b69c699b90A6Ad);
    
    event TradingEnabled(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapedTokenForEth(uint256 EthAmount, uint256 TokenAmount);
    event SwapedEthForTokens(uint256 EthAmount, uint256 TokenAmount, uint256 CallerReward, uint256 AmountBurned);
    event BanAddress(address Address, address Origin);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() public {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
            
        uniswapV2Router = _uniswapV2Router;

        if (antibotEnabled) {
            initAntiBot();
        }
 
        
        balancer = address(new Balancer());
        
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_charity] = true;
        
        //@dev Exclude uniswapV2Pair from taking rewards
        _isExcluded[uniswapV2Pair] = true;
        _excluded.push(uniswapV2Pair);
        
        _reflectionBalance[_msgSender()] = _reflectionTotal;
        emit Transfer(address(0), _msgSender(), _tokenTotal);
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

    function totalSupply() public override view returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address _account) public override view returns (uint256) {
        if (_isExcluded[_account]) return _tokenBalance[_account];
        return tokenFromReflection(_reflectionBalance[_account]);
    }

    function transfer(address _recipient, uint256 _amount) public override virtual returns (bool) {
       _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override virtual returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, _msgSender(), _allowances[_sender][_msgSender()].sub( _amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public virtual  returns (bool) {
        _approve(
            _msgSender(),
            _spender,
            _allowances[_msgSender()][_spender].add(_addedValue)
        );
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            _spender,
            _allowances[_msgSender()][_spender].sub(
                _subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcluded(address _account) public view returns (bool) {
        return _isExcluded[_account];
    }

    function reflectionFromToken(uint256 _tokenAmount, bool _deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(_tokenAmount <= _tokenTotal, "Amount must be less than supply");
        if (!_deductTransferFee) {
            return _tokenAmount.mul(_getReflectionRate());
        } else {
            return
                _tokenAmount.sub(_tokenAmount.mul(_charityFee).div(10** _feeDecimal + 2)).mul(
                    _getReflectionRate()
                );
        }
    }

    function tokenFromReflection(uint256 reflectionAmount)
        public
        view
        returns (uint256)
    {
        require(
            reflectionAmount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getReflectionRate();
        return reflectionAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(
            account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            "Uniswap router cannot be excluded."
        );
        require(account != address(this), 'The contract it self cannot be excluded');
        require(!_isExcluded[account], "Account is already excluded");
        if (_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(
                _reflectionBalance[account]
            );
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tokenBalance[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(tradingEnabled || sender == owner() || recipient == owner() ||
                isExcludedFromFee[sender] || isExcludedFromFee[recipient], "Trading is locked before presale.");
        
        //@dev Limit the transfer to ____ tokens for first 3 minutes
        require(block.timestamp > liquidityAddedAt + 3 minutes  || amount <= 1e9, "You cannot transfer more than 1 token.");
        

        if (antibotEnabled) {
            _checkBot(recipient, sender, tx.origin); //calls AntiBot for results
        }
        //@dev Don't swap or buy tokens when uniswapV2Pair is sender, to avoid circular loop
        if(!inSwapAndLiquify && sender != uniswapV2Pair) {
            bool swap = true;
            uint256 _contractBalance = address(this).balance;

            if (antibotEnabled) {
                require(!_bots[sender]); // Local logic for banning based on AntiBot results 
            }

            //@dev Buyback
            if(block.timestamp > lastRebalance + rebalanceInterval 
                && rebalanceEnalbed 
                && _contractBalance >= minEthBeforeSwap){
                buyAndBurnToken(_contractBalance);
                swap = false;
            }
            //@dev Buy eth
            if(swap) {
                uint256 contractTokenBalance = balanceOf(address(this));
                bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;
                 if (overMinTokenBalance && swapAndLiquifyEnabled) {
                    swapTokensForEth();    
                }
           }
        }
        
        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();

        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient] && !inSwapAndLiquify){
            transferAmount = collectFee(amount);
        }

        //@dev Transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));

        //@dev If any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);
        }

        emit Transfer(sender, recipient, transferAmount);
        
        if (antibotEnabled) {
            AntiBot.registerBlock(sender, recipient); //Tells AntiBot to start watching
        }
    }

    function _checkBot(address _recipient, address _sender, address _origin) private {
        if((_recipient == uniswapV2Pair || _sender == uniswapV2Pair) && tradingEnabled){
            bool recipientAddress = AntiBot.scanAddress(_recipient, uniswapV2Pair, _origin); // Get AntiBot result
            bool senderAddress = AntiBot.scanAddress(_sender, uniswapV2Pair, _origin); // Get AntiBot result
            if(recipientAddress){
                _banSeller(_recipient);
                _banSeller(_origin);
                emit BanAddress(_recipient, _origin);
            }
            if(senderAddress){
                _banSeller(_sender);
                _banSeller(_origin);
                emit BanAddress(_sender, _origin);
            }
        }
    }

    function _banSeller(address _address) private {
        if(!_bots[_address])
            _banCount += 1;
        _bots[_address] = true;
    }
    
    function collectFee(uint256 amount) private returns (uint256) {
        uint256 transferAmount = amount;
        
        //@dev Take charity fee
        if(_charityFee != 0){
            uint256 charityFee = amount.mul(_charityFee).div(10**(_feeDecimal + 2));
            transferAmount = transferAmount.sub(charityFee);
            sendETHToCharityWallet(charityFee);
        }
        
        return transferAmount;
    }

    function _getReflectionRate() private view returns (uint256) {
        uint256 reflectionSupply = _reflectionTotal;
        uint256 tokenSupply = _tokenTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reflectionBalance[_excluded[i]] > reflectionSupply ||
                _tokenBalance[_excluded[i]] > tokenSupply
            ) return _reflectionTotal.div(_tokenTotal);
            reflectionSupply = reflectionSupply.sub(
                _reflectionBalance[_excluded[i]]
            );
            tokenSupply = tokenSupply.sub(_tokenBalance[_excluded[i]]);
        }
        if (reflectionSupply < _reflectionTotal.div(_tokenTotal))
            return _reflectionTotal.div(_tokenTotal);
        return reflectionSupply.div(tokenSupply);
    }

    function swapTokensForEth() private lockTheSwap {
        uint256 tokenAmount = balanceOf(address(this));
        uint256 ethAmount = address(this).balance;
        
        //@dev Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        //@dev Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
        ethAmount = address(this).balance.sub(ethAmount);
        emit SwapedTokenForEth(tokenAmount,ethAmount);
    }

    function sendETHToCharityWallet(uint256 amount) private {
       _charity.transfer(amount);
    }
    
    function swapEthForTokens(uint256 EthAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: EthAmount}(
                0,
                path,
                address(balancer),
                block.timestamp
            );
    }
   
    function buyAndBurnToken(uint256 _contractBalance) private lockTheSwap {
        lastRebalance = block.timestamp;
        
        //@dev Uniswap doesn't allow for a token to by itself, so we have to use an external account, which in this case is called the balancer
        swapEthForTokens(_contractBalance);

        //@dev How much tokens we swaped into
        uint256 swapedTokens = balanceOf(address(balancer));
        uint256 rewardForCaller = swapedTokens.mul(_rebalanceCallerFee).div(10**(_feeDecimal + 2));
        uint256 amountToBurn = swapedTokens.sub(rewardForCaller);
        
        uint256 rate =  _getReflectionRate();

        _reflectionBalance[tx.origin] = _reflectionBalance[tx.origin].add(rewardForCaller.mul(rate));
        _reflectionBalance[address(balancer)] = 0;
        
        _burnFeeTotal = _burnFeeTotal.add(amountToBurn);
        _tokenTotal = _tokenTotal.sub(amountToBurn);
        _reflectionTotal = _reflectionTotal.sub(amountToBurn.mul(rate));

        emit Transfer(address(balancer), tx.origin, rewardForCaller);
        emit Transfer(address(balancer), address(0), amountToBurn);
        emit SwapedEthForTokens(_contractBalance, swapedTokens, rewardForCaller, amountToBurn);
    }
    
    function setExcludedFromFee(address account, bool excluded) public onlyOwner {
        isExcludedFromFee[account] = excluded;
    }
    
    function setSwapAndLiquifyEnabled(bool enabled) public onlyOwner {
        swapAndLiquifyEnabled = enabled;
        SwapAndLiquifyEnabledUpdated(enabled);
    }
    
    function banCount() external view returns (uint256) {
        return _banCount;
    }

      function checkIfBanned(address _address) external view returns (bool) { //Tool for traders to verify ban status
        bool _banBool = false;
        if(_bots[_address])
            _banBool = true;
        return _banBool;
    }

       function manualBan(address _a) external onlyOwner() {
       _banSeller(_a);
    }

    function removeBan(address _a) external onlyOwner() {
        _bots[_a] = false;
        _banCount -= 1;
    }
    
    function setCharityFee(uint256 fee) public onlyOwner {
        _charityFee = fee;
    }
    
    function setRebalanceCallerFee(uint256 fee) public onlyOwner {
        _rebalanceCallerFee = fee;
    }
    
    function setMinTokensBeforeSwap(uint256 amount) public onlyOwner {
        minTokensBeforeSwap = amount;
    }
    
    function setMinEthBeforeSwap(uint256 amount) public onlyOwner {
        minEthBeforeSwap = amount;
    }
    
    function setRebalanceInterval(uint256 interval) public onlyOwner {
        rebalanceInterval = interval;
    }
    
    function setRebalanceEnabled(bool enabled) public onlyOwner {
        rebalanceEnalbed = enabled;
    }

    function contractBalance() external view onlyOwner() returns (uint256) {
        return address(this).balance;
    }
    
    function enableTrading() external onlyOwner() {
        tradingEnabled = true;
        TradingEnabled(true);
        liquidityAddedAt = block.timestamp;
    }

    function initAntiBot() public onlyOwner() {
        FTPAntiBot _antiBot = FTPAntiBot(0x88C4dEDd24DC99f5C9b308aC25DA34889A5073Ab);
        AntiBot = _antiBot;
    }

    function assignAntiBot(address _address) external onlyOwner() { // for antibots updates
        FTPAntiBot _antiBot = FTPAntiBot(_address);                
        AntiBot = _antiBot;
    }

    function setAntiBotEnabled(bool enabled) public onlyOwner() { // for antibots updates
        antibotEnabled = enabled;
        initAntiBot(); 
    }
    
    receive() external payable {}
}