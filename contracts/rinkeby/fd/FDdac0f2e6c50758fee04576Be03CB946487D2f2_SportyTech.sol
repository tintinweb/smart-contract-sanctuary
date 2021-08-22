/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

//Written by blockchainguy.net

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.2;

// contract PlayContract{

      
//         mapping(address => uint256) signed_between; //player_address => team id
//         mapping(uint256 => mapping(address => string)) contract_details; // [offer_id][player_address] => contract
        
//         function make_contract(address player_address,uint256 offer_id, string memory team_name, uint256 team_id, string memory player_name,string memory player_dob, string memory team_dor ,string memory contract_applies_date, string memory up_to, string memory basesalary, string memory reward) public{
//             string memory contract_text = make_contract_text(team_name, player_name,  player_dob,   team_dor , contract_applies_date,  up_to,  basesalary, reward);
//             signed_between[player_address] = team_id;
//             contract_details[offer_id][player_address] = contract_text;
//         }
        
//         function make_contract_text(string memory team_name, string memory player_name,string memory player_dob, string memory team_dor ,string memory contract_applies_date, string memory up_to, string memory basesalary, string memory reward) internal returns(string memory){
//             string memory description = "The following smart contract has been entered into by and between : The Club Name :";
//             string memory temp1 = append(description,team_name," and The Player Name :",player_name,". Section  1: The Player information: Name: ");
//             string memory temp2 = second_part(player_name, player_dob, team_name, team_dor, contract_applies_date);
//             string memory temp4 = append(up_to, ". The payment details: Base Salary: ", basesalary, ", Rewards: ", reward );
//             string memory final_detail = string(abi.encodePacked(temp1,temp2,temp4));
//             return final_detail;
//         }
        
//         function second_part(string memory player_name, string memory player_dob, string memory team_name, string memory team_dor, string memory contract_applies_date) internal returns(string memory){
//             string memory temp2 = append(player_name, ", DoB: ", player_dob, ". Section  2: The Club information: Name: ",team_name);
//             string memory temp3 = append(" DoR: ",team_dor, ", Section  3: The Contract Conditions: This smart contract applies as of ",contract_applies_date, " ,  up to and including ");
//             string memory temp4 = string(abi.encodePacked(temp2, temp3));
//             return temp4;
//         }
        
//         function get_contract(uint256 offer_id, address player_address) public view returns(string memory){
//           return contract_details[offer_id][player_address];
//         }
        
// function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {

//     return string(abi.encodePacked(a, b, c, d, e));

// }
    
// }


