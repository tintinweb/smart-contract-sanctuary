pragma solidity ^0.4.25;


contract TokenERC2 {
    string public name;
    string public symbol;
    uint256 public decimals = 18;
    uint256 public totaoSupply;
    
    mapping(address => uint) public balanceOf ; 
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor(
        uint256 initialSupply,
        string tokenname,
        string tokensymbol
        )public {
            name = tokenname;
            symbol = tokensymbol;
            totaoSupply = initialSupply * 10 ** decimals;
            balanceOf[msg.sender] = totaoSupply;
        }
        
        event Transfer(address _from , address _to , uint256 _value);
        event Approval(address _owner,address _spender , uint256 _value);
        
        
        function _transfer(address _from , address _to , uint256 _value) internal {
            require(_to !=address(0));
            require(balanceOf[_from] >= _value);
            balanceOf[_from] -=_value;
            balanceOf[_to] +=_value;
            emit Transfer(_from,_to,_value);
        }
        
        function transfer(address _to,uint256 _value) public returns (bool){
            _transfer(msg.sender,_to,_value);
            return true;
        }
        
        function transferFrom(address _from ,address _to ,uint256 _value) public returns (bool success){
            require(allowance[_from][msg.sender] >=_value);
            allowance[_from][msg.sender] -=_value;
            _transfer(_from,_to,_value);
            return true;
        }
        function approve(address _spender,uint256 _value) public returns (bool success) {
            allowance[msg.sender][_spender] =_value;
            emit Approval(msg.sender , _spender,_value);
            return true;
        }
}