/**
 *Submitted for verification at polygonscan.com on 2021-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


interface Origin {
    //function punkIndexToAddress(uint index) external view returns(address);
    //function getAxie(uint256 _axieId) external view returns(address,uint256,uint256,uint256);
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

    struct dnaStruct {
        uint8 class;
        uint8 color;
    }


    constructor(address _core) {
        core = _core;
    }

    /*
    function getAxie(uint256 _axieID) external view returns (address owner,uint256 dna,uint256 dataGame,uint256 bornAt,uint256 parents, bytes32 name) {
         (owner, dna, dataGame, bornAt, parents, name) = Origin(core).getAxie(_axieID);
    }
    */

    function setAxie() external returns (uint256) {
        
        uint256 bornAt = block.timestamp + (21*24*60*60); // 21 days
        address to = msg.sender;
        uint256 dna;

        /*
        enum Genes {csd,cd,eyd,ead,bd,hd,td,md,pd,cr,eyr,ear,br,hr,tr,mr,pr,cu,eyu,eau,bu,hu,tu,mu,pu}
        Genes choice;
        Genes constant defaultChoice = Genes.class;

        uint[] memory chromosomes = new uint[](3);
        chromosomes[Genes.csd] = 6;
        chromosomes[Genes.cd] = 4;
        chromosomes[Genes.eyd] = 4;
        */

        dna = uint(1); // Origin

        for(uint m=1;m<=43;m++){
            if (m <= 19){
              dna = dna |= uint256(_exons(m,6))<<4*m;
            }
            else {
              dna = dna |= uint256(_exons(m,4))<<4*m;
            }
        }

        /*
        for(uint m=0;m<48;m++){
            dna = m == 0 ? dna = uint(_ramdom(m,6)) : dna |= uint256(_ramdom(m,6))<<4*m;
        }
        */
 

        /*
        uint256 class = _ramdom(1,6);
        uint256 cor = _ramdom(2,6);
        uint256 eyes = _ramdom(3,4);
        uint256 ears = _ramdom(4,4);
        uint256 back = _ramdom(5,5);
        uint256 horn = _ramdom(6,6);
        uint256 tail = _ramdom(7,5);
        uint256 mouth = _ramdom(8,4);
        */
        /*
        uint256 class2 = _ramdom(9,6);
        uint256 cor2 = _ramdom(10,6);
        uint256 eyes2 = _ramdom(11,4);
        uint256 ears2 = _ramdom(12,4);
        uint256 back2 = _ramdom(13,5);
        uint256 horn2 = _ramdom(14,6);
        uint256 tail2 = _ramdom(15,5);
        uint256 mouth2 = _ramdom(16,4);
        
        
        dna = uint256(mouth2);
        dna |= uint256(tail2)<<4;        
        dna |= uint256(horn2)<<8;
        dna |= uint256(back2)<<12;
        dna |= uint256(ears2)<<16;
        dna |= uint256(eyes2)<<20;
        dna |= uint256(cor2)<<24;
        dna |= uint256(class2)<<28;
       
       /* dna |= uint256(mouth)<<32;
        dna |= uint256(tail)<<36;        
        dna |= uint256(horn)<<40;
        dna |= uint256(back)<<44;
        dna |= uint256(ears)<<48;
        dna |= uint256(eyes)<<52;
        dna |= uint256(cor)<<56;
        dna |= uint256(class)<<60;*/

        return Origin(core).birthAxie(to,dna,bornAt,0);
    }

    function _exons(uint256 _num, uint256 _max) public view returns(uint256) {
       uint index = uint(keccak256(abi.encodePacked(_num, nonce, msg.sender, block.difficulty, block.timestamp))) % _max;
       index = index - 1;
       return(index);
    }

}