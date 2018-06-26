pragma solidity ^0.4.24;

interface TokenERC721 {
    function transfer(address _to, string _tokenId) external;
}

contract AutorizedAddresses {
    TokenERC721 public tokenERC721;
    mapping (address => bool) list;
    mapping (address => address) ownerOf;
    
    constructor(address _tokenERC721) public {
        list[msg.sender] = true;
        tokenERC721 = TokenERC721(_tokenERC721);
    }

    function add(address _address) public {
        require(list[msg.sender]);
        list[_address] = true;
        ownerOf[_address] = msg.sender;
    }

    function remove(address _address) public {
        require(list[msg.sender]);
        require(ownerOf[_address] == msg.sender);
        list[_address] = false;
    }

    function transferETH(address _to, uint256 _value) public {
        require(list[msg.sender]);
        require(_to != 0x0);
        require(_value > 0);
        _to.transfer(_value);
    }

    function transferERC721(address _to, string _id) public {
        require(list[msg.sender]);
        require(_to != 0x0);
        tokenERC721.transfer(_to, _id);
    }
}