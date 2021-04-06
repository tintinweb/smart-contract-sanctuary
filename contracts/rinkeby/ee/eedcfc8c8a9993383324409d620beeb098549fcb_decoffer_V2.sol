/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

pragma solidity ^0.4.24;




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

contract decoffer_V2{
    using SafeMath for uint;
    
  
    Credit_token CT = Credit_token(0x2Cc5DCBC7d0Ef8ad90B293C265c5c6bd052e2b90);
   
    
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     
    address public owner;
    uint now_balance;
    uint out_share;
    
    mapping(address=>mapping(uint=>uint))public coffer_info; 
    //1.invest 2.price 3.credit 4.get_CT 
    mapping(uint=>mapping(uint=>uint))public fee_info;
    mapping(address=>bool)public authorize;
    
    event deposit(address user, uint amount , uint cumulation);
    event _price(uint _price);
    
    
    
    constructor()public payable{
        owner = msg.sender;
        
        out_share = CT.totalSupply().sub(CT.balanceOf(address(this)));
        now_balance = address(this).balance;
        
        fee_info[1][1] = 1*10**16;  //1-1最小投資金額
        fee_info[1][2] = 60;       //1-2匯兌比 
        fee_info[1][4] = 600;       //1-4 Actual profit
        fee_info[1][5] = 300;       //1-5收益抽成
        
        fee_info[3][1] = 20;        // credit
        fee_info[3][2] = 4;         // credit weight
        
        
    }
    
    
    
    function Deposit()public payable{
        require(msg.value >= fee_info[1][1]);
        
        out_share = CT.totalSupply().sub(CT.balanceOf(address(this)));
     
        uint amount = msg.value.sub(msg.value.mul(fee_info[1][2]).div(1000));
        uint ct_amount = amount.mul(out_share).div(now_balance);
        CT.transfer(msg.sender,ct_amount);
        
        coffer_info[msg.sender][1] = coffer_info[msg.sender][1].add(msg.value);
        coffer_info[msg.sender][3] = coffer_info[msg.sender][3].add(msg.value.mul(fee_info[3][1]).div(1000).mul(fee_info[3][2]));
        coffer_info[msg.sender][4] = coffer_info[msg.sender][4].add(ct_amount);
        
        uint cost = msg.value.mul(fee_info[3][1]).div(1000);
        now_balance = now_balance.add(msg.value).sub(cost);
        
        save_price(ct_amount);
        emit deposit(msg.sender,msg.value,coffer_info[msg.sender][1]); 
        
    }
    
    
    function save_price(uint ct_amount)private{
        out_share = CT.totalSupply().sub(CT.balanceOf(address(this)));
        uint price = ct_amount.mul(now_balance).div(out_share);
        coffer_info[msg.sender][2] =coffer_info[msg.sender][2].add(price);
        
        uint one = 1*10**18;
        emit _price(one.mul(now_balance).div(out_share));
    }
    

    
    
    function withdraw()public {
        require(CT.balanceOf(msg.sender) >= coffer_info[msg.sender][4]);
        out_share = CT.totalSupply().sub(CT.balanceOf(address(this)));
        uint now_price = coffer_info[msg.sender][4].mul(now_balance).div(out_share);
        //---先計算儲存CT的目前價格
        
        require(now_price >= coffer_info[msg.sender][2]); //現在價格是否大於儲存價格
        uint profit = now_price.sub(coffer_info[msg.sender][2]);
        uint actual = profit.mul(fee_info[1][4]).div(1000);
        uint discount = profit.sub(actual);
        
        uint fee = actual.mul(fee_info[1][5]).div(1000); 
        uint total_profit = coffer_info[msg.sender][1].add(actual).sub(fee);
        
        if(coffer_info[msg.sender][3] >= discount){
            uint fine = coffer_info[msg.sender][3].sub(discount);
            require(total_profit >= fine);
            total_profit = total_profit.sub(fine);
        }
            
        
        owner.transfer(fee);
      
       
        CT.transfer(address(0x0),coffer_info[msg.sender][4]);
        msg.sender.transfer(total_profit);
        now_balance = now_balance.sub(total_profit);
        
        
        reset(); 

    }
    

    
    function reset()private{
        
        for(uint i=1; i<=4 ; i++){
            coffer_info[msg.sender][i]=0;
        }
      
    }
    
    
    
    function set_parameter(uint p1, uint p2, uint p3)public onlyOwner{
        fee_info[p1][p2] = p3;
    }
    
    
    
    //-----------------------------pool_contrl------------------------------------------------
   
    
    function CT_swap_ETH(uint _ct,uint _eth,address _user)public {
       require(authorize[msg.sender] == true);
       require(CT.balanceOf(_user)>0);
       require(_ct>0 && _eth>0);
       out_share = CT.totalSupply().sub(CT.balanceOf(address(this)));
       require(_ct.mul(now_balance).div(out_share)>=_eth);
       
       CT.transferFrom(_user,address(this),_ct);
       _user.transfer(_eth);
       
    
       now_balance = now_balance.sub(_eth);
    }
   
   
    function input()public payable {
       require(authorize[msg.sender] == true);
       uint fee = msg.value.mul(1).div(100);
       owner.transfer(fee);
       now_balance = now_balance.add(msg.value.sub(fee));
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
    
    
    function authorization(address user)public onlyOwner{
        require(msg.sender == owner);
        authorize[user] = true;
    }
    
    function cancel_authorization(address user)public onlyOwner{
        require(msg.sender == owner);
        authorize[user] = false;
    }
    
    
    function ct_approve(address _to, uint ct_amount)public onlyOwner{
        CT.approve(_to,ct_amount);
    }
  
    
    
}