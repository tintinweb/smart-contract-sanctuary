/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity >=0.7.0 <0.9.0;


contract Club {

    // Static Values for the Contract
    string  public name; 
    address public clubLeader; 
    Member[] public members;
    uint256 public memberCount;

    // 
    struct Member{
        string  memberName;
        address memberAddressID;
    }
    constructor(){
    memberCount = 0; 
    }

    function createMember( string memory _name) public {
        memberCount++;
        members.push(Member(_name, msg.sender));
    }

        function returnMembers() public view returns(string[] memory ){
       // if (memberCount>0){
            string[] memory retMember = new string[](memberCount);
            for (uint128 i =0; i < memberCount; i++){
                retMember[i]= members[i].memberName;
               
            }
            return retMember;
        }


         function returnAddresses() public view returns(address[] memory ){
       // if (memberCount>0){
            address[] memory memberIDs = new address[](memberCount);
            for (uint128 i =0; i < memberCount; i++){
                memberIDs[i]= members[i].memberAddressID;
               
            }
            return memberIDs;
        }
}