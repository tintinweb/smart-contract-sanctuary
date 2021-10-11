//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ProofCrossChain {

    struct Content {
        string value;
        bool isCrossChain; 
    }

    string public proofName;
    address public govAddress;

    mapping (string => Content) public proofs;

    event Set(string _key, string _value, bool _isCrossChain);
    event Remove(string _key, bool _isCrossChain);
    event SetGov(address _govAddress);

    modifier onlyAllowGov() {
        require(msg.sender == govAddress, "!gov");
        _;
    }

    constructor(string memory _proofName, address _govAddress) {
        proofName = _proofName;
        govAddress = _govAddress;
    }

    function setGov(address _govAddress) public onlyAllowGov {
        govAddress = _govAddress;
        emit SetGov(_govAddress);
    }

    function set(string memory _key, string memory _value) public onlyAllowGov {
        setCrossChain(_key, _value, false);
    }

    function setCrossChain(string memory _key, string memory _value, bool _isCrossChain) public onlyAllowGov {
        proofs[_key] = Content({
            value: _value,
            isCrossChain: _isCrossChain
            });
        emit Set(_key, _value, _isCrossChain);
    }

    function remove(string memory _key) public onlyAllowGov {
        removeCrossChain(_key, false);
    }

    function removeCrossChain(string memory _key, bool _isCrossChain) public onlyAllowGov {
        delete proofs[_key];
        emit Remove(_key, _isCrossChain);
    }

    function get(string memory _key) public view returns(string memory){
        return proofs[_key].value;
    }
}