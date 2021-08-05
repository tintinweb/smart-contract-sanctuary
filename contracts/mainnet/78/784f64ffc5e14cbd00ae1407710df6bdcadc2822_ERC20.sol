/**
 *Submitted for verification at Etherscan.io on 2021-01-15
*/

pragma solidity >=0.6.0 <0.8.0;
  
// SPDX-License-Identifier: MIT
// @title ERC20 Token
// @created_by  Avalon Blockchain Consulting

/**
 * 
 * @dev Operations with Overflow chechs.
 * 
 **/
library Math { 
    
    /**
     * 
     * @dev Returnthe subtraction of two integers, reverting with message on overflow
     * 
     **/
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b <= a, "Subtraction overflow");
      return a - b;
    }
    
    /**
     * 
     * @dev Return the addition of two integers, reverting with message on overflow
     * 
     **/
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a, "Addition overflow");
      return c;
    }
    
    /**
     * 
     * @dev Return the multiplication of two two integers, reverting with message on overflow
     * 
     **/
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }
}

/**
 * 
 * @dev Contract that guarantees exclusive access to specific functions for the owner
 * 
 * */
abstract contract Ownable {
    address private _owner;
    address private _newOwner;
    
    event OwnerShipTransferred(address indexed oldOwner, address indexed newOwner);
    
    /**
     * 
     * @dev Setting the deployer as the initial owner.
     * 
     */
     
    constructor() {
        _owner = msg.sender;
        _newOwner = msg.sender;
        emit OwnerShipTransferred(address(0), _owner);
    }
    
     /**
     * 
     * @dev Returns the address of the current owner.
     * 
     */
    
    function owner() public view returns(address){
        return _owner;
    }
    
    /**
     * 
     * @dev Reverting with message on overflow if called by any account other than the owner.
     * 
     */
    modifier onlyOwner(){
        require(msg.sender == _owner, 'You are not the owner');
        _;
    }
    
    /**
     * 
     * @dev Set new owner to transfer ownership, reverting with message on overflow if account is not the owner
     * 
     */
    function transferOwnership(address newOwner_) public onlyOwner{
        require(newOwner_ != address(0), 'Invalid address');
        _newOwner = newOwner_;
    }
    
    /**
     * 
     * @dev Accept ownership, reverting with message on overflow if account is not the new owner
     * 
     */
    function acceptOwnership()public{
        require(msg.sender == _newOwner, 'You are not the new owner');
        _transferOwnership(_newOwner);
    }
    
    function _transferOwnership(address newOwner_) internal{
        emit OwnerShipTransferred(_owner,newOwner_);
        _owner = newOwner_;
    }
}

/**
 * 
 * @dev ERC20 Standard Interface as defined in the EIP.
 *
 */
 
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

/**
 * 
 * @dev Implementation of the IERC20w.
 * 
 **/

contract ERC20 is IERC20, Ownable{
    using Math for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    
    constructor (string memory name_, string memory symbol_, uint256 totalSupply_, uint8 decimals_)  {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_.mul(10 ** decimals_);
        _decimals = decimals_;
        _balances[msg.sender] = _balances[msg.sender].add(_totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
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
    
    function transfer(address to, uint256 value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowed[owner][spender];
    }
    
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 value) public override returns (bool) {
        _transfer(sender, recipient, value);
        _approve(sender, msg.sender, _allowed[sender][msg.sender].sub(value));
        return true;
    }
    
    
    function _transfer(address from_, address to_, uint256 amount_) internal{
        require(from_ != address(0), "Sender Invalid address");
        require(to_ != address(0), "Recipient Invalid Address");
        _balances[from_] = _balances[from_].sub(amount_);
        _balances[to_] = _balances[to_].add(amount_);
        emit Transfer(from_, to_, amount_);
    }
    
    function _approve(address owner_, address spender_, uint256 amount_) internal{
        require(owner_ != address(0), "Approve from the zero address");
        require(spender_ != address(0), "Approve to the zero address");
        _allowed[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }
    
    /**
    * 
    * @dev Destroy Tokens from the caller, reverting with message on overflow if caller is not the contract owner
    * 
    */
   
    function burn(uint256 value) public onlyOwner {
        require(msg.sender != address(0), 'Invalid account address');
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(msg.sender, address(0), value);
    }

    
}