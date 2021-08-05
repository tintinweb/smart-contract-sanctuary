/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

pragma solidity ^0.5.2;


contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Erc20Token is ERC20Interface{
    string public name = "ERC20";
    string public symbol = "ERC20";
    uint public decimals = 0;
    
    uint public supply;
    address public founder;
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    constructor() public{
        supply = 565000;
        founder = msg.sender;
        balances[founder] = supply;
    }
    
    function allowance(address tokenOwner, address spender) view public returns(uint){
        return allowed[tokenOwner][spender];
    }
    
    //Approve allowance
    function approve(address spender, uint tokens) public returns(bool){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    //Transfer tokens from the owner account to the account that calls the function
    function transferFrom(address from, address to, uint tokens) public returns(bool){
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);
        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][to] -= tokens;
        return true;
    }
    
    function totalSupply() public view returns (uint){
        return supply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance){
         return balances[tokenOwner];
    }
     
    function transfer(address to, uint tokens) public returns (bool success){
         require(balances[msg.sender] >= tokens && tokens > 0);
         
         balances[to] += tokens;
         balances[msg.sender] -= tokens;
         emit Transfer(msg.sender, to, tokens);
         return true;
    }
}

contract Erc20Trade is Erc20Token{
    address public admin;
    address payable public deposit;
    
    uint tokenPrice = 220000000000000;
    
    uint public hardCap = 100000000000000000000;
    uint public raisedAmount;
    uint public saleStart = now;
    uint public saleEnd = now + 10080 minutes; // 1 Week
    //Non-Transferable
    uint public coinTradeStart = now + 365 days;
    uint public maxInvestment = 500000000000000000; // 0,5 ETH
    uint public minInvestment = 100000000000000000; // 0.1 ETH
    
    enum State { beforeStart, running, afterEnd, halted}
    State public tradeState;
    
    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
    
    event Invest(address investor, uint value, uint tokens);

    constructor(address payable _deposit) public{
        deposit = _deposit;
        admin = msg.sender;
        tradeState = State.beforeStart;
    }
    
    //Emergency stop of trade
    function halt() public onlyAdmin{
        tradeState = State.halted;
    }
    
    //Restart trade
    function unhalt() public onlyAdmin{
        tradeState = State.running;
    }
    
    //Only the admin can change the deposit address
    function changeDepositAddress(address payable newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }
    
    //Returns trade state
    function getCurrentState() public view returns(State){
        if(tradeState == State.halted){
            return State.halted;
        }else if(block.timestamp < saleStart){
            return State.beforeStart;
        }else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }
    
    function invest() payable public returns(bool){
        //Invest only in Running
        tradeState = getCurrentState();
        require(tradeState == State.running);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        uint tokens = msg.value / tokenPrice;
        //HardCap not reached
        require(raisedAmount + msg.value <= hardCap);
        raisedAmount += msg.value;
        //Add tokens to investor balance from trader balance
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        //Transfer eth to the deposit address
        deposit.transfer(msg.value);
        //emit event
        emit Invest(msg.sender, msg.value, tokens);
        return true;
    }
    
    function () payable external{
        invest();
    }
    
    function mintTeamBalance() public onlyAdmin returns(bool){
        tradeState = getCurrentState();
        require(tradeState == State.afterEnd);
        balances[founder] = 50000;
    }
    
    function transfer(address to, uint value) public returns(bool){
        require(block.timestamp > coinTradeStart);
        super.transfer(to, value);
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns(bool){
        require(block.timestamp > coinTradeStart);
        super.transferFrom(_from, _to, _value);
    }
    
}