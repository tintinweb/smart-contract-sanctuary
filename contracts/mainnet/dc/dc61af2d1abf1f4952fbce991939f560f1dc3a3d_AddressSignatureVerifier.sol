pragma experimental ABIEncoderV2;
pragma solidity ^0.5.15;

contract AddressSignatureVerifier {
    struct Wallet {
        address wallet;
        string message;
    }

    string private constant WALLET_TYPE = "Wallet(address wallet,string message)";
    bytes32 private constant WALLET_TYPEHASH = keccak256(abi.encodePacked(WALLET_TYPE));

    uint256 constant chainId = 1;
    bytes32 constant salt = 0xb857c3bb801294f2c8a1a75673b4d63e1550f30e0ee556df6867a5a853b86047;
    string private constant EIP712_DOMAIN = "EIP712Domain(string name,string version,uint256 chainId,bytes32 salt)";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
    bytes32 private constant DOMAIN_SEPARATOR = keccak256(abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256("POAP.app"),
        keccak256("1"),
        chainId,
        salt
    ));

    function hashWallet(Wallet memory wallet) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
           DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                WALLET_TYPEHASH,
                wallet.wallet,
                wallet.message
            ))
        ));
    }

    function verify(Wallet memory wallet, bytes32 r, bytes32 s, uint8 v) public pure returns (address) {
        return ecrecover(hashWallet(wallet), v, r, s);
    }
}