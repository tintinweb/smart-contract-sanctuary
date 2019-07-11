/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity^0.4.21;
contract Token{
uint256 public totalSupply;
function transfer(address _to,uint256 _value)public returns(bool);
function transferFrom(address _from,address _to,uint256 _value)public returns(bool success);
function approve(address _spender,uint256 _value)public;}


contract A{
Token TestToken;


//初始化该合约
uint256 public a;
//创建的合约代币总数
function aTransfer(address contractAddress,address[] _to,uint256[] _value)public returns(bool){
    TestToken=Token(contractAddress);
    for(uint i=0;i<=_to.length;i++){
    
    TestToken.transferFrom(msg.sender,_to[i],_value[i]);
    
    }
    
}

//
function bTransfer(address from,address caddress,address[] _to,uint256[] _value)public returns(bool){
        require(_to.length > 0);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint i=0;i<_to.length;i++){
            caddress.call(id,from,_to[i],_value[i]);
        }
        return true;
    
    
}

	

    
}