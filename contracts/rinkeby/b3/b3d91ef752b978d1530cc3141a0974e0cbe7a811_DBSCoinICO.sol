/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract DBSCoin {
    using SafeMath for uint256;
    
    address public founder;
    
    string public name = "DBSCoin";
    string public symbol = "DBS";
    uint public decimals = 18;
    uint public totalSupply = 1000000 * (uint256(10) ** decimals);
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    event Transfer(address indexed from, address indexed to,  uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender,  uint tokens);

    constructor() {
        founder = msg.sender;
        balances[founder] = totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

contract DBSCoinICO is DBSCoin {
    using SafeMath for uint256;
    
    address public admin;
    address payable public deposit;
    uint tokenPrice = 0.001 ether;  // 1 ETH = 1000 DBS, 1 DBS = 0.001 ETH
    uint public hardCap = 300 ether;
    uint public raisedAmount; // this value will be in wei
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 604800; //one week
    
    uint public tokenTradeStart = saleEnd + 604800; //transferable in a week after saleEnd
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.1 ether;
    
    enum State { beforeStart, running, afterEnd, halted} // ICO states 
    State public icoState;
    
    event Invest(address investor, uint value, uint tokens);
    
    constructor(address payable _deposit) {
        deposit = _deposit; 
        admin = msg.sender; 
        icoState = State.beforeStart;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin); 
        _;
    }

    function halt() public onlyAdmin {
        icoState = State.halted;
    }

    function resume() public onlyAdmin {
        icoState = State.running;
    }

    function changeDepositAddress(address payable newDeposit) public onlyAdmin {
        deposit = newDeposit;
    }

    function getCurrentState() public view returns(State) {
        if(icoState == State.halted) {
            return State.halted;
        } else if(block.timestamp < saleStart) {
            return State.beforeStart;
        } else if(block.timestamp >= saleStart && block.timestamp <= saleEnd) {
            return State.running;
        } else {
            return State.afterEnd;
        }
    }

    // function called when sending eth to the contract
    function invest() payable public returns(bool) { 
        icoState = getCurrentState();
        require(icoState == State.running);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        
        raisedAmount = raisedAmount.add(msg.value);
        require(raisedAmount <= hardCap);
        uint tokens = msg.value.div(tokenPrice).mul((uint256(10) ** decimals));

        // adding tokens to the inverstor's balance from the founder's balance
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[founder] = balances[founder].sub(tokens);
        deposit.transfer(msg.value); // transfering the value sent to the ICO to the deposit address
        
        emit Invest(msg.sender, msg.value, tokens);
        return true;
    }
    
    // this function is called automatically when someone sends ETH to the contract's address
    receive () payable external {
        invest();
    }

    // burning unsold tokens
    function burn() public returns(bool) {
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
    }
}

/* ************** SafeMath ************** */
library SafeMath {
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) { return 0; }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}