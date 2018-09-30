pragma solidity ^0.4.24;

contract ERC721BatchTest {
    address public owner;
    address public myAddress;
    uint256 public num;

    event BatchTransfer(address _addr);

    constructor() public {
        owner = msg.sender;
    }
    
    function arrayTest(address[] _addrs) public {
        require(msg.sender == owner);
        uint j;
        for(uint256 i = 0; i<_addrs.length; i++) {
            myAddress = _addrs[i];
            j = i;
        }
        emit BatchTransfer(_addrs[j]);
    }
    
    function arrayTestMulti(address[] _from, address[] _to, uint256[] _tokenId) public {
        require(msg.sender == owner);
        uint j;
        for(uint256 i = 0; i<_from.length; i++) {
            myAddress = _from[i];
            myAddress = _to[i];
            num = _tokenId[i];
            j = i;
        }
        emit BatchTransfer(_from[j]);
    }
}