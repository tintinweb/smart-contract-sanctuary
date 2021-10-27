/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

pragma solidity >=0.5.0;
interface ERC20Interface{
    function totalsupply() external view returns(uint);
    function balanceOf(address tokenOwner) external view returns(uint value);
    function transfer(address to, uint tokens) external returns(bool success);
    
    function allowance(address tokenOwner,address spender) external view returns(uint remaining);//getter function for state variable mapping allowed;
    function approve(address spender,uint tokens) external returns(bool success);//setter function to mapping allowed 
    function transferFrom(address from,address to,uint tokens) external returns(bool success);//function to transfer token from _from to _to and updating balances
    
    event Transfer(address indexed from,address indexed to,uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender,uint tokens);
}
contract Cryptos is ERC20Interface{
    string public name="crypto";
    string public symbol="CRYPT";
    uint public decimals=0;
    uint public override totalsupply;
    
    mapping(address=>mapping(address=>uint)) allowed;
    
    address public founder;
    mapping(address=>uint) public balances;
    constructor(){
        totalsupply = 1000000;
        founder = msg.sender;
        balances[founder]=totalsupply;
    }
    function balanceOf(address tokenOwner) public view override returns(uint value){
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public virtual override returns(bool success){
        require(balances[msg.sender]>=tokens,"Not having enough balance");
        
        balances[to]+=tokens;
        balances[msg.sender]-=tokens;
        emit Transfer(msg.sender,to,tokens);
        
        return true;
    }
     function allowance(address tokenOwner,address spender) public view override returns(uint remaining){
         return allowed[tokenOwner][spender];
         
     }
      function approve(address spender,uint tokens)public override returns(bool success){
          require(balances[msg.sender]>=tokens,"Notmuch token");
          require(tokens>0);
          allowed[msg.sender][spender]=tokens;
          emit Approval(msg.sender,spender,tokens);
          return true;
      }
      function transferFrom(address from,address to,uint tokens) public virtual override returns(bool success){
          require(allowed[from][to]>=tokens);
          require(balances[from]>=tokens);
          balances[from]-=tokens;
          balances[to]+=tokens;
          allowed[from][to]-=tokens;
          return true;
      }
      
      
}