// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";

contract ReadyPlayaOne is ERC721, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Address for address;
    
    mapping (uint256 => string) private _tokenURIs;

    string private _baseURIextended;
    
    Counters.Counter private _tokenIdCounter;
    
    uint256 public constant RP1MaxSupply = 10000;
    bool public saleStatus = false;
    uint256 public salePrice;
    
    address payable thisContract;
    
    address[] private _team = [
        0xF73bd9D826a2e2ed84Cd23d0d9030EbAd4cf438C
        ];
    
    uint256[] private _teamShares = [
        100
        ];
    
    constructor() ERC721("Ready Playa One", "RP1") PaymentSplitter(_team, _teamShares) {
    }
    
    fallback() external payable {

  	}
  	
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    function setSaleStatus(bool _trueOrFalse) external onlyOwner {
        saleStatus = _trueOrFalse;
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
  	
  	function setBaseURI(string memory baseURI_) external onlyOwner() {
            _baseURIextended = baseURI_;
    }
    
    function setThisContract(address payable _thisContract) external onlyOwner {
        thisContract = _thisContract;
    }
    
    function mintPlayas(uint256 _numberOfPlayas) public payable {
        require(msg.value >= calculateTotalPrice(_numberOfPlayas), "Insuffcient amount sent");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(_tokenIdCounter.current().add(_numberOfPlayas) <= RP1MaxSupply, "Purchase would exceed max supply");
        require(saleStatus == true, "Sale is not active");
        
        for(uint256 i = 0; i < _numberOfPlayas; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current() + 1);
            _tokenIdCounter.increment();
        }
    }    
    
    function calculateTotalPrice(uint256 _numberOfPlayas) public view returns(uint256) {
        return salePrice.mul(_numberOfPlayas);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
            return _baseURIextended;
    }
    
}