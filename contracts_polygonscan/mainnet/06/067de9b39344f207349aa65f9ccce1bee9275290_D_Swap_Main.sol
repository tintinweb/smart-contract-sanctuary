/**
 *Submitted for verification at polygonscan.com on 2021-08-27
*/

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


 abstract contract ERC20Interface {
    function totalSupply()virtual  public  view returns (uint);
    function balanceOf(address tokenOwner)virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

abstract contract ERC20_Gen_Lib{
    function Create(address p_owner, uint256 p_total ,string memory p_symbol , string memory p_name , uint8 p_decimals ) virtual public  returns(address);
}
// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data)virtual public;
}

 abstract contract ERC20_Prop_Interface {
     

     
     function symbol()virtual  public  view returns (string memory);
     function name()virtual  public  view returns (string memory);
     function decimals()virtual  public  view returns (uint8);
    
}
abstract contract Trading_Charge
{
    function Amount(uint256 amount ,uint256 block_span) virtual public view  returns(uint256);
   
}

abstract contract D_Swap_Factory  {
   
    function Create(address user, address token_head,address token_tail,address sys_reward_addr,uint256 sys_reward)virtual payable public  returns(address);
   
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

contract D_Swap_Main is Owned {
    
    using SafeMath for uint;

    address public m_Factory_Lib=address(0);
    address public m_Trading_Charge_Lib=address(0);
    address public m_Address_of_Arche_Token=address(0);
    uint256 public m_Arche_Amount_Per_Deal=0;
    address public m_Address_of_Token_Collecter=address(0);
    
    
    function Set_Trading_Charge_Lib(address lib) public onlyOwner
    {
        m_Trading_Charge_Lib=lib;
    }
    function Set_Arche_Address(address addr) public onlyOwner
    {
        m_Address_of_Arche_Token=addr;
    }
    function Set_Arche_Amount_Per_Deal(uint256 amount) public onlyOwner
    {
        m_Arche_Amount_Per_Deal=amount;
    }
    function Set_Token_Collecter(address addr) public onlyOwner
    {
        m_Address_of_Token_Collecter=addr;
    }
    function Set_Factory_Lib(address addr) public onlyOwner
    {
        m_Factory_Lib=addr;
    }
    constructor()public
    {
        
    }
    
    event E_Create(address swap ,address user,address swap_owner ,address token_head,address token_tail,address sys_reward_addr,uint256 sys_reward);
    event E_Initialize(address swap ,address user,uint256 total_amount_head ,uint256 total_amount_tail ,uint256 future_block_offset,string  slogan );
    
    event E_Remaining_Supply(address swap ,uint256 head_amount,uint256 tail_amount);
    event E_Token_Price(address swap ,address user, uint256 price);
    event E_Claim_For_Head(address swap ,address user);
    event E_Permit_User(address swap ,address user,address target);

    event E_Deposit_For_Head(address swap ,address user, uint256 amount,uint256 deposited_amount,address referer,uint256 head_remaining,uint256 tail_remaining);
    event E_Deposit_For_Tail(address swap ,address user, uint256 amount,uint256 deposited_amount,address referer,uint256 head_remaining,uint256 tail_remaining);
    event E_Withdraw_Head(address swap ,address user ,uint256 status);
    event E_Withdraw_Tail(address swap ,address user ,uint256 status);
    event E_Claim_For_Delivery(address swap ,address user );
    event E_Token_Info(address swap ,address user ,address head ,uint256 head_decimal,uint256 head_name ,address tail ,uint256 tail_decimal,uint256 tail_name,address reward ,uint256 reward_decimal,uint256 reward_name );
    
    mapping(address=>bool) public m_My_Dear_Son;
    modifier My_Dear_Son {
        require(m_My_Dear_Son[msg.sender] == true);
        _;
    }
    function Create(address token_head,address token_tail,address sys_reward_addr,uint256 sys_reward) payable public  returns(address){
        // Deflationary token is not supported 
        bool sys_res=false;
        if(sys_reward>0 && sys_reward_addr!=address(0))
        {
            // FUCK U Tether
            Receive_Token(sys_reward_addr,sys_reward,msg.sender);
          
        }
        
        address res= address(D_Swap_Factory(m_Factory_Lib).Create( msg.sender,token_head,token_tail,sys_reward_addr,sys_reward));
        m_My_Dear_Son[res]=true;
        Triger_Create(res , msg.sender, msg.sender , token_head, token_tail,sys_reward_addr,sys_reward);

        // Deflationary token is not supported 
        if(sys_reward>0 && sys_reward_addr!=address(0) )
        {
            // FUCK U Tether
            safeTransfer(sys_reward_addr,res,sys_reward);
            
        }

        ////Charging for deal//////////////////////////////////////////////////
        Receive_Token(m_Address_of_Arche_Token,m_Arche_Amount_Per_Deal,msg.sender);
        
        return (res);
    }
    function Triger_Create(address swap ,address user,address swap_owner ,address token_head,address token_tail ,address sys_reward_addr, uint256 sys_reward)private
    {
            emit E_Create( swap , user, swap_owner , token_head, token_tail,sys_reward_addr,sys_reward);
    }
    
    function Triger_Claim_For_Head(address swap ,address user  )public My_Dear_Son
    {
            emit E_Claim_For_Head( swap , user );
    }
    function Triger_Token_Price(address swap ,address user, uint256 price)public My_Dear_Son
    {
            emit E_Token_Price( swap , user ,price);
    }


    function Triger_Initialize(address swap ,address user,uint256 total_amount_head ,uint256 total_amount_tail ,uint256 future_block_offset,string memory slogan)public My_Dear_Son
    {
            emit E_Initialize( swap , user, total_amount_head , total_amount_tail,future_block_offset,slogan );
    }
    function Triger_Permit_User(address swap ,address user,address target )public My_Dear_Son
    {
            emit E_Permit_User( swap , user, target);
    }
   
    function Triger_Deposit_For_Head(address swap ,address user, uint256 amount , uint256 deposited_amount,address referer,uint256 head_remaining,uint256 tail_remaining)public My_Dear_Son
    {
        emit E_Deposit_For_Head( swap , user,  amount ,deposited_amount,referer,head_remaining,tail_remaining);
    }
    function Triger_Deposit_For_Tail(address swap ,address user, uint256 amount, uint256 deposited_amount,address referer,uint256 head_remaining,uint256 tail_remaining)public My_Dear_Son
    {
        emit E_Deposit_For_Tail( swap , user,  amount,deposited_amount, referer,head_remaining,tail_remaining);
    }
    function Triger_Withdraw_Head(address swap ,address user,uint256 status)public My_Dear_Son
    {
       emit E_Withdraw_Head( swap , user,status);
    }
    function Triger_Withdraw_Tail(address swap ,address user,uint256 status)public My_Dear_Son
    {
       emit E_Withdraw_Tail( swap , user,status);
    }
    
    function Triger_Claim_For_Delivery(address swap ,address user)public My_Dear_Son
    {
       emit E_Claim_For_Delivery( swap , user);
    }
    function Triger_Remaining_Supply(address swap ,uint256 head_amount,uint256 tail_amount)public My_Dear_Son
    {
        emit E_Remaining_Supply(swap,head_amount,tail_amount);
    }
    
    function Triger_Token_Info(address swap ,address user, address head ,uint256 head_decimal,uint256 head_name ,address tail ,uint256 tail_decimal,uint256 tail_name,address reward ,uint256 reward_decimal,uint256 reward_name)public My_Dear_Son
    {
            emit E_Token_Info( swap , user , head , head_decimal, head_name , tail , tail_decimal, tail_name, reward , reward_decimal, reward_name );
    }
  
////////////////////////////////////////////////////////////////////////////////////
    function TakeETH(uint256 quantity)public  onlyOwner returns(bool)
    {
         
        payable((owner)).transfer(quantity);
        return true;
    }
    fallback() external payable {}
    receive() external payable { 
    revert();
    }
    function Receive_Token(address addr,uint256 value,address from) internal
    {
        
        // FUCK U TETHER;
        uint256 t_balance_old = ERC20Interface(addr).balanceOf(address(this));
        safeTransferFrom(addr,from, address(this),value);
        uint256 t_balance = ERC20Interface(addr).balanceOf(address(this));
        
        uint256 e_amount=t_balance.sub(t_balance_old);
        
        require(e_amount>=value,"TOKEN LOST,REBASING TOKEN IS NOT SUPPORTED");
        
    }
    function safeTransfer(address _token, address _to, uint _value) internal {
        
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(ERC20Interface.transfer.selector, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER FAILED ,CHEACK OUT YOUR BALANCE');
    }
    function safeTransferFrom(address _token,address _from, address _to, uint _value) internal {
        
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(ERC20Interface.transferFrom.selector, _from,_to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER FAILED ,CHEACK OUT YOUR BALANCE');
    }
    function Call_Function(address addr,uint256 value ,bytes memory data) public  onlyOwner {
      addr.call{value:value}(data);
    }
    function Take_Token(address token_address,uint token_amount) public onlyOwner{
           ERC20Interface(token_address).transfer(msg.sender,token_amount);
    }
}