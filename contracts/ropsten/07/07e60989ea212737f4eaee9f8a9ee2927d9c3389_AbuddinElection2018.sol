pragma solidity ^0.4.0;
//WP27080956Concordia
contract AbuddinElection2018 {
    string[7] candidates  = ["Abstain","Conservative", "Liberal", "Socialist", "Communist", "Fascist","Libertarian"];
    mapping(bytes32 => bool) validShaHashes;
    mapping(uint8 => uint) public tallies;
    function addAllValidShaHashes() private{
     validShaHashes[0x15261CC1AB9CA4065B017403B3FB1EB3C903FA3F970026BDA1EAADD363A516D6] = true;
     validShaHashes[0x81AAE50317919A9EECA85B52A07D7BDBFA231BF91A28678B75AC2CBCDE1F2D8D] = true;
     validShaHashes[0x24A22EC61DD09F7A44BDEB5C8F1E56FFD04D11B8D4E7ADA561846990FE4A6E2C] = true;
     validShaHashes[0x0B0059844B6F1A082760F1CC9F49C88D23E13B17C8F4F56EF3B8004C5E35F805] = true;
     validShaHashes[0xEB6AC1E7DAC03EEBD2B9E3662627D996B0CF671D8CB197DC98878321E00C3D6E] = true;
     validShaHashes[0x3F01CDD5A10119B48723DBCF6E7CFED723C2F7293D3D7D3AA078532713C1C6F8] = true;
     validShaHashes[0x55BC7825982DD59F8D06DADA7B8DD11E63F1CA7601BCBEC93BEF862DB0F59030] = true;
     validShaHashes[0xE23C9FC642181829E10F6C29181D9A5DDC39208F59D86A2FD81CFE80A96496A5] = true;
     validShaHashes[0x815A165BE2B3A9408C8A535C9D10F20F110301EFD803938426D4BD6234F90C04] = true;
     validShaHashes[0xD1C8BEC3883B2ED96E15CC99481455BC531036F8C0522FEB601E3CD61C448369] = true;
    
   }
    //Does the validShaHashes mapping have an entry accescodeHash => true
    //If no entry appears, then the accescodeHash is not valid and the voter provided an incorrect accescode
    //if an entry appears but it is: accescodeHash => true, then this voter has already voted and is no longer elligible
    function isHashValid(bytes32 accescodeHash) private view returns(bool){
        bool accescodeHashExists = validShaHashes[accescodeHash];
        return accescodeHashExists;
   }
   function toSHA256(string accescode) private pure returns(bytes32){
       return sha256(bytes(accescode));
   }
   function _vote(bytes32 hashOfVoter, uint8 indexOfCandidate) private{
        tallies[indexOfCandidate] = tallies[indexOfCandidate] + 1;//increase tally for candidate
        setHashToFalse(hashOfVoter); //remove elligiblility for this voter
   }
   function setHashToFalse(bytes32 hashOfVoter) private{
       validShaHashes[hashOfVoter] = false;
   }
   function vote(string accescode, uint8 indexOfCandidate) external{
       bytes32 accescodeHash = toSHA256(accescode);
       if(isHashValid(accescodeHash)){
            _vote(accescodeHash, indexOfCandidate);
       } else {
           revert("accesscode is invalid, or you already voted");
       }
   }
   constructor() public {
     addAllValidShaHashes();
   }
}