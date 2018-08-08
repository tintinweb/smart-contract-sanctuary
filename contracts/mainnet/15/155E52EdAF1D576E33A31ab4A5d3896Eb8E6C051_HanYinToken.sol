pragma solidity ^0.4.18;


// https://github.com/ethereum/EIPs/issues/20
interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function decimals() public view returns(uint digits);

    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 _value);

}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}


contract Ownable {

    /// `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    function Ownable() public {
        owner = msg.sender;
    }

    address newOwner=0x0;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    ///change the owner
    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /// accept the ownership
    function acceptOwnership() public{
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

contract Controlled is Ownable{

    function Controlled() public {
        exclude[msg.sender] = true;
    }

    modifier onlyAdmin() {
        if(msg.sender != owner){
            require(admins[msg.sender]);
        }
        _;
    }

    mapping(address => bool) admins;

    // Flag that determines if the token is transferable or not.
    bool public transferEnabled = false;

    // frozen account
    mapping(address => bool) exclude;
    mapping(address => bool) locked;
    mapping(address => bool) public frozenAccount;

    // The nonce for avoid transfer replay attacks
    mapping(address => uint256) nonces;


    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);


    function setAdmin(address _addr, bool isAdmin) public onlyOwner returns (bool success){
        admins[_addr]=isAdmin;
        return true;
    }


    function enableTransfer(bool _enable) public onlyOwner{
        transferEnabled=_enable;
    }


    function setExclude(address _addr, bool isExclude) public onlyOwner returns (bool success){
        exclude[_addr]=isExclude;
        return true;
    }

    function setLock(address _addr, bool isLock) public onlyAdmin returns (bool success){
        locked[_addr]=isLock;
        return true;
    }


    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /*
     * Get the nonce
     * @param _addr
     */
    function getNonce(address _addr) public constant returns (uint256){
        return nonces[_addr];
    }

    modifier transferAllowed(address _addr) {
        if (!exclude[_addr]) {
            assert(transferEnabled);
            assert(!locked[_addr]);
            assert(!frozenAccount[_addr]);
        }
        _;
    }

}

