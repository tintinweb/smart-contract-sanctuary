/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity >=0.4.22 <0.6.0;

contract ProxyGW {
    address internal masterCopy;

    mapping(uint256 => uint256) private tArr;
    address[]                   private owners;
    
    address internal GWF;                                                       // GroupWalletFactory contract
    mapping(uint256 => bytes)   private structures;

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