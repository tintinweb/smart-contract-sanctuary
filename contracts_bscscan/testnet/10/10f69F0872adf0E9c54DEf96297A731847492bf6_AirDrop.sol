// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "./context.sol";
import "./erc1363.sol";
import "./ierc20.sol";
import "./erc1363.sol";
import "./ierc1363receiver.sol";
import "./ierc1363spender.sol";

contract AirDrop is Context, ERC165, IERC1363Receiver, IERC1363Spender {
    ERC1363 public wrappedAsset;
    uint256 public amount;
    uint256 public balance;
    mapping(address => bool) public claimed;

    bytes4 private constant INTERFACE_ID_ERC1363_RECEIVER = 0x88a7ca5c;
    bytes4 private constant INTERFACE_ID_ERC1363_SPENDER = 0x7b04a2d0;

    constructor(address _wrappedAsset, uint256 _amount) {
        require(_wrappedAsset != address(0), "Cannot be zero address");
        require(_amount > 0, "Amount must be greater than 0");
        wrappedAsset = ERC1363(_wrappedAsset);
        require(wrappedAsset.supportsInterface(type(IERC1363).interfaceId));
        amount = _amount;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == INTERFACE_ID_ERC1363_RECEIVER ||
            interfaceId == INTERFACE_ID_ERC1363_SPENDER ||
            super.supportsInterface(interfaceId);
    }

    function onTransferReceived(
        address, /* operator */
        address, /* from */
        uint256 value,
        bytes memory /* data */
    ) external override returns (bytes4) {
        require(
            _msgSender() == address(wrappedAsset),
            "wrappedAsset is not message sender"
        );
        balance += value;
        return INTERFACE_ID_ERC1363_RECEIVER;
    }

    function onApprovalReceived(
        address owner,
        uint256 value,
        bytes memory /* data */
    ) external override returns (bytes4) {
        require(
            _msgSender() == address(wrappedAsset),
            "wrappedAsset is not message sender"
        );
        bool succeess = IERC20(wrappedAsset).transferFrom(
            owner,
            address(this),
            value
        );
        require(succeess, "Failed to transfer wrappedAsset");
        balance += value;
        return INTERFACE_ID_ERC1363_SPENDER;
    }

    function claim() public {
        require(claimed[_msgSender()] == false, "Already claimed");
        require(balance >= amount, "Insufficient funds");
        claimed[_msgSender()] = true;
        bool success = IERC20(wrappedAsset).transfer(
            address(_msgSender()),
            amount
        );
        balance -= amount;
        require(success, "Failed to send airdrop");
    }
}