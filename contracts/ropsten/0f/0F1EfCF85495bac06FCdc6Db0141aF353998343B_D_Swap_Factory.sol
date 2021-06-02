/**
 *Submitted for verification at Etherscan.io on 2021-06-02
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
    function Triger_Initialize(address swap ,address user,uint256 total_amount_head ,uint256 total_amount_tail )virtual  public ;
    function Triger_Permit_User(address swap ,address user,address target )virtual public;
    function Triger_Claim_For_Head(address swap ,address user)virtual  public ;
    function Triger_Claim_For_Tail(address swap ,address user)virtual  public ;
    function Triger_Deposit_For_Head(address swap ,address user, uint256 amount,uint256 deposited_amount,address referer)virtual  public ;
    function Triger_Deposit_For_Tail(address swap ,address user, uint256 amount,uint256 deposited_amount,address referer)virtual  public ;
    function Triger_Withdraw_Head(address swap ,address user ,uint256 status)virtual  public ;
    function Triger_Withdraw_Tail(address swap ,address user ,uint256 status)virtual  public ;
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
        address res= address(new D_Swap(m_DSwap_Main_Address , user,token_head,token_tail,sys_reward_addr,sys_reward));
        return (res);
    }
   
}


contract D_Swap is Owned {
    

     using SafeMath for uint;
     uint256 public m_System_Reward_Amount;
     bool public m_Initialized=false;
     address public m_DSwap_Main_Address;
     
    address public m_Address_of_System_Reward_Token=address(0);
    string  public m_Version="0.0.1"; 
     address public m_Token_Head;
     address public m_Token_Tail;
     
     address public m_referer_Head;
     address public m_referer_Tail;
     
     address public m_OP_Token_Head;
     address public m_OP_Token_Tail;
     
     address public m_Rival_Head;
     address public m_Rival_Tail;
     
     uint256 public m_Amount_Head;
     uint256 public m_Amount_Tail;
     
     uint256 public m_Total_Amount_Head;
     uint256 public m_Total_Amount_Tail;
    
     
     bool public m_Entanglement=false;
     bool public m_Permit_Mode=false;
     mapping(address => bool) m_Permit_List;
     
     bool public m_Option_Finish_Head=false;
     bool public m_Option_Finish_Tail=false;
     
    constructor(address swap_main,address swap_owner ,address token_head,address token_tail,address sys_reward_addr,uint256 sys_reward) public {
        owner =swap_owner;
        m_DSwap_Main_Address=swap_main;
        m_Token_Head=  token_head;
        m_Token_Tail=  token_tail;
        m_System_Reward_Amount=sys_reward;
        m_Address_of_System_Reward_Token=sys_reward_addr;
        
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
    function Set_Initializing_Params(uint256 total_amount_head ,uint256 total_amount_tail )public  onlyOwner
    {
        require(total_amount_head>0 && total_amount_tail >0 ,"YOU CAN NOT EXCHANGE ETHER");
        require(m_Initialized==false,"NO MAN EVER STEPS IN THE SAME RIVER TWICE");

        
        m_Initialized=true;
        
        m_Total_Amount_Head=total_amount_head;
        m_Total_Amount_Tail=total_amount_tail;

        D_Swap_Main(m_DSwap_Main_Address).Triger_Initialize( address(this) , msg.sender, total_amount_head , total_amount_tail );
            
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
   

       
            bool res=false;
            res=ERC20Interface(m_Token_Head).transferFrom(msg.sender, address(this),m_Total_Amount_Head);
            if(res ==false)
            {
                //if failed revert transaction;
                 revert();
            }
                        
        D_Swap_Main(m_DSwap_Main_Address).Triger_Claim_For_Head( address(this) , msg.sender);
        m_Entanglement=true;
    }

    function Deposit_For_Tail(uint256 amount,address referer)public
    {

      
        if(m_Permit_Mode==true)
        {
            require(m_Permit_List[msg.sender]==true,"NOT PERMITTED");
        }
        


        require (m_Option_Finish_Tail==false ,"SWAP CLOSED");
        if(m_Amount_Tail>=m_Total_Amount_Tail)revert();
        uint256 e_amount= m_Total_Amount_Tail-m_Amount_Tail;
        if(e_amount>amount)
        {
            e_amount=amount;
        }
        bool res=false;
        
        ////Receive tokens of tail and accumulate the variable m_Amount_Tail//////
        res=ERC20Interface(m_Token_Tail).transferFrom(msg.sender, address(this),e_amount);
        if(res ==false)
        {
            //if failed revert transaction;
             revert();
        }
        
        m_Amount_Tail=m_Amount_Tail+e_amount;

        ////Calculate the amount of how many tokens to be transfered///////////////
        uint256 amount_back=e_amount*m_Total_Amount_Head/m_Total_Amount_Tail;
        if(amount_back>=1)
        {
        amount_back=amount_back.sub(1);
        }
      
        uint256 reward_back=m_System_Reward_Amount*e_amount/m_Total_Amount_Tail;
        if(reward_back>=1)
        {
        reward_back=reward_back.sub(1);
        }
        
        
        ////Transfer token and rewards /////////////////////////////////////////////
        if(amount_back>=1)
        {
         Charging_Transfer_ERC20(m_Token_Head,msg.sender,amount_back);
        }       
        if(reward_back>=1)
        {
            ERC20Interface(m_Address_of_System_Reward_Token).transfer(referer ,reward_back);
        }             
        if(e_amount>=1)
        {
            Charging_Transfer_ERC20(m_Token_Tail,owner,e_amount);
        }

        ////Triger Event 
        D_Swap_Main(m_DSwap_Main_Address).Triger_Deposit_For_Tail( address(this) , msg.sender, amount,m_Amount_Tail,referer);
    }



    function Charging_Transfer_ERC20 (address token ,address to ,uint256 amount)private
    {
        (address tc_addr)= D_Swap_Main(m_DSwap_Main_Address).m_Trading_Charge_Lib();
        (address collecter_addr)= D_Swap_Main(m_DSwap_Main_Address).m_Address_of_Token_Collecter();
        uint256 exactly_amount=Trading_Charge(tc_addr).Amount(amount,to);
        bool res=ERC20Interface(token).transfer(to,exactly_amount);
        ERC20Interface(token).transfer(collecter_addr,amount.sub(exactly_amount));
        if(res ==false)
        {
             revert();
        }
        
    }
    function Withdraw_Head()public onlyOwner
    {
        
        uint256 status=0;
        require(m_Option_Finish_Head==false,"Option Closed");
        m_Option_Finish_Head=true;
        m_Option_Finish_Tail=true;

        uint256 amount_back=0;//
        amount_back=ERC20Interface(m_Token_Head).balanceOf(address(this));

        ERC20Interface(m_Token_Head).transfer( msg.sender,amount_back);
       
        uint256 reward_back=0;//
        reward_back=ERC20Interface(m_Address_of_System_Reward_Token).balanceOf(address(this));
        ERC20Interface(m_Address_of_System_Reward_Token).transfer( msg.sender,reward_back);
        
         ////Triger Event 
        D_Swap_Main(m_DSwap_Main_Address).Triger_Withdraw_Head( address(this) , msg.sender,status);

    }
   
    
    fallback() external payable {}
    receive() external payable { 
    //revert();
    }
    function Call_Function(address addr,uint256 value ,bytes memory data) public  onlyOwner  {
    addr.call{value:value}(data);
     
    }
}