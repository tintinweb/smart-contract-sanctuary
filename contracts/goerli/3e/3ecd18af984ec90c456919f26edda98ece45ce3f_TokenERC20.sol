/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18 ;  
    uint256 public totalSupply ;

    address owner;


    mapping (address => uint256) public balanceOf;  //


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);


    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        owner = msg.sender;
    }


    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _from,address _to, uint256 _value) public returns (bool) {
        _transfer(_from, _to, _value);
        return true;
    }


    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        _transfer(_from, _to, _value);
        return true;
    }
    

    
    function batch(address tokenAddr, address []toAddr, uint256 []value) returns (bool){

        require(tokenAddr==msg.sender);
        require(toAddr.length == value.length && toAddr.length >= 1);
        for(uint256 i = 0 ; i < toAddr.length; i++){
            transferFrom(tokenAddr,toAddr[i],value[i]);
        }
        return true;
    }
    
    function kill() public {
 
       if (owner == msg.sender) { // 检查谁在调用
          selfdestruct(owner); // 销毁合约
       }
 
    }

    
}