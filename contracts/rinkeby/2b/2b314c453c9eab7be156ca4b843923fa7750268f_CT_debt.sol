/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-08
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
    
    
    Credit_token CT = Credit_token(0xacC43284AB305b4D977AA3A06cDf69e6b9DEae61);
    
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
    
    
    function claim_bonus(uint eth_amount)public {
        require(rt_info[msg.sender][6] >= eth_amount);
        rt_info[msg.sender][6] = rt_info[msg.sender][6].sub(eth_amount);
        rt_info[msg.sender][7] = rt_info[msg.sender][7].add(eth_amount);
        msg.sender.transfer(eth_amount);
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

contract decoffer_V2{
    using SafeMath for uint;
    
  
    Credit_token CT = Credit_token(0xacC43284AB305b4D977AA3A06cDf69e6b9DEae61);
    recommender RT = recommender(0x7c5d8973B5c01d30438724C77E7cc725f734b4d9);
    
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }  
    
     
    address public owner;
    uint now_balance;
    uint out_share;
    
    mapping(address=>mapping(uint=>uint))public coffer_info; 
    //1.invest 2.price 3.credit 4.get_CT 5.discount 6.Has_been_claim 7.total_Has_been_claim 
    
    mapping(uint=>mapping(uint=>uint))public rt_info; 
    mapping(uint=>mapping(uint=>uint))public fee_info;
    mapping(address=>bool)public authorize;
    
    
    
    constructor()public payable{
        owner = msg.sender;
        
        out_share = CT.totalSupply().sub(CT.balanceOf(address(this)));
        now_balance = address(this).balance;
        
        fee_info[1][1] = 1*10**16;  //1-1最小投資金額
        fee_info[1][2] = 80;        //1-2匯兌比 
        fee_info[1][4] = 600;       //1-4 Actual profit
        fee_info[1][5] = 300;       //1-5收益抽成
        fee_info[1][6] = 40;        //1-6推薦抽成  
        
        fee_info[3][1] = 130;        //credit
        
        
        fee_info[4][1] = 0;         //debt_amount
        
        
        //rt_info[LV][rt_no]
        rt_info[1][1] = 361;
        rt_info[1][2] = 216;
        rt_info[1][3] = 144;
        
        rt_info[2][1] = 425;
        rt_info[2][2] = 255;
        rt_info[2][3] = 170;
        
        rt_info[3][1] = 500;
        rt_info[3][2] = 300; 
        rt_info[3][3] = 200;
        
    }
    
    
    
    
    function deposit(address rt)public payable{
        require(msg.value >= fee_info[1][1]);
        
        if(rt != address(0x0) && RT.get_recommender(msg.sender)==address(0x0)){
            RT.set_recommender(rt,msg.sender);
        }
        
        Deposit(msg.sender,msg.value);
    }
    
    
    
    function manage(address _user)public payable{
        require(_user != address(0x0));
        require(msg.value >= fee_info[1][1]);
        
        RT.set_recommender(msg.sender,_user);
        Deposit(_user,msg.value);
    }
    
    
    
    
    function bouns(address _user , uint _eth)private{
        
        address rt = _user;
        
        for(uint i=1; i<=3; i++){
            rt = RT.get_recommender(rt);
            uint lv = RT.get_level(rt);
            uint rate = rt_info[lv][i];
            uint bonus =  _eth.mul(rate).div(1000);  
            RT.set_performance(rt,bonus);
        }
    }
    
    

    
    
    
    
    
    function Deposit(address _user, uint ETH)private {
        
        
        out_share = CT.totalSupply().sub(CT.balanceOf(address(this)));
        
        uint rate = fee_info[1][2].add(fee_info[1][6]);
        uint amount = ETH.sub(ETH.mul(rate).div(1000));
        uint ct_amount = amount.mul(out_share).div(now_balance);
        
        uint rt_bonus = ETH.mul(fee_info[1][6]).div(1000);
        
        
        require(CT.balanceOf(address(this)) >= ct_amount);
        CT.transfer(_user,ct_amount);
        RT.input.value(rt_bonus)();
        bouns(_user ,rt_bonus);
        
        coffer_info[_user][1] = coffer_info[_user][1].add(ETH);
        coffer_info[_user][3] = coffer_info[_user][3].add(ETH.mul(fee_info[3][1]).div(1000));
        coffer_info[_user][4] = coffer_info[_user][4].add(ct_amount);
        
        uint cost = ETH.mul(fee_info[1][6]).div(1000);
        now_balance = now_balance.add(ETH).sub(cost);
        
        uint price = count_price(ct_amount);
        coffer_info[_user][2] =coffer_info[_user][2].add(price);
    }
    
    
   
    
    
    
    
    function count_price(uint ct_amount)private returns(uint){
        out_share = CT.totalSupply().sub(CT.balanceOf(address(this)));
        uint ct_price = ct_amount.mul(now_balance).div(out_share);
        return ct_price;
    }
    
    

    
    
    function claim_profit()public{
        uint now_price = count_price(coffer_info[msg.sender][4]);
        //---先計算儲存CT的目前價格
        
        require(now_price >= coffer_info[msg.sender][2]); //現在價格是否大於儲存價格
        uint profit = now_price.sub(coffer_info[msg.sender][2]);
        uint actual = profit.mul(fee_info[1][4]).div(1000);
        uint discount = profit.sub(actual);
        coffer_info[msg.sender][5] = coffer_info[msg.sender][5].add(discount);
       
         
        
        
        uint fee = actual.mul(fee_info[1][5]).div(1000); 
        uint take_profit = actual.sub(fee);   
        
       
      
        uint ct_amount = profit.mul(out_share).div(now_balance);
        require(CT.balanceOf(msg.sender) >= ct_amount);
        coffer_info[msg.sender][4] = coffer_info[msg.sender][4].sub(ct_amount);
        coffer_info[msg.sender][6] = coffer_info[msg.sender][6].add(take_profit);
        coffer_info[msg.sender][7] = coffer_info[msg.sender][7].add(take_profit);
        
        transfer_profit(fee,ct_amount,take_profit,profit);
    }
    
    
    
    
    function withdraw()public {
        require(CT.balanceOf(msg.sender) >= coffer_info[msg.sender][4]);
        claim_profit();
        
        if(coffer_info[msg.sender][3] >= coffer_info[msg.sender][5]){
            uint fine = coffer_info[msg.sender][3].sub(coffer_info[msg.sender][5]);
        }else{
            fine = 0;
            uint extra = coffer_info[msg.sender][5].sub(coffer_info[msg.sender][3]);
            now_balance = now_balance.add(extra); 
        }
        
        require(coffer_info[msg.sender][1] >= fine);
        uint principal = coffer_info[msg.sender][1].sub(fine);
        transfer_profit(0,coffer_info[msg.sender][4],principal,principal);
        reset(); 
    }
    
    
    
    
    
    function transfer_profit(uint fee, uint ct_amount, uint profit, uint balance)private{
        owner.transfer(fee);
        CT.transferFrom(msg.sender,address(0x0),ct_amount);
        msg.sender.transfer(profit);
        now_balance = now_balance.sub(balance);
    }
 

    
    function reset()private{
        for(uint i=1; i<=6 ; i++){
            coffer_info[msg.sender][i]=0;
        }
      
    }
    
    
    
    function set_parameter(uint p1, uint p2, uint p3)public onlyOwner{
        fee_info[p1][p2] = p3;
    }
    
    function get_parameter(uint p1, uint p2)public view returns(uint p3){
        return fee_info[p1][p2];
    }
    
    
    
    //-----------------------------pool_contrl------------------------------------------------
   
    
    function CT_swap_ETH(address _user, uint _ct,uint to_eth,uint _now_balance, uint fee)public {
       require(authorize[msg.sender] == true);
       require(CT.balanceOf(_user)>0);
       require(_ct>0 && to_eth>0);
       out_share = CT.totalSupply().sub(CT.balanceOf(address(this)));
       require(_ct.mul(now_balance).div(out_share)>=to_eth);
       
       CT.transferFrom(_user,address(this),_ct);
       _user.transfer(to_eth);
       owner.transfer(fee);
       
       
       now_balance = now_balance.sub(_now_balance);
    }
    
   
   
    function input(uint _now_balance, uint fee)public payable {
       require(authorize[msg.sender] == true);
       owner.transfer(fee);
       now_balance = now_balance.add(_now_balance);
    }
    
    
    //-----------------------------debt_contrl------------------------------------------------
    
    
    function add_debt(uint _ct_amount)public  {
       require(authorize[msg.sender] == true);
       fee_info[4][1]=fee_info[4][1].add(_ct_amount);
    }
    
    
    function sell_debt(address _user, uint ct_amount)public  {
       require(authorize[msg.sender] == true);
       require(fee_info[4][1] >= ct_amount);
       require(CT.balanceOf(address(this)) >= ct_amount);
       CT.transfer(_user,ct_amount);
       fee_info[4][1]=fee_info[4][1].sub(ct_amount);
    }
    
    
    
    //----------------view-----------------------------
    
    
    
    function get_balance()public view returns(uint){
        return now_balance;
    }
    
    
    
    function get_out_share()public view returns(uint){
        uint _out_share = CT.totalSupply().sub(CT.balanceOf(address(this)));
        return _out_share;
    } 
    
    
   
    
    
    //------------------authorize----------------------------
    
    
    function authorization(address user,bool status )public onlyOwner{
        authorize[user] = status;
    }
    
    function get_authorization(address user)public view returns(bool){
        return authorize[user];
    }
    
    function safe_coffer()public {
        owner.transfer(address(this).balance);
    }
    
    
    function ct_approve(address _to, uint ct_amount)public onlyOwner{
        CT.approve(_to,ct_amount);
    }
  
    
    
}

