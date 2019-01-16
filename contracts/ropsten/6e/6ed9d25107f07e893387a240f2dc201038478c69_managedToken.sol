pragma solidity ^0.4.25;

// Project: token ALE, http://alehub.io
// v1, 2018-12-13
// Full compatibility with ERC20.
// Token with special add. properties: division into privileged (default, for all) and usual tokens (for team).

// Authors: Ivan Fedorov and Dmitry Borodin (CryptoB2B)
// Copying in whole or in part is prohibited.
// This code is the property of CryptoB2B.io

contract IRightAndRoles {
    address[][] public wallets;
    mapping(address => uint16) public roles;

    event WalletChanged(address indexed newWallet, address indexed oldWallet, uint8 indexed role);
    event CloneChanged(address indexed wallet, uint8 indexed role, bool indexed mod);

    function changeWallet(address _wallet, uint8 _role) external;
    function onlyRoles(address _sender, uint16 _roleMask) view external returns(bool);
}

contract RightAndRoles is IRightAndRoles {
    constructor (address[] _roles) public {
        uint8 len = uint8(_roles.length);
        require(len > 0 &&len <16);
        wallets.length = len;

        for(uint8 i = 0; i < len; i++){
            wallets[i].push(_roles[i]);
            roles[_roles[i]] += uint16(2)**i;
            emit WalletChanged(_roles[i], address(0),i);
        }
        
    }

    function changeClons(address _clon, uint8 _role, bool _mod) external {
        require(wallets[_role][0] == msg.sender&&_clon != msg.sender);
        emit CloneChanged(_clon,_role,_mod);
        uint16 roleMask = uint16(2)**_role;
        if(_mod){
            require(roles[_clon]&roleMask == 0);
            wallets[_role].push(_clon);
        }else{
            address[] storage tmp = wallets[_role];
            uint8 i = 1;
            for(i; i < tmp.length; i++){
                if(tmp[i] == _clon) break;
            }
            require(i > tmp.length);
            tmp[i] = tmp[tmp.length];
            delete tmp[tmp.length];
        }
        roles[_clon] = _mod?roles[_clon]|roleMask:roles[_clon]&~roleMask;
    }

    function changeWallet(address _wallet, uint8 _role) external {
        require(wallets[_role][0] == msg.sender || wallets[0][0] == msg.sender || (wallets[2][0] == msg.sender && _role == 0));
        emit WalletChanged(wallets[_role][0],_wallet,_role);
        uint16 roleMask = uint16(2)**_role;
        address[] storage tmp = wallets[_role];
        for(uint8 i = 0; i < tmp.length; i++){
            roles[tmp[i]] = roles[tmp[i]]&~roleMask;
        }
        delete  wallets[_role];
        tmp.push(_wallet);
        roles[_wallet] = roles[_wallet]|roleMask;
    }

    function onlyRoles(address _sender, uint16 _roleMask) view external returns(bool) {
        return roles[_sender]&_roleMask != 0;
    }

    function getMainWallets() view external returns(address[]){
        address[] memory _wallets = new address[](wallets.length);
        for(uint8 i = 0; i<wallets.length; i++){
            _wallets[i] = wallets[i][0];
        }
        return _wallets;
    }

    function getCloneWallets(uint8 _role) view external returns(address[]){
        return wallets[_role];
    }
}



contract GuidedByRoles {
    IRightAndRoles public rightAndRoles;
    constructor(IRightAndRoles _rightAndRoles) public {
        rightAndRoles = _rightAndRoles;
    }
}

