// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";


contract CodeTest_1 is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    constructor() ERC721("CodeTest_1", "CT1") {}
    
    
    uint256 token_id = 0;
    
    struct nft_reveal{
        address nft_owner;
        uint256 nft_id;
        uint256 buy_time;
    }
    
    uint256 reveal_time = 7 days ;
    uint256 last_token_time = 12 hours;
    uint256 set_token = 0;
    uint256 random_num = 0;
    uint256 count = 0;
    uint256 last_time ;
    
    uint256[] public list_of_nft ;
    address owner_of_token;
    
    mapping (uint256 => nft_reveal) public reveal_nft;
    mapping (address => uint256) private listOfAdrress;
    mapping (address => bool) private ico;
    mapping (uint256 => bool) private token_list;
    
    modifier onlyico() {
        require(owner() == _msgSender() || ico[_msgSender()], "Ownable: caller is not the owner");
        _;
    }
  
    
    function add_ico(address _ico) public onlyOwner {
        ico[_ico] = true;
    }
    function remove_ico(address _ico) public onlyOwner {
        ico[_ico] = false;
    }
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safemint(address to, string memory metadata) public {
        
        require(token_id < 666, "Strings: 666 nft is minted");
        require(listOfAdrress[to] < 31, "Strings: You can't mint");
        
        token_id++;
        listOfAdrress[to] += 1; 
        list_of_nft.push(token_id);
        _safeMint(to, token_id);
        _setTokenURI(token_id, metadata);
        
    }
    
    function buy_nft(address to) public onlyico {
        random_num = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        random_num = random_num % (list_of_nft.length);
        owner_of_token = ownerOf(list_of_nft[random_num]);
        _transfer(owner_of_token,  to , list_of_nft[random_num]);
       
        count++;
        last_time = block.timestamp;
        nft_reveal memory reveal_info;
        reveal_info = nft_reveal({
              nft_owner :  to,
              nft_id : list_of_nft[random_num],
              buy_time : block.timestamp
        });
        
        reveal_nft[list_of_nft[random_num]] = reveal_info;
        token_list[list_of_nft[random_num]] = true;
        list_of_nft[random_num] = list_of_nft[list_of_nft.length - 1];
        delete list_of_nft[list_of_nft.length - 1];
        list_of_nft.pop();
        // list_of_nft.push(list_of_nft[random_num]);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)internal whenNotPaused override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId)public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
       
        if(reveal_nft[tokenId].buy_time + reveal_time <= block.timestamp )
        {
               return super.tokenURI(tokenId);
        }
        else
        {
            if( count >= 666 && last_time + last_token_time <= block.timestamp )
            {
                   return super.tokenURI(tokenId); 
            }
            else
            {
                return "null";
            }
        }

    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function getToken(uint256 tokenId) public view virtual returns (address, string memory) {
        
        address owner = ownerOf(tokenId);
        string memory ipfs =  tokenURI(tokenId);
        return (owner, ipfs);
    }
}