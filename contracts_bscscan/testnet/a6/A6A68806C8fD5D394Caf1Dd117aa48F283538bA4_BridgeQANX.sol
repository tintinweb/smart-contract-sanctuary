/**
 *Submitted for verification at BscScan.com on 2021-10-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// MINIMAL ERC20 INTERFACE FOR QANX TRANSFERABILITY
interface TransferableERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Signed {

    // THE ADDRESSES PERMITTED TO SIGN WITHDRAWAL REQUESTS UP TO X AMOUNT
    mapping(address => uint256) internal signers;

    // SET NO LIMIT SIGNER ON DEPLOYMENT
    constructor() {
        signers[msg.sender] = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    /*inline test support fnc*/ function getLimit(address signer) external view returns (uint256) { return signers[signer]; }

    // METHOD TO SET WITHDRAWAL SIGNER / OPERATOR ADDRESS
    function setSigner(address signer, uint256 limit) external {
        require(signer != address(0) && signers[msg.sender] == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        signers[signer] = limit;
    }

    // METHOD TO VERIFY WITHDRAWAL SIGNATURE OF A GIVEN TXID
    function verifySignature(bytes32 txid, bytes memory signature, uint256 amount) internal view returns (bool) {

        // SIGNATURE VARIABLES FOR ECRECOVER
        bytes32 r;
        bytes32 vs;

        // SPLIT SIGNATURE INTO r + vs
        assembly {
            r := mload(add(signature, 32))
            vs := mload(add(signature, 64))
        }

        // DETERMINE s AND v FROM vs
        bytes32 s = vs & 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        uint8 v = 27 + uint8(uint256(vs) >> 255);

        // RECOVER & VERIFY SIGNER IDENTITY
        return amount < signers[ecrecover(txid, v, r, s)];
    }
}

contract BridgeQANX is Signed {

    // POINTS TO THE OFFICIAL QANX CONTRACT
    TransferableERC20 private _qanx = TransferableERC20(0xAAA7A10a8ee237ea61E8AC46C50A8Db8bCC1baaa);

    constructor(TransferableERC20 qanx_) Signed() {
        _qanx = qanx_;
    }

    // STORES NONCES FOR CROSS-CHAIN TRANSFERS (msg.sender => depositChainId => withdrawChainId = nonce)
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private _nonces;

    // FETCH NONCE OF SENDER BASED ON CHAIN IDS
    function getNonce(address sender, uint256 depositChainId, uint256 withdrawChainId) external view returns (uint256) {
        return _nonces[sender][depositChainId][withdrawChainId];
    }

    // DEPOSIT TOKENS ON THE SOURCE CHAIN OF THE BRIDGE
    function bridgeDeposit(address beneficiary, uint256 amount, uint256 withdrawChainId) external returns (bytes32) {

        // CALCULATE TXID AND INCREMENT NONCE
        bytes32 txid = keccak256(abi.encode(msg.sender, block.chainid, withdrawChainId, _nonces[msg.sender][block.chainid][withdrawChainId]++, beneficiary, amount));

        // TRANSFER TOKENS FROM MSG SENDER TO THIS CONTRACT FOR THE AMOUNT TO BE BRIDGED
        require(_qanx.transferFrom(msg.sender, address(this), amount));

        // RETURN TXID
        return txid;
    }

    // WITHDRAW TOKENS ON THE TARGET CHAIN OF THE BRIDGE
    function bridgeWithdraw(address beneficiary, uint256 amount, uint256 depositChainId, bytes calldata signature) external returns (bool) {

        // CALCULATE TXID AND INCREMENT NONCE
        bytes32 txid = keccak256(abi.encode(msg.sender, depositChainId, block.chainid, _nonces[msg.sender][depositChainId][block.chainid]++, beneficiary, amount));
        
        // VERIFY SIGNATURE
        require(verifySignature(txid, signature, amount), "ERR_SIG");

        // COLLECT FEE
        uint256 fee = amount / 100 * feePercentage;
        feesCollected += fee;

        // TRANSFER TOKENS TO BENEFICIARY
        require(_qanx.transfer(beneficiary, amount - fee), "ERR_TXN");
        return true;
    }

    // FEE PERCENTAGE AND TOTAL COLLECTED FEES
    uint256 private feePercentage;
    uint256 private feesCollected;

    // FEE TRANSPARENCY FUNCTION
    function getFeeInfo() external view returns (uint256[2] memory) {
        return [feePercentage, feesCollected];
    }

    // SETTER FOR FEE PERCENTAGE (MAX 5%)
    function setFeePercentage(uint8 _feePercentage) external {
        require(signers[msg.sender] > 0 && _feePercentage <= 5);
        feePercentage = _feePercentage;
    }

    // METHOD TO WITHDRAW TOTAL COLLECTED FEES SO FAR
    function withdrawFees(address beneficiary) external {
        require(signers[msg.sender] > 0);
        require(_qanx.transfer(beneficiary, feesCollected), "ERR_TXN");
        feesCollected = 0;
    }
}