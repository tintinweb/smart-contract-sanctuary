pragma solidity ^0.4.21;

library MessageSigning {
    function recoverAddressFromSignedMessage(bytes signature, bytes message) internal pure returns (address) {
        require(signature.length == 65);
        bytes32 r;
        bytes32 s;
        bytes1 v;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := mload(add(signature, 0x60))
        }
        return ecrecover(hashMessage(message), uint8(v), r, s);
    }

    function hashMessage(bytes message) internal pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        return keccak256(prefix, Helpers.uintToString(message.length), message);
    }
}

library Helpers {
    /// returns whether `array` contains `value`.
    function addressArrayContains(address[] array, address value) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    // returns the digits of `inputValue` as a string.
    // example: `uintToString(12345678)` returns `"12345678"`
    function uintToString(uint256 inputValue) internal pure returns (string) {
        // figure out the length of the resulting string
        uint256 length = 0;
        uint256 currentValue = inputValue;
        do {
            length++;
            currentValue /= 10;
        } while (currentValue != 0);
        // allocate enough memory
        bytes memory result = new bytes(length);
        // construct the string backwards
        uint256 i = length - 1;
        currentValue = inputValue;
        do {
            result[i--] = byte(48 + currentValue % 10);
            currentValue /= 10;
        } while (currentValue != 0);
        return string(result);
    }

    /// returns whether signatures (whose components are in `vs`, `rs`, `ss`)
    /// contain `requiredSignatures` distinct correct signatures
    /// where signer is in `allowed_signers`
    /// that signed `message`
    function hasEnoughValidSignatures(bytes message, uint8[] vs, bytes32[] rs, bytes32[] ss, address[] allowed_signers, uint256 requiredSignatures) internal pure returns (bool) {
        // not enough signatures
        if (vs.length < requiredSignatures) {
            return false;
        }

        var hash = MessageSigning.hashMessage(message);
        var encountered_addresses = new address[](allowed_signers.length);

        for (uint256 i = 0; i < requiredSignatures; i++) {
            var recovered_address = ecrecover(hash, vs[i], rs[i], ss[i]);
            // only signatures by addresses in `addresses` are allowed
            if (!addressArrayContains(allowed_signers, recovered_address)) {
                return false;
            }
            // duplicate signatures are not allowed
            if (addressArrayContains(encountered_addresses, recovered_address)) {
                return false;
            }
            encountered_addresses[i] = recovered_address;
        }
        return true;
    }

}

interface ERC20 {

  function TokenName() external view returns (string _name);

  function symbol() external view returns (string _symbol);

  function decimals() external view returns (uint _decimals);

  function totalSupply() external view returns (uint _totalSupply);

  function balanceOf(address _owner)external view returns (uint _balance);

  function transfer(address _to,uint _value) external returns (bool _success);

  function transferFrom(address _from, address _to, uint _value) external returns (bool _success);

  function approve(address _spender,uint _value)external returns (bool _success);

  function allowance(address _owner,address _spender) external view returns (uint _remaining);

  event Transfer( address indexed _from,address indexed _to,uint _value);

  event Approval(address indexed _owner,address indexed _spender,uint _value);

}

