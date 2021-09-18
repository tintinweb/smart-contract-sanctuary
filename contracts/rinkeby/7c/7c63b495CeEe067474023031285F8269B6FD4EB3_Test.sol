/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
contract Test{
    
    function transferETH(address _from) payable public returns (bool){
           require(_from != address(0));
           payable(_from).transfer(msg.value);
           return true;
    }
    function sendETH(address _to) payable public returns (bool){
            bool result = payable(_to).send(msg.value);
            require(result);
            return result;
    }
    function testVerify(uint _value,bytes memory signature) public pure returns (address) {
        bytes32 messageHash = getMessageHash(_value);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature);
    }
    /* function verify(
        address _owner,
        uint _value,
        bytes memory signature
    ) public pure returns (bool) {

        return recoverSigner(_value, signature) == _owner;
    } */


    function recoverSigner(
        uint _message,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(getMessageHash(_message), v, r, s);
    }
    /* function splitSignature(bytes memory signature)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(signature.length == 65, "invalid signature length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    } */


    function toBytes1(uint256 x) public pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    /* function getMessageHash(uint256 _value)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_value));
    } */

    function toBytes2(uint256 x) public pure returns (bytes memory c) {
        bytes32 b = bytes32(x);
        c = new bytes(32);
        for (uint i=0; i < 32; i++) {
            c[i] = b[i];
        }
    }

     /// string类型转化为bytes32型转
    function stringToBytes32(string memory source) public pure returns(bytes32 result){
        assembly{
            result := mload(add(source,32))
        }
    }
    function verify(
        address _owner,
        uint256 _value,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_value);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _owner;
    }

    function getMessageHash(uint256 id)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(id));
    }

    function getEthSignedMessageHash(bytes32 messageHash)
        public pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
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

    function splitSignature(bytes memory signature)
        public pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(signature.length == 65, "invalid signature length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }

}