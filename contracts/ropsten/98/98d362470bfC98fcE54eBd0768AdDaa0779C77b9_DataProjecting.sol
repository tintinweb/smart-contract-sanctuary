//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DataManipulation.sol";



contract DataProjecting is DataManipulation{
    
    /*   Ownership Related Functions   */   
    
    function _23_______________ViewOwnerByIndexPosition(uint32 _position) public view returns(address){
        
        return contractOwners[_position];
    }
    
    function _24__________CheckIfAddressIsContractOwner(address _address) public view returns(bool){
        
        for(uint32 i = 0; i < contractOwners.length; i++){
            
            if(contractOwners[i] == _address){
                
                return true;
            }
        }
        
        return false;
    } 
    
    
    /*   Project Donations Related Functions   */
    
    function _18_____GetContractWithdrawableBNBBalance() public view returns(uint256){
        
        return(contractClearedBNBBalance);
    }
    
     function _19____GetContractWithdrawableTokenBalance() public view returns(uint256){
        
        return(contractClearedTokenBalance);
    }
    
    
    /*   Project Tokenomics Related Functions   */
    
    function _14______________GetContractFullBNBBalance() public view returns(uint256){
        
        return(address(this).balance);
    }
    
    function _15____________GetContractFullTokenBalance() public view returns(uint256){
        
        return(balances[address(this)]);
    }
    
    function _16___________GetContractLockedBNBBalance() public view returns(uint256){
        
        return(address(this).balance - contractClearedBNBBalance);
    }
    
    function _17__________GetContractLockedTokenBalance() public view returns(uint256){
        
        return(balances[address(this)] - contractClearedTokenBalance);
    }

    function _20___________________GetTokenTradingState() public view returns(bool){
        
        return canTradeTokens;
    }
    
    function _21_________ViewBurnAddressByIndexPosition(uint256 _position) public view returns(address){
        
        return burnAddresses[_position];
    }
    
    function totalSupply() public view returns (uint256) {
        
        return totalCirculatingTokens;
    }


    function balanceOf(address tokenOwner) public view returns (uint256) {
        
        return balances[tokenOwner];
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        
        return allowed[owner][delegate];
    } 
    
    
    /*   Project Safety Related Functions   */
    
    function _22_____ViewBlacklistAddressByIndexPosition(uint256 _position) public view returns(address){
        
        return blacklistedAddresses[_position];
    }
    

    /*   Other Functions   */
    
    function _25_______________________NumcheckAddress(string memory _address) public pure returns (address) {
        
        bytes memory tmp = bytes(_address);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            }
            else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            }
            else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            }
            else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            }
            else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            
            iaddr += (b1 * 16 + b2);
        }
        
        return address(iaddr);
    }
}