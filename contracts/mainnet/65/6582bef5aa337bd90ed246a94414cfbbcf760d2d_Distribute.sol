/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-27
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-13
*/

pragma solidity 0.4.26;

contract IERC20 {
    uint public decimals;
    string public    name;
    string public   symbol;
    mapping(address => uint) public balances;
    mapping (address => mapping (address => uint)) public allowed;
    
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

 


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
 
  
contract Distribute{
       using SafeMath for uint;
       
       
       
        event GetFod(address getAddress, uint256 value);
        event DepositeFod(address ethAddress, uint256 value);
        event UseInviteCode(address ethAddress, bytes4 code);    
       
      struct Pledge{
            uint day;
            uint investAmount;  
            uint earnings;         
            uint createTime;    
            uint dueTime;
            uint receivedDay;
            uint end;
      }  


      struct Invite{
            address userAddr;
            uint256 earnings; 
            uint day;
            uint256 createTime;  
            uint256 dueTime;
            uint256 receivedDay;
            uint end;
      }  

        uint intervalTime=86400;
        uint public yieldRate=110;
        uint public inviteYieldRate=100;

        address public founder;

        address fod=0xc7bE1Cf99e6a691ad5c56E3D63AD9667C6932E63;
        uint fodDecimals=8;
    
   
        mapping (bytes4 => Invite[]) public inviteLogs;
        
        mapping (address => bytes4) public useInviteCodeMap;
        
        mapping (bytes4 => address) public inviteCodeMap;
        
        mapping (bytes4 => uint) public codeUsageCounts;
        
        mapping (address => Pledge[]) public addressToPledge;
        mapping(uint=>uint) public dateToYields;
        mapping(uint=>uint) public dayMap;
            
            
            
        constructor() public {
            dateToYields[0]=18;
            dateToYields[1]=26;
            dateToYields[2]=36;
            dateToYields[3]=46;
            dateToYields[4]=56;
            
            dayMap[0]=1;
            dayMap[1]=7;
            dayMap[3]=30;
            dayMap[2]=60;
            dayMap[4]=90;
            
            founder = msg.sender;
         }
         
        
        
        function getAddrInviteCode(address _addr) view returns (bytes4) {
            bytes4  inviteCode=bytes4(keccak256((_addr)));
            if(inviteCodeMap[inviteCode]!=0){
                return inviteCode;
            }else{
                return 0;
            }
        }
         
        function getInviteCode() view returns (bytes4) {
            bytes4  inviteCode=bytes4(keccak256((msg.sender)));
            return inviteCode;
        }
        
        function getPledgeCount(address _addr) view returns (uint) {
            return addressToPledge[_addr].length;
        }
        
        function getInvitesCount(address _addr) view returns (uint) {
            bytes4  inviteCode=bytes4(keccak256((msg.sender)));
            return inviteLogs[inviteCode].length;
        }
   
   
        function setYieldRate(uint _yieldRate) public onlyOwner returns (bool success) {
            yieldRate=_yieldRate;
            return true;
        }
         
        function setInviteYieldRate(uint _inviteYieldRate) public onlyOwner returns (bool success) {
            inviteYieldRate=_inviteYieldRate;
            return true;
        }
        
        function setDateToYield(uint _index,uint _yield) public onlyOwner returns (bool success) {
            dateToYields[_index]=_yield;
            return true;
        }
         
        function setDayMap(uint _index,uint _day) public onlyOwner returns (bool success) {
            dayMap[_index]=_day;
            return true;
        }
        
        
        function getTotalUnLockAmount(address _addr) public view returns (uint256) {
             uint256 unlockAmount;
             uint256 currentAmount;
             Pledge[] pledges=addressToPledge[_addr];
             for(uint i=0;i<pledges.length;i++){
                if(pledges[i].end==1)continue;
                uint day=(now.sub(pledges[i].createTime)).div(intervalTime);
                uint256 dayAmount=pledges[i].earnings.div(pledges[i].day);
            
                if(now>pledges[i].dueTime){
                    if(day.add(pledges[i].receivedDay)>=pledges[i].day){
                        currentAmount=(pledges[i].day.sub(pledges[i].receivedDay)).mul(dayAmount).add(pledges[i].investAmount);
                    }else{
                         currentAmount=(day.sub(pledges[i].receivedDay)).mul(dayAmount).add(pledges[i].investAmount);
                    }
                }else{
                    currentAmount=(day.sub(pledges[i].receivedDay)).mul(dayAmount);
                }
                unlockAmount=unlockAmount.add(currentAmount);
            }
            bytes4  inviteCode=bytes4(keccak256((_addr)));
            Invite[] Invites=inviteLogs[inviteCode];
            for(uint j=0;j<Invites.length;j++){
                if(Invites[j].end==1)continue;
                uint day2=(now.sub(Invites[j].createTime)).div(intervalTime);
                uint256 dayAmount2=Invites[j].earnings.div(Invites[j].day);
                
                if(day2.add(Invites[j].receivedDay)>=Invites[j].day){
                     currentAmount=(Invites[j].day.sub(Invites[j].receivedDay)).mul(dayAmount2);
                }else{
                     currentAmount=(day2.sub(Invites[j].receivedDay)).mul(dayAmount2);
                }
                unlockAmount=unlockAmount.add(currentAmount);
            }
            return unlockAmount;
        }
        
        function getTotalPledgeAmount(address _addr) public view returns (uint256) {
            uint256 amount;
            uint256 unlockAmount;
            Pledge[] pledges=addressToPledge[_addr];
            for(uint i=0;i<pledges.length;i++){
                amount=amount.add(pledges[i].investAmount);
            }
            return amount;
        }
        
        function getUnLockPledgeAmount(address _addr) public view returns (uint256) {
            uint256 unlockAmount;
            uint256 currentAmount;
            Pledge[] pledges=addressToPledge[_addr];
             for(uint i=0;i<pledges.length;i++){
                if(pledges[i].end==1)continue;
                uint day=(now.sub(pledges[i].createTime)).div(intervalTime);
                uint256 dayAmount=pledges[i].earnings.div(pledges[i].day);
            
                if(now>pledges[i].dueTime){
                    if(day.add(pledges[i].receivedDay)>=pledges[i].day){
                        currentAmount=(pledges[i].day.sub(pledges[i].receivedDay)).mul(dayAmount).add(pledges[i].investAmount);
                    }else{
                         currentAmount=(day.sub(pledges[i].receivedDay)).mul(dayAmount).add(pledges[i].investAmount);
                    }
                }else{
                    currentAmount=(day.sub(pledges[i].receivedDay)).mul(dayAmount);
                }
                unlockAmount=unlockAmount.add(currentAmount);
            }
            return unlockAmount;
        }
        
        function getTotalInviteAmount(address _addr) public view returns (uint256) {
            uint256 amount;
            bytes4  inviteCode=bytes4(keccak256((_addr)));
            Invite[] Invites=inviteLogs[inviteCode];
            for(uint i=0;i<Invites.length;i++){
                amount=amount.add(Invites[i].earnings);
            }
            return amount;
        }
        
        function getUnlockInviteAmount(address _addr) public view returns (uint256) {
            uint256 unlockAmount;
            uint256 currentAmount;
            bytes4  inviteCode=bytes4(keccak256((_addr)));
            Invite[] Invites=inviteLogs[inviteCode];
            for(uint j=0;j<Invites.length;j++){
                if(Invites[j].end==1)continue;
                uint day=(now.sub(Invites[j].createTime)).div(intervalTime);
                uint256 dayAmount=Invites[j].earnings.div(Invites[j].day);
                
                if(day.add(Invites[j].receivedDay)>=Invites[j].day){
                     currentAmount=(Invites[j].day.sub(Invites[j].receivedDay)).mul(dayAmount);
                }else{
                     currentAmount=(day.sub(Invites[j].receivedDay)).mul(dayAmount);
                }
                unlockAmount=unlockAmount.add(currentAmount);
            }
            return unlockAmount;
        }
   
        function useInviteCode(bytes4 _inviteCode) public returns (bool success) {
            require(useInviteCodeMap[msg.sender]==0);
            require(inviteCodeMap[_inviteCode]!=0);
            bytes4  inviteCode=bytes4(keccak256((msg.sender)));
            require(_inviteCode!=inviteCode);
            useInviteCodeMap[msg.sender]=_inviteCode;
            codeUsageCounts[_inviteCode]=codeUsageCounts[_inviteCode]+1;
            emit UseInviteCode(msg.sender,_inviteCode);
            return true;
        }
   

        function depositeFod(uint256 _amount,uint _mode) public {
            uint256 yie=100;
            if(useInviteCodeMap[msg.sender]!=0){
                yie=yieldRate;
            }

            IERC20 fodToken =IERC20(fod);
            fodToken.transferFrom(msg.sender,this,_amount);
            
            uint256 dueTime=now.add(dayMap[_mode].mul(intervalTime));
            uint256 earnings=_amount.mul(yie).mul(dateToYields[_mode]).mul(dayMap[_mode]).div(3650000);
            Pledge memory  pledge=Pledge(dayMap[_mode],_amount,earnings,now,dueTime,0,0);
            addressToPledge[msg.sender].push(pledge);

            if(useInviteCodeMap[msg.sender]!=0){
                 Invite memory  invite=Invite(msg.sender,earnings.mul(inviteYieldRate).div(100),dayMap[_mode],now,dueTime,0,0);
                 inviteLogs[useInviteCodeMap[msg.sender]].push(invite);
            }

            if(inviteCodeMap[bytes4(keccak256((msg.sender)))]==0){
                 inviteCodeMap[bytes4(keccak256((msg.sender)))]=msg.sender;
            }
            
            emit DepositeFod(msg.sender,_amount);
        }
        
       function receiveFod() public{
            uint256 unlockAmount;
             uint256 currentAmount;
            Pledge[] pledges=addressToPledge[msg.sender];
            for(uint i=0;i<pledges.length;i++){
                if(pledges[i].end==1)continue;
                uint day=(now.sub(pledges[i].createTime)).div(intervalTime);
                uint256 dayAmount=pledges[i].earnings.div(pledges[i].day);
            
                if(now>pledges[i].dueTime){
                    if(day.add(pledges[i].receivedDay)>=pledges[i].day){
                        currentAmount=(pledges[i].day.sub(pledges[i].receivedDay)).mul(dayAmount).add(pledges[i].investAmount);
                    }else{
                         currentAmount=(day.sub(pledges[i].receivedDay)).mul(dayAmount).add(pledges[i].investAmount);
                    }
                    pledges[i].end=1;
                }else{
                    currentAmount=(day.sub(pledges[i].receivedDay)).mul(dayAmount);
                    pledges[i].receivedDay=day;
                }
                unlockAmount=unlockAmount.add(currentAmount);
            }
            
            bytes4  inviteCode=bytes4(keccak256((msg.sender)));
            Invite[] Invites=inviteLogs[inviteCode];
            for(uint j=0;j<Invites.length;j++){
                if(Invites[j].end==1)continue;
                uint day2=(now.sub(Invites[j].createTime)).div(intervalTime);
                uint256 dayAmount2=Invites[j].earnings.div(Invites[j].day);
                
                if(day2.add(Invites[j].receivedDay)>=Invites[j].day){
                     currentAmount=(Invites[j].day.sub(Invites[j].receivedDay)).mul(dayAmount2);
                     Invites[j].end=1;
                }else{
                     currentAmount=(day2.sub(Invites[j].receivedDay)).mul(dayAmount2);
                     Invites[j].receivedDay=day2;
                }
                unlockAmount=unlockAmount.add(currentAmount);
            }
  
            IERC20 fodToken =IERC20(fod);
            fodToken.transfer(msg.sender,unlockAmount);
            emit GetFod(msg.sender,unlockAmount);
        }
        
        
        
        
        
        
 
        function withdrawToken (address _tokenAddress,address _user,uint256 _tokenAmount)public onlyOwner returns (bool) {
             IERC20 token =IERC20(_tokenAddress);
             token.transfer(_user,_tokenAmount);
            return true;
        }


        function changeFounder(address newFounder) public onlyOwner{
            if (msg.sender!=founder) revert();
            founder = newFounder; 
        }
 
        modifier onlyOwner() {
            require(msg.sender == founder);
            _;
        }
   
}