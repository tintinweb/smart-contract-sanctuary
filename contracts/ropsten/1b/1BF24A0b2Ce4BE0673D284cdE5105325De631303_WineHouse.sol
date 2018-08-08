pragma solidity ^0.4.21;

contract WineHouse {
    address public owner;
    bytes32[] public wineIndices;
    mapping (bytes32 => WineData) private wines;
    mapping (address => bool) private trustedPartners;
    mapping (address => OwnerInfo) private wineOwners;
    
    constructor() public {
        owner = msg.sender;
    }
    
    struct OwnerInfo {
        string name;
        string proofOfIdentity;
        bool isVerified;
        bytes32[] ownedWines;
        mapping (bytes32 => bool) wines;
        mapping (bytes32 => uint) ownedWinesIndices;
    }
    
    struct WineData {
        string cork;
        string capsule;
        string glass;
        string frontLabel;
        string backLabel;
        string bottle;
        address currentOwner;
        address[] ownerHistory;
        uint index;
        bool isActive;
    }

    function transferContract(address _to) public onlyMaster {
        owner = _to;
    }
    
    modifier onlyMaster() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyTrustedPartner() {
        require(trustedPartners[msg.sender] == true);
        _;
    }
    
    modifier onlyAssetOwner(bytes32 _uniqueIdentifier) {
        require(wineOwners[msg.sender].wines[_uniqueIdentifier] == true);
        _;
    }
    
    modifier onlyVerified() {
        require(wineOwners[msg.sender].isVerified == true);
        _;
    }

    modifier wineShouldNotExist(bytes32 _uniqueIdentifier) {
        require(wines[_uniqueIdentifier].isActive == false);
        _;
    }
    
    function getWineCount() view public returns (uint count) {
        return wineIndices.length;
    }

    function getOwnedWineCountOf(address _wineOwner) view public returns (uint) {
        return wineOwners[_wineOwner].ownedWines.length;
    }

    function getWineIdentifierAt(address _wineOwner, uint _index) view public returns (bytes32) {
        return wineOwners[_wineOwner].ownedWines[_index];
    }

    function getOwnerHistoryAt(bytes32 _uniqueIdentifier, uint _index) view public returns (address) {
        return wines[_uniqueIdentifier].ownerHistory[_index];
    }

    function getOwnerHistoryCountOf(bytes32 _uniqueIdentifier) view public returns (uint count) {
        return wines[_uniqueIdentifier].ownerHistory.length;
    }

    event NewWineOwner(address _ownerAddress, string _name);
    event NewTrustedPartner(address _partnerAddress, string _name);
    event RemovedTrustedPartner(address _partnerAddress);
    event NewWine(bytes32 _uniqueIdentifier);
    event WineTransfer(address _to, bytes32 _uniqueIdentifier);
    
    // ===============================================================
    
    function registerWineOwner(
        address _ownerAddress, 
        string _name,
        string _proofOfIdentity
        ) public onlyMaster
        returns (
            address, string, bool
        ) {
        
        wineOwners[_ownerAddress].name = _name;
        wineOwners[_ownerAddress].isVerified = true;
        wineOwners[_ownerAddress].proofOfIdentity = _proofOfIdentity;

        emit NewWineOwner(_ownerAddress, _name);

        return (
            _ownerAddress, 
            wineOwners[_ownerAddress].name, 
            wineOwners[_ownerAddress].isVerified
        );

    }

    function getWineOwner(address _ownerAddress) view public returns (address, string, bool, string) {
        return (
            _ownerAddress,
            wineOwners[_ownerAddress].name,
            wineOwners[_ownerAddress].isVerified,
            wineOwners[_ownerAddress].proofOfIdentity
        );
    }
    
    function addTrustedPartner(address _partnerAddress, string _name, string _proofOfIdentity) public onlyMaster returns (address, bool) {
        trustedPartners[_partnerAddress] = true;
        wineOwners[_partnerAddress].name = _name;
        wineOwners[_partnerAddress].isVerified = true;
        wineOwners[_partnerAddress].proofOfIdentity = _proofOfIdentity;
        registerWineOwner(_partnerAddress, _name, _proofOfIdentity);
        
        emit NewTrustedPartner(_partnerAddress, _name);

        return (_partnerAddress, trustedPartners[_partnerAddress]);
    }

    function getTrustedPartner(address _partner) view public returns (address, bool) {
        return (_partner, trustedPartners[_partner]);
    }
    
    function removeTrustedPartner(address _partner) public onlyMaster returns (address ,bool) {
        trustedPartners[_partner] = false;

        emit RemovedTrustedPartner(_partner);

        return (_partner, trustedPartners[_partner]);
    }
    
    function createWine(
        string _cork,
        string _capsule,
        string _glass,
        string _frontLabel,
        string _backLabel,
        string _bottle,
        bytes32 _uniqueIdentifier
    ) public onlyTrustedPartner wineShouldNotExist(_uniqueIdentifier)
        returns (
            uint index, 
            bytes32 uniqueIdentifier, 
            bool isActive
        ) {
        
        bytes32 uniqueIdentCheck = keccak256(abi.encodePacked(_backLabel, "|",  _bottle, "|", _capsule, "|", _cork, "|", _frontLabel, "|", _glass));
            
        require(
            keccak256(abi.encodePacked(uniqueIdentCheck)) == keccak256(abi.encodePacked(_uniqueIdentifier))
        );
        
        wines[_uniqueIdentifier].cork = _cork;
        wines[_uniqueIdentifier].capsule = _capsule;
        wines[_uniqueIdentifier].glass = _glass;
        wines[_uniqueIdentifier].frontLabel = _frontLabel;
        wines[_uniqueIdentifier].backLabel = _backLabel;
        wines[_uniqueIdentifier].bottle = _bottle;
        
        wines[_uniqueIdentifier].currentOwner = msg.sender;
        
        wines[_uniqueIdentifier].isActive = true;
        wines[_uniqueIdentifier].index = wineIndices.length;
        
        wineIndices.push(_uniqueIdentifier);

        wineOwners[msg.sender].wines[_uniqueIdentifier] = true;
        wineOwners[msg.sender].ownedWines.push(_uniqueIdentifier);
        wineOwners[msg.sender].ownedWinesIndices[_uniqueIdentifier] = wineOwners[msg.sender].ownedWines.length;

        emit NewWine(_uniqueIdentifier);
        
        return (wineIndices.length - 1, _uniqueIdentifier, wines[_uniqueIdentifier].isActive);
    }
    
    function transferWine(address _to, bytes32 _uniqueIdentifier) 
        public onlyAssetOwner(_uniqueIdentifier) onlyVerified() {
            
        wines[_uniqueIdentifier].ownerHistory.push(wines[_uniqueIdentifier].currentOwner);
        wineOwners[wines[_uniqueIdentifier].currentOwner].wines[_uniqueIdentifier] = false;
        
        wines[_uniqueIdentifier].currentOwner = _to;

        uint totalElementCount = getOwnedWineCountOf(msg.sender);
        uint index = wineOwners[msg.sender].ownedWinesIndices[_uniqueIdentifier] - 1;

        bytes32 lastElement = wineOwners[msg.sender].ownedWines[totalElementCount - 1];
        wineOwners[msg.sender].ownedWines[index] = lastElement;
        wineOwners[msg.sender].ownedWines.length = totalElementCount - 1;

        wineOwners[_to].ownedWines.push(_uniqueIdentifier);
        wineOwners[_to].wines[_uniqueIdentifier] = true;

        delete wineOwners[msg.sender].ownedWinesIndices[_uniqueIdentifier];

        emit WineTransfer(_to, _uniqueIdentifier);
    }
    
    function retrieveWineData(bytes32 _uniqueIdentifier) view public 
        returns (
            string cork,
            string capsule,
            string glass,
            string frontLabel,
            string backLabel,
            string bottle,
            address currentOwner
        ) {
        return (
            wines[_uniqueIdentifier].cork,
            wines[_uniqueIdentifier].capsule,
            wines[_uniqueIdentifier].glass,
            wines[_uniqueIdentifier].frontLabel,
            wines[_uniqueIdentifier].backLabel,
            wines[_uniqueIdentifier].bottle,
            wines[_uniqueIdentifier].currentOwner
        );   
    }
}