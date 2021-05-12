/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

pragma solidity ^0.5.0;

contract RevieveToken {
    address owner = msg.sender;

    mapping(uint256 => bool) usedNonces;
    
    uint256 totalAmount;
    
    CCCToken cccToken = CCCToken(0x1848bb97dA57bBaD45f9d87986C1B506dfb02532);

    constructor(uint256 amount) public payable {
        totalAmount=amount;
    }
    
    function externalClaimPayment(uint256 _amount, uint256 _nonce) internal {
        cccToken.claimPayment(_amount,_nonce);
    }

    // 收款方认领付款
    function claimPayment(uint256 _amount, uint256 nonce) public {
        require(!usedNonces[nonce]);
        require(totalAmount >= _amount);
        usedNonces[nonce] = true;
        externalClaimPayment(_amount,nonce);
    }

    /// destroy the contract and reclaim the leftover funds.
    function kill() public {
        require(msg.sender == owner);
        selfdestruct(msg.sender);
    }

    /// 第三方方法，分离签名信息的 v r s
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    /// 加入一个前缀，因为在eth_sign签名的时候会加上。
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


contract CCCToken{
    function  claimPayment(uint256 amount, uint256 nonce) external;
}