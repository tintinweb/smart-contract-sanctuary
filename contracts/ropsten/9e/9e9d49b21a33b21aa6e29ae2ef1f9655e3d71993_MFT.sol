/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity >=0.6.0 <0.8.0;

contract MFT {
    bool public saleIsActive = false;
    
    function flipSaleState() public {
            saleIsActive = !saleIsActive;
        }
    
    function mintApe(uint numberOfTokens) public payable {
            require(saleIsActive, "Sale must be active to mint Ape");
    
            
        }
        
    function withdraw() public {
            uint balance = address(this).balance;
            msg.sender.transfer(balance);
        }
}