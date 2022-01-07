/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAlpacaWorker
{

    function ApproveToken(address token, address to, uint256 value) external;
    function ClosePosition(uint256 id, uint slippage) external returns (uint256);
    function ForcedClose(uint256 amount) external;
    function TotalVal() external view returns(uint256);
    function transferOwnership(address newOwner) external;
}


contract TestContractCall
{
    
    address public AlpacaWorkerAddress;
    function ClosePosition(uint256 posId, uint256 slippage) public {
        IAlpacaWorker(AlpacaWorkerAddress).ClosePosition(posId, slippage);
    }
    function ForcedClose(uint256 amount) public{
        IAlpacaWorker(AlpacaWorkerAddress).ForcedClose(amount);
    }
    function TransferOwnership(address newOwner) public {
        IAlpacaWorker(AlpacaWorkerAddress).transferOwnership(newOwner);
    }
    function SetAlpacaWorker(address newAddress) public {
        AlpacaWorkerAddress = newAddress;
    }
    
}