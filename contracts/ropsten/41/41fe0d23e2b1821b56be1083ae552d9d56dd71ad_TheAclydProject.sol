pragma solidity ^0.4.0;
contract TheAclydProject {
    /* Public variables of the TheAclydProject */
    string public companyName = "The Aclyd Project";
    string public corporateReg = "12345678";
    string public corporateDomicile = "Nassau, Bahamas";
    string public physicalAddress =  "5454 S. 1st Ave, Nassau, Bahamas";
    string public tokenstandard = "ERC20";
    string public tokenSymbol = "ACLYD";
    string public officialTokenContract = "0x9EBd891C64c14D443b6F8a08c82AEAfEF1275CC9";
    string public principleKYCcode = "12345678";
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        throw;     // Prevents accidental sending of ether
    }
}