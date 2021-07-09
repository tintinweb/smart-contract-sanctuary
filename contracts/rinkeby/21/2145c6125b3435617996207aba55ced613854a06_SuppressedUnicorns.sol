// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SuppressedUnicorns is ERC721Enumerable, Ownable {

/*
   uint total = 254;

   constructor() ERC721("SuppressedUnicorns", "UNICORN") { 
      
   }


   function getFive() public pure returns(string memory) {
      return 'GIVE ME FIVE, BRO';
   }

   function deleteContract() public onlyOwner {
      selfdestruct(payable(owner()));
   }

*/

// !!!!! delete Before Upload Ethereum
function deleteContract() public onlyOwner {
   selfdestruct(payable(owner()));
}


//catsssssss


   using Strings for uint256;

   string _baseTokenURI;
   string private _baseContractURI;
   uint8 private _reserved = 200;
   uint16 public constant MAX_UNICORNS = 13000;
   uint256 private _price = 0.04 ether;
   bool public _paused = true;

//ok
   constructor(/*string memory baseURI, string memory baseContractURI*/) ERC721("SuppressedUnicorns", "UNICORN")  {
      // setBaseURI(baseURI);
      // _baseContractURI = baseContractURI;

      // team(me) gets 1 unicorn:)
      _safeMint( owner(), 0);

   }

//ok
   function adopt(uint8 num) public payable {
      uint256 supply = totalSupply();
      require( !_paused,                                  "Sale paused" );
      require( num > 0 && num < 31,                       "You can adopt a maximum of 30 unicorn and minimum 1" );
      require( supply + num < MAX_UNICORNS - _reserved,   "Exceeds maximum Unicorns supply" );
      require( msg.value >= _price * num,                 "Ether sent is not correct" );

      for(uint8 i; i < num; i++){
         _safeMint( msg.sender, supply + i );
      }
   }

//ok
   function tokensOfOwner(address _owner) public view returns(uint256[] memory) {
      uint256 tokenCount = balanceOf(_owner);

      if(tokenCount == 0) {
         return new uint256[](0);
      }
      else {
         uint256[] memory tokensId = new uint256[](tokenCount);
         for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
         }
         return tokensId;
      }
   }

//ok
   function setPrice(uint256 _newPrice) public onlyOwner {
     _price = _newPrice;
   }

//ok 
   function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
   }

//ok 
   function setBaseURI(string memory baseURI) public onlyOwner {
      _baseTokenURI = baseURI;
   }

//ok
   function contractURI() public view returns (string memory) {
      return _baseContractURI;
   }







//ok
   function getPrice() public view returns (uint256) {
      return _price;
   }

//ok
   function getReservedCount() public view returns (uint8) {
      return _reserved;
   }

//ok
   function reserveAirdrop(address _to, uint8 _amount) external onlyOwner {
      require( _amount <= _reserved, "Exceeds reserved Unicorn supply" );

      uint256 supply = totalSupply();
      for(uint8 i; i < _amount; i++){
         _safeMint( _to, supply + i );
      }

      _reserved -= _amount;
   }




//ok
   function pause(bool val) public onlyOwner {
      _paused = val;
   }

//ok
   function withdrawAll() public payable onlyOwner {
      require(payable(msg.sender).send(address(this).balance));
   }

   // additinal func

   // ???
   function unicornTokenBalance(address tokenContractAddress) private view returns(uint) {
      ERC721 token = ERC721(tokenContractAddress); // token is cast as type ERC721, so it's a contract
      return token.balanceOf(msg.sender);
   }

   // ??
   function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }


///// cats


/*
//// dystoPunks

    uint public constant MAX_UNICORNS = 13000;
    bool public hasSaleStarted = false;
   //  mapping (address => uint) private _DystoPunksV1Owners;
    string private _baseTokenURI;
    string private _baseContractURI;

+++    constructor(string memory baseTokenURI, string memory baseContractURI) ERC721("SuppressedUnicorns", "UNICORN")  {
        setBaseURI(baseTokenURI);
        _baseContractURI = baseContractURI;
    }

+++
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

+++
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

+++
    function contractURI() public view returns (string memory) {
       return _baseContractURI;
    }

---
   //  function isAuthClaim(address _to) public view returns(uint) {
   //    return _DystoPunksV1Owners[_to];
   //  }

---
   //  function authClaim(address _to, uint  _NumberOfPunks) public onlyOwner{
   //       _DystoPunksV1Owners[_to] = _NumberOfPunks;
   //  }


++++
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


--------
    function calculatePrice() public view returns (uint256) {
        require(hasSaleStarted == true, "Sale hasn't started");
        require(totalSupply() < MAX_UNICORNS, "Sale has already ended");

        uint currentSupply = totalSupply();
        if (currentSupply >= 2000) {
            return 100000000000000000;        // 2000-2077:  0.10 ETH
        } else if (currentSupply >= 1667) {
            return 80000000000000000;         // 1667-1999:  0.08 ETH
        } else if (currentSupply >= 1334) {
            return 60000000000000000;         // 1334-1666:  0.06 ETH
        } else if (currentSupply >= 1001) {
            return 40000000000000000;         // 1001-1333:  0.04 ETH
        } else if (currentSupply >= 501) {
            return 30000000000000000;         // 501-1000:   0.03 ETH
        } else {
            return 20000000000000000;         // 1 - 500:    0.02 ETH
        }
    }


++++
   function getDystoPunk(uint256 numDystoPunks) public payable {
        require(totalSupply() < MAX_UNICORNS, "Sale has already ended");
        require(numDystoPunks > 0 && numDystoPunks <= 20, "You can mint minimum 1, maximum 20 DystoPunks");
        require(totalSupply()+numDystoPunks <= MAX_UNICORNS, "Exceeds MAX_UNICORNS");
        require(msg.value >= calculatePrice() * numDystoPunks, "Ether value sent is below the price");

        for (uint i = 0; i < numDystoPunks; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

+++
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

+++
    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

+++
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

+++
    function reserveAirdrop(uint256 numDystoPunks) public onlyOwner {
        uint currentSupply = totalSupply();
        require(totalSupply() + numDystoPunks <= 130, "Exceeded airdrop supply");
        require(hasSaleStarted == false, "Sale has already started");
        uint256 index;
        // Reserved for DystoPunks V1 holders airdrop, DystoFactory Upgrade and giveaways
        for (index = 0; index < numDystoPunks; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }


???
   function punksTokenBalance(address tokenContractAddress) private view returns(uint) {
       ERC721 token = ERC721(tokenContractAddress); // token is cast as type ERC721, so it's a contract
       return token.balanceOf(msg.sender);
   }

---
   function claimDystoPunk() public {
     require(totalSupply() < MAX_UNICORNS, "Sale end");
     require(hasSaleStarted == true, "Sale has not already started");
     require(_DystoPunksV1Owners[msg.sender] > 0, "Not owner");
     address _to = msg.sender;
     uint _NumberToClaim = _DystoPunksV1Owners[_to];
     for(uint i = 0; i < _NumberToClaim; i++){
       _safeMint(_to, totalSupply());
     }
     _DystoPunksV1Owners[_to]=0;
   }

*/
//// dystoPunks





   
}