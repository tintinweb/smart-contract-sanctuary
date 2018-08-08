pragma solidity ^0.4.18;

// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function Owned() public {
        owner = msg.sender;
    }

    function changeOwner(address _newOwner) public onlyOwner{
        owner = _newOwner;
    }
}


// Safe maths, borrowed from OpenZeppelin
// ----------------------------------------------------------------------------
library SafeMath {

  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract tokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
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

contract limitedFactor {
    using SafeMath for uint;
    
    uint256 public totalSupply = 0;
    uint256 public topTotalSupply = 18*10**8*10**6;
    uint256 public teamSupply = percent(15);
    uint256 public teamAlloacting = 0;
    uint256 internal teamReleasetokenEachMonth = 5 * teamSupply / 100;
    uint256 public creationInvestmentSupply = percent(15);
    uint256 public creationInvestmenting = 0;
    uint256 public ICOtotalSupply = percent(30);
    uint256 public ICOSupply = 0;
    uint256 public communitySupply = percent(20);
    uint256 public communityAllocating = 0;
    uint256 public angelWheelFinanceSupply = percent(20);
    uint256 public angelWheelFinancing = 0;
    address public walletAddress;
    uint256 public teamAddressFreezeTime = startTimeRoundOne;
    address public teamAddress;
    uint256 internal teamAddressTransfer = 0;
    uint256 public exchangeRateRoundOne = 16000;
    uint256 public exchangeRateRoundTwo = 10000;
    uint256 internal startTimeRoundOne = 1526313600;
    uint256 internal stopTimeRoundOne =  1528991999;
    
    modifier teamAccountNeedFreeze18Months(address _address) {
        if(_address == teamAddress) {
            require(now >= teamAddressFreezeTime + 1.5 years);
        }
        _;
    }
    
    modifier releaseToken (address _user, uint256 _time, uint256 _value) {
        if (_user == teamAddress){
            require (teamAddressTransfer + _value <= calcReleaseToken(_time)); 
        }
        _;
    }
    
    function calcReleaseToken (uint256 _time) internal view returns (uint256) {
        uint256 _timeDifference = _time - (teamAddressFreezeTime + 1.5 years);
        return _timeDifference / (3600 * 24 * 30) * teamReleasetokenEachMonth;
    } 
    
     /// @dev calcute the tokens
    function percent(uint256 percentage) internal view returns (uint256) {
        return percentage.mul(topTotalSupply).div(100);
    }

}

contract standardToken is ERC20Token, limitedFactor {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    /* Transfers tokens from your address to other */
    function transfer(address _to, uint256 _value) 
        public 
        teamAccountNeedFreeze18Months(msg.sender) 
        releaseToken(msg.sender, now, _value)
        returns (bool success) 
    {
        require (balances[msg.sender] >= _value);           // Throw if sender has insufficient balance
        require (balances[_to] + _value >= balances[_to]);  // Throw if owerflow detected
        balances[msg.sender] -= _value;                     // Deduct senders balance
        balances[_to] += _value;                            // Add recivers blaance
        if (msg.sender == teamAddress) {
            teamAddressTransfer += _value;
        }
        emit Transfer(msg.sender, _to, _value);                  // Raise Transfer event
        return true;
    }

    /* Approve other address to spend tokens on your account */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        allowances[msg.sender][_spender] = _value;          // Set allowance
        emit Approval(msg.sender, _spender, _value);             // Raise Approval event
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);              // Cast spender to tokenRecipient contract
        approve(_spender, _value);                                      // Set approval to contract for _value
        spender.receiveApproval(msg.sender, _value, this, _extraData);  // Raise method on _spender contract
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require (balances[_from] >= _value);                // Throw if sender does not have enough balance
        require (balances[_to] + _value >= balances[_to]);  // Throw if overflow detected
        require (_value <= allowances[_from][msg.sender]);  // Throw if you do not have allowance
        balances[_from] -= _value;                          // Deduct senders balance
        balances[_to] += _value;                            // Add recipient blaance
        allowances[_from][msg.sender] -= _value;            // Deduct allowance for this address
        emit Transfer(_from, _to, _value);                       // Raise Transfer event
        return true;
    }

    /* Get the amount of allowed tokens to spend */
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

}

