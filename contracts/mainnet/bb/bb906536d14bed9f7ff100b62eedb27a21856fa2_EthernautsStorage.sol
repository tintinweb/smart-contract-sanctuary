pragma solidity ^0.4.19;





/// @dev Base contract for all Ethernauts contracts holding global constants and functions.
contract EthernautsBase {

    /*** CONSTANTS USED ACROSS CONTRACTS ***/

    /// @dev Used by all contracts that interfaces with Ethernauts
    ///      The ERC-165 interface signature for ERC-721.
    ///  Ref: https://github.com/ethereum/EIPs/issues/165
    ///  Ref: https://github.com/ethereum/EIPs/issues/721
    bytes4 constant InterfaceSignature_ERC721 =
    bytes4(keccak256(&#39;name()&#39;)) ^
    bytes4(keccak256(&#39;symbol()&#39;)) ^
    bytes4(keccak256(&#39;totalSupply()&#39;)) ^
    bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
    bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
    bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;transfer(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;takeOwnership(uint256)&#39;)) ^
    bytes4(keccak256(&#39;tokensOfOwner(address)&#39;)) ^
    bytes4(keccak256(&#39;tokenMetadata(uint256,string)&#39;));

    /// @dev due solidity limitation we cannot return dynamic array from methods
    /// so it creates incompability between functions across different contracts
    uint8 public constant STATS_SIZE = 10;
    uint8 public constant SHIP_SLOTS = 5;

    // Possible state of any asset
    enum AssetState { Available, UpForLease, Used }

    // Possible state of any asset
    // NotValid is to avoid 0 in places where category must be bigger than zero
    enum AssetCategory { NotValid, Sector, Manufacturer, Ship, Object, Factory, CrewMember }

    /// @dev Sector stats
    enum ShipStats {Level, Attack, Defense, Speed, Range, Luck}
    /// @notice Possible attributes for each asset
    /// 00000001 - Seeded - Offered to the economy by us, the developers. Potentially at regular intervals.
    /// 00000010 - Producible - Product of a factory and/or factory contract.
    /// 00000100 - Explorable- Product of exploration.
    /// 00001000 - Leasable - Can be rented to other users and will return to the original owner once the action is complete.
    /// 00010000 - Permanent - Cannot be removed, always owned by a user.
    /// 00100000 - Consumable - Destroyed after N exploration expeditions.
    /// 01000000 - Tradable - Buyable and sellable on the market.
    /// 10000000 - Hot Potato - Automatically gets put up for sale after acquiring.
    bytes2 public ATTR_SEEDED     = bytes2(2**0);
    bytes2 public ATTR_PRODUCIBLE = bytes2(2**1);
    bytes2 public ATTR_EXPLORABLE = bytes2(2**2);
    bytes2 public ATTR_LEASABLE   = bytes2(2**3);
    bytes2 public ATTR_PERMANENT  = bytes2(2**4);
    bytes2 public ATTR_CONSUMABLE = bytes2(2**5);
    bytes2 public ATTR_TRADABLE   = bytes2(2**6);
    bytes2 public ATTR_GOLDENGOOSE = bytes2(2**7);
}

/// @title Inspired by https://github.com/axiomzen/cryptokitties-bounty/blob/master/contracts/KittyAccessControl.sol
/// @notice This contract manages the various addresses and constraints for operations
//          that can be executed only by specific roles. Namely CEO and CTO. it also includes pausable pattern.
contract EthernautsAccessControl is EthernautsBase {

    // This facet controls access control for Ethernauts.
    // All roles have same responsibilities and rights, but there is slight differences between them:
    //
    //     - The CEO: The CEO can reassign other roles and only role that can unpause the smart contract.
    //       It is initially set to the address that created the smart contract.
    //
    //     - The CTO: The CTO can change contract address, oracle address and plan for upgrades.
    //
    //     - The COO: The COO can change contract address and add create assets.
    //
    /// @dev Emited when contract is upgraded - See README.md for updgrade plan
    /// @param newContract address pointing to new contract
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public ctoAddress;
    address public cooAddress;
    address public oracleAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CTO-only functionality
    modifier onlyCTO() {
        require(msg.sender == ctoAddress);
        _;
    }

    /// @dev Access modifier for CTO-only functionality
    modifier onlyOracle() {
        require(msg.sender == oracleAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == ctoAddress ||
            msg.sender == cooAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CTO. Only available to the current CTO or CEO.
    /// @param _newCTO The address of the new CTO
    function setCTO(address _newCTO) external {
        require(
            msg.sender == ceoAddress ||
            msg.sender == ctoAddress
        );
        require(_newCTO != address(0));

        ctoAddress = _newCTO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current COO or CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cooAddress
        );
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /// @dev Assigns a new address to act as oracle.
    /// @param _newOracle The address of oracle
    function setOracle(address _newOracle) external {
        require(msg.sender == ctoAddress);
        require(_newOracle != address(0));

        oracleAddress = _newOracle;
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

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CTO account is compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCEO whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }

}

/// @title Storage contract for Ethernauts Data. Common structs and constants.
/// @notice This is our main data storage, constants and data types, plus
//          internal functions for managing the assets. It is isolated and only interface with
//          a list of granted contracts defined by CTO
/// @author Ethernauts - Fernando Pauer
contract EthernautsStorage is EthernautsAccessControl {

    function EthernautsStorage() public {
        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // the creator of the contract is the initial CTO as well
        ctoAddress = msg.sender;

        // the creator of the contract is the initial CTO as well
        cooAddress = msg.sender;

        // the creator of the contract is the initial Oracle as well
        oracleAddress = msg.sender;
    }

    /// @notice No tipping!
    /// @dev Reject all Ether from being sent here. Hopefully, we can prevent user accidents.
    function() external payable {
        require(msg.sender == address(this));
    }

    /*** Mapping for Contracts with granted permission ***/
    mapping (address => bool) public contractsGrantedAccess;

    /// @dev grant access for a contract to interact with this contract.
    /// @param _v2Address The contract address to grant access
    function grantAccess(address _v2Address) public onlyCTO {
        // See README.md for updgrade plan
        contractsGrantedAccess[_v2Address] = true;
    }

    /// @dev remove access from a contract to interact with this contract.
    /// @param _v2Address The contract address to be removed
    function removeAccess(address _v2Address) public onlyCTO {
        // See README.md for updgrade plan
        delete contractsGrantedAccess[_v2Address];
    }

    /// @dev Only allow permitted contracts to interact with this contract
    modifier onlyGrantedContracts() {
        require(contractsGrantedAccess[msg.sender] == true);
        _;
    }

    modifier validAsset(uint256 _tokenId) {
        require(assets[_tokenId].ID > 0);
        _;
    }
    /*** DATA TYPES ***/

    /// @dev The main Ethernauts asset struct. Every asset in Ethernauts is represented by a copy
    ///  of this structure. Note that the order of the members in this structure
    ///  is important because of the byte-packing rules used by Ethereum.
    ///  Ref: http://solidity.readthedocs.io/en/develop/miscellaneous.html
    struct Asset {

        // Asset ID is a identifier for look and feel in frontend
        uint16 ID;

        // Category = Sectors, Manufacturers, Ships, Objects (Upgrades/Misc), Factories and CrewMembers
        uint8 category;

        // The State of an asset: Available, On sale, Up for lease, Cooldown, Exploring
        uint8 state;

        // Attributes
        // byte pos - Definition
        // 00000001 - Seeded - Offered to the economy by us, the developers. Potentially at regular intervals.
        // 00000010 - Producible - Product of a factory and/or factory contract.
        // 00000100 - Explorable- Product of exploration.
        // 00001000 - Leasable - Can be rented to other users and will return to the original owner once the action is complete.
        // 00010000 - Permanent - Cannot be removed, always owned by a user.
        // 00100000 - Consumable - Destroyed after N exploration expeditions.
        // 01000000 - Tradable - Buyable and sellable on the market.
        // 10000000 - Hot Potato - Automatically gets put up for sale after acquiring.
        bytes2 attributes;

        // The timestamp from the block when this asset was created.
        uint64 createdAt;

        // The minimum timestamp after which this asset can engage in exploring activities again.
        uint64 cooldownEndBlock;

        // The Asset&#39;s stats can be upgraded or changed based on exploration conditions.
        // It will be defined per child contract, but all stats have a range from 0 to 255
        // Examples
        // 0 = Ship Level
        // 1 = Ship Attack
        uint8[STATS_SIZE] stats;

        // Set to the cooldown time that represents exploration duration for this asset.
        // Defined by a successful exploration action, regardless of whether this asset is acting as ship or a part.
        uint256 cooldown;

        // a reference to a super asset that manufactured the asset
        uint256 builtBy;
    }

    /*** CONSTANTS ***/

    // @dev Sanity check that allows us to ensure that we are pointing to the
    //  right storage contract in our EthernautsLogic(address _CStorageAddress) call.
    bool public isEthernautsStorage = true;

    /*** STORAGE ***/

    /// @dev An array containing the Asset struct for all assets in existence. The Asset UniqueId
    ///  of each asset is actually an index into this array.
    Asset[] public assets;

    /// @dev A mapping from Asset UniqueIDs to the price of the token.
    /// stored outside Asset Struct to save gas, because price can change frequently
    mapping (uint256 => uint256) internal assetIndexToPrice;

    /// @dev A mapping from asset UniqueIDs to the address that owns them. All assets have some valid owner address.
    mapping (uint256 => address) internal assetIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) internal ownershipTokenCount;

    /// @dev A mapping from AssetUniqueIDs to an address that has been approved to call
    ///  transferFrom(). Each Asset can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) internal assetIndexToApproved;


    /*** SETTERS ***/

    /// @dev set new asset price
    /// @param _tokenId  asset UniqueId
    /// @param _price    asset price
    function setPrice(uint256 _tokenId, uint256 _price) public onlyGrantedContracts {
        assetIndexToPrice[_tokenId] = _price;
    }

    /// @dev Mark transfer as approved
    /// @param _tokenId  asset UniqueId
    /// @param _approved address approved
    function approve(uint256 _tokenId, address _approved) public onlyGrantedContracts {
        assetIndexToApproved[_tokenId] = _approved;
    }

    /// @dev Assigns ownership of a specific Asset to an address.
    /// @param _from    current owner address
    /// @param _to      new owner address
    /// @param _tokenId asset UniqueId
    function transfer(address _from, address _to, uint256 _tokenId) public onlyGrantedContracts {
        // Since the number of assets is capped to 2^32 we can&#39;t overflow this
        ownershipTokenCount[_to]++;
        // transfer ownership
        assetIndexToOwner[_tokenId] = _to;
        // When creating new assets _from is 0x0, but we can&#39;t account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // clear any previously approved ownership exchange
            delete assetIndexToApproved[_tokenId];
        }
    }

    /// @dev A public method that creates a new asset and stores it. This
    ///  method does basic checking and should only be called from other contract when the
    ///  input data is known to be valid. Will NOT generate any event it is delegate to business logic contracts.
    /// @param _creatorTokenID The asset who is father of this asset
    /// @param _owner First owner of this asset
    /// @param _price asset price
    /// @param _ID asset ID
    /// @param _category see Asset Struct description
    /// @param _state see Asset Struct description
    /// @param _attributes see Asset Struct description
    /// @param _stats see Asset Struct description
    function createAsset(
        uint256 _creatorTokenID,
        address _owner,
        uint256 _price,
        uint16 _ID,
        uint8 _category,
        uint8 _state,
        uint8 _attributes,
        uint8[STATS_SIZE] _stats,
        uint256 _cooldown,
        uint64 _cooldownEndBlock
    )
    public onlyGrantedContracts
    returns (uint256)
    {
        // Ensure our data structures are always valid.
        require(_ID > 0);
        require(_category > 0);
        require(_attributes != 0x0);
        require(_stats.length > 0);

        Asset memory asset = Asset({
            ID: _ID,
            category: _category,
            builtBy: _creatorTokenID,
            attributes: bytes2(_attributes),
            stats: _stats,
            state: _state,
            createdAt: uint64(now),
            cooldownEndBlock: _cooldownEndBlock,
            cooldown: _cooldown
        });

        uint256 newAssetUniqueId = assets.push(asset) - 1;

        // Check it reached 4 billion assets but let&#39;s just be 100% sure.
        require(newAssetUniqueId == uint256(uint32(newAssetUniqueId)));

        // store price
        assetIndexToPrice[newAssetUniqueId] = _price;

        // This will assign ownership
        transfer(address(0), _owner, newAssetUniqueId);

        return newAssetUniqueId;
    }

    /// @dev A public method that edit asset in case of any mistake is done during process of creation by the developer. This
    /// This method doesn&#39;t do any checking and should only be called when the
    ///  input data is known to be valid.
    /// @param _tokenId The token ID
    /// @param _creatorTokenID The asset that create that token
    /// @param _price asset price
    /// @param _ID asset ID
    /// @param _category see Asset Struct description
    /// @param _state see Asset Struct description
    /// @param _attributes see Asset Struct description
    /// @param _stats see Asset Struct description
    /// @param _cooldown asset cooldown index
    function editAsset(
        uint256 _tokenId,
        uint256 _creatorTokenID,
        uint256 _price,
        uint16 _ID,
        uint8 _category,
        uint8 _state,
        uint8 _attributes,
        uint8[STATS_SIZE] _stats,
        uint16 _cooldown
    )
    external validAsset(_tokenId) onlyCLevel
    returns (uint256)
    {
        // Ensure our data structures are always valid.
        require(_ID > 0);
        require(_category > 0);
        require(_attributes != 0x0);
        require(_stats.length > 0);

        // store price
        assetIndexToPrice[_tokenId] = _price;

        Asset storage asset = assets[_tokenId];
        asset.ID = _ID;
        asset.category = _category;
        asset.builtBy = _creatorTokenID;
        asset.attributes = bytes2(_attributes);
        asset.stats = _stats;
        asset.state = _state;
        asset.cooldown = _cooldown;
    }

    /// @dev Update only stats
    /// @param _tokenId asset UniqueId
    /// @param _stats asset state, see Asset Struct description
    function updateStats(uint256 _tokenId, uint8[STATS_SIZE] _stats) public validAsset(_tokenId) onlyGrantedContracts {
        assets[_tokenId].stats = _stats;
    }

    /// @dev Update only asset state
    /// @param _tokenId asset UniqueId
    /// @param _state asset state, see Asset Struct description
    function updateState(uint256 _tokenId, uint8 _state) public validAsset(_tokenId) onlyGrantedContracts {
        assets[_tokenId].state = _state;
    }

    /// @dev Update Cooldown for a single asset
    /// @param _tokenId asset UniqueId
    /// @param _cooldown asset state, see Asset Struct description
    function setAssetCooldown(uint256 _tokenId, uint256 _cooldown, uint64 _cooldownEndBlock)
    public validAsset(_tokenId) onlyGrantedContracts {
        assets[_tokenId].cooldown = _cooldown;
        assets[_tokenId].cooldownEndBlock = _cooldownEndBlock;
    }

    /*** GETTERS ***/

    /// @notice Returns only stats data about a specific asset.
    /// @dev it is necessary due solidity compiler limitations
    ///      when we have large qty of parameters it throws StackTooDeepException
    /// @param _tokenId The UniqueId of the asset of interest.
    function getStats(uint256 _tokenId) public view returns (uint8[STATS_SIZE]) {
        return assets[_tokenId].stats;
    }

    /// @dev return current price of an asset
    /// @param _tokenId asset UniqueId
    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
        return assetIndexToPrice[_tokenId];
    }

    /// @notice Check if asset has all attributes passed by parameter
    /// @param _tokenId The UniqueId of the asset of interest.
    /// @param _attributes see Asset Struct description
    function hasAllAttrs(uint256 _tokenId, bytes2 _attributes) public view returns (bool) {
        return assets[_tokenId].attributes & _attributes == _attributes;
    }

    /// @notice Check if asset has any attribute passed by parameter
    /// @param _tokenId The UniqueId of the asset of interest.
    /// @param _attributes see Asset Struct description
    function hasAnyAttrs(uint256 _tokenId, bytes2 _attributes) public view returns (bool) {
        return assets[_tokenId].attributes & _attributes != 0x0;
    }

    /// @notice Check if asset is in the state passed by parameter
    /// @param _tokenId The UniqueId of the asset of interest.
    /// @param _category see AssetCategory in EthernautsBase for possible states
    function isCategory(uint256 _tokenId, uint8 _category) public view returns (bool) {
        return assets[_tokenId].category == _category;
    }

    /// @notice Check if asset is in the state passed by parameter
    /// @param _tokenId The UniqueId of the asset of interest.
    /// @param _state see enum AssetState in EthernautsBase for possible states
    function isState(uint256 _tokenId, uint8 _state) public view returns (bool) {
        return assets[_tokenId].state == _state;
    }

    /// @notice Returns owner of a given Asset(Token).
    /// @dev Required for ERC-721 compliance.
    /// @param _tokenId asset UniqueId
    function ownerOf(uint256 _tokenId) public view returns (address owner)
    {
        return assetIndexToOwner[_tokenId];
    }

    /// @dev Required for ERC-721 compliance
    /// @notice Returns the number of Assets owned by a specific address.
    /// @param _owner The owner address to check.
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    /// @dev Checks if a given address currently has transferApproval for a particular Asset.
    /// @param _tokenId asset UniqueId
    function approvedFor(uint256 _tokenId) public view onlyGrantedContracts returns (address) {
        return assetIndexToApproved[_tokenId];
    }

    /// @notice Returns the total number of Assets currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint256) {
        return assets.length;
    }

    /// @notice List all existing tokens. It can be filtered by attributes or assets with owner
    /// @param _owner filter all assets by owner
    function getTokenList(address _owner, uint8 _withAttributes, uint256 start, uint256 count) external view returns(
        uint256[6][]
    ) {
        uint256 totalAssets = assets.length;

        if (totalAssets == 0) {
            // Return an empty array
            return new uint256[6][](0);
        } else {
            uint256[6][] memory result = new uint256[6][](totalAssets > count ? count : totalAssets);
            uint256 resultIndex = 0;
            bytes2 hasAttributes  = bytes2(_withAttributes);
            Asset memory asset;

            for (uint256 tokenId = start; tokenId < totalAssets && resultIndex < count; tokenId++) {
                asset = assets[tokenId];
                if (
                    (asset.state != uint8(AssetState.Used)) &&
                    (assetIndexToOwner[tokenId] == _owner || _owner == address(0)) &&
                    (asset.attributes & hasAttributes == hasAttributes)
                ) {
                    result[resultIndex][0] = tokenId;
                    result[resultIndex][1] = asset.ID;
                    result[resultIndex][2] = asset.category;
                    result[resultIndex][3] = uint256(asset.attributes);
                    result[resultIndex][4] = asset.cooldown;
                    result[resultIndex][5] = assetIndexToPrice[tokenId];
                    resultIndex++;
                }
            }

            return result;
        }
    }
}