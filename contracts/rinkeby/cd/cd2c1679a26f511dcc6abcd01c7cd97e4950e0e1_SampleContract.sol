/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

pragma solidity ^0.4.26;
contract SampleContract{
    struct UserRand{
      uint id;
      uint   chance;
      uint256 RandChance;
    }
    UserRand[] usersRand;
    bytes32  user_hash;
    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty))) % 251;
    }
    function setDataInputRand(uint256[]  userID,uint256[]  UserChance) public  {
         for (uint i = 0; i< userID.length;i++){
            uint256 rand = random();
            uint256 count = rand + userID[i] + UserChance[i];
            usersRand.push(UserRand(userID[i],UserChance[i],count));
        }
    }
    function showDataWasSetByIdRand(uint ind) public view returns(uint Userid, uint UserChances,uint256 chanceRand){
        Userid = usersRand[ind].id;
        UserChances = usersRand[ind].chance;
        chanceRand = usersRand[ind].RandChance;
    }
}