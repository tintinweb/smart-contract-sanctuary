// contracts/Doggos.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";


contract Doggos is ERC721Enumerable {
    
    using Strings for uint256;
    bool public hasSaleStarted = false;
    bool public hasPreSale1Started = false; 
    bool public hasPreSale2Started = false;
    uint16[] private mintId;
    uint256 private MAX_RESERVE = 165; 
    uint256 private MAX_PRESALE1 = 500; 
    uint256 private MAX_PRESALE2 = 500; 
    uint256 public MINT_PRICE = 0.0555 ether; 
    uint256 public constant MAX_DOGGOS = 5555; 
    string private baseTokenURI = "https://doggo.mypinata.cloud/ipfs/QmaHnicVZaPHDroFpV2LLoUdmbTyhYJzgLUYcLxySHBWXe/";
    address DevAddress = 0x7fABe37ce4caEE5215dB182Bea81232098DaAFc5;
    
    mapping(address => bool) private addressInPreSale;
    mapping(address => uint256) private totalPreSale1Minted;
    mapping(address => uint256) private totalPreSale2Minted;
    
    constructor() ERC721("The Doggos", "DOGGO") { 
        initMintId();
    }

    function initMintId() internal {
         for (uint16 i = 1; i <= MAX_DOGGOS; i++){
            mintId.push(i);
         }
    }

   function mintDoggos(uint256 numofDOGGOS) public payable { 
        require(totalSupply() + numofDOGGOS <= MAX_DOGGOS - MAX_RESERVE, "Exceeds max DOGGOS mintable");
        require(hasSaleStarted == true, "Sales have not start");
        require(numofDOGGOS <= 10, "Exceeds max 10 DOGGOS per mint"); 
        require(msg.value >= MINT_PRICE * numofDOGGOS, "Value sent insufficient");
        
        for (uint256 i = 0; i < numofDOGGOS; i++) {
            _safeMint(msg.sender, getRandomId());
        }
    } 
    
     function preSale1Mint(uint256 numofDOGGOS) public payable {
        require(hasPreSale1Started == true, "Presales1 have not start");
        require(totalPreSale1Minted[msg.sender] + numofDOGGOS <= 2, "Exceeds supply of presale1 mintable."); 
        require(numofDOGGOS <= MAX_PRESALE1, "Exceeds max Presale1 DOGGOS mintable");
        require(totalSupply() + numofDOGGOS <= MAX_DOGGOS - MAX_RESERVE, "Exceeds max DOGGOS mintable");
        require(msg.value >= MINT_PRICE * numofDOGGOS, "Value sent insufficient");

        for (uint256 i; i < numofDOGGOS; i++) {
            _safeMint(msg.sender, getRandomId());
        }

        totalPreSale1Minted[msg.sender] += numofDOGGOS;
        MAX_PRESALE1 -= numofDOGGOS;
    }
    
    function preSale2Mint(uint256 numofDOGGOS) public payable {
        require(hasPreSale2Started == true, "Presales2 have not start");
        require(addressInPreSale[msg.sender] == true, "Address not whitelisted for presale2");
        require(totalPreSale2Minted[msg.sender] + numofDOGGOS <= 2, "Exceeds supply of presale2 mintable."); 
        require(numofDOGGOS <= MAX_PRESALE2, "Exceeds max Presale2 DOGGOS mintable");
        require(totalSupply() + numofDOGGOS <= MAX_DOGGOS - MAX_RESERVE, "Exceeds max DOGGOS mintable");
        require(msg.value >= MINT_PRICE * numofDOGGOS, "Value sent insufficient");

        for (uint256 i; i < numofDOGGOS; i++) {
            _safeMint(msg.sender, getRandomId());
        }

        totalPreSale2Minted[msg.sender] += numofDOGGOS;
        MAX_PRESALE2 -= numofDOGGOS;
    }
    
    function addWalletToPreSale(address[] memory _address) external onlyOwner {
        for(uint256 i = 0 ; i < _address.length ; i++){
            addressInPreSale[_address[i]] = true;
        }
    }
    
    function giveaways(address to, uint256 numofDOGGOS) public onlyOwner {
        require(totalSupply() + numofDOGGOS <= MAX_DOGGOS, "Exceeds Max DOGGOS");
        require(numofDOGGOS <= MAX_RESERVE, "Exceeds Max reserve");
        
        for (uint256 i = 0; i < numofDOGGOS; i++) {
            _safeMint(to, getRandomId());
        }
        MAX_RESERVE -= numofDOGGOS;
    }
    
    function giveawaysToMany(address[] memory recipients) external onlyOwner {
        require(totalSupply() + recipients.length <= MAX_DOGGOS, 'Exceeds Max DOGGOS');
        require(recipients.length <= MAX_RESERVE, "Exceeds Max reserve");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], getRandomId());
        }
        MAX_RESERVE -= recipients.length;
    }
    
    function getRandomId() private returns (uint256) {
        uint256 random = _getRandomNumber(mintId.length);
        uint256 tokenId = uint256(mintId[random]);

        mintId[random] = mintId[mintId.length - 1];
        mintId.pop();

        return tokenId;
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
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
    
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    mintId.length,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender
                )
            )
        );
        return random % _upper;
    }
    
    function getPrice() public view returns (uint256){
        return MINT_PRICE;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function setBaseURI(string memory BaseURI) public onlyOwner {
        baseTokenURI = BaseURI;
    }
    
    function baseURI() external view returns (string memory) {  
        return baseTokenURI;
    }
    
    function setPrice(uint256 _newPrice) public onlyOwner() {  
        MINT_PRICE = _newPrice;
    }
    
    function flipSale() public onlyOwner {
        hasSaleStarted = !hasSaleStarted;
    }
    
    function flipPreSale1() public onlyOwner {
        hasPreSale1Started = !hasPreSale1Started;
    }
    
    function flipPreSale2() public onlyOwner {
        hasPreSale2Started = !hasPreSale2Started;
    }
    
    function withdrawAll() public onlyOwner {
        require(payable(DevAddress).send(address(this).balance / 1000 * 75));
        require(payable(msg.sender).send(address(this).balance));
    }
    
}