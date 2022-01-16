// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
/// @title Clock auction for non-fungible tokens.
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../core/interface/IDinolandNFT.sol";

contract DinoMarketplaceUpgradeable is
    Pausable,
    Initializable,
    ReentrancyGuard
{
    /*** EVENTS ***/

    event DinoSpawned(uint256 _id, uint256 _genes);

    event AuctionCreated(
        uint256 indexed _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address indexed _seller
    );

    event AuctionSuccessful(
        uint256 indexed _tokenId,
        uint256 _totalPrice,
        address indexed _winner
    );

    event EggBought(
        uint256 indexed _eggGenes,
        uint256 indexed _eggAmount,
        address indexed _owner
    );

    event EggCreated(uint256 eggId, uint256 genes);

    event AuctionCancelled(uint256 indexed _tokenId);

    event MarketManagerChanged(address _newMarketManager);

    event AdminChanged(address _adminAddress, bool _isAdmin);

    event TokenAddressChanged(address _newTokenAddress);

    event NftAddressChanged(address _newNftAddress);

    /*** DATA TYPES ***/
    using SafeMath for uint256;
    /// @dev Represents an egg
    struct Egg {
        /// The genes code of this egg
        uint256 genes;
        /// Current owner of this egg
        address owner;
        /// Egg borned at (unix timestamp)
        uint256 createdAt;
        /// Egg ready hatch at (unix timestamp)
        uint256 readyHatchAt;
        /// Egg ready hatch at block (block number)
        uint256 readyAtBlock;
        /// Egg is still available or not
        bool isAvailable;
    }

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in wei) at beginning of auction
        uint128 startingPrice;
        // Price (in wei) at end of auction
        uint128 endingPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;
    }

    /*** STORAGES ***/

    uint256 public blockTime;
    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;
    //DNL contract Address
    address public tokenAddress;
    //DINO contract address
    address public nftAddress;
    //MarketManager address
    address public marketManagerAddress;
    //Admins list
    mapping(address => bool) public admins;
    //Black list
    mapping(address => bool) public blackList;
    uint256 public defaultEggPrice;
    uint256 public incubationTime;
    uint256 public skipHatchCooldownPrice;
    mapping(uint256 => uint256) public totalSellingEggByGenes;
    mapping(uint256 => uint256) public eggPriceByGenes;
    mapping(address => uint256[]) public userOwnedEggs;

    Egg[] public eggs;

    // Map from token ID to their corresponding auction.
    mapping(address => mapping(uint256 => Auction)) public auctions;

    /*** METHODS***/

    /// @dev A method that be called by proxy to init storage value of the contract
    function initialize() public initializer {
        marketManagerAddress = msg.sender;
        admins[msg.sender] = true;
        ownerCut = 500;

        /// Set default egg price is 3000 DNL
        defaultEggPrice = 3000 * 1e18;
        /// Set default incubatin period is 6 hours
        incubationTime = 6 hours;
        /// Set default skip incubation time is 500 DNL
        skipHatchCooldownPrice = 500 * 1e18;
        // Set default block time is 3 seconds
        blockTime = 3;
        emit MarketManagerChanged(marketManagerAddress);
        emit AdminChanged(msg.sender, true);
    }

    // Modifiers to check that inputs can be safely stored with a certain
    // number of bits. We use constants and multiple modifiers to save gas.
    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= 18446744073709551615);
        _;
    }

    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455);
        _;
    }
    /// @dev The modifier that restrict admin permission
    modifier onlyAdmin() {
        require(admins[msg.sender], "need_admin_permission");
        _;
    }

    /// @dev The modifier that restrict egg owner permission by egg id
    modifier onlyEggOwner(uint256 _eggId) {
        require(eggs[_eggId].owner == msg.sender, "need_egg_owner_permission");
        _;
    }

    /// @dev The modifier that restrict market manager permission
    modifier onlyMarketManger() {
        require(
            msg.sender == marketManagerAddress,
            "need_market_manager_permission"
        );
        _;
    }

    /// @dev The modifer that prevent blacklist user
    modifier onlyNotBlackListed(address _user) {
        require(!blackList[_user], "user_is_black_list");
        _;
    }

    function pause() public onlyMarketManger {
        _pause();
    }

    function unpause() public onlyMarketManger {
        _unpause();
    }

    /// @dev Set new market manager address
    /// @param _newMarketManagerAddress - Address of new admin.
    function setMarketManagerAddress(address _newMarketManagerAddress)
        external
        onlyMarketManger
    {
        require(
            _newMarketManagerAddress != address(0),
            "market_manager_address_cannot_be_0"
        );
        marketManagerAddress = _newMarketManagerAddress;
        emit MarketManagerChanged(_newMarketManagerAddress);
    }

    /// @dev Set black list
    /// @param _blackListAddress - Address of black list.
    /// @param _isBlackList - True if address is black list, false if not.
    function setBlackList(address _blackListAddress, bool _isBlackList) external onlyMarketManger {
        blackList[_blackListAddress] = _isBlackList;
    }

    /// @dev Set new admin address
    /// @param _adminAddress - Address of admin.
    /// @param _isAdmin - Is admin or not.
    function setAdmin(address _adminAddress, bool _isAdmin)
        external
        onlyMarketManger
    {
        require(
            _adminAddress != address(0),
            "admin_address_cannot_be_0"
        );
        admins[_adminAddress] = _isAdmin;
        emit AdminChanged(_adminAddress, _isAdmin);
    }

    /// @dev Set new token address
    /// @param _newTokenAddress - Address of new erc20 token.
    function setTokenAddress(address _newTokenAddress)
        external
        onlyMarketManger
    {
        require(
            _newTokenAddress != address(0),
            "token_address_cannot_be_0"
        );
        tokenAddress = _newTokenAddress;
        emit TokenAddressChanged(_newTokenAddress);
    }

    /// @dev Set new nft address
    /// @param _newNftAddress - Address of new erc721 token.
    function setNftAddress(address _newNftAddress) external onlyMarketManger {
        require(
            _newNftAddress != address(0),
            "nft_address_cannot_be_0"
        );
        nftAddress = _newNftAddress;
        emit NftAddressChanged(_newNftAddress);
    }

    /// @dev Set new egg price
    /// @param _newEggPrice - Set new value for egg price
    function setDefaultEggPrice(uint256 _newEggPrice) external onlyAdmin {
        defaultEggPrice = _newEggPrice;
    }

    /// @dev Set egg price by genes
    /// @param _eggGenes - Egg genes.
    /// @param _eggPrice - Price of this egg genes.
    function setEggPriceByGenes(uint256 _eggGenes, uint256 _eggPrice)
        external
        onlyAdmin
    {
        eggPriceByGenes[_eggGenes] = _eggPrice;
    }

    function setIncubationTime(uint256 _incubationTime) external onlyAdmin {
        incubationTime = _incubationTime;
    }

    function setBlockTime(uint256 _blockTime) external onlyAdmin {
        blockTime = _blockTime;
    }

    /// @dev Set total egg by genes of market
    /// @param _eggGenes - Dino egg genes
    /// @param _total - Total egg by genes
    function setTotalSellingEggByGenes(uint256 _eggGenes, uint256 _total)
        external
        onlyAdmin
    {
        totalSellingEggByGenes[_eggGenes] = _total;
    }

    /// @dev Set skip hatching price
    /// @param _newSkipHatchCooldownPrice - New skip cooldown price
    function setSkipHatchCooldownPrice(uint256 _newSkipHatchCooldownPrice)
        external
        onlyAdmin
    {
        skipHatchCooldownPrice = _newSkipHatchCooldownPrice;
    }

    /// @dev Get total selling egg by the input genes
    /// @param _eggGenes - Genes of the egg type that you want to get total egg
    function getTotalSellingEggByGenes(uint256 _eggGenes)
        external
        view
        returns (uint256)
    {
        return totalSellingEggByGenes[_eggGenes];
    }

    /// @dev Get egg price by egg genes
    /// @param _eggGenes - Genes of the egg type that you want to get price
    function getEggPriceByGenes(uint256 _eggGenes)
        external
        view
        returns (uint256)
    {
        uint256 eggPrice = eggPriceByGenes[_eggGenes] == 0
            ? defaultEggPrice
            : eggPriceByGenes[_eggGenes];
        return eggPrice;
    }

    /// @dev Get eggs list by owner address
    /// @param _owner Owner address

    function getEggsByOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return userOwnedEggs[_owner];
    }

    ///@dev Get total existing egg on the market
    function getTotalEgg() external view returns (uint256) {
        return eggs.length;
    }

    ///@dev Get specific detail of an egg by egg id
    /// _eggId - The Egg Id
    function getEggDetail(uint256 _eggId)
        external
        view
        returns (
            uint256 genes,
            address owner,
            uint256 createdAt,
            uint256 readyHatchAt,
            uint256 readyAtBlock,
            bool isAvailable
        )
    {
        Egg storage egg = eggs[_eggId];
        return (
            egg.genes,
            egg.owner,
            egg.createdAt,
            egg.readyHatchAt,
            egg.readyAtBlock,
            egg.isAvailable
        );
    }

    ///@dev An external method that allow Admin to update the egg status
    /// @param _eggId - The Egg Id
    /// @param _isAvailable - Is Available or not, set to false if you want to disable this egg

    function updateEggStatus(uint256 _eggId, bool _isAvailable)
        external
        onlyAdmin
        returns (uint256)
    {
        require(_eggId <= eggs.length - 1, "egg_not_exist");
        eggs[_eggId].isAvailable = _isAvailable;
        return _eggId;
    }

    /// @dev An external method that allow admin to disable an egg
    /// @param _eggId - The id of the egg that you want to disable
    function disableEgg(uint256 _eggId) external onlyAdmin {
        Egg storage egg = eggs[_eggId];
        require(_eggId <= eggs.length - 1, "egg_not_exist");
        require(block.timestamp > egg.readyHatchAt, "Egg not ready");
        require(egg.isAvailable == true, "Egg not availble");
        eggs[_eggId].isAvailable = false;
    }

    /// @dev Get current balance holding in market
    function getMarketManagerBalance() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /// @dev Skip egg cooldown by paying some DNL token
    /// @param _eggId - Id of the egg that you want to skip incubation
    function skipEggCooldown(uint256 _eggId) external onlyEggOwner(_eggId) {
        Egg storage egg = eggs[_eggId];
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            skipHatchCooldownPrice
        );
        egg.readyHatchAt = block.timestamp;
        egg.readyAtBlock = block.number;
    }

    /// @dev Buy egg by genes logic, transfer DNL from buyer address to market
    /// @param _eggGenes - Current buying egg genes
    /// @param _eggAmount - Amount of egg to buy
    function buyEgg(uint256 _eggGenes, uint256 _eggAmount)
        external
        nonReentrant
    {
        require(
            totalSellingEggByGenes[_eggGenes] >= _eggAmount,
            "egg_sold_out"
        );
        if (eggPriceByGenes[_eggGenes] > 0) {
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _eggAmount.mul(eggPriceByGenes[_eggGenes])
            );
        } else {
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _eggAmount.mul(defaultEggPrice)
            );
        }

        totalSellingEggByGenes[_eggGenes] = totalSellingEggByGenes[_eggGenes]
            .sub(_eggAmount);
        //Create new egg
        uint256 readyHatchAt = block.timestamp + incubationTime;
        for (uint256 i = 0; i < _eggAmount; i++) {
            _createEgg(_eggGenes, readyHatchAt, msg.sender);
        }

        emit EggBought(_eggGenes, _eggAmount, msg.sender);
    }

    /// @dev Create egg
    function _createEgg(
        uint256 _eggGenes,
        uint256 _readyHatchAt,
        address _ownerAddress
    ) private returns (uint256) {
        uint256 targetBlock = block.number +
            (_readyHatchAt - block.timestamp) /
            blockTime;
        Egg memory newEgg = Egg(
            _eggGenes,
            _ownerAddress,
            block.timestamp,
            _readyHatchAt,
            targetBlock,
            true
        );
        eggs.push(newEgg);
        uint256 _eggId = eggs.length - 1;
        userOwnedEggs[_ownerAddress].push(_eggId);
        emit EggCreated(_eggId, _eggGenes);
        return _eggId;
    }

    /// @dev Create egg and assign to an address
    function createEgg(
        uint256 _eggGenes,
        uint256 _readyHatchAt,
        address _owner
    ) external onlyAdmin returns (uint256) {
        uint256 eggId = _createEgg(_eggGenes, _readyHatchAt, _owner);
        return eggId;
    }

    /// @dev Withdraw balance of market to specific address
    /// @param _to - Receiver address
    /// @param _amount - Token amount
    function withdrawBalance(address _to, uint256 _amount)
        external
        onlyMarketManger
        returns (bool)
    {
        IERC20(tokenAddress).transfer(_to, _amount);
        return true;
    }

    /// @dev Withdraw all balance of market to specific address
    /// @param _to - Receiver address
    function withdrawAllBalance(address _to)
        external
        onlyMarketManger
        returns (bool)
    {
        uint256 marketManagerBalance = getMarketManagerBalance();
        return IERC20(tokenAddress).transfer(_to, marketManagerBalance);
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
        external
        view
        returns (
            address seller,
            uint256 startingPrice,
            uint256 endingPrice,
            uint256 duration,
            uint256 startedAt
        )
    {
        Auction storage _auction = auctions[nftAddress][_tokenId];
        require(_isOnAuction(_auction));
        return (
            _auction.seller,
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            _auction.startedAt
        );
    }

    /// @dev Returns the current price of an auction.
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPrice(uint256 _tokenId) external view returns (uint256) {
        Auction storage _auction = auctions[nftAddress][_tokenId];
        require(_isOnAuction(_auction));
        return _getCurrentPrice(_auction);
    }

    /// @dev Creates and begins a new auction.
    ///  the Nonfungible Interface.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    /// @param _startingPrice - Price of item (in wei) at beginning of auction.
    /// @param _endingPrice - Price of item (in wei) at end of auction.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
        nonReentrant
        onlyNotBlackListed(msg.sender)
        canBeStoredWith128Bits(_startingPrice)
        canBeStoredWith128Bits(_endingPrice)
        canBeStoredWith64Bits(_duration)
    {
        address _seller = msg.sender;
        require(_owns(_seller, _tokenId), "you_dont_have_permission");
        _escrow(nftAddress, _seller, _tokenId);
        Auction memory _auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(block.timestamp)
        );
        _addAuction(nftAddress, _tokenId, _auction, _seller);
    }

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    ///  the Nonfungible Interface.
    /// @param _tokenId - ID of token to bid on.
    function bid(uint256 _tokenId, uint256 _amount)
        external
        onlyNotBlackListed(msg.sender)
        whenNotPaused
        nonReentrant
    {
        // _bid will throw if the bid or funds transfer fails
        _bid(_tokenId, _amount);
        _transfer(nftAddress, msg.sender, _tokenId);
    }

    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId) public onlyNotBlackListed(msg.sender) {
        Auction storage _auction = auctions[nftAddress][_tokenId];
        require(_isOnAuction(_auction), "is_not_on_auction");
        require(
            msg.sender == _auction.seller || admins[msg.sender],
            "dont_have_pemission"
        );
        _cancelAuction(_tokenId, _auction.seller);
    }

    /// @dev Cancels all auctions that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// For emergency purposes only
    function cancelAllAuction() external onlyMarketManger {
        uint256[] memory dinosOwnedByMarket = IDinolandNFT(nftAddress)
            .getDinosByOwner(address(this));
        for (uint256 i = 0; i < dinosOwnedByMarket.length; i++) {
            if (dinosOwnedByMarket[i] != 0) {
                cancelAuction(dinosOwnedByMarket[i]);
            }
        }
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _nftAddress - Address of the NFT.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelAuctionWhenPaused(address _nftAddress, uint256 _tokenId)
        external
        whenPaused
        onlyAdmin
    {
        Auction storage _auction = auctions[_nftAddress][_tokenId];
        require(_isOnAuction(_auction));
        _cancelAuction(_tokenId, _auction.seller);
    }

    /// @dev Returns true if the NFT is on auction.
    /// @param _auction - Auction to check.
    function _isOnAuction(Auction storage _auction)
        internal
        view
        returns (bool)
    {
        return (_auction.startedAt > 0);
    }

    /// @dev Gets the NFT object from an address, validating that implementsERC721 is true.
    /// @param _nftAddress - Address of the NFT.
    function _getNftContract(address _nftAddress)
        internal
        pure
        returns (IERC721)
    {
        IERC721 candidateContract = IERC721(_nftAddress);
        // require(candidateContract.implementsERC721());
        return candidateContract;
    }

    /// @dev Returns current price of an NFT on auction. Broken into two
    ///  functions (this one, that computes the duration from the auction
    ///  structure, and the other that does the price computation) so we
    ///  can easily test that the price computation works correctly.
    function _getCurrentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 _secondsPassed = 0;

        // A bit of insurance against negative values (or wraparound).
        // Probably not necessary (since Ethereum guarantees that the
        // now variable doesn't ever go backwards).
        if (block.timestamp > _auction.startedAt) {
            _secondsPassed = block.timestamp - _auction.startedAt;
        }

        return
            _computeCurrentPrice(
                _auction.startingPrice,
                _auction.endingPrice,
                _auction.duration,
                _secondsPassed
            );
    }

    /// @dev Computes the current price of an auction. Factored out
    ///  from _currentPrice so we can run extensive unit tests.
    ///  When testing, make this function external and turn on
    ///  `Current price computation` test suite.
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    ) internal pure returns (uint256) {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our external functions carefully cap the maximum values for
        //  time (at 64-bits) and currency (at 128-bits). _duration is
        //  also known to be non-zero (see the require() statement in
        //  _addAuction())
        if (_secondsPassed >= _duration) {
            // We've reached the end of the dynamic pricing portion
            // of the auction, just return the end price.
            return _endingPrice;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 _totalPriceChange = int256(_endingPrice) -
                int256(_startingPrice);

            // This multiplication can't overflow, _secondsPassed will easily fit within
            // 64-bits, and _totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 _currentPriceChange = (_totalPriceChange *
                int256(_secondsPassed)) / int256(_duration);

            // _currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            int256 _currentPrice = int256(_startingPrice) + _currentPriceChange;

            return uint256(_currentPrice);
        }
    }

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _claimant, uint256 _tokenId)
        private
        view
        returns (bool)
    {
        IERC721 _nftContract = _getNftContract(nftAddress);
        return (_nftContract.ownerOf(_tokenId) == _claimant);
    }

    /// @dev Adds an auction to the list of open auctions. Also fires the
    ///  AuctionCreated event.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(
        address _nftAddress,
        uint256 _tokenId,
        Auction memory _auction,
        address _seller
    ) internal {
        // Require that all auctions have a duration of
        // at least one minute. (Keeps our math from getting hairy!)
        require(_auction.duration >= 1 minutes, "duration_need_at_least_1min");

        auctions[_nftAddress][_tokenId] = _auction;

        emit AuctionCreated(
            _tokenId,
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration),
            _seller
        );
    }

    /// @dev Removes an auction from the list of open auctions.
    /// @param _tokenId - ID of NFT on auction.
    function _removeAuction(uint256 _tokenId) internal {
        delete auctions[nftAddress][_tokenId];
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(nftAddress, _seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _nftAddress - The address of the NFT.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(
        address _nftAddress,
        address _owner,
        uint256 _tokenId
    ) internal {
        IERC721 _nftContract = IERC721(_nftAddress);

        // It will throw if transfer fails
        _nftContract.transferFrom(_owner, address(this), _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _nftAddress - The address of the NFT.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(
        address _nftAddress,
        address _receiver,
        uint256 _tokenId
    ) internal {
        IERC721 _nftContract = IERC721(_nftAddress);

        // It will throw if transfer fails
        _nftContract.transferFrom(address(this), _receiver, _tokenId);
    }

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
        //  statement in the ClockAuction constructor). The result of this
        //  function is always guaranteed to be <= _price.
        return (_price * ownerCut) / 10000;
    }

    /// @dev Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        // Get a reference to the auction struct
        Auction storage _auction = auctions[nftAddress][_tokenId];

        // Explicitly check that this auction is currently live.
        // (Because of how Ethereum mappings work, we can't just count
        // on the lookup above failing. An invalid _tokenId will just
        // return an auction object that is all zeros.)
        // require(_isOnAuction(_auction), "Is not on auction");
        require(_auction.startedAt > 0, "is_not_on_auction");

        // Check that the incoming bid is higher than the current
        // price
        uint256 _price = _getCurrentPrice(_auction);
        require(_bidAmount >= _price, "bid_amount_is_not_enough");

        // Grab a reference to the seller before the auction struct
        // gets deleted.
        address _seller = _auction.seller;

        // The bid is good! Remove the auction before sending the fees
        // to the sender so we can't have a reentrancy attack.
        _removeAuction(_tokenId);

        // Transfer proceeds to seller (if there are any!)
        if (_price > 0) {
            //  Calculate the auctioneer's cut.
            // (NOTE: _computeCut() is guaranteed to return a
            //  value <= price, so this subtraction can't go negative.)
            uint256 _auctioneerCut = _computeCut(_price);
            uint256 _sellerProceeds = _price - _auctioneerCut;

            // Keep ownerCut percent
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _auctioneerCut
            );
            // Transfer the remaining token to seller
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                _seller,
                _sellerProceeds
            );
        }
        // Tell the world!
        emit AuctionSuccessful(_tokenId, _price, msg.sender);

        return _price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IDinolandNFT{
    function createDino(uint256 _dinoGenes, address _ownerAddress, uint128 _gender, uint128 _generation) external returns(uint256);
    function getDinosByOwner(address _owner) external returns(uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
        return msg.data;
    }
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
    constructor() {
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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}