/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

// MPC management means multi-party validation.
// MPC signing likes Multi-Signature is more secure than use private key directly.
contract MPCManageable {
    address public mpc;
    address public pendingMPC;

    uint256 public constant delay = 2*24*3600;
    uint256 public delayMPC;

    modifier onlyMPC() {
        require(msg.sender == mpc, "MPC: only mpc");
        _;
    }

    event LogChangeMPC(
        address indexed oldMPC,
        address indexed newMPC,
        uint256 indexed effectiveTime);

    event LogApplyMPC(
        address indexed oldMPC,
        address indexed newMPC,
        uint256 indexed applyTime);

    constructor(address _mpc) {
        require(_mpc != address(0), "MPC: mpc is the zero address");
        mpc = _mpc;
        emit LogChangeMPC(address(0), mpc, block.timestamp);
    }

    function changeMPC(address _mpc) external onlyMPC {
        require(_mpc != address(0), "MPC: mpc is the zero address");
        pendingMPC = _mpc;
        delayMPC = block.timestamp + delay;
        emit LogChangeMPC(mpc, pendingMPC, delayMPC);
    }

    function applyMPC() external {
        require(msg.sender == pendingMPC, "MPC: only pendingMPC");
        require(block.timestamp >= delayMPC, "MPC: time before delayMPC");
        emit LogApplyMPC(mpc, pendingMPC, block.timestamp);
        mpc = pendingMPC;
        pendingMPC = address(0);
        delayMPC = 0;
    }
}

interface IERC721Transfer {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC1155Transfer {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

contract NFTRouter is MPCManageable {
    uint256 public immutable cID;
    uint256 public feePerTransaction;
    uint256 public feePerUnitInBatch;

    constructor(
        address _mpc,
        uint256 _feePerTransaction,
        uint256 _feePerUnitInBatch
    ) MPCManageable(_mpc) {
        uint256 chainID;
        assembly {chainID := chainid()}
        cID = chainID;
        feePerTransaction = _feePerTransaction;
        feePerUnitInBatch = _feePerUnitInBatch;
    }

    // adjust base fee per transaction
    function adjustFeePerTransaction(uint256 newFee) external onlyMPC {
        emit LogAdjustFee(feePerTransaction, newFee, false);
        feePerTransaction = newFee;
    }

    // adjust unit fee in batch transfer
    function adjustFeePerUnitInBatch(uint256 newFee) external onlyMPC {
        emit LogAdjustFee(feePerUnitInBatch, newFee, true);
        feePerUnitInBatch = newFee;
    }

    // swapin `tokenId` of `token` in `fromChainID` to recipient `to` on this chainID
    function nft721SwapIn(
        bytes32 txHash,
        address token,
        address to,
        uint256 tokenId,
        uint256 fromChainID
    ) external onlyMPC {
        IERC721Transfer(token).safeTransferFrom(address(this), to, tokenId);
        emit LogNFT721SwapIn(txHash, token, to, tokenId, fromChainID, cID);
    }

    // swapin `amount` of `tokenId` of `token` in `fromChainID` to recipient `to` on this chainID
    function nft1155SwapIn(
        bytes32 txHash,
        address token,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 fromChainID
    ) external onlyMPC {
        IERC1155Transfer(token).safeTransferFrom(address(this), to, tokenId, amount, new bytes(0));
        emit LogNFT1155SwapIn(txHash, token, to, tokenId, amount, fromChainID, cID);
    }

    // swapin `amounts` of `tokenIds` of `token` in `fromChainID` to recipient `to` on this chainID
    function nft1155BatchSwapIn(
        bytes32 txHash,
        address token,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 fromChainID
    ) external onlyMPC {
        IERC1155Transfer(token).safeBatchTransferFrom(address(this), to, tokenIds, amounts, new bytes(0));
        emit LogNFT1155SwapInBatch(txHash, token, to, tokenIds, amounts, fromChainID, cID);
    }

    // swapout `tokenId` of `token` from this chain to `toChainID` chain with recipient `to`
    function nft721SwapOut(
        address token,
        address to,
        uint256 tokenId,
        uint256 toChainID
    ) external payable {
        _transferFee(0);
        IERC721Transfer(token).safeTransferFrom(msg.sender, address(this), tokenId);
        emit LogNFT721SwapOut(token, msg.sender, to, tokenId, cID, toChainID);
    }

    // swapout `amount` of `tokenId` of `token` from this chain to `toChainID` chain with recipient `to`
    function nft1155SwapOut(
        address token,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data,
        uint256 toChainID
    ) external payable {
        _transferFee(0);
        IERC1155Transfer(token).safeTransferFrom(msg.sender, address(this), tokenId, amount, data);
        emit LogNFT1155SwapOut(token, msg.sender, to, tokenId, amount, cID, toChainID);
    }

    // swapout `amounts` of `tokenIds` of `token` from this chain to `toChainID` chain with recipient `to`
    function nft1155BatchSwapOut(
        address token,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data,
        uint256 toChainID
    ) external payable {
        _transferFee(tokenIds.length);
        IERC1155Transfer(token).safeBatchTransferFrom(msg.sender, address(this), tokenIds, amounts, data);
        emit LogNFT1155SwapOutBatch(token, msg.sender, to, tokenIds, amounts, cID, toChainID);
    }

    function _transferFee(uint256 unitsInBatch) internal {
        uint256 needFee = feePerTransaction + unitsInBatch * feePerUnitInBatch;
        require(msg.value >= needFee, "NFTRouter: not enough fee");
        if (msg.value > 0) {
            (bool success,) = mpc.call{value: msg.value}(new bytes(0));
            require(success, "NFTRouter: transfer fee failed");
        }
    }

    // make this router contract can receive erc721 token
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return NFTRouter.onERC721Received.selector;
    }

    // make this router contract can receive erc1155 token
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return NFTRouter.onERC1155Received.selector;
    }

    // make this router contract can receive erc1155 token in batch
    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns (bytes4) {
        return NFTRouter.onERC1155BatchReceived.selector;
    }

    event LogAdjustFee(
        uint256 indexed oldFee,
        uint256 indexed newFee,
        bool isUnitFee);

    event LogNFT721SwapIn(
        bytes32 indexed txHash,
        address indexed token,
        address indexed to,
        uint256 tokenId,
        uint256 fromChainID,
        uint256 toChainID);

    event LogNFT1155SwapIn(
        bytes32 indexed txHash,
        address indexed token,
        address indexed to,
        uint256 tokenId,
        uint256 amount,
        uint256 fromChainID,
        uint256 toChainID);

    event LogNFT1155SwapInBatch(
        bytes32 indexed txHash,
        address indexed token,
        address indexed to,
        uint256[] tokenIds,
        uint256[] amounts,
        uint256 fromChainID,
        uint256 toChainID);

    event LogNFT721SwapOut(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 fromChainID,
        uint256 toChainID);

    event LogNFT1155SwapOut(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 amount,
        uint256 fromChainID,
        uint256 toChainID);

    event LogNFT1155SwapOutBatch(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256[] tokenIds,
        uint256[] amounts,
        uint256 fromChainID,
        uint256 toChainID);
}