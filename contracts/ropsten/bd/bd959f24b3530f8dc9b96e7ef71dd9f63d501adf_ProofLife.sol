pragma solidity ^0.4.18;

contract ProofLife {

    struct Proof {
        string ipfsHash;
        string hashProof;
    }

    struct Scribe {
        string firstName;
        string lastName;
    }

    mapping (address => Scribe) scribes;
    address[] public scribesAccounts;

    mapping (address => Proof[]) proofs;

    function setScribe(address _address, string _firstName, string _lastName) public {
        Scribe storage scribe = scribes[_address];

        scribe.firstName = _firstName;
        scribe.lastName = _lastName;

        scribesAccounts.push(_address);
    }

    function getScribes() public view returns(address[]) {
        return scribesAccounts;
    }

    function getScribe(address _address) public view returns (string, string) {
        return (scribes[_address].firstName, scribes[_address].lastName);
    }

    function setProof(string _ipfsHash, string _hashProof) public {
        Proof memory proof = Proof(_ipfsHash, _hashProof);
        proofs[msg.sender].push(proof);
    }

    function getCountProof() public view returns (uint256) {
        return proofs[msg.sender].length;
    }

    function getProof(uint256 _index) public view returns (string ipfsHash, string hashProof) {
        return (proofs[msg.sender][_index].ipfsHash, proofs[msg.sender][_index].hashProof);
    }
}