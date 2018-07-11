pragma solidity ^0.4.21;

contract Token{
    function transfer(address _to, uint256 _value){_to;_value;}
}

contract BatchTransfer{
    address public owner;
    mapping (address => bool) public admins;
    Token public token;
    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyOwnerOrAdmin{
        require(msg.sender == owner || admins[msg.sender] == true);
        _;
    }
    
    function BatchTransfer(address _tokenAddr) public {
        owner = msg.sender;
        token = Token(_tokenAddr);
    }
    
    function ownerSetOwner(address newOwner) public onlyOwner{
        owner = newOwner;
    }
    
    function ownerSetAdmin(address[] _admins) public onlyOwner{
        for(uint i = 0; i<_admins.length; i++){
            admins[_admins[i]] = true;
        }
    }
    
    function ownerModAdmin(address _admin, bool _authority) onlyOwner{
        admins[_admin] = _authority;
    }
    
    function ownerTransfer(address _addr, uint _value) public onlyOwner{
        token.transfer(_addr,_value);
    }
    
    function executeBatchTransfer(address[] _dests, uint[] _values) public onlyOwnerOrAdmin returns(uint){
        uint i = 0;
        while (i < _dests.length) {
            token.transfer(_dests[i], _values[i] * (10 ** 18));
            i += 1;
        }
        return i;
    }
    
    
}