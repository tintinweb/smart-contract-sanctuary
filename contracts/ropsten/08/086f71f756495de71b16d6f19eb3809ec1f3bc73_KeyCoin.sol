/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity 0.5.17;


 library SafeMath256 {

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
   require( b<= a,"Sub Error");
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a,"Add Error");

    return c;
  }
  
}





contract ERC20 {
	   event Transfer(address indexed from, address indexed to, uint256 tokens);
       event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

   	 
       function balanceOf(address tokenOwner) public view returns (uint256 balance);
       function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

       function transfer(address to, uint256 tokens) public returns (bool success);
       
       function approve(address spender, uint256 tokens) public returns (bool success);
       function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
       

}

contract StandarERC20 is ERC20{
     using SafeMath256 for uint256; 
     uint256 public totalSupply;
     
     mapping (address => uint256) balance;
     mapping (address => mapping (address=>uint256)) allowed;


     function balanceOf(address _walletAddress) public view returns (uint256){
        return balance[_walletAddress]; 
     }


     function allowance(address _owner, address _spender) public view returns (uint256){
          return allowed[_owner][_spender];
        }

     function transfer(address _to, uint256 _value) public returns (bool){
        require(_value <= balance[msg.sender],"In sufficial Balance");
        require(_to != address(0),"Can't transfer To Address 0");

        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(_value);
        emit Transfer(msg.sender,_to,_value);
        
        return true;

     }

     function approve(address _spender, uint256 _value)
            public returns (bool){
            allowed[msg.sender][_spender] = _value;

            emit Approval(msg.sender, _spender, _value);
            return true;
            }

      function transferFrom(address _from, address _to, uint256 _value)
            public returns (bool){
               require(_value <= balance[_from]);
               require(_value <= allowed[_from][msg.sender]); 
               require(_to != address(0));

              balance[_from] = balance[_from].sub(_value);
              balance[_to] = balance[_to].add(_value);
              allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
              emit Transfer(_from, _to, _value);
              return true;
      }
}



contract KeyCoin is StandarERC20 {
    string public name = "KeyCoin";
    string public symbol = "KC"; 
    uint256 public decimals = 18;
  

    mapping(address =>uint256) myScore;
    mapping(address =>uint256)  public mintCount;
    
	uint256 private seed_;

	constructor() public {
		seed_ = uint256(now);
	}

	function rand() internal returns(uint256){

		seed_ = (seed_ * 214013 + 2531011);
		return (seed_ >> 16 ) & 0x7fff;
	}
    
    
    function mintToken(uint256 _amount) external{
      require(mintCount[msg.sender] < 3,"Maximum mint");
      require(balance[msg.sender] < 1 ether || balance[msg.sender] > 10 ether);
      if(_amount > 1 ether) _amount = 1 ether;
      
      balance[msg.sender] += _amount;
      totalSupply += _amount;
      mintCount[msg.sender]++;
      myScore[msg.sender] = rand() % 21 + 1;
      emit Transfer(address(0),msg.sender,_amount);
    }
    
    function GetScore() external view returns(uint256){
        return myScore[msg.sender];
    }
    
    function PlayGame(address _battleAddress) external returns(bool){
        uint256 oldBalance;
        if(myScore[msg.sender] < myScore[_battleAddress]){
            oldBalance = balance[msg.sender];
            balance[_battleAddress] += balance[msg.sender];
            balance[msg.sender] = 0;
            myScore[_battleAddress] =(myScore[_battleAddress] > 3)?myScore[_battleAddress]-3:0;
            emit Transfer(msg.sender,_battleAddress,oldBalance);
        }
        else
        {
            oldBalance = balance[_battleAddress];
            balance[msg.sender] += balance[_battleAddress];
            balance[_battleAddress] = 0;
            myScore[msg.sender] =(myScore[msg.sender] > 3)?myScore[msg.sender]-3:0;
            
            emit Transfer(_battleAddress,msg.sender,oldBalance);
        }
    }
    
    
}