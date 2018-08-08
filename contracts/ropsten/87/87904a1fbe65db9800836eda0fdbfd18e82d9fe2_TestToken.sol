pragma solidity ^0.4.24;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract JtTsOwner{
 
 address public owner;
 
 constructor() public{
     owner = msg.sender;
 }
 
 modifier onlyOwner {
     require(msg.sender == owner);
     _;
 }
 
 function transferOwnerShip(address newOwner) public onlyOwner{
     owner = newOwner;
 }
 
}


contract TokenAllot is JtTsOwner{
 
  mapping(string => uint256) tokenMap; 
  
  mapping(string => uint8) frozenTokenMap; 
 
  function initFrozenTokenMap() private{
      //shi mu ji gou
      frozenTokenMap["SM"] = 1;
      //shi chang tui guang
      frozenTokenMap["SCTG"] = 1;
      //chuang shi tuan dui
      frozenTokenMap["CSTD"] = 1;
      //WFT ji jin hui
      frozenTokenMap["WFTJJ"] = 0;
      //zao qi tou zi zhe
      frozenTokenMap["ZQTZZ"] = 1;
      //sheng tai wang kuang 
      frozenTokenMap["STWK"] = 1;
 }
 
  modifier frozenTypeCheck(string tokenType) {
    require(frozenTokenMap[tokenType] == 1);
     _;
  }
 
  function allotToken(uint256 initialSupply) public{
      initFrozenTokenMap();
      //shi mu ji gou
      tokenMap["SM"] = initialSupply * 20 / 100;
      //shi chang tui guang
      tokenMap["SCTG"] = initialSupply * 15 / 100;
      //chuang shi tuan dui
      tokenMap["CSTD"] = initialSupply * 10 / 100;
      //WFT ji jin hui
      tokenMap["WFTJJ"] = initialSupply * 10 / 100;
      //zao qi tou zi zhe
      tokenMap["ZQTZZ"] = initialSupply * 10 / 100;
      //sheng tai wang kuang 
      tokenMap["STWK"] = initialSupply * 35 / 100;
      
  }
  
  function frozenType(string tokenType) public onlyOwner returns (bool success){
      uint8 oldTokenType = frozenTokenMap[tokenType];
      if(oldTokenType != 0){
          frozenTokenMap[tokenType] = 1;
      }
      if(frozenTokenMap[tokenType] == 1){
          return true;
      }
      return false;
  }
  
  function unfrozenType(string tokenType) public onlyOwner returns (bool success){
      uint8 oldTokenType = frozenTokenMap[tokenType];
      if(oldTokenType != 1){
          frozenTokenMap[tokenType] = 0;
      }
      if(frozenTokenMap[tokenType] == 0){
          return true;
      }
      return false;
  }
}

contract TestToken is TokenAllot {
    
    string public name = "WFTTS";
    string public symbol = "WFTSB";
    uint8 public decimals = 0;  // 18 是建议的默认值
    uint256 public totalSupply = 1000000000;
    
    mapping (address => uint256) public balanceOf;  
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    constructor(uint256 initoalSupply)public {
        totalSupply = initoalSupply;
        balanceOf[msg.sender] = totalSupply;
        allotToken(totalSupply);
    }


    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

}