contract slot is ERC20{

    struct SignaturesCollection {
        /// Signed message.
        bytes message;
        /// Authorities who signed the message.
        address[] authorities;
        /// Signatures
        bytes[] signatures;
    }

    string internal tokenName="slot";
    string internal tokenSymbol="slt";
    uint internal tokenDecimals=0;
    uint internal tokenTotalSupply;
    uint internal transferRate=100;
    mapping (address => uint) internal balances;
    mapping (address => mapping (address => uint)) internal allowed;

    uint256 public requiredSignatures;
    address[] public authorities;
    mapping(bytes32 => address[]) deposits;
    mapping(address => address) public publicAddress;
    mapping (bytes32 => SignaturesCollection) signatures;
    mapping(bytes32 => address[]) syncs;



    event WithdrawSignatureSubmitted(bytes32 messageHash);
    /// Collected signatures which should be relayed to main chain.
    event CollectedSignatures(address authorityResponsibleForRelay, bytes32 messageHash);

    event DepositConfirmation(address recipient, uint256 value, bytes32 transactoinHash);
    event Transfer(address indexed _from,address indexed _to,uint _value);
    event Login(address indexed privateAdd, address indexed publicAdd, uint time);
    event Approval(address indexed _owner,address indexed _spender,uint _value);
    event Sync(address []  _from, address [] _to, uint [] _amount, uint [] time);
    event SyncConfirmation(address indexed _from, address indexed _to, uint time);
    event Pay(address indexed _user, uint _amount , bytes32 transactoinHash);
    event Award(address indexed _user, uint _amount );
    event Consume(address indexed _user, uint _amount);
    event ExchangeToken(address user, uint amount);
    //event UpdateUserInfo(address user, uint gameNewPlayed, uint moneyNewInjected);

    constructor (uint initialSupply, uint _requiredSignatures, address[] _authorities)
    public {
        tokenTotalSupply = initialSupply * 10 ** uint(tokenDecimals);
        balances[msg.sender] = tokenTotalSupply;
        requiredSignatures = _requiredSignatures;
        authorities = _authorities;
    }

    modifier onlyAuthority(){
        require (Helpers.addressArrayContains(authorities, msg.sender));
        _;
    }

    function () payable public{
        require(msg.value>0);
        uint reward = msg.value*transferRate;
        require(balances[msg.sender]+reward >= balances[msg.sender]);
        balances[msg.sender] += reward;
    }

    function login(address publicAdd) public{
        publicAddress[msg.sender] = publicAdd;
        emit Login(msg.sender, publicAdd, now);
    }

    function addAuthority(address newAuthority) public onlyAuthority(){
        authorities.push(newAuthority);
    }

    function setRequiredSignatures(uint newRequiredSignatures) public onlyAuthority(){
        requiredSignatures = newRequiredSignatures;
    }

    function getRequiredSignatures() view public returns(uint _requiredSignatures){
        _requiredSignatures = requiredSignatures;
    }

    function consume(address _user, uint _amount) public returns(bool _success){
        require(balances[_user]>=_amount);
        balances[_user] -= _amount;
        emit Consume(_user, _amount);
        _success = true;
    }

    function sync(address [] _user, uint [] _amount, uint [] _time) public {
	    address _owner = 0x3c62Aa7913bc303ee4B9c07Df87B556B6770E3fC;
        // var hash = keccak256(_user, time);
        // //require(!Helpers.addressArrayContains(syncs[hash],msg.sender));
        // syncs[hash].push(msg.sender);
        // if (syncs[hash].length != requiredSignatures){
        //     emit SyncConfirmation(_user, publicAddress[_user], time);
        //     return;
        // }else{
        //     emit Sync(_user, publicAddress[_user], balances[_user],time);
        //     balances[_user] = 0;
        // }
	address [] memory owners = new address[](_user.length);
        uint num = _user.length;
        for (uint i = 0; i < num ; ++i) {
            require(balances[_user[i]]>= _amount[i]);
            balances[_user[i]] -= _amount[i];
	    owners[i]=_owner;
        }
        emit Sync(_user, owners, _amount, _time);
    }

    function submitSignature(bytes message, bytes signature) public onlyAuthority(){

        require(msg.sender == MessageSigning.recoverAddressFromSignedMessage(signature, message));

        var hash = keccak256(message);

        // each authority can only provide one signature per message
        require(!Helpers.addressArrayContains(signatures[hash].authorities, msg.sender));
        signatures[hash].message = message;
        signatures[hash].authorities.push(msg.sender);
        signatures[hash].signatures.push(signature);

        // TODO: this may cause troubles if requiredSignatures len is changed
        if (signatures[hash].authorities.length == requiredSignatures) {
            emit CollectedSignatures(msg.sender, hash);
        } else {
            emit WithdrawSignatureSubmitted(hash);
        }
    }

    function pay(address _user, uint _amount, bytes32 _transactionHash) public onlyAuthority() {
        var hash = keccak256(_user, _amount, _transactionHash);
        deposits[hash].push(msg.sender);
        if(deposits[hash].length == requiredSignatures) {
            balances[_user] += _amount;
            emit Pay(_user, _amount, _transactionHash);
        }

    }

    function setTransferRate(uint _transfeRate) public onlyAuthority(){
        transferRate =  _transfeRate;
    }


    function TransferRate() external view returns(uint _transfeRate){
        _transfeRate = transferRate;
    }

    function TokenName() external view returns (string _name){
        _name = tokenName;
    }

    function symbol() external view returns (string _symbol){
        _symbol = tokenSymbol;
    }

    function decimals() external view returns (uint _decimals){
        _decimals = tokenDecimals;
    }

    function totalSupply() external view returns (uint _totalSupply){
        _totalSupply = tokenTotalSupply;
    }

    function balanceOf(address _owner)external view returns (uint _balance){
        _balance = balances[_owner];
    }

    function transfer(address _to,uint _value) external returns (bool _success){
        require(_value <= balances[msg.sender]);
        require(balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        _success = true;
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool _success){
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(balances[_to] + _value >= balances[_to]);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        _success = true;
    }

    function approve(address _spender,uint _value)external returns (bool _success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        _success = true;
    }

    function allowance(address _owner,address _spender) external view returns (uint _remaining){
        _remaining = allowed[_owner][_spender];
    }


    // function setUserInfo(address user, uint gameNewPlayed, uint moneyNewInjected) public onlyAuthority() returns (bool _success){
    //     uint gameCycle = user_info[user].gameCycle + gameNewPlayed;
    //     uint moneyInjected = user_info[user].moneyInjected + moneyNewInjected;
    //     require(gameCycle>=user_info[user].gameCycle);
    //     require(moneyInjected>=user_info[user].moneyInjected);
    //     uint amount = gameCycle / config.gamePerToken + moneyInjected / config.moneyPerToken;
    //     uint amount = gameCycle/ config.gamePerToken;
    //     if(amount!=0){
    //         require(balances[user] + amount>= balances[user]);
    //         balances[user] += amount;
    //         emit Award(user, amount);
    //     }
    //     user_info[user].gameCycle = gameCycle % config.gamePerToken;
    //     user_info[user].moneyInjected = moneyInjected % config.moneyPerToken;
    //     _success=true;
    //     emit UpdateUserInfo(user, gameNewPlayed, moneyNewInjected);
    // }

    function award(address _user, uint _amount) public {
        //require(msg.sender==owner);
        require(balances[_user] + _amount>= balances[_user]);
        balances[_user] += _amount;
        //emit Award(_user, _amount);
    }

    /// Get signature
    function signature(bytes32 messageHash, uint256 index) public view returns (bytes) {
        return signatures[messageHash].signatures[index];
    }

    /// Get message
    function message(bytes32 message_hash) public view returns (bytes) {
        return signatures[message_hash].message;
    }

}