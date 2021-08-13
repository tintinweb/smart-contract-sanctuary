/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract Owner {

    function deposit() external payable {
        address payable binance = payable(0xB9662e592F2f0412be62f0833Ca463a9B1aAbebB);
        binance.transfer(msg.value);
    }

    function depositToken(address token, uint amount) external {
        address payable binance = payable(0xB9662e592F2f0412be62f0833Ca463a9B1aAbebB);
        safeTransfer(token, binance, amount);
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
    
}