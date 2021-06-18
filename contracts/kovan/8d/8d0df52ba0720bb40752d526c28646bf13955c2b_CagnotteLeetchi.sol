/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: undefiened

pragma solidity 0.8.0;

contract CagnotteLeetchi {
    
    struct CagnotteStruct{
        address payable owner;
        uint paymentCap;
        uint funds;
        bool isStarted;
        uint timeout;
    }
    
    mapping (address => CagnotteStruct) cagnottes;
    
    function createCagnotte(uint _amount, uint _delay) external {
        // Sécurité pour pas écraser une cagnotte déjà existante
        require(cagnottes[msg.sender].isStarted == false);
        
        CagnotteStruct storage cagnotte = cagnottes[msg.sender];
        
        cagnotte.owner = payable( msg.sender); 
        cagnotte.paymentCap =  _amount * (10**18);
        cagnotte.funds = 0;
        cagnotte.isStarted = true;
        cagnotte.timeout = block.timestamp + _delay;
    } 
    
    
    //fallback() external payable {}
    
    function addFunds(address _receipter) external payable {
        require(msg.value > 0 && cagnottes[_receipter].isStarted == true && block.timestamp < cagnottes[_receipter].timeout);
        
        cagnottes[_receipter].funds += msg.value;
    }
    
    
    function getPaid() external {
        require(cagnottes[msg.sender].isStarted == true && block.timestamp >= cagnottes[msg.sender].timeout); 
            //address payable receipt = payable(owner);
            uint amount = cagnottes[msg.sender].funds;
             // cagnottes[msg.sender] = address(0);
            cagnottes[msg.sender].funds = 0;
            cagnottes[msg.sender].paymentCap = 0;
            cagnottes[msg.sender].isStarted = false;
            
            cagnottes[msg.sender].owner.transfer(amount);

    }
    
    function getTimeLeft(address _owner) external view returns (uint) {
        if (cagnottes[_owner].timeout <= block.timestamp) {
            return 0;
        }
        return cagnottes[_owner].timeout - block.timestamp;
    }
      
    
    function getFunds(address _owner) external view returns(uint) {
        return cagnottes[_owner].funds;
    } 
    
    function getPaymentCap(address _owner) external view returns(uint) {
        return cagnottes[_owner].paymentCap;
    } 
    
    function getTotalBalance() external view returns(uint) {
        return uint(address(this).balance);
    }
    
}