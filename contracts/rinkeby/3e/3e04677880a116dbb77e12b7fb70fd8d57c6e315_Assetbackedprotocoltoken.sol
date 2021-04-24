/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Assetbackedprotocoltoken is IERC20 , Ownable{
    
    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    address[] isaddedToBannedList;
    mapping (address => bool) private _addToBannedList;
    
    uint256 private _totalSupply;
    address private _owner;
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    
    constructor ()  {
        _name = 'Asset backed protocol token';
        _symbol = 'ABP';
        _decimals = 18;
        _owner = 0x6419c74008Bc806739eC5608dB318e3D594e9EAa;
        
        
        _totalSupply =  2000000000  * (10**_decimals);
        
        //transfer total supply to owner
        _balances[_owner] =_totalSupply;
        
        //fire an event on transfer of tokens
        emit Transfer(address(this),_owner, _balances[_owner]);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
     function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public  override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

   
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

 
    function approve(address spender, uint256 amount) public  virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_allowances[sender][msg.sender]>=amount,"In Sufficient allowance");
        _transfer(sender, recipient, amount);
        _approve(sender,msg.sender, _allowances[sender][msg.sender]-=amount);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(sender != recipient,"cannot send money to your Self");
        require(_balances[sender]>=amount,"In Sufficiebt Funds");
        require(_addToBannedList[recipient] != true, "Transfer can not be executed");
        
        _balances[sender] -= amount;
        _balances[recipient] +=amount;
        emit Transfer(sender, recipient, amount);
    }
     
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(owner != spender,"cannot send allowances to yourself");
        require(_balances[owner]>=amount,"In Sufficiebt Funds");
    
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function checkInBannedList(address beneficiary) public onlyOwner view returns(bool)
    {
        return _addToBannedList[beneficiary];
    }
    function addtoBannedList (address beneficiary) public onlyOwner
    {
        require(beneficiary != address(0), "zero address can not be added");
        _addToBannedList[beneficiary] = true;
        isaddedToBannedList.push(beneficiary);
    }
    
    function _mint(uint amount) external {
        require(msg.sender == _owner,"only owner can call this");
        _totalSupply += amount * (10**_decimals);
    }
    
    function _burn(uint amount) external {
        require(msg.sender == _owner,"only owner can call this");
        _totalSupply -= amount * (10**_decimals);
    }
}