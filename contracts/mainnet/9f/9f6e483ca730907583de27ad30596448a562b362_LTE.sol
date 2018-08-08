pragma solidity ^0.4.21;

contract Owned {

    address public owner;
    address internal newOwner;
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

    uint256  internal _totalSupply;

    mapping (address => uint256) public balances;

    function totalSupply() constant public returns (uint256 supply);

    function balanceOf(address _owner) constant public returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract Controlled is Owned {
    using SafeMath for uint;
    uint256 oneMonth = 3600 * 24 * 30; //2592000

    uint256 public releaseStartTime = 1527910441;  //20180602 11:35 default  date +%s
    bool  public emergencyStop = false;
    uint256 internal _lockValue;
    
    event reportCalc(address _user,uint transferValue,uint256 releaseValue);
    struct userToken {
        uint256 OCE;
        uint256 addrLockType;
    }
    mapping (address => userToken) userReleaseToken;

    modifier canTransfer {
        require(emergencyStop == false);
        _;
    }

    function setTransferOCE(bool _bool) public onlyOwner{
        emergencyStop = !_bool;
    }


    function setRealseTime(uint256 _time) public onlyOwner {
        releaseStartTime = _time;
    }

    modifier releaseTokenValid(address _user, uint256 _value) {
        uint256 _lockTypeIndex = userReleaseToken[_user].addrLockType;
        if(_lockTypeIndex != 0) {
            uint256 lockValue = userReleaseToken[_user].OCE.sub(calcReleaseToken(_user));
            emit reportCalc(_user,_value,lockValue);
            require (_value >= lockValue);
        }
        _;
    }

    function getLockBalance(address _user) constant public returns (uint256)
    {
        _lockValue = 0;
        uint256 _lockTypeIndex = userReleaseToken[_user].addrLockType;
        if(_lockTypeIndex != 0) {
            _lockValue = userReleaseToken[_user].OCE.sub(calcReleaseToken(_user));
            emit reportCalc(_user,_lockTypeIndex,_lockValue);
        }
        return _lockValue;
    }

    function calcReleaseToken(address _user) internal view returns (uint256) {
        uint256 _lockTypeIndex = userReleaseToken[_user].addrLockType;
        uint256 _timeDifference = now.sub(releaseStartTime);
        uint256 _whichPeriod = getPeriod(_lockTypeIndex, _timeDifference);

        // lock type 1, 75% lock 3 months
        // lock type 2, 90% lock 6 months
        // lock type 3, 75% lock 3 years remove it

        if(_lockTypeIndex == 1) {
            return (percent(userReleaseToken[_user].OCE, 25).add( percent(userReleaseToken[_user].OCE, _whichPeriod.mul(25))));
        }
        if(_lockTypeIndex == 2) {
            return (percent(userReleaseToken[_user].OCE, 10).add(percent(userReleaseToken[_user].OCE, _whichPeriod.mul(25))));
        }
        if(_lockTypeIndex == 3) {
            return (percent(userReleaseToken[_user].OCE, 25).add(percent(userReleaseToken[_user].OCE, _whichPeriod.mul(15))));
        }
        revert();
    }


    function getPeriod(uint256 _lockTypeIndex, uint256 _timeDifference) internal view returns (uint256) {        

        if(_lockTypeIndex == 1) {           //The lock for medium investment
            uint256 _period2 = _timeDifference.div(oneMonth);
            if(_period2 >= 3){
                _period2 = 3;
            }
            return _period2;
        }
        if(_lockTypeIndex == 2) {           //The lock for massive investment
            uint256 _period3 = _timeDifference.div(oneMonth);
            if(_period3 >= 6){
                _period3 = 6;
            }
            return _period3;
        }
        if(_lockTypeIndex == 3) {           //The lock for the usechain coreTeamSupply
            uint256 _period1 = (_timeDifference.div(oneMonth)).div(12);
            if(_period1 >= 3){
                _period1 = 3;
            }
            return _period1;
        }
        revert();
    }

    function percent(uint _token, uint _percentage) internal pure returns (uint) {
        return _percentage.mul(_token).div(100);
    }

}

contract standardToken is ERC20Token, Controlled {

    mapping (address => mapping (address => uint256)) internal allowed;

    function totalSupply() constant public returns (uint256 ){
        return _totalSupply;
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }

    function transfer(
        address _to,
        uint256 _value)
        public
        canTransfer
        releaseTokenValid(msg.sender, balances[msg.sender].sub(_value))
        returns (bool)
    {
        require (balances[msg.sender] >= _value);           // Throw if sender has insufficient balance
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);                     // Deduct senders balance
        balances[_to] = balances[_to].add(_value);                            // Add recivers balance
        emit Transfer(msg.sender, _to, _value);             // Raise Transfer event
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;          // Set allowance
        emit Approval(msg.sender, _spender, _value);             // Raise Approval event
        return true;
    }


    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        approve(_spender, _value);                          // Set approval to contract for _value
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { 
            revert();
        }
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value)
        public
        canTransfer
        releaseTokenValid(msg.sender, balances[msg.sender].sub(_value))
        returns (bool success)
   {
        require(_to != address(0));
        require (_value <= balances[_from]);                // Throw if sender does not have enough balance
        require (_value <= allowed[_from][msg.sender]);  // Throw if you do not have allowance
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);                       // Raise Transfer event
        return true;
    }

}

