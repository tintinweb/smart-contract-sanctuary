/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

pragma solidity ^0.8.0;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMWWMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMWWWWMWWMWWMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXxodxKWMWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK0O0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMXdoO0kodXWWMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNxdOKOk0WMMMMWMMMMMMMMMMMMMMMMMMMMMMWXxxKK0XXxlOWMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNxck00XXkkXWMMMMMMMMMMMMMMMMMMMMMMMMWXkkXK0O0NNxcxNMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMWMMO:dKOO0NN0kOXWMMMMMMMMMMMMMMMMMMMMMWKOKXK0OkkKWNx:xNMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMWMXll0KOkkKNWNOxkXWWWMMMMMMMMMMMMMMMWN0OKNX0OOkxkKWNd;kWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMWx:kXK0kxkKNWWXdckNWMMMMMMMMMMMMMWWXO0NNXKOkkxxx0NWK::KMWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMXlcKX0kkxxkKWWWNx;lXWWWWWWNNNNNNXNXO0NWNK0kxddxxOXWWd.dWWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMM0:dXK0kxdxkKX0kxl,.;cccc::;;;,,,,;;;lxOK0OxdddddxKWWk.;KMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMWx:kXK0kddxxo;'.........................;ldxdooodxKWWk.'OMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMWd:ONK0koc,...............................':loooxOXWWk..xWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMWx;kN0kl,....'..............................':okKNWWNo..oNMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMWO;lXO:..'ck00d;............:dkko;............:0WWWW0:..oWMWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMXl,c,..;kXNNNN0:.........;kNWWWWXx;...........:dOKKo. .xWMWMWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMWWWKc....lKNXXXKXNk,.......;OWWWWWWWW0c.............,,.. .oNWWMMWMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWXkl'....oXNXKOkkOKKc.....,lkNWNNXNWWWWXo'.............    .o0XWMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWMWXd,...';:xXKdlcclcckXd....'xXNNKkollokKNWNO:.............    ..,dNMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMNKkd:..,oOKXNWNd.,c:oo:xNd...;kNWN0l,;;lo:;o0NWXd;..............    .oXMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWO;...'cONWWWWNW0c'. ..cKNl.'lKWWWK:.,:.,lc.'kWWWNKx:..................lOXWMMMMMMMM
// MMMMMMMMMMMMMMMMMNo.,dOKNWWWWWWNNN0l,. ,OWNxo0NWWX0o. .'   .,xNWWWWWWXOo:'.........,;....'xWMMMMMMMM
// MMMMMMMMMMMMMMMMMXl.:XWWWWWWWNWWNNNKxldKWWWWWWWWN0Oxc'.',,:dKNWWNWWWWWWNXKOkddddxk0X0;...'xWMMMMMMMM
// MMMMMMMMMMMMMMMMMXl.;0WWWWWWWWNWNXK00KWWWWWWWWMWWNNNXXKKXNNWWWWWWWWWNWWWNWWWWWWWWWWWKc...,OWMMMMMMMM
// MMMMMMMMMMMMMMMMMNo.c0WWWWWWNNNNKKXNNNNNNWWWMMMWWWWWWNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNO:..lXMMMMMMMMM
// MMMMMMMMMMMMMMMMMNd:kWWWWWWWNXXKKOxdolcclodk0NWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWK:.,kWMMMMMMMMM
// MMMMMMMMMMMMMMMMMWO:dNWWWWWNNXXKkc;;;;;;;:::cOWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNx..,dNMMMMMMMMM
// MMMMMMMMMMMMMMMMMMK:cKWWWWNNNXXNk;,;:ccc::;':0WWWWWWWWWWWWWNXXWWWWWWWWWWWWWWWWWWWWWW0;..'xWMMMMMMMMM
// MMMMMMMMMMMMMMMMMMK:,xNWWWNWNKKNKl..''''.  'xNWWWWWWWWWWWWKockNWWWWWWWWWWWWWWWWWWWWXl...,0MMMMMMMMMM
// MMMMMMMMMMMMMMMMMMXo':KWWWWWNXKXN0o,......;kNNWWWWWWWWWWXx:l0NWWWWWWNNNNNNNNWWWWWWWOc...:XMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWO,'oNWWWWNX00XX0d:. .,lkKNNWWWWWWWWXx;;xNWWWWWWWWNNNNNWWWWWWWWWWXo.  lNMMWWMMMMMM
// MMMMMMMMMMMMMMMMMMMNd;lKWNWWNXKkxkkkl'  'lkKXWWWWNXKkl'.;ONWWWWNNNNNNNNNWWWWWWWWWWXd.   :XMWWWMMMMMM
// MMMMMMMMMMMMMMMMMWWMKdkNWWWWNXXKkoc;'.   .,:odolc,'.   :0WWWWNNNNNNNNNNWWWWWWWWWW0l..   .lKWWWMMMMMM
// MMMMMMMMMMMMMMMMMMMWW0dOWWWWWNXXKOdl,.               .lKWWWNNNNNNNNNNNNNNWWWWWWXx;....    ':xKWMMMMM
// MMMMMMMMMMMMMMMMMMMWMNxcOWWWWNNNX0kdc,..............,xNWWNNNNNNNNNNNNNNNWWWWWXx:.......      .l0WMMM
// MMMMMMMMMMMMMMMMMMWMMWXdcxNWWWNNNK0kl;;;;,,;;;;;;cldKNWWNNNNNNNNNWWNNNWWWWWXkc'........        .lKWM
// MMMMMMMMMMMMMMMMMMMMMMMNxco0WWWWNNX0dlllcccllllld0NWWNNNXNNNNNNNNNNNWWWWWWNOc'.........          .lO
// MMMMMMMMMMMMMMMMMMMMWWMMW0ockXWWWNNKxddddddddxdxKWWNXXXXNNNNNNNNNWWWWWWWN0d:'...............       .
// MMMMMMMMMMMMMMMMMMMMMMMWMWNOldKNWWWXOxxxxxxkxddOK000KXXXNNNNWWWWWWWWWXOo:,..''................      
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMXdoKWWWWX0OkkkkkxdkOO00KXXNNWNWWWWWWWWXko:,'''''....................    
// MMMMMMMMMMMMMMMMMMMMMMMMWWMMM0cdXWWWWN0kkxxkkOO0KKXXNNNWWWWWWWWX0xl;,,,''.........................  
// MMMMMMMMMMMMMMMMMMMMMMMMWWMWMXl,cxKWWWNKOOO000KKXNNNNNWWWMWWWXxc;,,,''........'..................   
// MMMMMMMMMMMMMMMMMMMMMMMMMMWWMNd;,;dNWWWWNXKKKKXXNWWWWWMWWMWWWO:,;;,'.......''''...................  
// MMMMMMMMMMMMMMMMMMMMMMMMMWWWWNx:;:lkNMWWWWNXXXXNNWMMWWMMWWWW0l;::'...'',,,,,'''''''.................
// MMMMMMMMMMMMMMMMMMMMMMMMWWMMWWO:,;;ckNWWWWWWWNNNWMMMWWMMWWWNklc;',:c::;;,,''''''....................
// MMMMMMMMMMMMMMMMMMMMMMMMMWMMMMXl,;;:xNWWWMMMMWWWMMMMWWMMWWWWXd;;clc:;,''''''''......................
// MMMMMMMMMMMMMMMMMMMMMMMMMMWWWMWk:,,;l0WWWWWWMMWWMMMMWMMMWWWW0l;:ccclodoc;'....''....................

contract Husky is ERC20 {
    address public admin;

    constructor() ERC20("Husky", "HUSKY") {
        admin = msg.sender;
    }

      function updateAdmin(address newAdmin) external {
    require(msg.sender == admin, 'only admin');
    admin = newAdmin;
  }

  function mint(address to, uint amount) external {
    require(msg.sender == admin, 'only admin');
    _mint(to, amount);
  }

  function burn(address owner, uint amount) external {
    require(msg.sender == admin, 'only admin');
    _burn(owner, amount);
  }
}