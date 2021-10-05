/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------
 
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
 
 
contract FLOWtoken is ERC20Interface{
    string public name = "flowTOKEN";
    string public symbol = "FLCY";
    uint public decimals = 4;
    uint public override totalSupply; //override keyword is neccessary since totalSupply is already a function, creates getter function
    
    address public founder; //address that deploys contract and has all tokens in the first place
    mapping(address => uint) public balances; //storing the number of tokens of each address
  
    
    mapping(address => mapping(address => uint)) allowed;
    
    
    
    constructor(){
        totalSupply = 10000000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }
    
    
    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }
    
    
    function transfer(address to, uint tokens) public virtual override returns(bool success){
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
    
    
    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success){
         require(allowed[from][to] >= tokens);
         require(balances[from] >= tokens);
         
         balances[from] -= tokens;
         balances[to] += tokens;
         allowed[from][to] -= tokens;
         
         return true;
     }
}



contract FlowICO is FLOWtoken {
    address public admin;
    address payable public deposit;
    uint tokenPrice = 0.0001 ether; 
    uint public hardCap = 1000 ether;
    uint public raisedAmount;
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 604800; // ICO ends in a week
    uint public tokenTradeStart = saleEnd + 604800; //starts trading after a week so early investors can't dump
    uint public maxInvestment = 25 ether;
    uint public minInvestment = 0.001 ether;
    
    enum State {beforeStart, running, afterEnd, halted}
    State public icoState;
    
     constructor(address payable _deposit){
        deposit = _deposit; 
        admin = msg.sender; 
        icoState = State.beforeStart;
    }

    
    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
    
    
    // emergency stop
    function halt() public onlyAdmin{
        icoState = State.halted;
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
        }else if(block.timestamp < saleStart){
            return State.beforeStart;
        }else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }


    event Invest(address investor, uint value, uint tokens);
    
    
    // function called when sending eth to the contract
    function invest() payable public returns(bool){ 
        icoState = getCurrentState();
        require(icoState == State.running);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        
        raisedAmount += msg.value;
        require(raisedAmount <= hardCap);
        
        uint tokens = msg.value / tokenPrice;

        // adding tokens to the inverstor's balance from the founder's balance
        balances[msg.sender] += tokens;
        balances[founder] -= tokens; 
        deposit.transfer(msg.value); // transfering the value sent to the ICO to the deposit address
        
        emit Invest(msg.sender, msg.value, tokens);
        
        return true;
    }
   
   
   // this function is called automatically when someone sends ETH to the contract's address
   receive () payable external{
        invest();
    }
    
     function transfer(address to, uint tokens) public override returns(bool success){
         require(block.timestamp > tokenTradeStart);
         super.transfer(to, tokens);
         return true;
     }
     
     function transferFrom(address from, address to, uint tokens) public override returns (bool success){
         require(block.timestamp > tokenTradeStart);
         super.transferFrom(from, to, tokens);
         return true;
     }
     
     function burn() public returns(bool){
         icoState = getCurrentState();
         require(icoState == State.afterEnd); 
         balances[founder] = 0; //burns all the remaining tokens that haven't sold from the founders balance, may want to change this
         return true; // it's a public function so anyone can call it to ensure the founder doesn't change their mind
     }
}