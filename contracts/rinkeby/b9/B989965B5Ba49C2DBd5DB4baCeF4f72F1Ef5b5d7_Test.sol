/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Test {
    
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
    function testVerify(address _owner,bytes32 _value,bytes memory signature) public pure returns (bool) {
        return verify(_owner,_value,signature);
    }
    function verify(
        address _owner,
        bytes32 _value,
        bytes memory signature
    ) public pure returns (bool) {

        return recoverSigner(_value, signature) == _owner;
    }


    function recoverSigner(
        bytes32 _message,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_message, v, r, s);
    }
    function splitSignature(bytes memory signature)
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
    }
}