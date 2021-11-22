/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

pragma solidity 0.6.6;

// import "./IVault.sol";

contract AlpacaHelper { 
    address testContract;
    
    constructor() public {
        testContract = 0xf9d32C5E10Dd51511894b360e6bD39D7573450F9;
    }
    
    function getNextPosition() public returns (uint256){
        // uint256 pos = IVault(testContract).nextPositionID();
        (bool success, bytes memory returnData) = testContract.call(
          abi.encodeWithSelector(0x1c824905)
        );
        if (success) {
            return abi.decode(returnData, (uint256));
        }
        return 0;
    }
}