contract IToken {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transferViaProxy(address _from, address _to, uint _value) returns (uint error) {}
    function transferFromViaProxy(address _source, address _from, address _to, uint256 _amount) returns (uint error) {}
    function approveFromProxy(address _source, address _spender, uint256 _value) returns (uint error) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    function issueNewCoins(address _destination, uint _amount) returns (uint error){}
    function issueNewHeldCoins(address _destination, uint _amount){}
    function destroyOldCoins(address _destination, uint _amount) returns (uint error) {}
    function takeTokensForBacking(address _destination, uint _amount){}
}


contract DestructionContract{

    address public curator;
    address public dev;
    IToken tokenContract;

    function DestructionContract(){
        dev = msg.sender;
    }

    function destroy(uint _amount){
        if (msg.sender != curator) throw;

        tokenContract.destroyOldCoins(msg.sender, _amount);
    }

    function setDestructionCurator(address _curatorAdress){
        if (msg.sender != dev) throw;

        curator = _curatorAdress;
    }

    function setTokenContract(address _contractAddress){
        if (msg.sender != curator) throw;

        tokenContract = IToken(_contractAddress);
    }

    function killContract(){
        if (msg.sender != dev) throw;

        selfdestruct(dev);
    }

    function tokenAddress() constant returns (address tokenAddress){
        return address(tokenContract);
    }
}