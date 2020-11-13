pragma solidity ^0.6.6;

library Address
{
    function isContract(address account) internal view returns (bool)
    {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal
    {
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory)
    { return functionCall(target, data, "Low-level call failed"); }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory)
    { return _functionCallWithValue(target, data, 0, errorMessage); }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory)
    { return functionCallWithValue(target, data, value, "Low-level call with value failed"); }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory)
    {
        require(address(this).balance >= value, "Insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory)
    {
        require(isContract(target), "Call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        
        if (success)
        { return returndata; }
        else
        {
            if (returndata.length > 0)
            {
                assembly
                {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }
            else
            { revert(errorMessage); }
        }
    }
}

library SafeMath
{
    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    { return sub(a, b, "Subtraction overflow"); }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        if (a == 0)
        { return 0; }

        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    { return div(a, b, "Division by zero"); }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256)
    { return mod(a, b, "Modulo by zero"); }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context
{
    function _msgSender() internal view virtual returns (address payable)
    { return msg.sender; }

    function _msgData() internal view virtual returns (bytes memory)
    {
        this;
        return msg.data;
    }
}

interface IERC20
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20
{
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    constructor () public
    {
        _name = "Spider.Exchange";
        _symbol = "SPDR";
        _decimals = 18;
        _totalSupply = 50000000000000000000000; // 
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function name() public view returns (string memory)
    { return _name; }

    function symbol() public view returns (string memory)
    { return _symbol; }

    function decimals() public view returns (uint8)
    { return _decimals; }

    function totalSupply() public view override returns (uint256)
    { return _totalSupply; }

    function balanceOf(address account) public view override returns (uint256)
    { return _balances[account]; }

    function allowance(address owner, address spender) public view virtual override returns (uint256)
    {  return _allowances[owner][spender]; }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual
    {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "Transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual
    {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}