contract MMONToken is standardToken,Owned {
    using SafeMath for uint;

    string constant public name="MONEY MONSTER";
    string constant public symbol="MMON";
    uint256 constant public decimals=6;
    
    bool public ICOStart;
    
    /// @dev Fallback to calling deposit when ether is sent directly to contract.
    function() public payable {
        require (ICOStart);
        depositToken(msg.value);
    }
    
    /// @dev initial function
    function MMONToken() public {
        owner=msg.sender;
        ICOStart = true;
    }
    
    /// @dev Buys tokens with Ether.
    function depositToken(uint256 _value) internal {
        uint256 tokenAlloc = buyPriceAt(getTime()) * _value;
        require(tokenAlloc != 0);
        ICOSupply = ICOSupply.add(tokenAlloc);
        require (ICOSupply <= ICOtotalSupply);
        mintTokens(msg.sender, tokenAlloc);
        forwardFunds();
    }
    
    /// @dev internal function
    function forwardFunds() internal {
        if (walletAddress != address(0)){
            walletAddress.transfer(msg.value);
        }
    }
    
    /// @dev Issue new tokens
    function mintTokens(address _to, uint256 _amount) internal {
        require (balances[_to] + _amount >= balances[_to]);     // Check for overflows
        balances[_to] = balances[_to].add(_amount);             // Set minted coins to target
        totalSupply = totalSupply.add(_amount);
        require(totalSupply <= topTotalSupply);
        emit Transfer(0x0, _to, _amount);                            // Create Transfer event from 0x
    }
    
    /// @dev Calculate exchange
    function buyPriceAt(uint256 _time) internal constant returns(uint256) {
        if (_time >= startTimeRoundOne && _time <= stopTimeRoundOne) {
            return exchangeRateRoundOne;
        }  else {
            return 0;
        }
    }
    
    /// @dev Get time
    function getTime() internal constant returns(uint256) {
        return now;
    }
    
    /// @dev set initial message
    function setInitialVaribles(address _walletAddress, address _teamAddress) public onlyOwner {
        walletAddress = _walletAddress;
        teamAddress = _teamAddress;
    }
    
    /// @dev withDraw Ether to a Safe Wallet
    function withDraw(address _etherAddress) public payable onlyOwner {
        require (_etherAddress != address(0));
        address contractAddress = this;
        _etherAddress.transfer(contractAddress.balance);
    }
    
    /// @dev allocate Token
    function allocateTokens(address[] _owners, uint256[] _values) public onlyOwner {
        require (_owners.length == _values.length);
        for(uint256 i = 0; i < _owners.length ; i++){
            address owner = _owners[i];
            uint256 value = _values[i];
            mintTokens(owner, value);
        }
    }
    
    /// @dev allocate token for Team Address
    function allocateTeamToken() public onlyOwner {
        require(balances[teamAddress] == 0);
        mintTokens(teamAddress, teamSupply);
        teamAddressFreezeTime = now;
    }
    
    function allocateCommunityToken (address[] _commnityAddress, uint256[] _amount) public onlyOwner {
        communityAllocating = mintMultiToken(_commnityAddress, _amount, communityAllocating);
        require (communityAllocating <= communitySupply);
    }
    /// @dev allocate token for Private Address
    function allocateCreationInvestmentingToken(address[] _creationInvestmentingingAddress, uint256[] _amount) public onlyOwner {
        creationInvestmenting = mintMultiToken(_creationInvestmentingingAddress, _amount, creationInvestmenting);
        require (creationInvestmenting <= creationInvestmentSupply);
    }
    
    /// @dev allocate token for contributors Address
    function allocateAngelWheelFinanceToken(address[] _angelWheelFinancingAddress, uint256[] _amount) public onlyOwner {
        //require(balances[contributorsAddress] == 0);
        angelWheelFinancing = mintMultiToken(_angelWheelFinancingAddress, _amount, angelWheelFinancing);
        require (angelWheelFinancing <= angelWheelFinanceSupply);
    }
    
    function mintMultiToken (address[] _multiAddr, uint256[] _multiAmount, uint256 _target) internal returns (uint256){
        require (_multiAddr.length == _multiAmount.length);
        for(uint256 i = 0; i < _multiAddr.length ; i++){
            address owner = _multiAddr[i];
            uint256 value = _multiAmount[i];
            _target = _target.add(value);
            mintTokens(owner, value);
        }
        return _target;
    }
}