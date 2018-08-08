pragma solidity ^0.4.24;

interface ERC20 {
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function approve(address _spender, uint _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface ERC223 {
    function transfer(address _to, uint _value, bytes _data) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract Token {

    string internal _symbol;
    string internal _name;

    uint8 internal _decimals;
    uint internal _totalSupply;

    mapping (address => uint) internal _balanceOf;
    mapping (address => mapping (address => uint)) internal _allowances;

    constructor(string symbol, string name, uint8 decimals, uint totalSupply) public {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply;
    }

    function name()
        public
        view
        returns (string) {
        return _name;
    }

    function symbol()
        public
        view
        returns (string) {
        return _symbol;
    }

    function decimals()
        public
        view
        returns (uint8) {
        return _decimals;
    }

    function totalSupply()
        public
        view
        returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address _addr) public view returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}

library SafeMath {
    function sub(uint _base, uint _value)
        internal
        pure
        returns (uint) {
        assert(_value <= _base);
        return _base - _value;
    }

    function add(uint _base, uint _value)
        internal
        pure
        returns (uint _ret) {
        _ret = _base + _value;
        assert(_ret >= _base);
    }

    function div(uint _base, uint _value)
        internal
        pure
        returns (uint) {
        assert(_value > 0 && (_base % _value) == 0);
        return _base / _value;
    }

    function mul(uint _base, uint _value)
        internal
        pure
        returns (uint _ret) {
        _ret = _base * _value;
        assert(0 == _base || _ret / _base == _value);
    }
}

library Addresses {
    function isContract(address _base) internal view returns (bool) {
        uint codeSize;
            assembly {
            codeSize := extcodesize(_base)
            }
        return codeSize > 0;
    }
}

contract MyToken is Token("LOCA", "Locanza", 8, 5000000000000000), ERC20, ERC223 {

    using SafeMath for uint;
    using Addresses for address;

    address owner;

    struct lockDetail {
        uint amount;
        uint lockedDate;
        uint daysLocked;
        bool Locked;
    }

// to keep track of the minting stages
// The meaning of the 5 stages have yet to be determined
// minting will be done after 25 years or earlier when mining bounties are relevant

    enum Stages {
        FirstLoyaltyProgram,
        Stage1,
        Stage2,
        Stage3,
        Stage4,
        Stage5
    }
    Stages internal stage = Stages.FirstLoyaltyProgram;

// Locked Balance + Balance = total _totalsupply
    mapping(address=>lockDetail)  _Locked;

//Lock event
    event Locked(address indexed _locker, uint _amount);
// Unlock event
    event Unlock(address indexed _receiver, uint _amount);

    modifier onlyOwner () {
        require (owner == msg.sender);
        _;
    }

//checked
    constructor()
        public {
        owner = msg.sender;
        _balanceOf[msg.sender] = _totalSupply;
    }

//checked
    function balanceOf(address _addr)
        public
        view
        returns (uint) {
        return _balanceOf[_addr];
    }
//checked
    function transfer(address _to, uint _value)
        public
        returns (bool) {
        return transfer(_to, _value, "");
    }
//checked
    function transfer(address _to, uint _value, bytes _data)
        public
        returns (bool) {
        require (_value > 0 &&
            _value <= _balanceOf[msg.sender]); 
        
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

            if (_to.isContract()) {
                ERC223ReceivingContract _contract = ERC223ReceivingContract(_to);
                _contract.tokenFallback(msg.sender, _value, _data);
            }
  
        

        return true;
    }
//checked
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool) {
        return transferFrom(_from, _to, _value, "");
    }

//checked
    function transferFrom(address _from, address _to, uint _value, bytes _data)
        public
        returns (bool) {
        require (_allowances[_from][msg.sender] > 0 && 
            _value > 0 &&
            _allowances[_from][msg.sender] >= _value &&
            _balanceOf[_from] >= _value); 

        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);

        if (_to.isContract()) {
            ERC223ReceivingContract _contract = ERC223ReceivingContract(_to);
            _contract.tokenFallback(msg.sender, _value, _data);
              }

        return true;
        
    }
// checked
    function approve(address _spender, uint _value)
        public
        returns (bool) {
        require (_balanceOf[msg.sender] >= _value && _value >= 0); 
            _allowances[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
    }
// checked
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint) {
        
        return _allowances[_owner][_spender];
       
    }

// minting and locking functionality


// Minted coins are added to the total supply
// Minted coins have to be locked between 30 and 365 to protect tokenholders
// Only minting sets a new stage (first stage is the FirstLoyaltyProgram after initial token creation)

    function coinMinter (uint _amount, uint _days) public onlyOwner  returns (bool) {
        require(_amount > 0);
        // max 1 year lock only
        require(_days > 30 && _days <= 365);
    // this is where we eventualy set the total supply
        require (_amount + _totalSupply <= 10000000000000000);
        _totalSupply += _amount;
        stage = Stages(uint(stage)+1);
        lockAfterMinting(_amount, _days);
        return true;
    }
// Only one stage at a time can be minted
// Because of the internal call to lockAfterMinting

    function lockAfterMinting( uint _amount, uint _days) internal onlyOwner returns(bool) {
     // only one token lock (per stage) is possible
        require(_amount > 0);
        require(_days > 30 && _days <= 365);
        require(_Locked[msg.sender].Locked != true);
        _Locked[msg.sender].amount = _amount;
        _Locked[msg.sender].lockedDate = now;
        _Locked[msg.sender].daysLocked = _days;
        _Locked[msg.sender].Locked = true;
        emit Locked(msg.sender, _amount);
        return true;
    }

    function lockOwnerBalance( uint _amount, uint _days) public onlyOwner returns(bool) {
   // max 1 year lock only
        require(_amount > 0);
        require(_days > 30 && _days <= 365);
        require(_balanceOf[msg.sender] >= _amount);
   // only one token lock (per stage) is possible
        require(_Locked[msg.sender].Locked != true);
  // extract tokens from the owner balance
        _balanceOf[msg.sender] -= _amount;

        _Locked[msg.sender].amount = _amount;
        _Locked[msg.sender].lockedDate = now;
        _Locked[msg.sender].daysLocked = _days;
        _Locked[msg.sender].Locked = true;
        emit Locked(msg.sender, _amount);
        return true;
    }

    function lockedBalance() public view returns(uint,uint,uint){
        
        return (_Locked[owner].amount,_Locked[owner].lockedDate,_Locked[owner].daysLocked) ;
    }

// This functions adds te locked tokens to the owner balance
    function unlockOwnerBalance() public onlyOwner returns(bool){

        require(_Locked[msg.sender].Locked == true);
// require statement regarding the date time require for unlock
// for testing purposes only in seconds
        require(now > _Locked[msg.sender].lockedDate + _Locked[msg.sender].daysLocked * 1 days);
        _balanceOf[msg.sender] += _Locked[msg.sender].amount;
        delete _Locked[msg.sender];

        emit Unlock(msg.sender, _Locked[msg.sender].amount);
        return true;
    }

    function getStage() public view returns(string){

        if (uint(stage)==0) {
            return "FirstLoyalty";
        } else if(uint(stage)==1){
            return "Stage1";
         } else if (uint(stage)==2){
            return "Stage2";
        }  else if(uint(stage)==3){
            return "Stage3" ;
        } else if(uint(stage)==4){
            return "Stage4" ;
        }else if(uint(stage)==5){
            return "Stage5" ;
        }
    }

}