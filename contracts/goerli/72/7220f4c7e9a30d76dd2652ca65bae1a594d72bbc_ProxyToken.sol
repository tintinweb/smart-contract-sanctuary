/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

/// @title Proxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]> /// ProxyToken adapted and applied for token by pepihasenfuss.eth
pragma solidity >=0.4.22 <0.6.0;

contract ProxyToken {
    address internal masterCopy;

    bytes32 internal name32;
    uint256 private ownerPrices;

    mapping (address => uint256) private balances;
    mapping (address => mapping  (address => uint256)) private allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Deposit(address from, uint256 value);
    event Deployment(address owner, address theContract);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    constructor(address _masterCopy) public payable
    {
      masterCopy = _masterCopy;
    }
    
    function () external payable
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, masterCopy)
                return(0, 0x20)
            }

            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}