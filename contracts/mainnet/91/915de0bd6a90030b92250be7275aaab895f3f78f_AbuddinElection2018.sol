pragma solidity ^0.4.0;
//WP27080956Concordia
contract AbuddinElection2018 {
    string[7] candidates  = ["Abstain","Conservative", "Liberal", "Socialist", "Communist", "Fascist","Libertarian"];
    mapping(bytes32 => bool) validShaHashes;
    mapping(uint8 => uint) tallies; 
    
    function addAllValidShaHashes() private{
     validShaHashes[0x04BF3170DE8C838DE8C45640365200AE34F570C2E24C79791DC6302A3BF14476] = true;
     validShaHashes[0x8E79AB77EAB3205F7312E3BAF19E4EB0E31EACA7470C35F67F986E20C36E7DD4] = true;
     validShaHashes[0xF8A7CAA40E78C3EDD18C7148A4FA945B89E5EF94A9E737E8743C6342B3C9AD0F] = true;
     validShaHashes[0xC5405BC0E338728FFE7E71A300E2520022CE6A5F37D5589B538C906941076DC8] = true;
     validShaHashes[0x0D48A1CEFDE54BF705940490301C607A495AD8DB2A3D1A843A6BE1CD9BF15594] = true;
     validShaHashes[0x6B7D27405E6C275246BEAACB4610DBD3B1ECBC80B01481C3FF3184917131500B] = true;
     validShaHashes[0xB444A09C1F44FEA2760C0CE8B7911F636EEE868660DD29F309CF5D04D7D21F46] = true;
     validShaHashes[0x0111804C995BEFEAE6CA6A15D71A76A8A12D86465C500463D056AA5259A1A0C9] = true;
     validShaHashes[0x4F0707A24F34C3EF91685B8500F203BC31EDF174FDCEAA41E8B7DBFF8997BD55] = true;
     validShaHashes[0xBE65EFC4DA245C5D8A6891F835E1E7777F72D524BA5CB15178DFB2541B40EB32] = true;
     validShaHashes[0x6060BA9AD6C059690EB7827DA7132A92532336323F160706A967C54B0A6379EF] = true;
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