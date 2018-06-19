/**
 * https://github.com/drlecks/Ethereum-Contracts/tree/master/Hodl
 */



pragma solidity ^0.4.23;

contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;
    //How many decimals to show.
    uint256 public decimals;
    
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name  
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract OwnableContract {
 
    address superOwner;
		
	constructor() public { 
        superOwner = msg.sender;  
    }
	
	modifier onlyOwner() {
        require(msg.sender == superOwner);
        _;
    } 
    
    function viewSuperOwner() public view returns (address owner) {
        return superOwner;
    }
    
	function changeOwner(address newOwner) onlyOwner public {
        superOwner = newOwner;
    }
}


contract BlockableContract is OwnableContract{
 
    bool public blockedContract;
	
	constructor() public { 
        blockedContract = false;  
    }
	
	modifier contractActive() {
        require(!blockedContract);
        _;
    } 
	
	function doBlockContract() onlyOwner public {
        blockedContract = true;
    }
    
    function unBlockContract() onlyOwner public {
        blockedContract = false;
    }
}

contract Hodl is BlockableContract{
    
    struct Safe{
        uint256 id;
        address user;
        address tokenAddress;
        uint256 amount;
        uint256 time;
    }
    
    /**
    * @dev safes variables
    */
    mapping( address => uint256[]) public _userSafes;
    mapping( uint256 => Safe) private _safes;
    uint256 private _currentIndex;
    
    mapping( address => uint256) public _totalSaved;
     
    /**
    * @dev owner variables
    */
    uint256 public comission; //0..100
    mapping( address => uint256) private _systemReserves;
    address[] public _listedReserves;
     
    /**
    * constructor
    */
    constructor() public { 
        _currentIndex = 1;
        comission = 10;
    }
    
    /**
    * fallback function to receive donation eth
    */
    function () public payable {
        require(msg.value>0);
        _systemReserves[0x0] = add(_systemReserves[0x0], msg.value);
    }
    
    /**
    * how many safes has the user
    */
    function GetUserSafesLength(address a) public view returns (uint256 length) {
        return _userSafes[a].length;
    }
    
    /**
    * how many tokens are reservedfor owner as comission
    */
    function GetReserveAmount(address tokenAddress) public view returns (uint256 amount){
        return _systemReserves[tokenAddress];
    }
    
    /**
    * returns safe&#39;s values&#39;
    */
    function Getsafe(uint256 _id) public view
        returns (uint256 id, address user, address tokenAddress, uint256 amount, uint256 time)
    {
        Safe storage s = _safes[_id];
        return(s.id, s.user, s.tokenAddress, s.amount, s.time);
    }
    
    
    /**
    * add new hodl safe (ETH)
    */
    function HodlEth(uint256 time) public contractActive payable {
        require(msg.value > 0);
        require(time>now);
        
        _userSafes[msg.sender].push(_currentIndex);
        _safes[_currentIndex] = Safe(_currentIndex, msg.sender, 0x0, msg.value, time); 
        
        _totalSaved[0x0] = add(_totalSaved[0x0], msg.value);
        
        _currentIndex++;
    }
    
    /**
    * add new hodl safe (ERC20 token)
    */
    function ClaimHodlToken(address tokenAddress, uint256 amount, uint256 time) public contractActive {
        require(tokenAddress != 0x0);
        require(amount>0);
        require(time>now);
          
        EIP20Interface token = EIP20Interface(tokenAddress);
        require( token.transferFrom(msg.sender, address(this), amount) );
        
        _userSafes[msg.sender].push(_currentIndex);
        _safes[_currentIndex] = Safe(_currentIndex, msg.sender, tokenAddress, amount, time);
        
        _totalSaved[tokenAddress] = add(_totalSaved[tokenAddress], amount);
        
        _currentIndex++;
    }
    
    /**
    * user, claim back a hodl safe
    */
    function UserRetireHodl(uint256 id) public {
        Safe storage s = _safes[id];
        
        require(s.id != 0);
        require(s.user == msg.sender);
        
        RetireHodl(id);
    }
    
    /**
    * private retire hodl safe action
    */
    function RetireHodl(uint256 id) private {
        Safe storage s = _safes[id]; 
        require(s.id != 0); 
        
        if(s.time < now) //hodl complete
        {
            if(s.tokenAddress == 0x0) 
                PayEth(s.user, s.amount);
            else  
                PayToken(s.user, s.tokenAddress, s.amount);
        }
        else //hodl in progress
        {
            uint256 realComission = mul(s.amount, comission) / 100;
            uint256 realAmount = sub(s.amount, realComission);
            
            if(s.tokenAddress == 0x0) 
                PayEth(s.user, realAmount);
            else  
                PayToken(s.user, s.tokenAddress, realAmount);
                
            StoreComission(s.tokenAddress, realComission);
        }
        
        DeleteSafe(s);
    }
    
    /**
    * private pay eth to address
    */
    function PayEth(address user, uint256 amount) private {
        require(address(this).balance >= amount);
        user.transfer(amount);
    }
    
    /**
    * private pay token to address
    */
    function PayToken(address user, address tokenAddress, uint256 amount) private{
        EIP20Interface token = EIP20Interface(tokenAddress);
        require(token.balanceOf(address(this)) >= amount);
        token.transfer(user, amount);
    }
    
    /**
    * store comission from unfinished hodl
    */
    function StoreComission(address tokenAddress, uint256 amount) private {
        _systemReserves[tokenAddress] = add(_systemReserves[tokenAddress], amount);
        
        bool isNew = true;
        for(uint256 i = 0; i < _listedReserves.length; i++) {
            if(_listedReserves[i] == tokenAddress) {
                isNew = false;
                break;
            }
        } 
        
        if(isNew) _listedReserves.push(tokenAddress); 
    }
    
    /**
    * delete safe values in storage
    */
    function DeleteSafe(Safe s) private  {
        _totalSaved[s.tokenAddress] = sub(_totalSaved[s.tokenAddress], s.amount);
        delete _safes[s.id];
        
        uint256[] storage vector = _userSafes[msg.sender];
        uint256 size = vector.length; 
        for(uint256 i = 0; i < size; i++) {
            if(vector[i] == s.id) {
                vector[i] = vector[size-1];
                vector.length--;
                break;
            }
        } 
    }
    
    
    //OWNER
    
    /**
    * owner retire hodl safe
    */
    function OwnerRetireHodl(uint256 id) public onlyOwner {
        Safe storage s = _safes[id]; 
        require(s.id != 0); 
        RetireHodl(id);
    }

    /**
    * owner, change comission value
    */
    function ChangeComission(uint256 newComission) onlyOwner public {
        comission = newComission;
    }
    
    /**
    * owner withdraw eth reserved from comissions 
    */
    function WithdrawReserve(address tokenAddress) onlyOwner public
    {
        require(_systemReserves[tokenAddress] > 0);
        
        uint256 amount = _systemReserves[tokenAddress];
        _systemReserves[tokenAddress] = 0;
        
        EIP20Interface token = EIP20Interface(tokenAddress);
        require(token.balanceOf(address(this)) >= amount);
        token.transfer(msg.sender, amount);
    }
    
    /**
    * owner withdraw token reserved from comission
    */
    function WithdrawAllReserves() onlyOwner public {
        //eth
        uint256 x = _systemReserves[0x0];
        if(x > 0 && x <= address(this).balance) {
            _systemReserves[0x0] = 0;
            msg.sender.transfer( _systemReserves[0x0] );
        }
         
        //tokens
        address ta;
        EIP20Interface token;
        for(uint256 i = 0; i < _listedReserves.length; i++) {
            ta = _listedReserves[i];
            if(_systemReserves[ta] > 0)
            { 
                x = _systemReserves[ta];
                _systemReserves[ta] = 0;
                
                token = EIP20Interface(ta);
                token.transfer(msg.sender, x);
            }
        } 
        
        _listedReserves.length = 0; 
    }
    
    /**
    * owner remove free eth
    */
    function WithdrawSpecialEth(uint256 amount) onlyOwner public
    {
        require(amount > 0); 
        uint256 freeBalance = address(this).balance - _totalSaved[0x0];
        require(freeBalance >= amount); 
        msg.sender.transfer(amount);
    }
    
    /**
    * owner remove free token
    */
    function WithdrawSpecialToken(address tokenAddress, uint256 amount) onlyOwner public
    {
        EIP20Interface token = EIP20Interface(tokenAddress);
        uint256 freeBalance = token.balanceOf(address(this)) - _totalSaved[tokenAddress];
        require(freeBalance >= amount);
        token.transfer(msg.sender, amount);
    } 
    
    
    //AUX
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }
    
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
    
    
}