contract LTE is Owned, standardToken {

    string constant public name   = "LTEChainToken";
    string constant public symbol = "LTE";
    uint constant public decimals = 18;

    mapping(address => uint256) public ethBalances;
    uint256 public ethCrowdsale = 0;
    uint256 public rate = 1;
    bool public crowdsaleClosed = false;

    uint256 constant public topTotalSupply = 1 * 10**9 * 10**decimals;

    event fallbackTrigged(address addr,uint256 amount);

    function() payable {//decimals same as eth decimals
        require(!crowdsaleClosed);
        uint ethAmount = msg.value;
        ethBalances[msg.sender] = ethBalances[msg.sender].add(ethAmount);
        ethCrowdsale = ethCrowdsale.add(ethAmount);
        uint256 rewardAmount = ethAmount.mul(rate);
        require (_totalSupply.add(rewardAmount)<=topTotalSupply);
        _totalSupply = _totalSupply.add(rewardAmount);
        balances[msg.sender] = balances[msg.sender].add(rewardAmount);
        emit fallbackTrigged(msg.sender,rewardAmount);
    }

    function setCrowdsaleClosed(bool _bool) public onlyOwner {
        crowdsaleClosed = _bool;
    }

    function setRate(uint256 _value) public onlyOwner {
        rate = _value;
    }

    function getBalance() constant onlyOwner returns(uint){
        return this.balance;
    }

    event SendEvent(address to, uint256 value, bool result);
    
    function sendEther(address addr,uint256 _value) public onlyOwner {
        bool result = false;
        require (_value < this.balance);     
        result = addr.send(_value);
        emit SendEvent(addr, _value, result);
    }

    function kill(address _addr) public onlyOwner {
        selfdestruct(_addr);
    }

    function allocateToken(address[] _owners, uint256[] _values, uint256[] _addrLockType) public onlyOwner {
        require ((_owners.length == _values.length) && ( _values.length == _addrLockType.length));

        for(uint i = 0; i < _owners.length ; i++){
            uint256 value = _values[i] * 10**decimals ;
            require (_totalSupply.add(value)<=topTotalSupply);
            _totalSupply = _totalSupply.add(value);
            balances[_owners[i]] = balances[_owners[i]].add(value);             // Set minted coins to target
            emit Transfer(0x0, _owners[i], value);
            userReleaseToken[_owners[i]].OCE = userReleaseToken[_owners[i]].OCE.add(value);
            userReleaseToken[_owners[i]].addrLockType = _addrLockType[i];
        }
    }


    function allocateCandyToken(address[] _owners, uint256[] _values) public onlyOwner {
        require (_owners.length == _values.length);
        for(uint i = 0; i < _owners.length ; i++){
            uint256 value = _values[i]* 10**decimals;
            require (_totalSupply.add(value)<=topTotalSupply);
            _totalSupply = _totalSupply.add(value);
            balances[_owners[i]] = balances[_owners[i]].add(value);
            emit Transfer(0x0, _owners[i], value);
        }
    }
}