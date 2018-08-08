pragma solidity ^0.4.13;

contract Commons {

    int256 constant INT256_MIN = int256((uint256(1) << 255));
    int256 constant INT256_MAX = int256(~((uint256(1) << 255)));
    uint256 constant UINT256_MIN = 0;
    uint256 constant UINT256_MAX = ~uint256(0);

    struct IndexElem {
        bytes32 mappingId;
        int nOp;
    }

    function Commons() internal { }
}

contract Ownable {

    address internal owner;

    event LogTransferOwnership(address previousOwner, address newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() internal
    {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier ownerOnly()
    {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external
        ownerOnly
    {
        require(_newOwner != address(0));
        emit LogTransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     *
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

contract Authorized is Ownable {

    struct User {
        string friendlyName;
        string offChainIdentity;
        bool isRegulator;
        bool isProducer;
        bool isWinery;
    }

    mapping (address => User) public onChainIdentities;    
    mapping (bytes32 => address) public onChainAddresses;

    event LogSetUser
    (
        address account, 
        string oldFriendlyName, 
        string oldOffChainIdentity, 
        bool oldIsProducer, 
        bool oldIsWinery, 
        bool oldIsRegulator, 
        address indexed operationSender
    );

    event LogSetWinery
    (
        address winery, 
        bool oldIsValid, 
        bool isValid, 
        address indexed operationSender
    );

    event LogSetRegulator
    (
        address regulator, 
        bool oldValue, 
        bool value, 
        address indexed operationSender
    );

    event LogSetProducer
    (
        address producer, 
        bool oldValue, 
        bool value, 
        address indexed operationSender
    );

    function Authorized() internal { }

    modifier producersOnly() {
        require(onChainIdentities[msg.sender].isProducer);
        _;
    }

    modifier wineriesOnly() {
        require(onChainIdentities[msg.sender].isWinery);
        _;
    }

    modifier regulatorsOnly() {
        require(onChainIdentities[msg.sender].isRegulator);
        _;
    }

    function setUser(
        address _address,
        string _friendlyName,
        string _offChainIdentity,
        bool _isRegulator,
        bool _isProducer,
        bool _isWinery
    ) 
        public
        ownerOnly
    {
        emit LogSetUser (
            _address, 
            onChainIdentities[_address].friendlyName, 
            onChainIdentities[_address].offChainIdentity, 
            onChainIdentities[_address].isProducer, 
            onChainIdentities[_address].isWinery, 
            onChainIdentities[_address].isRegulator, 
            msg.sender
        );
        onChainAddresses[keccak256(_offChainIdentity)] = _address;
        onChainIdentities[_address].friendlyName = _friendlyName;
        onChainIdentities[_address].offChainIdentity = _offChainIdentity;
        onChainIdentities[_address].isRegulator = _isRegulator;
        onChainIdentities[_address].isProducer = _isProducer;
        onChainIdentities[_address].isWinery = _isWinery;
    }

    function getOffChainIdentity(address _address) internal view returns (string offChainIdentity)
    {
        return onChainIdentities[_address].offChainIdentity;
    }

    function getUser(address _address)
        external view
        returns (
            string friendlyName, 
            string offChainIdentity, 
            bool isRegulator, 
            bool isProducer, 
            bool isWinery
        ) 
    {
        return (
            onChainIdentities[_address].friendlyName,
            onChainIdentities[_address].offChainIdentity,
            onChainIdentities[_address].isRegulator,
            onChainIdentities[_address].isProducer,
            onChainIdentities[_address].isWinery
        );
    }

    function getAddress(string _offChainIdentity) public view returns (address) {
        return onChainAddresses[keccak256(_offChainIdentity)];
    }

    function setRegulator(address _address, bool _newValue) external ownerOnly {
        emit LogSetRegulator(_address, onChainIdentities[_address].isRegulator, _newValue, msg.sender);
        onChainIdentities[_address].isRegulator = _newValue;
    }

    function setProducer(address _address, bool _newValue) external ownerOnly {
        emit LogSetProducer(_address, onChainIdentities[_address].isProducer, _newValue, msg.sender);
        onChainIdentities[_address].isProducer = _newValue;
    }

    function setWinery(address _address, bool _newValue) external ownerOnly {
        emit LogSetProducer(_address, onChainIdentities[_address].isWinery, _newValue, msg.sender);
        onChainIdentities[_address].isWinery = _newValue;
    }

}

contract WineryOperations is Commons, Authorized {

    uint256 constant OPERATION_SEARCH_MAX = uint(INT256_MAX);

    struct WineryOperation {
        address operationSender;
        string offChainIdentity;   //cuaa
        string operationID;        // hash (offChainIdentity, operationDate, operationCode)
        string operationCode;      //Es. IMBO
        uint operationDate;
        uint16 areaCode;           // mapping
        string codeICQRF;          // codice_icqrf_stabilimento
        string attributes;
        Product[] prods;
        IndexElem[] parentList;
        IndexElem[] childList;        
    }

    struct Product {
        string productID;      // codice_primario + codice_secondario
        string quantity;        // 1,345 kg
        string attributes;      // dsda; dasd;; sadas;
    }

    mapping(bytes32 => WineryOperation[]) public wineries;

    event LogAddWineryOperation(
        string _trackID,
        address operationSender,
        address indexed onChainIdentity,
        string operationID,      
        uint index
    );

    event LogAddProduct(
        string _trackID,
        address operationSender,
        address indexed onChainIdentity,
        string indexed operationID,
        string productID
    );

    function WineryOperations() internal { }
    
    // ============================================================================================
    // External functions for wineries
    // ============================================================================================

    function addWineryOperation(
        string _trackID,
        string _operationID,
        string _operationCode,
        uint _operationDate,
        uint16 _areaCode,
        string _codeICQRF
    )
        external
        wineriesOnly
        returns (bool success)
    {
        bytes32 _mappingID = keccak256(_trackID, msg.sender);
        addWineryOperation(
            _mappingID,
            msg.sender,
            onChainIdentities[msg.sender].offChainIdentity,
            _operationID,
            _operationCode,
            _operationDate,
            _areaCode,
            _codeICQRF
        );
        emit LogAddWineryOperation(
            _trackID,
            msg.sender,
            msg.sender,
            _operationID,
            wineries[_mappingID].length
        );
        return true;
    }

    function addProduct(
        string _trackID,
        uint _index,
        string _productID,
        string _quantity,
        string _attributes
    )
        external
        wineriesOnly
        returns (bool success)
    {
        bytes32 _mappingID = keccak256(_trackID, msg.sender);
        addProduct(
            _mappingID,
            _index,
            _productID,
            _quantity,
            _attributes
        );
        emit LogAddProduct(
            _trackID,
            msg.sender,
            msg.sender,
            wineries[_mappingID][_index].operationID,
            _productID
        );
        return true;
    }

    function addReferenceParentWineryOperation(
        string _trackID,
        uint _numCurOperation,
        string _parentTrackID,
        address _parentWinery,
        int _numParent        
    )
        external
        wineriesOnly
        returns (bool success)
    {
        addRelationshipBindingWineryOperation(
            keccak256(_trackID, msg.sender),
            _numCurOperation,
            keccak256(_parentTrackID, _parentWinery),
            _numParent
        );
        return true;
    }

    function setOperationAttributes(
        string _trackID,
        uint _operationIndex,
        string attributes
    )
        external
        wineriesOnly
        returns (bool success)
    {
        bytes32 _mappingID = keccak256(_trackID, msg.sender);
        wineries[_mappingID][_operationIndex].attributes = attributes;
        return true;
    }

    function setProductAttributes(
        string _trackID,
        uint _operationIndex,
        uint _productIndex,
        string attributes
    )
        external
        wineriesOnly
        returns (bool success)
    {
        bytes32 _mappingID = keccak256(_trackID, msg.sender);
        wineries[_mappingID][_operationIndex].prods[_productIndex].attributes = attributes;
        return true;
    }

    // ============================================================================================
    // External functions for regulators
    // ============================================================================================

    function addWineryOperationByRegulator(
        string _trackID,
        string _offChainIdentity,
        string _operationID,
        string _operationCode,
        uint _operationDate,
        uint16 _areaCode,
        string _codeICQRF
    )
        external
        regulatorsOnly
    {
        address _winery = getAddress(_offChainIdentity);
        bytes32 _mappingID = keccak256(_trackID, _winery);
        addWineryOperation(
            _mappingID,
            msg.sender,
            _offChainIdentity,
            _operationID,
            _operationCode,
            _operationDate,
            _areaCode,
            _codeICQRF
        );
        emit LogAddWineryOperation(
            _trackID,
            msg.sender,
            _winery,
            _operationID,
            wineries[_mappingID].length
        );
    }
    
    function addProductByRegulator(
        string _trackID,
        uint _index,
        string _offChainIdentity,
        string _productID,
        string _quantity,
        string _attributes
    )
        external
        regulatorsOnly
    {
        address _winery = getAddress(_offChainIdentity);
        bytes32 _mappingID = keccak256(_trackID, _winery);
        addProduct(
            _mappingID,
            _index,
            _productID,
            _quantity,
            _attributes
        );
        emit LogAddProduct(
            _trackID,
            msg.sender,
            _winery,
            wineries[_mappingID][_index].operationID,
            _productID
        );
    }

    function setOperationAttributesByRegulator(
        string _trackID,
        string _offChainIdentity,
        uint _operationIndex,
        string attributes
    )
        external
        regulatorsOnly
        returns (bool success)
    {     
        address _winery = getAddress(_offChainIdentity);
        bytes32 _mappingID = keccak256(_trackID, _winery);
        wineries[_mappingID][_operationIndex].attributes = attributes;
        return true;
    }

    function setProductAttributesByRegulator(
        string _trackID,
        string _offChainIdentity,
        uint _operationIndex,
        uint _productIndex,
        string attributes
    )
        external
        regulatorsOnly
        returns (bool success)
    {
        address _winery = getAddress(_offChainIdentity);
        bytes32 _mappingID = keccak256(_trackID, _winery);
        wineries[_mappingID][_operationIndex].prods[_productIndex].attributes = attributes;
        return true;
    }

    function addReferenceParentWineryOperationByRegulator(
        string _trackID,
        string _offChainIdentity,
        uint _numCurOperation,
        string _parentTrackID,
        string _parentOffChainIdentity,
        int _numParent        
    )
        external
        regulatorsOnly
        returns (bool success)
    {
        address _winery = getAddress(_offChainIdentity);
        address _parentWinery = getAddress(_parentOffChainIdentity);
        addRelationshipBindingWineryOperation(
            keccak256(_trackID, _winery),
            _numCurOperation,
            keccak256(_parentTrackID, _parentWinery),
            _numParent
        );
        return true;
    }

    // ============================================================================================
    // Helpers for &#208;Apps
    // ============================================================================================
    
    /// @notice ****
    function getWineryOperation(string _trackID, address _winery, uint _index)
        external view
        returns (
            address operationSender,
            string offChainIdentity,
            string operationID,
            string operationCode,
            uint operationDate,
            uint16 areaCode,
            string codeICQRF,
            string attributes
        )
    {
        bytes32 _mappingID = keccak256(_trackID, _winery);
        operationSender = wineries[_mappingID][_index].operationSender;
        offChainIdentity = wineries[_mappingID][_index].offChainIdentity;
        operationID = wineries[_mappingID][_index].operationID;
        operationCode = wineries[_mappingID][_index].operationCode;
        operationDate = wineries[_mappingID][_index].operationDate;
        areaCode = wineries[_mappingID][_index].areaCode;
        codeICQRF = wineries[_mappingID][_index].codeICQRF;
        attributes = wineries[_mappingID][_index].attributes;
    }

    function getProductOperation(string _trackID, address _winery, uint _index, uint _productIndex)
        external view
        returns (
            string productID,
            string quantity,
            string attributes
        )
    {
        bytes32 _mappingID = keccak256(_trackID, _winery);
        productID = wineries[_mappingID][_index].prods[_productIndex].productID;
        quantity = wineries[_mappingID][_index].prods[_productIndex].quantity;
        attributes = wineries[_mappingID][_index].prods[_productIndex].attributes;
    }

    function getNumPositionOperation(string _trackID, address _winery, string _operationID)
        external view
        returns (int position)
    {
        bytes32 _mappingID = keccak256(_trackID, _winery);
        for (uint i = 0; i < wineries[_mappingID].length && i < OPERATION_SEARCH_MAX; i++) {
            if (keccak256(wineries[_mappingID][i].operationID) == keccak256(_operationID)) {
                return int(i);
            }
        }
        return -1;
    }

    // ============================================================================================
    // Private functions
    // ============================================================================================

    /// @notice TODO Commenti
    function addWineryOperation(
        bytes32 _mappingID,
        address _operationSender,
        string _offChainIdentity,
        string _operationID,
        string _operationCode,
        uint _operationDate,
        uint16 _areaCode,
        string _codeICQRF
    )
        private
    {
        uint size = wineries[_mappingID].length;
        wineries[_mappingID].length++;
        wineries[_mappingID][size].operationSender = _operationSender;
        wineries[_mappingID][size].offChainIdentity = _offChainIdentity;
        wineries[_mappingID][size].operationID = _operationID;
        wineries[_mappingID][size].operationCode = _operationCode;
        wineries[_mappingID][size].operationDate = _operationDate;
        wineries[_mappingID][size].areaCode = _areaCode;
        wineries[_mappingID][size].codeICQRF = _codeICQRF;
    }

    /// @notice TODO Commenti
    function addProduct(
        bytes32 _mappingID,
        uint _index,
        string _productID,
        string _quantity,
        string _attributes
    )
        private
    {
        wineries[_mappingID][_index].prods.push(
            Product(
                _productID,
                _quantity,
                _attributes
            )
        );
    }

    function addRelationshipBindingWineryOperation(
        bytes32 _mappingID,
        uint _numCurOperation,
        bytes32 _parentMappingID,        
        int _numParent        
    )
        private
    {
        require(_numCurOperation < OPERATION_SEARCH_MAX);
        require(_numParent >= 0);
        uint _parentIndex = uint(_numParent);
        int _numCurOperationINT = int(_numCurOperation);
        wineries[_mappingID][_numCurOperation].parentList.push(IndexElem(_parentMappingID, _numParent));
        wineries[_parentMappingID][_parentIndex].childList.push(IndexElem(_mappingID, _numCurOperationINT));
    }

  /*
    
    // ======================================================================================
    // &#208;Apps helpers
    // ======================================================================================




    function getParentOperation(bytes32 _mappingID, uint8 _index, uint8 _nParent) external view returns (bytes32 id, int num) {
        id = wineries[_mappingID][_index].parentList[_nParent].mappingId;
        num = wineries[_mappingID][_index].parentList[_nParent].nOp;
    }

    function getNumParentOperation(bytes32 _mappingID, uint8 _index) external view returns (uint num) {
        num = wineries[_mappingID][_index].parentList.length;
    }

    function getChildOperation(bytes32 _mappingID, uint8 _index, uint8 _nParent) external view returns (bytes32 id, int num) {
        id = wineries[_mappingID][_index].childList[_nParent].mappingId;
        num = wineries[_mappingID][_index].childList[_nParent].nOp;
    }

    function getNumChildOperation(bytes32 _mappingID, uint8 _index) external view returns (uint num) {
        num = wineries[_mappingID][_index].childList.length;
    }
    
    function getNumPositionProduct(bytes32 _mappingID, uint8 _nPosOp, string _productId) external view returns (int position) {
        position = -1;
        for (uint8 i = 0; i < wineries[_mappingID][_nPosOp].prods.length; i++) {
            if (keccak256(wineries[_mappingID][_nPosOp].prods[i].productID) == keccak256(_productId))
                position = i;
        }
    }

    function getNumWineryOperation(bytes32 _mappingID) external view returns (uint num) {
        num = wineries[_mappingID].length;
    }

    */

}

contract ProducerOperations is Commons, Authorized {

    // ============================================================================================
    // Producer operations
    // ============================================================================================

    struct HarvestOperation {
        address operationSender;
        string offChainIdentity;
        string operationID;    // codice_allegato
        uint32 quantity;        // uva_rivendicata (kg)
        uint24 areaCode;        // cod_istat regione_provenienza_uve, mapping
        uint16 year;            // anno raccolta
        string attributes;      
        IndexElem child;
        Vineyard[] vineyards;
    }

    struct Vineyard {
        uint16 variety;        // variet&#224; mapping descrizione_varieta
        uint24 areaCode;       // codice_istat_comune, mapping dal quale si ricaver&#224; anche prov. e descrizione
        uint32 usedSurface;    // vigneto utilizzato (superficie_utilizzata) mq2
        uint16 plantingYear;
    }

    mapping(bytes32 => HarvestOperation) public harvests;
    
    event LogStoreHarvestOperation(
        string trackIDs,
        address operationSender,
        address indexed onChainIdentity,
        string operationID
    );

    event LogAddVineyard(
        string trackIDs,
        address operationSender,
        address indexed onChainIdentity,
        uint24 indexed areaCode       
    );

    function ProducerOperations() internal { }
    
    // ============================================================================================
    // External functions for producers
    // ============================================================================================

    /// @notice ****
    /// @dev ****
    /// @param _trackIDs ****
    /// @return true if operation is successful
    function storeHarvestOperation(
        string _trackIDs,
        string _operationID,
        uint32 _quantity,
        uint16 _areaCode,
        uint16 _year,
        string _attributes
    )
        external
        producersOnly
        returns (bool success)
    {
        storeHarvestOperation(
            keccak256(_trackIDs, msg.sender),
            msg.sender,
            getOffChainIdentity(msg.sender),
            _operationID,            
            _quantity,
            _areaCode,
            _year,
            _attributes
        );
        emit LogStoreHarvestOperation(
            _trackIDs,
            msg.sender,
            msg.sender,
            _operationID
        );
        return true;
    }

    /// @notice ****
    /// @dev ****
    /// @param _trackIDs ****
    /// @return true if operation is successful
    function addVineyard(
        string _trackIDs,
        uint16 _variety,
        uint24 _areaCode,
        uint32 _usedSurface,
        uint16 _plantingYear
    )
        external
        producersOnly
        returns (bool success)
    {
        addVineyard(
            keccak256(_trackIDs, msg.sender),
            _variety,
            _areaCode,            
            _usedSurface,
            _plantingYear
        );
        emit LogAddVineyard(_trackIDs, msg.sender, msg.sender, _areaCode);
        return true;
    }

    // ============================================================================================
    // External functions for regulators
    // ============================================================================================

    function storeHarvestOperationByRegulator(
        string _trackIDs,
        string _offChainIdentity,
        string _operationID,
        uint32 _quantity,
        uint16 _areaCode,
        uint16 _year,
        string _attributes
    )
        external
        regulatorsOnly
        returns (bool success)
    {
        address _producer = getAddress(_offChainIdentity);
        storeHarvestOperation(
            keccak256(_trackIDs,_producer),
            msg.sender,
            _offChainIdentity,
            _operationID,
            _quantity,
            _areaCode,
            _year,
            _attributes
        );
        emit LogStoreHarvestOperation(
            _trackIDs,
            msg.sender,
            _producer,
            _operationID
        );
        return true;
    }

    function addVineyardByRegulator(
        string _trackIDs,
        string _offChainIdentity,
        uint16 _variety,
        uint24 _areaCode,
        uint32 _usedSurface,
        uint16 _plantingYear
    )
        external
        regulatorsOnly
        returns (bool success)
    {
        address _producer = getAddress(_offChainIdentity);
        require(_producer != address(0));
        addVineyard(
            keccak256(_trackIDs,_producer),
            _variety,
            _areaCode,
            _usedSurface,
            _plantingYear
        );
        emit LogAddVineyard(_trackIDs, msg.sender, _producer, _areaCode);
        return true;
    }

    // ============================================================================================
    // Helpers for &#208;Apps
    // ============================================================================================

    function getHarvestOperation(string _trackID, address _producer)
        external view
        returns (
            address operationSender,
            string offChainIdentity,
            string operationID,
            uint32 quantity,
            uint24 areaCode,
            uint16 year,
            string attributes
        )
    {
        bytes32 _mappingID32 = keccak256(_trackID, _producer);
        operationSender = harvests[_mappingID32].operationSender;
        offChainIdentity = harvests[_mappingID32].offChainIdentity;
        operationID = harvests[_mappingID32].operationID;
        quantity = harvests[_mappingID32].quantity;
        areaCode = harvests[_mappingID32].areaCode;
        year = harvests[_mappingID32].year;
        attributes = harvests[_mappingID32].attributes;
    }

    function getVineyard(string _trackID, address _producer, uint _index)
        external view
        returns (
            uint32 variety,
            uint32 areaCode,
            uint32 usedSurface,
            uint16 plantingYear
        )
    {
        bytes32 _mappingID32 = keccak256(_trackID, _producer);
        variety = harvests[_mappingID32].vineyards[_index].variety;
        areaCode = harvests[_mappingID32].vineyards[_index].areaCode;
        usedSurface = harvests[_mappingID32].vineyards[_index].usedSurface;
        plantingYear = harvests[_mappingID32].vineyards[_index].plantingYear;
    }

    function getVineyardCount(string _trackID, address _producer)
        external view
        returns (uint numberOfVineyards)
    {
        bytes32 _mappingID32 = keccak256(_trackID, _producer);
        numberOfVineyards = harvests[_mappingID32].vineyards.length;
    }

    // ============================================================================================
    // Private functions
    // ============================================================================================

    function storeHarvestOperation(
        bytes32 _mappingID,
        address _operationSender,
        string _offChainIdentity,
        string _operationID,
        uint32 _quantity,
        uint24 _areaCode,        
        uint16 _year,
        string _attributes
    )
        private
    {
        harvests[_mappingID].operationSender = _operationSender;
        harvests[_mappingID].offChainIdentity = _offChainIdentity;
        harvests[_mappingID].operationID = _operationID;
        harvests[_mappingID].quantity = _quantity;
        harvests[_mappingID].areaCode = _areaCode;
        harvests[_mappingID].year = _year;
        harvests[_mappingID].attributes = _attributes;
    }

    function addVineyard(
        bytes32 _mappingID,
        uint16 _variety,
        uint24 _areaCode,
        uint32 _usedSurface,
        uint16 _plantingYear        
    )
        private
    {
        harvests[_mappingID].vineyards.push(
            Vineyard(_variety, _areaCode, _usedSurface, _plantingYear)
        );
    }
    
}

contract Upgradable is Ownable {

    address public newAddress;
    uint    public deprecatedSince;
    string  public version;
    string  public newVersion;
    string  public reason;

    event LogSetDeprecated(address newAddress, string newVersion, string reason);

    /**
     *
     */
    function Upgradable(string _version) internal
    {
        version = _version;
    }

    /**
     *
     */
    function setDeprecated(address _newAddress, string _newVersion, string _reason) external
        ownerOnly
        returns (bool success)
    {
        require(!isDeprecated());
        require(_newAddress != address(this));
        require(!Upgradable(_newAddress).isDeprecated());
        deprecatedSince = now;
        newAddress = _newAddress;
        newVersion = _newVersion;
        reason = _reason;
        emit LogSetDeprecated(_newAddress, _newVersion, _reason);
        return true;
    }

    /**
     * @notice check if the contract is deprecated
     */
    function isDeprecated() public view returns (bool deprecated)
    {
        return (deprecatedSince != 0);
    }
}

contract SmartBinding is Authorized {

    mapping (bytes32 => bytes32) public bindingSmartIdentity;
 
    event LogBindSmartIdentity (
        string _trackIDs,
        address operationSender,
        address onChainIdentity,
        string smartIdentity
    );

    function SmartBinding() internal { }

    // ============================================================================================
    // External functions for wineries
    // ============================================================================================

    /// @notice ****
    /// @dev ****
    /// @param _trackIDs ****
    /// @return true if operation is successful
    function bindSmartIdentity(string _trackIDs, string _smartIdentity)
        external
        wineriesOnly
    {
        bindingSmartIdentity[keccak256(_smartIdentity, msg.sender)] = keccak256(_trackIDs, msg.sender);
        emit LogBindSmartIdentity(_trackIDs, msg.sender, msg.sender, _smartIdentity);
    }

    // ============================================================================================
    // External functions for regulators
    // ============================================================================================
    
    /// @notice ****
    /// @dev ****
    /// @param _trackIDs ****
    /// @return true if operation is successful
    function bindSmartIdentityByRegulator(
        string _trackIDs,
        string _offChainIdentity,  
        string _smartIdentity
    )
        external
        regulatorsOnly
    {
        address winery = getAddress(_offChainIdentity);
        bindingSmartIdentity[keccak256(_smartIdentity, winery)] = keccak256(_trackIDs, winery);
        emit LogBindSmartIdentity(_trackIDs, msg.sender, winery, _smartIdentity);
    }

    // ======================================================================================
    // &#208;Apps helpers
    // ======================================================================================

    function getWineryMappingID(string _smartIdentity, string _offChainIdentity)
        external view
        returns (bytes32 wineryMappingID)
    {
        bytes32 index = keccak256(_smartIdentity, getAddress(_offChainIdentity));
        wineryMappingID = bindingSmartIdentity[index];
    }

}

contract WineSupplyChain is
    Commons,
    Authorized,
    Upgradable,
    ProducerOperations,
    WineryOperations,
    SmartBinding
{

    address public endorsements;

    function WineSupplyChain(address _endorsements) Upgradable("1.0.0") public {
        endorsements = _endorsements;
    }

    // ============================================================================================
    // External functions for regulators
    // ============================================================================================

    /// @notice TODO Inserire commenti
    function startWineryProductByRegulator(
        string _harvestTrackID,
        string _producerOffChainIdentity,
        string _wineryOperationTrackIDs,
        string _wineryOffChainIdentity,
        int _productIndex
    )
        external
        regulatorsOnly
        returns (bool success)
    {
        require(_productIndex >= 0);
        address producer = getAddress(_producerOffChainIdentity);
        bytes32 harvestMappingID = keccak256(_harvestTrackID, producer);
        address winery = getAddress(_wineryOffChainIdentity);
        bytes32 wineryOperationMappingID = keccak256(_wineryOperationTrackIDs, winery);
        harvests[harvestMappingID].child = IndexElem(wineryOperationMappingID, _productIndex);
        wineries[wineryOperationMappingID][uint(_productIndex)].parentList.push(
            IndexElem(harvestMappingID, -1));
        return true;
    }

    /// @notice TODO Commenti
    // TOCHECK AGGIUNGERE REQUIRE SU TIPO_OPERAZIONE = &#39;CASD&#39; ???
    function startWinery(
        string _harvestTrackID,
        string _offChainProducerIdentity,
        string _wineryTrackID,
        uint _productIndex
    )
        external
        wineriesOnly
    {
        require(_productIndex >= 0);
        address producer = getAddress(_offChainProducerIdentity);
        bytes32 harvestMappingID = keccak256(_harvestTrackID, producer);
        bytes32 wineryOperationMappingID = keccak256(_wineryTrackID, msg.sender);
        wineries[wineryOperationMappingID][_productIndex].parentList.push(
            IndexElem(harvestMappingID, -1));
    }

    /// @notice TODO Commenti
    // TOCHECK AGGIUNGERE REQUIRE SU TIPO_OPERAZIONE = &#39;CASD&#39; ???
    function startProduct(
        string _harvestTrackID,
        string _wineryTrackID,
        string _offChainWineryIdentity,
        int _productIndex
    )
        external
        producersOnly
    {
        require(_productIndex > 0);
        bytes32 harvestMappingID = keccak256(_harvestTrackID, msg.sender);
        address winery = getAddress(_offChainWineryIdentity);
        bytes32 wineryOperationMappingID = keccak256(_wineryTrackID, winery);
        harvests[harvestMappingID].child = IndexElem(wineryOperationMappingID, _productIndex);
    }

    /// @notice ***
    /// @dev ****
    /// @param _trackIDs **
    /// @param _address **
    /// @return mappingID if ***
    function getMappingID(string _trackIDs, address _address)
        external pure
        returns (bytes32 mappingID)
    {
        mappingID = keccak256(_trackIDs, _address);
    }

}