contract SportyTech {

    
    uint256 team_count = 0;
    uint256 offers_count = 0;
    
  struct team { 
      address team_owner;
      string name;
      uint256 team_id;
   }
   
   struct player{
       address player_address;
       string name;
   }
   

      mapping(uint256 => mapping(address => bool)) player_applied_to_offer; // [ofer_id][player_id] = true/false 


   mapping(uint256 => bool) t_applied_to_offers; //this will stay empty, only created to make players
   mapping(uint256 => team) team_list; //team_list[team_id] to get back team variable
   mapping(address => player) public player_list; //player list
   mapping(uint256 => uint256) offer_list; //offer_list[offers_count] = team_id;
   mapping(uint256 => bool) is_offer_open_to_apply;
   mapping(uint256 => address) offer_accepted_list; // offer_id => player address

   
        mapping(address => uint256) signed_between; //player_address => team id
        mapping(uint256 => mapping(address => string)) public contract_details; // [offer_id][player_address] => contract
   
   
  constructor() {

    //   t_team_members[msg.sender] = true;
       team_list[team_count] = team(msg.sender, "Team 1", team_count);
       create_offer(team_count);
       team_count++;
     
       team_list[team_count] = team(0xae48Cf32c56806D8DfC038D7744212Ce4B180Bc0, "Team 2", team_count);
       create_offer(team_count);
       team_count++;
       
       team_list[team_count] = team(0x6985a31192eE28A6DE4BeCF449b65e64731D36cA, "Team 3", team_count);
       create_offer(team_count);
       team_count++;
       
        team_list[team_count] = team(0x6985a31192eE28A6DE4BeCF449b65e64731D36cA, "Team 4", team_count);
       create_offer(team_count);
       team_count++;
       


       
   }
  function get_single_offer(uint256 offer_id) external view returns(string memory, uint256){
      uint256 team_id = offer_list[offer_id];
      team memory temp_team = team_list[team_id];
      return (temp_team.name, temp_team.team_id);
  }
  function get_offer_list() external view returns(uint256[] memory){
        uint256[] memory memoryArray = new uint256[](offers_count);
        for(uint i = 0; i < offers_count; i++) {
            //if(is_offer_open_to_apply[i] != false){
                memoryArray[i] = offer_list[i];
           // }
            
        }
        return memoryArray;
  }

   
  function create_offer(uint256 team_id) public {
      // team memory temp_team = team_list[team_id];
       //require(msg.sender == temp_team.team_owner, "Only Team Owner can create the offer");
       offer_list[offers_count] = team_id;
       is_offer_open_to_apply[offers_count] = true;
      offers_count++;
       
   }
  function apply_to_offer(uint256 offer_id) public {
       //require(is_offer_open_to_apply[offer_id] == true, "Offer Closed");
       require(check_player_applied_to(msg.sender, offer_id) != true, "You already applied");

            create_player();
           set_player_applied_to(msg.sender, offer_id, true);
           player_applied_to_offer[offer_id][msg.sender] = true;
          // applied_to_offer[offer_id][msg.sender] = false;
       

      
       
  }
  function create_player()public {
      if(!check_player_exist(msg.sender)){
           player_list[msg.sender] = player(msg.sender,"demo_player");
       }
  }

  
  function accept_player_from_offer(uint256 offer_id, address player_id) public {
      team memory temp_team = team_list[offer_list[offer_id]];
      //require(msg.sender == temp_team.team_owner, "Only Owner can accept player");
      //require(is_offer_open_to_apply[offer_id] == true, "Offer is Closed");
      require(player_applied_to_offer[offer_id][player_id] == true, "Player didnt apply to the offer");
      
      //is_offer_open_to_apply[offer_id] = false;
      offer_accepted_list[offer_id] = player_id;
      string memory team_name = team_list[offer_list[offer_id]].name;
      uint256 team_id = team_list[offer_list[offer_id]].team_id;
      make_contract(player_id, offer_id,team_name, team_id, "Player 1","11 April 1997","12 Jan 2021", "21 Jan 2022", "21 Jan 2023", "$10,000","$2000");
      
      
  }
  function check_player_applied_to(address player_address, uint256 offer_id) public view returns(bool){
      return player_applied_to_offer[offer_id][player_address];
    //   return player_list[player_address].applied_to_offers[offer_id];
      
  }
  function set_player_applied_to(address player_address, uint256 offer_id, bool check) internal {

      player_applied_to_offer[offer_id][player_address] = check;
      
  }
  function check_player_exist(address player_address) public view returns(bool){
     if(player_list[player_address].player_address == address(0)){
         return false;
     }
     else{
         return true;
     }
  }

        function make_contract(address player_address,uint256 offer_id, string memory team_name, uint256 team_id, string memory player_name,string memory player_dob, string memory team_dor ,string memory contract_applies_date, string memory up_to, string memory basesalary, string memory reward) public{
            string memory contract_text = make_contract_text(team_name, player_name,  player_dob,   team_dor , contract_applies_date,  up_to,  basesalary, reward);
            signed_between[player_address] = team_id;
            contract_details[offer_id][player_address] = contract_text;
        }
        
        function make_contract_text(string memory team_name, string memory player_name,string memory player_dob, string memory team_dor ,string memory contract_applies_date, string memory up_to, string memory basesalary, string memory reward) internal returns(string memory){
            string memory description = "The following smart contract has been entered into by and between : The Club Name :";
            string memory temp1 = append(description,team_name," and The Player Name :",player_name,". Section  1: The Player information: Name: ");
            string memory temp2 = second_part(player_name, player_dob, team_name, team_dor, contract_applies_date);
            string memory temp4 = append(up_to, ". The payment details: Base Salary: ", basesalary, ", Rewards: ", reward );
            string memory final_detail = string(abi.encodePacked(temp1,temp2,temp4));
            return final_detail;
        }
        
        function second_part(string memory player_name, string memory player_dob, string memory team_name, string memory team_dor, string memory contract_applies_date) internal returns(string memory){
            string memory temp2 = append(player_name, ", DoB: ", player_dob, ". Section  2: The Club information: Name: ",team_name);
            string memory temp3 = append(" DoR: ",team_dor, ", Section  3: The Contract Conditions: This smart contract applies as of ",contract_applies_date, " ,  up to and including ");
            string memory temp4 = string(abi.encodePacked(temp2, temp3));
            return temp4;
        }
        
        function get_contract(uint256 offer_id, address player_address) public view returns(string memory){
           return contract_details[offer_id][player_address];
        } 
        
        function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {

         return string(abi.encodePacked(a, b, c, d, e));

        }
}

//Written by blockchainguy.net