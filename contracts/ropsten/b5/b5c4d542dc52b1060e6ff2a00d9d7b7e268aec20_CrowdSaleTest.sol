pragma solidity ^0.4.24;

// File: contracts/zeppelin/token/IERC20.sol

/**
* @title ERC20 Interface
* @dev see https://github.com/ethereum/EIPs/issues/20
*/
contract IERC20 {
/**
* @dev Get the total token supply
*/
    function totalSupply() public view returns(uint256);

/**
* @dev Get the account balance of another account with address `who`
*/
    function balanceOf(address _who) public view returns(uint256);

/**
* @dev Returns the amount which _spender is still allowed to withdraw from _owner
*/
    function allowance(address _owner, address _spender) public view returns(uint256);

/**
* @dev Send _value amount of tokens to address _to
*/
    function transfer(address _to, uint256 _value) public returns(bool);

/**
* @dev Allow _spender to withdraw from your account, multiple times, up to the _value amount. 
* If this function is called again it overwrites the current allowance with _value.
*/
    function approve(address _spender, uint256 _value) public returns(bool);

/**
* @dev Send _value amount of tokens from address _from to address _to
*/
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);

/**
* @dev Triggered when tokens are transferred
*/
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

/**
* @dev Triggered whenever approve(address _spender, uint256 _value) is called
*/
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

// File: contracts/zeppelin/math/SafeMath.sol

/**
* @title SafeMath
* @dev Math operations that security checkd that throw on error 
*/
library SafeMath {

/**
* @dev Multiplies two numbers, throw overflow 
*/
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0){
            return a;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    } 
/**
* @dev Integer devision of two number truncating the quotient, reverts division by zero
*/

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "b must be larger than zero");
        uint256 c = a / b;
        return c;
    }
/**
* @dev Subtracts two numbers, reverts on overflow 
*/
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "b must be lower than a");
        uint256 c = a - b;
        return c;
    }
/**
* @dev Adds two number reverts on overflow
*/
    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        require(c >= a, "c must be larger than a");
        return c;
    }

/**
* @dev Divides two numbers and returns the remainder (unsign integer modulo),
* reverts when dividing by zero */
    function mod(uint256 a, uint256 b) internal pure returns (uint256){
        require(b!=0,"b can not equal to zero");
        return a % b;
    }

}

// File: contracts/zeppelin/token/ERC20.sol

/**
* @title Standard ERC20 token
* @dev Implement of the basic standard Token
* https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
* Originally based on code by FirstBlood: 
* https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
*/
contract ERC20 is IERC20 {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 _totalSupply;

/**
* @dev Total number of tokens in existence
*/
    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

/**
* @dev Gets the balance of specified address.
* @param owner The adress to query balance of.
* @return An uint256 represeting the amount owned by the passed address.
*/
    function balanceOf(address owner) public view returns(uint256){
        return _balances[owner];
    }

/**
* @dev Fucntion to check amount of tokens that an owner allowed to a spender.
* @param owner The address which owns the funds.
* @param spender The address which will spend the funds.
* @return A uint256 specifying the amount of tokens still available for the spender.
*/
    function allowance(address owner, address spender) public view returns(uint256){
        return _allowed[owner][spender];
    }

/**
* @dev Transfer token to specified address
* @param to The address to transfer to.
* @param value The amount to be transferred.
*/
    function transfer(address to, uint256 value) public returns(bool){
        require(to != address(0), "Invalid address");        
        require(value <= _balances[msg.sender], "Balance is not enough");

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value); 
        return true;
    }

