/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

pragma solidity ^0.8.7;

contract insurance {
    mapping(address => uint) public balance;
    address payable private owner; //Insurer address
    
    //constructor
    constructor() {
        owner = payable(msg.sender); 
    }
    
    //List of valid medical claims
    string[] validClaims = ["surgery", "neuro", "dental", "therapy", "psych"];
    
    //struct for claim
    struct TreatmentClaim{ 
      uint256 cost;
      string description;
      string approval;
    }
    
    uint256 withdrawal;
    //address mapped to claims
    mapping (address => TreatmentClaim) claims;
    
    /**
     * Checks if the claim description "str" is valid, the possible
     * valid claims are stored in validClaims
     */
    function checkClaimDescription(string memory str) view private returns (bool) {
        for(uint i = 0; i < validClaims.length; i++) {
            if(keccak256(abi.encodePacked(str)) == keccak256(abi.encodePacked(validClaims[i])))
                return true;
        }
        return false;
    }
    
    /**
     * Converts the string "str" to lowercase
     */
    function tolower(string memory str) internal pure returns (string memory) {
        bytes memory _Str = bytes(str);
        bytes memory _Lower = new bytes(_Str.length);
        for (uint i = 0; i < _Str.length; i++) {
            // Uppercase character...
            if ((uint8(_Str[i]) >= 65) && (uint8(_Str[i]) <= 90)) {
                // So we add 32 to make it lowercase
                _Lower[i] = bytes1(uint8(_Str[i]) + 32);
            } else {
                _Lower[i] = _Str[i];
            }
        }
        return string(_Lower);
    }
    
    /**
     * Add balance to the insurer's account (the insurance company)
     */
    function InsurerBalanceTopUp() public payable {
        //require(msg.sender == owner,"Insurer only function"); //For testing purposes, user can deposit their own funds
        balance[owner] += msg.value;
    }
    
    /**
     * The claimant(patient) can claim the insurance money by 
     * inputting his address, cost and description. The description 
     * is checked against validClaims to know if the claim is valid.
     * 
     */
    function ApplyClaim(address payable _claimant ,uint _cost, string memory _description) public payable {
      require(msg.sender == _claimant,"Applicant does not match the address");
     //checks if the claim description matches any from validClaims
      if(checkClaimDescription(tolower(_description)) != true){
          _description = string(abi.encodePacked(_description," is an invalid claim."));
          claims[_claimant] = TreatmentClaim(_cost,_description,"Rejected");
      }
     //check the Insurer's balance if it is sufficient to reimburse the claim
      else if(balance[owner] < _cost * 1 ether){
          _description = string(abi.encodePacked(_description,", insufficient balance."));
          claims[_claimant] = TreatmentClaim(_cost,_description,"Rejected");
      }
     //Once approved, deduct Insurer's balance and reimburse the claimant
      else{
            claims[_claimant] = TreatmentClaim(_cost,_description," Approved");
            balance[owner] -= _cost * 1 ether;     //deduct insurer balance
            _claimant.transfer(_cost * 1 ether);   //Reimburse claimant 
      }
    }
    /**
     * Allows the patient to view his claim and status, can only be accessed by the patient
     */
    function ViewYourClaim(address _claimant) view public returns (string memory) {
      require(msg.sender == _claimant,"Applicant does not match the address");
      string memory message = string(abi.encodePacked(claims[_claimant].description," ",claims[_claimant].approval));
      return(message);
    }
    /**
     * Allows the insurance company to view any claim
     */
    function InsurerViewClaimDetail(address _claimant) view public returns (string memory) {
      require(msg.sender == owner,"Applicant does not match the address");
      string memory message = string(abi.encodePacked(claims[_claimant].description," ",claims[_claimant].approval));
      return(message);
    }
}