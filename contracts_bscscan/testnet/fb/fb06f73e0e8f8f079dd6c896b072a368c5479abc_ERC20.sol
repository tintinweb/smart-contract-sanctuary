/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

pragma solidity ^0.5.0;

pragma solidity ^0.5.0;

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

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract SaleXToken is Ownable {
    
    using SafeMath for uint; 
    
    uint public TokenPrice; //USDT *Note: Can be edited.
    uint public TotalSoled;
    
    /* for token Owner Start */
    uint public TotalUsdt     = 0; //Total USDT balance for token Owner
    uint public WithdrawnUsdt = 0; //Withdrawn USDT balance for token Owner
    uint public balanceUsdt   = 0; //balance USDT for token Owner
    /* for token Owner Ende */ 
    
    bool public endSale       = false;
    address public USDTContractAddress; 
    address public TokenContractAddress; 
    
    mapping(address => bool) public authorizeds;
    mapping(address => bool) public ownerToken;  // Wallet having token
    mapping(address => uint) public amountSoled; // Total Soled For Wallet
    
    event Sold(address indexed purchaser,uint amount);
    uint decimals = 6;
    
    constructor () public {
        TokenPrice    = 20;
        TotalSoled    = 0;
    }
    
    function setAuthorizeds (address _account,bool _mode) public onlyOwner returns (bool) {
        authorizeds[_account] = _mode;
        return true; 
    } 
     
    function updateTokenPrice (uint _newprice) onlyOwner public returns (bool)  {
        TokenPrice = _newprice;
        return true;
    } 
    
    function getUSDTBalanceOf(address _address) public  view returns (uint) {
       return IERC20(USDTContractAddress).balanceOf(_address);
    }
    
    function getTokenBalanceOf(address _address) public  view returns (uint) {
        return IERC20(TokenContractAddress).balanceOf(_address);
    }
    
   
    function calculateTotal (uint _amount) public view returns (uint) {
        uint totalUsdt     = (_amount * TokenPrice) / 100;
        return totalUsdt;
    }
    
    function updateUSDTContractAddress (address _address) onlyOwner public returns (bool) {
        USDTContractAddress = _address;
        return true;
    }
    
    function updateTokenContractAddress (address _address) onlyOwner public returns (bool) {
        TokenContractAddress = _address;
        return true;
    }
    
     function setEndSale (bool _endsale) onlyOwner public returns (bool) {
        endSale = _endsale;
        return true;
    }
    
    function buyToken (uint _amount)  public returns(bool) {
        address sender     = msg.sender;
        require(!endSale, "Token Sale ended!");
        uint USDTBalance   = getUSDTBalanceOf(sender);
        require(USDTBalance > 0, "Not enough USDT in your wallet!");
        require(_amount >= 500 * (10 ** uint(decimals)) , "Min amount 500 XAE!");       
        uint totalUsdt     = _amount * TokenPrice / 100;
        require(totalUsdt <= USDTBalance, "insufficient balance!");
        
        uint TokenBalance   = getTokenBalanceOf(address(this));
        require(_amount <= TokenBalance, "insufficient balance in smart contract!");
        
        uint allowance = IERC20(USDTContractAddress).allowance(msg.sender, address(this));
        require(allowance >= totalUsdt, "Check the token allowance");
        
        IERC20(USDTContractAddress).transferFrom(msg.sender, address(this), totalUsdt);
        IERC20(TokenContractAddress).transfer(msg.sender,_amount);
        
        emit Sold(msg.sender,_amount);
        
        TotalSoled = TotalSoled + _amount;
        TotalUsdt = TotalUsdt + totalUsdt;
        balanceUsdt = balanceUsdt + totalUsdt;
        ownerToken[msg.sender]  = true;
        amountSoled[msg.sender] = amountSoled[msg.sender] + _amount;
        
        return true;
    }
    
     function checkBuying (uint _amount) public view returns (bool) {
        address sender     = msg.sender;
        require(!endSale, "Token Sale ended!");
        uint USDTBalance   = getUSDTBalanceOf(sender);
        require(USDTBalance > 0, "Not enough USDT in your wallet!");
        require(_amount >= 500 * (10 ** uint(decimals)) , "Min amount 500 XAE!");
        uint totalUsdt     = _amount * TokenPrice / 100;
        require(totalUsdt <= USDTBalance, "insufficient balance!");
        uint allowance = IERC20(USDTContractAddress).allowance(msg.sender, address(this));
        require(allowance >= totalUsdt, "Check the token allowance");
        return true;
    }
    
    function withdrawUSDT (address _address) public returns (bool)  {
        address sender     = msg.sender;
        require(authorizeds[sender], "You not authorized!");
        uint USDTBalance   = getUSDTBalanceOf(address(this));
        require(USDTBalance > 0, "No USDT!");
        IERC20(USDTContractAddress).transfer(_address,USDTBalance);
        WithdrawnUsdt = WithdrawnUsdt + USDTBalance;
        balanceUsdt = balanceUsdt - USDTBalance;
        return true;
    }
    
    function withdrawToken (address _address) public returns (bool)  {
        address sender     = msg.sender;
        require(authorizeds[sender], "You not authorized!");
        uint TokenBalance   = getTokenBalanceOf(address(this));
        require(TokenBalance > 0, "No Token!");
        IERC20(TokenContractAddress).transfer(_address,TokenBalance);
        return true;
    }
}