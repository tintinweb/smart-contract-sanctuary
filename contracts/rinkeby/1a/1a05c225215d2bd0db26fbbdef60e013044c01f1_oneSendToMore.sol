/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

pragma solidity ^0.4.24;

contract oneSendToMore{
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
        address owner = 0x0;
    //添加payable,支持在创建合约的时候，value往合约里面传eth
        constructor () public  payable{
            owner = msg.sender;
        }
    /**
     * 余额查询
     **/
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    /**
     * 可用金额授权
     **/
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    /**
     * 直接转账-1
     **/
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    /**
     * 直接转账-2 
     **/
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    
    
    
    
    /**
     * ETH转账
     **/
     
     
    /**
     * 批量转账-1
     **/
    function transferEthsAvg(address[] _tos,uint256 _value) public returns (bool) {//添加payable,支持在调用方法的时候，value往合约里面传eth，注意该value最终平分发给所有账户
        require(_tos.length > 0);
        require(msg.sender == owner);
        for(uint32 i=0;i<_tos.length;i++){
        _tos[i].transfer(_value);
        }
        return true;
    }
    
    /**
     * 批量转账-2
     **/
    function transferEths(address[] _tos,uint256[] values) public returns (bool) {//添加payable,支持在调用方法的时候，value往合约里面传eth，注意该value最终平分发给所有账户
        require(_tos.length > 0);
        require(msg.sender == owner);
        for(uint32 i=0;i<_tos.length;i++){
        _tos[i].transfer(values[i]);
        }
        return true;
    }
    
    
     
    
    /**
     * ERC20 Token代币转账
     **/
     
    
    /**
     * 批量转账-1
     **/
    function transferTokensAvg(address from,address caddress,address[] _tos,uint v)public returns (bool){
        require(_tos.length > 0);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint i=0;i<_tos.length;i++){
            caddress.call(id,from,_tos[i],v);
        }
        return true;
    }
    
    
    /**
     * 批量转账-2
     **/
    function transferTokens(address from,address caddress,address[] _tos,uint[] values)public returns (bool){
        require(_tos.length > 0);
        require(values.length > 0);
        require(values.length == _tos.length);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint i=0;i<_tos.length;i++){
            caddress.call(id,from,_tos[i],values[i]);
        }
        return true;
    }
    

}