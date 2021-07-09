// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20MinterPauserCapped.sol";

contract SwapperContract {
    
    address private erc20 = 0x396eC402B42066864C406d1ac3bc86B575003ed8;
    address private burner = 0x1C5f60C7e1230895d32e3f4FE8173a970BbAE9C2;

    event SwapRequest(
        address indexed sender, 
        uint256 indexed amount, 
        string algorand
    );

    function doTransfer(uint256 _amount, string memory _algorand) public {
        ERC20MinterPauserCapped erc20Instance = ERC20MinterPauserCapped(erc20);
        erc20Instance.transferFrom(msg.sender, burner, _amount);
        emit SwapRequest(msg.sender, _amount, _algorand);
    }

}