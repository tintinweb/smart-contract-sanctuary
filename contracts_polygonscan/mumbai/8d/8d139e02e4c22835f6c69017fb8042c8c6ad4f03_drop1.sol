/**
 *Submitted for verification at polygonscan.com on 2021-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


interface Origin {
    //function punkIndexToAddress(uint index) external view returns(address);
    function getAxie(uint256 _axieId) external view returns(address,uint256,uint256,uint256);
    function birthAxie(address _to, uint256 _dna, uint256 _bornAt) external returns (uint256);      
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
    uint256 nonce = 1;

    struct dnaStruct {
        uint8 class;
        uint8 color;
    }


    constructor(address _core) {
        core = _core;
    }

    function getAxie(uint256 _axieID) external view returns (address owner,uint256 dna,uint256 dataGame,uint256 bornAt) {
         (owner, dna, dataGame, bornAt) = Origin(core).getAxie(_axieID);
    }

    function setAxie() external returns (uint256) {
        
        

      
        uint256 bornAt = block.timestamp + (21*24*60*60);
        address to = msg.sender;
        uint256 dna;
        
        for(uint m=0;m<16;m++){
            dna = m == 0 ? dna = uint(_ramdom(m,6)) : dna |= uint256(_ramdom(m,6))<<4*m;
        }
        return Origin(core).birthAxie(to,dna,bornAt);
    }

    function random() external view returns(uint256) {
       uint256 index = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp)));
       return(index);
    }

    function _ramdom(uint256 _num, uint256 _max) public view returns(uint256) {
       uint256 index = uint256(keccak256(abi.encodePacked(_num, msg.sender, block.difficulty, block.timestamp))) % _max+1;
       return(index);
    }

}