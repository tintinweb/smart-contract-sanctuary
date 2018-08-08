pragma solidity ^0.4.23;

/* Controls state and access rights for contract functions
 * @title Operational Control
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 * Inspired and adapted from contract created by OpenZeppelin
 * Ref: https://github.com/OpenZeppelin/zeppelin-solidity/
 */
contract OperationalControl {
    // Facilitates access & control for the game.
    // Roles:
    //  -The Managers (Primary/Secondary): Has universal control of all elements (No ability to withdraw)
    //  -The Banker: The Bank can withdraw funds and adjust fees / prices.
    //  -otherManagers: Contracts that need access to functions for gameplay

    /// @dev Emited when contract is upgraded
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public managerPrimary;
    address public managerSecondary;
    address public bankManager;

    // Contracts that require access for gameplay
    mapping(address => uint8) public otherManagers;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    // @dev Keeps track whether the contract erroredOut. When that is true, most actions are blocked & refund can be claimed
    bool public error = false;

    /// @dev Operation modifiers for limiting access
    modifier onlyManager() {
        require(msg.sender == managerPrimary || msg.sender == managerSecondary);
        _;
    }

    modifier onlyBanker() {
        require(msg.sender == bankManager);
        _;
    }

    modifier onlyOtherManagers() {
        require(otherManagers[msg.sender] == 1);
        _;
    }


    modifier anyOperator() {
        require(
            msg.sender == managerPrimary ||
            msg.sender == managerSecondary ||
            msg.sender == bankManager ||
            otherManagers[msg.sender] == 1
        );
        _;
    }

    /// @dev Assigns a new address to act as the Other Manager. (State = 1 is active, 0 is disabled)
    function setOtherManager(address _newOp, uint8 _state) external onlyManager {
        require(_newOp != address(0));

        otherManagers[_newOp] = _state;
    }

    /// @dev Assigns a new address to act as the Primary Manager.
    function setPrimaryManager(address _newGM) external onlyManager {
        require(_newGM != address(0));

        managerPrimary = _newGM;
    }

    /// @dev Assigns a new address to act as the Secondary Manager.
    function setSecondaryManager(address _newGM) external onlyManager {
        require(_newGM != address(0));

        managerSecondary = _newGM;
    }

    /// @dev Assigns a new address to act as the Banker.
    function setBanker(address _newBK) external onlyManager {
        require(_newBK != address(0));

        bankManager = _newBK;
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

    /// @dev Modifier to allow actions only when the contract has Error
    modifier whenError {
        require(error);
        _;
    }

    /// @dev Called by any Operator role to pause the contract.
    /// Used only if a bug or exploit is discovered (Here to limit losses / damage)
    function pause() external onlyManager whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function unpause() public onlyManager whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function hasError() public onlyManager whenPaused {
        error = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function noError() public onlyManager whenPaused {
        error = false;
    }
}

contract CSCNFTFactory {

   
    /** Public Functions */

    function getAssetDetails(uint256 _assetId) public view returns(
        uint256 assetId,
        uint256 ownersIndex,
        uint256 assetTypeSeqId,
        uint256 assetType,
        uint256 createdTimestamp,
        uint256 isAttached,
        address creator,
        address owner
    );

    function getAssetDetailsURI(uint256 _assetId) public view returns(
        uint256 assetId,
        uint256 ownersIndex,
        uint256 assetTypeSeqId,
        uint256 assetType,
        uint256 createdTimestamp,
        uint256 isAttached,
        address creator,
        address owner,
        string metaUriAddress
    );

    function getAssetRawMeta(uint256 _assetId) public view returns(
        uint256 dataA,
        uint128 dataB
    );

    function getAssetIdItemType(uint256 _assetId) public view returns(
        uint256 assetType
    );

    function getAssetIdTypeSequenceId(uint256 _assetId) public view returns(
        uint256 assetTypeSequenceId
    );
    
    function getIsNFTAttached( uint256 _tokenId) 
    public view returns(
        uint256 isAttached
    );

    function getAssetIdCreator(uint256 _assetId) public view returns(
        address creator
    );
    function getAssetIdOwnerAndOIndex(uint256 _assetId) public view returns(
        address owner,
        uint256 ownerIndex
    );
    function getAssetIdOwnerIndex(uint256 _assetId) public view returns(
        uint256 ownerIndex
    );

    function getAssetIdOwner(uint256 _assetId) public view returns(
        address owner
    );

    function isAssetIdOwnerOrApproved(address requesterAddress, uint256 _assetId) public view returns(
        bool
    );
    /// @param _owner The owner whose ships tokens we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
    ///  expensive (it walks the entire NFT owners array looking for NFT belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens);
    // Get the name of the Asset type
    function getTypeName (uint32 _type) public returns(string);
    function RequestDetachment(
        uint256 _tokenId
    )
        public;
    function AttachAsset(
        uint256 _tokenId
    )
        public;
    function BatchAttachAssets(uint256[10] _ids) public;
    function BatchDetachAssets(uint256[10] _ids) public;
    function RequestDetachmentOnPause (uint256 _tokenId) public;
    function burnAsset(uint256 _assetID) public;
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);
    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId)
        public view returns (address _operator);
    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator)
        public view returns (bool);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        public;

}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
contract ERC721Receiver {
    /**
    * @dev Magic value to be returned upon successful reception of an NFT
    *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
    *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    */
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

    /**
    * @notice Handle the receipt of an NFT
    * @dev The ERC721 smart contract calls this function on the recipient
    *  after a `safetransfer`. This function MAY throw to revert and reject the
    *  transfer. This function MUST use 50,000 gas or less. Return of other
    *  than the magic value MUST result in the transaction being reverted.
    *  Note: the contract address is always the message sender.
    * @param _from The sending address
    * @param _tokenId The NFT identifier which is being transfered
    * @param _data Additional data with no specified format
    * @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    */
    function onERC721Received(
        address _from,
        uint256 _tokenId,
        bytes _data
    )
        public
        returns(bytes4);
}
contract ERC721Holder is ERC721Receiver {
    function onERC721Received(address, uint256, bytes) public returns(bytes4) {
        return ERC721_RECEIVED;
    }
}