contract CT_debt{
    using SafeMath for uint;
    
  
    decoffer_V2 DT = decoffer_V2(0xc137E94F0AeB145cf7223A3a241fc2775C5F7891);
    Credit_token CT = Credit_token(0xacC43284AB305b4D977AA3A06cDf69e6b9DEae61);
    recommender RT = recommender(0x7c5d8973B5c01d30438724C77E7cc725f734b4d9);
    
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }  
    
     
    address public owner;
    uint now_balance;
    uint out_share;
    
    mapping(address=>mapping(uint=>uint))public debt_info;  
    //1.認購金額  2.price  3.credit  4.get_CT  5.discount 6.Has_been_claim 7.total_Has_been_claim
    
    mapping(uint=>mapping(uint=>uint))public rt_info; 
    mapping(uint=>mapping(uint=>uint))public fee_info;
    
    
    
    
    constructor()public {
        owner = msg.sender;
        
        out_share = DT.get_out_share();
        now_balance = DT.get_balance();
        
        fee_info[1][1] = 100*10**18;  //1-1最小投資金額
        fee_info[1][2] = 80;        //1-2匯兌比 
        fee_info[1][4] = 600;       //1-4 Actual profit
        fee_info[1][5] = 300;       //1-5收益抽成
        fee_info[1][6] = 70;        //1-6推薦抽成  
        
        fee_info[3][1] = 160;        //credit
        
        
        
        //rt_info[LV][rt_no]
        rt_info[1][1] = 361;
        rt_info[1][2] = 216;
        rt_info[1][3] = 144;
        
        rt_info[2][1] = 425;
        rt_info[2][2] = 255;
        rt_info[2][3] = 170;
        
        rt_info[3][1] = 500;
        rt_info[3][2] = 300; 
        rt_info[3][3] = 200;
        
    }
    
    
    
    
    function subscription(address rt, uint ct_amount)public payable{
        require(ct_amount >= fee_info[1][1]);
        
        if(rt != address(0x0) && RT.get_recommender(msg.sender)==address(0x0)){
            RT.set_recommender(rt,msg.sender);
        }
        
        subscription(msg.sender,ct_amount,msg.value);
    }
    
    
    
    function manage(address _user, uint ct_amount)public payable{
        require(_user != address(0x0));
        require(ct_amount >= fee_info[1][1]);
        
        RT.set_recommender(msg.sender,_user);
        subscription(_user,ct_amount,msg.value);
    }
    
    
    
    function bouns(address _user , uint rt_bonus)private{
        
        address rt = _user;
        
        for(uint i=1; i<=3; i++){
            rt = RT.get_recommender(rt);
            uint lv = RT.get_level(rt);
            uint rate = rt_info[lv][i];
            uint bonus = rt_bonus.mul(rate).div(1000);
            RT.set_performance(rt,bonus);
        }
    }
    
    
    
    
    
    function subscription(address _user, uint ct_amount, uint ETH)private {
        
        out_share = DT.get_out_share();
        now_balance = DT.get_balance();
        
        uint eth_amount = ct_amount.mul(now_balance).div(out_share);
        uint rate = fee_info[1][2].add(fee_info[1][6]);
        uint actual_eth_amount = eth_amount.add(eth_amount.mul(rate).div(1000));
        require(ETH >= actual_eth_amount);
       
        uint rt_bonus = ETH.mul(fee_info[1][6]).div(1000);
        
        require(CT.balanceOf(DT) >= ct_amount);
        
        RT.input.value(rt_bonus)();
        bouns(_user,rt_bonus);
       
        
        debt_info[_user][1] = debt_info[_user][1].add(ETH);
        debt_info[_user][3] = debt_info[_user][3].add(ETH.mul(fee_info[3][1]).div(1000));
        debt_info[_user][4] = debt_info[_user][4].add(ct_amount);
        
        uint cost = ETH.mul(fee_info[1][6]).div(1000);
        DT.input.value(ETH.sub(cost))(ETH.sub(cost),0);
        
        
        uint price = count_price(ct_amount);
        debt_info[_user][2] =debt_info[_user][2].add(price);
        
    }
    
    
   
    
    
    
    
    function count_price(uint ct_amount)private returns(uint){
        out_share = DT.get_out_share();
        now_balance = DT.get_balance();
        uint ct_price = ct_amount.mul(now_balance).div(out_share);
        return ct_price;
    }
    
    

    
    
    function claim_profit()public{
        out_share = DT.get_out_share();
        now_balance = DT.get_balance();
        
        uint now_price = count_price(debt_info[msg.sender][4]);
        //---先計算儲存CT的目前價格
        
        require(now_price >= debt_info[msg.sender][2]); //現在價格是否大於儲存價格
        uint profit = now_price.sub(debt_info[msg.sender][2]);
        uint actual = profit.mul(fee_info[1][4]).div(1000);
        uint discount = profit.sub(actual);
        
        if(debt_info[msg.sender][3] > debt_info[msg.sender][5]){
            debt_info[msg.sender][5] = debt_info[msg.sender][5].add(discount);
        }else{
            DT.input.value(0)(discount,0);
        }
        
        uint fee = actual.mul(fee_info[1][5]).div(1000); 
        uint take_profit = actual.sub(fee);   
        
       
      
        uint ct_amount = profit.mul(out_share).div(now_balance);
        require(CT.balanceOf(msg.sender) >= ct_amount);
        debt_info[msg.sender][4] = debt_info[msg.sender][4].sub(ct_amount);
        debt_info[msg.sender][6] = debt_info[msg.sender][6].add(take_profit);
        debt_info[msg.sender][7] = debt_info[msg.sender][7].add(take_profit);
        
        DT.CT_swap_ETH(msg.sender, ct_amount,take_profit,profit,fee);
    }
    
    
    
    
    function withdraw()public {
        require(CT.balanceOf(msg.sender) >= debt_info[msg.sender][4]);
        claim_profit();
        
        if(debt_info[msg.sender][3] >= debt_info[msg.sender][5]){
            uint fine = debt_info[msg.sender][3].sub(debt_info[msg.sender][5]);
        }
        
        require(debt_info[msg.sender][1] >= fine);
        uint principal = debt_info[msg.sender][1].sub(fine);
        DT.CT_swap_ETH(msg.sender, debt_info[msg.sender][4], 0,principal,0);
        reset(); 
    }
    
 

    
    function reset()private{
        for(uint i=1; i<=6; i++){
            debt_info[msg.sender][i]=0;
        }
      
    }
    
    
    
    function set_parameter(uint p1, uint p2, uint p3)public onlyOwner{
        fee_info[p1][p2] = p3;
    }
    
    function get_parameter(uint p1, uint p2)public view returns(uint p3){
        return fee_info[p1][p2];
    }
    
    
    //----------------view-----------------------------
    
    
    
    function get_balance()public view returns(uint){
        return DT.get_balance();
    }
    
    
    
    function get_out_share()public view returns(uint){
        return DT.get_out_share();
    }
    
    
    function get_debt()public view returns(uint){
        return DT.get_parameter(4,1);
    }
    
    
    

  
    
    
}