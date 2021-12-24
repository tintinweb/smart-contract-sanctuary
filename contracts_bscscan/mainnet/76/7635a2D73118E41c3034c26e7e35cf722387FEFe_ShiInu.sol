// SPDX-License-Identifier: Unlicensed

/*
░██████╗██╗░░██╗██╗██╗███╗░░██╗██╗░░░██╗
██╔════╝██║░░██║██║██║████╗░██║██║░░░██║
╚█████╗░███████║██║██║██╔██╗██║██║░░░██║
░╚═══██╗██╔══██║██║██║██║╚████║██║░░░██║
██████╔╝██║░░██║██║██║██║░╚███║╚██████╔╝
╚═════╝░╚═╝░░╚═╝╚═╝╚═╝╚═╝░░╚══╝░╚═════╝░
Safe Degen Project By t.me/ShitMoonShots

ShiInu - SHIINU

Taxes on Buy: 5%
Taxes on Sell: 5%

Max Wallet: 3% from initial supply
Max transaction: 3% from initial supply

LP Locked 1 Day on mudra.website

LP lock extend program
Extend to 3 Days on 5K MarketCap
Extend to 1 Week on 10K MarketCap
Extend to 1 Month on 20K MarketCap
Extend to 3 Month on 50K MarketCap
And so on
*/

pragma solidity 0.8.10;

import "./Interface.sol";
import "./Library.sol";
import "./Abstract.sol";