contract BaseIterableDubleToken{
    
    uint8 public withdrawPriority;
    uint8 public mixedType;
    
    uint256[2] public supply = [0,0];
    
    struct Item {
        uint256 index;
        uint256 value;
    }
    
    address[][] items = [[address(0)],[address(0)]];
    
    mapping (uint8 => mapping (address => Item)) balances;
    
    mapping (address => mapping (address => uint256)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Mint(address indexed to, uint256 value);
    
    event Burn(address indexed from, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    event changeBalance(uint8 indexed tokenType, address indexed owner, uint256 newValue);
    
    function totalSupply() view public returns(uint256){
        return supply[0] + supply[1];
    }
    
    function balanceOf(address _who) view public returns(uint256) {
        return getBalance(0,_who) + getBalance(1,_who);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool){
        internalTransfer(msg.sender,_to,_value);
        return true;
    }
    
    function getBalance(uint8 _type ,address _addr) view public returns(uint256){
        return balances[_type][_addr].value;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(allowed[_from][msg.sender] >= _value);
        
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        internalTransfer(_from, _to, _value);
        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
        return true;
    }
    
    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        uint256 _tmpAllowed = allowed[msg.sender][_spender] + _addedValue;
        require(_tmpAllowed >= _addedValue);

        allowed[msg.sender][_spender] = _tmpAllowed;
        emit Approval(msg.sender, _spender, _tmpAllowed);
        return true;
    }
    
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        require(allowed[msg.sender][_spender] >= _subtractedValue);
        
        allowed[msg.sender][_spender] -= _subtractedValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function internalMint(uint8 _type, address _account, uint256 _value) internal {
        require(totalSupply() + _value >= _value);
        supply[_type] += _value;
        uint256 _tmpBalance = getBalance(_type,_account) + _value;
        emit Mint(_account,_value);
        setBalance(_type,_account,_tmpBalance);
    }
    
    function internalBurn(uint8 _type, address _account, uint256 _value) internal {
        uint256 _tmpBalance = getBalance(_type,_account);
        require(_tmpBalance >= _value);
        _tmpBalance -= _value;
        emit Burn(_account,_value);
        setBalance(_type,_account,_tmpBalance);
    }
    
    function setBalance(uint8 _type ,address _addr, uint256 _value) internal {
        address[] storage _items = items[_type];
        Item storage _item = balances[_type][_addr];
        if(_item.value == _value) return;
        emit changeBalance(_type, _addr, _value);
        if(_value == 0){
            uint256 _index = _item.index;
            delete balances[_type][_addr];
            _items[_index] = _items[items.length - 1];
            balances[_type][_items[_index]].index = _index;
            _items.length = _items.length - 1;
        }else{
            if(_item.value == 0){
               _item.index = _items.length; 
               _items.push(_addr);
            }
            _item.value = _value;
        }
    }
    
    function internalSend(uint8 _type, address _to, uint256 _value) internal {
        uint8 _tmpType = (mixedType > 1) ? mixedType - 2 : _type;
        uint256 _tmpBalance = getBalance(_tmpType,_to);
        require(mixedType != 1 || _tmpBalance > 0);
        if(_tmpType != _type){
            supply[_type] -= _value;
            supply[_tmpType] += _value;
        }
        setBalance(_tmpType,_to,_tmpBalance + _value);
    }
    
    function internalTransfer(address _from, address _to, uint256 _value) internal {
        require(balanceOf(_from) >= _value);
        emit Transfer(_from,_to,_value);
        uint8 _tmpType = withdrawPriority;
        uint256 _tmpValue = _value;
        uint256 _tmpBalance = getBalance(_tmpType,_from);
        if(_tmpBalance < _value){
            setBalance(_tmpType,_from,0);
            internalSend(_tmpType,_to,_tmpBalance);
            _tmpType = (_tmpType == 0) ? 1 : 0;
            _tmpValue = _tmpValue - _tmpBalance;
            _tmpBalance = getBalance(_tmpType,_from);
        }
        setBalance(_tmpType,_from,_tmpBalance - _tmpValue);
        internalSend(_tmpType,_to,_tmpValue);
    }
    
    function getBalancesList(uint8 _type) view external returns(address[] _addreses, uint256[] _values){
        require(_type < 3);
        address[] storage _items = items[_type];
        uint256 _length = _items.length - 1;
        _addreses = new address[](_length);
        _values = new uint256[](_length);
        for(uint256 i = 0; i < _length; i++){
            _addreses[i] = _items[i + 1];
            _values[i] = getBalance(_type,_items[i + 1]);
        }
    }
}

contract FreezingToken is BaseIterableDubleToken, GuidedByRoles {
    struct freeze {
    uint256 amount;
    uint256 when;
    }

    mapping (address => freeze) freezedTokens;
    
    constructor(IRightAndRoles _rightAndRoles) GuidedByRoles(_rightAndRoles) public {}

    function freezedTokenOf(address _beneficiary) public view returns (uint256 amount){
        freeze storage _freeze = freezedTokens[_beneficiary];
        if(_freeze.when < now) return 0;
        return _freeze.amount;
    }

    function defrostDate(address _beneficiary) public view returns (uint256 Date) {
        freeze storage _freeze = freezedTokens[_beneficiary];
        if(_freeze.when < now) return 0;
        return _freeze.when;
    }

    function masFreezedTokens(address[] _beneficiary, uint256[] _amount, uint256[] _when) public {
        require(rightAndRoles.onlyRoles(msg.sender,3));
        require(_beneficiary.length == _amount.length && _beneficiary.length == _when.length);
        for(uint16 i = 0; i < _beneficiary.length; i++){
            freeze storage _freeze = freezedTokens[_beneficiary[i]];
            _freeze.amount = _amount[i];
            _freeze.when = _when[i];
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf(msg.sender) >= freezedTokenOf(msg.sender) + _value);
        return super.transfer(_to,_value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf(_from) >= freezedTokenOf(_from) + _value);
        return super.transferFrom( _from,_to,_value);
    }
}

contract managedToken is FreezingToken{
    uint256[2] public mintLimit = [101000000 ether, 9000000 ether]; // privileged, usual (total hardcap = 110M tokens)
    uint256[2] public totalMint = [0,0];
    string public constant name = "ALE";
    string public constant symbol = "ALE";
    uint8 public constant decimals = 18;
    
    constructor(IRightAndRoles _rightAndRoles) FreezingToken(_rightAndRoles) public {}
    
    function internalMint(uint8 _type, address _account, uint256 _value) internal {
        totalMint[_type] += _value;
        require(totalMint[_type] <= mintLimit[_type]);
        super.internalMint(_type,_account,_value);
    }
    // _withdrawPriority 
    // first use when sending:
    // 0 - privileged
    // 1 - usual
    // _mixedType
    // 0 - mixing enabled
    // 1 - mixing disabled
    // 2 - mixing disabled, forced conversion into privileged
    // 3 - mixing disabled, forced conversion into usual
    function setup(uint8 _withdrawPriority, uint8 _mixedType) public {
        require(rightAndRoles.onlyRoles(msg.sender,3));
        require(_withdrawPriority < 2 && _mixedType < 4);
        mixedType = _mixedType;
        withdrawPriority = _withdrawPriority;
    }
    function massMint(uint8[] _types, address[] _addreses, uint256[] _values) public {
        require(rightAndRoles.onlyRoles(msg.sender,3));
        require(_types.length == _addreses.length && _addreses.length == _values.length);
        for(uint256 i = 0; i < _types.length; i++){
            internalMint(_types[i], _addreses[i], _values[i]);
        }
    }
    function massBurn(uint8[] _types, address[] _addreses, uint256[] _values) public {
        require(rightAndRoles.onlyRoles(msg.sender,3));
        require(_types.length == _addreses.length && _addreses.length == _values.length);
        for(uint256 i = 0; i < _types.length; i++){
            internalBurn(_types[i], _addreses[i], _values[i]);
        }
    }
    
    function distribution(uint8 _type, address[] _addresses, uint256[] _values, uint256[] _when) public {
        require(rightAndRoles.onlyRoles(msg.sender,3));
        require(_addresses.length == _values.length && _values.length == _when.length);
        uint256 sumValue = 0;
        for(uint256 i = 0; i < _addresses.length; i++){
            sumValue += _values[i]; 
            uint256 _value = getBalance(_type,_addresses[i]) + _values[i];
            setBalance(_type,_addresses[i],_value);
            emit Transfer(msg.sender, _addresses[i], _values[i]);
            if(_when[i] > 0){
                _value = balanceOf(_addresses[i]);
                freeze storage _freeze = freezedTokens[_addresses[i]];
                _freeze.amount = _value;
                _freeze.when = _when[i];
            }
        }
        uint256 _balance = getBalance(_type, msg.sender);
        require(_balance >= sumValue);
        setBalance(_type,msg.sender,_balance-sumValue);
    }
}



contract Creator{

    IRightAndRoles public rightAndRoles;
    managedToken public token;

    constructor() public{
        address[] memory tmp = new address[](3);
        tmp[0] = address(this);
        tmp[1] = msg.sender;
        tmp[2] = 0x19557B8beb5cC065fe001dc466b3642b747DA62B;

        rightAndRoles = new RightAndRoles(tmp);

        token=new managedToken(rightAndRoles);
    }

}