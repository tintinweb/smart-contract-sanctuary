/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity ^0.4.16;

contract DAPPToken {
    string public name ="DAPP Token";
    string public symbol = "DAPP";
    string public version= "DAPP Token V1.0.0";
    uint256 public totalSupply;
    
    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;
    
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    
    function DAPPToken() public {
        uint256 _initialSupply=1000000;
        balanceOf[msg.sender]=_initialSupply;
        totalSupply=_initialSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns(bool){
        require(balanceOf[msg.sender]>=_value);
        balanceOf[msg.sender]-=_value;
        balanceOf[_to]+=_value;
        Transfer(msg.sender,_to,_value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowance[msg.sender][_spender]=_value;
        Approval(msg.sender,_spender,_value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_value<=balanceOf[_from]);
        require(_value<=allowance[_from][msg.sender]);
        balanceOf[_from]-=_value;
        balanceOf[_to]+=_value;
        allowance[_from][msg.sender]-=_value;
        Transfer(_from,_to,_value);
        return true;
    }
}