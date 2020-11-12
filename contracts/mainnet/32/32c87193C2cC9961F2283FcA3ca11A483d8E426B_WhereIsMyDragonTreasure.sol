// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./IERC1155Receiver.sol";
import "./ERC165.sol";
import "./IEthItem.sol";

contract WhereIsMyDragonTreasure is IERC1155Receiver, ERC165 {

    address private _source;
    uint256 private _legendaryCard;

    uint256 private _singleReward;
    uint256 private _legendaryCardAmount;
    uint256 private _startBlock;

    uint256 private _redeemed;

    constructor(address source, uint256 legendaryCard, uint256 legendaryCardAmount, uint256 startBlock) {
        _source = source;
        _legendaryCard = legendaryCard;
        _legendaryCardAmount = legendaryCardAmount;
        _startBlock = startBlock;
        _registerInterfaces();
    }

    function _registerInterfaces() private {
        _registerInterface(this.onERC1155Received.selector);
        _registerInterface(this.onERC1155BatchReceived.selector);
    }

    receive() external payable {
        if(block.number >= _startBlock) {
            payable(msg.sender).transfer(msg.value);
            return;
        }
        _singleReward = address(this).balance / _legendaryCardAmount;
    }

    function data() public view returns(uint256 balance, uint256 singleReward, uint256 startBlock, uint256 redeemed) {
        balance = address(this).balance;
        singleReward = _singleReward;
        startBlock = _startBlock;
        redeemed = _redeemed;
    }

    function onERC1155Received(
        address,
        address from,
        uint256 objectId,
        uint256 amount,
        bytes memory
    )
        public override
        returns(bytes4) {
        uint256[] memory objectIds = new uint256[](1);
        objectIds[0] = objectId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        _checkBurnAndTransfer(from, objectIds, amounts);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] memory objectIds,
        uint256[] memory amounts,
        bytes memory
    )
        public override
        returns(bytes4) {
        _checkBurnAndTransfer(from, objectIds, amounts);
        return this.onERC1155BatchReceived.selector;
    }

    function _checkBurnAndTransfer(address from, uint256[] memory objectIds, uint256[] memory amounts) private {
        require(msg.sender == _source, "Unauthorized Action");
        require(block.number >= _startBlock, "Redeem Period still not started");
        for(uint256 i = 0; i < objectIds.length; i++) {
            require(objectIds[i] == _legendaryCard, "Wrong Card!");
            _redeemed += amounts[i];
            payable(from).transfer(_singleReward * amounts[i]);
        }
        IEthItem(_source).burnBatch(objectIds, amounts);
    }
}