/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity ^0.5.0;

/**
 * @title - Crypto Skully
 * ███████╗██╗    ██╗ █████╗ ██████╗    ███████╗██╗  ██╗██╗   ██╗██╗     ██╗     ██╗   ██╗
 * ██╔════╝██║    ██║██╔══██╗██╔══██╗   ██╔════╝██║ ██╔╝██║   ██║██║     ██║     ╚██╗ ██╔╝
 * ███████╗██║ █╗ ██║███████║██████╔╝   ███████╗█████╔╝ ██║   ██║██║     ██║      ╚████╔╝
 * ╚════██║██║███╗██║██╔══██║██╔═══╝    ╚════██║██╔═██╗ ██║   ██║██║     ██║       ╚██╔╝
 * ███████║╚███╔███╔╝██║  ██║██║        ███████║██║  ██╗╚██████╔╝███████╗███████╗   ██║
 * ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝        ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝   ╚═╝
 * ---
 *
 * POWERED BY
 *  __    ___   _     ___  _____  ___     _     ___
 * / /`  | |_) \ \_/ | |_)  | |  / / \   | |\ |  ) )
 * \_\_, |_| \  |_|  |_|    |_|  \_\_/   |_| \| _)_)
 *
 * Game at https://skullys.co/
 **/
 
