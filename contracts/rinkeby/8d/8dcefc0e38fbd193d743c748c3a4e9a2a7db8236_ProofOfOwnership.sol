/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity 0.8.0;
 
contract ProofOfOwnership {
    
    address payable public owner;
    uint public FEE_VALUE;
    mapping(string => address) files;

    constructor (address payable _receiver, uint _fee) {
        owner = _receiver; 
        FEE_VALUE = _fee;
    }
     
    function register(string memory _hash) public payable {
        require(msg.value == FEE_VALUE, "you fee is not correct");
        require(files[_hash] == address(0), "the hash already exists");
        files[_hash] = msg.sender;
    }
    
    function proveFileExists(string memory _hash) public view returns(bool) {
        return files[_hash] != address(0);
    }
    
    function proveFileOwner(string memory _hash, address _user) public view returns(bool) {
        return files[_hash] == _user;
    }

    function collectFees () public {
        require(msg.sender == owner, "only contract owner can collect fees");
        owner.transfer (address(this).balance);
    }
    
    fallback () external payable {}
    
    receive () external payable {}
    
}