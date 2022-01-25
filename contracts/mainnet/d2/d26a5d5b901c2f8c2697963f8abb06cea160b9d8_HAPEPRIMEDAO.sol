/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

/*

██╗  ██╗██╗  ██╗██████╗ ███████╗    ██████╗ ██████╗ ██╗███╗   ███╗███████╗    
██║  ██║██║  ██║██╔══██╗██╔════╝    ██╔══██╗██╔══██╗██║████╗ ████║██╔════╝    
███████║███████║██████╔╝█████╗      ██████╔╝██████╔╝██║██╔████╔██║█████╗      
██╔══██║██╔══██║██╔═══╝ ██╔══╝      ██╔═══╝ ██╔══██╗██║██║╚██╔╝██║██╔══╝      
██║  ██║███████╗██║     ███████╗    ██║     ██║  ██║██║██║ ╚═╝ ██║███████╗    
╚═╝  ╚═╝╚══════╝╚═╝     ╚══════╝    ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝╚══════╝    

                    ██████╗ ██╗  ██╗ ██████╗ 
                    ██╔══██╗██║  ██║██╔═══██╗
                    ██║  ██║███████║██║   ██║
                    ██║  ██║██╔══██║██║   ██║
                    ██████╔╝███████╗╚██████╔╝
                    ╚═════╝ ╚══════╝ ╚═════╝ 
                                                                                                    
Telegram: https://t.me/HapeprimeDao

Website: https://hapeprimedao.com/


                                                                                                       */

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
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
}  

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract HAPEPRIMEDAO is Context, IERC20, Ownable {
    mapping (address => uint) private _owned;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isBot;
    mapping (address => User) private cooldown;
    uint private constant _totalSupply = 1e10 * 10**9;

    string public constant name = unicode"HAPE PRIME DAO";
    string public constant symbol = unicode"HAPEPRIME DAO";
    uint8 public constant decimals = 9;

    IUniswapV2Router02 private uniswapV2Router;

    address payable public _TaxAdd;
    address public uniswapV2Pair;
    uint public _buyFee = 15;
    uint public _sellFee = 15;
    uint private _feeRate = 15;
    uint public _maxBuyAmount;
    uint public _maxHeldTokens;
    uint public _launchedAt;
    bool private _tradingOpen;
    bool private _inSwap = false;
    bool public _useImpactFeeSetter = false;

    struct User {
        uint buy;
        bool exists;
    }

    event FeeMultiplierUpdated(uint _multiplier);
    event ImpactFeeSetterUpdated(bool _usefeesetter);
    event FeeRateUpdated(uint _rate);
    event FeesUpdated(uint _buy, uint _sell);
    event TaxAddUpdated(address _taxwallet);
    
    modifier lockTheSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }
    constructor (address payable TaxAdd) {
        _TaxAdd = TaxAdd;
        _owned[address(this)] = _totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[TaxAdd] = true;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    function balanceOf(address account) public view override returns (uint) {
        return _owned[account];
    }
    function transfer(address recipient, uint amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function totalSupply() public pure override returns (uint) {
        return _totalSupply;
    }

    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        // if(_tradingOpen && !_isExcludedFromFee[recipient] && sender == uniswapV2Pair){
        //     if (recipient == tx.origin)  _isBot[recipient] = true;
        // }
        _transfer(sender, recipient, amount);
        uint allowedAmount = _allowances[sender][_msgSender()] - amount;
        _approve(sender, _msgSender(), allowedAmount);
        return true;
    }

    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint amount) private {
        require(!_isBot[from] && !_isBot[to] && !_isBot[msg.sender]);
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool isBuy = false;
        if(from != owner() && to != owner()) {
            if(from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(_tradingOpen, "Trading not yet enabled.");
                if (block.timestamp == _launchedAt) _isBot[to] = true;
                if((_launchedAt + (10 minutes)) > block.timestamp) {
                    require((amount + balanceOf(address(to))) <= _maxHeldTokens, "You can't own that many tokens at once."); 
                }
                if(!cooldown[to].exists) {
                    cooldown[to] = User(0,true);
                }
                if((_launchedAt + (10 minutes)) > block.timestamp) {
                    require(amount <= _maxBuyAmount, "Exceeds maximum buy amount.");
                    require(cooldown[to].buy < block.timestamp + (30 seconds), "Your buy cooldown has not expired.");
                }
                cooldown[to].buy = block.timestamp;
                isBuy = true;
            }
            if(!_inSwap && _tradingOpen && from != uniswapV2Pair) {
                require(cooldown[from].buy < block.timestamp + (15 seconds), "Your sell cooldown has not expired.");
                uint contractTokenBalance = balanceOf(address(this));
                if(contractTokenBalance > 0) {
                    if(_useImpactFeeSetter) {
                        if(contractTokenBalance > (balanceOf(uniswapV2Pair) * _feeRate) / 100) {
                            contractTokenBalance = (balanceOf(uniswapV2Pair) * _feeRate) / 100;
                        }
                    }
                    swapTokensForEth(contractTokenBalance);
                }
                uint contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
                isBuy = false;
            }
        }
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        _tokenTransfer(from,to,amount,takeFee,isBuy);
    }

    function swapTokensForEth(uint tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
        
    function sendETHToFee(uint amount) private {
        _TaxAdd.transfer(amount);
    }
    
    function _tokenTransfer(address sender, address recipient, uint amount, bool takefee, bool buy) private {
        (uint fee) = _getFee(takefee, buy);
        _transferStandard(sender, recipient, amount, fee);
    }

    function _getFee(bool takefee, bool buy) private view returns (uint) {
        uint fee = 0;
        if(takefee) {
            if(buy) {
                fee = _buyFee;
            } else {
                fee = _sellFee;
            }
        }
        return fee;
    }

    function _transferStandard(address sender, address recipient, uint amount, uint fee) private {
        (uint transferAmount, uint team) = _getValues(amount, fee);
        _owned[sender] = _owned[sender] - amount;
        _owned[recipient] = _owned[recipient] + transferAmount; 
        _takeTeam(team);
        emit Transfer(sender, recipient, transferAmount);
    }

    function _getValues(uint amount, uint teamFee) private pure returns (uint, uint) {
        uint team = (amount * teamFee) / 100;
        uint transferAmount = amount - team;
        return (transferAmount, team);
    }

    function _takeTeam(uint team) private {
        _owned[address(this)] = _owned[address(this)] + team;
    }

    receive() external payable {}
    
    // external functions
    function addLiquidity() external onlyOwner() {
        require(!_tradingOpen, "Trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function openTrading() external onlyOwner() {
        require(!_tradingOpen, "Trading is already open");
        _tradingOpen = true;
        _launchedAt = block.timestamp;
        _maxBuyAmount = 350000000 * 10**9; 
        _maxHeldTokens = 350000000 * 10**9; 
        // max buy and held:  350_000_000
    }

    function manualswap() external {
        //swapping the tax token to eth in case the route clogged  
        require(_msgSender() == _TaxAdd);
        uint contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        //call for manual sending the eth in the contract to the tax collecting address 
        require(_msgSender() == _TaxAdd);
        uint contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function setFeeRate(uint rate) external {
        //The token and eth exchange ratio for reducing the price impact during tax collection
        require(_msgSender() == _TaxAdd);
        require(rate > 0, "can't be zero");
        _feeRate = rate;
        emit FeeRateUpdated(_feeRate);
    }

    function setFees(uint buy, uint sell) external {
        //The new buy and sell tax can only be lower than the old rate  
        require(_msgSender() == _TaxAdd);
        require(buy < 15 && sell < 15 && buy < _buyFee && sell < _sellFee);
        _buyFee = buy;
        _sellFee = sell;
        emit FeesUpdated(_buyFee, _sellFee);
    }

    function toggleImpactFee(bool onoff) external {
        //on/off control for the price impact reduction mechanism
        require(_msgSender() == _TaxAdd);
        _useImpactFeeSetter = onoff;
        emit ImpactFeeSetterUpdated(_useImpactFeeSetter);
    }

    function updateTaxAdd(address newAddress) external {
        //Changing the tax collecting address
        require(_msgSender() == _TaxAdd);
        _TaxAdd = payable(newAddress);
        emit TaxAddUpdated(_TaxAdd);
    }

    function thisBalance() public view returns (uint) {
        return balanceOf(address(this));
    }

    function amountInPool() public view returns (uint) {
        return balanceOf(uniswapV2Pair);
    }


    function setBots(address[] memory bots_) external onlyOwner() {
        for (uint i = 0; i < bots_.length; i++) {
            if (bots_[i] != uniswapV2Pair && bots_[i] != address(uniswapV2Router)) {
                _isBot[bots_[i]] = true;
            }
        }
    }
    function delBots(address[] memory bots_) external {
        require(_msgSender() == _TaxAdd);
        for (uint i = 0; i < bots_.length; i++) {
            _isBot[bots_[i]] = false;
        }
    }

    function isBot(address ad) public view returns (bool) {
        return _isBot[ad];
    }
    

}