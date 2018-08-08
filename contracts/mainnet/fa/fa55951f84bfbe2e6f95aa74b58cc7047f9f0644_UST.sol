pragma solidity ^0.4.21;

contract Owned {
    
    /// &#39;owner&#39; is the only address that can call a function with 
    /// this modifier
    address public owner;
    address internal newOwner;
    
    ///@notice The constructor assigns the message sender to be &#39;owner&#39;
    function Owned() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    event updateOwner(address _oldOwner, address _newOwner);
    
    ///change the owner
    function changeOwner(address _newOwner) public onlyOwner returns(bool) {
        require(owner != _newOwner);
        newOwner = _newOwner;
        return true;
    }
    
    /// accept the ownership
    function acceptNewOwner() public returns(bool) {
        require(msg.sender == newOwner);
        emit updateOwner(owner, newOwner);
        owner = newOwner;
        return true;
    }
    
}

// Safe maths, borrowed from OpenZeppelin
library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        return c;
    }
    
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Token {
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
    
    /// user tokens
    mapping (address => uint256) public balances;
    
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant public returns (uint256 balance);

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
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Controlled is Owned, ERC20Token {
    using SafeMath for uint;
    uint256 public releaseStartTime;
    uint256 oneMonth = 3600 * 24 * 30;
    
    // Flag that determines if the token is transferable or not
    bool  public emergencyStop = false;
    
    struct userToken {
        uint256 UST;
        uint256 addrLockType;
    }
    mapping (address => userToken) public userReleaseToken;
    
    modifier canTransfer {
        require(emergencyStop == false);
        _;
    }
    
    modifier releaseTokenValid(address _user, uint256 _time, uint256 _value) {
		uint256 _lockTypeIndex = userReleaseToken[_user].addrLockType;
		if(_lockTypeIndex != 0) {
			require (balances[_user].sub(_value) >= userReleaseToken[_user].UST.sub(calcReleaseToken(_user, _time, _lockTypeIndex)));
        }
        
		_;
    }
    
    
    function canTransferUST(bool _bool) public onlyOwner{
        emergencyStop = _bool;
    }
    
    /// @notice get `_user` transferable token amount 
    /// @param _user The user&#39;s address
    /// @param _time The present time
    /// @param _lockTypeIndex The user&#39;s investment lock type
    /// @return Return the amount of user&#39;s transferable token
    function calcReleaseToken(address _user, uint256 _time, uint256 _lockTypeIndex) internal view returns (uint256) {
        uint256 _timeDifference = _time.sub(releaseStartTime);
        uint256 _whichPeriod = getPeriod(_lockTypeIndex, _timeDifference);
        
        if(_lockTypeIndex == 1) {
            
            return (percent(userReleaseToken[_user].UST, 25) + percent(userReleaseToken[_user].UST, _whichPeriod.mul(25)));
        }
        
        if(_lockTypeIndex == 2) {
            return (percent(userReleaseToken[_user].UST, 25) + percent(userReleaseToken[_user].UST, _whichPeriod.mul(25)));
        }
        
        if(_lockTypeIndex == 3) {
            return (percent(userReleaseToken[_user].UST, 10) + percent(userReleaseToken[_user].UST, _whichPeriod.mul(15)));
        }
		
		revert();
    
    }
    
    /// @notice get time period for the given &#39;_lockTypeIndex&#39;
    /// @param _lockTypeIndex The user&#39;s investment locktype index
    /// @param _timeDifference The passed time since releaseStartTime to now
    /// @return Return the time period
    function getPeriod(uint256 _lockTypeIndex, uint256 _timeDifference) internal view returns (uint256) {
        if(_lockTypeIndex == 1) {           //The lock for the usechain coreTeamSupply
            uint256 _period1 = (_timeDifference.div(oneMonth)).div(12);
            if(_period1 >= 3){
                _period1 = 3;
            }
            return _period1;
        }
        if(_lockTypeIndex == 2) {           //The lock for medium investment
            uint256 _period2 = _timeDifference.div(oneMonth);
            if(_period2 >= 3){
                _period2 = 3;
            }
            return _period2;
        }
        if(_lockTypeIndex == 3) {           //The lock for massive investment
            uint256 _period3 = _timeDifference.div(oneMonth);
            if(_period3 >= 6){
                _period3 = 6;
            }
            return _period3;
        }
		
		revert();
    }
    
    function percent(uint _token, uint _percentage) internal pure returns (uint) {
        return _percentage.mul(_token).div(100);
    }
    
}

contract standardToken is ERC20Token, Controlled {
    
    mapping (address => mapping (address => uint256)) public allowances;
    
    /// @param _owner The address that&#39;s balance is being requested
    /// @return The balance of `_owner` at the current block
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    /// @notice Send `_value` tokens to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    
	function transfer(
        address _to,
        uint256 _value) 
        public 
        canTransfer
        releaseTokenValid(msg.sender, now, _value)
        returns (bool) 
    {
        require (balances[msg.sender] >= _value);           // Throw if sender has insufficient balance
        require (balances[_to] + _value >= balances[_to]);  // Throw if owerflow detected
        balances[msg.sender] -= _value;                     // Deduct senders balance
        balances[_to] += _value;                            // Add recivers balance
        emit Transfer(msg.sender, _to, _value);             // Raise Transfer event
        return true;
    }
    
    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;          // Set allowance
        emit Approval(msg.sender, _spender, _value);             // Raise Approval event
        return true;
    }

    /// @notice `msg.sender` approves `_spender` to send `_value` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        approve(_spender, _value);                          // Set approval to contract for _value
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { 
            revert(); 
        }
        return true;
    }

    /// @notice Send `_value` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _value The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _value) public canTransfer releaseTokenValid(msg.sender, now, _value) returns (bool success) {
        require (balances[_from] >= _value);                // Throw if sender does not have enough balance
        require (balances[_to] + _value >= balances[_to]);  // Throw if overflow detected
        require (_value <= allowances[_from][msg.sender]);  // Throw if you do not have allowance
        balances[_from] -= _value;                          // Deduct senders balance
        balances[_to] += _value;                            // Add recipient balance
        allowances[_from][msg.sender] -= _value;            // Deduct allowance for this address
        emit Transfer(_from, _to, _value);                       // Raise Transfer event
        return true;
    }

    /// @dev This function makes it easy to read the `allowances[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed to spend
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowances[_owner][_spender];
    }

}

