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

contract IToken {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transferViaProxy(address _from, address _to, uint _value) returns (uint error) {}
    function transferFromViaProxy(address _source, address _from, address _to, uint256 _amount) returns (uint error) {}
    function approveViaProxy(address _source, address _spender, uint256 _value) returns (uint error) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {} 
    function mint(address _destination, uint _amount) returns (uint error){}
    function destroy(address _destination, uint _amount) returns (uint error) {}
}

contract MacroProxyContract is IERC20Token {

    address public dev;
    address public curator;
    address public proxyManagementAddress;
    bool public proxyWorking;

    string public standard = &#39;MacroERC20Proxy&#39;;
    string public name = &#39;Macro&#39;;
    string public symbol = &#39;MCR&#39;;
    uint8 public decimals = 8;

    IToken tokenContract;

    function MacroProxyContract(){ 
        dev = msg.sender;
    }

    function totalSupply() constant returns (uint256 supply) {
        return tokenContract.totalSupply();
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return tokenContract.balanceOf(_owner);
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (!proxyWorking) throw;
        
        tokenContract.transferViaProxy(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (!proxyWorking) throw;

        tokenContract.transferFromViaProxy(msg.sender, _from, _to, _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if (!proxyWorking) throw;
        
        tokenContract.approveViaProxy(msg.sender, _spender, _value);
        Approval(msg.sender, _spender, _value);
        return true;
     
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return tokenContract.allowance(_owner, _spender);
    } 

    function setTokenContract(address _tokenAddress) {
        if (msg.sender != curator) throw;
        tokenContract = IToken(_tokenAddress);
    }
    
    function setProxyManagementAddress(address _proxyManagementAddress){ 
        if (msg.sender != curator) throw;
        proxyManagementAddress = _proxyManagementAddress;
    }

    function enableDisableTokenProxy(){
        if (msg.sender != curator) throw;
        proxyWorking = !proxyWorking;

    }
    
    function setProxyCurator(address _curatorAddress){
        if( msg.sender != dev) throw;
        curator = _curatorAddress;
    }

    function killContract(){
        if (msg.sender != dev) throw;
        selfdestruct(dev);
    }

    function tokenAddress() constant returns (address contractAddress){
        return address(tokenContract);
    }

    function raiseTransferEvent(address _from, address _to, uint256 _value){
        if(msg.sender != proxyManagementAddress) throw;
        Transfer(_from, _to, _value);
    }

    function raiseApprovalEvent(address _owner, address _spender, uint256 _value){
        if(msg.sender != proxyManagementAddress) throw;
        Approval(_owner, _spender, _value);
    }

    function () {
        throw;     
    }
}