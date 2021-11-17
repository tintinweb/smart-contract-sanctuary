pragma solidity ^0.8.4;
                                          
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Sloth is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public giftedAmount;
    uint256 public publicAmountMinted;
    uint256 public privateAmountMinted;
    uint256 public presalePurchaseLimit = 5;
    bool public presaleLive;
    bool public saleLive;
    bool public evolutionLive;
    bool public locked;

    bool public revealed = false; 

    uint256 public constant SLZ_GIFT = 200;
    uint256 public constant SLZ_PRIVATE = 400;
    uint256 public constant SLZ_PUBLIC = 8800;
    uint256 public constant SLZ_MAX = SLZ_GIFT + SLZ_PRIVATE + SLZ_PUBLIC;
    uint256 public constant SLZ_PRICE = 0.088 ether;
    uint256 public constant SLZ_PER_MINT = 10;
    
    mapping(address => bool) public presalerList;
    mapping(address => uint256) public presalerListPurchases;
    mapping(uint256 => bool) private evolved;
    
    string private _tokenBaseURI = "ipfs://QmToZAaU483ijUSiQtUyNEj1TsPQFZd2iEMqk1tWnrRWbK";
    string private _tokenEvolvedURI = "";

    constructor() ERC721("The Sloth Tribe", "SLOTHS") { }
    
    modifier notLocked {
        require(!locked, "Contract metadata methods are locked");
        _;
    }
    
    function addToPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!presalerList[entry], "DUPLICATE_ENTRY");

            presalerList[entry] = true;
        }   
    }

    function removeFromPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            
            presalerList[entry] = false;
        }
    }
    
    
    function buy(uint256 tokenQuantity) external payable {
        require(saleLive, "SALE_CLOSED");
        require(!presaleLive, "ONLY_PRESALE");
        require(totalSupply() < SLZ_MAX, "OUT_OF_STOCK");
        require(publicAmountMinted + tokenQuantity <= SLZ_PUBLIC, "EXCEED_PUBLIC");
        require(tokenQuantity <= SLZ_PER_MINT, "EXCEED_SLZ_PER_MINT");
        require(SLZ_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        
        for(uint256 i = 0; i < tokenQuantity; i++) {
            publicAmountMinted++;
            evolved[totalSupply() + 1] = false;
            _safeMint(msg.sender, totalSupply() + 1);
        }
        
    }
    
    function presaleBuy(uint256 tokenQuantity) external payable {
        require(!saleLive && presaleLive, "PRESALE_CLOSED");
        require(presalerList[msg.sender], "NOT_QUALIFIED");
        require(totalSupply() < SLZ_MAX, "OUT_OF_STOCK");
        require(privateAmountMinted + tokenQuantity <= SLZ_PRIVATE, "EXCEED_PRIVATE");
        require(presalerListPurchases[msg.sender] + tokenQuantity <= presalePurchaseLimit, "EXCEED_ALLOC");
        require(SLZ_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        
        for (uint256 i = 0; i < tokenQuantity; i++) {
            privateAmountMinted++;
            presalerListPurchases[msg.sender]++;
            evolved[totalSupply() + 1] = false;
            _safeMint(msg.sender, totalSupply() + 1);
        }
        
    }
    
    function evolve(uint256 tokenId) external payable {
        require(evolutionLive, "EVOLUTION_CLOSED");
        require(ownerOf(tokenId) == msg.sender);
        require(msg.value >= 0 ether);
        evolved[tokenId] = true; 
    }
    
    function send(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= SLZ_MAX, "MAX_MINT");
        require(giftedAmount + receivers.length <= SLZ_GIFT, "GIFTS_EMPTY");
        
        for (uint256 i = 0; i < receivers.length; i++) {
            giftedAmount++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function isPresaler(address addr) external view returns (bool) {
        return presalerList[addr];
    }
    
    function presalePurchasedCount(address addr) external view returns (uint256) {
        return presalerListPurchases[addr];
    }
    
    function lockMetadata() external onlyOwner {
        locked = true;
    }
    
    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }
    
    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }
    
    function toggleEvolutionStatus() external onlyOwner {
        evolutionLive = !evolutionLive;
    }
    

    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
        revealed = true;
    }
    
    function setEvolvedURI(string calldata URI) external onlyOwner notLocked {
        _tokenEvolvedURI = URI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        if (revealed && evolved[tokenId]) {
            return string(abi.encodePacked(_tokenEvolvedURI, tokenId.toString()));
        } 
        else if (revealed) {
            return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
        }else {
            return  _tokenBaseURI;
        }
        
    }
}