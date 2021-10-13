/**
 *Submitted for verification at polygonscan.com on 2021-10-12
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

    struct dnaStruct {
        uint8 class;
        uint8 color;
    }


    constructor(address _core) {
        core = _core;
    }

    function setAxie() external returns (uint256) {
        
        uint256 bornAt = block.timestamp + (21*24*60*60); // 21 days
        address to = msg.sender;
        uint256 dna;

        dna = uint(1);
        dna = dna |= uint256(2)>>256-(4*1);
        dna = dna |= uint256(3)>>256-(4*2);
        dna = dna |= uint256(4)>>256-(4*3);
        dna = dna |= uint256(5)>>256-(4*4);
        


        /*
        for(uint m=1;m<=43;m++){
            
            uint256 _genes = _exons(m,6);
            if(m > 19) {
                if(_genes > 4){
                    _genes = 0;
                }
            }
            dna = dna |= uint256(_genes)<<4*m;

        }*/

        return Origin(core).birthAxie(to,dna,bornAt,0);
    }

    function _exons(uint256 _num, uint256 _max) public view returns(uint256) {
       uint index = uint(keccak256(abi.encodePacked(_num, nonce, msg.sender, block.difficulty, block.timestamp)));
       uint256 mode = index % _max;
       return(mode);
    }

}