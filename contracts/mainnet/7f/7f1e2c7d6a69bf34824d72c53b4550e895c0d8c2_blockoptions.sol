pragma solidity ^ 0.4 .8;


contract ERC20 {

    function totalSupply() constant returns(uint total_Supply);

    function balanceOf(address who) constant returns(uint256);

    function allowance(address owner, address spender) constant returns(uint);

    function transferFrom(address from, address to, uint value) returns(bool ok);

    function approve(address spender, uint value) returns(bool ok);

    function transfer(address to, uint value) returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

}

contract blockoptions is ERC20

{

       /* Public variables of the token */
      //To store name for token
      string public name = "blockoptions";
    
      //To store symbol for token       
      string public symbol = "BOP";
    
      //To store decimal places for token
      uint public decimals = 8;    
    
      //To store current supply of BOP
      uint public _totalSupply=20000000 * 10**decimals;
      
       uint pre_ico_start;
       uint pre_ico_end;
       uint ico_start;
       uint ico_end;
       mapping(uint => address) investor;
       mapping(uint => uint) weireceived;
       mapping(uint => uint) optsSent;
      
        event preico(uint counter,address investors,uint weiReceived,uint bopsent);
        event ico(uint counter,address investors,uint weiReceived,uint bopsent);
        uint counter=0;
        uint profit_sent=0;
        bool stopped = false;
        
      function blockoptions() payable{
          owner = msg.sender;
          balances[owner] = _totalSupply ; //to handle 8 decimal places
          pre_ico_start = now;
          pre_ico_end = pre_ico_start + 7 days;
          
        }
      //map to store BOPT balance corresponding to address
      mapping(address => uint) balances;
    
      //To store spender with allowed amount of BOPT to spend corresponding to BOPTs holder&#39;s account
      mapping (address => mapping (address => uint)) allowed;
    
      //owner variable to store contract owner account
      address public owner;
      
      //modifier to check transaction initiator is only owner
       modifier onlyOwner() {
        if (msg.sender != owner) 
        {
            revert();
        }
        _;
    }
    
      //ownership can be transferred to provided newOwner. Function can only be initiated by contract owner&#39;s account
      function transferOwnership(address newOwner) onlyOwner {
          balances[newOwner] = balances[owner];
          balances[owner]=0;
          owner = newOwner;
      }

        /**
        * Multiplication with safety check
        */
        function Mul(uint a, uint b) internal returns (uint) {
          uint c = a * b;
          //check result should not be other wise until a=0
          assert(a == 0 || c / a == b);
          return c;
        }
    
        /**
        * Division with safety check
        */
        function Div(uint a, uint b) internal returns (uint) {
          //overflow check; b must not be 0
          assert(b > 0);
          uint c = a / b;
          assert(a == b * c + a % b);
          return c;
        }
    
        /**
        * Subtraction with safety check
        */
        function Sub(uint a, uint b) internal returns (uint) {
          //b must be greater that a as we need to store value in unsigned integer
          assert(b <= a);
          return a - b;
        }
    
        /**
        * Addition with safety check
        */
        function Add(uint a, uint b) internal returns (uint) {
          uint c = a + b;
          //result must be greater as a or b can not be negative
          assert(c>=a && c>=b);
          return c;
        }
    
      /**
        * assert used in different Math functions
        */
        function assert(bool assertion) internal {
          if (!assertion) {
            throw;
          }
        }
    
    //Implementation for transferring BOP to provided address 
      function transfer(address _to, uint _value) returns (bool){

        uint check = balances[owner] - _value;
        if(msg.sender == owner && now>=pre_ico_start && now<=pre_ico_end && check < 1900000000000000)
        {
            return false;
        }
        else if(msg.sender ==owner && now>=pre_ico_end && now<=(pre_ico_end + 16 days) && check < 1850000000000000)
        {
            return false;
        }
        else if(msg.sender == owner && check < 130000000000000 && now < ico_start + 180 days)
        {
            return false;
        }
        else if (msg.sender == owner && check < 80000000000000 && now < ico_start + 360 days)
        {
            return false;
        }
        else if (msg.sender == owner && check < 30000000000000 && now < ico_start + 540 days)
        {
            return false;
        }
        //Check provided BOP should not be 0
       else if (_value > 0) {
          //deduct BOP amount from transaction initiator
          balances[msg.sender] = Sub(balances[msg.sender],_value);
          //Add BOP to balace of target account
          balances[_to] = Add(balances[_to],_value);
          //Emit event for transferring BOP
          Transfer(msg.sender, _to, _value);
          return true;
        }
        else{
          return false;
        }
      }
      
      //Transfer initiated by spender 
      function transferFrom(address _from, address _to, uint _value) returns (bool) {
    
        //Check provided BOP should not be 0
        if (_value > 0) {
          //Get amount of BOP for which spender is authorized
          var _allowance = allowed[_from][msg.sender];
          //Add amount of BOP in target account&#39;s balance
          balances[_to] = Add(balances[_to], _value);
          //Deduct BOPT amount from _from account
          balances[_from] = Sub(balances[_from], _value);
          //Deduct Authorized amount for spender
          allowed[_from][msg.sender] = Sub(_allowance, _value);
          //Emit event for Transfer
          Transfer(_from, _to, _value);
          return true;
        }else{
          return false;
        }
      }
      
      //Get BOP balance for provided address
      function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
      }
      
      //Add spender to authorize for spending specified amount of BOP 
      function approve(address _spender, uint _value) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        //Emit event for approval provided to spender
        Approval(msg.sender, _spender, _value);
        return true;
      }
      
      //Get BOP amount that spender can spend from provided owner&#39;s account 
      function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
      }
      
       /*	
       * Failsafe drain
       */
    	function drain() onlyOwner {
    		owner.send(this.balance);
    	}
	
    	function() payable 
    	{   
    	    if(stopped && msg.sender != owner)
    	    revert();
    	     else if(msg.sender == owner)
    	    {
    	        profit_sent = msg.value;
    	    }
    	   else if(now>=pre_ico_start && now<=pre_ico_end)
    	    {
    	        uint check = balances[owner]-((400*msg.value)/10000000000);
    	        if(check >= 1900000000000000)
                pre_ico(msg.sender,msg.value);
    	    }
            else if (now>=ico_start && now<ico_end)
            {
                main_ico(msg.sender,msg.value);
            }
            
        }
       
       function pre_ico(address sender, uint value)private
       {
          counter = counter+1;
	      investor[counter]=sender;
          weireceived[counter]=value;
          optsSent[counter] = (400*value)/10000000000;
          balances[owner]=balances[owner]-optsSent[counter];
          balances[investor[counter]]+=optsSent[counter];
          preico(counter,investor[counter],weireceived[counter],optsSent[counter]);
       }
       
       function  main_ico(address sender, uint value)private
       {
           if(now >= ico_start && now <= (ico_start + 7 days)) //20% discount on BOPT
           {
              counter = counter+1;
    	      investor[counter]=sender;
              weireceived[counter]=value;
              optsSent[counter] = (250*value)/10000000000;
              balances[owner]=balances[owner]-optsSent[counter];
              balances[investor[counter]]+=optsSent[counter];
              ico(counter,investor[counter],weireceived[counter],optsSent[counter]);
           }
           else if (now >= (ico_start + 7 days) && now <= (ico_start + 14 days)) //10% discount on BOPT
           {
              counter = counter+1;
    	      investor[counter]=sender;
              weireceived[counter]=value;
              optsSent[counter] = (220*value)/10000000000;
              balances[owner]=balances[owner]-optsSent[counter];
              balances[investor[counter]]+=optsSent[counter];
              ico(counter,investor[counter],weireceived[counter],optsSent[counter]);
           }
           else if (now >= (ico_start + 14 days) && now <= (ico_start + 31 days)) //no discount on BOPT
           {
              counter = counter+1;
    	      investor[counter]=sender;
              weireceived[counter]=value;
              optsSent[counter] = (200*value)/10000000000;
              balances[owner]=balances[owner]-optsSent[counter];
              balances[investor[counter]]+=optsSent[counter];
              ico(counter,investor[counter],weireceived[counter],optsSent[counter]);
           }
       }
       
       function startICO()onlyOwner
       {
           ico_start = now;
           ico_end=ico_start + 31 days;
           pre_ico_start = 0;
           pre_ico_end = 0;
           
       }
       
        function totalSupply() constant returns(uint256 totalSupply) 
        {
        totalSupply = _totalSupply;
        }
      
        function endICO()onlyOwner
       {
          stopped=true;
          if(balances[owner] > 130000000000000)
          {
              uint burnedTokens = balances[owner]-130000000000000;
           _totalSupply = _totalSupply-burnedTokens;
           balances[owner] = 130000000000000;
          }
       }
}