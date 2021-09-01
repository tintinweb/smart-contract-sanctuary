/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.6;

interface ITransfer {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

// MPC management means multi-party validation.
// MPC signing likes Multi-Signature is more sercure than use private key directly.
contract MPCManageable {
    address public mpc;
    address public pendingMPC;

    uint256 public constant delay = 2*24*3600;
    uint256 public delayMPC;

    modifier onlyMPC() {
        require(msg.sender == mpc, "MPC: only mpc");
        _;
    }

    event LogChangeMPC(address indexed oldMPC, address indexed newMPC, uint256 indexed effectiveTime);
    event LogApplyMPC(address indexed oldMPC, address indexed newMPC, uint256 indexed applyTime);

    constructor(address _mpc) {
        require(_mpc != address(0), "MPC: mpc is the zero address");
        mpc = _mpc;
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

contract NFTRouter is MPCManageable {
    uint256 public feePerTransaction;
    uint256 public immutable cID;

    address public constant factory = address(0);
    address public constant wNATIVE = address(0);

    event LogAnySwapIn(bytes32 indexed txhash, address indexed token, address indexed to,
                       uint256 tokenId, uint256 fromChainID, uint256 toChainID);
    event LogAnySwapOut(address indexed token, address indexed from, address indexed to,
                        uint256 tokenId, uint256 fromChainID, uint256 toChainID);
    event LogAdjustFee(uint256 indexed oldFee, uint256 indexed newFee);

    constructor(address _mpc) MPCManageable(_mpc) {
        uint256 chainID;
        assembly {chainID := chainid()}
        cID = chainID;
    }

    // adjust fee per cross-chain transaction
    function adjustFee(uint256 _newFee) external onlyMPC {
        emit LogAdjustFee(feePerTransaction, _newFee);
        feePerTransaction = _newFee;
    }

    // swapin `tokenId` of `token` in `fromChainID` to recipient `to` on this chainID
    function anySwapInAuto(
        bytes32 txs,
        address token,
        address to,
        uint256 tokenId,
        uint256 fromChainID
    ) external onlyMPC {
        ITransfer(token).safeTransferFrom(address(this), to, tokenId);
        emit LogAnySwapIn(txs, token, to, tokenId, fromChainID, cID);
    }

    // swapout `tokenId` of `token` from this chain to `toChainID` chain with recipient `to`
    function anySwapOut(
        address token,
        address to,
        uint256 tokenId,
        uint256 toChainID
    ) external payable {
        require(msg.value >= feePerTransaction, "NFTRouter: not enough fee");
        ITransfer(token).safeTransferFrom(msg.sender, address(this), tokenId);
        emit LogAnySwapOut(token, msg.sender, to, tokenId, cID, toChainID);
    }

    // make this router contract can receive erc721 token
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return NFTRouter.onERC721Received.selector;
    }
}