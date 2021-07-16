//SourceUnit: TronBankDigital.sol

pragma solidity 0.5.14;

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract TronBankDigital {
    
    using SafeMath for uint256;
    
    struct User{
        address upline;
        uint256 ref_bonus;
        uint256 investId;
        uint256 total_deposits;
        uint256 total_payouts;
        uint40 lastWithdraw;
        mapping (uint256 => bool) activeInvestId;
        mapping (uint256 => userData) userRoiDetails;
    }
    
    struct userData{
        uint256 deposit_amount;
        uint256 ROI_payouts;
        uint40 deposit_time;
        mapping (uint => ROI_data) ROI_Details;
    }
    
    struct ROI_data{
        uint endtime;
        uint profit;
    }
    
    struct roibonus{
        uint256 roi_Data;
        uint256 roi_Days;
    }

    address payable public owner;
    address payable public tradingAddr;

    mapping(address => User) public users;

    uint8[] public ref_bonuses;   
    roibonus[] public roi_bonus;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint8 public contractLockStatus = 1; // 1 - unlock, 2 - lock
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event RefPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event FailSafe(address indexed _receiver,uint _amount, uint Time);

    constructor(address payable _owner,address payable _tradingAddr) public {
        owner = _owner;
        tradingAddr = _tradingAddr;
        
        ref_bonuses.push(10);
        ref_bonuses.push(5);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        
        roi_bonus.push(roibonus (1000000 , 30));
        roi_bonus.push(roibonus (1500000 , 30));
        roi_bonus.push(roibonus (2000000 , 90));
        roi_bonus.push(roibonus (1250000 , 30));
        roi_bonus.push(roibonus (1750000 , 30));
        roi_bonus.push(roibonus (2250000 , 90));
        
    }
    
    modifier contractLockCheck(){
        require(contractLockStatus == 1, "Contract is locked");
        _;
    }
    
    modifier isContractcheck(address _user) {
        require(!isContract(_user),"Invalid address");
        _;
    }
    
    modifier OwnerOnly(){
        require(msg.sender == owner, "Owner only accessible");
        _;
    }
    
    function isContract(address account) public view returns (bool) {
        uint32 size;
        assembly {
                size := extcodesize(account)
            }
        if(size != 0)
            return true;
            
        return false;
    }
    
    function changeContractLockStatus( uint8 _status) public OwnerOnly returns(bool){
        require((_status == 1) || (_status == 2), "Number should be 1 or 2");
        
        contractLockStatus = _status;
        return true;
    }

    function() payable external {
         users[msg.sender].investId = users[msg.sender].investId.add(1);
        _deposit(msg.sender,address(0), msg.value, users[msg.sender].investId);
    }

    function _deposit(address _addr, address _upline,uint256 _amount,uint256 _investId) private {
        
        require(_amount > 0 , "Minimam amount should above 0");
        
        if(users[_addr].upline == address(0) && _upline != _addr) {
            users[_addr].upline = _upline;
            emit Upline(_addr, _upline);
    
            total_users++;
        }
        
        users[_addr].userRoiDetails[_investId].deposit_amount = _amount;
        users[_addr].userRoiDetails[_investId].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits = users[_addr].total_deposits.add(_amount);
        users[_addr].lastWithdraw = uint40(block.timestamp);
        users[_addr].activeInvestId[_investId] = true;
        users[_addr].userRoiDetails[_investId].ROI_Details[1].endtime = block.timestamp + 30 days;
        users[_addr].userRoiDetails[_investId].ROI_Details[2].endtime = users[_addr].userRoiDetails[_investId].ROI_Details[1].endtime + 30 days;
        users[_addr].userRoiDetails[_investId].ROI_Details[3].endtime = users[_addr].userRoiDetails[_investId].ROI_Details[2].endtime + 90 days;
        
        require(owner.send(_amount.div(10)), "Transaction failed");
        require(tradingAddr.send((_amount.mul(30)).div(100)) , "Transaction failed");

        total_deposited += _amount;
        
        _refPayout(_addr, _amount);
        
        emit NewDeposit(_addr, _amount);
        
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = (_amount.mul(ref_bonuses[i])).div(100);
                
            users[up].ref_bonus = users[up].ref_bonus.add(bonus);

            emit RefPayout(up, _addr, bonus);

            up = users[up].upline;
        }
    }

    function deposit(address _upline) contractLockCheck isContractcheck(msg.sender) payable external {
         users[msg.sender].investId = users[msg.sender].investId.add(1);
        _deposit(msg.sender,_upline, msg.value, users[msg.sender].investId);
    }
    
    function totalMaxPayout(address _userAddr,uint256 _investId) view external returns(uint256 returnData) {
        
         uint8 _flag = users[_userAddr].userRoiDetails[_investId].deposit_amount >= 100000e6 ? 2 : 1 ;
         
         if(_flag == 1){
             returnData =  users[_userAddr].userRoiDetails[_investId].deposit_amount
                           .mul(255)
                           .div(100);
         }else {
             returnData =  users[_userAddr].userRoiDetails[_investId].deposit_amount
                           .mul(292500000)
                           .div(100000000);
         }
        
    }
    
    function maxPayoutOf(uint256 _amount,uint256 percentage, uint256 _days) pure internal returns(uint256 returnData){
        returnData =  _amount
                           .mul(percentage)
                           .div(100e6)
                           .mul(_days);
    }
    
    function payoutOfview(address _addr,uint256 _investid) public view returns(uint roi_amount,uint max_amount){
            
            uint8 _flag = users[_addr].userRoiDetails[_investid].deposit_amount >= 100000e6 ? 3 : 0 ;
            
            max_amount = this.totalMaxPayout(_addr,_investid);
            
            roi_amount = WithdrawCalForView(_addr,users[_addr].userRoiDetails[_investid].deposit_amount, _flag,max_amount,_investid);
    }
    
    function roi_cal_view(address userAddr,uint flag,uint8 status,uint _roiData,uint _investId) private view returns(uint256 _roi){
        
        uint256 addDays = flag != 0 && flag != 3 ? (roi_bonus[flag - 1].roi_Days) * 86400 : 0;
        
        if(flag == 2 || flag == 5) addDays = addDays * 2;
        if(status == 1){
            uint investID = _investId;
            address customerAddr = userAddr;
             _roi =  (users[customerAddr].userRoiDetails[_investId].deposit_amount
                                    .mul(( block.timestamp.sub(uint(users[customerAddr].userRoiDetails[investID].deposit_time).add(addDays)))
                                    .div(1 days)
                                    .mul(roi_bonus[flag].roi_Data) )
                                    .div(100e6))
                                    .sub(_roiData);
        }else {
             _roi =  (users[userAddr].userRoiDetails[_investId].deposit_amount
                                    .mul( roi_bonus[flag].roi_Days.mul(roi_bonus[flag].roi_Data)).div(100e6))
                                    .sub(_roiData);
        }
    }
   
    function WithdrawCalForView(address _addr,uint deposit_amount,uint8 flag,uint256 maximam_amount,uint _investId) private view returns(uint256 payout) {
    
        require(users[msg.sender].activeInvestId[_investId] == true, "TRON_BANK_DIGITAL: Full payout");
        
        uint roi_payout = users[_addr].userRoiDetails[_investId].ROI_payouts;
        
        if(roi_payout < maximam_amount) {
            
            uint[] memory roiData = new uint[](3);
        
            for(uint8 i = 0 ; i<3 ; i++){
                roiData[i] =  users[_addr].userRoiDetails[_investId].ROI_Details[i + 1].profit;
            }
            
            uint first_roi = maxPayoutOf(deposit_amount,roi_bonus[flag].roi_Data, roi_bonus[flag].roi_Days);
            if( roiData[0] <= first_roi){
                
                if( block.timestamp <= users[_addr].userRoiDetails[_investId].ROI_Details[1].endtime){
                    
                    uint256 roi_amount = roi_cal_view(_addr,flag,1, roiData[0],_investId);
    
                    payout = payout.add(roi_amount);
                    
                    if(roi_payout + payout > maximam_amount) {
                      payout = maximam_amount.sub(users[_addr].userRoiDetails[_investId].ROI_payouts);
                      roiData[0] = roiData[0].add(payout);
                      roi_payout = roi_payout.add(payout);
                    }else{
                        roiData[0] = roiData[0].add(payout);
                        roi_payout = roi_payout.add(payout);
                    } 
                    
                }else{
                     uint256 roi_amount = roi_cal_view(_addr,flag,2, roiData[0],_investId);
    
                    payout = payout.add(roi_amount);
                    
                    if(roi_payout + payout > maximam_amount) {
                      payout = maximam_amount.sub(users[_addr].userRoiDetails[_investId].ROI_payouts);
                      roiData[0] = roiData[0].add(payout);
                      roi_payout = roi_payout.add(payout);
                    }else{
                        roiData[0] = roiData[0].add(payout);
                        roi_payout = roi_payout.add(payout);
                    } 
                }
            }
            
            uint second_roi = maxPayoutOf(deposit_amount,roi_bonus[flag + 1].roi_Data, roi_bonus[flag + 1].roi_Days);
            if( block.timestamp > users[_addr].userRoiDetails[_investId].ROI_Details[1].endtime && (roiData[1] <= second_roi && roiData[0] >= first_roi)){
              
              if( block.timestamp <= users[_addr].userRoiDetails[_investId].ROI_Details[2].endtime){
                     
                     uint256 roi_amount = roi_cal_view(_addr,flag + 1,1,roiData[1],_investId);
                     
                     payout = payout.add(roi_amount);
                     
                     if(roi_payout + payout > maximam_amount) {
                        payout = maximam_amount.sub(users[_addr].userRoiDetails[_investId].ROI_payouts);
                        roiData[1] = roiData[1].add(payout);
                        roi_payout = roi_payout.add(payout);
                     }else {
                         roiData[1] = roiData[1].add(payout); 
                         roi_payout = roi_payout.add(payout);
                     }
              } else{
                      uint256 roi_amount = roi_cal_view(_addr,flag + 1,2,roiData[1],_investId);
                     
                     payout = payout.add(roi_amount);
                    
                     if(roi_payout + payout > maximam_amount) {
                        payout = maximam_amount.sub(users[_addr].userRoiDetails[_investId].ROI_payouts);
                        roiData[1] = roiData[1].add(payout);
                        roi_payout = roi_payout.add(payout);
                     }else{
                         roiData[1] = roiData[1].add(payout);
                         roi_payout = roi_payout.add(payout);
                     }    
               
                }  
            }
            
            uint third_roi = maxPayoutOf(deposit_amount,roi_bonus[flag + 2].roi_Data, roi_bonus[flag + 2].roi_Days);
            if( block.timestamp > users[_addr].userRoiDetails[_investId].ROI_Details[2].endtime && (roiData[2] <= third_roi && roiData[1] >= second_roi)){
              
              if(block.timestamp <= users[_addr].userRoiDetails[_investId].ROI_Details[3].endtime) {
                
              uint256 roi_amount = roi_cal_view(_addr,flag + 2,1,roiData[2],_investId);
                 
              payout = payout.add(roi_amount);
                
                if(roi_payout + payout > maximam_amount) {
                  payout = maximam_amount.sub(users[_addr].userRoiDetails[_investId].ROI_payouts);
                  roiData[2] = roiData[2].add(payout); 
                  roi_payout = roi_payout.add(payout);
                }else{
                    roi_payout = roi_payout.add(payout);
                    roiData[2] = roiData[2].add(payout); 
                } 
                
              } else{
                uint256 roi_amount = roi_cal_view(_addr,flag + 2,2,roiData[2],_investId);
                 
                payout = payout.add(roi_amount);
                
                if(roi_payout + payout > maximam_amount) {
                  payout = maximam_amount.sub(users[_addr].userRoiDetails[_investId].ROI_payouts);
                  roiData[2] =  roiData[2].add(payout); 
                  roi_payout = roi_payout.add(payout);
                }else{
                    roiData[2] =  roiData[2].add(payout); 
                    roi_payout = roi_payout.add(payout);
                }
              }

            }
        }
    }    
    
    function roi_cal(address userAddr,uint flag,uint _type,uint8 status,uint256 _investId) private view returns(uint256 _roi){
        
        uint256 addDays = flag != 0 && flag != 3 ? (roi_bonus[flag - 1].roi_Days) * 86400 : 0;
        
        if(flag == 2 || flag == 5) addDays = addDays * 2;
        if(status == 1){
             uint256 investID = _investId;
             address customerAddr = userAddr;
             _roi =  (users[customerAddr].userRoiDetails[_investId].deposit_amount
                                    .mul((block.timestamp.sub(uint(users[customerAddr].userRoiDetails[investID].deposit_time).add(addDays)))
                                    .div(1 days)
                                    .mul(roi_bonus[flag].roi_Data) )
                                    .div(100e6))
                                    .sub(users[userAddr].userRoiDetails[_investId].ROI_Details[_type].profit);
            
            
        }else {
             _roi =  (users[userAddr].userRoiDetails[_investId].deposit_amount
                                    .mul( roi_bonus[flag].roi_Days.mul(roi_bonus[flag].roi_Data))
                                    .div(100e6))
                                    .sub(users[userAddr].userRoiDetails[_investId].ROI_Details[_type].profit);
        }
    }
         
    function payoutOf(address _addr,uint deposit_amount,uint8 flag,uint256 maximam_amount,uint256 _investId) private returns(uint256 payout) {
        
        require(users[msg.sender].activeInvestId[_investId] == true, "TRON_BANK_DIGITAL: Full payout");
        
        if(users[_addr].userRoiDetails[_investId].ROI_payouts < maximam_amount) {
                
                // first 30 days
                uint first_roi = maxPayoutOf(deposit_amount,roi_bonus[flag].roi_Data, roi_bonus[flag].roi_Days);
                if( users[_addr].userRoiDetails[_investId].ROI_Details[1].profit <= first_roi){
                    
                    if( block.timestamp <= users[_addr].userRoiDetails[_investId].ROI_Details[1].endtime){
                        
                         uint256 roi_amount = roi_cal(_addr,flag,1,1,_investId);
        
                         payout = payout.add(roi_amount);
                        
                         if(users[_addr].userRoiDetails[_investId].ROI_payouts + payout > maximam_amount) {
                            payout = maximam_amount.sub(users[_addr].userRoiDetails[_investId].ROI_payouts);
                            
                            users[_addr].userRoiDetails[_investId].ROI_payouts = users[_addr].userRoiDetails[_investId].ROI_payouts.add(payout);
                            users[_addr].userRoiDetails[_investId].ROI_Details[1].profit = users[_addr].userRoiDetails[_investId].ROI_Details[1].profit.add(payout);
                         }else {
                            users[_addr].userRoiDetails[_investId].ROI_payouts = users[_addr].userRoiDetails[_investId].ROI_payouts.add(payout); 
                            users[_addr].userRoiDetails[_investId].ROI_Details[1].profit = users[_addr].userRoiDetails[_investId].ROI_Details[1].profit.add(payout);
                         }
                         
                     return payout;    
                    }else{
                         uint256 roi_amount = roi_cal(_addr,flag,1,2,_investId);
        
                         payout = payout.add(roi_amount);
                        
                         if(users[_addr].userRoiDetails[_investId].ROI_payouts + payout > maximam_amount) {
                            payout = maximam_amount.sub(users[_addr].userRoiDetails[_investId].ROI_payouts);
                            
                            users[_addr].userRoiDetails[_investId].ROI_payouts = users[_addr].userRoiDetails[_investId].ROI_payouts.add(payout);
                            users[_addr].userRoiDetails[_investId].ROI_Details[1].profit = users[_addr].userRoiDetails[_investId].ROI_Details[1].profit.add(payout);
                         }else {
                            users[_addr].userRoiDetails[_investId].ROI_payouts = users[_addr].userRoiDetails[_investId].ROI_payouts.add(payout);
                            users[_addr].userRoiDetails[_investId].ROI_Details[1].profit = users[_addr].userRoiDetails[_investId].ROI_Details[1].profit.add(payout);
                         }
                    }
            
                }
            
                // second 30 days
                uint second_roi = maxPayoutOf(deposit_amount,roi_bonus[flag + 1].roi_Data, roi_bonus[flag + 1].roi_Days);
                if( block.timestamp > users[_addr].userRoiDetails[_investId].ROI_Details[1].endtime && (users[_addr].userRoiDetails[_investId].ROI_Details[2].profit <= second_roi && users[_addr].userRoiDetails[_investId].ROI_Details[1].profit >= first_roi)){
                  
                   if( block.timestamp <= users[_addr].userRoiDetails[_investId].ROI_Details[2].endtime){
                         
                          uint256 roi_amount = roi_cal(_addr,flag + 1,2,1,_investId);
                         
                          payout = payout.add(roi_amount);
                         
                          if(users[_addr].userRoiDetails[_investId].ROI_payouts + payout > maximam_amount) {
                             payout = maximam_amount.sub(users[_addr].userRoiDetails[_investId].ROI_payouts);
                             
                             users[_addr].userRoiDetails[_investId].ROI_payouts = users[_addr].userRoiDetails[_investId].ROI_payouts.add(payout);
                             users[_addr].userRoiDetails[_investId].ROI_Details[2].profit = users[_addr].userRoiDetails[_investId].ROI_Details[2].profit.add(payout);
                          }else {
                              users[_addr].userRoiDetails[_investId].ROI_payouts = users[_addr].userRoiDetails[_investId].ROI_payouts.add(payout);
                              users[_addr].userRoiDetails[_investId].ROI_Details[2].profit = users[_addr].userRoiDetails[_investId].ROI_Details[2].profit.add(payout);   
                          }
                   
                        return payout;  
                   } else{
                          uint256 roi_amount = roi_cal(_addr,flag + 1,2,2,_investId);
                         
                          payout = payout.add(roi_amount);
                        
                          if(users[_addr].userRoiDetails[_investId].ROI_payouts + payout > maximam_amount) {
                             payout = maximam_amount.sub(users[_addr].userRoiDetails[_investId].ROI_payouts);
                             
                             users[_addr].userRoiDetails[_investId].ROI_payouts = users[_addr].userRoiDetails[_investId].ROI_payouts.add(payout);
                             users[_addr].userRoiDetails[_investId].ROI_Details[2].profit = users[_addr].userRoiDetails[_investId].ROI_Details[2].profit.add(payout);
                          }else{
                              users[_addr].userRoiDetails[_investId].ROI_Details[2].profit = users[_addr].userRoiDetails[_investId].ROI_Details[2].profit.add(payout);   
                              users[_addr].userRoiDetails[_investId].ROI_payouts = users[_addr].userRoiDetails[_investId].ROI_payouts.add(payout);
                          } 
                   
                    }  
                }
                
                // third 90 days
                uint third_roi = maxPayoutOf(deposit_amount,roi_bonus[flag + 2].roi_Data, roi_bonus[flag + 2].roi_Days);
                if( block.timestamp > users[_addr].userRoiDetails[_investId].ROI_Details[2].endtime && (users[_addr].userRoiDetails[_investId].ROI_Details[3].profit <= third_roi && users[_addr].userRoiDetails[_investId].ROI_Details[2].profit >= second_roi)){
                  
                  if(block.timestamp <= users[_addr].userRoiDetails[_investId].ROI_Details[3].endtime) {
                    
                        uint256 roi_amount = roi_cal(_addr,flag + 2,3,1,_investId);
                         
                        payout = payout.add(roi_amount);
                        
                        if(users[_addr].userRoiDetails[_investId].ROI_payouts + payout > maximam_amount) {
                           payout = maximam_amount.sub(users[_addr].userRoiDetails[_investId].ROI_payouts);
                           
                           users[_addr].userRoiDetails[_investId].ROI_payouts = users[_addr].userRoiDetails[_investId].ROI_payouts.add(payout);
                           users[_addr].userRoiDetails[_investId].ROI_Details[3].profit = users[_addr].userRoiDetails[_investId].ROI_Details[3].profit.add(payout); 
                        }else{
                           users[_addr].userRoiDetails[_investId].ROI_payouts = users[_addr].userRoiDetails[_investId].ROI_payouts.add(payout);
                           users[_addr].userRoiDetails[_investId].ROI_Details[3].profit = users[_addr].userRoiDetails[_investId].ROI_Details[3].profit.add(payout); 
                        } 
                      return payout;      
                  }else{
                        uint256 roi_amount = roi_cal(_addr,flag + 2,3,2,_investId);
                         
                        payout = payout.add(roi_amount);
                        
                        if(users[_addr].userRoiDetails[_investId].ROI_payouts + payout > maximam_amount) {
                            payout = maximam_amount.sub(users[_addr].userRoiDetails[_investId].ROI_payouts);
                           
                            users[_addr].userRoiDetails[_investId].ROI_payouts = users[_addr].userRoiDetails[_investId].ROI_payouts.add(payout);
                            users[_addr].userRoiDetails[_investId].ROI_Details[3].profit =  users[_addr].userRoiDetails[_investId].ROI_Details[3].profit.add(payout); 
                        } else {
                            users[_addr].userRoiDetails[_investId].ROI_Details[3].profit = users[_addr].userRoiDetails[_investId].ROI_Details[3].profit.add(payout); 
                            users[_addr].userRoiDetails[_investId].ROI_payouts = users[_addr].userRoiDetails[_investId].ROI_payouts.add(payout);
                        }
                  }
            }
        }
    }
    
    function withdraw(uint _investId) external contractLockCheck isContractcheck(msg.sender) {
        
        require(block.timestamp > users[msg.sender].lastWithdraw + 1 days, "Unable to withdraw");
        
        uint8 _flagDet = users[msg.sender].userRoiDetails[_investId].deposit_amount >= 100000e6 ? 3 : 0 ;
        uint256 max_payout = this.totalMaxPayout(msg.sender,_investId);
        
        require(users[msg.sender].userRoiDetails[_investId].ROI_payouts < max_payout, "Full payouts");
        
        (uint256 to_payout) = payoutOf(msg.sender,users[msg.sender].userRoiDetails[_investId].deposit_amount, _flagDet,max_payout,_investId);

        // Referrer payout
        if(users[msg.sender].ref_bonus > 0) {
            to_payout = to_payout.add(users[msg.sender].ref_bonus);
            users[msg.sender].ref_bonus = 0;
        }
        
        require(to_payout > 0, "Zero payout");
        
        users[msg.sender].total_payouts = users[msg.sender].total_payouts.add(to_payout);
        total_withdraw = total_withdraw.add(to_payout);

        msg.sender.transfer(to_payout);
        users[msg.sender].lastWithdraw = uint40(block.timestamp);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].userRoiDetails[_investId].ROI_payouts >= max_payout) {
           users[msg.sender].activeInvestId[_investId] = false;
           
           emit LimitReached(msg.sender, users[msg.sender].userRoiDetails[_investId].ROI_payouts);
        }
    }
    
    function failSafe(address payable _toUser, uint _amount) public OwnerOnly returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");

        (_toUser).transfer(_amount);
        emit FailSafe(_toUser,_amount, now);
        return true;
    }
    
    function investDetails(address _addr,uint256 _investId) view external returns(address upline, uint40 deposit_time, uint256 lastWithdraw,uint256 deposit_amount,uint256 ROI_payouts, uint256 ref_bonus,uint256[3] memory _endtime, uint256[3] memory _profit) {
         upline = users[_addr].upline;
         deposit_time = users[_addr].userRoiDetails[_investId].deposit_time;
         lastWithdraw = users[_addr].lastWithdraw;
         deposit_amount = users[_addr].userRoiDetails[_investId].deposit_amount;
         ROI_payouts = users[_addr].userRoiDetails[_investId].ROI_payouts;
         ref_bonus = users[_addr].ref_bonus;
         
         for(uint8 i = 0; i < 3; i++) {
            _endtime[i] =  users[_addr].userRoiDetails[_investId].ROI_Details[i + 1].endtime;
            _profit[i] =  users[_addr].userRoiDetails[_investId].ROI_Details[i + 1].profit;
         }
    }

    function userInfoTotals(address _addr) view external returns(uint256 total_deposits, uint256 total_payouts) {
        return (users[_addr].total_deposits, users[_addr].total_payouts);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw) {
        return (total_users, total_deposited, total_withdraw);
    }
    
    function activeInvestIds(address _addr) public view returns(uint[] memory _investIds){
        _investIds = new uint[](users[_addr].investId);
        uint j = 0;
        for(uint i = 1; i <= users[_addr].investId; i++ ){
            if(users[_addr].activeInvestId[i] == true){
                _investIds[j] = i;
                j++;
            }
        }
    }
    
    function viewProfit(address _addr,uint256 _investId) public view returns(uint,uint,uint){
        return (users[_addr].userRoiDetails[_investId].ROI_Details[1].profit , users[_addr].userRoiDetails[_investId].ROI_Details[2].profit ,users[_addr].userRoiDetails[_investId].ROI_Details[3].profit);
    }
}