/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

pragma experimental ABIEncoderV2;
pragma solidity ^0.5.15;

contract RaffleSignatureVerifier {
    struct Participant {
        address wallet;
        uint256 raffle;
    }

    string private constant PARTICIPANT_TYPE = "Participant(address wallet,uint256 raffle)";
    bytes32 private constant PARTICIPANT_TYPEHASH = keccak256(abi.encodePacked(PARTICIPANT_TYPE));

    uint256 constant chainId = 1;
    bytes32 constant salt = 0xb857c3bb801294f2c8a1a75673b4d63e1550f30e0ee556df6867a5a853b86047;
    string private constant EIP712_DOMAIN = "EIP712Domain(string name,string version,uint256 chainId,bytes32 salt)";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
    bytes32 private constant DOMAIN_SEPARATOR = keccak256(abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256("POAP.fun"),
        keccak256("1"),
        chainId,
        salt
    ));

    function hashParticipant(Participant memory participant) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
           DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                PARTICIPANT_TYPEHASH,
                participant.wallet,
                participant.raffle
            ))
        ));
    }

    function verify(Participant memory participant, bytes32 r, bytes32 s, uint8 v) public pure returns (address) {
        return ecrecover(hashParticipant(participant), v, r, s);
    }
}