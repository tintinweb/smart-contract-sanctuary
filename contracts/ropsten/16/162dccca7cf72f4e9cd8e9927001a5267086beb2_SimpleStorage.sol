pragma solidity ^0.5.0;

// File: contracts/IndividualCertification.sol

/**
  * @title   Individual Certification Contract
  * @author  Rosen GmbH
  *
  * This contract represents the individual certificate.
  */
contract SimpleStorage {
   string public speakerName;
   
    constructor(string memory _speakerName) 
        public 
    {
        speakerName = _speakerName;
    }
    
    function setSpeakerName(string memory _newSpeaker)
     public 
    {
         speakerName = _newSpeaker;
    }

}