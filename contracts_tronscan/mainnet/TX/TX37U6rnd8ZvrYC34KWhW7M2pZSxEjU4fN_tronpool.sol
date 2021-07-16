//SourceUnit: con_aaa.sol

pragma solidity 0.5.10;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
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
interface Voyage {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) ;
    function balanceOf(address account) external view returns (uint256) ;
}

contract tronpool {

    using SafeMath for uint256;

    uint256 private project_start;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    Voyage  constant private voyage = Voyage(0x3C6f24C1131cf9fD38fA47b25Ffc28492eCf6D83);
    address payable constant private token_owner = 0xA651ea384181481032a1e7f43dE27DaCEa37aeaf;
    address payable constant private root = 0xdb955301fFc8671D302299117e647856aea439aa;
    address payable constant private withdraw_fee = 0x7A8052eB4BE7D3e196E35Be82ED0ce4F1C568433;
    address payable constant private admin_fee = 0x6c4dD4365e27D0E44F2cB0eda355a9E8EEE3fFC2;
    uint256 public assign_weights = 0;
    uint256[16] public investment_grades;
    uint8 private activeLevel = 5;
    uint8 public highestLevelCount = 0;
    uint32 public totalUsers;
    uint16 constant public block_step = 25;
    uint184 public distribute = 5;
    uint8 public calculation = 5;

    struct Deposit {
        uint8 level;
        uint248 start;
		uint128 withdrawn;
        uint128 bonus;
    }

	struct User {
        uint256  deposit_count;
	    uint24[16] user_grade_count;
		Deposit[] deposits;
		address referrer;
		uint256 withdrawn;
		uint256 spot; 
		uint256 bonus; 
	    uint256 deposits_amount;
	}

	mapping (address => User) public users;
    mapping (uint32 => address) userAddrs;

	event NewDeposit(address indexed user,address indexed referrer, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
    event Withdrawn_fee(address indexed user, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event _out(address indexed user,uint256 amount);
	event _bonus(address indexed user, uint256 amount);
	event token_transfer(address indexed f, address indexed t,uint256 amount);

   constructor()public{

	    User storage user = users[root];
	    totalUsers = 0;
	    user.deposits.push(Deposit(0,uint248(block.number),0,0));
	    project_start = block.number;
	    investment_grades[0] = 3 trx;
        investment_grades[1] = 9 trx;
        investment_grades[2] = 18 trx;
        investment_grades[3] = 30 trx;
        investment_grades[4] = 45 trx;
        investment_grades[5] = 63 trx;
        investment_grades[6] = 84 trx;
        investment_grades[7] = 108 trx;
        investment_grades[8] = 135 trx;
        investment_grades[9] = 165 trx;
        investment_grades[10] = 198 trx;
        investment_grades[11] = 234 trx;
        investment_grades[12] = 273 trx;
        investment_grades[13] = 315 trx;
        investment_grades[14] = 360 trx;
        investment_grades[15] = 408 trx;

	}

   function() payable external {

	    require(tx.origin == msg.sender,"Not contract");
        _deposit(root,msg.sender, msg.value,1);

    }

   function deposit(address referrer, uint8 level) payable external {

       require(tx.origin == msg.sender);
       if(referrer == address(0)){
          _deposit(root,msg.sender,msg.value,level);
       }else{
          _deposit(referrer,msg.sender,msg.value,level);
       }

   }

   function withdraw() public {

        require(tx.origin == msg.sender,"Not contract");
        if(address(this).balance <= totalInvested.div(50)){
             _termination();
        }else{
           User storage user = users[msg.sender];
           require(user.deposits.length>0,'User has no dividends');
           uint256 amount = 0;
           for(uint256 i = 0; i < user.deposits.length; i++){
              uint256 dividends = calculationDividends(user.deposits[i],msg.sender == root);
              if(dividends > user.deposits[i].withdrawn){
                  user.deposits[i].start = uint128(block.number);
                  user.deposits[i].bonus = 0;
                  uint256 draw = dividends.sub(user.deposits[i].withdrawn);
                  user.deposits[i].withdrawn = uint128(dividends);
                  amount = amount.add(draw);
              }
            }

            require(amount > 0,"No balance to withdraw");
            user.withdrawn = user.withdrawn.add(amount);
            _transfer(amount,msg.sender);
            emit Withdrawn(msg.sender,amount);
        }

   }

   function out() public {
       
        if(address(this).balance <= totalInvested.div(50)){
             _termination();
        }else{
           require(tx.origin == msg.sender && msg.sender != root,"super");
           User storage user = users[msg.sender];
           require(user.deposits.length > 0,"No deposit to check out");
           uint8 count = 0;
           for(uint256 i = 0; i < user.deposits.length; i++){
                uint256 dividends = calculationDividends(user.deposits[i],msg.sender == root);
                uint256 amount = investment_grades[user.deposits[i].level];
                uint256 most = amount.mul(23).div(10);
                if(dividends >= most){
                   count++;
                   uint256 send = most.sub(user.deposits[i].withdrawn);
        
                   if(send > 0){
                       user.withdrawn = user.withdrawn.add(send);
                       _transfer(send,msg.sender);
                   }
                   emit _out(msg.sender,amount);
                }
            }
        
           if(count > 0){
               if(count == user.deposits.length){
                 delete user.deposits;
               }else{
                 user.deposits[0] = user.deposits[1];
                 delete user.deposits[1];
                 user.deposits.length--;
               }
           } 
        }

   }

   function _transfer(uint256 amount,address payable receive) private {

       uint256 last = totalInvested.div(50);
       require(last < address(this).balance,"Insufficient Balance");
       if(amount.add(last) > address(this).balance){
           amount = address(this).balance.sub(last);
       }
       receive.transfer(amount.mul(87).div(100));
       withdraw_fee.transfer(amount.sub(amount.mul(87).div(100)));
       emit Withdrawn_fee(withdraw_fee,amount.mul(13).div(100));
       uint256 balance = voyage.balanceOf(token_owner);
       uint256 ta = amount.mul(13).div(10000);
       if(balance < ta){
           ta = balance;
       }
       require(voyage.transferFrom(token_owner,receive,ta),"token transfer fail");
       emit token_transfer(token_owner,receive,ta);
       totalWithdrawn = totalWithdrawn.add(amount);

   }

   function _deposit(address referrer,address addr, uint256 amount, uint8 level) private {

        
       require(totalInvested == 0 || address(this).balance.sub(amount) > totalInvested.div(50),"project is stop");
       require(!isContract(addr),"Not contract");
       require(addr != root,"super");
       User storage user = users[addr];
       uint8 grade = activeGrades();
       if(grade > activeLevel){
           activeLevel = grade;
           highestLevelCount = 0;
       }
       require( level > 0 && level-1 <= grade,"Invalid investment grade");
       require(investment_grades[level-1] == amount,"Unmatched amount");
       if(level-1 < grade){
           require(user.user_grade_count[level-1] < 3,"Investment grade beyond limit");
       }
       require(user.deposits.length < 2,"Twice at most");
       if(user.referrer == address(0)){

           if(referrer != root){
               require(users[referrer].referrer != address(0), "recommender does not exist");
           }
           user.referrer = referrer;
           uint32 mod =  totalUsers % 100;
           userAddrs[mod] = msg.sender;
           totalUsers ++;
       }
       user.user_grade_count[level-1] = user.user_grade_count[level-1] + 1;
       user.deposits.push(Deposit(level-1,uint248(block.number),0,0));
       user.deposits_amount = amount.add(user.deposits_amount);
       user.deposit_count = user.deposit_count + 1;
       emit NewDeposit(msg.sender,referrer,amount);
       referrer = user.referrer;
       totalInvested = totalInvested.add(amount);
       uint8 count_spot = 0;
       uint256 pot = amount.mul(6).div(2000);
       address up = referrer;
       while(up != address(0) && count_spot < 20){

           User storage user_referrer = users[up];
           uint256 award = 0;
           if(count_spot < level){
                uint256 effective = effectiveQuota(up);
                if(effective >= investment_grades[count_spot]){
                   award = award.add(uint256(count_spot+1).mul(3 trx).mul(6).div(10));
                }
            }
           uint256 spot = pot;
           if(award.add(spot) > 0){
                if(user_referrer.deposits.length > 1){
                             uint256 dividends =  calculationDividends(user_referrer.deposits[0],up == root);
                             uint256 dep_amount = investment_grades[user_referrer.deposits[0].level];
                             uint256 most = dep_amount.mul(23).div(10);
                             if(dividends.add(award).add(spot) < most){
                                user_referrer.deposits[0].bonus = uint128(user_referrer.deposits[0].bonus+award);
                                user_referrer.deposits[0].withdrawn = uint128(user_referrer.deposits[0].withdrawn+spot);
                                user_referrer.spot = user_referrer.spot.add(spot);
                                toPayAble(up).transfer(spot);
                             }else {
                                
                                if(dividends.add(award) >= most){
                                     uint256 send = most.sub(user_referrer.deposits[0].withdrawn);

                                    if(send > 0){
                                        user_referrer.withdrawn = user_referrer.withdrawn.add(send);
                                       _transfer(send,toPayAble(up));
                                     }
                                    award = award.add(dividends).sub(most);
                                }else{
                                    if(award > 0){
                                        user_referrer.withdrawn = user_referrer.withdrawn.add(award);
                                       _transfer(award,toPayAble(up));
                                    }
                                    spot = dividends.add(award).add(spot).sub(most);
                                    award = 0;

                                }
                                user_referrer.deposits[0] = user_referrer.deposits[1];
                                delete user_referrer.deposits[1];
                                user_referrer.deposits.length --;
                                emit _out(up,dep_amount);
                             }
                    }

                 if(user_referrer.deposits.length == 1){

                        if(award.add(spot) > 0){
                            uint256 dividends = calculationDividends(user_referrer.deposits[0],up == root);
                            uint256 dep_amount = investment_grades[user_referrer.deposits[0].level];
                             uint256 most = dep_amount.mul(23).div(10);
                             if(up == root || dividends.add(award).add(spot) < most){
                                user_referrer.deposits[0].bonus = uint128(user_referrer.deposits[0].bonus+award);
                                user_referrer.deposits[0].withdrawn = uint128(user_referrer.deposits[0].withdrawn+pot);
                                user_referrer.spot = user_referrer.spot.add(pot);
                                toPayAble(up).transfer(pot);
                             }else{
                               if(dividends.add(award) >= most){
                                    uint256 send = most.sub(user_referrer.deposits[0].withdrawn);

                                    if(send > 0){
                                        user_referrer.withdrawn = user_referrer.withdrawn.add(send);
                                       _transfer(send,toPayAble(up));
                                    }
                               }else{
                                   if(award > 0){
                                        user_referrer.withdrawn = user_referrer.withdrawn.add(award);
                                       _transfer(award,toPayAble(up));
                                   }
                                   spot = pot.sub(dividends.add(award).add(spot).sub(most));
                                   if(spot > 0){
                                     user_referrer.spot = user_referrer.spot.add(spot);
                                     toPayAble(up).transfer(spot);

                                   }

                               }
                                emit _out(up,dep_amount);
                                delete user_referrer.deposits;
                             }
                        }
                }

            }
            count_spot ++;
            up = user_referrer.referrer;
       }
       
       if(count_spot < 20){
           uint256 t = pot.mul(20 - count_spot);
           toPayAble(root).transfer(t);
       }
       admin_fee.transfer(amount.mul(4).div(100));
       emit FeePayed(admin_fee,amount.mul(3).div(100));
       if(level-1 == activeLevel && highestLevelCount < 50 ){
           uint256 award = address(this).balance.div(2000);
           user.bonus = user.bonus.add(award);
           msg.sender.transfer(award);
           highestLevelCount ++;
           emit _bonus(msg.sender,award);
       }
       

   }

   function calculationDividends(Deposit memory dep,bool isRoot) private view returns(uint256){

       if(isRoot){
          return dep.bonus+dep.withdrawn;
       }
       uint256 result = 0;
       uint256 amount = investment_grades[dep.level];
       if(dep.start > project_start){
           result = dep.bonus+dep.withdrawn;
           uint256 step = block.number.sub(dep.start).div(block_step);
           uint256 base = 11 + dep.level;  
           uint256 mod = step.mod(base.sub(1));
           mod = mod.mul(mod.add(1));
           uint256 c = step.div(base.sub(1)).mul(base.mul(base.sub(1)));
          
           result = result.add(mod.add(c).mul(amount).div(2000));
       }
       uint256 most = amount.mul(23).div(10);
       if(result > most ){
           result = most;
       }
        return result;

   }

   function effectiveQuota(address addr) private view returns(uint256){
       
       if(addr == root){
           return 408000 trx;
       }
        uint256 result = 0;
        User memory user = users[addr];

        if(user.deposits.length == 0){
          return result;
        }

       for(uint256 i = 0; i < user.deposits.length; i++){
           uint256 dividends = calculationDividends(user.deposits[i],addr == root);
           uint256 amount = investment_grades[user.deposits[i].level];
           uint256 most = amount.mul(23).div(10);
           if(amount > result && dividends < most){
              result = amount;
           }
        }

        return result;

   }

   function _termination() private {
        uint256 balance = address(this).balance;
        require(balance>0 && balance <= totalInvested.div(50),"fail");
        if(calculation >0){
                uint8 start = uint8(20*(5-calculation));
                uint8 end = start + 20;
            
                uint256 total = 0;
                for(uint8 i=start;i<end;i++){
                     uint256 effectiv = achievement(userAddrs[i]);
                     if(effectiv > 0){
                      total = total.add(effectiv);
                     }
                } 
                calculation = calculation - 1;
                assign_weights =assign_weights.add(total);
            }else{
               
               require(distribute > 0,"fail");
                uint8 start = uint8(20*(5-distribute));
                uint8 end = start + 20;
               for(uint8 i=start;i<end;i++){
                     uint256 effectiv = achievement(userAddrs[i]);
                     if(effectiv > 0){
                      uint256 amount = totalInvested.div(50).mul(effectiv).div(assign_weights);     
                      toPayAble(userAddrs[i]).transfer(amount.mul(87).div(100));
                      require(voyage.transferFrom(token_owner,userAddrs[i],amount.mul(13).div(10000)),"token transfer fail");
                     }

                }
                 distribute = distribute - 1;
                 if(distribute == 0){
                     withdraw_fee.transfer(address(this).balance); 
                }
            }
    }

   function achievement(address addr) private view returns(uint256 amount){
       User memory user = users[addr];
       if(user.deposits.length > 0){
           for(uint8 i = 0; i < user.deposits.length; i++){
            uint256 dividends = calculationDividends(user.deposits[i],addr == root);
            uint256 dep_amount = investment_grades[user.deposits[i].level];
             if(dividends < dep_amount.mul(23).div(10)){
                 amount = dep_amount.add(amount);
             }
           }
       }
   }

   function toPayAble(address addr) private pure returns(address payable){

        return address(uint160(addr));

    }

   function isContract(address addr) internal view returns (bool) {

        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;

    }

   function poolInfo()external view returns(uint256 balance,uint256 totalInvest,uint256 blockNumber){

        return(address(this).balance,totalInvested,block.number);

   }

   function userInfo(address addr) external view returns(uint256 spot,uint256 investAmount,uint256[2] memory amounts,uint256[2] memory dividends,uint256[2] memory staticRate,uint256 bonus){

         User memory user = users[addr];
         spot = user.spot;
         bonus = user.bonus;
         if(user.deposits.length > 0){
            for(uint256 i = 0; i < user.deposits.length; i++){
              amounts[i] = investment_grades[user.deposits[i].level];
              dividends[i] = calculationDividends(user.deposits[i],addr == root);
              investAmount = investAmount.add(investment_grades[user.deposits[i].level]);
              uint256 step = block.number.sub(user.deposits[i].start).div(block_step);
            if(step < 1){
                staticRate[i] = 0;
            }else{
                staticRate[i] = step.mod(uint256(user.deposits[i].level+10));
                if(staticRate[i] == 0)
                  staticRate[i] = user.deposits[i].level + 10;
                }
            }  
         }
   }

   function userDespositGrade(address addr) external view returns(uint24[16] memory user_grade_count,uint8  activeGrade){

        user_grade_count = users[addr].user_grade_count;
        activeGrade = activeGrades();

   }

   function activeGrades() public view returns(uint8){

        uint256 result = block.number.sub(project_start).div(uint256(block_step).mul(30));
    	if(result < 1){
    	    return 4;
    	}else if(result>14){
    	    return 15;
    	}else{
    	    return (uint8)(result.add(4));
    	}

   }

   function userFinance(address addr) external view returns(uint256 totalIncome,uint256 tokenTotalIncome,uint256 balance,uint256 tokenBalance){

        User memory user = users[msg.sender];
        uint256 b = 0;
        if(users[addr].deposits.length > 0){
            for(uint256 i = 0; i < user.deposits.length; i++){
                uint256 dividends = calculationDividends(user.deposits[i],addr == root);
                if(dividends > user.deposits[i].withdrawn){
                    b = dividends.add(b).sub(user.deposits[i].withdrawn);
                }
            }
        }
        totalIncome = user.withdrawn.add(b).mul(87).div(100);
        tokenTotalIncome = user.withdrawn.add(b).mul(13).div(10000);
        if(b > 0){
            balance = b.mul(87).div(100);
            tokenBalance = b.mul(13).div(10000);
        }

   }

   function hasToOut(address  addr) external view returns(bool){

        bool result = false;
        User memory user = users[addr];
        if(addr == root || user.deposits.length == 0){
            return result;
        }
        for(uint256 i = 0; i < user.deposits.length; i++){
            uint256 dividends = calculationDividends(user.deposits[i],addr == root);
            uint256 most = investment_grades[user.deposits[i].level].mul(23).div(10);
            if(dividends >= most){
                result = true;
                break;
            }
        }
        return result;

   }
   
   function kill() public{
       selfdestruct(msg.sender);
   }

}