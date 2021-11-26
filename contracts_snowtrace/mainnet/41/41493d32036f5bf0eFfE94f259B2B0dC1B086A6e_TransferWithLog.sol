// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

// solhint-disable-next-line
pragma solidity ^0.8.0;

/// TransferWithLog is a replacement for a standard ETH transfer, with an added
/// log to make it easily searchable.
contract TransferWithLog is Context {
    string public constant NAME = "TransferWithLog";

    event LogTransferred(address indexed from, address indexed to, uint256 amount);

    function transferWithLog(address payable to) external payable {
        require(to != address(0x0), "TransferWithLog: invalid empty recipient");
        uint256 amount = msg.value;
        // `call` is used instead of `transfer` or `send` to avoid a hard-coded
        // gas limit.
        // See https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "TransferWithLog: transfer failed");
        emit LogTransferred(_msgSender(), to, amount);
    }
}