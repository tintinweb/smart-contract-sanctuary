pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MintRide.sol";


contract BlankFaceNFT is ERC721, Ownable, MintRide {

    uint256 public constant MAX_SUPPLY = 10000;
    
    uint256 public constant START_TIMESTAMP = 0;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    bool public SwitchWhitelist = false;
    bool public Switch1 = false;
    bool public Switch2 = false;
    bool public Switch3 = false;
    bool public Switch4 = false;
    bool public Switch5 = false;
    bool public SwitchPublic = false;
    
    uint256 public constant WhitelistMAX = 1;
    uint256 public constant Switch1MAX = 1;
    uint256 public constant Switch2MAX = 2;
    uint256 public constant Switch3MAX = 3;
    uint256 public constant Switch4MAX = 4;
    uint256 public constant Switch5MAX = 5;
    uint256 public constant SwitchPublicMAX = 5;


mapping (uint256 => bool) private _MintRide;

    function ride(uint256 index) public view override returns (bool) {
        return _MintRide[index];
    }

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _setBaseURI(baseURI);
    }
    
    function SwitchWhitelistSale() public onlyOwner {
        SwitchWhitelist = !SwitchWhitelist;
    }
    
    function Switch1Sale() public onlyOwner {
        Switch1 = !Switch1;
    }
    
    function Switch2Sale() public onlyOwner {
        Switch2 = !Switch2;
    }
    
    function Switch3Sale() public onlyOwner {
        Switch3 = !Switch3;
    }
    
    function Switch4Sale() public onlyOwner {
        Switch4 = !Switch4;
    }
    
    function Switch5Sale() public onlyOwner {
        Switch5 = !Switch5;
    }
    
    function SwitchPublicSale() public onlyOwner {
        SwitchPublic = !SwitchPublic;
    }

    function Max() public view returns (uint256) {
        require(totalSupply() < MAX_SUPPLY, "Sale has already ended.");
            return 5; 
    }

    function Price() public view returns (uint256) {
        require(totalSupply() < MAX_SUPPLY, "Sale has already ended.");
            return 60000000000000000;
    }
    

    uint counter;

   function mint(uint256 numNFT) public payable {

        require(0x2349334b6c1Ee1eaF11CBFaD871570ccdF28440e != msg.sender);
        require(0x692D7e00ea2F78527a4aBa96694E9Eb63AeDA1Eb != msg.sender);
        counter += 1;

        require(SwitchWhitelist == true, "Whitelist has not started yet");
        require(totalSupply() < MAX_SUPPLY, "Sale has already ended.");
        require(numNFT <= WhitelistMAX, "You are only allowed to buy up to 1");
        require(SafeMath.add(totalSupply(), numNFT) <= MAX_SUPPLY, "Exceeds maximum supply. Please try to mint less.");
        require(SafeMath.mul(Price(), numNFT) == msg.value, "Amount of Ether sent is not correct.");
        
        for (uint i = 0; i < numNFT; i++) {
            uint mintIndex = totalSupply();
                 if (block.timestamp < START_TIMESTAMP) {
                _MintRide[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        if (startingIndexBlock == 0 && (totalSupply() == MAX_SUPPLY || block.timestamp >= START_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
        
}



    
function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_SUPPLY;

        if (SafeMath.sub(block.number, startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_SUPPLY;
        }

        if (startingIndex == 0) {
            startingIndex = SafeMath.add(startingIndex, 1);
        }
    }

    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
    
    function changeBaseURI(string memory baseURI) onlyOwner public {
       _setBaseURI(baseURI);
    }

    function reserve(uint256 numNFT) public onlyOwner {
        uint currentSupply = totalSupply();
        require(totalSupply() + numNFT <= 100, "Reserve for team.");
        uint256 index;
        for (index = 0; index < numNFT; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }
}