import "./ERC721.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Dragons of Zobrotera contract
 * @dev Extends ERC721 Non-Fungible Token Standard implementation
 */
contract DOZ is ERC721, AccessControl{
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
    uint256 private nftPrice = 0.069 * (10 ** 18);
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
    }

    /**
        Update the number of reserved giveaway
        @param _numberOfGiveaway the new number of reserved giveaway
    */
    function reserveGiveaways(uint256 _numberOfGiveaway) public onlyOwner {
        NUMBER_OF_GIVEAWAY = _numberOfGiveaway;
        MAX_NFTS = 10000 - _numberOfGiveaway;
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
        Add new white listed addresses
        Used to identify the presale authorized wallets
        @param addresses the new addresses to add to the white list  
    */
    function whitelistAddressesForPresale(address[] memory addresses) public onlyOwner{
        for(uint32 i = 0; i < addresses.length; i++){
            grantRole(whiteListedRole, addresses[i]);
        }
    }

    /**
        Register new giveaway winners
        Grant access ro the "claimMyGiveAways" function
        @param winners the winners addresses
    */
    function registerGiveawayWinners(address[] memory winners) public onlyOwner {
        for(uint32 i = 0; i < winners.length; i++){
            if(!hasRole(giveawayWinnerRole, winners[i])){
                grantRole(giveawayWinnerRole, winners[i]); 
            }
            giveaways[winners[i]]++;
        }
    }

    /**
        Toggle the presale state
    */
    function flipPresaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    /**
        Toggle the official sale state
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
        Mint a unique surprise :)
        @param winner the big winner of the surprise
    */
    function mintCholrone(address winner) public onlyOwner {
        require(cholroneMintedCount < NUMBER_OF_CHOLRONE, "Cholrone as already been minted");
        require(winner != owner(), "Cholrone cannot be minted by the owner");
        _safeMint(
            winner, 
            MAX_NFTS.add(
                NUMBER_OF_GIVEAWAY.add(
                    cholroneMintedCount.add(1)
                )
            )
        );
        cholroneMintedCount++;
        emit CholroneSafeMinted(winner);
    }

 
    /**
        Claim all the sender's giveaway 
    */
    function claimMyGiveAways() public onlyRole(giveawayWinnerRole){
        require(hasRole(giveawayWinnerRole, msg.sender), "You didn't won any giveaway");
        require(giveaways[msg.sender] > 0, "You already claim all your givaways, wait for the next one");

        for(uint32 i = 0; i < giveaways[msg.sender]; i++){
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            count += 1;
        }

        giveaways[msg.sender] = 0;
    }

    
    /**
        Mint a nft during the presale
    */
    function buyNftOnPresale() public payable onlyRole(whiteListedRole) {
        require(presaleIsActive, "Preale must be active to mint Nft");
        require(!saleIsActive, "Presale as been closed");
        require(totalSupply().add(1) <= MAX_NFTS.add(NUMBER_OF_GIVEAWAY), "Purchase would exceed max supply of Nfts");
        require(nftPrice <= msg.value, "Ether value sent is not correct");
        require(presaled[msg.sender] == 0, "You can't mint more than 1 token with the same account");

        uint256[] memory output = new uint256[](1);

        uint mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
        output[0] = mintIndex;
        count += 1;

        presaled[msg.sender] = count;
        
        emit SafeMinted(msg.sender, 0, output, false);
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
        Emergency: price can be changed in case of large fluctuations in ETH price.
        This feature is here to prevent nft from having prices that are too different from each other.
        WITH A MAXIMUM OF 0.1 ETH
        @param newPrice the new nft price
    */
    function emergencyChangePrice(uint256 newPrice) public onlyOwner {
        require(newPrice <= 0.1 * (10 ** 18), "Price can't exceed 0.1 ETH");
        nftPrice = newPrice;
    }
}