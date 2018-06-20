pragma solidity ^0.4.13;


contract Notary {
    
    address public jan = 0x45f5c8b556c3f2887b50184c823d1223f41a4156;
    address public investor = 0xCF4e87991826081d172B61b2e1B2800F18dA8cE7;

    address NotaryPersistentStorageAddress = 0x8439dacB099826eba3c56A8B2d3A15F108a89552;

    event LogResponse(bytes32, bool);

    function Notary() payable {
    }

    function notarise(bytes32 _proof) public payable returns (bool success) {
        
        NotaryPersistentStorage notary = NotaryPersistentStorage(NotaryPersistentStorageAddress);
        notary.storeProof(_proof);

        _payRoyalty();
        
        return true;
    }

    function hasProof(bytes32 _proof) public returns (bool) {
        NotaryPersistentStorage notary = NotaryPersistentStorage(NotaryPersistentStorageAddress);
        bool result = notary.hasProof(_proof);
        LogResponse(_proof,result);
        return result;
    }
    
    function _payRoyalty() public payable {
        uint amount = msg.value;
        jan.transfer(amount/2);
        investor.transfer(amount/2);
    }
    
    // fallback function
    function () payable {
    }
    
}


contract NotaryPersistentStorage {
    function storeProof(bytes32 _proof) public returns (bool);
    function hasProof(bytes32 _proof) public constant returns (bool);
}