contract CSCTimeSaleManager is ERC721Holder, OperationalControl {
    //DATATYPES & CONSTANTS
    struct CollectibleSale {
        // Current owner of NFT (ERC721)
        address seller;
        // Price (in wei) at beginning of sale (For Buying)
        uint256 startingPrice;
        // Price (in wei) at end of sale (For Buying)
        uint256 endingPrice;
        // Duration (in seconds) of sale, 2592000 = 30 days
        uint256 duration;
        // Time when sale started
        // NOTE: 0 if this sale has been concluded
        uint64 startedAt;
        // Flag denoting is the Sale still active
        bool isActive;
        // address of the wallet who bought the asset
        address buyer;
        // ERC721 AssetID
        uint256 tokenId;
    }
    struct PastSales {
        uint256[5] sales;
    }

    // CSCNTFAddress
    address public NFTAddress;

    // Map from token to their corresponding sale.
    mapping (uint256 => CollectibleSale) public tokenIdToSale;

    // Count of AssetType Sales
    mapping (uint256 => uint256) public assetTypeSaleCount;

    // Last 5 Prices of AssetType Sales
    mapping (uint256 => PastSales) internal assetTypeSalePrices;

    uint256 public avgSalesToCount = 5;

    // type to sales of type
    mapping(uint256 => uint256[]) public assetTypeSalesTokenId;

    event SaleWinner(address owner, uint256 collectibleId, uint256 buyingPrice);
    event SaleCreated(uint256 tokenID, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint64 startedAt);
    event SaleCancelled(address seller, uint256 collectibleId);

    constructor() public {
        require(msg.sender != address(0));
        paused = true;
        error = false;
        managerPrimary = msg.sender;
        managerSecondary = msg.sender;
        bankManager = msg.sender;
    }

    function  setNFTAddress(address _address) public onlyManager {
        NFTAddress = _address;
    }

    function setAvgSalesCount(uint256 _count) public onlyManager  {
        avgSalesToCount = _count;
    }

    /// @dev Creates and begins a new sale.
    function CreateSale(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint64 _duration, address _seller) public anyOperator {
        _createSale(_tokenId, _startingPrice, _endingPrice, _duration, _seller);
    }

    function BatchCreateSales(uint256[] _tokenIds, uint256 _startingPrice, uint256 _endingPrice, uint64 _duration, address _seller) public anyOperator {
        uint256 _tokenId;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            _tokenId = _tokenIds[i];
            _createSale(_tokenId, _startingPrice, _endingPrice, _duration, _seller);
        }
    }

    function CreateSaleAvgPrice(uint256 _tokenId, uint256 _margin, uint _minPrice, uint256 _endingPrice, uint64 _duration, address _seller) public anyOperator {
        var cscNFT = CSCNFTFactory(NFTAddress);
        uint256 assetType = cscNFT.getAssetIdItemType(_tokenId);
        // Avg Price of last sales
        uint256 salePrice = GetAssetTypeAverageSalePrice(assetType);

        //  0-10,000 is mapped to 0%-100% - will be typically 12000 or 120%
        salePrice = salePrice * _margin / 10000;

        if(salePrice < _minPrice) {
            salePrice = _minPrice;
        } 
       
        _createSale(_tokenId, salePrice, _endingPrice, _duration, _seller);
    }

    function BatchCreateSaleAvgPrice(uint256[] _tokenIds, uint256 _margin, uint _minPrice, uint256 _endingPrice, uint64 _duration, address _seller) public anyOperator {
        var cscNFT = CSCNFTFactory(NFTAddress);
        uint256 assetType;
        uint256 _tokenId;
        uint256 salePrice;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            _tokenId = _tokenIds[i];
            assetType = cscNFT.getAssetIdItemType(_tokenId);
            // Avg Price of last sales
            salePrice = GetAssetTypeAverageSalePrice(assetType);

            //  0-10,000 is mapped to 0%-100% - will be typically 12000 or 120%
            salePrice = salePrice * _margin / 10000;

            if(salePrice < _minPrice) {
                salePrice = _minPrice;
            } 
            
            _tokenId = _tokenIds[i];
            _createSale(_tokenId, salePrice, _endingPrice, _duration, _seller);
        }
    }

    function BatchCancelSales(uint256[] _tokenIds) public anyOperator {
        uint256 _tokenId;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            _tokenId = _tokenIds[i];
            _cancelSale(_tokenId);
        }
    }

    function CancelSale(uint256 _assetId) public anyOperator {
        _cancelSale(_assetId);
    }

    function GetCurrentSalePrice(uint256 _assetId) external view returns(uint256 _price) {
        CollectibleSale memory _sale = tokenIdToSale[_assetId];
        
        return _currentPrice(_sale);
    }

    function GetCurrentTypeSalePrice(uint256 _assetType) external view returns(uint256 _price) {
        CollectibleSale memory _sale = tokenIdToSale[assetTypeSalesTokenId[_assetType][0]];
        return _currentPrice(_sale);
    }

    function GetCurrentTypeDuration(uint256 _assetType) external view returns(uint256 _duration) {
        CollectibleSale memory _sale = tokenIdToSale[assetTypeSalesTokenId[_assetType][0]];
        return  _sale.duration;
    }

    function GetCurrentTypeStartTime(uint256 _assetType) external view returns(uint256 _startedAt) {
        CollectibleSale memory _sale = tokenIdToSale[assetTypeSalesTokenId[_assetType][0]];
        return  _sale.startedAt;
    }

    function GetCurrentTypeSaleItem(uint256 _assetType) external view returns(address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt, uint256 tokenId) {
        CollectibleSale memory _sale = tokenIdToSale[assetTypeSalesTokenId[_assetType][0]];
        return (
            _sale.seller,
            _sale.startingPrice,
            _sale.endingPrice,
            _sale.duration,
            _sale.startedAt,
            _sale.tokenId
        );
    }

    function GetCurrentTypeSaleCount(uint256 _assetType) external view returns(uint256 _count) {
        return assetTypeSalesTokenId[_assetType].length;
    }

    function BuyCurrentTypeOfAsset(uint256 _assetType) external whenNotPaused payable {
        require(msg.sender != address(0));
        require(msg.sender != address(this));

        CollectibleSale memory _sale = tokenIdToSale[assetTypeSalesTokenId[_assetType][0]];
        require(_isOnSale(_sale));

        _buy(_sale.tokenId, msg.sender, msg.value);
    }

    /// @dev BuyNow Function which call the interncal buy function
    /// after doing all the pre-checks required to initiate a buy
    function BuyAsset(uint256 _assetId) external whenNotPaused payable {
        require(msg.sender != address(0));
        require(msg.sender != address(this));
        CollectibleSale memory _sale = tokenIdToSale[_assetId];
        require(_isOnSale(_sale));
        
        //address seller = _sale.seller;

        _buy(_assetId, msg.sender, msg.value);
    }

    function GetAssetTypeAverageSalePrice(uint256 _assetType) public view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < avgSalesToCount; i++) {
            sum += assetTypeSalePrices[_assetType].sales[i];
        }
        return sum / 5;
    }

    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can&#39;t have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive CALL.
    function unpause() public anyOperator whenPaused {
        // Actually unpause the contract.
        super.unpause();
    }

    /// @dev Remove all Ether from the contract, which is the owner&#39;s cuts
    ///  as well as any Ether sent directly to the contract address.
    ///  Always transfers to the NFT (ERC721) contract, but can be called either by
    ///  the owner or the NFT (ERC721) contract.
    function withdrawBalance() public onlyBanker {
        // We are using this boolean method to make sure that even if one fails it will still work
        bankManager.transfer(address(this).balance);
    }

    /// @dev Returns sales info for an CSLCollectibles (ERC721) on sale.
    /// @param _assetId - ID of the token on sale
    function getSale(uint256 _assetId) external view returns (address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt, bool isActive, address buyer, uint256 tokenId) {
        CollectibleSale memory sale = tokenIdToSale[_assetId];
        require(_isOnSale(sale));
        return (
            sale.seller,
            sale.startingPrice,
            sale.endingPrice,
            sale.duration,
            sale.startedAt,
            sale.isActive,
            sale.buyer,
            sale.tokenId
        );
    }


    /** Internal Functions */

    function _createSale(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint64 _duration, address _seller) internal {
        var cscNFT = CSCNFTFactory(NFTAddress);

        require(cscNFT.isAssetIdOwnerOrApproved(this, _tokenId) == true);
        
        CollectibleSale memory onSale = tokenIdToSale[_tokenId];
        require(onSale.isActive == false);

        // Sanity check that no inputs overflow how many bits we&#39;ve allocated
        // to store them in the sale struct.
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        //Transfer ownership if needed
        if(cscNFT.ownerOf(_tokenId) != address(this)) {
            
            require(cscNFT.isApprovedForAll(msg.sender, this) == true);

            cscNFT.safeTransferFrom(cscNFT.ownerOf(_tokenId), this, _tokenId);
        }

        CollectibleSale memory sale = CollectibleSale(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now),
            true,
            address(0),
            uint256(_tokenId)
        );
        _addSale(_tokenId, sale);
    }

    /// @dev Adds an sale to the list of open sales. Also fires the
    ///  SaleCreated event.
    function _addSale(uint256 _assetId, CollectibleSale _sale) internal {
        // Require that all sales have a duration of
        // at least one minute.
        require(_sale.duration >= 1 minutes);
        
        tokenIdToSale[_assetId] = _sale;

        var cscNFT = CSCNFTFactory(NFTAddress);
        uint256 assetType = cscNFT.getAssetIdItemType(_assetId);
        assetTypeSalesTokenId[assetType].push(_assetId);

        SaleCreated(
            uint256(_assetId),
            uint256(_sale.startingPrice),
            uint256(_sale.endingPrice),
            uint256(_sale.duration),
            uint64(_sale.startedAt)
        );
    }

    /// @dev Returns current price of a Collectible (ERC721) on sale. Broken into two
    ///  functions (this one, that computes the duration from the sale
    ///  structure, and the other that does the price computation) so we
    ///  can easily test that the price computation works correctly.
    function _currentPrice(CollectibleSale memory _sale) internal view returns (uint256) {
        uint256 secondsPassed = 0;

        // A bit of insurance against negative values (or wraparound).
        // Probably not necessary (since Ethereum guarnatees that the
        // now variable doesn&#39;t ever go backwards).
        if (now > _sale.startedAt) {
            secondsPassed = now - _sale.startedAt;
        }

        return _computeCurrentPrice(
            _sale.startingPrice,
            _sale.endingPrice,
            _sale.duration,
            secondsPassed
        );
    }

    /// @dev Computes the current price of an sale. Factored out
    ///  from _currentPrice so we can run extensive unit tests.
    ///  When testing, make this function public and turn on
    ///  `Current price computation` test suite.
    function _computeCurrentPrice(uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, uint256 _secondsPassed) internal pure returns (uint256) {
        // NOTE: We don&#39;t use SafeMath (or similar) in this function because
        //  all of our public functions carefully cap the maximum values for
        //  time (at 64-bits) and currency (at 128-bits). _duration is
        //  also known to be non-zero (see the require() statement in
        //  _addSale())
        if (_secondsPassed >= _duration) {
            // We&#39;ve reached the end of the dynamic pricing portion
            // of the sale, just return the end price.
            return _endingPrice;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

            // This multiplication can&#39;t overflow, _secondsPassed will easily fit within
            // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    function _buy(uint256 _assetId, address _buyer, uint256 _price) internal {

        CollectibleSale storage _sale = tokenIdToSale[_assetId];

        // Check that the bid is greater than or equal to the current buyOut price
        uint256 currentPrice = _currentPrice(_sale);

        require(_price >= currentPrice);
        _sale.buyer = _buyer;
        _sale.isActive = false;

        _removeSale(_assetId);

        uint256 bidExcess = _price - currentPrice;
        _buyer.transfer(bidExcess);

        var cscNFT = CSCNFTFactory(NFTAddress);
        uint256 assetType = cscNFT.getAssetIdItemType(_assetId);
        _updateSaleAvgHistory(assetType, _price);
        cscNFT.safeTransferFrom(this, _buyer, _assetId);

        emit SaleWinner(_buyer, _assetId, _price);
    }

    function _cancelSale (uint256 _assetId) internal {
        CollectibleSale storage _sale = tokenIdToSale[_assetId];

        require(_sale.isActive == true);

        address sellerAddress = _sale.seller;

        _removeSale(_assetId);

        var cscNFT = CSCNFTFactory(NFTAddress);

        cscNFT.safeTransferFrom(this, sellerAddress, _assetId);

        emit SaleCancelled(sellerAddress, _assetId);
    }
    
    /// @dev Returns true if the FT (ERC721) is on sale.
    function _isOnSale(CollectibleSale memory _sale) internal view returns (bool) {
        return (_sale.startedAt > 0 && _sale.isActive);
    }

    function _updateSaleAvgHistory(uint256 _assetType, uint256 _price) internal {
        assetTypeSaleCount[_assetType] += 1;
        assetTypeSalePrices[_assetType].sales[assetTypeSaleCount[_assetType] % avgSalesToCount] = _price;
    }

    /// @dev Removes an sale from the list of open sales.
    /// @param _assetId - ID of the token on sale
    function _removeSale(uint256 _assetId) internal {
        delete tokenIdToSale[_assetId];

        var cscNFT = CSCNFTFactory(NFTAddress);
        uint256 assetType = cscNFT.getAssetIdItemType(_assetId);

        bool hasFound = false;
        for (uint i = 0; i < assetTypeSalesTokenId[assetType].length; i++) {
            if ( assetTypeSalesTokenId[assetType][i] == _assetId) {
                hasFound = true;
            }
            if(hasFound == true) {
                if(i+1 < assetTypeSalesTokenId[assetType].length)
                    assetTypeSalesTokenId[assetType][i] = assetTypeSalesTokenId[assetType][i+1];
                else 
                    delete assetTypeSalesTokenId[assetType][i];
            }
        }
        assetTypeSalesTokenId[assetType].length--;
    }

}