contract UST is Owned, standardToken {
        
    string constant public name   = "UseChainToken";
    string constant public symbol = "UST";
    uint constant public decimals = 18;

    uint256 public totalSupply = 0;
    uint256 constant public topTotalSupply = 2 * 10**10 * 10**decimals;
    uint public forSaleSupply        = percent(topTotalSupply, 45);
    uint public marketingPartnerSupply = percent(topTotalSupply, 5);
    uint public coreTeamSupply   = percent(topTotalSupply, 15);
    uint public technicalCommunitySupply       = percent(topTotalSupply, 15);
    uint public communitySupply          = percent(topTotalSupply, 20);
    uint public softCap                = percent(topTotalSupply, 30);
    
    function () public {
        revert();
    }
    
    /// @dev Owner can change the releaseStartTime when needs
    /// @param _time The releaseStartTime, UTC timezone
    function setRealseTime(uint256 _time) public onlyOwner {
        releaseStartTime = _time;
    }
    
    /// @dev This owner allocate token for private sale
    /// @param _owners The address of the account that owns the token
    /// @param _values The amount of tokens
    /// @param _addrLockType The locktype for different investment type
    function allocateToken(address[] _owners, uint256[] _values, uint256[] _addrLockType) public onlyOwner {
        require ((_owners.length == _values.length) && ( _values.length == _addrLockType.length));
        for(uint i = 0; i < _owners.length ; i++){
            uint256 value = _values[i] * 10 ** decimals;
            
            totalSupply = totalSupply.add(value);
            balances[_owners[i]] = balances[_owners[i]].add(value);             // Set minted coins to target
            emit Transfer(0x0, _owners[i], value);    
            
            userReleaseToken[_owners[i]].UST = userReleaseToken[_owners[i]].UST.add(value);
            userReleaseToken[_owners[i]].addrLockType = _addrLockType[i];
        }
    }
    
    /// @dev This owner allocate token for candy airdrop
    /// @param _owners The address of the account that owns the token
    /// @param _values The amount of tokens
	function allocateCandyToken(address[] _owners, uint256[] _values) public onlyOwner {
       for(uint i = 0; i < _owners.length ; i++){
           uint256 value = _values[i] * 10 ** decimals;
           totalSupply = totalSupply.add(value);
		   balances[_owners[i]] = balances[_owners[i]].add(value); 
		   emit Transfer(0x0, _owners[i], value);  		  
        }
    }
    
}