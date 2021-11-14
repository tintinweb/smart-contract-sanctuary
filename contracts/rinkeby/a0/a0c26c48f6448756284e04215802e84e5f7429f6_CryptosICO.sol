/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

//SPDX-License-Identifier: GPL-3.0 

pragma solidity ^0.8.6;

interface ERC20Interface {
    
    // mandatory
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    // optional
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokwnOwned, address indexed spender, uint tokens);

}

contract Cryptos is ERC20Interface{
    string public name = "Cryptos";
    string public symbol = "CRPT";
    uint public decimals = 0; //18 is most used value for decimals
    uint public override totalSupply; //override creates getter fxn bc variable is public
    
    address public founder;
    
    // this is how contract stores tokens of each address
    mapping(address => uint) public balances;
    // balances[0x1111...] = 100;
    
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() {
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }
    
    // called by owner to transfer own tokens to other account
    function transfer(address to, uint tokens) public virtual override returns(bool success){
        require(balances[msg.sender] >= tokens);
        
        // updates balances of recipient and sender
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }

    // returns how many tokens owner has allowed spender to withdraw
    function allowance(address tokenOwner, address spender) view public override returns(uint){
        return allowed[tokenOwner][spender];
    }
    
    // called by the token owner to set the allowance (amount that can be spent by spender from their account)
    function approve(address spender, uint tokens) public override returns(bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    // allows spender to withdraw from owners account multiple times up to allowance value
    // called on behalf of token owner after owner approved another address to spend tokens in possesion
    function transferFrom(address from, address to, uint tokens) public virtual override returns(bool success){
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);
        
        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][to] -= tokens;
        
        return true;
    }
    
}

contract CryptosICO is Cryptos {
    address public admin;
    // deposit address, where ETH gets sent rather than contract
    // this is safer than storing ETH in contract   
    address payable public deposit;
    uint tokenPrice = 0.001 ether; // 1ETH = 1000 CRPT, 1 CRPT = 0.001 ether
    uint public hardCap = 300 ether;
    uint public raisedAmount; // total raisedAmount
    uint public saleStart = block.timestamp; //starts in 1 hours (seconds)
    uint public saleEnd = block.timestamp + 1200; //ICO ends in 1 weeks
    // prevents early investors from not dumping
    uint public tokenTradeStart = saleEnd + 1200; //20 mins after sale end
    // max and min investment in address
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.1 ether; // use ether suffix otherwise in wei
    
    // State of ICO
    enum State {beforeStart, running, afterEnd, halted}
    State public icoState;
    
    constructor(address payable _deposit){
        deposit = _deposit; // deposit address
        admin = msg.sender;
        icoState = State.beforeStart;
    }
    
    // emergency stop if there is contract vulnerability
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    function halt() public onlyAdmin{
        icoState = State.halted;
    }
    
    function resume() public onlyAdmin{
        icoState = State.running;
    }
    
    function changeDepositAddress(address payable newDeposit) public onlyAdmin {
        deposit = newDeposit;    
    }
    
    // view doesn't alter blockchain
    function getCurrentState() public view returns(State){
        if(icoState == State.halted) {
            return State.halted;
        }else if(block.timestamp < saleStart){
            return State.beforeStart;
        }else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }
    
    event Invest(address invester, uint value, uint tokens);
    
    // main function of ICO 
    function invest() payable public returns(bool){
        // sets ICO state 
        icoState = getCurrentState();
        require(icoState == State.running);
        // msg.value is amount sent to contract
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        raisedAmount += msg.value;
        require(raisedAmount <= hardCap);
        
        uint tokens = msg.value / tokenPrice;
        
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        deposit.transfer(msg.value);
        emit Invest(msg.sender, msg.value, tokens);
        
        return true;
    }
    
    // fxn automatically called when someone sells ETH to contract address
    receive() payable external{
        invest();
    }
    
    // Locking up tokens for a period after ICO ends 
    // "virtual" means function can change behavior in derived contracts by overriding  
    // see transfer and transferFrom in Cryptos contract 
    function transfer(address to, uint tokens) public override returns(bool success){
        require(block.timestamp > tokenTradeStart);
        Cryptos.transfer(to, tokens);
        // can also use "super" which indicates contract from which derived
        //super.transfer(to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public override returns(bool success){
        require(block.timestamp > tokenTradeStart);
        Cryptos.transferFrom(from, to, tokens);
        return true;
    }
    
    // burn tokens 
    function burn() public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        // tokens vanish from owner 
        balances[founder] = 0;
        return true;
        
    }
    
}