// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";

contract MercenaryMintPass is ERC721, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Address for address;
    
    mapping (uint256 => string) private _tokenURIs;
    mapping(address => uint256) userPurchaseTotal;

    string private _baseURIextended;
    
    Counters.Counter private _tokenIdCounter;
    
    uint256 public constant maxMintPassSupply = 500;
    bool public saleStatus = false;
    uint256 public salePrice;
    uint256 public maxPurchaseAmount = 500;
    
    address payable thisContract;
    
    address[] private _team = [
        0xF73bd9D826a2e2ed84Cd23d0d9030EbAd4cf438C
        ];
    
    uint256[] private _teamShares = [
        100
        ];
    
    constructor() ERC721("Mercenary Early Access Pass", "RP1MERCENARY") PaymentSplitter(_team, _teamShares) {
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
    
    function setMaxPurchaseAmount(uint256 _maxAllowed) external onlyOwner {
        maxPurchaseAmount = _maxAllowed;
    }
    
    function setThisContract(address payable _thisContract) external onlyOwner {
        thisContract = _thisContract;
    }
    
    function purchaseMintPass(uint256 _numberOfPasses) public payable {
        require(msg.value >= calculateTotalPrice(_numberOfPasses), "Insuffcient amount sent");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(userPurchaseTotal[msg.sender].add(_numberOfPasses) <= maxPurchaseAmount, "Transaction exceeds max alloted per user");
        require(_tokenIdCounter.current().add(_numberOfPasses) <= maxMintPassSupply, "Purchase would exceed max supply");
        require(saleStatus == true, "Sale is not active");
        
        for(uint256 i = 0; i < _numberOfPasses; i++) {
            userPurchaseTotal[msg.sender] = userPurchaseTotal[msg.sender] + 1;
            _safeMint(msg.sender, _tokenIdCounter.current() + 1);
            _tokenIdCounter.increment();
        }
    }    
    
    function calculateTotalPrice(uint256 _numberOfPasses) public view returns(uint256) {
        return salePrice.mul(_numberOfPasses);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
            return _baseURIextended;
    }
    
}