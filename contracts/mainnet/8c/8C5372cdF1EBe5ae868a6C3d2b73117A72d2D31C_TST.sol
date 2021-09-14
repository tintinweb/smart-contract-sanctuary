import "./ERC721.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title NFT contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract TST is ERC721, AccessControl{
    using SafeMath for uint256;

    bytes32 private constant whiteListedRole = keccak256("wl");
    bytes32 private constant giveawayWinnerRole = keccak256("gw");

    uint public constant maxNftPurchase = 20;
    uint public constant maxNftPurchaseOnPresale = 1;

    mapping(address => uint256) private presaled;
    mapping(address => uint256) private giveaways;

    uint256 private count = 0;
    uint256 private testCount = 1 * (10 ** 10);
    uint256 private nftPrice = 0.00000001 * (10 ** 18);
    uint256 private NUMBER_OF_GIVEAWAY = 100;
    uint256 private NUMBER_OF_CHOLRONE = 1;
    uint256 private MAX_NFTS = 10000 - NUMBER_OF_GIVEAWAY;
    uint256 private cholroneMintedCount = 0;
    bool private saleIsActive = false;
    bool private presaleIsActive = false;

    event SafeMinted(address who, uint64 timestamp, uint256[] tokenIds, bool isTestMint);
    event GiveawaySafeMinted(address[] winners);
    event CholroneSafeMinted(address who);

    constructor() ERC721("tstdz", "TST") {
        _setRoleAdmin(whiteListedRole, DEFAULT_ADMIN_ROLE);
        _setupRole(getRoleAdmin(whiteListedRole), msg.sender);
    }


    /**
        Public only owner functions
    */
    function reserveGiveaways(uint256 _numberOfGiveaway) public onlyOwner {
        NUMBER_OF_GIVEAWAY = _numberOfGiveaway;
        MAX_NFTS = 10000 - _numberOfGiveaway;
    }

    function testMintToOwner() public onlyOwner {
        uint mintIndex = totalSupply();
        _safeMint(owner(), mintIndex);
        count += 1;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function whitelistAddressesForPresale(address[] memory addresses) public onlyOwner{
        for(uint32 i = 0; i < addresses.length; i++){
            grantRole(whiteListedRole, addresses[i]);
        }
    }

    function registerGiveawayWinners(address[] memory winners) public onlyOwner {
        for(uint32 i = 0; i < winners.length; i++){
            if(!hasRole(giveawayWinnerRole, winners[i])){
                grantRole(giveawayWinnerRole, winners[i]); 
            }
            giveaways[winners[i]]++;
        }
    }

    function flipPresaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

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
        Public functions
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
        Public payable functions
    */

    function buyNftOnPresale() public payable onlyRole(whiteListedRole) {
        require(presaleIsActive, "Preale must be active to mint Nft");
        require(!saleIsActive, "Presale as been closed");
        require(totalSupply().add(1) <= MAX_NFTS.add(NUMBER_OF_GIVEAWAY), "Purchase would exceed max supply of Nfts");
        require(nftPrice <= msg.value, "Ether value sent is not correct");
        require(balanceOf(msg.sender).add(1) <= maxNftPurchaseOnPresale, "You can't mint more than 1 token with the same account");

        uint256[] memory output = new uint256[](1);

        uint mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
        output[0] = mintIndex;
        count += 1;

        presaled[msg.sender] = count;
        
        emit SafeMinted(msg.sender, 0, output, false);
    }

    function mintNft(uint64 timeStamp, uint64 numberOfToken) public payable {
        require(saleIsActive, "Sale must be active to mint Nft");
        require(totalSupply().add(numberOfToken) <= MAX_NFTS, "Purchase would exceed max supply of Nfts");
        require(nftPrice.mul(numberOfToken) <= msg.value, "Ether value sent is not correct");
        require(balanceOf(msg.sender).add(numberOfToken) <= maxNftPurchase, "You can't mint more than 20 token with the same account");

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
        Public view functions
    */

    function getCount() public view returns(uint256) {
        return count;
    }

    function totalSupply() public view returns (uint256) {
        return getCount();
    }

    function isSaleActive() public view returns (bool) {
        return saleIsActive;
    }

    function isPresaleActive() public view returns (bool) {
        return presaleIsActive;
    }

    function isAddressWhitelisted(address addr) public view returns (bool){
        return hasRole(whiteListedRole, addr);
    }

    function didSenderBoughtOnPresale() public view returns (uint256){
        return presaled[msg.sender];
    }

    // Emergency: price can be changed in case of large fluctuations in ETH price.
    // This feature is here to prevent nft from having prices that are too different from each other.
    // WITH A MAXIMUM OF 0.1 ETH
    function emergencyChangePrice(uint256 newPrice) public onlyOwner {
        require(newPrice <= 0.1 * (10 ** 18), "Price can't exceed 0.1 ETH");
        nftPrice = newPrice;
    }
}