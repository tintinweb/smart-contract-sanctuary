pragma solidity ^0.4.20;

contract SimpleToken {
    uint256 tokenCount = 0;

    mapping (uint256 => address) public ownerOf;
    mapping (uint256 => uint256) public priceOf;

    function mint() public returns (uint256) {
        priceOf[tokenCount] = 0.01 ether;
        ownerOf[tokenCount] = 0x0;
        tokenCount += 1;
        return tokenCount-1;
    }

    function getTokenPrice(uint256 _tokenId) public view returns (uint256) {
        require(exists(_tokenId));
        return priceOf[_tokenId];
    }
    
    function setTokenPrice(uint256 _tokenId, uint256 _price) public {
        require(exists(_tokenId));
        require(msg.sender == ownerOf[_tokenId]);
        priceOf[_tokenId] = _price;
    }
    
    function exists(uint256 _tokenId) public view returns (bool) {
        return (_tokenId <= tokenCount);
    }

    function purchase(uint256 _tokenId) public payable {
        require(exists(_tokenId));
        require(msg.value == priceOf[_tokenId]);
        require(msg.sender != ownerOf[_tokenId]);

        ownerOf[_tokenId].transfer(priceOf[_tokenId]);
        ownerOf[_tokenId] = msg.sender;
    }
}