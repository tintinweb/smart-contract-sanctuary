//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

import "./MyCoinInterface.sol"; 

contract EkremCoin is EkremInterface{
    string public name = "Ekrem";
    string public symbol = "EKRM";
    uint public decimals = 0;
    uint public override totalSupply;
    
    address public founder;
    mapping(address => uint) public balances;
    mapping(address => bool) public black_lists;
    // balances[0x1111...] = 100;
    
    mapping(address => mapping(address => uint)) allowed;
    // allowed[0x111][0x222] = 100;

    enum State { beforeStart, running, afterEnd, halted} // action states 
    State public action_state;
    
    
    constructor(){
        totalSupply = 100000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
        action_state = State.running;
    }

    modifier onlyAdmin(){
        require(msg.sender == founder);
        _;
    }

    function halt() public virtual onlyAdmin{
        action_state = State.halted;
    }
    
    function resume() public virtual onlyAdmin{
        action_state = State.running;
    }

    function addToBlackList(address[] calldata addresses) external onlyAdmin {
      for (uint256 i; i < addresses.length; ++i) {
        black_lists[addresses[i]] = true;
      }
    }


    function removeFromBlackList(address remove_address) public onlyAdmin{
        black_lists[remove_address] = false;
    }

    function getCurrentState() public view virtual returns(State){
        if(action_state == State.halted){
            return State.halted;}
       else{
            return State.running;
        }
    }
    
    
    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }
    
    
    function transfer(address to, uint tokens) public virtual override returns(bool success){
        action_state = getCurrentState();
        require(action_state == State.running);
        require(balances[msg.sender] >= tokens);
        require(!black_lists[msg.sender] && !black_lists[to]);
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    
    
    function allowance(address tokenOwner, address spender) public view override returns(uint){
        require(!black_lists[tokenOwner] && !black_lists[spender]);
        return allowed[tokenOwner][spender];
    }
    
    
    function approve(address spender, uint tokens) public override returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        require(!black_lists[msg.sender] && !black_lists[spender]);
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    
    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success){
         require(allowed[from][to] >= tokens);
         require(balances[from] >= tokens);
         require(!black_lists[from] && !black_lists[to]);

         balances[from] -= tokens;
         balances[to] += tokens;
         allowed[from][to] -= tokens;
         
         return true;
     }
}