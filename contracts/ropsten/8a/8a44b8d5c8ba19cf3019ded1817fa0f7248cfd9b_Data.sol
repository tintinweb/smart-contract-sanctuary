/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

contract Data {
    
    bytes32 internal storedData;
    
    constructor(bytes32 initialData) {
        storedData = initialData;
    }
    
    function get() public view returns(bytes32) {
        return storedData;
    }
}