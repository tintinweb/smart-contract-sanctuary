/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

// Spent ETH Oracle for Reeth
// This oracle collects eth data from various whitelisted data sources to generate a database of eth spent data for users
// The ETH spent data will be used by the Reeth Claimer to determine how much cashback to reward to zs-Reeth holders
// 
// Governance can update whitelisted addresses, change eth spent balances per user and update the iteration of the oracle (which resets all balances to 0)

pragma solidity =0.6.6;

contract GenericSpentETHOracle {

    address public governance;
    uint256 private _globalIteration; // This resets all the balances back to 0
    
    mapping(address => UserInfo) private allUsersInfo;
    mapping(address => bool) private providers; // This will be a list of all providers eligible
    
    event GovernanceUpdated(address _add);
    event ProviderAdded(address _add);
    event ProviderRemoved(address _add);
    event NewIteration(uint256 _iter);
    event UserETHSpentUpdated(address _updater, address _user, uint256 _amount);
    
    // Structs
    struct UserInfo {
        uint256 ethSpent; // The amount of eth spent since last claim
        uint256 iteration; // The iteration version of the user
    }

    constructor() public {
        governance = msg.sender;
    }
    
    modifier onlyGovernance() {
        require(governance == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function getCurrentIteration() external view returns (uint256) {
        return _globalIteration;
    }
    
    function getUserETHSpent(address _add) external view returns (uint256) {
        if(allUsersInfo[_add].iteration < _globalIteration){
            return 0; // The user is on an old iteration of this oracle
        }else{
            return allUsersInfo[_add].ethSpent; // Get the eth septn
        }
    }
    
    function getUserIteration(address _add) external view returns (uint256) {
        return allUsersInfo[_add].iteration;
    }
    
    function isAddressProvider(address _add) public view returns (bool) {
        return providers[_add];
    }
    
    // Write functions
    // Whitelisted contracts can call this oracle to update the amount the user spent to perform a call
    function addUserETHSpent(address _add, uint256 _ethback) external returns (bool) {
        if(isAddressProvider(msg.sender) == false){
            return false; // Don't revert, just return false instead
        }
        if(allUsersInfo[_add].iteration < _globalIteration){
            allUsersInfo[_add].iteration = _globalIteration;
            allUsersInfo[_add].ethSpent = 0;
        }
        allUsersInfo[_add].ethSpent = allUsersInfo[_add].ethSpent + _ethback; // Overflow is ok
        emit UserETHSpentUpdated(msg.sender, _add, _ethback); // Create an event
        return true; // This function will never revert so safe to be integrated
    }
    
    // Governance functions
    function updateGovernanceAddress(address _add) external onlyGovernance {
        require(_add != address(0), "Can't set to 0 address");
        governance = _add;
        emit GovernanceUpdated(_add);
    }
    
    function governanceUpdateUserETHSpent(address _add, uint256 amount) external onlyGovernance {
        // Governance can update users balances manually in case of errors
        allUsersInfo[_add].iteration = _globalIteration; // Set to the current iteration
        allUsersInfo[_add].ethSpent = amount;
    }
    
    function governanceAddToProviders(address _add) external onlyGovernance {
        providers[_add] = true;
        emit ProviderAdded(_add);
    }
    
    function governanceRemoveFromProviders(address _add) external onlyGovernance {
        providers[_add] = false;
        emit ProviderRemoved(_add);
    }
    
    function governanceNewIteration() external onlyGovernance {
        // This will reset all ETH spends back to zero
        _globalIteration = _globalIteration + 1;
        emit NewIteration(_globalIteration);
    }
    
}