/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function burn(uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

contract BlockchainCryptoBusinessToken is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _icoSupply;
    uint256 private _circulationSupply;
    uint256 private _totalBurnableToken;
    uint256 private _ownersSupply;
    uint256 private _burnedToken;
    uint256 private _remainningBurnableToken;
    uint256 private _convertvolume;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _owner;
    address private _burnaddress;
    
    
    constructor (
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint256 icoSupply_,
        uint256 totalBurnableToken_,
        uint256 circulationSupply_,
        uint256 ownersSupply_,
        address burnaddress_
        )  {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = _convertVolume(totalSupply_);
        _icoSupply = _convertVolume(icoSupply_);
        _totalBurnableToken = _convertVolume(totalBurnableToken_);
        _remainningBurnableToken = totalBurnableToken();
        _circulationSupply = _convertVolume(circulationSupply_);
        _ownersSupply = _convertVolume(ownersSupply_);
        _burnaddress = burnaddress_;
        _balances[msg.sender] = totalSupply().sub(totalBurnableToken());
        _balances[_burnaddress] = totalBurnableToken();
        _owner = msg.sender;
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
    
    function burnedToken() public view returns (uint256) {
        return _burnedToken;
    }
    
    function icoSupply() public view returns (uint256) {
        return _icoSupply;
    }
    
    function circulationSupply() public view returns (uint256) {
        return _circulationSupply;
    }
    
    function owners() public view returns (address) {
        return _owner;
    }
    
    function ownersSupply() public view returns (uint256) {
        return _ownersSupply;
    }
    
    function totalBurnableToken() public view returns (uint256) {
        return _totalBurnableToken;
    }
    
    function remainningBurnableToken() public view returns (uint256) {
        return _remainningBurnableToken;
    }
    
   
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function _convertVolume(uint256 amount) internal returns(uint256) {
        _convertvolume = (amount * (10 ** uint256(decimals())));
        return _convertvolume;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function burn(uint256 amount) public virtual override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(account == _burnaddress, "ERC20: burn access not allowed for your address");
        require(amount <= _remainningBurnableToken, "ERC20: burn amount exceeds the burn limits");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        _remainningBurnableToken = _remainningBurnableToken.sub(amount);
        _burnedToken = _burnedToken.add(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}