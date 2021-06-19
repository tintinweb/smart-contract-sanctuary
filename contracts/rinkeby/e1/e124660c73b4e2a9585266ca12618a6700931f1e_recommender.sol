/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

pragma solidity ^0.4.17 ~ 0.4.24;




// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}









//------------------------------------------------------------token contract-------------------------------------------------------------------------------
//------------------------------------------------------------credit_mine-------------------------------------------------------------------------------


contract Credit_token is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "CT";
        name = "Credit_token";
        decimals = 18;
        _totalSupply = 1000000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

contract recommender{
    using SafeMath for uint; 
    
    
    Credit_token CT = Credit_token(0xE1Aa89C39bC8fB30613D5ae30cD977b8eB88BE53);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    
    
    address owner;
    
    mapping(address=>address)public my_recommender;
    mapping(uint=>mapping(uint=>uint))public rule_info;
    mapping(address=>mapping(uint=>uint))public rt_info; 
    // 1.rt1_no 2.rt2_no 3.rt3_no 4.my_LV 5.performance 6.bouns 7.already_claim
    mapping(address=>bool)public authorize;
    


    
    constructor()public {
        owner = msg.sender;
        rt_info[msg.sender][4] = 3;
        my_recommender[msg.sender] = address(this);
        
        rule_info[0][1] = 1*10**17;         //推薦人金額
        rule_info[0][2] = 200*10**18;       //推薦人條件(CT)
        
        rule_info[1][1] = 10*10**18;        //LV2業績
        rule_info[1][2] = 20*10**18;        //LV3業績
         
    }
    
    
    // 推薦資格
    // 1. 必須有推薦人令牌
    // 2. 推薦人必須要有推薦人
    // 3. 初始推薦人必須為0x0
    // 3. 不能輸入自己
    
    function set_recommender(address rt ,address user)public {
        require(rt_info[rt][4]>0); 
        require(my_recommender[rt] != address(0x0));
        require(my_recommender[user] == address(0x0));
        require(user != rt);
  
        my_recommender[user]=rt;
        set_rt_numbrt(user);
    }
    
    
    
    function set_rt_numbrt(address user)private{
        
        address rt = user;
        
        for(uint i=1; i<=3; i++){
            rt = my_recommender[rt];
            rt_info[rt][i] = rt_info[rt][i].add(1);
        }
    }
   
    
    
    
    function level_up()public payable{
       require(CT.balanceOf(msg.sender) >= rule_info[0][2]);    
       require(msg.value >= rule_info[0][1]); //成為推薦人必須先投入ETH枚數
       require(my_recommender[msg.sender] != address(0x0)); //成為推薦人必須先有推薦人
       rt_info[msg.sender][4] = 1;
       
       uint performance = rt_info[msg.sender][5];
       
           
       if(performance>=rule_info[1][1] && rt_info[msg.sender][4]==1){
           rt_info[msg.sender][4] = 2;
       }
       
       if(performance >= rule_info[1][2] && rt_info[msg.sender][4]==2){
           rt_info[msg.sender][4] = 3;
       }
       
       owner.transfer(msg.value);
    }
    
    
    
    
    function set_performance(address user, uint score)public {
        require(authorize[msg.sender] == true);
        rt_info[user][5] = rt_info[user][5].add(score);
        rt_info[user][6] = rt_info[user][6].add(score);
    }
    
    
    function input()public payable {
       require(authorize[msg.sender] == true);
    }
    
    
    function claim_bonus()public {
        msg.sender.transfer(rt_info[msg.sender][6]);
        rt_info[msg.sender][7] = rt_info[msg.sender][7].add(rt_info[msg.sender][6]);
        rt_info[msg.sender][6] = 0;
    }
   
    
    
    
    
    function get_recommender(address user)public view returns(address){
        return my_recommender[user];
    }
    
    
    function get_level(address user)public view returns(uint){
        return  rt_info[user][4];
    }
    
    
    function get_CT_balance(address user)public view returns(uint){
        return  CT.balanceOf(user);
    }
    
    
    function withdraw(uint eth_amount)public onlyOwner{
        owner.transfer(eth_amount);
    }
    
    
    
    
    //------------------ctrl_parameter----------------------------
    
    
    function set_parameter(uint p1, uint p2, uint p3)public onlyOwner{
        rule_info[p1][p2] = p3;
    }
    
    
    function get_parameter(uint p1, uint p2)public view returns(uint){
        return rule_info[p1][p2];
    }
   
    
    
    //------------------authorize----------------------------
    
    
    function authorization(address user,bool status )public onlyOwner{
        authorize[user] = status;
    }
    
    function get_authorization(address user)public view returns(bool){
        return authorize[user];
    }
    
    
    
    
}