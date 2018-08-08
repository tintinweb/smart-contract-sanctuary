pragma solidity ^0.4.18;

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ApproveAndCallReceiver {
    function receiveApproval(
    address _from,
    uint256 _amount,
    address _token,
    bytes _data
    ) public;
}

contract ERC20Token {

    using SafeMath for uint256;
    
    uint256 public totalSupply;
    
    mapping (address => uint256) public balanceOf;

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenI is ERC20Token {

    string public name;                
    uint8 public decimals;             
    string public symbol;              

    function approveAndCall(
    address _spender,
    uint256 _amount,
    bytes _extraData
    ) public returns (bool success);


    function generateTokens(address _owner, uint _amount) public returns (bool);

    function destroyTokens(address _owner, uint _amount) public returns (bool);

}

contract Token is TokenI {

    struct FreezeInfo {
    address user;
    uint256 amount;
    }
    //Key1: step(募资阶段); Key2: user sequence(用户序列)
    mapping (uint8 => mapping (uint8 => FreezeInfo)) public freezeOf; //所有锁仓，key 使用序号向上增加，方便程序查询。
    mapping (uint8 => uint8) public lastFreezeSeq; //最后的 freezeOf 键值。key: step; value: sequence
    mapping (address => uint256) public airdropOf;//空投用户

    address public owner;
    bool public paused=false;//是否暂停私募
    bool public pauseTransfer=false;//是否允许转账
    uint256 public minFunding = 1 ether;  //最低起投额度
    uint256 public airdropQty=0;//每个账户空投获得的量
    uint256 public airdropTotalQty=0;//总共发放的空投代币数量
    uint256 public tokensPerEther = 10000;//1eth兑换多少代币
    address private vaultAddress;//存储众筹ETH的地址
    uint256 public totalCollected = 0;//已经募到ETH的总数量

    event Burn(address indexed from, uint256 value);

    event Freeze(address indexed from, uint256 value);

    event Unfreeze(address indexed from, uint256 value);

    event Payment(address sender, uint256 _ethAmount, uint256 _tokenAmount);

    function Token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        address _vaultAddress
    ) public {
        require(_vaultAddress != 0);
        totalSupply = initialSupply * 10 ** uint256(decimalUnits);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        owner = msg.sender;
        vaultAddress=_vaultAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier realUser(address user){
        if(user == 0x0){
            revert();
        }
        _;
    }

    modifier moreThanZero(uint256 _value){
        if (_value <= 0){
            revert();
        }
        _;
    }

    function transfer(address _to, uint256 _value) realUser(_to) moreThanZero(_value) public returns (bool) {
        require(!pauseTransfer);
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                     // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    function approve(address _spender, uint256 _value) moreThanZero(_value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool success) {
        require(approve(_spender, _amount));
        ApproveAndCallReceiver(_spender).receiveApproval(
        msg.sender,
        _amount,
        this,
        _extraData
        );

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) realUser(_from) realUser(_to) moreThanZero(_value) public returns (bool success) {
        require(!pauseTransfer);
        require(balanceOf[_from] >= _value);                 // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
        require(allowance[_from][msg.sender] >= _value);     // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);                           // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transferMulti(address[] _to, uint256[] _value) onlyOwner public returns (uint256 amount){
        require(_to.length == _value.length);
        uint8 len = uint8(_to.length);
        for(uint8 j; j<len; j++){
            amount = amount.add(_value[j]*10**uint256(decimals));
        }
        require(balanceOf[msg.sender] >= amount);
        for(uint8 i; i<len; i++){
            address _toI = _to[i];
            uint256 _valueI = _value[i]*10**uint256(decimals);
            balanceOf[_toI] = balanceOf[_toI].add(_valueI);
            balanceOf[msg.sender] =balanceOf[msg.sender].sub(_valueI);
            emit Transfer(msg.sender, _toI, _valueI);
        }
    }

    //冻结账户
    function freeze(address _user, uint256 _value, uint8 _step) moreThanZero(_value) onlyOwner public returns (bool success) {
        _value=_value*10**uint256(decimals);
        return _freeze(_user,_value,_step);
    }

    function _freeze(address _user, uint256 _value, uint8 _step) moreThanZero(_value) private returns (bool success) {
        //info256("balanceOf[_user]", balanceOf[_user]);
        require(balanceOf[_user] >= _value);
        balanceOf[_user] = balanceOf[_user].sub(_value);
        freezeOf[_step][lastFreezeSeq[_step]] = FreezeInfo({user:_user, amount:_value});
        lastFreezeSeq[_step]++;
        emit Freeze(_user, _value);
        return true;
    }


    //为用户解锁账户资金
    function unFreeze(uint8 _step) onlyOwner public returns (bool unlockOver) {
        //_end = length of freezeOf[_step]
        uint8 _end = lastFreezeSeq[_step];
        require(_end > 0);
        unlockOver=false;
        uint8  _start=0;
        for(; _end>_start; _end--){
            FreezeInfo storage fInfo = freezeOf[_step][_end-1];
            uint256 _amount = fInfo.amount;
            balanceOf[fInfo.user] += _amount;
            delete freezeOf[_step][_end-1];
            lastFreezeSeq[_step]--;
            emit Unfreeze(fInfo.user, _amount);
        }
    }

    function generateTokens(address _user, uint _amount) onlyOwner public returns (bool) {
        _amount=_amount*10**uint256(decimals);
        return _generateTokens(_user,_amount);
    }

    function _generateTokens(address _user, uint _amount)  private returns (bool) {
        require(balanceOf[owner] >= _amount);
        balanceOf[_user] = balanceOf[_user].add(_amount);
        balanceOf[owner] = balanceOf[owner].sub(_amount);
        emit Transfer(0, _user, _amount);
        return true;
    }

    function destroyTokens(address _user, uint256 _amount) onlyOwner public returns (bool) {
        _amount=_amount*10**uint256(decimals);
        return _destroyTokens(_user,_amount);
    }

    function _destroyTokens(address _user, uint256 _amount) private returns (bool) {
        require(balanceOf[_user] >= _amount);
        balanceOf[owner] = balanceOf[owner].add(_amount);
        balanceOf[_user] = balanceOf[_user].sub(_amount);
        emit Transfer(_user, 0, _amount);
        emit Burn(_user, _amount);
        return true;
    }


    function changeOwner(address newOwner) onlyOwner public returns (bool) {
        balanceOf[newOwner] = balanceOf[owner];
        balanceOf[owner] = 0;
        owner = newOwner;
        return true;
    }


    /**
     * 修改token兑换比率,1eth兑换多少代币
     */
    function changeTokensPerEther(uint256 _newRate) onlyOwner public {
        tokensPerEther = _newRate;
    }

    /**
     * 修改每个账户可获得的空投量
     */   
    function changeAirdropQty(uint256 _airdropQty) onlyOwner public {
        airdropQty = _airdropQty;
    }

    /**
     * 修改空投总量
     */   
    function changeAirdropTotalQty(uint256 _airdropTotalQty) onlyOwner public {
        uint256 _token =_airdropTotalQty*10**uint256(decimals);
        require(balanceOf[owner] >= _token);
        airdropTotalQty = _airdropTotalQty;
    }

        ////////////////
    // 修是否暂停私募
    ////////////////
    function changePaused(bool _paused) onlyOwner public {
        paused = _paused;
    }
    
    function changePauseTranfser(bool _paused) onlyOwner public {
        pauseTransfer = _paused;
    }

    //accept ether
    function() payable public {
        require(!paused);
        address _user=msg.sender;
        uint256 tokenValue;
        if(msg.value==0){//空投
            require(airdropQty>0);
            require(airdropTotalQty>=airdropQty);
            require(airdropOf[_user]==0);
            tokenValue=airdropQty*10**uint256(decimals);
            airdropOf[_user]=tokenValue;
            airdropTotalQty-=airdropQty;
            require(_generateTokens(_user, tokenValue));
            emit Payment(_user, msg.value, tokenValue);
        }else{
            require(msg.value >= minFunding);//最低起投
            require(msg.value % 1 ether==0);//只能投整数倍eth
            totalCollected +=msg.value;
            require(vaultAddress.send(msg.value));//Send the ether to the vault
            tokenValue = (msg.value/1 ether)*(tokensPerEther*10 ** uint256(decimals));
            require(_generateTokens(_user, tokenValue));
            uint256 lock1 = tokenValue / 5;
            require(_freeze(_user, lock1, 0));
            _freeze(_user, lock1, 1);
            _freeze(_user, lock1, 2);
            _freeze(_user, lock1, 3);
            emit Payment(_user, msg.value, tokenValue);

        }
    }
}