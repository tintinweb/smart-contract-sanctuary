pragma solidity =0.8.9;

import "./CTF.sol";

interface IFlagReciever {
    function recieveFlag(bytes32) external;
}

contract Level3 is CTF {
    constructor() CTF() {}
    
    function obtainFlag() external {
        require(isContract(msg.sender), "not a contract");
        IFlagReciever(msg.sender).recieveFlag(flag);
    }
    
    // SPDX-License-Identifier: MIT
    // OpenZeppelin Contracts v4.3.2 (utils/Address.sol)
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

pragma solidity =0.8.9;

contract CTF {
    address internal owner;
    bytes32 internal flag;
    
    constructor() {
        owner = msg.sender;
        flag = keccak256(abi.encodePacked(block.timestamp));
    }
    
    function bye() external {
        require(msg.sender == owner);
        selfdestruct(payable(msg.sender));
    }
}