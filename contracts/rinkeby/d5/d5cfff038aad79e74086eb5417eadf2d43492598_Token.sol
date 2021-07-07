/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;

//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
/**
    * @title SafeMath
    * @dev Math operations with safety checks that throw on error
    */

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
//****************************************************************************//
//---------------------        IERC20    ---------------------//
//****************************************************************************//
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
//****************************************************************************//
//---------------------        ERC20Detailed     ---------------------//
//****************************************************************************//
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

//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//

contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

   
}

//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//

contract ERC20 is IERC20,owned {
    using SafeMath for uint256;
    address private ownerCandidate;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping(address => bool) private _isFreezed;

    uint256 private _totalSupply;
    
    address public dexContract;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    address public owner;
    function Owned() public{
        owner = msg.sender;
    }
     modifier onlyOwnerCandidate() {
        assert(msg.sender == ownerCandidate);
        _;
     }
    
    function transferOwnership(address candidate)  external onlyOwner {
        ownerCandidate = candidate;
    }
    function acceptOwnership() external onlyOwnerCandidate  {
        owner = ownerCandidate;
    }

     function ownerExist() public view returns (address) {
        return msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

   
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(_isFreezed[recipient]!= true, "ERC20: account has been freezed");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    
    function allowance(address ownerHere, address spender) public view returns (uint256) {
        require(_isFreezed[ownerHere]!= true, "ERC20: account has been freezed");
        require(_isFreezed[spender]!= true, "ERC20: account has been freezed");
        return _allowances[ownerHere][spender];
    }

    
    function approve(address spender, uint256 value) public returns (bool) {
       require(_isFreezed[spender]!= true, "ERC20: your account has been freezed");
        _approve(msg.sender, spender, value);
        return true;
    }

   
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_isFreezed[sender]!= true, "ERC20: your account has been freezed");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

   
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(_isFreezed[spender]!= true, "ERC20: your account has been freezed");
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
       require(_isFreezed[spender]!= true, "ERC20: your account has been freezed");
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    
    function freezeAccount(address account) public {
        
        require(!_isFreezed[account], 'Account is already Freezed');
        _isFreezed[account] = true;
        
    }
        
    function isFreezed(address account) public view returns (bool) {
        return _isFreezed[account];
    }

   
     
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(_isFreezed[sender]!= true, "ERC20: your account has been freezed");
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

     
    function burn(address account, uint256 value) public {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    
    function _approve(address ownerHere, address spender, uint256 value) internal {
        require(ownerHere != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[ownerHere][spender] = value;
        emit Approval(ownerHere, spender, value);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }



bool public dexContractChangeLock;
    
    function setDexContract(address _dexContract) external onlyOwner returns(bool){
        require(_dexContract != address(0), 'Invalid address');
        require(!dexContractChangeLock, 'Dex contrat can not be changed');
        dexContractChangeLock=true;
        dexContract = _dexContract;
        return true;
    }
}
contract Token is ERC20Detailed,ERC20 {

   
    constructor () public ERC20Detailed("CZM Token", "CZM", 18) {
        _mint(msg.sender, 1000000000 * (10 ** uint256(decimals())));
    }
}