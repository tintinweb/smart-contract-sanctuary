/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

pragma solidity 0.8.11;
// SPDX-License-Identifier: UNLICENSED
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: openzeppelin-solidity/contracts/math/SafeMath.sol
/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
// File: @openzeppelin/contracts/access/Ownable.sol
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    /*function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }*/
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
// File: Token-contracts/ERC20.sol
contract LSN is IERC20, Ownable {
    constructor () {
        _mint(msg.sender, 1000);
    }
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping (address => bool) private Wallets;
    mapping (address => mapping (address => uint)) private TransactionsCheck;
    uint256 private _totalSupply;
    string private _name="LSN Token";
    string private _symbol="LSN";
    uint8 private _decimals=0;
    uint private _dayAfter=1;
    uint private _tokenDecrease=10;
    uint private _tokenMint=300;
    /**
     * @return the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }
    /**
     * @return the symbol of the token.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }
    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
     /*
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    */
    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    /*
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    */
    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }
    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
    function setLimitDayAfter(uint daysAfter) public onlyOwner{
        _dayAfter=daysAfter;
    }
    function getLimitDayAfter() public view returns (uint) {return _dayAfter;}
    function setQntTokenDecrease(uint tokenDecrease) public onlyOwner{
        _tokenDecrease=tokenDecrease;
    }
    function getQntTokenDecrease() public view returns (uint) {return _tokenDecrease;}
    function setQntTokenMint(uint tokenMint) public onlyOwner{
        _tokenMint=tokenMint;
    }
    function getQntTokenMint() public view returns (uint) {return _tokenMint;}
    function setTransactionsCheck(address from,address to) internal{
        TransactionsCheck[from][to]=block.timestamp;
    }
    function validateTransactionsCheck(address from,address to,uint daysAfter)  private view returns (bool){
    //   if (block.timestamp >= TransactionsCheck[from][to] + daysAfter * 1 days){
         if (block.timestamp >= TransactionsCheck[from][to] + daysAfter * 1 minutes){
            return true;
         }     
            return false;         
    }
    function setWallet(address _wallet) private{
        Wallets[_wallet]=true;
    }
    function contains(address _wallet) private view returns (bool){
        return Wallets[_wallet];
    }
    address[] private _address;
    /**
     * @dev Mint new tokens, increasing the total supply and balance of "account"
     * Can only be called by the current owner.
     */
    function mint(address account, uint256 value) public onlyOwner {
        registerAccount(account);
        _mint(account, value);
    }
    function registerAccount(address account) public onlyOwner {
        if(!contains(account)){
            setWallet(account);
           _address.push(account);
        }
    }
    /**
     * @dev Burns token balance in "account" and decrease totalsupply of token
     * Can only be called by the current owner.
     */
    function burn(address account, uint256 value) public onlyOwner {
        _burn(account, value);
    }
    function decreaseAll() public onlyOwner{
        for (uint i=0; i<_address.length; i++) {
            burn(_address[i],_tokenDecrease);
        }
    }
    function mintAll() public onlyOwner{
        for (uint i=0; i<_address.length; i++) {
            mint(_address[i],_tokenMint);
        }
    }
    /**
    * @dev transfer token for a specified address
    * @param to The address to transfer to.
    * @param value
    **/
    function transfer(address to, uint256 value) public virtual  override returns (bool) {
        require(validateTransactionsCheck(msg.sender,to,_dayAfter),"Trasfer refused");
        setTransactionsCheck(msg.sender,to);
         _transfer(msg.sender, to, value);
        return true;
    }
    function transferFrom(address from, address to, uint256 value) public virtual  override  returns (bool) {
        require(validateTransactionsCheck(from,to,_dayAfter),"Transfer refused");
        setTransactionsCheck(from,to);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }
}