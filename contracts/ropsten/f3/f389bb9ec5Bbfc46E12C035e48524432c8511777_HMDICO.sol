/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity >=0.5.0 <0.9.9;  

interface ERC20Interface{
    //强制性的功能
    function totalSupply() external view returns(uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns(uint remaning);
    function approve(address spender, uint tokens) external returns(bool success);
    function transferFrom(address from, address to, uint tokens) external returns(bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract HMD is ERC20Interface{
    
    string public name = "Fintech Coin";
    string public symbol = "FIC";
    uint public  decimals = 3;
    uint public override totalSupply;
    
    address public founder; //部署合同的账户 
    
    //持有人余额
    mapping(address => uint)  public balances;
    
    mapping(address => mapping(address => uint)) public allowed;
    
    constructor(){
         totalSupply = 10000000;  //总量
         founder = msg.sender;
         balances[founder] = totalSupply;
    }
    
    /*
     返回该地址的代币持有量的余额
    */
    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }
    
    /*
    将代币从一个账户转移到另一个账户
    */
    function transfer(address to, uint tokens) public virtual override returns (bool success) {
        require(balances[msg.sender] >= tokens,"Not enough tokens");
        
        balances[to] +=  tokens;
        balances[msg.sender] -= tokens;
        
        //保存在区块链中的日志事件
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    
    /*
    - 返回剩余的代币数量 
    */
    function allowance(address tokenOwner, address spender) public view override returns(uint){
        return  allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public override returns(bool success){
        require(balances[msg.sender] > tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        
        return true;
    }
    
    /*
    转移代币
    但这些代币不一定要属于调用合约的人
    */
    function transferFrom(address from, address to, uint tokens) public virtual override returns(bool success){
        require(allowed[from][to] >= tokens);
        require(balances[from] > tokens);
        require(tokens > 0);
        
        balances[from] -= tokens;
        balances[to] += tokens;
        
        allowed[from][to] -= tokens;
        
        return true;
    }
    

}

/*
作为投资者，我想发送ETH到代币的合同地址，并获得HMD代币
作为代币的所有者，我想设置ICO的状态 
作为代币的所有者，我想停止ICO，以防万一 
作为代币的拥有者，我想设置最低和最高投资额度
作为代币的持有者，我想设置已知的募集金额（发送到我钱包的ETH数量）
作为代币的持有者，我想设置销售结束后一周的开始交易日期
*/

contract HMDICO is HMD{
    //ICO的管理员（代币所有者）
    address public admin;
    
    //存款地址，将创建一个新的账户并将其作为存款地址
    address payable public deposit;
    
    uint tokenPrice = 0.001 ether; //1 FIC = 0.001ETH or 1ETH = 1000FIC
    uint public hardCap = 300 ether; //最大金额
    
    uint public raisedAmount; //发送给ICO的ETH总量
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 604800; //ICO在一周内结束
    uint public tokenTradeStart = saleEnd + 604800; //可在销售结束后转让       
    
    uint public maxInvesment = 5 ether;
    uint public minInvesment = 0.1 ether;
    
    enum State {beforeStart, running, afterEnd, halted}
    State public icoState;
    
    constructor(address payable _deposit) {
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"Only admin is able to proceed");
        _;
    }
    //管理员能够停止ico状态
    function halt() public onlyAdmin{
        icoState = State.halted;
    }
    
    //管理员能够恢复ico
    function resume() public onlyAdmin{
        icoState = State.running;
    }
    
    //更改存款地址，以防止其被泄露 
    function changeDepositAddress(address payable _newDeposit) public onlyAdmin{
        deposit = _newDeposit;
    }
    
    function getCurrentState() public view returns(State){
        if (icoState == State.halted){
            return State.halted;
        }else if(block.timestamp < saleStart) {
            return State.beforeStart;
        }else if (block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }
    
    event Invest(address investor, uint value, uint tokens);
    
    /*
    投资者在向合约发送ETH时，会在接收功能中调用它
    从前端（网站）或投资者直接发送时
    */
    function invest() public payable returns(bool){
        require(getCurrentState() == State.running);
        require(msg.value >= minInvesment && msg.value <= maxInvesment);
        raisedAmount += msg.value;
        require(raisedAmount <= hardCap);
        
        uint tokens = msg.value / tokenPrice;
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        deposit.transfer(msg.value);
        
        emit Invest(msg.sender, msg.value, tokens);
        
        return true;
    }
    
    receive() external payable{
        //
        invest();
    }
    
    //防止价格崩溃。
    //作为一个投资者，只有当当前日期大于tokenTradeStart时，你才可以转让
    function transfer(address to, uint tokens) public override returns (bool success) {
        require(block.timestamp > tokenTradeStart);
        super.transfer(to, tokens);
        
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public override returns(bool success){
        require(block.timestamp > tokenTradeStart);
        super.transferFrom(from, to, tokens);
        
        return true;
    }
    
    /*
    销毁在ICO中没有出售的代币 
    */
    function burn() public returns(bool){
        require(getCurrentState() == State.afterEnd);
        
        balances[founder] = 0;
        
        return true;
    }
}