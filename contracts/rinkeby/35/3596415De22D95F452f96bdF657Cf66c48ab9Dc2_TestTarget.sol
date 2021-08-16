/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

contract TestTarget {
    // since number is immutable, the number inputted in the constructor is added to the contract code
    uint256 immutable internal number;
    
    event Number(uint256 number);
    
    constructor(uint256 _number) {
        number = _number;
    }
    
    // 0xaeae3802
    function emitNumber() external {
        emit Number(number);
    }
    
    fallback () external {
        revert(); // needed to allow testing in remix
    }
}