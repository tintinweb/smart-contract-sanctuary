// SPDX-License-Identifier: MIT

// Created by Al Razzaq
// Name of the project

pragma solidity ^0.8.0;


import "./SafeMath.sol";
import "./Ownable.sol";


contract RankNFT is Ownable {
    
    using SafeMath for uint256;
  
//*********** Variables *****************

  uint constant DAY_IN_SECONDS = 86400;
  uint constant MINUTES_IN_SECONDS = 3600;
  address constant private developer = 0x31D165F1123ad9166cBFAC2b11D2F377e824b08B;
  
  uint private costOfSixMonthMemmbership =  0.7 ether;
  uint private costOfOneMonthMemmbership =  0.15 ether;
  uint private costOfSevenDaysMemmbership =  0.06 ether;
  uint private costOfOneDayMemmbership =  0.02 ether;
  
  address[] private whitelistedUsers;


//*********** Mappings *****************

  mapping(address => uint256) public whitelisting_period;
  mapping(address => uint256) public subscription_period;
  

//*********** Events *****************
  event AmountChanged(address account);
  event MembershipAssigned(address account, uint duration);

  event WhiteListed(address account, uint duration);
  event BlackListed(address account);
  event PaymentReleased(address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);
   
  
  function developer_address() public pure returns(address){
    return developer;
  }

  function set_cost_of_subscription(uint256 _days, uint256 _amount) public onlyOwner{
      require(_days == 1 || _days == 7 || _days == 30 || _days == 180);
      
      if(_days == 1){
        costOfOneDayMemmbership = _amount;
      }
      if(_days == 7){
        costOfSevenDaysMemmbership = _amount;
      }
      if(_days == 30){
        costOfOneMonthMemmbership = _amount;
      }
      if(_days == 180){
        costOfSixMonthMemmbership = _amount;
      }
      
  }
  
  function get_cost_of_subscription(uint256 _days) view public returns(uint) {
      require(_days == 1 || _days == 7 || _days == 30 || _days == 180);
      
      if(_days == 1){
        return costOfOneDayMemmbership;
      }
      if(_days == 7){
        return costOfSevenDaysMemmbership;
      }
      if(_days == 30){
        return costOfOneMonthMemmbership;
      }
      if(_days == 180){
        return costOfSixMonthMemmbership;
      }
      else {
          return 0;
      }

  }
 

  function assign_subscription(address _user, uint256 _days) internal {

    whitelistUser(_user, _days);

    if(subscription_period[_user] > block.timestamp){
        subscription_period[_user] = subscription_period[_user].add(DAY_IN_SECONDS.mul(_days));
        emit MembershipAssigned(_user, subscription_period[_user]);
    }
    else{
        subscription_period[_user] = block.timestamp.add(DAY_IN_SECONDS.mul(_days));
        emit MembershipAssigned(_user, subscription_period[_user]);

    }

   distribute_equity();
            
}

  function whitelistUser(address _user, uint256 _days) internal {

    if(whitelisting_period[_user] > block.timestamp){
        whitelisting_period[_user] = whitelisting_period[_user].add(DAY_IN_SECONDS.mul(_days));
        emit WhiteListed(_user, whitelisting_period[_user]);
    }
    else {
        whitelistedUsers.push(_user);
        whitelisting_period[_user] = block.timestamp.add(DAY_IN_SECONDS.mul(_days));
        emit WhiteListed(_user, whitelisting_period[_user]);

    }
    
  }

  function blacklistUser(address _user) internal {
    delete whitelisting_period[_user];
    delete subscription_period[_user];
    emit BlackListed(_user);
  }

  
      // free one hour subscription
  function giveaway_subscription(address[] memory _users, uint _hours) public onlyOwner {
    
    for(uint i = 0; i < _users.length; i++){

        if(whitelisting_period[_users[i]] > block.timestamp){
            whitelisting_period[_users[i]] = whitelisting_period[_users[i]].add(MINUTES_IN_SECONDS.mul(_hours));
            emit WhiteListed(_users[i], whitelisting_period[_users[i]]);
        }
        else {
            whitelistedUsers.push(_users[i]);
            whitelisting_period[_users[i]] = block.timestamp.add(MINUTES_IN_SECONDS.mul(_hours));
            emit WhiteListed(_users[i], whitelisting_period[_users[i]]);
    
        }      
          subscription_period[_users[i]] > block.timestamp ?
                subscription_period[_users[i]] = subscription_period[_users[i]].add(MINUTES_IN_SECONDS.mul(_hours)) :
                subscription_period[_users[i]] = block.timestamp.add(MINUTES_IN_SECONDS.mul(_hours));
                
    }
    
  }



      // Daily subscription
  function get_single_day_subscription() public payable {

      require(msg.value >= costOfOneDayMemmbership, "not enough money sent");
      require(whitelisting_period[msg.sender] > block.timestamp, "Not whitelisting_period, Please contact to Admin");

    assign_subscription(msg.sender, 1);

  }     
   
      // Weekly subscription
  function get_seven_days_subscription() public payable {

      require(msg.value >= costOfSevenDaysMemmbership, "not enough money sent");
      require(whitelisting_period[msg.sender] >block.timestamp, "Not whitelisting_period, Please contact to Admin");
      
      assign_subscription(msg.sender, 7);

}

      // Monthly subscription
  function get_one_month_subscription() public payable {

      require(msg.value >= costOfOneMonthMemmbership, "not enough money sent");
      require(whitelisting_period[msg.sender] >block.timestamp, "Not whitelisting_period, Please contact to Admin");

         assign_subscription(msg.sender, 30);

}

      // Six Monthl subscription
  function get_six_month_subscription() public payable {

      require(msg.value >= costOfSixMonthMemmbership, "not enough money sent");
      require(whitelisting_period[msg.sender] > block.timestamp, "Not whitelisting_period, Please contact to Admin");

      assign_subscription(msg.sender, 180);

}


  function is_whitelisted(address _address) public view returns (bool) {
    return whitelisting_period[_address] > block.timestamp;
  }
  
  function is_subscriber(address _address) public view returns (bool) {
    return subscription_period[_address] > block.timestamp;
  }
   
 
  function whitelist_users(address[] memory _users, uint256 _days) public onlyOwner {
      
    if(_users.length == 1){
        whitelistUser(_users[0], _days);
    }
    else {
        for(uint i = 0; i < _users.length; i++){
            whitelistUser(_users[i], _days);
        }
    }
  }
  

  function blacklist_users(address[] memory _users) public onlyOwner {
      
    if(_users.length == 1){
        blacklistUser(_users[0]);
    }
    else {
        for(uint i = 0; i < _users.length; i++){
        blacklistUser(_users[i]);
        }
    }
  }
  
  
  function list_of_whitelisted_users() public view returns(address[] memory){
    return whitelistedUsers;
  }
  
  // function refresh_list_of_whitelisted_users() public onlyOwner{
      
  //   address[] memory allWhitelistedUsers = whitelistedUsers;

  //   whitelistedUsers = new address[](0);
      
  //   for(uint i = 0; i < allWhitelistedUsers.length; i++){
  //       if( whitelisting_period[allWhitelistedUsers[i]] >  block.timestamp){
  //           whitelistedUsers.push(allWhitelistedUsers[i]);
  //       }
  //   }
  // }
  
  
  function total_balance_available() public view returns(uint256) {
        return  address(this).balance;
  }
    
  
  function withdraw_total_amount() public onlyOwner {
      distribute_equity();
  }
 
    
  function distribute_equity() internal {
        
        uint256 totalamount =  address(this).balance;
        require(totalamount > 0, "balance is nill");

        address owner = owner();
        
        // distribute owner's 85% cut
        uint256 ownersCut =  totalamount.mul(85).div(100);     
        bool sentOwner = payable(owner).send(ownersCut);
        require(sentOwner, "Failed to send Ether");
        emit PaymentReleased(owner, ownersCut);
        
        // distribute remaining 15% to developer
        uint developersCut = totalamount.sub(ownersCut);
        bool sentDeveloper = payable(developer).send(developersCut);
        require(sentDeveloper, "Failed to send Ether");
        emit PaymentReleased(developer, developersCut);
        
    }
  
}