contract IProxyManagement { 
    function isProxyLegit(address _address) returns (bool){}
    function raiseTransferEvent(address _from, address _to, uint _ammount){}
    function raiseApprovalEvent(address _sender,address _spender,uint _value){}
    function dedicatedProxyAddress() constant returns (address contractAddress){}
}

contract ITokenRecipient { 
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); 
}

contract IFundManagement {
	function fundsCombinedValue() constant returns (uint value){}
    function getFundAlterations() returns (uint alterations){}
}

contract IERC20Token {

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MacroTokenContract{
    
    address public dev;
    address public curator;
    address public mintingContractAddress;
    address public destructionContractAddress;
    uint256 public totalSupply = 0;
    bool public lockdown = false;

    string public standard = &#39;Macro token&#39;;
    string public name = &#39;Macro&#39;;
    string public symbol = &#39;MCR&#39;;
    uint8 public decimals = 8;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    IProxyManagement proxyManagementContract;
    IFundManagement fundManagementContract;

    uint public weiForMcr;
    uint public mcrAmmountForGas;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Mint(address _destination, uint _amount);
    event Destroy(address _destination, uint _amount);
    event McrForGasFailed(address _failedAddress, uint _ammount);

    function MacroTokenContract() { 
        dev = msg.sender;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) returns (bool success){
        if(balances[msg.sender] < _value) throw;
        if(balances[_to] + _value <= balances[_to]) throw;
        if(lockdown) throw;

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        createTransferEvent(true, msg.sender, _to, _value);              
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if(balances[_from] < _value) throw;
        if(balances[_to] + _value <= balances[_to]) throw;
        if(_value > allowed[_from][msg.sender]) throw;
        if(lockdown) throw;

        balances[_from] -= _value;
        balances[_to] += _value;
        createTransferEvent(true, _from, _to, _value);
        allowed[_from][msg.sender] -= _value;
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if(lockdown) throw;
        
        allowed[msg.sender][_spender] = _value;
        createApprovalEvent(true, msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function transferViaProxy(address _source, address _to, uint256 _amount) returns (bool success){
        if (!proxyManagementContract.isProxyLegit(msg.sender)) throw;
        if (balances[_source] < _amount) throw;
        if (balances[_to] + _amount <= balances[_to]) throw;
        if (lockdown) throw;

        balances[_source] -= _amount;
        balances[_to] += _amount;

        if (msg.sender == proxyManagementContract.dedicatedProxyAddress()){
            createTransferEvent(false, _source, _to, _amount); 
        }else{
            createTransferEvent(true, _source, _to, _amount); 
        }
        return true;
    }
    
    function transferFromViaProxy(address _source, address _from, address _to, uint256 _amount) returns (bool success) {
        if (!proxyManagementContract.isProxyLegit(msg.sender)) throw;
        if (balances[_from] < _amount) throw;
        if (balances[_to] + _amount <= balances[_to]) throw;
        if (lockdown) throw;
        if (_amount > allowed[_from][_source]) throw;

        balances[_from] -= _amount;
        balances[_to] += _amount;
        allowed[_from][_source] -= _amount;

        if (msg.sender == proxyManagementContract.dedicatedProxyAddress()){
            createTransferEvent(false, _source, _to, _amount); 
        }else{
            createTransferEvent(true, _source, _to, _amount); 
        }
        return true;
    }
    
    function approveViaProxy(address _source, address _spender, uint256 _value) returns (bool success) {
        if (!proxyManagementContract.isProxyLegit(msg.sender)) throw;
        if(lockdown) throw;
        
        allowed[_source][_spender] = _value;
        if (msg.sender == proxyManagementContract.dedicatedProxyAddress()){
            createApprovalEvent(false, _source, _spender, _value);
        }else{
            createApprovalEvent(true, _source, _spender, _value);
        }
        return true;
    }

    function mint(address _destination, uint _amount) returns (bool success){
        if (msg.sender != mintingContractAddress) throw;
        if(balances[_destination] + _amount < balances[_destination]) throw;
        if(totalSupply + _amount < totalSupply) throw;

        totalSupply += _amount;
        balances[_destination] += _amount;
        Mint(_destination, _amount);
        createTransferEvent(true, 0x0, _destination, _amount);
        return true;
    }

    function destroy(address _destination, uint _amount) returns (bool success) {
        if (msg.sender != destructionContractAddress) throw;
        if (balances[_destination] < _amount) throw;

        totalSupply -= _amount;
        balances[_destination] -= _amount;
        Destroy(_destination, _amount);
        createTransferEvent(true, _destination, 0x0, _amount);
        return true;
    }

    function setTokenCurator(address _curatorAddress){
        if( msg.sender != dev) throw;
        curator = _curatorAddress;
    }
    
    function setMintingContractAddress(address _contractAddress){ 
        if (msg.sender != curator) throw;
        mintingContractAddress = _contractAddress;
    }

    function setDescrutionContractAddress(address _contractAddress){ 
        if (msg.sender != curator) throw;
        destructionContractAddress = _contractAddress;
    }

    function setProxyManagementContract(address _contractAddress){
        if (msg.sender != curator) throw;
        proxyManagementContract = IProxyManagement(_contractAddress);
    }

    function setFundManagementContract(address _contractAddress){
        if (msg.sender != curator) throw;
        fundManagementContract = IFundManagement(_contractAddress);
    }

    function emergencyLock() {
        if (msg.sender != curator && msg.sender != dev) throw;
        
        lockdown = !lockdown;
    }

    function killContract(){
        if (msg.sender != dev) throw;
        selfdestruct(dev);
    }

    function setWeiForMcr(uint _value){
        if (msg.sender != curator) throw;
        weiForMcr = _value;
    }
    
    function setMcrAmountForGas(uint _value){
        if (msg.sender != curator) throw;
        mcrAmmountForGas = _value;
    }

    function getGasForMcr(){
        if (balances[msg.sender] < mcrAmmountForGas) throw;
        if (balances[curator] > balances[curator] + mcrAmmountForGas) throw;
        if (this.balance < weiForMcr * mcrAmmountForGas) throw;

        balances[msg.sender] -= mcrAmmountForGas;
        balances[curator] += mcrAmmountForGas;
        createTransferEvent(true, msg.sender, curator, weiForMcr * mcrAmmountForGas);
        if (!msg.sender.send(weiForMcr * mcrAmmountForGas)) {
            McrForGasFailed(msg.sender, weiForMcr * mcrAmmountForGas);
        }
    }

    function fundManagementAddress() constant returns (address fundManagementAddress){
        return address(fundManagementContract);
    }

    function proxyManagementAddress() constant returns (address proxyManagementAddress){
        return address(proxyManagementContract);
    }

    function fundsCombinedValue() constant returns (uint value){
        return fundManagementContract.fundsCombinedValue();
    }

    function getGasForMcrData() constant returns (uint, uint){
        return (weiForMcr, mcrAmmountForGas);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        ITokenRecipient spender = ITokenRecipient(_spender);
        spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }

    function createTransferEvent(bool _relayEvent, address _from, address _to, uint256 _value) internal {
        if (_relayEvent){
            proxyManagementContract.raiseTransferEvent(_from, _to, _value);
        }
        Transfer(_from, _to, _value);
    }

    function createApprovalEvent(bool _relayEvent, address _sender, address _spender, uint _value) internal {
        if (_relayEvent){
            proxyManagementContract.raiseApprovalEvent(_sender, _spender, _value);
        }
        Approval(_sender, _spender, _value);
    }
    
    function fillContract() payable{
        if (msg.sender != curator) throw;
    }
}