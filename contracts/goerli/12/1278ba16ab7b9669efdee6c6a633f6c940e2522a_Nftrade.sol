/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/Nftrade.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.6 <0.9.0;

////// src/Nftrade.sol
/* pragma solidity ^0.8.6; */

interface NFT {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function getApproved(uint256 _tokenId) external view returns (address);
}

contract Nftrade {
    struct Trade {
        uint256 ethAmount;
        uint256 tokenId;
        address nftContractAddress;
        address creator;
        bool isPaid;
    }

    event TradeCreated(bytes32 indexed tradeId);

    uint256 public immutable feePercent = 2; // 2%
    address payable public owner;
    mapping(bytes32 => Trade) public trades;

    constructor(address payable _owner) {
        owner = _owner;
    }

    function changeOwner(address payable _owner) external {
        require(owner == msg.sender, "Unauthorized");
        owner = _owner;
    }

    function listNFTForSale(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _ethAmount
    ) external returns (bytes32) {
        NFT nft = NFT(_nftContractAddress);

        require(
            nft.ownerOf(_tokenId) == msg.sender &&
                nft.getApproved(_tokenId) == address(this),
            "Unable to create trade"
        );

        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        Trade memory trade = Trade(
            _ethAmount,
            _tokenId,
            _nftContractAddress,
            msg.sender,
            false
        );
        bytes32 tradeId = keccak256(
            abi.encodePacked(
                _ethAmount,
                _tokenId,
                _nftContractAddress,
                msg.sender,
                block.timestamp
            )
        );
        trades[tradeId] = trade;

        emit TradeCreated(tradeId);
        return tradeId;
    }

    function offerToBuyNFT(address _nftContractAddress, uint256 _tokenId)
        external
        payable
        returns (bytes32)
    {
        Trade memory trade = Trade(
            msg.value,
            _tokenId,
            _nftContractAddress,
            msg.sender,
            true
        );
        bytes32 tradeId = keccak256(
            abi.encodePacked(
                msg.value,
                _tokenId,
                _nftContractAddress,
                msg.sender,
                block.timestamp
            )
        );
        trades[tradeId] = trade;

        emit TradeCreated(tradeId);
        return tradeId;
    }

    function completeTrade(bytes32 _tradeId) external payable {
        Trade memory trade = trades[_tradeId];

        require(msg.sender != trade.creator, "Cannot complete trade");

        NFT nft = NFT(trade.nftContractAddress);

        uint256 commission = (trade.ethAmount / 100) * feePercent;
        bool sent;

        // Seller
        if (trade.isPaid) {
            require(
                nft.ownerOf(trade.tokenId) == msg.sender &&
                    nft.getApproved(trade.tokenId) == address(this),
                "Unable to create trade"
            );

            (sent, ) = owner.call{value: commission}("");
            require(sent, "Failed to send commission");
            (sent, ) = msg.sender.call{value: trade.ethAmount - commission}("");
            require(sent, "Failed to send payment");

            nft.safeTransferFrom(msg.sender, trade.creator, trade.tokenId);

            return;
        }

        // Buyer
        require(msg.value == trade.ethAmount);

        (sent, ) = owner.call{value: commission}("");
        require(sent, "Failed to send commission");
        (sent, ) = trade.creator.call{value: trade.ethAmount - commission}("");
        require(sent, "Failed to send payment");

        nft.safeTransferFrom(address(this), msg.sender, trade.tokenId);

        delete trades[_tradeId];
    }

    function cancelTrade(bytes32 _tradeId) external {
        Trade memory trade = trades[_tradeId];

        require(msg.sender == trade.creator, "Cannot cancel trade");

        // Buyer
        if (trade.isPaid) {
            (bool sent, ) = msg.sender.call{value: trade.ethAmount}("");
            require(sent, "Failed to send payment");
            delete trades[_tradeId];
            return;
        }

        NFT nft = NFT(trade.nftContractAddress);
        nft.safeTransferFrom(
            address(this),
            address(trade.creator),
            trade.tokenId
        );

        delete trades[_tradeId];
    }

    // Needed to receive tokens from safeTransferFrom
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return this.onERC721Received.selector;
    }
}