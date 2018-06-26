// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
pragma solidity ^0.4.15;

contract Token {
    /* This is a slight change to the ERC20 base standard.*/
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint256 balance);

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
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {

    /// `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    function Owned() public {
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

contract Controlled is Owned{

    function Controlled() public {
        setExclude(msg.sender);
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

    // flag that makes locked address effect
    bool lockFlag=true;
    mapping(address => bool) locked;
    mapping(address => bool) exclude;



    function addAdmin(address _addr) public onlyOwner returns (bool success){
        admins[_addr]=true;
        return true;
    }

    function removeAdmin(address _addr) public onlyOwner returns (bool success){
        admins[_addr]=false;
        return true;
    }

    function enableTransfer(bool _enable) public onlyOwner{
        transferEnabled=_enable;
    }



    function disableLock(bool _enable) public onlyOwner returns (bool success){
        lockFlag=_enable;
        return true;
    }

    function addLock(address _addr) public onlyAdmin returns (bool success){
        require(_addr!=msg.sender);
        locked[_addr]=true;
        return true;
    }


    function setExclude(address _addr) public onlyOwner returns (bool success){
        exclude[_addr]=true;
        return true;
    }

    function removeLock(address _addr) public onlyOwner returns (bool success){
        locked[_addr]=false;
        return true;
    }



    modifier transferAllowed(address _addr) {
        if (!exclude[_addr]) {
            assert(transferEnabled);
            if(lockFlag){
                assert(!locked[_addr]);
            }
        }
        _;
    }

}

contract  FeeRateControlled is Controlled{

    // transfer fee account
    address feeAddr = 0x0;

    // default transfer rate,  rate/10000
    uint16 defaultTransferRate = 0; //test only
    // transfer rate, rate/10000
    mapping(address => int16) transferRates;
    // reverse transfer rate when receive from user
    mapping(address => int16) transferReverseRates;

    function setFeeAddr(address _addr) public onlyOwner returns (bool success){
        require(_addr != 0x0 && feeAddr != _addr);
        feeAddr = _addr;
        return true;
    }

    function setDefaultTransferRate(uint16 _transferRate) public onlyOwner returns (bool success){
        require(_transferRate>=0  && _transferRate<10000);
        defaultTransferRate = _transferRate;
        if(feeAddr==0x0){
            feeAddr = owner;
        }
        return true;
    }

    function setTransferRate(address _addr, int16 _transferRate) public onlyAdmin returns (bool success){
        require((_transferRate>=0  || _transferRate==-1)&& _transferRate<10000);
        transferRates[_addr] = _transferRate;
        return true;
    }

    function setTransferRate(address[] _addrs, int16 _transferRate) public onlyAdmin returns (bool success){
        require((_transferRate>=0  || _transferRate==-1)&& _transferRate<10000);
        for(uint256 i = 0; i < _addrs.length ; i++){
            address _addr = _addrs[i];
            transferRates[_addr] = _transferRate;
        }
        return true;
    }

    function removeTransferRate(address _addr) public onlyAdmin returns (bool success){
        delete transferRates[_addr];
        return true;
    }

    function removeTransferRate(address[] _addrs) public onlyAdmin returns (bool success){
        for(uint256 i = 0; i < _addrs.length ; i++){
            address _addr = _addrs[i];
            delete transferRates[_addr];
        }
        return true;
    }

    function setReverseRate(address _addr, int16 _reverseRate) public onlyAdmin returns (bool success){
        require(_reverseRate>0 && _reverseRate<10000);
        transferReverseRates[_addr] = _reverseRate;
        return true;
    }

    function setReverseRate(address[] _addrs, int16 _reverseRate) public onlyAdmin returns (bool success){
        require(_reverseRate>0 && _reverseRate<10000);
        for(uint256 i = 0; i < _addrs.length ; i++){
            address _addr = _addrs[i];
            transferReverseRates[_addr] = _reverseRate;
        }
        return true;
    }

    function removeReverseRate(address _addr) public onlyAdmin returns (bool success){
        delete transferReverseRates[_addr];
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
        if(transferRate>0){
           return _value * transferRate / 10000;
        }
        return 0;
    }

    function getReverseRate(address _addr) public constant returns(uint16 reverseRate){
        return uint16(transferReverseRates[_addr]);
    }

    function getReverseFee(address _addr, uint256 _value) public constant returns(uint256 reverseFee){
        uint16 reverseRate = uint16(transferReverseRates[_addr]);
        if(reverseRate>0){
            return _value * reverseRate / 10000;
        }
        return 0;
    }
}

contract StandardToken is Token, FeeRateControlled {

    function transfer(address _to, uint256 _value) public transferAllowed(msg.sender) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public transferAllowed(_from) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract StableToken is StandardToken {

    function () public {
        revert();
    }

    // The nonce for avoid transfer replay attacks
    mapping(address => uint256) nonces;


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
            require(balances[feeAddr] + transferFee > balances[feeAddr]);
        }

        balances[_from] -= (_value + transferFee);
        if(msg.sender!=_from){
            allowed[_from][msg.sender] -= (_value + transferFee);
        }

        balances[_to] += _value;
        Transfer(_from, _to, _value);

        if(transferFee>0){
            balances[feeAddr] += transferFee;
            Transfer(_from, feeAddr, transferFee);
        }
        return true;
    }

    function transferReverseProxy(address _from, address _to, uint256 _value,uint256 _feeProxy,
        uint8 _v,bytes32 _r, bytes32 _s) public transferAllowed(_from) returns (bool){
        require(_feeProxy>=0);
        require(balances[_from] >= _value + _feeProxy);
        uint256 transferReverseFee = getReverseFee(_to, _value);
        require(transferReverseFee>0);
        uint256 nonce = nonces[_from];
        bytes32 h = keccak256(_from,_to,_value, _feeProxy, nonce);
        require(_from == ecrecover(h,_v,_r,_s));

        require(balances[_to] + _value > balances[_to]);
        require(balances[feeAddr] + transferReverseFee > balances[feeAddr]);
        require(balances[msg.sender] + _feeProxy >= balances[msg.sender]);

        balances[_from] -= _value + _feeProxy;
        balances[_to] += (_value - transferReverseFee);
        balances[feeAddr] += transferReverseFee;
        Transfer(_from, _to, _value);
        Transfer(_to, feeAddr, transferReverseFee);
        balances[msg.sender] += _feeProxy;
        Transfer(_from, msg.sender, _feeProxy);

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
            balances[feeAddr] += transferFee;
            Transfer(_from, feeAddr, transferFee);
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
        require(balances[feeAddr] + transferReverseFee > balances[feeAddr]);
        require(balances[msg.sender] + _feeProxy >= balances[msg.sender]);

        balances[_from] -= _value + _feeProxy;
        balances[_to] += (_value - transferReverseFee);
        balances[feeAddr] += transferReverseFee;
        balances[msg.sender] += _feeProxy;

        Transfer(_from, _origin, _value);
        Transfer(_origin, _to, _value);
        Transfer(_to, feeAddr, transferReverseFee);
        Transfer(_from, msg.sender, _feeProxy);

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


    /*
     * Get the nonce
     * @param _addr
     */
    function getNonce(address _addr) public constant returns (uint256){
        return nonces[_addr];
    }

}

contract HanYinToken is StableToken{

    string public name = &quot;HanYin stable Token&quot;;                   //fancy name
    uint8 public decimals = 6;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol = &quot;HYT&quot;;                 //An identifier
    string public version = &#39;v1.0&#39;;       //SET 0.1 standard. Just an arbitrary versioning scheme.
    uint256 public allocateEndTime;


    function HanYinToken() public {
        allocateEndTime = now + 1 days;
        //allocateEndTime = now + 10 years;

        //uint256 value = 100000000000;
        //balances[msg.sender] += value;
        //totalSupply += value;
        //setDefaultTransferRate(200);
        //enableTransfer(true);
    }

    // Allocate tokens to the users
    // @param _owners The owners list of the token
    // @param _values The value list of the token
    function allocateTokens(address[] _owners, uint256[] _values) public onlyOwner {

        if(allocateEndTime < now) revert();
        if(_owners.length != _values.length) revert();

        for(uint256 i = 0; i < _owners.length ; i++){
            address to = _owners[i];
            uint256 value = _values[i];
            if(totalSupply + value <= totalSupply || balances[to] + value <= balances[to]) revert();
            totalSupply += value;
            balances[to] += value;
        }
    }


    function setMerchantRate(address[] _addrs, int16 _reverseRate) public returns (bool success){
        return setReverseRate(_addrs, _reverseRate);
    }

    /*
     * Proxy transfer  token. When some users of the ethereum account has no ether,
     * he or she can authorize the agent for broadcast transactions, and agents may charge agency fees
     * @param _from
     * @param _to, must be Merchant address
     * @param _value
     * @param fee
     * @param _v
     * @param _r
     * @param _s
     */
    function transferMerchantProxy(address _from, address _to, uint256 _value,uint256 _fee,
        uint8 _v,bytes32 _r, bytes32 _s) public returns (bool){
        return transferReverseProxy(_from, _to, _value, _fee, _v, _r, _s);
    }
}