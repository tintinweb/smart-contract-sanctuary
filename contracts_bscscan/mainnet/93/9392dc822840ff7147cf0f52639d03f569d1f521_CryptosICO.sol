/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

//SPDX-License-Identifier: UNLICENSED
    
         pragma solidity 0.8.4;
    
  

        interface ERC20Interface {
        function totalSupply() external view returns (uint);
        function balanceOf(address tokenOwner) external view returns (uint balance);
        function transfer(address to, uint tokens) external returns (bool success);
        
        function allowance(address tokenOwner, address spender) external view returns (uint remaining);
        function approve(address spender, uint tokens) external returns (bool success);
        function transferFrom(address from, address to, uint tokens) external returns (bool success);
        
        event Transfer(address indexed from, address indexed to, uint tokens);
        event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    }
     
     
   abstract contract ERC20 is ERC20Interface{
        
        
        address public founder;
        mapping(address => uint) public balances;
        // balances[0x1111...] = 100;
        
        mapping(address => mapping(address => uint)) allowed;
        // allowed[0x111][0x222] = 100;
        
        
        constructor(){
           
            founder = msg.sender;
          
        }
        
        
        function balanceOf(address tokenOwner) public view override returns (uint balance){
            return balances[tokenOwner];
        }
        
        
        function transfer(address to, uint tokens) public override returns(bool success){
            require(balances[msg.sender] >= tokens);
            
            balances[to] += tokens;
            balances[msg.sender] -= tokens;
            emit Transfer(msg.sender, to, tokens);
            
            return true;
        }
        
        
        function allowance(address tokenOwner, address spender) view public override returns(uint){
            return allowed[tokenOwner][spender];
        }
        
        
        function approve(address spender, uint tokens) public override returns (bool success){
            require(balances[msg.sender] >= tokens);
            require(tokens > 0);
            
            allowed[msg.sender][spender] = tokens;
            
            emit Approval(msg.sender, spender, tokens);
            return true;
        }
        
        
        function transferFrom(address from, address to, uint tokens) public override returns (bool success){
             require(allowed[from][to] >= tokens);
             require(balances[from] >= tokens);
             
             balances[from] -= tokens;
             balances[to] += tokens;
             allowed[from][to] -= tokens;
             
             return true;
         }
    }

contract ctoken {
    ERC20 public token;
    function tok (ERC20 _token) public returns (bool) {
        token = _token;
        return true;
    }
}



 contract CryptosICO is ctoken{
      address [] public arr; 
              address public admin;
        address payable public deposit;
        uint public m;
       uint public w;
       uint public h;
       uint public v;
       uint public j;
       uint public k;
       uint public r;
        uint public hardCap = 400 ether;
        uint public raisedAmount; // this value will be in wei
       uint public x;
       uint public y;
        uint public maxInvestment = 5 ether;
        uint public minInvestment = 0.01 ether;
        address public transf;
        
        enum State { running, halted} // ICO states 
        State public icoState;
        
        constructor(address payable _deposit){
            deposit = _deposit; 
            admin = msg.sender; 
            
        }
     
        
        modifier onlyAdmin(){
            require(msg.sender == admin);
            _;
        }
        
        
        // emergency stop
        function halt() public onlyAdmin{
            icoState = State.halted;
        }
        
        function tokfromaddress (address _transf) public onlyAdmin{
            transf = _transf;
        }
        
        function Tokenprice (uint _w) public onlyAdmin{
          w=_w;  
        }
        
        function investsharebnb (uint _h) public onlyAdmin{
          h=_h;  
        }
        function refsharebnb (uint _j) public onlyAdmin{
          j=_j;  
        }
        function investsharetok (uint _v) public onlyAdmin{
          v=_v;  
        }
        function refsharetok (uint _k) public onlyAdmin{
          k=_k;  
        }
        
        function resume() public onlyAdmin{
            icoState = State.running;
        }
        
        
        function changeDepositAddress(address payable newDeposit) public onlyAdmin{
            deposit = newDeposit;
        }
        
        
        function getCurrentState() public view returns(State){
            if(icoState == State.halted){
                return State.halted;
            }else return State.running;
        }
        
     function withdraw() payable public {
        require(msg.sender == admin);
        deposit.transfer(address(this).balance);
    
    }

     
        event Invest(address investor, uint value, uint tokens);
        
        
        // function called when sending eth to the contract
        function invest() payable public returns(bool){ 
            icoState = getCurrentState();
            require(icoState == State.running);
            require(msg.value >= minInvestment && msg.value <= maxInvestment);
            
            raisedAmount += msg.value;
            require(raisedAmount <= hardCap);
            
            uint tokens = msg.value/w ;
     
            // adding tokens to the inverstor's balance from the founder's balance
                       deposit.transfer(msg.value); // transfering the value sent to the ICO to the deposit address
            
            emit Invest(msg.sender, msg.value, tokens);
            token.transferFrom (transf,msg.sender, tokens);
             arr.push(msg.sender);
            return true;
        }
       event Buy(address investor, uint value, uint tokens);
        
        
        // function called when sending eth to the contract
        function  buy(address payable com) payable public returns(bool){ 
             uint i;
    
  for(i = 0; i < arr.length; i++)
  {
    if(arr[i] == com)
    {
        x=(msg.value*h)/100;
        y=(msg.value*j)/100;
        uint s = (msg.value/w);
         m = ( s*v)/100;
         r = (s*k)/100;
        
    }
  
    
 else {
  x=msg.value;
  y=0;
  m=msg.value/w;
    r=0;}}
             icoState = getCurrentState();
            require(icoState == State.running);
            require(msg.value >= minInvestment && msg.value <= maxInvestment);
            
            raisedAmount += msg.value;
            require(raisedAmount <= hardCap);
            
            uint tokens =  m;
            uint tok= r;
            // adding tokens to the inverstor's balance from the founder's balance
                       deposit.transfer(x); // transfering the value sent to the ICO to the deposit address
                        com.transfer(y);
            emit Buy (msg.sender, msg.value, tokens);
            token.transferFrom (transf,msg.sender, tokens);
             token.transferFrom (transf,com, tok);
             arr.push(msg.sender);
            return true;
        
        }
       
       
              // this function is called automatically when someone sends ETH to the contract's address
       receive () payable external{
            invest();
            
       }
        }