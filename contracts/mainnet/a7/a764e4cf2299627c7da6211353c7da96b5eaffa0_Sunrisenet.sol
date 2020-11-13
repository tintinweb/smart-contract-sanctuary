/*   

Sunrisenet Finance

https://sunrisenet.finance

SPDX-License-Identifier: MIT

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

// library to prevent overflow for uint256

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
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    mapping (address => bool) internal _whitelist;
    bool internal _globalWhitelist = true;

    uint256 internal _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal burnRate = 10; // Burn Rate is 10%

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

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
 
        if (_globalWhitelist == false) {
          if (_whitelist[sender] == false && _whitelist[recipient] == false) { // recipient being staking pools; sender used for presale airdrop
            amount = _burn(sender, amount, burnRate);
          }
        }

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual { }

    /* Takes an amount, burns % of it, returns remaining amount */
    function _burn(address account, uint256 amount, uint256 bRate) internal virtual returns(uint256) { 
        require(account != address(0), "ERC20: burn from the zero address");
        require(bRate <= 100, "Can't burn more than 100%!");

        uint256 burnCalc = (amount.mul(bRate).div(100));
        uint256 remainingAfterBurn = amount.sub(burnCalc);

        _balances[account] = _balances[account].sub(burnCalc, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(burnCalc);
        emit Transfer(account, address(0), burnCalc);
        return (remainingAfterBurn);
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

}

// File: @openzeppelin/contracts/token/ERC20/ERC20Capped.sol

abstract contract ERC20Capped is ERC20 {
    uint256 private _cap;

    constructor (uint256 cap) public {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20) {
        require(account != address(0), " ERC20: mint to the zeroaddress");
        require((_totalSupply.add(amount)) < _cap, " ERC20: Minting exceeds cap!");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

contract Ownable {
    
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, " Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), " Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: eth-token-recover/contracts/TokenRecover.sol

contract TokenRecover is Ownable {

    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

// File: contracts/BaseToken.sol

contract Sunrisenet is ERC20Capped, TokenRecover {

    // indicates if minting is finished
    bool private _mintingFinished = false;
    bool _transferEnabled = false;
    event MintFinished();
    event TransferEnabled();

    mapping (address => bool) internal _transWhitelist;
        

    modifier canMint() {
        require(!_mintingFinished, "BaseToken: minting is finished");
        _;
    }

    constructor() public ERC20('Sunrisenet Finance', 'SRN') ERC20Capped(10e23) {
      uint256 initialSupply = 10e22;

      _mint(owner(), initialSupply);
      whitelist(msg.sender);
      transferWhitelist(msg.sender);

    }
    function burn(uint256 amount, uint256 bRate) public returns(uint256) {
        return _burn(msg.sender, amount, bRate);
    }

    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }

    function mint(address to, uint256 value) public canMint onlyOwner {
        _mint(to, value);
    }

    function finishMinting() public canMint onlyOwner {
        _mintingFinished = true;
        emit MintFinished();
    }

    modifier canTransfer(address from) {
        require(
            _transferEnabled || _transWhitelist[from],
            "BaseToken:transfer is not enabled or from isn't whitelisted."
        );
        _;
    }

    function transfer(address to, uint256 value) public virtual override(ERC20) canTransfer(msg.sender) returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public virtual override(ERC20) canTransfer(from) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function enableTransfer() public onlyOwner {
        _transferEnabled = true;
        emit TransferEnabled();
    }

    function isTransferEnabled() public view returns(bool) {
        return _transferEnabled;
    }

    function isTransferWhitelisted(address user) public view returns(bool) {
        return _transWhitelist[user];
    }

    // Ensuring an equitable public launch 
    function transferWhitelist(address user) public onlyOwner returns(bool) {
        _transWhitelist[user] = true;
        return true;
    }

    function setGlobalWhitelist(bool state) public onlyOwner {
       _globalWhitelist = state;
    }

    function globalWhitelistState() public view returns(bool) {
        return _globalWhitelist;
    }

    // Removes user burn immunity
    function unwhitelist(address user) public onlyOwner returns(bool) {
       _whitelist[user] = false;
       return true;
    }

    function isWhitelisted(address user) public view returns(bool) {
       return _whitelist[user];
    }
    
    // Allows user to be immune to burn during transfer
    function whitelist(address user) public onlyOwner returns(bool) {
       _whitelist[user] = true;
       return true;
    }

    // In case of catastrophic failure
    function setBurnRate(uint256 rate) public onlyOwner {
       burnRate = rate;
    }

}