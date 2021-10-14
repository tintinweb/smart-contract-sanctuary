/**
 *Submitted for verification at polygonscan.com on 2021-10-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


interface Origin {
    function birthAxie(address _to, uint256 _dna, uint256 _bornAt,uint256) external returns (uint256);      
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}

contract drop1 {

    using SafeMath for uint256;

    // Core contract
    address internal core;
    // Random index assignment
    uint256 internal nonce = 0;

 
    uint256 public parents;

    constructor(address _core) {
        core = _core;
    }
    
    function setParents(uint256 mom, uint256 dad) public returns (uint256) {
        
        uint256 breed = uint256(uint8(parents>>96)) + 1;
        parents = uint256(mom);
        parents |= dad<<48;
        parents |= breed<<96;
        return parents;
    }
    
    function newBreed() external returns(uint256 breed){
       uint momdad   = uint256(uint96(parents));
       breed    = uint256(uint8(parents>>96));
       breed++;
      
       parents = uint256(momdad);
       parents |= breed<<96;
       
    }
    
    
     function getParents() external view returns (uint256 mom,uint256 dad,uint256 breed) {
       mom   = uint256(uint48(parents));
       dad   = uint256(uint48(parents>>48));
       breed = uint256(uint8(parents>>96));
    }
    

    function setAxie() external returns (uint256) {
        
        uint256 bornAt = block.timestamp + (21*24*60*60); // 21 days
        address to = msg.sender;
        uint256 dna;
        uint256 genes;
        
        for(uint256 helix=0; helix<=42; helix++){
            genes = 0;
            
            if(helix <= 2){             // Patern (D,R1,R2) 0 Normal; 1 Curly
               genes = _exons(helix,10);
               if(genes > 1){
                   genes = 0;
               }
            }
            
            if(helix >= 3 && helix <= 11){             // Colors (D,R1,R2) - 4 colors
               genes = _exons(helix,15);
               if(genes > 3 && genes < 13){
                   genes = 0;
               }
               if(genes >= 13) {
                   genes = 1;
               }
            }
            
            if(helix >= 6 && helix <= 11){             // Eyes,mouth (D,R1,R2) - 4 elements
               genes = _exons(helix,10);
               if(genes > 3 && genes < 8){
                   genes = 0;
               } 
               if(genes >= 8) {
                   genes = 1;
               }
            }
            
            if(helix >= 12 && helix <= 23){             // Ears,back,horn,tail (D,R1,R2) - 6 elements
               genes = _exons(helix,13);
               
               if(genes > 5 && genes < 10){
                   genes = 0;
               } 
               if(genes >= 10 ) {
                   genes = 1;
               }
            }
            
            if(helix >= 24){               // Class (D,R1,R2) - 6 elements
               genes = _exons(helix,48);
               
               if(genes > 5 && genes < 12){
                   genes = 0;
               } 
               if(genes >= 12 && genes < 23) {
                   genes = 2;
               }
               if(genes >= 23 && genes < 29) {
                   genes = 3;
               }
               if(genes >= 29 && genes < 35) {
                   genes = 4;
               }
               if(genes >= 35) {
                   genes = 5;
               }
            }
            
            dna = helix == 0 ? dna = uint256(15) : dna |= uint256(genes)<<4*helix;

        }
        dna |= uint256(uint8(0))<<180;

        
        nonce++;

        return Origin(core).birthAxie(to,dna,bornAt,0);
    }

    function _exons(uint256 _helix, uint256 _endgen) public view returns(uint256) {
       uint256 index = uint(keccak256(abi.encodePacked(_helix, nonce, msg.sender, block.difficulty, block.timestamp))) % _endgen;
       //uint256 mode = index % _endgen;
       return(index);
    }

}