/**
* @dev Approve the passed address to spend the specified amount of tokens on behafl of msg.sender.
* Beware that changing an allowance with this method brings the risk that someone may use both the old
* and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
* race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
* https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
* @param spender The address which will spend the funds.
* @param value The amount of tokens to be spent.
*/
    function approve(address spender,uint256 value) public returns (bool){
        require(spender != address(0), "Invalid address");

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

/**
* @dev Transfer tokens from one address to another
* @param from The address which you want to send tokens from.
* @param to The address which you want to transfer to
* @param value The amount of tokens to be transferred
*/
    function transferFrom(address from, address to, uint256 value) public returns(bool){
        require(to != address(0), "Invalid address");
        require(value <= _balances[from],"Not enough balance");
        require(value <= _allowed[from][msg.sender], "Allowed balance is not enough");
        

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

 /**
* @dev Increase the amount of tokens that an owner allowed to a spender.
* approve should be called when allowed_[_spender] == 0. To increment
* allowed value is better to use this function to avoid 2 calls (and wait until
* the first transaction is mined)
* From MonolithDAO Token.sol
* @param spender The address which will spend the funds.
* @param addedValue The amount of tokens to increase the allowance by.
*/
    function increaseAllowance(address spender, uint256 addedValue) public returns(bool){
        require(spender != address(0),"Invalid address");

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

/**
* @dev Decrease the amount of tokens that an owner allowed to a spender.
* approve should be called when allowed_[_spender] == 0. To decrement
* allowed value is better to use this function to avoid 2 calls (and wait until
* the first transaction is mined)
* From MonolithDAO Token.sol
* @param spender The address which will spend the funds.
* @param subtractedValue The amount of tokens to decrease the allowance by.
*/
    function decreaseAllowed(address spender, uint256 subtractedValue) public returns(bool){
        require(spender != address(0),"Invalid address");

        uint256 oldValue = _allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            _allowed[msg.sender][spender] = 0;
        } else {
            _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        }

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

/**
* @dev Internal function that mints an amount of the token and assigns it to
* an account. This encapsulates the modification of balances such that the
* proper events are emitted.
* @param account The account that will receive the created tokens.
* @param amount The amount that will be created.
*/
    function _mint(address account, uint256 amount) internal {
        require(account != address(0),"Invalid address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

/**
* @dev Internal fucntion that burns an amount of the token of given account.
* @param account The account whose tokens will burn.
* @param amount The amount that will be burnt. 
*/
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Invalid address");
        require(amount <= _balances[account], "Amount is incorrect");
        
        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

/**
* @dev Internal function that burns an amount of the token of a given
* account, deducting from the sender&#39;s allowance for said account. Uses the
* internal burn function.
* @param account The account whose tokens will be burnt.
* @param amount The amount that will be burnt.
*/
    function _burnFrom(address account, uint256 amount) internal {
        require(amount <= _allowed[account][msg.sender],"Amount is incorrect");
        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
        _burn(account, amount);
    }
    
}

// File: contracts/zeppelin/token/ERC20Burnable.sol

/**
* @title Burnable Token
* @dev Token that can be irreversibly burned (destroyed). 
*/
contract ERC20Burnable is ERC20 {

/**
* @dev Burn specific amount of tokens.
* @param value The amount of token to be burned.
*/
    function burn(uint256 value) public {
        _burn(msg.sender, value);   
    }

/**
* @dev Burns a specific amount of tokens for the target address and decrements allowance
* @param from The address who you want to burn tokens from
* @param value The amount of token to be burned.
*/
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }

/**
* @dev Overrides ERC20._burn in order for burn and burnFrom to emit
* an addition Burn event 
*/
    function _burn(address who, uint256 value) internal {
        super._burn(who, value);
    }

}

// File: contracts/zeppelin/ownership/Ownable.sol

/**
* @title Ownable
* @dev The ownable contract has owner address, and provide basic athorization control functions,
*       this is simplifies implementation of "user permission" 
*/
contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

/**
* @dev The ownable constructor sets the original `owner` of the contact to the sender account
*/
    constructor() public{
        _owner = msg.sender;
    }

/**
* @return the address of the owner 
*/
    function owner() public view returns(address){
        return _owner;
    }

/**
* @dev Throws if called by any account other than owner */
    modifier onlyOwner(){
        require(isOwner(), "msg.sender is not the onwer of this contract");
        _;
    }

/**
* @return true if `msg.sender` is the owner of the contract */
    function isOwner() public view returns(bool){
        return msg.sender == _owner;
    }

/**
* @dev Allow current owner relinquish control of the contract
* @notice Renouncing to ownership will leave the contract without an onwer
* It will not possible to call the functions with the `onlyOwner` modifier anymore
*/
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

/**
* @dev Allow current owner transfer control of the contract to newOnwer 
*/
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

/**
* @param newOwner The address to transfer ownership to.
*/
    function _transferOwnership(address newOwner) internal{
        require(newOwner != address(0), "Address incorrect");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
}

// File: contracts/zeppelin/token/Pausable.sol

contract Pausable {
    event Paused();
    event Unpaused();

    bool private _paused = false;

/**
@return true if the contract is paused, false otherwis
*/
    function paused() public view returns(bool) {
        return _paused;
    }

/**
@dev Modifier to make a function callable only when the contract is not paused.
*/
    modifier whenNotPaused(){
        require(!_paused,"Contract is paused");
        _;
    }

/**
* @dev Modifier to make a function callable only when the contract is paused.
*/
    modifier whenPaused(){
        require(_paused,"Contract is not paused");
        _;
    }

/**
* @dev to pause, triggers stopped state
*/
    function pause() public  whenNotPaused {
        _paused = true;
        emit Paused();
    }

/** 
* @dev to unpause, returns to normal state 
*/
    function unpause() public  whenPaused {
        _paused = false;
        emit Unpaused();
    }
}

// File: contracts/ICOToken.sol

/**
* @title ICO token
* @dev 
*/
contract ICOToken is ERC20, ERC20Burnable, Pausable, Ownable {

/**
* @dev Token Contract Constants 
*/
    string private  _name;
    string private  _symbol;
    uint8  private _decimals;

/**
* @dev Token Contract public variables
*/
    address public _tokenSaleContract;

/**
* @dev Token Contract modifier
* @param _to - Address to check if valid
*
*  Check if an address is valid
*  A valid address is as follows,
*    1. Not token address
*
*/
    modifier notTokenAddress(address _to) {
        require(_to != address(this),"Invalid address");
        _;
    }

    modifier isAllowedTransferable(){  
        require(!paused() || msg.sender == owner() || msg.sender == _tokenSaleContract, "Token is not transferable");
        _;
    }

/**
* @dev Token Contract contructor
* @param name The name of the token
* @param symbol The symbol of the token
* @param decimals the number of decimals of the token
*/
    constructor(string name, string symbol, uint8 decimals, address adminAddress, uint256 totalSupply) 
    public
    notTokenAddress(adminAddress)
    {
        require(adminAddress != address(0), "`Invaid address");
        require(decimals > 0, "Invalid decimals");
        require(totalSupply > 0, "Invalid supply amount");
        _name = name;
        _symbol = symbol;
        _decimals = decimals;

        _mint(msg.sender, totalSupply);
        _tokenSaleContract = msg.sender;
        transferOwnership(adminAddress);
    }

/**
* @dev Token transfer
* @param to Address to transfer to
* @param value Value to transfer
* Overloaded function ERC20&#39;s transfer
*/
    function transfer(address to,uint256 value)
    public
    isAllowedTransferable
    notTokenAddress(to)
    returns (bool){
        return super.transfer(to, value);
    }

/**
* @dev Approve the passed address to spend the specified amount of tokens on behafl of msg.sender.
* @param spender The address which will spend
* @param value The amount of tokens to be spent
* Overloaded function ERC20&#39;s approve
*/
    function approve(address spender,uint256 value) 
    public
    isAllowedTransferable
    notTokenAddress(spender) 
    returns (bool){
        return super.approve(spender, value);
    }

/**
* @dev Token transferFrom
* @param from Address to transfer from
* @param to Address to transfer to
* @param value Value to transfer
* Overload function ER20&#39;s transferFrom
*/
    function transferFrom(address from, address to, uint256 value)
    public
    isAllowedTransferable
    notTokenAddress(to)
    returns(bool){
        return super.transferFrom(from, to, value);
    }

/**
* @dev Increase Allowance
* @param spender Adress which will spend fund
* @param addedValue The amount of tokens to increase the allowance by.
* Overload function ERC20&#39;s increaseAllowance
*/
    function increaseAllowance(address spender, uint256 addedValue) 
    public 
    isAllowedTransferable
    notTokenAddress(spender)
    returns(bool) {
        return super.increaseAllowance(spender, addedValue);
    }

/**
* @dev Decrease the amount of tokens that an owner allowed to a spender.
* @param spender The address which will spend the funds.
* @param subtractedValue The amount of tokens to decrease the allowance by.
* Overload function ERC20&#39;s decreaseAllowed
*/
    function decreaseAllowed(address spender, uint256 subtractedValue) 
    public
    isAllowedTransferable
    notTokenAddress(spender) 
    returns(bool){
        super.decreaseAllowed(spender,subtractedValue);
    }

/**
* @dev to pause, triggers stopped state
* Overload fucntion ERC20Pausable&#39;s pause, only owner can call
*/
    function pause() 
    public
    onlyOwner  
    whenNotPaused {
        super.pause();
    }

/** 
* @dev to unpause, returns to normal state 
* Overload fucntion ERC20Pausable&#39;s unpause, only owner can call
*/
    function unpause() 
    public
    onlyOwner
    whenPaused {
        super.unpause();
    }

/** 
* @return The name of the token
*/    
    function name() public view returns(string){
        return _name;
    }
    
/**
* @return The symbol of the token
*/
    function symbol() public view returns(string){
        return _symbol;
    }

/**
* @return the number of decimals of the token
*/
    function decimals() public view returns(uint8){
        return _decimals;
    }
}

// File: contracts/ContributorList.sol

contract ContributorList is Ownable {

    using SafeMath for uint256;

    
    mapping(address => bool) _whiteListAddresses;
    mapping(address => uint256) _contributors;

    uint256 private _minContribution; // ETH
    uint256 private _maxContribution; // ETH
    address private _adminAddress;

    modifier onlyAdmin(){
        require(msg.sender == _adminAddress, "Permision denied");
        _;
    }

    constructor(uint256 minContribution, uint256 maxContribution, address adminAddress) public {
        require(minContribution > 0, "Invalid MinContribution");
        require(maxContribution > 0, "Invalid MaxContribution");
        _minContribution = minContribution;
        _maxContribution = maxContribution;
        _adminAddress = adminAddress;
    }

    event UpdateWhiteList(address user, bool isAllowed, uint256 time );

/**
* @dev Update contributor address in whitelist
* @param user Address of contributor
* @param isAllowed is allowed status
*/
    function updateWhiteList(address user, bool isAllowed) 
    public
    onlyAdmin{
        _whiteListAddresses[user] = isAllowed;
        emit UpdateWhiteList(user,isAllowed, block.timestamp);
    }

/**
* @dev Update list of contributors in whitelist
* @param users Array of whitelist address
* @param isAlloweds Array of is allowed status
*/
    function updateWhiteLists(address[] users, bool[] isAlloweds)
    public
    onlyAdmin{
        for (uint i = 0 ; i < users.length ; i++) {
            address _user = users[i];
            bool _allow = isAlloweds[i];
            _whiteListAddresses[_user] = _allow;
            emit UpdateWhiteList(_user, _allow, block.timestamp);
        }
    }

/**
* @dev Get Eligible Cap Amount 
* @param contributor Address of contributor
* @param amount  Intended contribution ETH amount
* @return Eligible Cap Amount 
*/
    function getEligibleAmount(address contributor, uint256 amount) public view returns(uint256){
        
        if(amount < _minContribution){
            return 0;
        }

        uint256 contributorMaxContribution = _maxContribution;
        uint256 remainingCap = contributorMaxContribution.sub(_contributors[contributor]);

        return (remainingCap > amount) ? amount : remainingCap;
    }

/**
*@dev Allowed contributor to increase contribution amount
*@param contributor Address of contributor
*@param amount Intened contribution ETH amount to increase
*/
    function increaseContribution(address contributor, uint256 amount)
    internal
    returns(uint256)
    {
        if(!_whiteListAddresses[contributor]){
            return 0;
        }
        uint256 result = getEligibleAmount(contributor,amount);
        _contributors[contributor] = _contributors[contributor].add(result);
        return result;
    }


}

// File: contracts/CrowdSaleTest.sol

contract CrowdSaleTest is ContributorList {

    ICOToken public _token;

    string _name;
    string _symbol; 
    uint8 _decimals; 
    address _adminAddress; 
    uint256 _totalSupply;

    constructor (
        string name, string symbol, uint8 decimals, address adminAddress, uint256 totalSupply,
        uint256 minContribution, uint256 maxContribution
    )
    ContributorList(minContribution, maxContribution, adminAddress)
    public 
    {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _adminAddress = adminAddress;
        _totalSupply = totalSupply;
        // _token = new ICOToken(name,symbol,decimals, adminAddress, totalSupply);
    }

    function getName() public view returns(string){
        return _name;
    }

}