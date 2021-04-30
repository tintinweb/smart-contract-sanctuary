/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

///SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/*
         _____                                           
       \/,---<                                           
       ( )a a(      YOU STOLE FIZZY LIFTING DRINKS!!!    
        C   >/                                           
         \ ~/      BUT THE D.A. MISHANDLED THE EVIDENCE, 
       ,- >o<-.    SO HERE'S THE KEYS TO MY FUDGE FACTORY
      /   \/   \                                         
     / /|  | |\ \     _                                  
     \ \|  | | \ `---/_)                                 
      \_\_ | |  `----\_O-                                
      /_/____|                                           
        |  | |                                           
        |  | |                                           
        |  | |               ____                        
        |__|_|_           &&& x_ \_,-------.___     |    
Stef00  (____)_)         &&&& x__*_\\._/__--_-_\-._/_    

Image found here: http://www.asciiartfarts.com/20121102.html

My name is Millie Monka
I love Meme Coins
And also you do
So I decided to open the doors of my Meme Coin Factory to you
Every 35 hours you can create a meme coin sending at least 1 ETH
you can choose name, symbol, and total supply
Meme Coin will be created and 99.98% of the total supply will be stored in a pool on UniswapV2 using eth you provided
remaining 0.02% of the Meme Coin total supply will be sent to Meme Coin creator so they can be swapped in future to have back creation fees
Resulting liquidity pool token will be held by the Meme Coin itself
the first burning 65% of the Meme Coin total supply will extract 60% of the pool
All Meme Coins removed from the pool will be burned
40% of removed eth will be sent to who burned tokens
47% of removed eth will be sent back to pool
remaining removed eth will be sent as Factory's fees
The remaining balance of liquidity pool token will be locked inside the Meme Coin forever

In Factory:

you have create(string memory name, string memory symbol, uint256 totalSupplyPlain) method to create a new Meme Coin. The amount is expressed in the decimal format so you DON'T HAVE TO multiply it for 1e18, Meme Coin will directly do it for you.

you have memeCoins() method to retrieve all Meme Coins in order of creation, including latest one
you have lastMemeCoin() method to retrieve the last Meme Coin only
you have nextCreationBlock() method to know when the next Meme Coin can be created
you have canBeCreated() method returning if nextCreationBlock reached and new Meme Coin can be created

In every Meme Coin:

you have the burn() method which will do all burn stuff descrived above for you

you have burnt() method to check if the 65% of total supply was already burnt or not

You can build a Telegram bot or fork the Uniswap frontend to easily use the Meme Coins

Hope you will enjoy my Meme Coin Factory,
I will do.

Yours,
Millie

*/

interface IUniswapV2Router {
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

    function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external returns (uint amountToken, uint amountETH);
}

interface IUniswapLiquidityPool {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function sync() external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface WETHToken {
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
}

contract MemeCoin {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    IUniswapV2Router private UNISWAP;

    address private _millie;

    bool public burnt;

    constructor(IUniswapV2Router uniswap, string memory _name, string memory _symbol, uint256 _totalSupply, address millie) {
        UNISWAP = uniswap;
        name = _name;
        symbol = _symbol;
        _millie = millie;
        _mint(msg.sender, _totalSupply);
    }

    receive() external payable {
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    function burn() public {
        require(!burnt);
        _burn(msg.sender, (totalSupply * 65) / 100);
        burnt = true;
        WETHToken weth = WETHToken(UNISWAP.WETH());
        IUniswapLiquidityPool liquidityPool = IUniswapLiquidityPool(IUniswapV2Factory(UNISWAP.factory()).getPair(address(weth), address(this)));
        uint256 poolBalance = (liquidityPool.balanceOf(address(this)) * 60) / 100;
        liquidityPool.approve(address(UNISWAP), poolBalance);
        (uint256 tokens, uint256 eths) = UNISWAP.removeLiquidityETH(address(this), poolBalance, 1, 1, address(this), block.timestamp + 1000000);
        _burn(address(this), tokens);
        poolBalance = eths;
        payable(msg.sender).transfer(tokens = (eths * 40) / 100);
        poolBalance -= tokens;
        weth.deposit{value : tokens = (eths * 47) / 100}();
        weth.transfer(address(liquidityPool), tokens);
        liquidityPool.sync();
        poolBalance -= tokens;
        payable(_millie).transfer(poolBalance);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract MemeCoinFactory {

    uint256 private constant BLOCK_INTERVAL = 9333;
    
    IUniswapV2Router private constant UNISWAP = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address private _millie = msg.sender;

    address[] private _memeCoins;

    uint256 private _lastMemeCoinCreation;

    function memeCoins() public view returns (address[] memory){
        return _memeCoins;
    }

    function lastMemeCoin() public view returns (address) {
        return _memeCoins[_memeCoins.length - 1];
    }

    function nextCreationBlock() public view returns (uint256) {
        return _lastMemeCoinCreation == 0 ? block.number : _lastMemeCoinCreation + BLOCK_INTERVAL;
    }

    function canBeCreated() public view returns (bool) {
        return _lastMemeCoinCreation == 0 ? true : block.number >= nextCreationBlock();
    }

    function create(string calldata name, string calldata symbol, uint256 totalSupplyPlain) public payable {
        require(canBeCreated());
        require(msg.value >= 1e18);
        _lastMemeCoinCreation = block.number;
        uint256 totalSupply = totalSupplyPlain * 1e18;
        MemeCoin newMemeCoin = new MemeCoin(UNISWAP, name, symbol, totalSupply, _millie);
        _memeCoins.push(address(newMemeCoin));
        uint256 senderBalance = (totalSupply * 2) / 10000;
        newMemeCoin.transfer(msg.sender, senderBalance);
        totalSupply -= senderBalance;
        newMemeCoin.approve(address(UNISWAP), totalSupply);
        UNISWAP.addLiquidityETH{value : msg.value}(address(newMemeCoin), totalSupply, 1, 1, address(newMemeCoin), block.timestamp + 100000000);
    }
}