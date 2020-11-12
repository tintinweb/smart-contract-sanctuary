/*
██╗     ███████╗██╗  ██╗
██║     ██╔════╝╚██╗██╔╝
██║     █████╗   ╚███╔╝ 
██║     ██╔══╝   ██╔██╗ 
███████╗███████╗██╔╝ ██╗
╚══════╝╚══════╝╚═╝  ╚═╝
 █████╗ ██╗██████╗      
██╔══██╗██║██╔══██╗     
███████║██║██████╔╝     
██╔══██║██║██╔══██╗     
██║  ██║██║██║  ██║     
╚═╝  ╚═╝╚═╝╚═╝  ╚═╝*/
pragma solidity 0.5.17;

interface IERC20 { // brief interface for erc20 token tx
    function balanceOf(address account) external view returns (uint256);
}

contract LexAIR {
    address public accessToken;
    address public governance;
    address[] private registrations;
    string public message;
    mapping(address => Registry) private registryList;
    
    event Register(address indexed account, bytes32 indexed message);
    event Deregister(address indexed account, bytes32 message);
    event UpdateAccessToken(address indexed accessToken);
    event UpdateGovernance(address indexed governance);
    event UpdateMessage(string indexed message);
    
    struct Registry {
        uint256 accountIndex;
        bool registered;
    }
    
    constructor (address[] memory _account, address _accessToken, address _governance, string memory _message) public {
        for (uint256 i = 0; i < _account.length; i++) {
            registryList[_account[i]].accountIndex = registrations.push(_account[i]) - 1;
            registryList[_account[i]].registered = true;
        }
        
        accessToken = _accessToken;
        governance = _governance;
        message = _message;
    }
    
    modifier onlyGovernance {
        require(msg.sender == governance, "!governance");
        _;
    }
    
    /****************
    LISTING FUNCTIONS
    ****************/
    function delist(address[] calldata _account, bytes32 _message) external {
        require(IERC20(accessToken).balanceOf(msg.sender) >= 1, "!access");
        
        for (uint256 i = 0; i < _account.length; i++) {
            require(registryList[_account[i]].registered, "!registered");
            
            uint256 accountToUnlist = registryList[_account[i]].accountIndex;
            address acct = registrations[registrations.length - 1];
            registrations[accountToUnlist] = acct;
            registryList[acct].accountIndex = accountToUnlist;
            registryList[_account[i]].registered = false;
            registrations.length--;
            
            emit Deregister(_account[i], _message);
        }
    }
    
    function list(address[] calldata _account, bytes32 _message) external { 
        require(IERC20(accessToken).balanceOf(msg.sender) >= 1, "!access");
        
        for (uint256 i = 0; i < _account.length; i++) {
            require(!registryList[_account[i]].registered, "registered");
            
            registryList[_account[i]].accountIndex = registrations.push(_account[i]) - 1;
            registryList[_account[i]].registered = true;
            
            emit Register(_account[i], _message);
        }
    }
    
    function updateAccessToken(address _accessToken) external onlyGovernance {
        accessToken = _accessToken;
        
        emit UpdateAccessToken(accessToken);
    }
    
    
    function updateGovernance(address _governance) external onlyGovernance {
        governance = _governance;
        
        emit UpdateGovernance(governance);
    }
    
    function updateMessage(string calldata _message) external onlyGovernance {
        message = _message;
        
        emit UpdateMessage(message);
    }
    
    // *******
    // GETTERS
    // *******
    function accountCount() external view returns (uint256) {
        return registrations.length;
    }
    
    function isRegistered(address _account) external view returns (bool) {
        if(registrations.length == 0) return false;
        return (registrations[registryList[_account].accountIndex] == _account);
    }
}