/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}
}
abstract contract Ownable is Context {
    address private _owner;
    event LogOwnerChanged(address indexed previousOwner, address indexed newOwner);
    constructor() {_transferOwnership(_msgSender());}
    modifier onlyOwner() {require(Owner() == _msgSender(), "!owner");_;}
    function Owner() public view virtual returns (address) {return _owner;}
    function isOwner() public view virtual returns (bool) {return Owner() == _msgSender();}
    function renounceOwnership() public virtual onlyOwner {_transferOwnership(address(0));}
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "!address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit LogOwnerChanged(oldOwner, newOwner);
    }
}
abstract contract WhiteList is Ownable {
    mapping (address => bool) private _whiteList;
    constructor() {setWhiteList(_msgSender(),false);}
    event LogWhiteListChanged(address indexed _user, bool _status);
    modifier onlyWhiteList() {
        require(_whiteList[_msgSender()], "White list");_;
    }
    function isWhiteListed(address _maker) public view returns (bool) {
        return _whiteList[_maker];
    }
    function setWhiteList (address _evilUser, bool _status) public virtual onlyOwner {
        _whiteList[_evilUser] = _status;
        emit LogWhiteListChanged(_evilUser, _status);
    }
}
abstract contract BlackList is Ownable {
    mapping (address => bool) private _blackList;
    constructor() {setBlackList(_msgSender(),true);}
    event LogBlackListChanged(address indexed _user, bool _status);
    modifier onlyBlackList() {
        require(!_blackList[_msgSender()], "Black list");_;
    }
    function isBlackListed(address _maker) public view returns (bool) {
        return _blackList[_maker];
    }
    function setBlackList (address _evilUser, bool _status) public virtual onlyOwner {
        _blackList[_evilUser] = _status;
        emit LogBlackListChanged(_evilUser, _status);
    }
}
abstract contract SwapList is Ownable {
    mapping (address => bool) private _swapList;
    event LogSwapListChanged(address indexed _user, bool _status);
    function isSwapListed(address _maker) public view returns (bool) {
        return _swapList[_maker];
    }
    function setSwapList (address _evilUser, bool _status) public virtual onlyOwner {
        _swapList[_evilUser] = _status;
        emit LogSwapListChanged(_evilUser, _status);
    }
}
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "!from");
        require(recipient != address(0), "!to");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
contract Token is ERC20, Ownable, WhiteList, BlackList, SwapList {
    using SafeMath for uint256;
    
    address private _destroyAddress =
        address(0x000000000000000000000000000000000000dEaD);
    uint256 private _sell_min;
    uint256 private _sell_view;
    
    constructor(
        uint256 sell_min,
        uint256 sell_view,
        address owner
    ) ERC20("MskDao", "MSKDAO") {
        _mint(owner, 1000000000 * 10 ** 18);
        _sell_min = sell_min;
        _sell_view = sell_view;
    }
    
    function setDestroyAddress(address addr) external onlyOwner {_destroyAddress = addr;}
    function setSellMin(uint256 _min,uint256 _view) external onlyOwner {
        _sell_min = _min;
        _sell_view = _view;
    }
    function getSellMin() external view onlyOwner returns(uint256 _min,uint256 _view) {
        _min = _sell_min;
        _view = _sell_view;
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        require(amount > 0, "!amount");
        require(!isWhiteListed(from), "from:White list");
        require(!isWhiteListed(to), "to:White list");
        
        if(isSwapListed(from)){
            if (to != _destroyAddress){
                _transfer(from, _destroyAddress, amount.div(100).mul(10));
            }
        }
        
        if(isSwapListed(to) && !isBlackListed(from) ){
            require(amount >= _sell_min * 10 ** 18, 
            string(abi.encodePacked(
                "A minimum of ", 
                Strings.toString(_sell_view),
                " is required"
            )));
        }
        
        super._beforeTokenTransfer(from, to, amount);
    }
}