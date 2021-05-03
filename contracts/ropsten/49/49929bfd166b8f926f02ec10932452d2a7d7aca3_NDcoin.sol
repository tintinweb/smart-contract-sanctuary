/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-29
*/

pragma solidity ^0.5.12;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) public _allowances;

    uint private _totalSupply;
   
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
   
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}


contract NDcoin is ERC20, ERC20Detailed {

    using SafeMath for uint;
   
    uint256 internal holdingFee = 2;
    uint256 internal charityFee = 2;
    uint256 internal burnForever = 1;
    
    address internal charityWallet;
    address public governance;
    address [] internal holders;

    mapping(address => bool) internal hasHolding;

    constructor (address _charityWallet, address _governance) public ERC20Detailed("NDcoin", "NDCTEST", 18) {
        governance = _governance;
        charityWallet = _charityWallet;
        holders.push(_governance);

        super._mint(_governance, 69000000  * (10 ** 18));
    }
   
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _updateHoldings(recipient);
        _calculateTransfer(recipient,amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function transfer(address recipient, uint amount) public returns (bool) {
        _updateHoldings(recipient);
        _calculateTransfer(recipient,amount);
       
        return true;
    }
    

    function _calculateTransfer(address recipient, uint256 amount) internal {
        uint256 _burnAmount = SafeMath.div(SafeMath.mul(amount,burnForever),100);
        uint256 _holdingAmount = SafeMath.div(SafeMath.mul(amount,holdingFee),100);
        uint256 _charityAmount = SafeMath.div(SafeMath.mul(amount,charityFee),100);
        uint256 _amountToSend = amount.sub(_burnAmount + _holdingAmount + _charityAmount);

        _transfer(_msgSender(), charityWallet, _charityAmount);
        _holdingDisperse(_holdingAmount);
        _burn( msg.sender, _burnAmount);
        _transfer(_msgSender(), recipient, _amountToSend);

    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }


    function _updateHoldings(address recipient) internal returns(bool)  {
        if(!hasHolding[recipient]) holders.push(recipient);
        else return false;
        
        hasHolding[recipient] = true;
        return true;
    }
    
    function _holdingDisperse(uint256 amount) internal returns(bool)  {
        
        uint256 calculateEachTransferAmount = amount.div(holders.length);
        
        for (uint256 i = 0; i < holders.length; i++ ) {
            _transfer(_msgSender(), holders[i], calculateEachTransferAmount);
        }
        
        return true;
    }

}