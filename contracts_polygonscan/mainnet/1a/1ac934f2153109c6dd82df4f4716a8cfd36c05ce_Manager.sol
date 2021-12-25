/**
 *Submitted for verification at polygonscan.com on 2021-12-25
*/

// File: interfaces/IRoleAccess.sol



pragma solidity ^0.8.0;

interface IRoleAccess {
    function isAdmin(address user) view external returns (bool);
    function isDeployer(address user) view external returns (bool);
    function isConfigurator(address user) view external returns (bool);
    function isApprover(address user) view external returns (bool);
    function isRole(string memory roleName, address user) view external returns (bool);
}

// File: interfaces/IManager.sol



pragma solidity ^0.8.0;


interface IManager {
    function addCampaign(address newContract, address distributor, address newNFTContract) external;   
    function getRoles() external view returns (IRoleAccess);
}


// File: Manager.sol



pragma solidity ^0.8.0;



contract Manager is IManager {

    IRoleAccess private _roles;
    address private _feeVault;
    
    enum Status {
        Inactive,
        Active,
        Cancelled
    }

     modifier onlyFactory() {
        require(_factoryMap[msg.sender], "Errors.NOT_FACTORY");
        _;
    }
    
    modifier onlyAdmin() {
        require(_roles.isAdmin(msg.sender), "Errors.NOT_ADMIN");
        _;
    }
    
    // Events
    event FactoryRegistered(address indexed deployedAddress);
    event CampaignAdded(address indexed contractAddress);
    event CampaignCancelled(address indexed contractAddress);

    struct CampaignInfo {
        address contractAddress;
        address distributor;
        address deedNFT;
        Status status;
    }

    
    // History & list of factories.
    mapping(address => bool) private _factoryMap;
    address[] private _factories;
    
    // History/list of all IDOs
    mapping(uint => CampaignInfo) private _indexCampaignMap; // Starts from 1. Zero is invalid //
    mapping(address => uint) private _addressIndexMap;  // Maps a campaign address to an index in _indexCampaignMap.
    uint private _count;
    
    
    constructor(IRoleAccess rolesRegistry) {
        _roles = rolesRegistry;
    }
    
    
    //--------------------//
    // EXTERNAL FUNCTIONS //
    //--------------------//
    
    function getCampaignInfo(uint id) external view returns (CampaignInfo memory) {
        return _indexCampaignMap[id];
    }
    
    
    function getTotalCampaigns() external view returns (uint) {
        return _count;
    }
    
    function registerFactory(address newFactory) external onlyAdmin {
        if ( _factoryMap[newFactory] == false) {
            _factoryMap[newFactory] = true;
            _factories.push(newFactory);
            emit FactoryRegistered(newFactory);
        }
    }
    
    function isFactory(address contractAddress) external view returns (bool) {
        return _factoryMap[contractAddress];
    }
    
    function getFactory(uint id) external view returns (address) {
        return (  (id < _factories.length) ? _factories[id] : address(0) );
    }

    function cancelCampaign(address contractAddress) external onlyAdmin {
        uint index = _addressIndexMap[contractAddress];
        CampaignInfo storage info = _indexCampaignMap[index];
        // Update status if campaign is exist & active
        if (info.status == Status.Active) {
            info.status = Status.Cancelled;         
            emit CampaignCancelled(contractAddress);
        }
    }

    //------------------------//
    // IMPLEMENTS IManager    //
    //------------------------//
    
    function addCampaign(address newContract, address distributor, address newNFTContract) external override onlyFactory {
        _count++;
        _indexCampaignMap[_count] = CampaignInfo(newContract, distributor, newNFTContract, Status.Active);
        _addressIndexMap[newContract] = _count;
        emit CampaignAdded(newContract);
    }
    
    function getRoles() external view override returns (IRoleAccess) {
        return _roles;
    }
}