/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

pragma solidity ^0.8.0;

contract VerifySignature {

    function getMessageHashItem(
        address _to,
        uint256 _nonce
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _nonce));
    }

    function getMessageHashPass(
        address _owner,
        address _to,
        uint _token,
        uint256 _nonce
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked( _owner, _to, _token, _nonce));
    }

    function getMessageHashPassSale(
        address _to,
        uint256 _nonce,
        uint256 token,
        uint256 buyPrice
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _nonce, token, buyPrice));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}