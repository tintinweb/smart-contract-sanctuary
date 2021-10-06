/**
 *Submitted for verification at Etherscan.io on 2021-10-06
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
    function openSwap(address payable _withdrawTrader, bytes32 _secretLock) public payable {
        swaps[swapID] = SwapDetails(block.timestamp + 1 days, msg.value, payable(msg.sender), _withdrawTrader, _secretLock, true);
        swapID += 1;
    }

    //closes swap, if it isn't expired, takes swap ID and secret key from second trader
    function closeSwap(uint _swapID, bytes memory _secretKey) public {
        require(block.timestamp <= swaps[_swapID].timelock, "Swap is expired, use func 'expireSwap'");
        require(swaps[_swapID].secretLock == sha256(abi.encodePacked(_secretKey)), "Wrong secret key!");
        swaps[_swapID].withdrawEthTrader.transfer(swaps[_swapID].value);
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