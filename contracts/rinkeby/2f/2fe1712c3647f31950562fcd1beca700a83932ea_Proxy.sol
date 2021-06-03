/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

contract Proxy  {

    address public owner;
    address public implementation;
        
    constructor(address _impl) public {
        owner = msg.sender;
        implementation = _impl;
    }

    function setImplementation(address _newImpl) public {
        require(msg.sender == owner);

        implementation = _newImpl;
    }
   
    fallback() external {
        address impl = implementation;
        assembly {
            let ptr := mload(0x40)
 
            // (1) copy incoming call data
            calldatacopy(ptr, 0, calldatasize())
 
             // (2) forward call to logic contract
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
 
            // (3) retrieve return data
            returndatacopy(ptr, 0, size)
 
            // (4) forward return data back to caller
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }   
    }
}