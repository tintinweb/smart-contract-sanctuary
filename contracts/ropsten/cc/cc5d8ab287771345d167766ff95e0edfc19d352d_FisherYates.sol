pragma solidity 0.4.25;

contract FisherYates {
    using SafeMath for uint;

    function range(uint length) internal pure returns (uint[] memory r) {
        r = new uint[](length);
        for (uint i = 0; i < r.length; i++) {
          r[i] = i;
        }
    }

    function random(uint _upper, uint _blockn, address entropy, uint index) internal view returns (uint randomNumber)
      {
        return maxRandom(_blockn, entropy, index) % _upper;
      }

    function maxRandom(uint _blockn, address entropy, uint index) internal view returns (uint randomNumber) {
        return uint256(keccak256(abi.encodePacked(blockhash(_blockn), entropy, index)));
    }

    uint[] public cardIndices = range(52);
    
    function fisherYates(uint[] memory r) internal view returns (uint[] memory) {
        uint n = r.length - 1;
        for (uint i = n; i > 0; i--) {
            uint j = random(i, block.number, msg.sender, 52 - n);
            uint tmp = r[i];
            r[i] = r[j];
            r[j] = tmp;
        }
        return r;
    }
    
    uint[] public demoShuffle = fisherYates(cardIndices);
}


/** ------------------------------- **/

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}