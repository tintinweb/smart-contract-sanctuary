pragma solidity ^0.4.18;

library SafeMath {

  function add(uint a, uint b)
    internal
    pure
    returns (uint c)
  {
    c = a + b;
    require(c >= a);
  }

  function sub(uint a, uint b)
    internal
    pure
    returns (uint c)
  {
    require(b <= a);
    c = a - b;
  }

  function mul(uint a, uint b)
    internal
    pure
    returns (uint c)
  {
    c = a * b;
    require(a == 0 || c / a == b);
  }

  function div(uint a, uint b)
    internal
    pure
    returns (uint c)
  {
    require(b > 0);
    c = a / b;
  }

}


contract ERC20Interface {

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

}




contract Owned {

  event OwnershipTransferred(address indexed _from, address indexed _to);

  address public owner;
  address public newOwner;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function Owned()
    public
  {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner)
    public
    onlyOwner
  {
    newOwner = _newOwner;
  }

  function acceptOwnership()
    public
  {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }

}

contract ELOT is ERC20Interface, Owned {

  using SafeMath for uint;

  string public symbol;
  string public  name;
  uint8 public decimals;
  uint public _totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  function ELOT()
    public
  {
    symbol = "ELOT";
    name = "ELOT COIN";
    decimals = 0;
    _totalSupply = 5000000000 ;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }

  function totalSupply()
    public
    constant
    returns (uint)
  {
    return _totalSupply  - balances[address(0)];
  }

  function balanceOf(address tokenOwner)
    public
    constant
    returns (uint balance)
  {
    return balances[tokenOwner];
  }


  function transfer(address to, uint tokens)
    public
    returns (bool success)
  {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }


  function approve(address spender, uint tokens)
    public
    returns (bool success)
  {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(address from, address to, uint tokens)
    public
    returns (bool success)
  {
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }

  function allowance(address tokenOwner, address spender)
    public
    constant
    returns (uint remaining)
  {
    return allowed[tokenOwner][spender];
  }


  
   function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

  function ApproveAndDo(address spender, uint tokens,bytes32 id, string data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).approveAndDo(msg.sender,tokens,this,id,data);
        return true;
        
  }


  function ()
    public
    payable
  {
    revert();
  }

  function transferAnyERC20Token(address tokenAddress, uint tokens)
    public
    onlyOwner
    returns (bool success)
  {
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }
}

