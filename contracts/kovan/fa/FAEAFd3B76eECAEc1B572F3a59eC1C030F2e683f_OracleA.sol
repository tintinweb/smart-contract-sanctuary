/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface OracleInterface {
    function notifyContractOfBlock(uint16 chain, address contractAddress, uint blockConfirmations) external;
}

contract OracleA {
    
    event NotifyContractOfBlock(
        uint16 chain,
        address contractAddress,
        uint256 blockConfirmations
    );
    
    function notifyContractOfBlock(uint16 chain, address contractAddress, uint blockConfirmations) public {
        emit NotifyContractOfBlock(chain, contractAddress, blockConfirmations);
    }
    
}