// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IERC20.sol';
import './ERC721.sol';
import './Ownable.sol';

contract EyesRareSeals is ERC721, Ownable {
    using SafeMath for uint256;
    uint public MAX_SEALS = 100;
    bool public hasSaleStarted = true;
    
    string public METADATA_PROVENANCE_HASH = "";
    address public burnAddress = address(0x000000000000000000000000000000000000dEaD);

    constructor() ERC721("EyesRareSeals","Eyes")  {
        setBaseURI("https://eyesrare.org/metadata/"); 
        feeReceiver = payable(msg.sender);
    } 
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    
    
   function mint(uint256 maxSeals) public payable {
        require(hasSaleStarted,"Mint not start");
        require(totalSupply() < MAX_SEALS, "Sale has already ended");
        require(maxSeals > 0 && maxSeals <= 3, "You can craft minimum 1, maximum 3 seals"); 
        require(totalSupply().add(maxSeals) <= MAX_SEALS, "Exceeds MAX_SEALS");
        for (uint i = 1; i <= maxSeals; i++) {
            uint mintIndex = totalSupply() + 1;
            _safeMint(msg.sender, mintIndex);
        }
    }
    
    // ONLYOWNER FUNCTIONS
    
    function setProvenanceHash(string memory _hash) public onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setMax(uint256 num) public onlyOwner {
        MAX_SEALS = num;
    }
    
    function startDrop() public onlyOwner {
        hasSaleStarted = true;
    }
    
    function pauseDrop() public onlyOwner {
        hasSaleStarted = false;
    }
    
    function withdrawAll() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}