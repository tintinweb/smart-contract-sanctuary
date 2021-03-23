/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity 0.7.6;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract TestVersion7 {
    using SafeMath for uint256;
    uint256 public result;
    
    function checkSubOperation(uint256 a, uint256 b) public {
        result = a.sub(b);
    }
    
    function checkDivOperation(uint256 a, uint256 b) public {
        result = a.div(b);
    }
    
    function checkMulOperation(uint256 a, uint256 b) public {
        result = a.mul(b);
    }
    
    function checkAddOperation(uint256 a, uint256 b) public {
        result = a.add(b);
    }
}