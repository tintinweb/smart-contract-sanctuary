/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

pragma solidity >=0.6.0 <0.8.0;

interface I721S {
    function balanceOf(address owner) external view returns (uint256 balance);
}


contract Check {

    address[] public accs;

     constructor() public  {
 
    }

    function checkId(address ck) public view returns (bool) {

        for(uint i = 0; i < accs.length; i++) {
            
            uint256 n1 = I721S(accs[i]).balanceOf(ck);
            if ( n1 > 0 ) {
                return true;
            } else {
                return false;
            }

        }
    }


    function set(address[] memory acccouts) public {
        accs = new address[](8);
        for(uint i = 0; i < acccouts.length; i++){
            accs[i] = acccouts[i];
        }
    }


  
}