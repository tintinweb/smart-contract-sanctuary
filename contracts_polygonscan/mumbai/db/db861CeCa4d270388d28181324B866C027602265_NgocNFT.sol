pragma solidity 0.8.10;
import "./ERC721.sol";

contract NgocNFT is ERC721 {
    string public name;
    string public symbol;
    mapping(uint256 => string) tokenURIs;
    uint256 public tokenCount;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function tokenURI(uint256 tokenID) public view returns (string memory) {
        require(ownerOf(tokenID) != address(0), "Token id ko ton tai");
        return tokenURIs[tokenID];
    }

    function mint(string memory _tokenURI) public {
        tokenCount += 1;
        _balances[msg.sender] += 1;
        _owners[tokenCount] = msg.sender;
        tokenURIs[tokenCount] = _tokenURI;

        emit Transfer(address(0), msg.sender, tokenCount);
    }

    function supportInteface(bytes4 interfaceID)
        public
        pure
        override
        returns (bool)
    {
        return interfaceID == 0x80ac58cd || interfaceID == 0x5b5e139f;
    }
}