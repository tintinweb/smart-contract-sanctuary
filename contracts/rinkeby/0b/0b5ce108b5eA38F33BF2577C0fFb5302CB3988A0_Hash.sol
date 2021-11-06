/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
/* import "./Strings.sol"; */
contract Hash{
   /*  using Strings for string; */
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
    function proxy (address _target,bytes memory _calldata) public returns (bool res,bytes memory str) {
        // require(_target.delegatecall(_calldata));
        (res,str) = _target.delegatecall(_calldata);
        // return _target.delegatecall(_calldata);
    }
    function proxyDo (address _target,string memory _method,address _to,uint _amount) public returns (bool res,bytes memory str) {
        // require(_target.delegatecall(abi.encodeWithSignature(_method, _to,_amount)));
        (res,str) = _target.delegatecall(abi.encodeWithSignature(_method,_to,_amount));
        // return _target.delegatecall(abi.encodeWithSignature(_method, _to,_amount));
    }
    function showSign (string memory _method,address _to,uint _amount) public pure returns (bytes memory str){
        str = abi.encodeWithSignature(_method,_to,_amount);
    }
    function showMsgData() public pure returns (bytes memory msgdata){
        msgdata = msg.data;
    }
    function showMsgGas() public view returns (uint gasCount){
        gasCount = gasleft();
    }
    /* function uintToHex(
        uint _value
    ) public pure returns (string memory) {
        return Strings.toHexString(_value);
    } */
    /* function verify1(
        address _owner,
        uint _msg,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 messageHash = getMessageHash(_owner,uintToHex(_msg));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        
        return recoverSigner(ethSignedMessageHash, signature);
    } */
    function verify(
        address _owner,
        string memory _msg,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 messageHash = getMessageHash(_owner,_msg);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        
        return recoverSigner(ethSignedMessageHash, signature);
    }



    function getMessageHash(address _owner,string memory _msg)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_owner,_msg));
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