// SPDX-License-Identifier: MIT
/**

██╗░░░██╗███████╗██████╗░██╗███████╗██╗░░░██╗
██║░░░██║██╔════╝██╔══██╗██║██╔════╝╚██╗░██╔╝
╚██╗░██╔╝█████╗░░██████╔╝██║█████╗░░░╚████╔╝░
░╚████╔╝░██╔══╝░░██╔══██╗██║██╔══╝░░░░╚██╔╝░░
░░╚██╔╝░░███████╗██║░░██║██║██║░░░░░░░░██║░░░
░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░░░░╚═╝░░░
                                                                                               


VERIFY Tokenomics :

Total Supply 50 Trillion 

10% Total tax
3% R&D wallet automatically converted to BNB
3% going into LP automatically
2% Charity automatically converted to BNB
2% automatic burn

*/

pragma solidity ^0.8.7;

import "./Imports.sol";


contract VERIFY is IERC20Metadata, Ownable {
    using SafeMath for uint256;
    
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 private _totalSupply = 50000000000000 * (10**18);

    string private _name = "VERIFY";
    string private _symbol = "VFY";
    uint8 constant _decimals = 18;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;
    bool public swapEnabled = true;
    bool public isInPresale = false;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public RDWallet = 0x5e2F1A839B46f8D59cb7445d9715B01bC09CD63f;
    address public charityWallet = 0x952c1079B61A9DE24FBb4c9022aD719e2B270935;

    uint256 public swapTokensAtAmount = 20000000 * (10**18);
    uint256 public maxBuyTranscationAmount = 250000000000 * (10**18); // 0.5% of total supply
    uint256 public maxSellTransactionAmount = 250000000000 * (10**18); // 0.5% of total supply
    uint256 public maxWalletToken = 1000000000000 * (10**18); // 2% of total supply

    uint256 public liquidityFee = 3;
    uint256 public charityFee = 2;
    uint256 public RDFee = 3;
    uint256 public burnFee = 2;
    uint256 public totalFees = charityFee.add(liquidityFee).add(RDFee).add(burnFee);
    
    uint256 internal FEES_DIVISOR = 10**2;
    
    mapping(address => bool) public _isBlacklisted;
    
     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() {
        
        _balances[owner()] = _balances[owner()].add(_totalSupply);
        
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(charityWallet, true);
        excludeFromFees(RDWallet, true);
        excludeFromFees(address(this), true);

        _approve(owner(),address(uniswapV2Router), ~uint256(0));
        emit Transfer(address(0), address(this), _totalSupply);
    }

    receive() external payable {

  	}
  	
  	function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
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
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool){
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
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        uniswapV2Router = IUniswapV2Router02(newAddress);
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setRDWallet(address payable wallet) external onlyOwner{
        RDWallet = wallet;
    }
    
    function setCharityWallet(address payable wallet) external onlyOwner{
        charityWallet = wallet;
    }
    
     function calcTotalFees() private {
        totalFees = charityFee.add(liquidityFee).add(RDFee).add(burnFee); 
    }

    function setRDFee(uint256 value) external onlyOwner{
        RDFee = value;
        calcTotalFees();
    }

    function setLiquidityFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        calcTotalFees();
    }

    function setCharityFee(uint256 value) external onlyOwner{
        charityFee = value;
        calcTotalFees();
    }
    
    function setBurnFee(uint256 value) external onlyOwner{
        burnFee = value;
        calcTotalFees();
    }
    
    function setMaxBuyTransaction(uint256 maxTxn) external onlyOwner {
  	    maxBuyTranscationAmount = maxTxn * (10**18);
  	}
  	
  	function setMaxSellTransaction(uint256 maxTxn) external onlyOwner {
  	    maxSellTransactionAmount = maxTxn * (10**18);
  	}
  	
  	function setMaxWalletToken(uint256 maxToken) external onlyOwner {
  	    maxWalletToken = maxToken * (10**18);
  	}

    function updateSwapTokensAt(uint256 _swaptokens) external onlyOwner {
        swapTokensAtAmount = _swaptokens * (10**18);
    }
    
    function updateSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled  = _enabled;
    }
    
    function switchPresale(bool _enabled) external onlyOwner {
        require(isInPresale != _enabled, "Presale is already set to this perimeter.");
        isInPresale = _enabled;
    }

    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');
        require(amount > 0, "Transfer amount must be greater than zero");
         // Buying
        if (from == uniswapV2Pair && !_isExcludedFromFees[to]) {
            require(amount <= maxBuyTranscationAmount, "Transfer amount exceeds the maxBuyTxAmount.");
        } 
        
        if ( maxWalletToken > 0 && !_isExcludedFromFees[to] && !_isExcludedFromFees[from] && to != address(uniswapV2Pair) ) {
                uint256 contractBalanceRecepient = balanceOf(to);
                require(contractBalanceRecepient + amount <= maxWalletToken, "Exceeds maximum wallet token amount.");
            }
            
         // Selling
         if ( !_isExcludedFromFees[from] && to == uniswapV2Pair ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap && !swapping && swapEnabled && to == uniswapV2Pair ) {
            swapping = true;
            
            swapAndLiquify(contractTokenBalance);
            
            swapping = false;
        }


        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        if ( isInPresale ){ takeFee = false; }

        if(takeFee) {
        	_takeFees(amount, from);
        	
        	uint256 fees = amount.mul(totalFees).div(FEES_DIVISOR);
            amount = amount.sub(fees);
        }
        
        _transferTokens(from, to, amount);
    }
    
    function _transferTokens (address sender, address recipient, uint256 amount) private {
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);   
    }
    
    function _takeFee(uint256 amount, uint256 fee, address sender, address recipient) private {
        uint256 tAmount = amount.mul(fee).div(FEES_DIVISOR);
        _balances[recipient] = _balances[recipient].add(tAmount);
        
        emit Transfer(sender, recipient, tAmount); 
    }
    
    function _takeFees(uint256 amount, address sender) private {
        _takeFee( amount, liquidityFee, sender, address(this)); // Liquidity fee
        _takeFee( amount, RDFee, sender, RDWallet); // RD fee
        _takeFee( amount, charityFee, sender, charityWallet); // Charity fee
        _takeFee( amount, burnFee, sender, deadWallet); // Burn fee
    }

    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }


    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }
    
    function TransferBNB(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Cannot withdraw the BNB balance to the zero address");
        recipient.transfer(amount);
    }
    
}