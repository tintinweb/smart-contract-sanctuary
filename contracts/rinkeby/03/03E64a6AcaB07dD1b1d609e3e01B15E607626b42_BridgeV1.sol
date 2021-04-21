/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity ^0.8.0;

interface IBridgeV1 {

    function SwapOut(uint256 amount, address swapInAddress)
    external
    returns (bool);

    
    function SwapIn(
        bytes32 txHash,
        address to,
        uint256 amount
    ) external returns (bool);

  
    event LogSwapOut(
        address indexed swapOutAddress,
        address indexed swapInAddress,
        uint256 amount
    );


    event LogSwapIn(
        bytes32 indexed txHash,
        address indexed swapInAddress,
        uint256 amount
    );
}

contract BridgeV1 is IBridgeV1 {
    function SwapOut(
        uint256 amount,
        address swapInAddress
    ) external override returns (bool) {
        emit LogSwapOut(msg.sender, swapInAddress, amount);
        return true;
    }

    function SwapIn(
        bytes32 txHash,
        address to,
        uint256 amount
    ) external override returns (bool) {
        emit LogSwapIn(txHash, to, amount);
        return true;
    }
}