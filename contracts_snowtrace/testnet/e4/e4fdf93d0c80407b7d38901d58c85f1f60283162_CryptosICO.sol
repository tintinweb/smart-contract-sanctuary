/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT

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

contract Cryptos is ERC20Interface {
    string public name = "FChain";
    string public symbol = "FTC";
    uint public decimals = 0;
    uint public override totalSupply;
    bool public pausedState = false;

    address public owner;
    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) public isBlackListed;


    constructor() {
        totalSupply = 1000000;
        owner = msg.sender;
        balances[owner] = totalSupply;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public virtual override returns(bool success) {
        require(!pausedState, "All transactions paused");
        require(!isBlackListed[msg.sender] && !isBlackListed[to], "This address is blacklisted");
        require(balances[msg.sender] >= tokens);

        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);

        return true;

    }

    function allowance(address tokenOwner, address spender) view public override returns(uint) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public override returns(bool success) {
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success) {
        require(!pausedState, "All transactions paused");
        require(!isBlackListed[from] && !isBlackListed[to], "This address is blacklisted");
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);
        
        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][to] -= tokens;

        return true;
    }

    function addToBlackList(address addresses) public onlyOwner {
        isBlackListed[addresses] = true;
    }

    function removeFromBlackList(address account) external onlyOwner {
        isBlackListed[account] = false;
    }

    function paused() public onlyOwner {
        pausedState = true;
    }

    function removePaused() public onlyOwner {
        pausedState = false;
    }



}

contract CryptosICO is Cryptos{
    address public admin;
    address payable public deposit;
    uint tokenPrice = 0.001 ether; 
    uint public hardCap = 300 ether;
    uint public raisedAmount; 
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 604800; 
    
    uint public tokenTradeStart = saleEnd + 604800;
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.1 ether;
    
    enum State { beforeStart, running, afterEnd, halted} 
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
        
    function halt() public onlyAdmin{
        icoState = State.halted;
    }
    
    
    function resume() public onlyAdmin{
        icoState = State.running;
    }
    
    
    function changeDepositAddress(address payable newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }
    
    
    function getCurrentState() public view returns(State) {
        if(icoState == State.halted){
            return State.halted;
        }else if(block.timestamp < saleStart) {
            return State.beforeStart;
        }else if(block.timestamp >= saleStart && block.timestamp <= saleEnd) {
            return State.running;
        }else {
            return State.afterEnd;
        }
    }


    event Invest(address investor, uint value, uint tokens);
    
    function invest() payable public returns(bool){ 
        icoState = getCurrentState();
        require(icoState == State.running);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        
        raisedAmount += msg.value;
        require(raisedAmount <= hardCap);
        
        uint tokens = msg.value / tokenPrice;

        balances[msg.sender] += tokens;
        balances[owner] -= tokens; 
        deposit.transfer(msg.value); 
        
        emit Invest(msg.sender, msg.value, tokens);
        
        return true;
    }
   
   
   receive () payable external{
        invest();
    }

    function transfer(address to, uint tokens) public override returns(bool success) {
        require(block.timestamp > tokenTradeStart);
        Cryptos.transfer(to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        require(block.timestamp > tokenTradeStart);
        Cryptos.transferFrom(from, to, tokens);
        return true;
    }

    function burn() public returns(bool) {
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[owner] = 0;
        return true;
    }  
}