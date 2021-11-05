/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SwapEthBtc {
    
    struct SwapDetails {
        uint256 timelock;
        uint256 value;
        address payable depositEthTrader;
        address payable withdrawEthTrader;
        bytes32 secretLock;
        bool isOpened;
    }
    
    uint swapID = 1;
    mapping (uint => SwapDetails) private swaps;

    // opens swap, takes two values: ether address of the second trader and secret lock
    // secret lock example: 0xba1bea57be20fadea2c3b617892a1a9fdf2b1b52b190356bafdfcd13db8521ef
    function openSwap(address payable _withdrawTrader, bytes32 _secretLock) public payable returns(uint _swapID) {
        swaps[swapID] = SwapDetails(block.timestamp + 1 days, msg.value, payable(msg.sender), _withdrawTrader, _secretLock, true);
        swapID += 1;
        return (swapID - 1);
    }

    //closes swap, if it isn't expired, takes swap ID and secret key from second trader
    // secret key example: 0x20737881218eca51cd901a64b4a02ccec0e276dc531a5543b144d6e40e2bc2d4
    function closeSwap(uint _swapID, bytes memory _secretKey) public {
        require(swaps[_swapID].isOpened == true, "Swap is closed!");
        require(block.timestamp <= swaps[_swapID].timelock, "Swap is expired, use func 'expireSwap'");
        require(swaps[_swapID].secretLock == sha256(abi.encodePacked(_secretKey)), "Wrong secret key!");
        swaps[_swapID].withdrawEthTrader.transfer(swaps[_swapID].value);
        swaps[_swapID].isOpened = false;
    }
    
    //if swap is expired, trader can get his ether back by swap ID
    function expireSwap(uint _swapID) public {
        require(swaps[_swapID].isOpened == true, "Swap is closed!");
        require(swaps[_swapID].timelock <= block.timestamp, "Swap isn't expired!");
        swaps[_swapID].depositEthTrader.transfer(swaps[_swapID].value);
        swaps[_swapID].isOpened = false;
    }

    //returns all info about swap by swap ID
    function swapInfo(uint _swapID) public view returns (SwapDetails memory _swap) {
        return swaps[_swapID];
    }
}