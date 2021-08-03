/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

/**
    * Dev. `Akena Ver.3.0.5: lockTime`
    */

pragma solidity >=0.4.16 < 0.9.0;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
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


contract Pausable is Ownable{
    event Paused(address account);
    
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    modifier whenPaused() {
        require(_paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


contract BEP20Token{
    using SafeMath for uint256;

    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    constructor(uint256 initialSupply,string memory tokenName,string memory tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                    // Give the creator all initial tokens
        name = tokenName;                                       // Set the name for display purposes
        symbol = tokenSymbol;                                   // Set the symbol for display purposes
    }

    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                              // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                                                  // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        balanceOf[_from] = balanceOf[_from].sub(_value);                                        // Subtract from the targeted balance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);                // Subtract from the sender's allowance
        totalSupply = totalSupply.sub(_value);                                                  // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}


contract Akena_Token is BEP20Token, Ownable,Pausable{

    mapping (address => bool) public frozenAccount;

    mapping(address => uint256) public lockedAccount;

    event FreezeAccount(address account, bool frozen);

    event LockAccount(address account,uint256 unlockTime);

    constructor() BEP20Token(1000000000,"AKENA","AKENA") public {
    }

   /**
    * Freeze of Account
    */
    function freezeAccount(address account) onlyOwner public {
        frozenAccount[account] = true;
        emit FreezeAccount(account, true);
    }

   /**
    * unFreeze of Account
    */
    function unFreezeAccount(address account) onlyOwner public{
        frozenAccount[account] = false;
        emit FreezeAccount(account, false);
    }

   /**
    * lock Account, if account is locked, fund can only transfer in but not transfer out.
    * Can not unlockAccount, if need unlock account , pls call unlockAccount interface
    * epoch time, not milliseconds
    */
    function lockAccount(address account, uint256 unlockTime) onlyOwner public{
        require(unlockTime > now);
        lockedAccount[account] = unlockTime;
        emit LockAccount(account,unlockTime);
    }

   /**
    * unlock of Account
    */
    function unlockAccount(address account) onlyOwner public{
        lockedAccount[account] = 0;
        emit LockAccount(account,0);
    }

    function changeName(string memory newName) public onlyOwner {
        name = newName;
    }

    function changeSymbol(string memory newSymbol) public onlyOwner{
        symbol = newSymbol;
    }

    function _transfer(address _from, address _to, uint _value) internal whenNotPaused {
        //Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));

        //if account is frozen, then fund can not be transfer in or out.
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);

        //if account is locked, then fund can only transfer in but can not transfer out.
        require(!isAccountLocked(_from));

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);
    }

    function isAccountLocked(address account) public view returns (bool) {
        return lockedAccount[account] > now;
    }

    function isAccountFrozen(address account) public view returns (bool){
        return frozenAccount[account];
    }
}