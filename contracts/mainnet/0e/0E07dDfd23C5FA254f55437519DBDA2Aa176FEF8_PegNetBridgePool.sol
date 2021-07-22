/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface ERC20Interface {
    function totalSupply() external returns (uint256);
    function balanceOf(address tokenOwner) external returns (uint balance);
    function allowance(address tokenOwner, address spender) external returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
}

contract PegNetBridgePool {
    ERC20Interface tokenOfPegNet;

    ERC20Interface tokenOfpUSD;

    event Transfer(address indexed from, address indexed to, uint256 tokens, string tokenType);

    address public owner = msg.sender;

    mapping(uint256 => bool) usedNonces;

    function getBridgeAmount(uint256 amount, uint256 nonce, bytes memory signature, uint256 tokenType) public {
        require(!usedNonces[nonce], "Nonce is duplicated");
        require(tokenType == 1 || tokenType == 2, "Unsupported token");

        // this recreates the message that was signed on the client
        bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, amount, nonce, tokenType, this)));

        require(recoverSigner(message, signature) == owner, "Signature is not matched");

        if (tokenType == 1) { // PegNet Token
            require(tokenOfPegNet.balanceOf(address(this)) >= amount, "No enough PegNet tokens in BridgePool");

            tokenOfPegNet.transfer(msg.sender, amount);

            emit Transfer(owner, msg.sender, amount, "PegNet");

        } else if (tokenType == 2) { // pUSD Token
            require(tokenOfpUSD.balanceOf(address(this)) >= amount, "No enough pUSD tokens in BridgePool");

            tokenOfpUSD.transfer(msg.sender, amount);

            emit Transfer(owner, msg.sender, amount, "pUSD");
        }

        usedNonces[nonce] = true;
    }

    /// destroy the contract and reclaim the leftover funds.
    function shutdown() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    /// signature methods.
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

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setPegNetToken(address _tokenPegNetAddr, address _tokenPUsdAddr) public onlyOwner {
        tokenOfPegNet = ERC20Interface(_tokenPegNetAddr);
        tokenOfpUSD = ERC20Interface(_tokenPUsdAddr);
    }
}