contract FeeControlled is Controlled{

    // receive transfer fee account
    address feeReceAccount = 0x0;

    // transfer rate  default value,  rate/10000
    uint16 defaultTransferRate = 0;
     // transfer fee min & max
    uint256 transferFeeMin = 0;
    uint256 transferFeeMax = 10 ** 10;

    // transfer rate, rate/10000
    mapping(address => int16) transferRates;
    // reverse transfer rate when receive from user
    mapping(address => int16) transferReverseRates;


    function setFeeReceAccount(address _addr) public onlyAdmin
    returns (bool success){
        require(_addr != address(0) && feeReceAccount != _addr);
        feeReceAccount = _addr;
        return true;
    }

    function setFeeParams(uint16 _transferRate, uint256 _transferFeeMin, uint256 _transferFeeMax) public onlyAdmin
    returns (bool success){
        require(_transferRate>=0  && _transferRate<10000);
        require(_transferFeeMin>=0 && _transferFeeMin<transferFeeMax);
        transferFeeMin = _transferFeeMin;
        transferFeeMax = _transferFeeMax;
        defaultTransferRate = _transferRate;
        if(feeReceAccount==0x0){
            feeReceAccount = owner;
        }
        return true;
    }


    function setTransferRate(address[] _addrs, int16 _transferRate) public onlyAdmin
    returns (bool success){
        require((_transferRate>=0  || _transferRate==-1)&& _transferRate<10000);
        for(uint256 i = 0; i < _addrs.length ; i++){
            address _addr = _addrs[i];
            transferRates[_addr] = _transferRate;
        }
        return true;
    }


    function removeTransferRate(address[] _addrs) public onlyAdmin
    returns (bool success){
        for(uint256 i = 0; i < _addrs.length ; i++){
            address _addr = _addrs[i];
            delete transferRates[_addr];
        }
        return true;
    }

    function setReverseRate(address[] _addrs, int16 _reverseRate) public onlyAdmin
    returns (bool success){
        require(_reverseRate>0 && _reverseRate<10000);
        for(uint256 i = 0; i < _addrs.length ; i++){
            address _addr = _addrs[i];
            transferReverseRates[_addr] = _reverseRate;
        }
        return true;
    }


    function removeReverseRate(address[] _addrs) public onlyAdmin returns (bool success){
        for(uint256 i = 0; i < _addrs.length ; i++){
            address _addr = _addrs[i];
            delete transferReverseRates[_addr];
        }
        return true;
    }

    function getTransferRate(address _addr) public constant returns(uint16 transferRate){
        if(_addr==owner || exclude[_addr] || transferRates[_addr]==-1){
            return 0;
        }else if(transferRates[_addr]==0){
            return defaultTransferRate;
        }else{
            return uint16(transferRates[_addr]);
        }
    }

    function getTransferFee(address _addr, uint256 _value) public constant returns(uint256 transferFee){
        uint16 transferRate = getTransferRate(_addr);
        transferFee = 0x0;
        if(transferRate>0){
           transferFee =  _value * transferRate / 10000;
        }
        if(transferFee<transferFeeMin){
            transferFee = transferFeeMin;
        }
        if(transferFee>transferFeeMax){
            transferFee = transferFeeMax;
        }
        return transferFee;
    }

    function getReverseRate(address _addr) public constant returns(uint16 reverseRate){
        return uint16(transferReverseRates[_addr]);
    }

    function getReverseFee(address _addr, uint256 _value) public constant returns(uint256 reverseFee){
        uint16 reverseRate = uint16(transferReverseRates[_addr]);
        reverseFee = 0x0;
        if(reverseRate>0){
            reverseFee = _value * reverseRate / 10000;
        }
        if(reverseFee<transferFeeMin){
            reverseFee = transferFeeMin;
        }
        if(reverseFee>transferFeeMax){
            reverseFee = transferFeeMax;
        }
        return reverseFee;
    }

}

contract TokenERC20 is ERC20, Controlled {

   // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    string public version = &#39;v1.0&#39;;

    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    uint256 public allocateEndTime;

    // This creates an array with all balances
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    

    function totalSupply() public view returns(uint){
        return totalSupply;
    }

    function decimals() public view returns(uint){
        return decimals;
    }

    function balanceOf(address _owner) public view returns(uint){
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) 
    public view returns (uint remaining){
        return allowed[_owner][_spender];
    }
    
    

    // Allocate tokens to the users
    // @param _owners The owners list of the token
    // @param _values The value list of the token
    function allocateTokens(address[] _owners, uint256[] _values) public onlyOwner {
        require(allocateEndTime > now);
        require(_owners.length == _values.length);
        for(uint256 i = 0; i < _owners.length ; i++){
            address to = _owners[i];
            uint256 value = _values[i];
            require(totalSupply + value > totalSupply && balances[to] + value > balances[to]) ;
            totalSupply += value;
            balances[to] += value;
        }
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) transferAllowed(_from) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);     // Check allowance
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }


    /*
    * Proxy transfer  token. When some users of the ethereum account has no ether,
    * he or she can authorize the agent for broadcast transactions, and agents may charge agency fees
    * @param _from
    * @param _to
    * @param _value
    * @param feeProxy
    * @param _v
    * @param _r
    * @param _s
    */
    function transferProxy(address _from, address _to, uint256 _value, uint256 _feeProxy,
        uint8 _v,bytes32 _r, bytes32 _s) public transferAllowed(_from) returns (bool){
        require(_value + _feeProxy >= _value);
        require(balances[_from] >=_value  + _feeProxy);
        uint256 nonce = nonces[_from];
        bytes32 h = keccak256(_from,_to,_value,_feeProxy,nonce);
        require(_from == ecrecover(h,_v,_r,_s));
        require(balances[_to] + _value > balances[_to]);
        require(balances[msg.sender] + _feeProxy > balances[msg.sender]);
        balances[_from] -= (_value  + _feeProxy);
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        if(_feeProxy>0){
            balances[msg.sender] += _feeProxy;
            Transfer(_from, msg.sender, _feeProxy);
        }
        nonces[_from] = nonce + 1;
        return true;
    }
}

