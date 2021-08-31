// contracts/Doggos.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";


contract Doggos is ERC721Enumerable {
    
    using Strings for uint256;
    bool public hasSaleStarted = true;
    bool public hasPreSaleStarted = true;
    uint16[] private mintId;
    uint256 private MAX_RESERVE = 100; 
    uint256 private MAX_PRESALE = 455; 
    uint256 public MINT_PRICE = 0.0555 ether; 
    uint256 public constant MAX_DOGGOS = 5555;
    string private baseTokenURI = "";
    address DevAddress = 0x5ab309bf1F7c8A4171df029140188e501D570078;
    
    mapping(address => bool) addressInPreSale;
    mapping(address => uint256) totalPreSaleMinted;
    
    constructor() ERC721("The Doggos", "DOGGO") {
        initMintId();
    }

    function initMintId() internal {
         for (uint16 i = 1; i <= MAX_DOGGOS; i++){
            mintId.push(i);
         }
    }

   function mintDoggos(uint256 numofDOGGOS) public payable { 
        require(totalSupply() + numofDOGGOS <= MAX_DOGGOS - MAX_RESERVE, "Exceeds Max DOGGOS mintable");
        require(hasSaleStarted == true, "Sales have not start");
        require(numofDOGGOS > 0 && numofDOGGOS <= 10, "Exceeds Max 10 DOGGOS per mint");
        require(msg.value >= MINT_PRICE * numofDOGGOS, "Ether value sent is insufficient");
        
        for (uint256 i = 0; i < numofDOGGOS; i++) {
            _safeMint(msg.sender, getRandomId());
        }
    } 
    
    function preSaleMint(uint256 numofDOGGOS) public payable {
        require(totalSupply() + numofDOGGOS <= MAX_DOGGOS - MAX_RESERVE, "Exceeds Max DOGGOS mintable");
        require(numofDOGGOS <= 5, "Exceeds Max 5 DOGGOS per mint");
        require(addressInPreSale[msg.sender] == true, "Address not whitelisted for presale");
        require(totalPreSaleMinted[msg.sender] + numofDOGGOS <= 5, "Exceeds supply of presale mintable.");
        require(MINT_PRICE * numofDOGGOS <= msg.value, "Transaction value too low.");

        for (uint256 i; i < numofDOGGOS; i++) {
            _safeMint(msg.sender, getRandomId());
        }

        totalPreSaleMinted[msg.sender] += numofDOGGOS;
    }
    
    function walletPreSaleMinted(address _address) public view returns (uint256) {
        return totalPreSaleMinted[_address];
    }
    
    function addWalletToPreSale(address[] memory _address) external onlyOwner {
        for(uint256 i = 0 ; i < _address.length ; i++){
            addressInPreSale[_address[i]] = true;
        }
    }
    
    function giveaways(address to, uint256 numofDOGGOS) public onlyOwner {
        require(totalSupply() + numofDOGGOS <= MAX_DOGGOS, "Exceeds Max DOGGOS");
        
        for (uint256 i = 0; i < numofDOGGOS; i++) {
            _safeMint(to, getRandomId());
        }
    }
    
    function giveawaysToMany(address[] memory recipients) external onlyOwner {
        require(totalSupply() + recipients.length <= MAX_DOGGOS, 'Exceeds Max DOGGOS');
        
        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], getRandomId());
        }
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
    
     function flipPreSale() public onlyOwner {
        hasPreSaleStarted = !hasPreSaleStarted;
    }
    
    function withdrawAll() public payable onlyOwner {
        require(payable(DevAddress).send(address(this).balance / 1000 * 75));
        require(payable(msg.sender).send(address(this).balance));
    }
    
}