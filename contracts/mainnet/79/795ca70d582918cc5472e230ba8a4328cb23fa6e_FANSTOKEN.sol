/**
 *Submitted for verification at Etherscan.io on 2021-05-05
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

contract StandardERC20 is ERC20{
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
        require(_value <= balance[msg.sender],"Insufficient Balance");
      //  require(_to != address(0),"Can't transfer To Address 0");

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
               require(_value <= balance[_from],"Insufficient Balance");
               require(_value <= allowed[_from][msg.sender],"Insufficient Balance allowed"); 
        //       require(_to != address(0));

              balance[_from] = balance[_from].sub(_value);
              balance[_to] = balance[_to].add(_value);
              allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
              emit Transfer(_from, _to, _value);
              return true;
      }
}

contract FANSTOKEN is StandardERC20{
  string public name = "FANS Token";
  string public symbol = "FANS"; 
  uint256 public decimals = 18;
  uint256 public HARD_CAP = 300000000 ether; 
  
  address public CO_FOUNDER= 0x37805553F1BcAb2CcdBa037B506a6824A17C43Ca;
  address public QR_MINING = 0xA5fa2c9B2290b381f68Dcf7A4C91e906ECea4dF4;
  address public DEV_TEAM  = 0x72B679CEF3dC3092d1b1dfB1C38F24227eBa41d0;
  address public AIR_DROP  = 0x795942F221ac040aa8424ECeCb6E13E342535B40;
  address public COMMUNITY = 0xFC42c43156C0C5A9b704453290656F31f9234619;


  function _preMint(address _addr,uint256 _amount) internal{
      balance[_addr] = _amount;
      totalSupply += _amount;
       emit Transfer(address(0),_addr,_amount);
  }

  constructor() public {
       _preMint(CO_FOUNDER,150000000 ether);
       _preMint(QR_MINING,  90000000 ether);
       _preMint(DEV_TEAM,   15000000 ether);
       _preMint(AIR_DROP,   15000000 ether);
       _preMint(COMMUNITY,  30000000 ether);
     
  }
  

}