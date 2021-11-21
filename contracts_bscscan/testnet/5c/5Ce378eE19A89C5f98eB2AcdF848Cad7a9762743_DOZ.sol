import "./ERC721.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./Stackable.sol";
import "./DOZItems.sol";

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Dragons of Zobrotera contract
 * @dev Extends ERC721 Non-Fungible Token Standard implementation
 */
contract DOZ is AccessControl, Stackable{
    using SafeMath for uint256;

    // White listed role
    bytes32 private constant whiteListedRole = keccak256("wl");
    // Giveaway winner role
    bytes32 private constant giveawayWinnerRole = keccak256("gw");

    // Max mint per transaction
    uint public constant maxNftPurchase = 20; 

    // Mapping from address to number of mint during presale
    mapping(address => uint256) private presaled;
    // Mapping from address to number of claimable giveaway
    mapping(address => uint256) private giveaways;

    // Tokens total count
    uint256 private count = 0;
    // Test tokens total count
    uint256 private testCount = 1 * (10 ** 10);
    // NFT price => 0.069 ETH
    uint256 private nftPrice = 135 * (10 ** 18);
    // Reserved number of giveaway
    uint256 private NUMBER_OF_GIVEAWAY = 100;
    // Maximum number of nft that can be minted
    uint256 private MAX_NFTS = 10000 - NUMBER_OF_GIVEAWAY;
    // Status of the official sale
    bool private saleIsActive = false;
    // Status of the presale
    bool private presaleIsActive = false;

    // Surprise :)
    uint256 private NUMBER_OF_CHOLRONE = 1;
    // Surprise :)
    uint256 private cholroneMintedCount = 0;

    // DOZitems contract address
    address DOZItemsContract;

    // Event emitted when a token as been minted safly
    event SafeMinted(address who, uint64 timestamp, uint256[] tokenIds, bool isTestMint);
    // Event emitted when a token as been minted safly througt a giveaway
    event GiveawaySafeMinted(address[] winners);
    // Event emitted for the surprise
    event CholroneSafeMinted(address who);


    /**
        Initialize and setup the admin role for the owner
    */
    constructor() ERC721("Dragons of Zobrotera", "DOZ") {
        _setRoleAdmin(whiteListedRole, DEFAULT_ADMIN_ROLE);
        _setupRole(getRoleAdmin(whiteListedRole), msg.sender);
        _setupStackTypes();
    }

    /**
        Update the number of reserved giveaway
        @param _numberOfGiveaway the new number of reserved giveaway
    */
    function reserveGiveaways(uint256 _numberOfGiveaway) public onlyOwner {
        NUMBER_OF_GIVEAWAY = _numberOfGiveaway;
        MAX_NFTS = MAX_NFTS - _numberOfGiveaway;
    }

    /**
        Mint a token only for the contract owner
        Used to setup a first mint to list the OpenSea collection
    */
    function testMintToOwner() public onlyOwner {
        uint mintIndex = totalSupply();
        _safeMint(owner(), mintIndex);
        count += 1;
    }

    /**
        Withdraw ether from the contract to the owner's wallet
    */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /** 
        Airdrop giveaway into the winners wallets
        @param winners the winners addresses list
    */
    function airdropGiveaways(address[] memory winners) public onlyOwner {
        for(uint32 i = 0; i < winners.length; i++){
            uint mintIndex = totalSupply();
            _safeMint(winners[i], mintIndex);
            count += 1;
        }
    }

    /**
        Toggle the official sale state
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
        Update the total max supply
        @param maxSupply the new max supply
     */
    function updateMaxSupply(uint256 maxSupply) public onlyOwner {
        require(maxSupply >= count);
        MAX_NFTS = maxSupply - NUMBER_OF_GIVEAWAY;
    }


    /**
        Update the doz items contract address
        @param contractAddress the new address
     */
    function setDozItemsContractAddress(address contractAddress) public onlyOwner(){
        DOZItemsContract = contractAddress;
    }

    /**
        Mint a nft during the official sale
        @param timeStamp the current timestamp, used for the dragons of zobrotera quest/game
        @param numberOfToken the number of token to mint
    */
    function mintNft(uint64 timeStamp, uint64 numberOfToken) public payable {
        require(saleIsActive, "Sale must be active to mint Nft");
        require(totalSupply().add(numberOfToken) <= MAX_NFTS.add(NUMBER_OF_GIVEAWAY), "Purchase would exceed max supply of Nfts");
        require(nftPrice.mul(numberOfToken) <= msg.value, "Ether value sent is not correct");
        require(numberOfToken <= maxNftPurchase, "You can't mint more than 20 token in the same transaction");

        uint256[] memory output = new uint256[](numberOfToken);

        for(uint32 i = 0; i < numberOfToken; i++){
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            output[i] = mintIndex;
            count += 1;
        }

        emit SafeMinted(msg.sender, timeStamp, output, false);
    }

    function claimStackedNft(uint256 tokenId) public {
        require(ownerOf(tokenId) == address(this), "Your token as not been stacked");
        require(stackedNft[tokenId].owner == address(msg.sender), "Your are not the owner of this stacked nft");
        require(stackedNft[tokenId].endDate <= block.timestamp, "This stack as not ended");

        uint256 timeUnderStack = block.timestamp - stackedNft[tokenId].startDate;
        StackType memory stackType = stackTypes[stackedNft[tokenId].stackType];
        
        require(timeUnderStack >= stackType.period, "Unsuficient stack time to claim rewards");

        _transfer(address(this), address(msg.sender), tokenId);
        
        if(stackType.winNft == true){
            for(uint32 i = 0; i < stackType.nftAmount; i++){
                uint mintIndex = totalSupply();
                _safeMint(msg.sender, mintIndex);
                count += 1;
            }
        }
        else if(stackType.winLootBox == true){
            DOZItems itemContract = DOZItems(DOZItemsContract);
            itemContract.openLootBoxes(stackType.lootBoxAmount, msg.sender);
        }
        else if(stackType.winCurrency == true){
            uint amount = stackType.currencyAmount;
            payable(address(msg.sender)).transfer(amount);
        }
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

    /**
        Get the current official sale state
        @return boolean
    */
    function isSaleActive() public view returns (bool) {
        return saleIsActive;
    }

    /**
        Get the current presale state
        @return boolean
    */
    function isPresaleActive() public view returns (bool) {
        return presaleIsActive;
    }

    /**
        Check if an address is white listed for the presale
        @param addr the address to check
        @return boolean
    */
    function isAddressWhitelisted(address addr) public view returns (bool){
        return hasRole(whiteListedRole, addr);
    }

    /**
        Check if the sender already bought the nft he could buy on presale, return the bought tokenID plus 1 or 0 if not token as been bought on presale
        @return uint256
    */
    function didSenderBoughtOnPresale() public view returns (uint256){
        return presaled[msg.sender];
    }

    /**
        Returns all sender owned token ids
        @return uint256[]
    */
    function getNfts() public view returns (uint256[] memory){
        uint256[] memory tokens = new uint256[](1);
        uint256 index = 0;
        for(uint32 i = 0; i < count; i++){
            if(ownerOf(i) == msg.sender){
                tokens[index] = i;
                index++;
            }
        }
        return tokens;
    }

    /**
        Emergency: price can be changed in case of large fluctuations in ETH price.
        This feature is here to prevent nft from having prices that are too different from each other.
        WITH A MAXIMUM OF 0.1 ETH
        @param newPrice the new nft price
    */
    function emergencyChangePrice(uint256 newPrice) public onlyOwner {
        require(newPrice >= 0, "Price can't be lower than 0");
        nftPrice = newPrice;
    }
}