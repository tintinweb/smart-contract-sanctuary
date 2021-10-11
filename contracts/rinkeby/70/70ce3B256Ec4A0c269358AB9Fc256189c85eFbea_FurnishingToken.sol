pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Strings.sol";

contract FurnishingToken is ERC721 {
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public _owner;
    
    event WithDrawn(address, uint);
    
    constructor() public ERC721("Furnishing Item Selling Token", "FIST") {
        _owner = msg.sender;
    }
    
    function deposit() public payable {}
    
    function withDraw() public onlyOwner {
        uint bal = address(this).balance;
        payable(msg.sender).transfer(bal);
        emit WithDrawn(msg.sender, bal);
    }

    function mint(address to_) public onlyOwner returns (uint256 newTokenId) {
        _tokenIds.increment();
        newTokenId = _tokenIds.current();
        _safeMint(to_, newTokenId);
        return newTokenId;
    }
    function burn(uint256 tokenid_) public {
        _burn(tokenid_);
    }
    
    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }
}