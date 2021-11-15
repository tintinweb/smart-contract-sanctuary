// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract ERC721Full is Context, AccessControlEnumerable, ERC721, ERC721Enumerable, ERC721Pausable {

  /*** INIT ***/

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  /*** METHODS ***/

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function pause() public {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
      _pause();
  }

  function unpause() public {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
      _unpause();
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
      return super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MarsGenesisAuctionBase.sol";


/// @title MarsGenesis Auction Contract
/// @author Mario Eguiluz
/// @notice You can use this contract to buy, sell and bid on MarsGenesis lands
contract MarsGenesisAuction is MarsGenesisAuctionBase {

    /// @notice Inits the contract 
    /// @param _erc721Address The address of the main MarsGenesis contract
    /// @param _walletAddress The address of the wallet of MarsGenesis contract
    /// @param _cut The contract owner tax on sales
    constructor (address _erc721Address, address payable _walletAddress, uint256 _cut) MarsGenesisAuctionBase(_erc721Address, _walletAddress, _cut) {}

    /*** EXTERNAL ***/

    /// @notice Enters a bid for a specific land (payable)
    /// @dev If there was a previous (lower) bid, it removes it and adds its amount to pending withdrawals. 
    /// On success, it emits the LandBidEntered event.
    /// @param tokenId The id of the land to bet upon
    function enterBidForLand(uint tokenId) external payable {
        require(nonFungibleContract.ownerOf(tokenId) != address(0), "Land not yet owned");
        require(nonFungibleContract.ownerOf(tokenId) != msg.sender, "You already own the land");
        require(msg.value > 0, "Amount must be > 0");
        
        Bid memory existing = landIdToBids[tokenId];
        require(msg.value > existing.value, "Amount must be > than existing bid");

        if (existing.value > 0) {
            // Refund the previous bid
            addressToPendingWithdrawal[existing.bidder] += existing.value;
        }
        landIdToBids[tokenId] = Bid(true, tokenId, msg.sender, msg.value);
        emit LandBidEntered(tokenId, msg.value, msg.sender);
    }

    /// @notice Buys a land for a specific price (payable)
    /// @dev The land must be for sale before other user calls this method. If the same user had the higher bid before, it gets refunded into the pending withdrawals. On success, emits the LandBought event. Executes a ERC721 safeTransferFrom
    /// @param tokenId The id of the land to be bought
    function buyLand(uint tokenId) external payable {
        require(msg.sender != nonFungibleContract.ownerOf(tokenId), "You cant buy your own land");
        
        Offer memory offer = landIdToOfferForSale[tokenId];
        require(offer.isForSale, "Item is not for sale");
        require(offer.seller == nonFungibleContract.ownerOf(tokenId), "Seller is no longer the owner of the item");
        require(msg.value >= offer.minValue, "Not enough balance");

        address seller = offer.seller;

        nonFungibleContract.safeTransferFrom(seller, msg.sender, tokenId);

        uint taxAmount = msg.value * ownerCut / 100;
        uint netAmount = msg.value - taxAmount;

        addressToPendingWithdrawal[seller] += netAmount;

        // 80% goes to non-profit
        uint npoAmount = taxAmount * 80 / 100;
        npoBalance += npoAmount;
        ownerBalance += taxAmount - npoAmount;

        emit LandBought(tokenId, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = landIdToBids[tokenId];
        if (bid.bidder == msg.sender) {
            addressToPendingWithdrawal[msg.sender] += bid.value;
            landIdToBids[tokenId] = Bid(false, tokenId, address(0), 0);
        }
    }

    /// @notice Offers a land that ones own for sale for a min price
    /// @dev On success, emits the event LandOffered
    /// @param tokenId The id of the land to put for sale
    /// @param minSalePriceInWei The minimum price of the land (Wei)
    function offerLandForSale(uint tokenId, uint minSalePriceInWei) external {
        require(msg.sender == address(nonFungibleContract), "Use MarsContractBase:offerLandForSale instead");
        require(nonFungibleContract.ownerOf(tokenId) == msg.sender || nonFungibleContract.getApproved(tokenId) == address(this), "Only owner can add item from sale");

        landIdToOfferForSale[tokenId] = Offer(true, tokenId, nonFungibleContract.ownerOf(tokenId), minSalePriceInWei);

        emit LandOffered(tokenId, minSalePriceInWei, nonFungibleContract.ownerOf(tokenId));
    }

    /// @notice Sends free balance to the main wallet 
    /// @dev Only callable by the deployer
    function sendBalanceToWallet() external { 
        require(msg.sender == _deployerAddress, "INVALID_ROLE");
        require(ownerBalance > 0, "No Balance to send");
        uint amount = ownerBalance;
        ownerBalance = 0;
        
        (bool success,) = address(walletContract).call{value: amount}("");
        require(success);
    }

    /// @notice Sends donation balance to the npo addresses
    /// @dev Only callable by the deployer
    function sendDonations() external { 
        require(msg.sender == _deployerAddress, "INVALID_ROLE");
        require(npoBalance > 0, "No Balance to send");
        
        uint amount = npoBalance;
        npoBalance = 0;

        uint donation1 = amount / 2;        
        (bool success1,) = NPOaddress1.call{value: donation1}("");
        require(success1);

        uint donation2 = amount - donation1;
        (bool success2,) = NPOaddress2.call{value: donation2}("");
        require(success2);
    }

    /// @notice Users can withdraw their available balance
    /// @dev Avoids reentrancy
    function withdraw() external { 
        uint amount = addressToPendingWithdrawal[msg.sender];
        addressToPendingWithdrawal[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /// @notice Owner of a land can accept a bid for its land
    /// @dev Only callable by the main contract. On success, emits the event LandBought. Disccounts the contract tax (cut) from the final price. Executes a ERC721 safeTransferFrom
    /// @param tokenId The id of the land
    /// @param minPrice The minimum price of the land
    function acceptBidForLand(uint tokenId, uint minPrice) external {
        require(msg.sender == address(nonFungibleContract), "Use MarsContractBase:acceptBidForLand instead");
        require(nonFungibleContract.ownerOf(tokenId) == msg.sender || nonFungibleContract.getApproved(tokenId) == address(this), "Sender is not owner");
        
        address seller = nonFungibleContract.ownerOf(tokenId);
        Bid memory bid = landIdToBids[tokenId];

        require(bid.value > 0, "Value must be > 0");
        require(bid.value >= minPrice, "Value < minPrice");

        nonFungibleContract.safeTransferFrom(seller, bid.bidder, tokenId);

        uint amount = bid.value;
        landIdToBids[tokenId] = Bid(false, tokenId, address(0), 0);

        uint taxAmount = amount * ownerCut / 100;
        uint netAmount = amount - taxAmount;

        addressToPendingWithdrawal[seller] += netAmount;
        
        // 80% goes to non-profit
        uint npoAmount = taxAmount * 80 / 100;
        npoBalance += npoAmount;
        ownerBalance += taxAmount - npoAmount;

        emit LandBought(tokenId, bid.value, seller, bid.bidder);
    }

    /// @notice Users can withdraw their own bid for a specific land
    /// @dev The bid amount is automatically transfered back to the user. Emits LandBidWithdrawn event. Avoids reentrancy.
    /// @param tokenId The id of the land that had the bid on
    function withdrawBidForLand(uint tokenId) external {
        require(nonFungibleContract.ownerOf(tokenId) != address(0), "Sender cant be 0x0");
        require(nonFungibleContract.ownerOf(tokenId) != msg.sender, "Sender cant be the owner");
        
        Bid memory bid = landIdToBids[tokenId];
        require(bid.bidder == msg.sender, "Only bidder can withdraw their bid");

        uint amount = bid.value;

        landIdToBids[tokenId] = Bid(false, tokenId, address(0), 0);
        payable(msg.sender).transfer(amount);
        emit LandBidWithdrawn(tokenId, bid.value, msg.sender);
    }

    /// @notice Updates the wallet contract address    
    /// @param _address The address of the wallet contract
    /// @dev Only callable by deployer
    function setWalletAddress(address payable _address) external {
        require(msg.sender == _deployerAddress, "INVALID_ROLE");
        MarsGenesisWallet candidateContract = MarsGenesisWallet(_address);
        walletContract = candidateContract;
    }

    /// @notice Updates the nonprofit addresses    
    /// @param _address1 The address of the NPO 1
    /// @param _address2 The address of the NPO 2
    /// @dev Only callable by deployer
    function setNonProfitAddresses(address payable _address1, address payable _address2) external {
        require(msg.sender == _deployerAddress, "INVALID_ROLE");
        NPOaddress1 = _address1;
        NPOaddress2 = _address2;
    }

    /*** PUBLIC ***/

    /// @notice Checks if a land is for sale
    /// @param tokenId The id of the land to check
    /// @return boolean, true if the land is for sale
    function landIdIsForSale(uint256 tokenId) public view returns(bool) {
        return landIdToOfferForSale[tokenId].isForSale;
    }

    /// @notice Puts a land no longer for sale
    /// @dev Callable only by the main contract or the owner of a land. Emits the event LandNoLongerForSale
    /// @param tokenId The id of the land
    function landNoLongerForSale(uint tokenId) public {
        require(nonFungibleContract.ownerOf(tokenId) == msg.sender || nonFungibleContract.getApproved(tokenId) == address(this), "Only owner can remove item from sale");
        landIdToOfferForSale[tokenId] = Offer(false, tokenId, msg.sender, 0);
        emit LandNoLongerForSale(tokenId, nonFungibleContract.ownerOf(tokenId));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./ERC721Full.sol";
import "./MarsGenesisWallet.sol";

/// @title MarsGenesis Auction Base Contract
/// @author Mario Eguiluz
/// @notice Serves as the base for MarsGenesisAuction contract
contract MarsGenesisAuctionBase is ERC165 {

    /// @dev Interface signatures
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);
    bytes4 constant InterfaceSignature_ERC721_Metadata = bytes4(0x5b5e139f);
    bytes4 constant InterfaceSignature_ERC721_Enumerable = bytes4(0x780e9d63);
    bytes4 constant InterfaceSignature_MarsGenesisAuction =
        bytes4(keccak256('landIdIsForSale(uint256 tokenId)')) ^
        bytes4(keccak256('landNoLongerForSale(uint256)'));

    /// @dev Contract owner balance
    uint public ownerBalance;

    /// @dev Contract non-profits balance
    uint public npoBalance;

    /// @dev Contract owner tax on sales
    uint256 public ownerCut;

    /// @dev Reference to main contract that implements ERC721
    ERC721Full nonFungibleContract; 

    /// @dev Auction contract address
    MarsGenesisWallet walletContract;

    /// @dev Address of the deployer account
    address _deployerAddress;

    /// @dev Address of the Non Profit Organization 1
    address public NPOaddress1;

    /// @dev Address of the Non Profit Organization 2
    address public NPOaddress2;

    /// @notice Inits the contract 
    /// @dev The main contract should support specific interfaces
    /// @param _erc721Address The address of the main MarsGenesis contract
    /// @param _walletAddress The address of the wallet of MarsGenesis contract
    /// @param _cut The contract owner tax on sales
    constructor (address _erc721Address, address payable _walletAddress, uint256 _cut) {
        require(_cut <= 100, "INVALID_OWNER_CUT");
        ownerCut = _cut;

        _deployerAddress = msg.sender;

        ERC721Full candidateContract = ERC721Full(_erc721Address);
        
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721), "ERC721 not supported");
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721_Metadata), "ERC721Metadata not supported");
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721_Enumerable), "ERC721Enumerable not supported");

        nonFungibleContract = candidateContract;
        walletContract = MarsGenesisWallet(_walletAddress);
    }
    

    /*** EVENTS ***/

    /// @dev Event fired when a land is offered for sale
    event LandOffered(uint indexed tokenId, uint minValue, address indexed from);

    /// @dev Event fired when a user bids on a land
    event LandBidEntered(uint indexed tokenId, uint value, address indexed from);

    /// @dev Event fired when a bid is withdrawn
    event LandBidWithdrawn(uint indexed tokenId, uint value, address indexed from);

    /// @dev Event fired when a land is bought via auctioning or direct sale
    event LandBought(uint indexed tokenId, uint value, address indexed from, address indexed to);

    /// @dev Event fired when a land is no longer for sale
    event LandNoLongerForSale(uint indexed tokenId, address indexed from);
    

    /*** STORAGE ***/

    /// @dev The main Offer struct for auctioning
    struct Offer {
        bool isForSale;
        uint tokenId;
        address seller;
        uint minValue; 
    }

    /// @dev The main Bid struct for auctioning
    struct Bid {
        bool hasBid;
        uint tokenId;
        address bidder;
        uint value;
    }

    /// @dev A mapping of lands that are offered for sale at a specific minimum value
    mapping (uint => Offer) public landIdToOfferForSale;

    /// @dev A mapping of the landId to its highest bid
    mapping (uint => Bid) public landIdToBids;

    /// @dev A mapping of address to their pending withdrawal
    mapping (address => uint) public addressToPendingWithdrawal;

    /*** ERC165 ***/

    /// @notice Checks for interface support
    /// @param interfaceId The interfaceId bytes
    /// @return bool, true or false for the support
    function supportsInterface(bytes4 interfaceId) public override pure returns (bool) {
        return interfaceId == InterfaceSignature_MarsGenesisAuction;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Full.sol";
import "./MarsGenesisAuction.sol";
import "./MarsGenesisWallet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title MarsGenesis main ERC721 contract
/// @author Mario Eguiluz
/// @notice Encapsulates the ERC721 methods and main features of MarsGenesis
contract MarsGenesisCore is ERC721Full {

    using Counters for Counters.Counter;

    /// @dev Maximum number of public minted lands
    uint16 private constant MAX_LANDS = 10000;

    /// @dev Maximum number of promotinal lands
    uint16 private constant MAX_PROMO_LANDS = 100;

    /// @dev Interface for auction contract
    bytes4 private constant InterfaceSignature_MarsGenesisAuction =
            bytes4(keccak256('landIdIsForSale(uint256 tokenId)')) ^
            bytes4(keccak256('landNoLongerForSale(uint256)'));

    Counters.Counter private _promoTokenIdTracker;
    Counters.Counter private _tokenIdTracker;

    /// @dev Address of the deployer account
    address private _deployerAddress;

    /// @dev Auction contract address
    MarsGenesisAuction public auctionContract;

    /// @dev Auction contract address
    MarsGenesisWallet private _walletContract;
    

    /*** EVENTS ***/

    /// @dev The Discovery event is fired whenever a new land comes into existence.
    event Discovery(address _owner, uint256 _tokenId, string _tokenURI, uint256 _cardId);
    
    
    /*** LANDS ***/

    /// @dev The main Land struct.
    struct Land {      
        string topLeftLatLong;
        string bottomRightLatLong;
        string metadataURI;
    }

    /// @dev An array containing the Land struct for all lands in existence. The ID
    ///  of each land is actually an index into this array.
    Land[] private _lands;

    /// @dev A mapping to check if certain lat#lng exists.
    ///  Used internally when minting a new land to avoid duplicates
    mapping (string => bool) private _coordinatesExists;
    
    /// @dev A mapping to keep track of token media hashes used
    mapping(string => uint8) hashes;
    
    /*** INIT ***/

    /// @notice Inits the main MarsGenesis contract ERC721 compatible
    /// @dev Contract starts paused. An admin needs to unpause to allow any transfer of lands
    constructor(address payable _walletAddress) ERC721Full("MarsGenesis", "MARS") {
        _deployerAddress = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _walletContract = MarsGenesisWallet(_walletAddress);

        pause();
    }

    /*** EXTERNAL ***/

    /// @notice Mints a new land
    /// @dev The method includes a signature that was provided by the MarsGenesis backend, to ensure data integrity
    /// @param isPromo Flag that indicates if the land is created for a promotion (callable only by contract admins)
    /// @param topLeftLatLong The lat long pair of the top left corner of the rectangle that defines a land
    /// @param bottomRightLatLong The lat long pair of the bottom right corner of the rectangle that defines a land
    /// @param signature The signature provided by the backend to ensure data integrity
    /// @param ipfsHash The hash on the IPFS of this land card
    /// @param metadataURI The URI of the IPFS where the metadata of this land card is recorded
    /// @param cardId The ID of this card on the MarsGenesis backend, for internal use (dont confuse it with tokenId, the one in the backend)
    /// @return uint, the tokenId of the minted land
    function mintLand(bool isPromo, string memory topLeftLatLong, string memory bottomRightLatLong, bytes memory signature, string memory ipfsHash, string memory metadataURI, uint cardId, address promoOwner) external payable returns (uint) {
        if (isPromo == true) {
            require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
            require(hashes[ipfsHash] != 1, "HASH_EXISTS");
            require(_promoTokenIdTracker.current() < MAX_PROMO_LANDS, "LIMIT_REACHED");
            _promoTokenIdTracker.increment();
        } else {
            require(msg.value >= _currentPrice(), "PAYMENT_TOO_LOW");
            require(hashes[ipfsHash] != 1, "HASH_EXISTS");
            bytes32 hash = keccak256(abi.encodePacked(topLeftLatLong, bottomRightLatLong, address(this), cardId));
            address signer = _recoverSigner(hash, signature);
            require(signer == _deployerAddress, "INVALID_SIGNATURE");
        }
        address landOwner;
        if (isPromo == true) {
            landOwner = promoOwner;
        } else {
            landOwner = _msgSender();
        }

        uint newTokenId = _mintLand(landOwner, topLeftLatLong, bottomRightLatLong, ipfsHash, metadataURI, cardId);
        return newTokenId;
    }

    /// @notice Sets a land for sale
    /// @dev Gets approval for the contract to do so
    /// @param tokenId The id of the land
    /// @param minSalePriceInWei The minimum price for the sale, in Wei
    function offerLandForSale(uint tokenId, uint minSalePriceInWei) external {
        approve(address(auctionContract), tokenId);
        auctionContract.offerLandForSale(tokenId, minSalePriceInWei);
    }

    /// @notice Accepts a bid for a land
    /// @dev Gets approval for the contract to do so
    /// @param tokenId The id of the land
    /// @param minPrice The minimum accepted price, in Wei
    function acceptBidForLand(uint tokenId, uint minPrice) external {
        approve(address(auctionContract), tokenId);
        auctionContract.acceptBidForLand(tokenId, minPrice);
    }

    /// @notice Retrieves the tokenURI for a given land
    /// @param tokenId The id of the land
    /// @return string The land's metadata URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
        return _lands[tokenId].metadataURI;
    }

    /// Owner methods

    /// @notice Sends free balance to the main wallet 
    /// @dev Only callable by the deployer
    function sendBalanceToWallet() external { 
        require(msg.sender == _deployerAddress, "INVALID_ROLE");
        require(address(this).balance > 0, "No Balance to send");
        
        (bool success,) = address(_walletContract).call{value: address(this).balance}("");
        require(success);
    }

    /// @notice Updates the auction contract address
    /// @param _address The address of the auction contract
    /// @dev Only callable by admin
    function setAuctionAddress(address _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
        
        MarsGenesisAuction candidateContract = MarsGenesisAuction(_address);
        require(candidateContract.supportsInterface(InterfaceSignature_MarsGenesisAuction), "NOT_SUPPORTED");

        auctionContract = candidateContract;
    }

    /// @notice Updates the wallet contract address
    /// @param _address The address of the wallet contract
    /// @dev Only callable by admin
    function setWalletAddress(address payable _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
        _walletContract = MarsGenesisWallet(_address);
    }


    /// @notice Returns the URI of the contract metadata
    /// @return URI of contract metadata
    function contractURI() public pure returns (string memory) {
        return "https://marsgenesis-web3.herokuapp.com/metadata/MarsGenesis.json";
    }

    /*** INTERNAL ***/

    function _mintLand(address to, string memory topLeftLatLong, string memory bottomRightLatLong, string memory ipfsHash, string memory metadataURI, uint cardId) private returns (uint) {
        require(_tokenIdTracker.current() < MAX_LANDS, "MAX_LANDS_REACHED");

        string memory coordinatesString = string(abi.encodePacked(topLeftLatLong, "#", bottomRightLatLong));
        require(_coordinatesExists[coordinatesString] != true, "COORDINATES_EXISTS");

        uint newLandId = _tokenIdTracker.current();
        Land memory newLand = Land({topLeftLatLong: topLeftLatLong, bottomRightLatLong: bottomRightLatLong, metadataURI: metadataURI});
        _lands.push(newLand);

        _mint(to, newLandId);

        _tokenIdTracker.increment();
        _coordinatesExists[coordinatesString] = true;
        hashes[ipfsHash] = 1;

        emit Discovery(to, newLandId, tokenURI(newLandId), cardId);

        return newLandId;
    }

    function _currentPrice() private view returns (uint256) {
      return (totalSupply() / uint256(100)) * 0.05 ether;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Full) {
      super._beforeTokenTransfer(from, to, tokenId);

      require(address(auctionContract) != address(0), "ACTION_ADDRESS_NOT_SET");
      if(auctionContract.landIdIsForSale(tokenId)) {
          auctionContract.landNoLongerForSale(tokenId);
      }
    }

    /// Signing helpers

    function _recoverSigner(bytes32 _message, bytes memory _sig) private pure returns (address) {
       uint8 v;
       bytes32 r;
       bytes32 s;

       (v, r, s) = _splitSignature(_sig);
       return ecrecover(_message, v, r, s);
    }

    function _splitSignature(bytes memory _sig) private pure returns (uint8, bytes32, bytes32) {
        require(_sig.length == 65);
        
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
        return (v, r, s);
    }
}

///// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./MarsGenesisCore.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";


/// @title MarsGenesis wallet contract
/// @author Mario Eguiluz
/// @dev Equity values are 0 to 10000 (representing 0 to 100 with decimals). So an equity of 3000 means 30%
/// @notice Encapsulates the wallet and cap table management
contract MarsGenesisWallet is AccessControlEnumerable {

    /// @dev Address of the deployer account
    address private _deployerAddress;

    
    /*** CAP TABLE ***/

    address[] private _founders;
    mapping(address => uint) public founderToEquity;
    mapping(address => FounderAuthorization[]) private _addressToFounderAuthorization;

    /// @dev A mapping of cxo address to their pending withdrawal
    mapping (address => uint) public addressToPendingWithdrawal;
    
    /// @dev The max shares being 100 represented by 10000 (to accept decimal positions)
    uint private constant TOTAL_CAP = 10000;


    struct FounderAuthorization {      
        address founder;
        uint equity;
        bool approved;
        bool isRemoval;
    }


    /*** INIT ***/
    /// @notice Inits the wallet
    /// @dev defines a initial cap table with specific equity per founder. Equity values 0 - 10000 representing 0-100% equity
    /// @param cxo1 founder 1     
    /// @param cxo2 founder 2
    /// @param cxo3 founder 3
    /// @param cdo1 founder 4
    /// @param cdo2 founder 5
    /// @param cdo3 founder 6
    constructor (address cxo1, address cxo2, address cxo3, address cdo1, address cdo2, address cdo3) {
        _deployerAddress = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Initial cap table
        createInitialFounder(cxo1, 3000);
        createInitialFounder(cxo2, 3000);
        createInitialFounder(cxo3, 3000);
        createInitialFounder(cdo1, 500);
        createInitialFounder(cdo2, 300);
        createInitialFounder(cdo3, 200);
    }

    /// @notice Inits the a initial founder.
    /// @dev Only callable once on contract construction
    /// @param founderAddress The address of a initial founder 
    /// @param equity The equity of the initial founder. Equity values 0 - 10000 representing 0-100% equity
    function createInitialFounder(address founderAddress, uint equity) private {
        require(msg.sender == _deployerAddress, "ONLY_DEPLOYER");
        require(equity <= TOTAL_CAP, "INVALID EQUITY (0-10000)");

        _founders.push(founderAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, founderAddress);
        founderToEquity[founderAddress] = equity;
    }


    /*** PUBLIC ***/

    /// @notice Wallet should receive ether from MarsGenesisCore and MarsGenesisAuction
    /// @dev Ether received is splitted by equity among wallet founders
    receive() external payable {
        require(msg.value > 0, "INVALID_AMOUNT");
        _updatePendingWithdrawals(msg.value);
    }

    function authorize(bool approved, uint equity, address who) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
        require(equity <= TOTAL_CAP, "INVALID EQUITY (0-10000)");
        require(equity >= 0, "INVALID EQUITY (0-10000)");

        FounderAuthorization[] storage auths = _addressToFounderAuthorization[who];
        bool exists = false;
        for (uint i = 0; i < auths.length; i++) {
            if (auths[i].founder == msg.sender) {
                exists = true;
                auths[i].equity = equity;
                auths[i].approved = approved;
                auths[i].isRemoval = false;
            }
        }

        if (!exists) {
            auths.push(FounderAuthorization({founder: msg.sender, equity: equity, approved: approved, isRemoval: false}));
        }
    }

    function revoke(bool approved, address who) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");

        FounderAuthorization[] storage auths = _addressToFounderAuthorization[who];
        bool exists = false;
        for (uint i = 0; i < auths.length; i++) {
            if (auths[i].founder == msg.sender) {
                exists = true;
                auths[i].equity = 0;
                auths[i].approved = approved;
                auths[i].isRemoval = true;
            }
        }

        if (!exists) {
            auths.push(FounderAuthorization({founder: msg.sender, equity: 0, approved: approved, isRemoval: true}));
        }
    }

    function updateCapTable(address who, uint equity, bool isRemoval) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
        require(equity <= TOTAL_CAP, "INVALID EQUITY (0-10000)");
        require(equity >= 0, "INVALID EQUITY (0-10000)");

        FounderAuthorization[] storage auths = _addressToFounderAuthorization[who];
        uint equityYes = 0;

        for (uint i = 0; i < auths.length; i++) {
            if (equity == auths[i].equity && auths[i].approved == true && isRemoval == auths[i].isRemoval) {
                equityYes += founderToEquity[auths[i].founder];
            } 
        }

        if (equityYes >= 7000) {
            if (isRemoval) {
                _removeFounder(who);
            } else {
                _addFounder(who, equity);
            }  
            delete _addressToFounderAuthorization[who];
        } 
    }

    function withdraw() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
        
        uint amount = addressToPendingWithdrawal[_msgSender()];
        addressToPendingWithdrawal[_msgSender()] = 0;
        
        payable(_msgSender()).transfer(amount);
    }

    /*** PRIVATE ***/

    function _addFounder(address who, uint equity) private {
        require(!_founderExists(who), "FOUNDER ALREADY EXISTS");

        for (uint i = 0; i < _founders.length; i++) {
            founderToEquity[_founders[i]] = founderToEquity[_founders[i]] * (TOTAL_CAP - equity) / TOTAL_CAP;
        }

        _founders.push(who);
        grantRole(DEFAULT_ADMIN_ROLE, who);
        founderToEquity[who] = equity;
    }

    function _removeFounder(address who) private {
        require(_founderExists(who), "FOUNDER DOESNT EXIST");

        uint equityToSplit = founderToEquity[who];
        uint indexToRemove;
        for (uint i = 0; i < _founders.length; i++) {
            if (_founders[i] == who) {
                indexToRemove = i;
                founderToEquity[who] = 0;
            } else {
               founderToEquity[_founders[i]] =  TOTAL_CAP * founderToEquity[_founders[i]] / (TOTAL_CAP - equityToSplit);
            }
        }

        delete _founders[indexToRemove];
        revokeRole(DEFAULT_ADMIN_ROLE, who);
    }

    function _founderExists(address who) private view returns(bool) {
        bool exists = false;
        for (uint i = 0; i < _founders.length; i++) {
            if (_founders[i] == who) {
                exists = true;
            }
        }
        return exists;
    }

    function _updatePendingWithdrawals(uint amount) private {
        for (uint i = 0; i < _founders.length; i++) {
            addressToPendingWithdrawal[_founders[i]] = addressToPendingWithdrawal[_founders[i]] + (amount * founderToEquity[_founders[i]] / TOTAL_CAP);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

