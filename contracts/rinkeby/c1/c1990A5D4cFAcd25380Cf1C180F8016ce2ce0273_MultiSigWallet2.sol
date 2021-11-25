// SPDX-License-Identifier: GPL-3.0

//decrlare verison of solidity
pragma solidity >=0.7.0 <0.9.0;

import './ERC20.sol';

contract MultiSigWallet2 {
    
    address[] owner;
    uint256 required;
    
    struct Transaction {
        uint256 id;
        string[] data;
        uint256 value;
        uint256 confirmation;
        string types;
        string status;
    }
    
    Transaction[] transaction;
    
    receive() external payable {
        
    }
    
    // constructor(address[] memory _owner, uint256 _required){
    //     owner = _owner;
    //     required = _required;
    // }
    
    function initializer(address[] memory _owner, uint256 _required) public {
        require(owner.length == 0);
        owner = _owner;
        required = _required;
    }
    
    function getNonce() public view returns(uint256){
        return transaction.length + 1;
    }
    
    function getMessageHash(string[] memory data, uint256 _value) public pure returns (bytes32)
    {
        string memory s;
        for(uint256 i = 0; i < data.length; i++){
            s = string(abi.encodePacked(s,  data[i]));
        }
        return keccak256(abi.encodePacked(s, _value));
    }
    
    function executeTransaction(string[] memory _data, uint256 _value, bytes[] memory signature) public {
        require(isOwner(msg.sender));
        uint256 confirmation = getConfirmation(signature, _data, _value);
        if(confirmation >= required){
            if(checkEqualString(_data[2], "ETH")){
                payable(parseAddr(_data[1])).transfer(_value);
            } else {
                ERC20 token = ERC20(parseAddr(_data[3]));
                token.approve(address(this), _value);
                token.transferFrom(address(this), parseAddr(_data[1]), _value);
            }
            transaction.push(Transaction(transaction.length+1, _data, _value, confirmation, "transfer", "approved"));
        } else {
            transaction.push(Transaction(transaction.length+1, _data, _value, confirmation, "transfer","rejected"));
        }
        
    }
    
    function executeAddOwner(string[] memory _data, uint256 _value, bytes[] memory signature) public {
        require(isOwner(msg.sender));
        uint256 confirmation = getConfirmation(signature, _data, _value);
        if(confirmation >= required){
            owner.push(parseAddr(_data[1]));
            transaction.push(Transaction(transaction.length+1, _data, _value, confirmation, "add owner", "approved"));
        } else {
            transaction.push(Transaction(transaction.length+1, _data, _value, confirmation, "add owner","rejected"));
        }
        
    }
    
    function executeRemoveOwner(string[] memory _data, uint256 _value, bytes[] memory signature) public {
        require(isOwner(msg.sender));
        uint256 confirmation = getConfirmation(signature, _data, _value);
        if(confirmation >= required){
            removeArrayOwner(parseAddr(_data[1]));
            transaction.push(Transaction(transaction.length+1, _data, _value, confirmation, "remove owner", "approved"));
        } else {
            transaction.push(Transaction(transaction.length+1, _data, _value, confirmation, "remove owner","rejected"));
        }
        
    }
    
    function executeChangeRequired(string[] memory _data, uint256 _value, bytes[] memory signature) public {
        require(isOwner(msg.sender));
        uint256 confirmation = getConfirmation(signature, _data, _value);
        if(confirmation >= required){
            required = _value;
            transaction.push(Transaction(transaction.length+1, _data, _value, confirmation, "change required", "approved"));
        } else {
            transaction.push(Transaction(transaction.length+1, _data, _value, confirmation, "change required","rejected"));
        }
        
    }
    
    function getBalance() public view returns (uint256){
        return address(this).balance;
    }
    
    function getBalanceToken(address _address) public view returns (uint256){
        return ERC20(_address).balanceOf(address(this));
    }
    
    function getTransaction() public view returns (Transaction[] memory){
        return transaction;
    }
    
    function getOwner() public view returns (address[] memory){
        return owner;
    }
    
    function checkEqualString(string memory a, string memory b) private pure returns (bool){
      return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    function isOwner(address _owner) private view returns (bool){
        bool result;
        for(uint i = 0; i < owner.length; i++){
            if(owner[i] == _owner){
                result = true;
            }
        }
        return result;
    }
    
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        private pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }
    
    function getConfirmation(bytes[] memory _signature, string[] memory _data, uint256 _value) private view returns(uint256){
        uint256 count;
        for(uint256 j = 0; j < _signature.length; j++){
            for(uint256 i = 0; i < owner.length; i++){
                if(verify(owner[i], _data, _value, _signature[j])){
                    count+=1;
                }
            }    
        }
        return count;
    }
    
    function verify(
        address _signer,
        string[] memory data,
        uint256 _value,
        bytes memory signature
    )
        private pure returns (bool)
    {
        bytes32 messageHash = getMessageHash(data, _value);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }
    
    function getEthSignedMessageHash(bytes32 _messageHash) private pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    
    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }
    
    function removeArrayOwner(address _owner) private {
        uint256 index;
        for(uint256 i = 0; i < owner.length; i++){
            if(owner[i] == _owner){
                index = i;
            }
        }
        owner[index] = owner[owner.length - 1];
        owner.pop();
    }
}