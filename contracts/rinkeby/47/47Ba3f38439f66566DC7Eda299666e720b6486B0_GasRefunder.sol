// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title NFTC Gas Refunder
 * @author @NiftyMike, NFT Culture
 * @notice Some code cribbed from Open Zeppelin Ownable.sol.
 * @dev Community available Bulk Gas Refunder.
 * Purpose of this contract is to just make it easier and cheaper to send
 * out refunds for gas issues.
 */
contract GasRefunder {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function executeRefunds(
        address[] memory addresses,
        uint256[] memory amounts
    ) external payable {
        require(addresses.length == amounts.length, "Unmatched arrays");

        uint256 idx;
        uint256 sendAmount;
        for (idx = 0; idx < amounts.length; idx++) {
            sendAmount += amounts[idx];
        }

        require(sendAmount == msg.value, "Not right amount to send");

        for (idx = 0; idx < amounts.length; idx++) {
            // send the money.
            payable(addresses[idx]).transfer(amounts[idx]);
        }
    }

    function tip() external payable {
        // Thank you.
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function destroy() external onlyOwner {
        selfdestruct(payable(_owner));
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}