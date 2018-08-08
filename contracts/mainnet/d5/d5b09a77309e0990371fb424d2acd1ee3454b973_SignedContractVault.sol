pragma solidity ^0.4.11;

contract SignedContractVault {
    address private owner;
    string[] private gpgKeys;

    struct Contract {
        string dawex;
        string buyer;
        string seller;
    }

    mapping (string => Contract) private contracts;

    modifier onlyOwner {
        if (msg.sender != owner)
            throw;
        _;
    }

    function SignedContractVault(string gpgKey) {
      owner = msg.sender;
      gpgKeys.push(gpgKey);
    }

    /**
     * Fallback function to avoid sending eth to this contract.
     */
    function() {
        throw;
    }

    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function createContract(string key, string signature) public onlyOwner {
        Contract _contract = contracts[key];
        if (bytes(_contract.dawex).length > 0) {
            throw;
        }
        contracts[key] = Contract(signature, "", "");
    }

    function addBuyerSig(string key, string signature) public onlyOwner {
        Contract _contract = contracts[key];
        if (bytes(_contract.dawex).length == 0 || bytes(_contract.buyer).length > 0) {
            throw;
        }
        _contract.buyer = signature;
    }

    function addSellerSig(string key, string signature) public onlyOwner {
        Contract _contract = contracts[key];
        if (bytes(_contract.dawex).length == 0 || bytes(_contract.seller).length > 0) {
            throw;
        }
        _contract.seller = signature;
    }

    function addGpgKey(string gpgKey) public onlyOwner {
        gpgKeys.push(gpgKey);
    }

    function getDawexSignature(string key) constant returns (string) {
        return contracts[key].dawex;
    }

    function getBuyerSignature(string key) constant returns (string) {
        return contracts[key].buyer;
    }

    function getSellerSignature(string key) constant returns (string) {
        return contracts[key].seller;
    }

    function getGpgKey() constant returns (string) {
        return gpgKeys[gpgKeys.length - 1];
    }
}