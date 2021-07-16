/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

contract Proxy {
    // Code position in storage is keccak256("WEARETHEFALCON") = "0x2188b6d4e73d37025fd2b6d16decd9bf9d2a93a5df9daed92a727a96b821546e"
    constructor(bytes memory constructData, address contractLogic) {
        // save the code address
        assembly { // solium-disable-line
            sstore(0x2188b6d4e73d37025fd2b6d16decd9bf9d2a93a5df9daed92a727a96b821546e, contractLogic)
        }
        (bool success, bytes memory result ) = contractLogic.delegatecall(constructData); // solium-disable-line
        require(success, "Construction failed");
    }

    fallback() external payable {
        assembly { // solium-disable-line
            let contractLogic := sload(0x2188b6d4e73d37025fd2b6d16decd9bf9d2a93a5df9daed92a727a96b821546e)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), contractLogic, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}