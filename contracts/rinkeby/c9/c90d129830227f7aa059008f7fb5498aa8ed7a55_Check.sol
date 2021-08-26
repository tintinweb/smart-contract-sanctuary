/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

contract Check {
    uint256 public number;
    
    function store(uint256 num, uint256 tum) public {
        uint check;
        check = num - tum;
        number = check;
    }

    function storeUnchecked(uint256 num, uint256 tum) public {
        uint check;
        unchecked {
            check = num - tum;
        }
        number = check;
    }

}