/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

pragma solidity ^0.4.26;

contract oneSendToMore{
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
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    /**
     *  查询授权余额
     **/
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
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
}