contract StableToken is TokenERC20, FeeControlled {


    function transfer(address _to, uint256 _value) public returns (bool success) {
        return _transferWithRate(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        return _transferWithRate(_from, _to, _value);
    }

     function _transferWithRate(address _from, address _to, uint256 _value)  transferAllowed(_from) internal returns (bool success) {
        // check transfer rate and transfer fee to owner
        require(balances[_from] >= _value);
        uint256 transferFee = getTransferFee(_from, _value);
        require(balances[_from] >= _value + transferFee);
        if(msg.sender!=_from){
            require(allowed[_from][msg.sender] >= _value + transferFee);
        }
        require(balances[_to] + _value > balances[_to]);
        if(transferFee>0){
            require(balances[feeReceAccount] + transferFee > balances[feeReceAccount]);
        }

        balances[_from] -= (_value + transferFee);
        if(msg.sender!=_from){
            allowed[_from][msg.sender] -= (_value + transferFee);
        }

        balances[_to] += _value;
        Transfer(_from, _to, _value);

        if(transferFee>0){
            balances[feeReceAccount] += transferFee;
            Transfer(_from, feeReceAccount, transferFee);
        }
        return true;
    }


     /*
     * Proxy transfer token with reverse transfer fee. When some users of the ethereum account has no ether,
     * he or she can authorize the agent for broadcast transactions, and agents may charge agency fees
     * @param _from
     * @param _to, must be reverse address
     * @param _value
     * @param fee
     * @param _v
     * @param _r
     * @param _s
     */
    function transferReverseProxy(address _from, address _to, uint256 _value,uint256 _feeProxy,
        uint8 _v,bytes32 _r, bytes32 _s) public transferAllowed(_from) returns (bool){
        require(_feeProxy>=0);
        require(balances[_from] >= _value + _feeProxy);
        require(getReverseRate(_to)>0);
        uint256 nonce = nonces[_from];
        bytes32 h = keccak256(_from,_to,_value, _feeProxy, nonce);
        require(_from == ecrecover(h,_v,_r,_s));

        uint256 transferReverseFee = getReverseFee(_to, _value);
        require(transferReverseFee>0);
        require(balances[_to] + _value > balances[_to]);
        require(balances[feeReceAccount] + transferReverseFee > balances[feeReceAccount]);
        require(balances[msg.sender] + _feeProxy >= balances[msg.sender]);

        balances[_from] -= (_value + _feeProxy);
        balances[_to] += (_value - transferReverseFee);
        balances[feeReceAccount] += transferReverseFee;
        Transfer(_from, _to, _value);
        Transfer(_to, feeReceAccount, transferReverseFee);
        if(_feeProxy>0){
            balances[msg.sender] += _feeProxy;
            Transfer(_from, msg.sender, _feeProxy);
        }

        nonces[_from] = nonce + 1;
        return true;
    }

    /*
    * Proxy transfer  token. When some users of the ethereum account has no ether,
    * he or she can authorize the agent for broadcast transactions, and agents may charge agency fees
    * @param _from
    * @param _to
    * @param _value
    * @param feeProxy
    * @param _v
    * @param _r
    * @param _s
    */
    function transferProxy(address _from, address _to, uint256 _value, uint256 _feeProxy,
        uint8 _v,bytes32 _r, bytes32 _s) public transferAllowed(_from) returns (bool){
        uint256 transferFee = getTransferFee(_from, _value);
        require(_value + transferFee + _feeProxy >= _value);
        require(balances[_from] >=_value + transferFee + _feeProxy);
        uint256 nonce = nonces[_from];
        bytes32 h = keccak256(_from,_to,_value,_feeProxy,nonce);
        require(_from == ecrecover(h,_v,_r,_s));
        require(balances[_to] + _value > balances[_to]);
        require(balances[msg.sender] + _feeProxy > balances[msg.sender]);
        balances[_from] -= (_value + transferFee + _feeProxy);
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        if(_feeProxy>0){
            balances[msg.sender] += _feeProxy;
            Transfer(_from, msg.sender, _feeProxy);
        }
        if(transferFee>0){
            balances[feeReceAccount] += transferFee;
            Transfer(_from, feeReceAccount, transferFee);
        }
        nonces[_from] = nonce + 1;
        return true;
    }

   /*
    * Wrapper function:  transferProxy + transferReverseProxy
    * address[] _addrs => [_from, _origin, _to]
    * uint256[] _values => [_value, _feeProxy]
    * token flows
    * _from->_origin: _value
    * _from->sender: _feeProxy
    * _origin->_to: _value
    * _to->feeAccount: transferFee
    * _from sign:
    * (_v[0],_r[0],_s[0]) = sign(_from, _origin, _value, _feeProxy, nonces[_from])
    * _origin sign:
    * (_v[1],_r[1],_s[1]) = sign(_origin, _to, _value)
    */
    function transferReverseProxyThirdParty(address[] _addrs, uint256[] _values,
        uint8[] _v, bytes32[] _r, bytes32[] _s)
        public transferAllowed(_addrs[0]) returns (bool){
        address _from = _addrs[0];
        address _origin = _addrs[1];
        address _to = _addrs[2];
        uint256 _value = _values[0];
        uint256 _feeProxy = _values[1];

        require(_feeProxy>=0);
        require(balances[_from] >= (_value + _feeProxy));
        require(getReverseRate(_to)>0);
        uint256 transferReverseFee = getReverseFee(_to, _value);
        require(transferReverseFee>0);

        // check sign _from => _origin
        uint256 nonce = nonces[_from];
        bytes32 h = keccak256(_from, _origin, _value, _feeProxy, nonce);
        require(_from == ecrecover(h,_v[0],_r[0],_s[0]));
         // check sign _origin => _to
        bytes32 h1 = keccak256(_origin, _to, _value);
        require(_origin == ecrecover(h1,_v[1],_r[1],_s[1]));


        require(balances[_to] + _value > balances[_to]);
        require(balances[feeReceAccount] + transferReverseFee > balances[feeReceAccount]);
        require(balances[msg.sender] + _feeProxy >= balances[msg.sender]);

        balances[_from] -= _value + _feeProxy;
        balances[_to] += (_value - transferReverseFee);
        balances[feeReceAccount] += transferReverseFee;
       
        Transfer(_from, _origin, _value);
        Transfer(_origin, _to, _value);
        Transfer(_to, feeReceAccount, transferReverseFee);
        
        if(_feeProxy>0){
            balances[msg.sender] += _feeProxy;
            Transfer(_from, msg.sender, _feeProxy);
        }
       

        nonces[_from] = nonce + 1;
        return true;
    }

    /*
     * Proxy approve that some one can authorize the agent for broadcast transaction
     * which call approve method, and agents may charge agency fees
     * @param _from The address which should tranfer TOKEN to others
     * @param _spender The spender who allowed by _from
     * @param _value The value that should be tranfered.
     * @param _v
     * @param _r
     * @param _s
     */
    function approveProxy(address _from, address _spender, uint256 _value,
        uint8 _v,bytes32 _r, bytes32 _s) public returns (bool success) {
        uint256 nonce = nonces[_from];
        bytes32 hash = keccak256(_from,_spender,_value,nonce);
        require(_from == ecrecover(hash,_v,_r,_s));
        allowed[_from][_spender] = _value;
        Approval(_from, _spender, _value);
        nonces[_from] = nonce + 1;
        return true;
    }
}

contract HanYinToken is StableToken{
    
    function HanYinToken() public {
        name = "HanYin stable Token";
        decimals = 6;
        symbol = "HYT";
        version = &#39;v1.0&#39;;
        
        allocateEndTime = now + 1 days;

        setFeeParams(100, 0, 1000000000000);
    }
}