/**
 *Submitted for verification at Etherscan.io on 2021-08-26
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
    function Amount(uint256 amount ,address to) virtual public view  returns(uint256);
   
}
abstract contract D_Swap_Main
{
    
    function m_Address_of_System_Reward_Token()virtual  public view returns (address);
    function m_Address_of_Token_Collecter()virtual  public view returns (address);
    function m_Trading_Charge_Lib()virtual  public view returns (address);

    function m_ERC20_Gen_Lib()virtual  public view returns (address);
    function Triger_Create(address swap ,address user,address swap_owner ,address token_head,address token_tail,uint256 sys_reward)virtual  public ;
    function Triger_Entanglement(address swap ,address user ,address op_token_head,address op_token_tail)virtual  public ;
    function Triger_Initialize(address swap ,address user,uint256 total_amount_head ,uint256 total_amount_tail ,uint256 future_block,string memory slogan)virtual  public ;
    function Triger_Permit_User(address swap ,address user,address target )virtual public;
    function Triger_Token_Price(address swap ,address user, uint256 price)virtual public;
    function Triger_Claim_For_Head(address swap ,address user)virtual  public ;
    function Triger_Claim_For_Tail(address swap ,address user)virtual  public ;
    function Triger_Deposit_For_Head(address swap ,address user, uint256 amount,uint256 deposited_amount,address referer,uint256 head_remaining,uint256 tail_remaining)virtual  public ;
    function Triger_Deposit_For_Tail(address swap ,address user, uint256 amount,uint256 deposited_amount,address referer,uint256 head_remaining,uint256 tail_remaining)virtual  public ;
    function Triger_Withdraw_Head(address swap ,address user ,uint256 status)virtual  public ;
    function Triger_Withdraw_Tail(address swap ,address user ,uint256 status)virtual  public ;
    function Triger_Claim_For_Delivery(address swap ,address user) virtual  public ;
    function Triger_Remaining_Supply(address swap ,uint256 head_amount,uint256 tail_amount)virtual public;
    function Triger_Token_Info(address swap ,address user ,address head ,uint256 head_decimal,uint256 head_name ,address tail ,uint256 tail_decimal,uint256 tail_name,address reward ,uint256 reward_decimal,uint256 reward_name )virtual  public ;
   
  
}



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

contract D_Swap_Factory is Owned {

    function Set_DSwap_Main_Address(address addr) public onlyOwner
    {
        m_DSwap_Main_Address=addr;
    }
    address public m_DSwap_Main_Address=address(0);
    function Create(address user, address token_head,address token_tail,address sys_reward_addr,uint256 sys_reward) payable public  returns(address){
        require(msg.sender==m_DSwap_Main_Address,"INVALID INVOKER");
        address res= address(new D_Swap(m_DSwap_Main_Address , user,token_head,token_tail,sys_reward_addr,sys_reward));
        return (res);
    }
   
}


contract D_Swap is Owned {
    

    using SafeMath for uint;
    bool public m_Initialized=false;
    address public m_DSwap_Main_Address;
    uint256 public m_Future_Block;
    string  public  m_Slogan;
    
    uint256 public m_Amount_Reward;
    address public m_Token_Reward=address(0);
    
    string  public m_Version="0.0.1"; 
    address public m_Token_Head;
    address public m_Token_Tail;
    
    //address public m_referer_Head;
    //address public m_referer_Tail;
    
    address public m_OP_Token_Head;
    address public m_OP_Token_Tail;
    
    address public m_Rival_Head;
    address public m_Rival_Tail;
    
    uint256 public m_Amount_Head;
    uint256 public m_Amount_Tail;
    
    uint256 public m_Amount_Head_Swapped;
    uint256 public m_Amount_Tail_Swapped;
    uint256 public m_Amount_Head_Deliveryed;
    uint256 public m_Amount_Tail_Deliveryed;
    uint256 public m_Amount_Reward_Swapped;
    
    uint256 public m_Total_Amount_Head;
    uint256 public m_Total_Amount_Tail;

    
    
    bool public m_Entanglement=false;
    bool public m_Permit_Mode=false;
    mapping(address => bool) m_Permit_List;
    mapping(address => uint256) m_Future_Balance_Tail;
    uint256 public m_Future_Balance_Head;
    uint256 public m_Total_Future_Balance_Tail;
    bool public m_Option_Finish_Head=false;
    bool public m_Option_Finish_Tail=false;
     
    constructor(address swap_main,address swap_owner ,address token_head,address token_tail,address sys_reward_addr,uint256 sys_reward) public {
        
        require(token_head!=token_tail,"YOU CAN NOT STEP INTO THE REVOLVING DOOR");
        //require(sys_reward_addr!=token_tail,"YOU MAY USE ANOTHER TOKEN AS REWARD");
        //require(token_head!=sys_reward_addr,"YOU MAY USE ANOTHER TOKEN AS REWARD");
        owner =swap_owner;
        m_DSwap_Main_Address=swap_main;
        m_Token_Head=  token_head;
        m_Token_Tail=  token_tail;
        m_Amount_Reward=sys_reward;
        m_Token_Reward=sys_reward_addr;
        
    }
    function  StringConcat(string memory _a, string memory _b) public pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length +4);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
   }  
   function Str_To_Uint(string memory _str) private returns(uint256)
   {
       bytes memory str_bytes = bytes(_str);

        uint256 res = 0;
        for (uint i = 0; i < str_bytes.length; i++)
        {
            res=res+(uint8) (str_bytes[i]);
            res=res*256;
            if(i>=20)
            {
                break;
            }
        }

        return (res);
   }
    function Set_Initializing_Params(uint256 total_amount_head ,uint256 total_amount_tail ,uint256 future_block_offset,string memory slogan)public  onlyOwner
    {
        require(total_amount_head>0 && total_amount_tail >0 ,"YOU CAN NOT EXCHANGE ETHER");
        require(m_Initialized==false,"NO MAN EVER STEPS IN THE SAME RIVER TWICE");
        
        m_Future_Block=block.number+future_block_offset;
        m_Initialized=true;
        m_Total_Amount_Head=total_amount_head;
        m_Total_Amount_Tail=total_amount_tail;
        m_Slogan=slogan;
        D_Swap_Main(m_DSwap_Main_Address).Triger_Initialize( address(this) , msg.sender, total_amount_head , total_amount_tail ,future_block_offset,slogan);
            
        uint256 price=total_amount_head.mul(1e18);
        price=price.div(total_amount_tail);
        D_Swap_Main(m_DSwap_Main_Address).Triger_Token_Price( address(this) , msg.sender,price );
        
        D_Swap_Main(m_DSwap_Main_Address).Triger_Token_Info(
            address(this) , msg.sender,
            m_Token_Head,ERC20_Prop_Interface(m_Token_Head).decimals(),Str_To_Uint(ERC20_Prop_Interface(m_Token_Head).symbol()),
            m_Token_Tail,ERC20_Prop_Interface(m_Token_Tail).decimals(),Str_To_Uint(ERC20_Prop_Interface(m_Token_Tail).symbol()),
            m_Token_Reward,ERC20_Prop_Interface(m_Token_Reward).decimals(),Str_To_Uint(ERC20_Prop_Interface(m_Token_Reward).symbol())
            );
        
        
    }
    
    function Permit_User(address[] memory users)public onlyOwner
    {
        for(uint256 i=0;i<users.length;i++)
        {
            m_Permit_List[users[i]]=true;
            D_Swap_Main(m_DSwap_Main_Address).Triger_Permit_User( address(this) , msg.sender, users[i]);
            
        }
        m_Permit_Mode=true;
    }
    function Claim_For_Head()public onlyOwner
    {
        require(m_Initialized==true,"STEP INTO THE ETHER");
        require(m_Entanglement==false,"YOU ARE TOOOOO RIIIIIIICH");
   

        Receive_Token(m_Token_Head,m_Total_Amount_Head,msg.sender);

        m_Amount_Head=m_Total_Amount_Head;                
        D_Swap_Main(m_DSwap_Main_Address).Triger_Claim_For_Head( address(this) , msg.sender);
        m_Entanglement=true;
    }
    function Probe_Deposit_For_Tail(uint256 amount)public view returns(uint256 ,uint256)
    {

      

        require (m_Entanglement==true,"NOT ACTIONABLE");
        require (m_Option_Finish_Tail==false ,"SWAP CLOSED");
        if(m_Amount_Tail>=m_Total_Amount_Tail)revert();
        uint256 e_amount=amount;


        ////Calculate the amount of how many tokens to be transfered///////////////
        uint256 amount_back=e_amount.mul(m_Total_Amount_Head);
        amount_back=amount_back.div(m_Total_Amount_Tail);
        if(amount_back>=1)
        {
            amount_back=amount_back.sub(1);
        }
        
      
        uint256 reward_back=m_Amount_Reward.mul(e_amount); 
        reward_back=reward_back.div(m_Total_Amount_Tail);
        
        if(reward_back>=1)
        {
            reward_back=reward_back.sub(1);
        }
        
        /////////////////////////////////////////////////////////////////////////////////
        
        
        return (amount_back,reward_back);      
 
    }
    
    function Get_Token_Balances() public view returns(uint256,uint256)
    {
         uint256 amount_back=0;//
        amount_back=m_Total_Amount_Head- m_Amount_Head_Deliveryed;
       
        uint256 reward_back=0;//
        reward_back=m_Amount_Reward- m_Amount_Reward_Swapped;
        
        return (amount_back,reward_back);   
    }
    
    function Deposit_For_Tail(uint256 amount,address referer)public
    {   
        address e_referer=referer;
        if(e_referer==address(0))
        {
            e_referer=D_Swap_Main(m_DSwap_Main_Address).m_Address_of_Token_Collecter();
        }
        
        if(m_Permit_Mode==true)
        {
            require(m_Permit_List[msg.sender]==true,"NOT PERMITTED");
        }
        

        require (m_Entanglement==true,"NOT ACTIONABLE");
        require (m_Option_Finish_Tail==false ,"SWAP CLOSED");
        
        
        ////calculate exactly amount whitch can be swapped ////////////////////////////////////////////////////////////////////////
        if(m_Amount_Tail>=m_Total_Amount_Tail)revert();
        uint256 e_amount= m_Total_Amount_Tail.sub(m_Amount_Tail);
        if(e_amount>amount)
        {
            e_amount=amount;
        }

        //////////////////////////////////////////////////////////////////////////////
        
        ////Receive tokens of tail and accumulate the variable m_Amount_Tail//////
        require(e_amount>0,"NO TOKEN RECEIVED");//check
        m_Amount_Tail=m_Amount_Tail.add(e_amount);//effect
        m_Amount_Tail_Swapped= m_Amount_Tail_Swapped.add(e_amount);//effect
        Receive_Token(m_Token_Tail,e_amount,msg.sender);//interaction
        
        //////////////////////////////////////////////////////////////////////////////
        
        
        ////Calculate the amount of how many tokens to be transfered///////////////
        uint256 amount_back=e_amount.mul(m_Total_Amount_Head);
        amount_back=amount_back.div(m_Total_Amount_Tail);
        if(amount_back>=1)
        {
            amount_back=amount_back.sub(1);
        }
        m_Amount_Head_Swapped= m_Amount_Head_Swapped.add(amount_back);
      
        uint256 reward_back=m_Amount_Reward.mul(e_amount); 
        reward_back=reward_back.div(m_Total_Amount_Tail);
        
        if(reward_back>=1)
        {
            reward_back=reward_back.sub(1);
        }
        m_Amount_Reward_Swapped= m_Amount_Reward_Swapped.add(reward_back);
        /////////////////////////////////////////////////////////////////////////////////
        
        
        
        ////Transfer token and rewards /////////////////////////////////////////////
        if(amount_back>=1)
        {
            m_Total_Future_Balance_Tail=m_Total_Future_Balance_Tail.add(amount_back);
            m_Future_Balance_Tail[msg.sender]=m_Future_Balance_Tail[msg.sender].add(amount_back);
        }       
        if(reward_back>=1)
        {
            safeTransfer(m_Token_Reward,e_referer ,reward_back);
        }             
        if(e_amount>=1)
        {
            m_Future_Balance_Head=m_Future_Balance_Head.add(e_amount);
        }
        ///////////////////////////////////////////////////////////////////////////
        
        
        ////Auto Delivery////////////////////////////////////////////////////////
        if(block.number>= m_Future_Block)
        {
            Impl_Delivery(msg.sender);
        }
        /////////////////////////////////////////////////////////////////////////
        
        
        ////Triger Event 
        D_Swap_Main(m_DSwap_Main_Address).Triger_Deposit_For_Tail( address(this) , msg.sender, e_amount,m_Amount_Tail,referer,
        m_Total_Amount_Head.sub(m_Amount_Head_Swapped),m_Total_Amount_Tail.sub(m_Amount_Tail_Swapped));
        
        D_Swap_Main(m_DSwap_Main_Address).Triger_Remaining_Supply( address(this) ,
        m_Total_Amount_Head.sub(m_Amount_Head_Swapped),m_Total_Amount_Tail.sub(m_Amount_Tail_Swapped));
    }
    function Impl_Delivery(address user) internal
    {
        // Delivery Token For Tail
        uint256 head_amount_back=m_Future_Balance_Tail[user];
        m_Amount_Head_Deliveryed=m_Amount_Head_Deliveryed.add(head_amount_back);
        m_Total_Future_Balance_Tail=m_Total_Future_Balance_Tail.sub(head_amount_back);
        m_Future_Balance_Tail[user]=0;
        
        if(head_amount_back>=1)
        {
            Charging_Transfer_ERC20(m_Token_Head,user,head_amount_back);//interaction 
        } 
        
        //////////////////////////////////////////////////////
        
        // Delivery Token For Head
        uint256 tail_amount_back=0;
        tail_amount_back=m_Future_Balance_Head;
        m_Future_Balance_Head=0;
        m_Amount_Tail_Deliveryed=m_Amount_Tail_Deliveryed.add( tail_amount_back);
        Charging_Transfer_ERC20(m_Token_Tail,owner,tail_amount_back);//interation
        
        D_Swap_Main(m_DSwap_Main_Address).Triger_Claim_For_Delivery( address(this) , user);
    
    }
    function Claim_For_Delivery() public
    {
        require(block.number>= m_Future_Block,"WAIT FOR THE BLOCK BY DAY AND BY NIGHT");
        
        Impl_Delivery(msg.sender);
        
        D_Swap_Main(m_DSwap_Main_Address).Triger_Claim_For_Delivery( address(this) , msg.sender);
    }

    function Charging_Transfer_ERC20 (address token ,address to ,uint256 amount)private
    {
        (address tc_addr)= D_Swap_Main(m_DSwap_Main_Address).m_Trading_Charge_Lib();
        (address collecter_addr)= D_Swap_Main(m_DSwap_Main_Address).m_Address_of_Token_Collecter();
        uint256 exactly_amount=Trading_Charge(tc_addr).Amount(amount,to);
        
        
        bool res=true;
        if(exactly_amount>=1)
        {
            safeTransfer(token,to,exactly_amount);
        }
       
        
        if(amount.sub(exactly_amount)>=1)
        {
           safeTransfer(token,collecter_addr,amount.sub(exactly_amount));
        }
        
    }
    function Withdraw_Head()public onlyOwner
    {
        
        uint256 status=0;
        require(m_Option_Finish_Head==false,"Option Closed");
        m_Option_Finish_Head=true;
        m_Option_Finish_Tail=true;

        if(m_Entanglement==true)
        {
            
            uint256 amount_back=0;//
            amount_back=m_Total_Amount_Head.sub(m_Amount_Head_Swapped);
            
            if(amount_back>=1)
            {
                safeTransfer(m_Token_Head, msg.sender,amount_back);
            }
        }
        
        if(m_Initialized==true)
        {
            
            uint256 reward_back=0;//
            reward_back= m_Amount_Reward.sub( m_Amount_Reward_Swapped);
            if(reward_back>=1)
            {
                safeTransfer(m_Token_Reward, msg.sender,reward_back);
            }
        }
        
         ////Triger Event 
        D_Swap_Main(m_DSwap_Main_Address).Triger_Withdraw_Head( address(this) , msg.sender,status);

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
    fallback() external payable {}
    receive() external payable { 
        //revert();
    }
    //function Call_Function(address addr,uint256 value ,bytes memory data) public  onlyOwner  {
    //addr.call{value:value}(data);
    // 
    //}
}