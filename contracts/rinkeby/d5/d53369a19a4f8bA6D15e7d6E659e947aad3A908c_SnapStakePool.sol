/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

//interface for stake pool contract
interface BakePool{
    function iswhitelisted(uint256 _stakeid) external view returns(bool);
    function AllStakes(address _addr) external view returns(uint256[] memory);
    function Totalticket(address _addr) external view returns(uint256);
}

contract SnapStakePool{

     address public stakePoolAddr = 0x56c14A9aBf70dc3DD28A09433260cfeF4e7507e2;

 // function for check user is whitelisted or not
    function checkWhitelisted(address _addr) public view returns(bool){
        
        uint256 i;
    
        uint256[] memory stakes= BakePool(stakePoolAddr).AllStakes(_addr);
        if(stakes.length >= 1 ){
            for(i=0; i <= stakes.length; i++){
                if((BakePool(stakePoolAddr).iswhitelisted(stakes[i]) == true)){
                    return true;
                    break;
                }
              /*  else{
                    return false;
                }*/
            }
        }
        else{
            return false;
        }

    }
    // calulating ticket for whitelisted users
    function calculateTicket(address _addr) public view returns(uint256){
        uint256 ticket;
        require(checkWhitelisted(_addr),"you are not whitelisted");
        ticket = BakePool(stakePoolAddr).Totalticket(_addr);
        return ticket;
    }

    
}