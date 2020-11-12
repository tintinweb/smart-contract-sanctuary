/*
██╗     ███████╗██╗  ██╗    
██║     ██╔════╝╚██╗██╔╝    
██║     █████╗   ╚███╔╝     
██║     ██╔══╝   ██╔██╗     
███████╗███████╗██╔╝ ██╗    
╚══════╝╚══════╝╚═╝  ╚═╝    
██╗     ██╗███████╗████████╗
██║     ██║██╔════╝╚══██╔══╝
██║     ██║███████╗   ██║   
██║     ██║╚════██║   ██║   
███████╗██║███████║   ██║   
╚══════╝╚═╝╚══════╝   ╚═╝*/
pragma solidity 0.5.17;

contract LexList {
    address public governance;
    address[] private listings;
    string public message;
    mapping(address => Contract) private contractList;
    
    event List(address indexed _contract);
    event Delist(address indexed _contract);
    event UpdateGovernance(address indexed governance);
    event UpdateMessage(string indexed message);
    
    struct Contract {
        uint256 contractIndex;
        bool listed;
    }
    
    constructor (address[] memory _contract, address _governance, string memory _message) public {
        for (uint256 i = 0; i < _contract.length; i++) {
            contractList[_contract[i]].contractIndex = listings.push(_contract[i]) - 1;
            contractList[_contract[i]].listed = true;
        }
        
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
    function delist(address[] calldata _contract) external onlyGovernance {
        for (uint256 i = 0; i < _contract.length; i++) {
            require(contractList[_contract[i]].listed, "!listed");
            
            uint256 contractToUnlist = contractList[_contract[i]].contractIndex;
            address k = listings[listings.length - 1];
            listings[contractToUnlist] = k;
            contractList[k].contractIndex = contractToUnlist;
            contractList[_contract[i]].listed = false;
            listings.length--;
            
            emit Delist(_contract[i]);
        }
    }
    
    function list(address[] calldata _contract) external onlyGovernance { 
        for (uint256 i = 0; i < _contract.length; i++) {
            require(!contractList[_contract[i]].listed, "listed");
            
            contractList[_contract[i]].contractIndex = listings.push(_contract[i]) - 1;
            contractList[_contract[i]].listed = true;
            
            emit List(_contract[i]);
        }
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
    function contractCount() external view returns (uint256) {
        return listings.length;
    }
    
    function isListed(address _contract) external view returns (bool) {
        if(listings.length == 0) return false;
        return (listings[contractList[_contract].contractIndex] == _contract);
    }
}