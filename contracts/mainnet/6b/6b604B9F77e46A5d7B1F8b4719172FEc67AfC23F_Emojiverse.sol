// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";

interface iDaoji {
    function updateRewards(address _sender, address _reciever) external;
    function burnDaoji(address _account, uint256 _number) external;
}

contract Emojiverse is ERC721, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Address for address;
    
    iDaoji public Daoji;
    
    mapping (uint256 => string) private _tokenURIs;
    mapping (address => bool) approvedAddress;

    string private _baseURIextended;
    
    bool public saleStatus = false;
    bool public burnState = false;
    
    Counters.Counter private _tokenIdCounter;
    
    uint256 public constant maxEmojis = 11111;
    uint256 public salePrice;
    uint256 public supplyCount;
    
    address payable thisContract;
    
    address[] private _team = [
        0x1CE46c579f0D2dB71B3875b5c391Ce7E81cff135
        ];
    
    uint256[] private _teamShares = [
        100
        ];
    
    constructor() ERC721("Emojiverse", "EMOJI") PaymentSplitter(_team, _teamShares) {
    }
    
    fallback() external payable {

  	}
  	
  	function setDaoji(address _daoji) external onlyOwner {
  	    Daoji = iDaoji(_daoji);
  	}
  	
    function totalSupply() external view returns (uint256) {
        return supplyCount;
    }
    
    function setSaleStatus() external onlyOwner {
        saleStatus = !saleStatus;
    }
    
    function setBurnState() external onlyOwner {
        burnState = !burnState;
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
  	
  	function setBaseURI(string memory baseURI_) external onlyOwner {
            _baseURIextended = baseURI_;
    }
    
    function setApprovedAddress(address _approved, bool _trueOrFalse) external onlyOwner {
        approvedAddress[_approved] = _trueOrFalse;
    }
    
    function setThisContract(address payable _thisContract) external onlyOwner {
        thisContract = _thisContract;
    }
    
    function happyFace(uint256 _numberOfEmojis) external payable {
        require(msg.value >= calculateTotalPrice(_numberOfEmojis), "Insuffcient amount sent");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(_tokenIdCounter.current().add(_numberOfEmojis) <= maxEmojis, "Purchase would exceed max supply");
        require(saleStatus == true, "Sale is not active");
        require(_numberOfEmojis <= 24, "Max per transaction is 24");
        
        if(_numberOfEmojis != 24) {
            for(uint256 i = 0; i < _numberOfEmojis; i++) {
                _safeMint(msg.sender, _tokenIdCounter.current() + 1);
                _tokenIdCounter.increment();
                supplyCount = supplyCount + 1;
            }
        } else
        if(_numberOfEmojis == 24) {
            for(uint256 i = 0; i < 30; i++) {
                _safeMint(msg.sender, _tokenIdCounter.current() + 1);
                _tokenIdCounter.increment();
                supplyCount = supplyCount + 1;
            }
        }
    }
    
    function sadFace(uint256 _tokenID) external {
        require(super.ownerOf(_tokenID) == msg.sender || approvedAddress[msg.sender] == true, "You are not eligible for the ID you are trying to burn");
        require(burnState == true, "Burning is not enabled");
        _burn(_tokenID);
        supplyCount = supplyCount - 1;
    }
    
    function daojiBurn(address _account, uint256 _amount) external {
        require(approvedAddress[msg.sender] == true, "You are not approved to burn with this function");
        Daoji.burnDaoji(_account, _amount);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override {
        Daoji.updateRewards(from, to);
        ERC721.transferFrom(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        Daoji.updateRewards(from, to);
        ERC721.safeTransferFrom(from, to, tokenId, _data);
    }
    
    function calculateTotalPrice(uint256 _numberOfEmojis) public view returns(uint256) {
        return salePrice.mul(_numberOfEmojis);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
            return _baseURIextended;
    }
    
}