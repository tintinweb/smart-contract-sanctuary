// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";

contract MoonPass is ERC721, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Address for address;
    
    Counters.Counter private _tokenIdCounter;
    
    uint256 public constant maxMoonPassSupply = 4161;
    bool public saleStatus = false;
    uint256 public salePrice;
    uint256 public maxPurchaseAmount = 5;
    
    address payable thisContract;
    address[] public owners;
    
    mapping(address => uint256) userPurchaseTotal;
    
    
    address[] private _team = [
        0x700eec4D6Ed56ED0F97a0f43Fc9DF5B426Ba25Fc, //Swan 1 23%
        0xDFf1889Ec0F09d14dE9379938bDc3Df0c6D0B39C, //Swan 2 22%
        0x4c2a5a4ea0d3f7E9142535f260A05b975Ee1df02, //Fritz 1 23%
        0xDbe3BfBEc8332b0835bf0f466bA34c64655Ba94D, //Fritz 2 22%
        0x12B285072b1Ffc70F367f08066b0D9A7d3337309 //Izadi 10%
        ];
    
    uint256[] private _teamShares = [
        23,
        22,
        23,
        22,
        10
        ];
    
    constructor() ERC721("MoonPass", "MOONPASS") PaymentSplitter(_team, _teamShares) {
    }
    
    fallback() external payable {

  	}
    
    function setMaxPurchaseAmount(uint256 _maxAllowed) external onlyOwner {
        maxPurchaseAmount = _maxAllowed;
    }
    
    function setThisContract(address payable _thisContract) external onlyOwner {
        thisContract = _thisContract;
    }
    
    function purchaseMoonPass(address _purchaser, uint256 _numberOfPasses) public payable {
        require(msg.value >= calculateTotalPrice(_numberOfPasses), "Insuffcient amount sent");
        require(thisContract.send(msg.value), "Receiever must be the contract");
        require(userPurchaseTotal[_purchaser].add(_numberOfPasses) <= maxPurchaseAmount, "Transaction exceeds max alloted per user");
        require(_tokenIdCounter.current().add(_numberOfPasses) <= maxMoonPassSupply, "Purchase would exceed max supply");
        require(saleStatus == true, "Sale is not active");
        
        for(uint256 i = 0; i < _numberOfPasses; i++) {
            userPurchaseTotal[_purchaser] = userPurchaseTotal[_purchaser] + 1;
            _safeMint(_purchaser, _tokenIdCounter.current() + 1);
            _tokenIdCounter.increment();
        }
    }    
    
    function calculateTotalPrice(uint256 _numberOfPasses) public view returns(uint256) {
        return salePrice.mul(_numberOfPasses);
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
    
    function populateCurrentHolders() external onlyOwner {
        uint256 currentTotal = _tokenIdCounter.current();
        for(uint256 i = 1; i <= currentTotal; i++) {
            address toAdd = super.ownerOf(i);
            owners.push(toAdd);
        }
    }
    
    function returnCurrentHolders() external view returns(address[] memory) {
        return owners;
    }
    
    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }
    
}