// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./AbstractSwipaFoxStory.sol";

contract SwipaFoxStory is AbstractSwipaFoxStory  {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    address public devAddress1 = 0x2Dd146bcf2Dae32851fCeE09e5F3a4E886eFe076;
    address public devAddress2 = 0x3e81D9B5E4fD4C7C3f69bb4396A857d41D1A3471;
    address public NFTA_Address = 0x855A67D331a52C8701306B7bfa62EaBa68F25F44;
    address public CommunityAddress = 0x266Db4743755109a5926D6fDeD5ED6F6a284aB98;
    address public oAddress = 0x6662DF22aE83a8cCfc9c99C641aA54dE8E120407;

    bool public isSaleActive = false; 

    Counters.Counter private swipaCounter; 
  
    mapping(uint256 => SwipaStory) public swipaStories;
    
    struct SwipaStory {
        uint256 mintPrice;
        string ipfsMetadataHash;
        uint maxSupply;
        uint supply;
    }

    constructor() ERC1155("https://swipathefox.mypinata.cloud/ipfs/") {
        name_ = "Swipa The Fox Stories";
        symbol_ = "FOXSTORIES";
    }

    function addSwipaStory (
        uint256  _mintPrice, 
        string memory _ipfsMetadataHash,
        uint _maxSupply,
        uint _supply
    ) external onlyOwner {

        SwipaStory storage _swipa_story = swipaStories[swipaCounter.current()];
        _swipa_story.mintPrice = _mintPrice;
        _swipa_story.ipfsMetadataHash = _ipfsMetadataHash;
        _swipa_story.maxSupply = _maxSupply;
        _swipa_story.supply = _supply;
        swipaCounter.increment();

    }

    function editSwipaStory (
        uint256 _mintPrice, 
        string memory _ipfsMetadataHash,        
        uint256 _swipaStory
    ) external onlyOwner {
        swipaStories[_swipaStory].mintPrice = _mintPrice;    
        swipaStories[_swipaStory].ipfsMetadataHash = _ipfsMetadataHash;    
    }       

    function mintSwipaStory (
        uint256 amount,
        uint256 _story
    ) external payable {
        require(isSaleActive, "Swipa sale is not active" );
        require(msg.value >= amount.mul(swipaStories[_story].mintPrice), "Swipa amount is not valid");

        uint currentSupply = swipaStories[_story].supply;
        require(currentSupply + amount <= swipaStories[_story].maxSupply, "Order exceeds supply" );
        swipaStories[_story].supply = swipaStories[_story].supply + amount; 

        _mint(msg.sender, _story, amount, "");
    }

    function ownerMint (
        uint256 amount,
        uint256 _story
    ) external onlyOwner {
        uint currentSupply = swipaStories[_story].supply;
        require(currentSupply + amount <= swipaStories[_story].maxSupply, "Order exceeds supply" );
        swipaStories[_story].supply = swipaStories[_story].supply + amount; 

        _mint(msg.sender, _story, amount, "");
    }

    function setSaleActive(bool isSaleActive_ ) external onlyOwner {
        require( isSaleActive != isSaleActive_ , "Values are not valid" );
        isSaleActive = isSaleActive_;
    }
    
    function emergencyWithdraw() external onlyOwner {
        (bool emergencyWithdrawStatus,) = devAddress1.call{value: address(this).balance}("");
        require(emergencyWithdrawStatus, "Failed Emergency Withdraw");
    }

    function emergencyWithdraw2() external onlyOwner {
        (bool emergencyWithdrawStatus2,) = devAddress2.call{value: address(this).balance}("");
        require(emergencyWithdrawStatus2, "Failed Emergency Withdraw");
    }

    function withdraw() external {
        require(address(this).balance > 0, "Not enough ether to withdraw");
        uint256 walletBalance = address(this).balance;
            
        (bool withdraw_1,) = devAddress1.call{value: walletBalance * 425 / 10000}("");
        (bool withdraw_2,) = devAddress2.call{value: walletBalance * 425 / 10000}("");
        (bool withdraw_3,) = NFTA_Address.call{value: walletBalance * 415 / 1000}("");
        (bool withdraw_4,) = CommunityAddress.call{value: walletBalance * 10 / 100}("");
        (bool withdraw_5,) = oAddress.call{value: walletBalance * 40 / 100}("");

        require(withdraw_1 && withdraw_2 && withdraw_3 && withdraw_4 && withdraw_5, "Failed withdraw");
    }

    function uri(uint256 _id) public view override returns (string memory) {
            require(totalSupply(_id) > 0, "URI: nonexistent token");
            
            return string(abi.encodePacked(super.uri(_id), swipaStories[_id].ipfsMetadataHash));
    }    
}