/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// MINIMAL ERC20 INTERFACE FOR QANX TRANSFERABILITY
interface TransferableERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Signed {

    // THE ADDRESS PERMITTED TO SIGN WITHDRAWAL REQUESTS
    address internal signer;

    // THE ADDRESS PERMITTED TO SET WITHDRAWAL SIGNER ADDRESS
    address private signerDelegator;

    // SET OPERATOR ADDRESS TO CONTRACT DEPLOYER BY DEFAULT
    constructor() {
        signerDelegator = msg.sender;
    }

    /*inline test support fnc*/ function getAddress(uint8 role) external view returns (address) { if(role == 0) return signer; if(role == 1) return signerDelegator; return address(0);}

    // METHOD TO SET WITHDRAWAL SIGNER / OPERATOR ADDRESS
    function setAddress(uint8 role, address newAddress) external {
        require(msg.sender == signerDelegator);
        if(role == 0) {
            signer = newAddress;
        }
        if(role == 1) {
            signerDelegator = newAddress;
        }
    }

    // METHOD TO VERIFY WITHDRAWAL SIGNATURE OF A GIVEN TXID
    function verifySignature(bytes32 txid, bytes memory signature) internal view returns (bool) {

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
        return ecrecover(txid, v, r, s) == signer;
    }
}

contract BridgeQANX is Signed {

    // POINTS TO THE OFFICIAL QANX CONTRACT
    TransferableERC20 private _qanx;

    // ADDRESS OF THE OFFICIAL QANX CONTRACT WILL BE PROVIDED UPON CONSTRUCT
    constructor(TransferableERC20 qanx_) Signed() {
        _qanx = qanx_;
    }

    // REPRESENTS A BRIDGE TRANSACTION
    struct BridgeTX {
        address beneficiary;      // BENEFICIARY ON WITHDRAWAL CHAIN
        uint256 amount;           // AMOUNT WITHDRAWABLE
        uint256 depositChainId;   // CHAIN ID OF THE DEPOSIT CHAIN
        uint256 withdrawChainId;  // CHAIN ID OF THE WITHDRAWAL CHAIN
    }

    // HOLDS ALL BRIDGE TRANSACTIONS MAPPED BY THEIR KECCAK256 HASH
    mapping (bytes32 => BridgeTX) private _btxs;

    // STORES NONCES FOR CROSS-CHAIN TRANSFERS
    mapping (bytes32 => uint256) private _nonces;

    // QUERY A BRIDGE TRANSACTION BY HASH
    function getBridgeTx(bytes32 btxHash) external view returns (BridgeTX memory) {
        return _btxs[btxHash];
    }

    // FETCH NONCE BASED ON KEY AND SIGNATURE
    function getNonce(bytes32 nonceKey, bytes calldata signature) external view returns (uint256) {
        require(verifySignature(nonceKey, signature), "ERR_SIG");
        return _nonces[nonceKey];
    }

    // DEPOSIT TOKENS ON THE SOURCE CHAIN OF THE BRIDGE
    function bridgeDeposit(address beneficiary, uint256 amount, uint256 withdrawChainId) external returns (bytes32) {

        // CALCULATE TXID AND INCREMENT NONCE
        bytes32 nonceKey = keccak256(abi.encode(msg.sender, block.chainid, withdrawChainId));
        bytes32 txid = keccak256(abi.encode(nonceKey, _nonces[nonceKey]++, beneficiary, amount));

        // TRANSFER TOKENS FROM MSG SENDER TO THIS CONTRACT FOR THE AMOUNT TO BE BRIDGED
        require(_qanx.transferFrom(msg.sender, address(this), amount));

        // REGISTER BRIDGE TX
        _btxs[txid] = BridgeTX(beneficiary, amount, block.chainid, withdrawChainId);

        // RETURN TXID
        return txid;
    }

    // WITHDRAW TOKENS ON THE TARGET CHAIN OF THE BRIDGE
    function bridgeWithdraw(address beneficiary, uint256 amount, uint256 depositChainId, bytes calldata signature) external returns (bool) {

        // CALCULATE TXID AND INCREMENT NONCE
        bytes32 nonceKey = keccak256(abi.encode(msg.sender, depositChainId, block.chainid));
        bytes32 txid = keccak256(abi.encode(nonceKey, _nonces[nonceKey]++, beneficiary, amount));
        
        // VERIFY SIGNATURE
        require(verifySignature(txid, signature), "ERR_SIG");

        // REGISTER BRIDGE TX
        _btxs[txid] = BridgeTX(beneficiary, amount, depositChainId, block.chainid);

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

    // SETTER FOR FEE PERCENTAGE (MAX 5%)
    function setFeePercentage(uint8 _feePercentage) external {
        require(msg.sender == signer && _feePercentage <= 5);
        feePercentage = _feePercentage;
    }

    // METHOD TO WITHDRAW TOTAL COLLECTED FEES SO FAR
    function withdrawFees(address beneficiary) external {
        require(msg.sender == signer);
        require(_qanx.transfer(beneficiary, feesCollected), "ERR_TXN");
        feesCollected = 0;
    }
}