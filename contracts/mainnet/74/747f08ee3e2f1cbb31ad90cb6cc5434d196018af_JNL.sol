/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

contract Context {
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract ERC20 is Context, Ownable, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) internal _balances;

    mapping (address => mapping (address => uint)) internal _allowances;

    uint internal _totalSupply;
    uint internal _circulatingSupply;
    
    bool public ventureLock = true;
    bool public teamLock = true;
    bool public marketingLock = true;
    bool public customerLock = true;
    uint256 public createdAt;
    
    
    address public venture = 0xE217C02ad8D1D898c14C186677bA19cc9f137CE2;
    address public LProvisions = 0x063a8111E550BA3eb981cb633163829df0ca7cb7;
    address public team = 0xD4A5d1D5855505740D9bc533ae45E1b5A18ac7CD;
    address public customer = 0x7a1A7ca0feD25FcFD428598FD00BA7D647FA4461;
    address public marketing = 0x0fc229640381BC5B2bB9239003e5238e403C92e5;
    
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }
    function circulatingSupply() public view returns (uint) {
        return _circulatingSupply;
    }
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public override  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address towner, address spender) public view override returns (uint) {
        return _allowances[towner][spender];
    }
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function _transfer(address sender, address recipient, uint amount) internal{
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
       
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
       
    }
 
    function _approve(address towner, address spender, uint amount) internal {
        require(towner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[towner][spender] = amount;
        emit Approval(towner, spender, amount);
    }
    
    function openVentureLock() public onlyOwner returns (bool)
    {
        if( block.timestamp >= createdAt + 180 days)
        {
            ventureLock = false;
            return true;
        }
        else return false;
    }
    
    function withdrawFromVenture(uint256 amount, address recipient) external onlyOwner
    {
        if(openVentureLock() == true)
        {
            _balances[venture] = _balances[venture].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(venture, recipient, amount);
        }
    }
    
    function openTeamLock() public onlyOwner returns (bool)
    {
        uint256 teamUnlockTime = createdAt + 730 days;
        if( block.timestamp >= teamUnlockTime)
        {
            teamLock = false;
            return true;
        }
        else return false;
    }
    
    function withdrawFromTeam(address recipient) external onlyOwner
    {
        uint256 sixMonths ;
        if(openTeamLock() == true)
        {
            if(sixMonths == 0 || block.timestamp >= sixMonths + 180 days)
            {
            _balances[team] = _balances[venture].sub(9000000 * (10**18));
            _balances[team] = _balances[recipient].add(9000000 * (10**18));
            emit Transfer(team, recipient, 9000000 * (10**18));
            sixMonths = block.timestamp;
            }
        }
    }
    
      function openMarketingLock() public onlyOwner returns (bool)
    {
        if( block.timestamp >= createdAt + 180 days)
        {
            marketingLock = false;
            return true;
        }
        else return false;
    }
    
    function withdrawFromMarketing(uint256 amount, address recipient) external onlyOwner
    {
        if(openMarketingLock() == true)
        {
            _balances[marketing] = _balances[marketing].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(marketing, recipient, amount);
        }
    }
    
      function openCustomerLock() public onlyOwner returns (bool)
    {
        if( block.timestamp >= createdAt + 456 days)
        {
            customerLock = false;
            return true;
        }
        else return false;
    }
    
    function withdrawFromCustomer(uint256 amount, address recipient) external onlyOwner
    {
        if(openCustomerLock() == true)
        {
            _balances[customer] = _balances[customer].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(customer, recipient, amount);
        }
    }

 function _burn(address account, uint amount) public onlyOwner{
        require(account != address(0), "ERC20: burn from the zero address");
    
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
}

contract ERC20Detailed is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory tname, string memory tsymbol, uint8 tdecimals) {
        _name = tname;
        _symbol = tsymbol;
        _decimals = tdecimals;
        
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



library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract JNL is ERC20, ERC20Detailed {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;
  
  
  address public _owner;
  
  constructor () ERC20Detailed("Jennel", "JNL", 18) {
     _owner = msg.sender;
    _totalSupply = 6000000000 *(10**uint256(18));
    
    createdAt = block.timestamp;
    
    _balances[venture] = 300000000 * (10**uint256(18));
    _balances[LProvisions] = 150000000 * (10**uint256(18));
    _balances[team] = 180000000 * (10**uint256(18));
    _balances[customer] = 90000000 * (10**uint256(18));
    _balances[marketing] = 90000000 * (10**uint256(18));
     
	_circulatingSupply =_totalSupply - (_balances[venture] + _balances[LProvisions] + _balances[team] + _balances[customer] + _balances[marketing]);
	_balances[_owner] = _circulatingSupply;
	
  }
}