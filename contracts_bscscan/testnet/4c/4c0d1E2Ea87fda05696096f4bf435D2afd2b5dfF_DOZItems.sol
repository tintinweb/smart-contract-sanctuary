import "./ERC721.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Dragons of Zobrotera contract
 * @dev Extends ERC721 Non-Fungible Token Standard implementation
 */
contract DOZItems is ERC721, AccessControl{
    using SafeMath for uint256;

    // Event emitted when a token as been minted safly
    event lootBoxOpened(address who, uint256 timestamp, uint256 numberOfLootBoxes);

    bool private saleIsActive = false;
    
    // Tokens total count
    uint256 private count = 0;
    // NFT price => 0.069 ETH
    uint256 private lootBoxPrice = 0.01 * (10 ** 18);
    address private DOZcontract;

    /**
        Initialize and setup the admin role for the owner
    */
    constructor() ERC721("Dragons of Zobrotera items", "DOZI") {
        
    }

    function setDozContractAddress(address DOZContractAddress) public onlyOwner(){
        DOZcontract = DOZContractAddress;
    }

    function flipSaleState() public onlyOwner(){
        saleIsActive = !saleIsActive;
    }

    /**
        Buy a lootbox
        @param numberOfBoxes the number of boxes to open
        @param _to the address where to mint the nft (only if msg.sender is DOZcontract)
    */
    function openLootBoxes(uint256 numberOfBoxes, address _to) public payable {
        require(saleIsActive || msg.sender == DOZcontract, "Sale must be active to mint Nft");
        require(lootBoxPrice.mul(numberOfBoxes) <= msg.value || msg.sender == DOZcontract, "Value sent is not correct");

        address to = msg.sender;

        if(msg.sender == DOZcontract){
            to = _to;
        }

        for(uint32 i = 0; i < numberOfBoxes; i++){
            uint mintIndex = totalSupply();
            _safeMint(to, mintIndex);
            count += 1;
        }

        emit lootBoxOpened(msg.sender, block.timestamp, numberOfBoxes);
    }

    /**
        Get the current number of minted tokens 
        @return uint256
    */
    function getCount() public view returns(uint256) {
        return count;
    }

    /**
        Get the current total supply
        @return uint256
    */
    function totalSupply() public view returns (uint256) {
        return getCount();
    }
}