pragma solidity 0.8.10;

import "./SerhiiLCoin.sol";

contract SerhiiLCoin_ICO is SerhiiLCoin {

    address public admin;
    address payable public deposit;

    uint tokenPrice = 0.001 ether;  // 1 ETH = 1000 CRTP, 1 CRPT = 0.001
    uint public hardCap = 300 ether;
    uint public raisedAmount; // this value will be in wei
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 604800; //one week

    uint public tokenTradeStart = saleEnd + 604800; //transferable in a week after saleEnd
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.1 ether;

    // ICO states
    enum State {
        beforeStart,
        running,
        afterEnd,
        halted
    }

    State public icoState;

    constructor(){
        admin = msg.sender;
        deposit = payable(msg.sender);
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

    // burning unsold tokens
    function burn() public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
    }

    function transfer(address to, uint tokens) public override returns (bool success){
        require(block.timestamp > tokenTradeStart); // the token will be transferable only after tokenTradeStart
        super.transfer(to, tokens);
        return true;
    }


    function transferFrom(address from, address to, uint tokens) public override returns (bool success){
        require(block.timestamp > tokenTradeStart); // the token will be transferable only after tokenTradeStart
        super.transferFrom(from, to, tokens);
        return true;
    }

}

pragma solidity 0.8.10;

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

contract SerhiiLCoin is ERC20Interface{

    string  public name = "Serhii L Token";
    string  public symbol = "SLC";
    uint8   public decimals = 18;
    uint256 public override totalSupply;

    address public founder;
    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) allowed;

    constructor(){
        totalSupply = 1000000000000000000000000; // 1 million tokens
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