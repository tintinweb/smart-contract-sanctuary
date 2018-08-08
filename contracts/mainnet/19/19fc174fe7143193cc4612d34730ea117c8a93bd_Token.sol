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

//normal contract. already compiled as bin
contract Controlled {
    modifier onlyController {
        require(msg.sender == controller);
        _;
    }
    address public controller;

    function Controlled() public {
        controller = msg.sender;
    }

    function changeController(address _newController) onlyController public {
        controller = _newController;
    }
}


contract ERC20Token {

    using SafeMath for uint256;
    /// total amount of tokens
    uint256 public totalSupply;
    //function totalSupply() public constant returns (uint256 balance);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    mapping (address => uint256) public balanceOf;

    // function balanceOf(address _owner) public constant returns (uint256 balance);

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
    mapping (address => mapping (address => uint256)) public allowance;
    //function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenI is ERC20Token, Controlled {

    string public name;                //The Token&#39;s name: e.g. DigixDAO Tokens
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP


    // ERC20 Methods

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(
    address _spender,
    uint256 _amount,
    bytes _extraData
    ) public returns (bool success);


    // Generate and destroy tokens

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint _amount) public returns (bool);


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
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
    uint256 public minFunding = 1 ether;  //最低起投额度
    uint256 public airdropQty=0;//每个账户空投获得的量
    uint256 public airdropTotalQty=0;//总共发放的空投代币数量
    uint256 public tokensPerEther = 9000;//1eth兑换多少代币
    address private vaultAddress;//存储众筹ETH的地址
    uint256 public totalCollected = 0;//已经募到ETH的总数量

    /* This generates a public event on the blockchain that will notify clients */
    //event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);

    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    event Payment(address sender, uint256 _ethAmount, uint256 _tokenAmount);

    /* Initializes contract with initial supply tokens to the creator of the contract */
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

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) {
            return false;
        }
        assembly {
        size := extcodesize(_addr)
        }
        return size>0;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) realUser(_to) moreThanZero(_value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                     // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) moreThanZero(_value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * @notice `msg.sender` approves `_spender` to send `_amount` tokens on
     *  its behalf, and then a function is triggered in the contract that is
     *  being approved, `_spender`. This allows users to use their tokens to
     *  interact with contracts in one function call instead of two
     * @param _spender The address of the contract able to transfer the tokens
     * @param _amount The amount of tokens to be approved for transfer
     * @return True if the function call was successful
     */
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

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) realUser(_from) realUser(_to) moreThanZero(_value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);                           // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = allowance[_from][msg.sender] + _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function transferMulti(address[] _to, uint256[] _value) onlyController public returns (uint256 amount){
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
            Transfer(msg.sender, _toI, _valueI);
        }
    }

    //冻结账户
    function freeze(address _user, uint256 _value, uint8 _step) moreThanZero(_value) onlyController public returns (bool success) {
        _value=_value*10**uint256(decimals);
        return _freeze(_user,_value,_step);
    }

    function _freeze(address _user, uint256 _value, uint8 _step) moreThanZero(_value) private returns (bool success) {
        //info256("balanceOf[_user]", balanceOf[_user]);
        require(balanceOf[_user] >= _value);
        balanceOf[_user] = balanceOf[_user] - _value;
        freezeOf[_step][lastFreezeSeq[_step]] = FreezeInfo({user:_user, amount:_value});
        lastFreezeSeq[_step]++;
        Freeze(_user, _value);
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
            Unfreeze(fInfo.user, _amount);
        }
    }


    ////////////////
    // Generate and destroy tokens
    ////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _user The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _user, uint _amount) onlyController public returns (bool) {
        _amount=_amount*10**uint256(decimals);
        return _generateTokens(_user,_amount);
    }

    function _generateTokens(address _user, uint _amount)  private returns (bool) {
        require(balanceOf[owner] >= _amount);
        balanceOf[_user] += _amount;
        balanceOf[owner] -= _amount;
        Transfer(0, _user, _amount);
        return true;
    }

    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _user The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _user, uint256 _amount) onlyOwner public returns (bool) {
        _amount=_amount*10**uint256(decimals);
        return _destroyTokens(_user,_amount);
    }

    function _destroyTokens(address _user, uint256 _amount) private returns (bool) {
        require(balanceOf[_user] >= _amount);
        balanceOf[owner] += _amount;
        balanceOf[_user] -= _amount;
        Transfer(_user, 0, _amount);
        Burn(_user, _amount);
        return true;
    }


    function changeOwner(address newOwner) onlyOwner public returns (bool) {
        balanceOf[newOwner] += balanceOf[owner];
        balanceOf[owner] = 0;
        owner = newOwner;
        return true;
    }


    /**
     * 修改token兑换比率,1eth兑换多少代币
     */
    function changeTokensPerEther(uint256 _newRate) onlyController public {
        tokensPerEther = _newRate;
    }

    /**
     * 修改每个账户可获得的空投量
     */   
    function changeAirdropQty(uint256 _airdropQty) onlyController public {
        airdropQty = _airdropQty;
    }

    /**
     * 修改空投总量
     */   
    function changeAirdropTotalQty(uint256 _airdropTotalQty) onlyController public {
        uint256 _token =_airdropTotalQty*10**uint256(decimals);
        require(balanceOf[owner] >= _token);
        airdropTotalQty = _airdropTotalQty;
    }

        ////////////////
    // 修是否暂停私募
    ////////////////
    function changePaused(bool _paused) onlyController public {
        paused = _paused;
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
            Payment(_user, msg.value, tokenValue);
        }else{
            require(msg.value >= minFunding);//最低起投
            require(msg.value % 1 ether==0);//只能投整数倍eth
            totalCollected +=msg.value;
            require(vaultAddress.send(msg.value));//把eth转到收款账户
            tokenValue = (msg.value/1 ether)*(tokensPerEther*10 ** uint256(decimals));
            require(_generateTokens(_user, tokenValue));
            //前期30%不封锁，每个半年（6个月）解锁35%，1年届满即可解锁所有SPM
            //
            require(_freeze(_user, tokenValue*35/100, 0));
            _freeze(_user, tokenValue*35/100, 1);
            Payment(_user, msg.value, tokenValue);

        }
    }
}