contract SwapControl {
    // This facet controls access control for CryptoSkullys. There are four roles managed here:
    //
    //     - The Admiral: The Admiral can reassign other roles and change the addresses of our dependent smart
    //         contracts. It is also the only role that can unpause the smart contract. It is initially
    //         set to the address that created the smart contract in the SkullyCore constructor.
    //
    //     - The Pilot: The Pilot can withdraw funds from SkullyCore and its auction contracts.
    //
    //     - The Captain: The Captain can release new minted skullys to auction, and mint promo skullys.
    //
    // It should be noted that these roles are distinct without overlap in their access abilities, the
    // abilities listed for each role above are exhaustive. In particular, while the Admiral can assign any
    // address to any role, the Admiral address itself doesn't have the ability to act in those roles. This
    // restriction is intentional so that we aren't tempted to use the Admiral address frequently out of
    // convenience. The less we use an address, the less likely it is that we somehow compromise the
    // account.

    /// @dev Emitted when contract is upgraded - See README.md for upgrade plan
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address payable public admiralAddress;
    address payable public pilotAddress;
    address payable public captainAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for admiral-only functionality
    modifier onlyAdmiral() {
        require(msg.sender == admiralAddress);
        _;
    }

    /// @dev Access modifier for Pilot-only functionality
    modifier onlyPilot() {
        require(msg.sender == pilotAddress);
        _;
    }

    /// @dev Access modifier for Captain-only functionality
    modifier onlyCaptain() {
        require(msg.sender == captainAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == captainAddress ||
            msg.sender == admiralAddress ||
            msg.sender == pilotAddress);
        _;
    }

    /// @dev Assigns a new address to act as the admiral. Only available to the current admiral.
    /// @param _newAdmiral The address of the new Admiral
    function setAdmiral(address payable _newAdmiral) external onlyAdmiral {
        require(_newAdmiral != address(0));

        admiralAddress = _newAdmiral;
    }

    /// @dev Assigns a new address to act as the pilot. Only available to the current Admiral.
    /// @param _newPilot The address of the new Pilot
    function setPilot(address payable _newPilot) external onlyAdmiral {
        require(_newPilot != address(0));

        pilotAddress = _newPilot;
    }

    /// @dev Assigns a new address to act as the captain. Only available to the current Admiral.
    /// @param _newCaptain The address of the new Captain
    function setCaptain(address payable _newCaptain) external onlyAdmiral {
        require(_newCaptain != address(0));

        captainAddress = _newCaptain;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Admiral, since
    ///  one reason we may pause the contract is when Pilot or Captain accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyAdmiral whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}

interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
contract ERC721 is IERC165 {

    // IERC721
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;

    // IERC721Metadata
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) public view returns (string memory);

    // IERC721Enumerable
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
    
    
    ///-----For ERC721 using transfer() function ---///
    function transfer(address _to, uint256 _tokenId) external;
    
    ///-------------------------------------------///
    
    function addNewCategory(uint256 _id, string calldata _newCategory) external;
    
    function changeCategory(uint256 _id, string calldata _newCategory) external;
    
    function updateSkill(uint256 _skullyId, uint256 _newAttack, uint256 _newDefend) external;
    
    function createPromoSkully(uint256 _skullyId, uint256 _attack, uint256 _defend, uint256 _category, address _owner) external;
    
    function createSaleAuction(uint256 _skullyId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, uint _paymentBy) external;
    
    function createNewSkullyAuction(uint256 _newSkullyId, uint256 _category, uint256 _startingPrice, uint256 _endingPrice) public;

    function createNewSkullysAuction(uint256 _startId, uint256 _endId, uint256 _category, uint256 _startingPrice, uint256 _endingPrice) external;
        
    function createNewSkully(uint256 _newSkullyId, uint256 _category, address _owner) external;
        
    function createNewSkullys(uint256 _startId, uint256 _endId, uint256 _category, address _owner) external;
        
    function setGamePlayAddress(address _gameAddress) external;
}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public;
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ClockAuction {
    function cancelAuction(uint256 _tokenId) external;
}

contract SkullyItems {
    function setDiscount(uint256 _newDiscount) external returns (uint256);
    
    function createNewMainAccessory(string memory name) public;
    
    function createNewAccessory(
        uint256 accessoryType,
        uint256 accessoryId,
        string memory name,
        uint256 attack,
        uint256 defend,
        uint256 po8,
        uint256 eth,
        uint256 po8DailyMultiplier,
        bool mustUnlock) public;
        
    function updateAccessoryInformation(
        uint256 id,
        string calldata newName,
        uint256 newAttack,
        uint256 newDefend,
        uint256 newPO8,
        uint256 newEth,
        uint256 newPO8DailyMultiplier,
        bool newMustUnlock) external returns (bool);
        
    function setAccessoryToSkully(uint256 skullyId, uint256 realAccessoryId) external;
    
    function setGamePlayAddress(address _gameAddress) external;
    
    function setNewRankPrice(uint8 rank, uint256 newPrice) public returns (bool);
    
    function setNewRankFlags(uint8 rank, uint256 newFlags) public returns (bool);
    
    function setExchangeRate(uint256 _newExchangeRate) external returns (uint256);
    
    function createNewBadge(uint256 badgeId, string memory description, uint256 po8) public;
    
    function setPO8OfBadge(uint256 badgeId, uint256 po8) public;
    
    function setClaimBadgeContract(address newAddress) external;
    
    function increaseSkullyExp(uint256 skullyId, uint256 flags) external;
    
    function setBadgeToSkully(uint256 skullyId, uint256 badgeId) external;
}

contract ExchangeERC721 is SwapControl {
    
    /// @dev The ERC-165 interface signature for ERC-721.
    ///  Ref: https://github.com/ethereum/EIPs/issues/165
    ///  Ref: https://github.com/ethereum/EIPs/issues/721
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);
    ERC721 public skullyContract;
    ClockAuction public auctionContract;
    SkullyItems public itemContract;
    
    mapping(uint64 => address) public listERC721;
    uint64 public totalERC721;
    uint64 public plusFlags;
    
    bool public pureSwapState;

	/* @notice This constructor of contract
	 * @param _nftAddress the address of skully core
	 * @param _auctionAdress the address of sale auction
	 * @param _itemAdress the address of skully item
	 * return none
	*/
    constructor(address _nftAddress, address _auctionAdress, address _itemAdress) public {
        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721), "The candidate contract must supports ERC721");
        skullyContract = candidateContract;
        
        auctionContract = ClockAuction(_auctionAdress);
        
        itemContract = SkullyItems(_itemAdress);
        
        listERC721[0] = address(candidateContract);
        totalERC721++;
        
        // the creator of the contract is the initial Admiral
        admiralAddress = msg.sender;

        // the creator of the contract is the initial Pilot
        pilotAddress = msg.sender;

        // the creator of the contract is also the initial Captain
        captainAddress = msg.sender;
        
        pureSwapState = false;
        plusFlags = 1000;
    }
    
    event Swapped(uint256 _skullyId, uint256 _exchangeTokenId, uint64 _typeERC, uint256 _time);
    event PureSwapped(uint256 _skullyId, uint256 _exchangeTokenId, uint64 _typeERC, uint256 _time);
    
	/* @notice This function was invoked when user want to swap their collections with skully
	 * @param skullyId the id of skully that user want to swap
	 * @param exchangeTokenId the id of their collections
	 * @param typeERC the number of erc721 in the list of contract that allow to exchange with 
	 * return none - just emit a result to the network
	*/
    function swap(uint256 skullyId, uint256 exchangeTokenId, uint64 typeERC) public whenNotPaused {
        ERC721(listERC721[typeERC]).transferFrom(msg.sender, address(this), exchangeTokenId);
        // cancel sale auction
        auctionContract.cancelAuction(skullyId);
        
        // set flag
        itemContract.increaseSkullyExp(skullyId, plusFlags);
        
        skullyContract.transferFrom(address(this), msg.sender, skullyId);
        
        emit Swapped(skullyId, exchangeTokenId, typeERC, block.timestamp);
    }
    
	/* @notice This function was invoked when user want to swap their collections with skully
	 * @param skullyId the id of skully that user want to swap
	 * @param exchangeTokenId the id of their collections
	 * @param typeERC the number of erc721 in the list of contract that allow to exchange with 
	 * return none - just emit a result to the network
	*/
    function pureSwap(uint256 skullyId, uint256 exchangeTokenId, uint64 typeERC) public whenNotPaused {
        require(pureSwapState == true);
        ERC721(listERC721[typeERC]).transferFrom(msg.sender, address(this), exchangeTokenId);
        skullyContract.transferFrom(address(this), msg.sender, skullyId);
        
        emit PureSwapped(skullyId, exchangeTokenId, typeERC, block.timestamp);
    }
    
	/* @notice
	 * @param
	 * return
	*/
    function setPureSwapSate(bool _state) public onlyCaptain {
        pureSwapState = _state;
    }
    
	/* @notice
	 * @param
	 * return
	*/
    function setFlags(uint64 _newFlags) public onlyCaptain {
        plusFlags = _newFlags;
    }
	
	///------------------NFT-----------------------///
    event NewNFTAdded(uint64 _id, address _newNFT);
    event NFTDeleted(uint64 _id, address _nftDelete);
    event NFTUpdated(uint64 _id, address _oldAddress, address _newAddress);
    
	/* @notice
	 * @param
	 * return
	*/
    function addNewNFT(address newNFTAddress) public onlyCaptain {
        listERC721[totalERC721] = newNFTAddress;
        emit NewNFTAdded(totalERC721, newNFTAddress);
        totalERC721++;
    }
    
	/* @notice
	 * @param
	 * return
	*/
    function addNewNFTs(address[] memory _newNFTsAddress) public onlyCaptain {
        for(uint i = 0; i < _newNFTsAddress.length; i++)
            addNewNFT(_newNFTsAddress[i]);
    }
    
	/* @notice
	 * @param
	 * return
	*/
    function deleteNFT(uint64 _id) external onlyCaptain {
        emit NFTDeleted(_id, listERC721[_id]);
        listERC721[_id] = address(0);
    }
    
	/* @notice
	 * @param
	 * return
	*/
    function updateNFT(uint64 _id, address updateNFTAddress) external onlyCaptain {
        emit NFTUpdated(_id, listERC721[_id], updateNFTAddress);
        listERC721[_id] = updateNFTAddress;
    }
	
	
    ///-----------------------------------------///
    
	/* @notice
	 * @param
	 * return
	*/
    function transferFromERC721ToCaptainWallet(uint256 tokenId, address erc721Adress) external onlyCaptain {
        ERC721(erc721Adress).transferFrom(address(this), captainAddress, tokenId);
    }
    
	/* @notice
	 * @param
	 * return
	*/
    function transferFromERC721sToCaptainWallet(uint256[] calldata tokenIds, address erc721Adress) external onlyCaptain {
        for(uint256 i = 0; i < tokenIds.length; i++)
            ERC721(erc721Adress).transferFrom(address(this), captainAddress, tokenIds[i]);
    }
    
	/* @notice
	 * @param
	 * return
	*/
    function transferERC721ToCaptainWallet(uint256 tokenId, address erc721Adress) external onlyCaptain {
        ERC721(erc721Adress).transfer(captainAddress, tokenId);
    }
    
	/* @notice
	 * @param
	 * return
	*/
    function transferERC721sToCaptainWallet(uint256[] calldata tokenIds, address erc721Adress) external onlyCaptain {
        for(uint256 i = 0; i < tokenIds.length; i++)
            ERC721(erc721Adress).transfer(captainAddress, tokenIds[i]);
    }
    
	/* @notice
	 * @param
	 * return
	*/
    function transferERC20ToCaptainWallet(address erc20Adress) external onlyCaptain {
        ERC20 token = ERC20(erc20Adress);
        token.transfer(captainAddress, token.balanceOf(address(this)));
    }
    
    // @dev Allows the pilot to capture the balance available to the contract.
    function withdrawBalance() external onlyCaptain {
        uint256 balance = address(this).balance;

        captainAddress.transfer(balance);
    }
    
	// This contract address allow ether transfer in
    function() external payable {}
	
	    
    ///-----------------------------------------///
    function createManySaleAuction(uint256[] calldata _listSkullyId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, uint _paymentBy) external onlyCaptain {
        for(uint i = 0; i < _listSkullyId.length; i++)
            createSaleAuction(_listSkullyId[i], _startingPrice, _endingPrice, _duration, _paymentBy);
    }
    
	
	// Don't care the rest of function below
	// It's belong to captain features
    ///-----------------ERC721------------------------///
    
    function setApprovalForAll(address operator, bool _approved) public onlyCaptain {
        skullyContract.setApprovalForAll(operator, _approved);
    }
    
    function addNewCategory(uint256 _id, string calldata _newCategory) external onlyCaptain {
        skullyContract.addNewCategory(_id, _newCategory);
    }
    
    function changeCategory(uint256 _id, string calldata _newCategory) external onlyCaptain {
        skullyContract.changeCategory(_id, _newCategory);
    }
    
    function updateSkill(uint256 _skullyId, uint256 _newAttack, uint256 _newDefend) external onlyCaptain {
        skullyContract.updateSkill(_skullyId, _newAttack, _newDefend);
    }
    
    function createPromoSkully(uint256 _skullyId, uint256 _attack, uint256 _defend, uint256 _category, address _owner) external onlyCaptain {
        skullyContract.createPromoSkully(_skullyId, _attack, _defend, _category, _owner);
    }
    
    function createSaleAuction(uint256 _skullyId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, uint _paymentBy) public onlyCaptain {
        skullyContract.createSaleAuction(_skullyId, _startingPrice, _endingPrice, _duration, _paymentBy);
    }
    
    function createNewSkullyAuction(uint256 _newSkullyId, uint256 _category, uint256 _startingPrice, uint256 _endingPrice) public onlyCaptain {
        skullyContract.createNewSkullyAuction(_newSkullyId, _category, _startingPrice, _endingPrice);
    }

    function createNewSkullysAuction(uint256 _startId, uint256 _endId, uint256 _category, uint256 _startingPrice, uint256 _endingPrice) external onlyCaptain {
        skullyContract.createNewSkullysAuction(_startId, _endId, _category, _startingPrice, _endingPrice);
    }
        
    function createNewSkully(uint256 _newSkullyId, uint256 _category, address _owner) external onlyCaptain {
        skullyContract.createNewSkully(_newSkullyId, _category, _owner);
    }
        
    function createNewSkullys(uint256 _startId, uint256 _endId, uint256 _category, address _owner) external onlyCaptain {
        skullyContract.createNewSkullys(_startId, _endId, _category, _owner);
    }
        
    function setGamePlayAddress(address _gameAddress) external onlyCaptain {
        skullyContract.setGamePlayAddress(_gameAddress);
    }
    
    ///-----------------ITEMS------------------------///
    
    function setDiscount(uint256 _newDiscount) external onlyCaptain returns (uint256) {
        itemContract.setDiscount(_newDiscount);
    }
    
    function createNewMainAccessory(string memory name) public onlyCaptain {
        itemContract.createNewMainAccessory(name);
    }
    
    function createNewAccessory(
        uint256 accessoryType,
        uint256 accessoryId,
        string memory name,
        uint256 attack,
        uint256 defend,
        uint256 po8,
        uint256 eth,
        uint256 po8DailyMultiplier,
        bool mustUnlock) public onlyCaptain {
        itemContract.createNewAccessory(accessoryType, accessoryId, name, attack, defend, po8, eth, po8DailyMultiplier, mustUnlock);
        }
        
    function updateAccessoryInformation(
        uint256 id,
        string calldata newName,
        uint256 newAttack,
        uint256 newDefend,
        uint256 newPO8,
        uint256 newEth,
        uint256 newPO8DailyMultiplier,
        bool newMustUnlock) external onlyCaptain returns (bool) {
        itemContract.updateAccessoryInformation(id, newName, newAttack, newDefend, newPO8, newEth, newPO8DailyMultiplier, newMustUnlock);
        }
        
    function setAccessoryToSkully(uint256 skullyId, uint256 realAccessoryId) external onlyCaptain {
        itemContract.setAccessoryToSkully(skullyId, realAccessoryId);
    }
    
    function setItemGamePlayAddress(address _gameAddress) external onlyCaptain {
        itemContract.setGamePlayAddress(_gameAddress);
    }
    
    function setNewRankPrice(uint8 rank, uint256 newPrice) public onlyCaptain returns (bool) {
        itemContract.setNewRankPrice(rank, newPrice);
    }
    
    function setNewRankFlags(uint8 rank, uint256 newFlags) public  onlyCaptain returns (bool) {
        itemContract.setNewRankFlags(rank, newFlags);
    }
    
    function setExchangeRate(uint256 _newExchangeRate) external onlyCaptain returns (uint256) {
        itemContract.setExchangeRate(_newExchangeRate);
    }
    
    function createNewBadge(uint256 badgeId, string memory description, uint256 po8) public onlyCaptain {
        itemContract.createNewBadge(badgeId, description, po8);
    }
    
    function setPO8OfBadge(uint256 badgeId, uint256 po8) public onlyCaptain {
        itemContract.setPO8OfBadge(badgeId, po8);
    }
    
    function setClaimBadgeContract(address newAddress) external onlyCaptain {
        itemContract.setClaimBadgeContract(newAddress);
    }
    
    function increaseSkullyExp(uint256 skullyId, uint256 flags) external onlyCaptain {
        itemContract.increaseSkullyExp(skullyId, flags);
    }
    
    function setBadgeToSkully(uint256 skullyId, uint256 badgeId) external onlyCaptain {
        itemContract.setBadgeToSkully(skullyId, badgeId);
    }
    
    ///-------------------AUCTION----------------------///
    
    function cancelAuction(uint256 _tokenId) public onlyCaptain {
        auctionContract.cancelAuction(_tokenId);
    }
    
    function cancelManyAuction(uint256[] calldata _listTokenId) external onlyCaptain {
        for(uint i = 0; i < _listTokenId.length; i++)
            cancelAuction(_listTokenId[i]);
    }
}