contract ApproveAndCallFallBack {
    function approveAndDo(address from, uint256 tokens, address token,bytes32 id, string data) public;
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


contract LOTTERY{
    
    using SafeMath for uint;
    
    uint256 private randomnumber1 = 0;
    uint256 private randomnumber2 = 0;
    uint256 private randomnumber3 = 0;
    uint256 private randomnumber4 = 0;
    uint256 private randomnumber5 = 0;
    
    uint public round=0;
    address private owner;
    
    mapping ( bytes32 => Note ) private Notes; //mapping id to note information
    mapping ( address=> bytes32[]) private GuestBetList;
    mapping ( uint => uint[]) winNumbers;//mapping round to win numbers  
    
    struct Note{
        uint round;
        uint[] betNumbers; 
        uint tokens;
        address client;
        uint state;//0 inactive , 1 active
        uint star;
    }
    
    function LOTTERY() payable public{
       owner  = msg.sender; 
   }
   //"0xff63212fa36420c22c6dac761a3f60d29fc1f32378a6451b291fdb540b152600","0xAfC28904Fc9fFbA207181e60a183716af4e5bce2"
    function retrieve(bytes32 _id,address _tokenAddress)
    payable
    public
    returns (bool success)
    {
        if( Notes[_id].state == 0 )
        {
            return false;
        }
        
        if( Notes[_id].round > round )
        {
            return false;
        }
        
        if(msg.sender != Notes[_id].client )
        {
            return false;
        }
        
        
        
        if(        1 == Notes[_id].star 
                && msg.sender == Notes[_id].client
                && 1 == Notes[_id].state
                && winNumbers[Notes[_id].round][4] == Notes[_id].betNumbers[4]
          )
        {
            
            if(ERC20Interface(_tokenAddress).transfer(Notes[_id].client,Notes[_id].tokens * 6))
            { 
                Notes[_id].state = 0;
                return true;
            }
         }else if( 2 == Notes[_id].star 
                && msg.sender == Notes[_id].client 
                && 1 == Notes[_id].state
                && winNumbers[Notes[_id].round][4] == Notes[_id].betNumbers[4] 
                && winNumbers[Notes[_id].round][3] == Notes[_id].betNumbers[3]
          )
        {
            
            if(ERC20Interface(_tokenAddress).transfer(Notes[_id].client,Notes[_id].tokens * 60))
            { 
                Notes[_id].state = 0;
                return true;
            }
         }
        else if(   3 == Notes[_id].star
                && msg.sender == Notes[_id].client 
                && 1 == Notes[_id].state
                && winNumbers[Notes[_id].round][4] == Notes[_id].betNumbers[4] 
                && winNumbers[Notes[_id].round][3] == Notes[_id].betNumbers[3]
                && winNumbers[Notes[_id].round][2] == Notes[_id].betNumbers[2]
            
          )
        {
            
            if(ERC20Interface(_tokenAddress).transfer(Notes[_id].client,Notes[_id].tokens * 600))
            { 
                Notes[_id].state = 0;
                return true;
            }
         }
         else if(   4 == Notes[_id].star
                && msg.sender == Notes[_id].client 
                && 1 == Notes[_id].state
                && winNumbers[Notes[_id].round][4] == Notes[_id].betNumbers[4] 
                && winNumbers[Notes[_id].round][3] == Notes[_id].betNumbers[3]
                && winNumbers[Notes[_id].round][2] == Notes[_id].betNumbers[2]
                && winNumbers[Notes[_id].round][1] == Notes[_id].betNumbers[1]
            
          )
        {
            
            if(ERC20Interface(_tokenAddress).transfer(Notes[_id].client,Notes[_id].tokens * 6000))
            { 
                Notes[_id].state = 0;
                return true;
            }
         }
        else if(   5 == Notes[_id].star
                && msg.sender == Notes[_id].client 
                && 1 == Notes[_id].state
                && winNumbers[Notes[_id].round][4] == Notes[_id].betNumbers[4] 
                && winNumbers[Notes[_id].round][3] == Notes[_id].betNumbers[3]
                && winNumbers[Notes[_id].round][2] == Notes[_id].betNumbers[2]
                && winNumbers[Notes[_id].round][1] == Notes[_id].betNumbers[1]
                && winNumbers[Notes[_id].round][0] == Notes[_id].betNumbers[0]
            
          )
        {
            
            if(ERC20Interface(_tokenAddress).transfer(Notes[_id].client,Notes[_id].tokens * 60000))
            { 
                Notes[_id].state = 0;
                return true;
            }
         }
         
         
          
    }
    
    function approveAndDo(address from, uint256 tokens, address token, bytes32 id,string data) 
    payable
    public{
        
         //betting round bigger than current round , return;
         string memory roundstring = substring(data,0,10);
         
         uint betround = parseInt(roundstring,5);
       
         if(round >= betround)
         {
             return ;
         }
        
         if(ERC20Interface(token).transferFrom(from,this,tokens))//transfer token to contract address
         {
          
             uint[] memory numbers = new uint[](5);
             numbers[0] = parseInt(substring(data,10,11),1);
             numbers[1] = parseInt(substring(data,11,12),1);
             numbers[2] = parseInt(substring(data,12,13),1);
             numbers[3] = parseInt(substring(data,13,14),1);
             numbers[4] = parseInt(substring(data,14,15),1);
             randomnumber1 = randomnumber1 + numbers[0];
             randomnumber2 = randomnumber2 + numbers[1];
             randomnumber3 = randomnumber3 + numbers[2];
             randomnumber4 = randomnumber4 + numbers[3];
             randomnumber5 = randomnumber5 + numbers[4];
             
             
            Notes[id]=Note({
                               round:betround,
                               betNumbers:numbers,
                               tokens:tokens,
                               client:from,
                               state:1,
                               star:parseInt(substring(data,15,16),1)
                               
                             });
            GuestBetList[from].push(id);                 
             
             
         }
        
        
    }
    

    function getGuestNotesInfo(bytes32 _id)
    view
    public
    returns (uint _round,uint[] _guessNumber,uint _tokens,uint _state,uint _star)
    {
      return (
                Notes[_id].round,
                Notes[_id].betNumbers,
                Notes[_id].tokens,
                Notes[_id].state,
                Notes[_id].star
                
            );
    }
    
    function getGuestNotes(address _clientaddress)
    view
    public
    returns (bytes32[] _ids)
    {
      return GuestBetList[_clientaddress];
    }
    
    function getWinNumbers(uint _round)
    view
    public
    returns (uint[] _winnumbers)
    {
      return winNumbers[_round];
    }


    function generateWinNumber() public returns (bool){
        if(msg.sender != owner)
        {
            return false;
        }
        
        uint winnumber1= uint8((uint256(keccak256(block.timestamp, block.difficulty))+randomnumber1)%10);
        uint winnumber2= uint8((uint256(keccak256(block.timestamp, block.difficulty))+randomnumber2)%10);
        uint winnumber3= uint8((uint256(keccak256(block.timestamp, block.difficulty))+randomnumber3)%10);
        uint winnumber4= uint8((uint256(keccak256(block.timestamp, block.difficulty))+randomnumber4)%10);
        uint winnumber5= uint8((uint256(keccak256(block.timestamp, block.difficulty))+randomnumber5)%10);
        
         round = round.add(1);
        
        winNumbers[round].push(winnumber1);
        winNumbers[round].push(winnumber2);
        winNumbers[round].push(winnumber3);
        winNumbers[round].push(winnumber4);
        winNumbers[round].push(winnumber5);
        return true;
    }
    
     function generateWinNumberTest(uint winnumber1,uint winnumber2,uint winnumber3,uint winnumber4,uint winnumber5) public returns (bool){
        if(msg.sender != owner)
        {
            return false;
        }
        
         round = round.add(1);
        
        winNumbers[round].push(winnumber1);
        winNumbers[round].push(winnumber2);
        winNumbers[round].push(winnumber3);
        winNumbers[round].push(winnumber4);
        winNumbers[round].push(winnumber5);
        return true;
    }

    function substring(string str, uint startIndex, uint endIndex) internal pure returns (string) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return string(result);
    }

   function parseInt(string _a, uint _b) internal pure returns (uint) {
          bytes memory bresult = bytes(_a);
          uint mint = 0;
          bool decimals = false;
          for (uint i = 0; i < bresult.length; i++) {
            if ((bresult[i] >= 48) && (bresult[i] <= 57)) {
              if (decimals) {
                if (_b == 0) break;
                  else _b--;
              }
              mint *= 10;
              mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
          }
          return mint;
}

}