contract ShiInu is Context, IERC20 { 
    using SafeMath for uint256;
    using Address for address;

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee; 

    address payable public Wallet_Marketing = payable(0x50Aa9F962529066406c84891Ef469DB256Fa88eE); 
    address payable public Wallet_Dev = payable(0x50Aa9F962529066406c84891Ef469DB256Fa88eE);
    address payable public constant Wallet_Burn = payable(0x000000000000000000000000000000000000dEaD); 


    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 9;
    uint256 private _tTotal = 10**12 * 10**_decimals;
    string private constant _name = "ShiInu"; 
    string private constant _symbol = unicode"SHIINU"; 

    uint8 private txCount = 0;
    uint8 private swapTrigger = 10; 

    uint256 public _Tax_On_Buy = 5;
    uint256 public _Tax_On_Sell = 5;

    uint256 public Percent_Marketing = 50;
    uint256 public Percent_Dev = 0;
    uint256 public Percent_Burn = 20;
    uint256 public Percent_AutoLP = 30; 

    uint256 public _maxWalletToken = _tTotal * 3 / 100;
    uint256 private _previousMaxWalletToken = _maxWalletToken;

    uint256 public _maxTxAmount = _tTotal * 3 / 100; 
    uint256 private _previousMaxTxAmount = _maxTxAmount;
                                     
                                     
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    event SwapAndLiquifyEnabledUpdated(bool true_or_false);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
        
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {

        _owner = 0x50Aa9F962529066406c84891Ef469DB256Fa88eE;
        emit OwnershipTransferred(address(0), _owner);

        _tOwned[owner()] = _tTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[Wallet_Marketing] = true; 
        _isExcludedFromFee[Wallet_Burn] = true;

        emit Transfer(address(0), owner(), _tTotal);

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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address theOwner, address theSpender) public view override returns (uint256) {
        return _allowances[theOwner][theSpender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
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

    receive() external payable {}

    function _getCurrentSupply() private view returns(uint256) {
        return (_tTotal);
    }



    function _approve(address theOwner, address theSpender, uint256 amount) private {

        require(theOwner != address(0) && theSpender != address(0), "ERR: zero address");
        _allowances[theOwner][theSpender] = amount;
        emit Approval(theOwner, theSpender, amount);

    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {

        if (to != owner() &&
            to != Wallet_Burn &&
            to != address(this) &&
            to != uniswapV2Pair &&
            from != owner() && to != Wallet_Dev && from != Wallet_Dev) {
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken,"Over wallet limit.");}

        if (from != owner() && to != Wallet_Dev && from != Wallet_Dev)
            require(amount <= _maxTxAmount, "Over transaction limit.");


        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");   

        if(
            txCount >= swapTrigger && 
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled 
            )
        {  
            
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > _maxTxAmount) {contractTokenBalance = _maxTxAmount;}
            txCount = 0;
            swapAndLiquify(contractTokenBalance);
        }
        
        bool takeFee = true;
        bool isBuy;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        } else {
         
            if(from == uniswapV2Pair){
                isBuy = true;
            }

            txCount++;

        }

        _tokenTransfer(from, to, amount, takeFee, isBuy);

    }
    
    function sendToWallet(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);

        }


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

            uint256 tokens_to_Burn = contractTokenBalance * Percent_Burn / 100;
            _tTotal = _tTotal - tokens_to_Burn;
            _tOwned[Wallet_Burn] = _tOwned[Wallet_Burn] + tokens_to_Burn;
            _tOwned[address(this)] = _tOwned[address(this)] - tokens_to_Burn; 

            uint256 tokens_to_M = contractTokenBalance * Percent_Marketing / 100;
            uint256 tokens_to_D = contractTokenBalance * Percent_Dev / 100;
            uint256 tokens_to_LP_Half = contractTokenBalance * Percent_AutoLP / 200;

            uint256 balanceBeforeSwap = address(this).balance;
            swapTokensForBNB(tokens_to_LP_Half + tokens_to_M + tokens_to_D);
            uint256 BNB_Total = address(this).balance - balanceBeforeSwap;

            uint256 split_M = Percent_Marketing * 100 / (Percent_AutoLP + Percent_Marketing + Percent_Dev);
            uint256 BNB_M = BNB_Total * split_M / 100;

            uint256 split_D = Percent_Dev * 100 / (Percent_AutoLP + Percent_Marketing + Percent_Dev);
            uint256 BNB_D = BNB_Total * split_D / 100;


            addLiquidity(tokens_to_LP_Half, (BNB_Total - BNB_M - BNB_D));
            emit SwapAndLiquify(tokens_to_LP_Half, (BNB_Total - BNB_M - BNB_D), tokens_to_LP_Half);

            sendToWallet(Wallet_Marketing, BNB_M);

            BNB_Total = address(this).balance;
            sendToWallet(Wallet_Dev, BNB_Total);

            }

    function swapTokensForBNB(uint256 tokenAmount) private {

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


    function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: BNBAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            Wallet_Burn, 
            block.timestamp
        );
    } 

    function remove_Random_Tokens(address random_Token_Address, uint256 percent_of_Tokens) public returns(bool _sent){
        require(random_Token_Address != address(this), "Can not remove native token");
        uint256 totalRandom = IERC20(random_Token_Address).balanceOf(address(this));
        uint256 removeRandom = totalRandom*percent_of_Tokens/100;
        _sent = IERC20(random_Token_Address).transfer(Wallet_Dev, removeRandom);

    }


    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee, bool isBuy) private {
        
        
        if(!takeFee){

            _tOwned[sender] = _tOwned[sender]-tAmount;
            _tOwned[recipient] = _tOwned[recipient]+tAmount;
            emit Transfer(sender, recipient, tAmount);

            if(recipient == Wallet_Burn)
            _tTotal = _tTotal-tAmount;

            } else if (isBuy){

            uint256 buyFEE = tAmount*_Tax_On_Buy/100;
            uint256 tTransferAmount = tAmount-buyFEE;

            _tOwned[sender] = _tOwned[sender]-tAmount;
            _tOwned[recipient] = _tOwned[recipient]+tTransferAmount;
            _tOwned[address(this)] = _tOwned[address(this)]+buyFEE;   
            emit Transfer(sender, recipient, tTransferAmount);

            if(recipient == Wallet_Burn)
            _tTotal = _tTotal-tTransferAmount;
            
            } else {

            uint256 sellFEE = tAmount*_Tax_On_Sell/100;
            uint256 tTransferAmount = tAmount-sellFEE;

            _tOwned[sender] = _tOwned[sender]-tAmount;
            _tOwned[recipient] = _tOwned[recipient]+tTransferAmount;
            _tOwned[address(this)] = _tOwned[address(this)]+sellFEE;   
            emit Transfer(sender, recipient, tTransferAmount);

            if(recipient == Wallet_Burn)
            _tTotal = _tTotal-tTransferAmount;


            }

    }


}