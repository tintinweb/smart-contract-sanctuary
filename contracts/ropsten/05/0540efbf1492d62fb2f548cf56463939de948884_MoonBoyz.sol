// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";

contract MoonBoyz is ERC721, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Address for address;
    
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURIextended;
    
    Counters.Counter private _tokenIdCounter;
    
    uint256 public constant maxMoonBoyzSupply = 11111;
    bool public whiteListSale = false;
    bool public regularSale = false;
    uint256 public salePrice;
    uint256 public mintFix = 843;
    
    
    address payable thisContract;
    
    mapping(address => uint256) internal whiteList;
    
    
    address[] private _team = [
        0x700eec4D6Ed56ED0F97a0f43Fc9DF5B426Ba25Fc, 
        0xDFf1889Ec0F09d14dE9379938bDc3Df0c6D0B39C, 
        0x4c2a5a4ea0d3f7E9142535f260A05b975Ee1df02, 
        0xDbe3BfBEc8332b0835bf0f466bA34c64655Ba94D, 
        0x12B285072b1Ffc70F367f08066b0D9A7d3337309 
        ];
    
    uint256[] private _teamShares = [
        23,
        22,
        23,
        22,
        10
        ];
    
    constructor() ERC721("MoonBoyz", "MOONBOYZ") PaymentSplitter(_team, _teamShares) {
    }
    
    fallback() external payable {

  	}
  	
  	function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setThisContract(address payable _thisContract) external onlyOwner {
        thisContract = _thisContract;
    }
    
    function whitelistMint(uint256 _numberOfMints) public payable {
        require(whiteList[msg.sender] > 0, "OUT OF WHITELIST MINTS");
        require(whiteList[msg.sender] >= _numberOfMints, "ATTEMPTING TO MINT MORE THAN ALLOTED");
        require(thisContract.send(msg.value), "RECIEVER MUST BE THE CONTRACT");
        require(msg.value == calculateCost(_numberOfMints), "INCORRECT AMOUNT SENT. SEND EXACT AMOUNTS");
        require(_tokenIdCounter.current().add(_numberOfMints) <= maxMoonBoyzSupply, "ATTEMPTED TO MINT PAST MAX SUPPLY");
        require(whiteListSale == true, "WHITELIST SALE IS INACTIVE");
        
        if(_numberOfMints == 1) {
            whiteList[msg.sender] = whiteList[msg.sender].sub(1);
            _safeMint(msg.sender, _tokenIdCounter.current().add(1));
            _tokenIdCounter.increment();
        } else if(_numberOfMints > 1) {
            for(uint256 i = 0; i < _numberOfMints; i++) {
                whiteList[msg.sender] = whiteList[msg.sender].sub(1);
                _safeMint(msg.sender, _tokenIdCounter.current().add(1));
                _tokenIdCounter.increment(); 
            }
        }    
    }
    
    function regularSaleMint(uint256 _numberOfMints) public payable {
        require(thisContract.send(msg.value), "RECIEVER MUST BE THE CONTRACT");
        require(msg.value == calculateCost(_numberOfMints), "INCORRECT AMOUNT SENT. SEND EXACT AMOUNTS");
        require(_tokenIdCounter.current().add(_numberOfMints) <= maxMoonBoyzSupply, "ATTEMPTED TO MINT PAST MAX SUPPLY");
        require(regularSale == true, "SALE IS INACTIVE");
        
        if(_numberOfMints == 1) {
            _safeMint(msg.sender, _tokenIdCounter.current().add(1));
            _tokenIdCounter.increment(); 
        } else
        if(_numberOfMints > 1) {
            for(uint256 i = 0; i < _numberOfMints; i++) {
                _safeMint(msg.sender, _tokenIdCounter.current().add(1));
                _tokenIdCounter.increment(); 
            }
        }
    }
    
    function fixLastMint(address[] memory _currentHolders) public onlyOwner {
        require(mintFix >= _currentHolders.length, "PREVIOUS HOLDERS ALREADY MINTED TO");
        
        for(uint256 i = 0; i < _currentHolders.length; i++) {
            mintFix = mintFix.sub(1);
            _safeMint(_currentHolders[i], _tokenIdCounter.current().add(1));
            _tokenIdCounter.increment();
        }
        
    }
    
    function calculateCost(uint256 _numberOfPasses) public view returns(uint256) {
        return salePrice.mul(_numberOfPasses);
    }
    
    function populateWhitelist(address[] memory _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            whiteList[_users[i]] = whiteList[_users[i]].add(2);
        }
    }
    
    function populatePartialPassUse(address[] memory _users) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            whiteList[_users[i]] = whiteList[_users[i]].add(1);
        }
    }
    
    function viewWhitelistForUser(address _user) external view returns(uint256) {
        return whiteList[_user];
    }
    
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    function setWhitelistSale(bool _trueOrFalse) external onlyOwner {
        whiteListSale = _trueOrFalse;
    }
    
    function setRegularSale(bool _trueOrFalse) external onlyOwner {
        regularSale = _trueOrFalse;
    }
    
    function setSalePrice(uint256 _priceInWei) external onlyOwner {
        salePrice = _priceInWei;
    }
    
    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }
    
}