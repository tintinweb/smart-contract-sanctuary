//SourceUnit: Klein.sol

pragma solidity >=0.4.22 <0.7.0;
/// @title KleinGame
contract Klein {
    struct Player{
        address payable addr;
        address payable recommender_addr;
        uint256 amount;//total deposit
        uint256 prepare_balance;
        uint256 released_amount;
        uint256 static_in_released_amount;
        uint256 total_released;
        uint last_ts;
        uint last_days;
        uint is_cvip;
        uint256 burn_amount;
        uint cvip_num;
        uint recommend_num;
        uint256 wait_award;
    }
    uint firstDepositTS;
    address[] public addressIndices;
    //all players
    mapping(address => Player) public players;
    
    //seven admin
    address payable admin1_27;
    address payable admin2_14_5;
    address payable admin3_14_5;
    address payable admin4_14_5;
    address payable admin5_14_5;
    address payable admin6_5;
    address payable admin7_5;
    address payable admin8_5;
    address payable insure_address;
    
    address contract_owner;
    
    uint256 history_top_balance;
    uint256 total_balance;
    uint256 insure_balance;
    uint256 top_award_balance_1;
    uint256 top_award_balance_7;

    uint constructor_ts;
    uint day_in_low_release;
    uint s;
    
    constructor(address payable admin1_addr,
                address payable admin2_addr,
                address payable admin3_addr,
                address payable admin4_addr,
                address payable admin5_addr,
                address payable admin6_addr,
                address payable admin7_addr,
                address payable admin8_addr,
        address payable insure_addr) payable public{
        if(contract_owner!=address(0)){
            return;
        }
        contract_owner=msg.sender;
        insure_address=insure_addr;
        admin1_27=admin1_addr;
        admin2_14_5=admin2_addr;
        admin3_14_5=admin3_addr;
        admin4_14_5=admin4_addr;
        admin5_14_5=admin5_addr;
        admin6_5=admin6_addr;
        admin7_5=admin7_addr;
        admin8_5=admin8_addr;
        history_top_balance=0;
        total_balance=0;
        s=1000000;
        insure_balance=0;
        top_award_balance_1=0;
        top_award_balance_7=0;
        constructor_ts=now;
        day_in_low_release=0;
    }
    
    function globalinfo() public view returns(uint256 _history_top_balance,uint256 _total_balance,uint256 _insure_balance,uint256 _top_award_balance_1,uint256 _top_award_balance_7,uint _total_address){
        _history_top_balance = history_top_balance;
        _total_balance = total_balance;
        _insure_balance = insure_balance;
        _top_award_balance_1 = top_award_balance_1;
        _top_award_balance_7 = top_award_balance_7;
        _total_address=addressIndices.length;
    }
    function myinfo() public view returns (address addr,uint amount,uint prepare_balance,
    uint released_amount,uint total_released,uint last_ts,uint last_days,uint is_cvip,uint burn_amount,uint cvip_num,uint recommend_num,uint wait_award){
        addr = players[msg.sender].recommender_addr;
        amount = players[msg.sender].amount;
        prepare_balance = players[msg.sender].prepare_balance;
        released_amount=players[msg.sender].released_amount;
        total_released=players[msg.sender].total_released;
        last_ts=players[msg.sender].last_ts;
        last_days=players[msg.sender].last_days;
        is_cvip=players[msg.sender].is_cvip;
        burn_amount=players[msg.sender].burn_amount;
        cvip_num=players[msg.sender].cvip_num;
        recommend_num=players[msg.sender].recommend_num;
        wait_award=players[msg.sender].wait_award;
        //team_num=teams[msg.sender].num;
        //team_amount=teams[msg.sender].amount;
    }
    //coin => contract
    event Deposit(address indexed recommender_addr, uint _value);
    function deposit(address payable recommender_addr) public payable returns (uint256){
        /*require(
            players[msg.sender].amount==0,
            "Already Deposited."
        );*/
        require(
            msg.sender!=recommender_addr,
            "Can not recommend self."
        );
        require(
            msg.value >= 1000 * s,
            "Deposit amount at least 1000RTX."
        ); 
        //updateTeam(recommender_addr,msg.value,players[msg.sender].addr==address(0));
        if(players[msg.sender].addr==address(0)){
            addressIndices.push(msg.sender);
        }
        //91% => contract balance
        total_balance+=msg.value*91/100;
        //2% => insure balance
        insure_balance+=msg.value*2/100;
        insure_address.transfer(msg.value*2/100);
        //1% => award for day
        top_award_balance_1+=msg.value*1/100;
        //1% => award for week
        top_award_balance_7+=msg.value*1/100;
        
        uint256 admin_amount=msg.value*5/100;
        admin1_27.transfer(admin_amount*27/100);
        admin2_14_5.transfer(admin_amount*29/2/100);
        admin3_14_5.transfer(admin_amount*29/2/100);
        admin4_14_5.transfer(admin_amount*29/2/100);
        admin5_14_5.transfer(admin_amount*29/2/100);
        admin6_5.transfer(admin_amount*5/100);
        admin7_5.transfer(admin_amount*5/100);
        admin8_5.transfer(admin_amount*5/100);
        if(history_top_balance<total_balance){
            history_top_balance=total_balance;
        }
        players[msg.sender].addr=msg.sender;
        //players[msg.sender].amount=msg.value*91/100;
        players[msg.sender].amount+=msg.value;
        //players[msg.sender].prepare_balance+=msg.value*91/100*getMulit2()/2;
        players[msg.sender].prepare_balance+=msg.value*getMulit2()/2;
        players[msg.sender].last_ts=now;
        players[msg.sender].last_days=0;
        //send award when first time deposited.
        if(recommender_addr!=address(0) && players[msg.sender].amount==msg.value){
            sendDepositAward(msg.value*9/100,recommender_addr);
            players[msg.sender].recommender_addr=recommender_addr;
            players[recommender_addr].recommend_num++;
            emit Deposit(recommender_addr, msg.value);
        }
        if(players[msg.sender].wait_award>0){
            if(players[msg.sender].prepare_balance>=players[msg.sender].wait_award){
                players[msg.sender].prepare_balance-=players[msg.sender].wait_award;
                players[msg.sender].released_amount+=players[msg.sender].wait_award;
                players[msg.sender].wait_award=0;
            }   
            else{
                players[msg.sender].wait_award-=players[msg.sender].prepare_balance;
                players[msg.sender].released_amount+=players[msg.sender].prepare_balance;
                players[msg.sender].prepare_balance=0;
            }
        }
        //clean static account
        return release_award(msg.sender);
    }
    function withdraw_without_award(address payable player_address) public returns(uint) {
        require(
            msg.sender==contract_owner,
            "Only contract owner can calling this function."
        );
        require(
            players[player_address].released_amount>0,
            "Not enough balance."
        );
        uint256 draw_amount;
        uint cvip_value=100000*getReleasePrecent10()/10;
        uint normal_value=50000*getReleasePrecent10()/10;
        if(players[player_address].is_cvip==1){
            if(players[player_address].released_amount>cvip_value*s){
                draw_amount=cvip_value*s;
            }
            else{
                draw_amount=players[player_address].released_amount;
            }
        }
        else{
            if(players[player_address].released_amount>normal_value*s){
                draw_amount=normal_value*s;
            }
            else{
                draw_amount=players[player_address].released_amount;
            }
        }
        
        uint256 amount_=draw_amount*90/100;
        player_address.transfer(amount_);
        players[player_address].released_amount-=draw_amount;
        total_balance-=draw_amount*93/100;
        insure_balance+=draw_amount*3/100;
        insure_address.transfer(draw_amount*3/100);
        //clean static accountv
        return 1;
    }
    function withdraw() public returns(uint) {
        require(
            players[msg.sender].released_amount>0,
            "Not enough balance."
        );
        uint256 draw_amount;
        uint cvip_value=100000*getReleasePrecent10()/10;
        uint normal_value=50000*getReleasePrecent10()/10;
        if(players[msg.sender].is_cvip==1){
            if(players[msg.sender].released_amount>cvip_value*s){
                draw_amount=cvip_value*s;
            }
            else{
                draw_amount=players[msg.sender].released_amount;
            }
        }
        else{
            if(players[msg.sender].released_amount>normal_value*s){
                draw_amount=normal_value*s;
            }
            else{
                draw_amount=players[msg.sender].released_amount;
            }
        }
        
        uint256 amount_=draw_amount*90/100;
        msg.sender.transfer(amount_);
        players[msg.sender].released_amount-=draw_amount;
        total_balance-=draw_amount*93/100;
        insure_balance+=draw_amount*3/100;
        insure_address.transfer(draw_amount*3/100);
        //clean static accountv
        return release_award(msg.sender);
    }
    function release_award(address addr) private returns(uint){
        uint256 amount=players[addr].static_in_released_amount;
        if(amount<=0){
            return 0;
        }
        uint loopnum=0;
        
        //manager award
        Player memory current_user=players[addr];
        address prev_addr=current_user.recommender_addr;
        for(uint i=1;i<=21;i++){
            if(prev_addr==address(0)){
                break;
            }
            current_user=players[prev_addr];
            if(current_user.recommend_num>=getNumRequest(i)){
                sendManagerAward(amount*getManagerAwardPrecent(i)/100,prev_addr);
            }
            prev_addr=current_user.recommender_addr;
            loopnum++;
        }
        release_cvip_award(addr);
    }
    
    function release_cvip_award(address addr) public returns (uint){
        address prev_addr;
        uint loopnum=0;
        uint256 amount=players[addr].static_in_released_amount;
        if(amount==0){
            return 0;
        }
        players[addr].static_in_released_amount=0;
        Player memory current_user=players[addr];
        current_user=players[addr];
        prev_addr=current_user.recommender_addr;
        uint256 award_released=0;
        uint precent;
        uint256 amount_cvip_award;
        uint256 amount_cvip_award_left;
        while(true){
            if(prev_addr==address(0)){
                break;
            }
            current_user=players[prev_addr];
            if(current_user.is_cvip!=1){
                prev_addr=current_user.recommender_addr;
                loopnum++;
                continue;
            }
            precent=getCVIPAwardPrecent(current_user.cvip_num);
            amount_cvip_award=amount*precent/100;
            amount_cvip_award_left=amount_cvip_award-award_released;
            if(amount_cvip_award_left<=0){
                prev_addr=current_user.recommender_addr;
                loopnum++;
                continue;
            }
            sendCVIPAward(amount_cvip_award_left,prev_addr);
            award_released+=amount_cvip_award_left;
            if(award_released>=amount*16/100){
                break;
            }
            prev_addr=current_user.recommender_addr;
            loopnum++;
        }
        return loopnum;
    }
    function release_amount_diary(address addr) private{
        uint256 amount=players[addr].amount*getReleasePrecent10()/10/100;
        release_amount(amount,addr);
        players[addr].static_in_released_amount+=amount;
    }
    function getCVIPAwardPrecent(uint cvipNum) private pure returns(uint){
        if(cvipNum>=128) return 16;
        if(cvipNum>=64) return 14;
        if(cvipNum>=32) return 12;
        if(cvipNum>=16) return 10;
        if(cvipNum>=8) return 8;
        if(cvipNum>=4) return 6;
        if(cvipNum>=2) return 4;
        return 2;
    }
    function getManagerAwardPrecent(uint i) private pure returns(uint){
        if(i==1) return 30;
        if(i==2) return 8;
        if(i==3) return 8;
        if(i==4) return 8;
        if(i==5) return 8;
        if(i==6) return 5;
        if(i==7) return 5;
        if(i==8) return 5;
        if(i==9) return 5;
        if(i==10) return 5;
        if(i==11) return 4;
        if(i==12) return 4;
        if(i==13) return 4;
        if(i==14) return 4;
        if(i==15) return 4;
        if(i==16) return 2;
        if(i==17) return 2;
        if(i==18) return 2;
        if(i==19) return 2;
        if(i==20) return 2;
        if(i==21) return 2;
    }
    function getNumRequest(uint i) private pure returns(uint){
        if(i==1) return 2;
        if(i==2) return 4;
        if(i==3) return 8;
        if(i==4) return 10;
        if(i==5) return 12;
        if(i==6) return 14;
        if(i==7) return 18;
        if(i==8) return 20;
        if(i==9) return 21;
        if(i==10) return 22;
        if(i==11) return 23;
        if(i==12) return 24;
        if(i==13) return 25;
        if(i==14) return 26;
        if(i==15) return 27;
        if(i==16) return 28;
        if(i==17) return 29;
        if(i==18) return 30;
        if(i==19) return 31;
        if(i==20) return 32;
        if(i==21) return 33;
    }
    function release_amount(uint amount,address addr) private{
        if(players[addr].prepare_balance<amount){
            return;
        }
        if(amount<=0){
            return;
        }
        players[addr].prepare_balance-=amount;
        
        players[addr].released_amount+=amount;
        //total_balance-=amount;
        players[addr].total_released+=amount;
        
        
    }
    function sendDepositAward(uint amount,address recommender_addr) private{
        uint prepare_balance=players[recommender_addr].prepare_balance;
        //burning 50% if balance is not enough
        if(prepare_balance<amount){
            amount=amount/2;
            players[recommender_addr].burn_amount+=amount;
        }
        //record to wait award balance if still not enough
        if(players[recommender_addr].prepare_balance<amount){
            players[recommender_addr].wait_award+=amount-players[recommender_addr].prepare_balance;
            amount=players[recommender_addr].prepare_balance;
        }
        release_amount(amount,recommender_addr);
    }
    function sendManagerAward(uint amount,address recommender_addr) private{
        uint prepare_balance=players[recommender_addr].prepare_balance;
        //burning half if balance is not enough
        if(prepare_balance<amount){
            amount=amount/2;
            players[recommender_addr].burn_amount+=amount;
        }
        //record to wait award balance if still not enough
        if(players[recommender_addr].prepare_balance<amount){
            players[recommender_addr].wait_award+=amount-players[recommender_addr].prepare_balance;
            amount=players[recommender_addr].prepare_balance;
        }
        release_amount(amount,recommender_addr);
    }
    function sendCVIPAward(uint amount,address recommender_addr) private{
        uint prepare_balance=players[recommender_addr].prepare_balance;
        //burning 50% if balance is not enough
        if(prepare_balance<amount){
            amount=amount/2;
            players[recommender_addr].burn_amount+=amount;
        }
        //record to wait award balance if still not enough
        if(players[recommender_addr].prepare_balance<amount){
            players[recommender_addr].wait_award+=amount-players[recommender_addr].prepare_balance;
            amount=players[recommender_addr].prepare_balance;
        }
        release_amount(amount,recommender_addr);
    }
    function redeposit()public returns(uint){
        require(
            players[msg.sender].released_amount>0,
            "Not enough balance."
        );
        uint value=players[msg.sender].released_amount;
        players[msg.sender].released_amount=0;
        //91% => contract balance
        //total_balance+=value*91/100;
        //2% => insure balance
        total_balance-=value*9/100;
        insure_balance+=value*2/100;
        insure_address.transfer(value*2/100);
        //1% => award for day
        top_award_balance_1+=value*1/100;
        //1% => award for week
        top_award_balance_7+=value*1/100;
        
        uint256 admin_amount=value*5/100;
        admin1_27.transfer(admin_amount*27/100);
        admin2_14_5.transfer(admin_amount*29/2/100);
        admin3_14_5.transfer(admin_amount*29/2/100);
        admin4_14_5.transfer(admin_amount*29/2/100);
        admin5_14_5.transfer(admin_amount*29/2/100);
        admin6_5.transfer(admin_amount*5/100);
        admin7_5.transfer(admin_amount*5/100);
        admin8_5.transfer(admin_amount*5/100);
        /*if(history_top_balance<total_balance){
            history_top_balance=total_balance;
        }*/
        players[msg.sender].amount+=value;
        players[msg.sender].prepare_balance+=value*getMulit2()/2;
        players[msg.sender].last_ts=now;
        players[msg.sender].last_days=0;
        if(players[msg.sender].wait_award>0){
            if(players[msg.sender].prepare_balance>=players[msg.sender].wait_award){
                players[msg.sender].prepare_balance-=players[msg.sender].wait_award;
                players[msg.sender].released_amount+=players[msg.sender].wait_award;
                players[msg.sender].wait_award=0;
            }   
            else{
                players[msg.sender].wait_award-=players[msg.sender].prepare_balance;
                players[msg.sender].released_amount+=players[msg.sender].prepare_balance;
                players[msg.sender].prepare_balance=0;
            }
        }
        //clean static account
        return release_award(msg.sender);
    }
    function cvip() public payable returns(uint){
        require(
            players[msg.sender].is_cvip==0,
            "Already CVIP."
        );
        require(
            msg.value==50000*s,
            "Value not correct."
        );
        players[msg.sender].is_cvip=1;
        address user=msg.sender;
        while(true){
            address prev_addr=players[user].recommender_addr;
            if(prev_addr!=address(0)){
                players[prev_addr].cvip_num+=1;
                user=prev_addr;
            }
            else{
                break;
            }
        }
        uint256 admin_amount=msg.value*60/100;
        admin1_27.transfer(admin_amount*27/100);
        admin2_14_5.transfer(admin_amount*29/2/100);
        admin3_14_5.transfer(admin_amount*29/2/100);
        admin4_14_5.transfer(admin_amount*29/2/100);
        admin5_14_5.transfer(admin_amount*29/2/100);
        admin6_5.transfer(admin_amount*5/100);
        admin7_5.transfer(admin_amount*5/100);
        admin8_5.transfer(admin_amount*5/100);
        total_balance+=msg.value*40/100;
        return players[msg.sender].cvip_num;
    }
    function isNowGMT13() private view returns(bool){
        (uint hour) = timestampToDateTime(now);
        if(hour==22){
            return true;
        }
        return false;
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint hour) {
        uint SECONDS_PER_DAY = 24 * 60 * 60;
        uint SECONDS_PER_HOUR = 60 * 60;
        //uint SECONDS_PER_MINUTE = 60;
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        //secs = secs % SECONDS_PER_HOUR;
        //minute = secs / SECONDS_PER_MINUTE;
        //second = secs % SECONDS_PER_MINUTE;
    }
    function dDaysPassed(uint ts,uint d) private view returns (bool) {
        return (now >= (ts + d*24 hours));
    }
    function release_top_day_award(address payable top1,address payable top2,address payable top3,address payable top4,address payable top5) private{
        uint256 amount=0;
        for(uint i=0;i<5;i++){
            if(i==0 && top1!=address(0)){
                amount=top_award_balance_1*40/100;
                top1.transfer(amount);
            }
            else if(i==1 && top2!=address(0)){
                amount=top_award_balance_1*25/100;
                top2.transfer(amount);
            }
            else if(i==2 && top3!=address(0)){
                amount=top_award_balance_1*20/100;
                top3.transfer(amount);
            }
            else if(i==3 && top4!=address(0)){
                amount=top_award_balance_1*10/100;
                top4.transfer(amount);
            }
            else if(i==4 && top5!=address(0)){
                amount=top_award_balance_1*5/100;
                top5.transfer(amount);
            }
            else {
                break;
            }
        }
        top_award_balance_1=0;
    }
    function release_top_week_award(address payable top1,address payable top2,address payable top3,address payable top4,address payable top5) private{
        uint256 amount=0;
        for(uint i=0;i<5;i++){
            if(i==0 && top1!=address(0)){
                amount=top_award_balance_7*40/100;
                top1.transfer(amount);
            }
            else if(i==1 && top2!=address(0)){
                amount=top_award_balance_7*25/100;
                top2.transfer(amount);
            }
            else if(i==2 && top3!=address(0)){
                amount=top_award_balance_7*20/100;
                top3.transfer(amount);
            }
            else if(i==3 && top4!=address(0)){
                amount=top_award_balance_7*10/100;
                top4.transfer(amount);
            }
            else if(i==4 && top5!=address(0)){
                amount=top_award_balance_7*5/100;
                top5.transfer(amount);
            }
            else {
                break;
            }
        }
        top_award_balance_7=0;
    }
    function release_insure() private{
        insure_balance=0;
    }
    function release_topaward(address payable topday1,address payable topday2,address payable topday3,address payable topday4,address payable topday5) public returns(bool){
        require(
            msg.sender==contract_owner,
            "Only contract owner can calling this function."
        );
        //if(isNowGMT13()){
            if(getReleasePrecent10()==1){
                day_in_low_release++;
            }
            release_top_day_award(topday1,topday2,topday3,topday4,topday5);
            return true;
        //}  
        //else{
        //    return false;
        //}
    }
    function release_topaward_week(address payable top1,address payable top2,address payable top3,address payable top4,address payable top5)public returns(bool){
        require(
            msg.sender==contract_owner,
            "Only contract owner can calling this function."
        );
        //if(isNowGMT13()){
            release_top_week_award(top1,top2,top3,top4,top5);
            return true;
        //}
    }
    function release_diary_self() public returns(bool){
        if(players[msg.sender].prepare_balance<=0){
            return false;
        }
        if(dDaysPassed(players[msg.sender].last_ts,players[msg.sender].last_days+1)){
            players[msg.sender].last_days++;
            release_amount_diary(msg.sender);
            return true;
        }
        return false;
    }
    function release_diary(address addr) public returns(bool){
        require(
            msg.sender==contract_owner,
            "Only contract owner can calling this function."
        );
        if(addr!=address(0)){
            if(players[addr].prepare_balance<=0){
                return false;
            }
            if(dDaysPassed(players[addr].last_ts,players[addr].last_days+1)){
                players[addr].last_days++;
                release_amount_diary(addr);
            }
        }
        else{
            uint arrayLength = addressIndices.length;
            for (uint i=0; i<arrayLength; i++) {
                addr=addressIndices[i];
                if(players[addr].prepare_balance<=0){
                    continue;
                }
                if(dDaysPassed(players[addr].last_ts,players[addr].last_days+1)){
                    players[addr].last_days++;
                    release_amount_diary(addr);
                }
            }
        }
        return true;
    }
    
    function getMulit2() private view returns(uint){
        if(total_balance<history_top_balance*18/100){
            return 15;
        }
        else if(total_balance<history_top_balance*26/100){
            return 14;
        }
        else if(total_balance<history_top_balance*34/100){
            return 13;
        }
        else if(total_balance<history_top_balance*42/100){
            return 12;
        }
        else if(total_balance<history_top_balance*50/100){
            return 11;
        }
        else if(total_balance<history_top_balance*58/100){
            return 10;
        }
        else if(total_balance<history_top_balance*66/100){
            return 9;
        }
        else if(total_balance<history_top_balance*74/100){
            return 8;
        }
        else if(total_balance<history_top_balance*82/100){
            return 7;
        }
        else {
            return 6;
        }
    }
    function getReleasePrecent10() private view returns(uint){
        if(total_balance<history_top_balance*18/100){
            return 1;
        }
        else if(total_balance<history_top_balance*26/100){
            return 2;
        }
        else if(total_balance<history_top_balance*34/100){
            return 3;
        }
        else if(total_balance<history_top_balance*42/100){
            return 4;
        }
        else if(total_balance<history_top_balance*50/100){
            return 5;
        }
        else if(total_balance<history_top_balance*58/100){
            return 6;
        }
        else if(total_balance<history_top_balance*66/100){
            return 7;
        }
        else if(total_balance<history_top_balance*74/100){
            return 8;
        }
        else if(total_balance<history_top_balance*82/100){
            return 9;
        }
        else {
            return 10;
        }
    }
}