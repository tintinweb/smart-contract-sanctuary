// CryptoRabbit Source code

pragma solidity ^0.4.18;





/// @title A base contract to control ownership
/// @author cuilichen
contract OwnerBase {

    // The addresses of the accounts that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;
    
    /// constructor
    function OwnerBase() public {
       ceoAddress = msg.sender;
       cfoAddress = msg.sender;
       cooAddress = msg.sender;
    }

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }


    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCFO The address of the new COO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

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
    function pause() external onlyCOO whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCOO whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }
}





/// @title all functions related to food
contract FoodStore is OwnerBase {
	/// event
	event Bought(address buyer, uint32 bundles);
	
	
    event ContractUpgrade(address newContract);

	
    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;
    
    // Price (in wei) for food
    uint public price = 10 finney;    
    
    
    

    /// @notice 
    function FoodStore() public {
        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
    }
    
        
    /// @notice customer buy food
    /// @param _bundles The num of food
    function buyFood(uint32 _bundles) external payable whenNotPaused returns (bool) {
		require(newContractAddress == address(0));
		
        uint cost = _bundles * price;
		require(msg.value >= cost);
		
        // Return the funds. 
        uint fundsExcess = msg.value - cost;
        if (fundsExcess > 1 finney) {
            msg.sender.transfer(fundsExcess);
        }
		emit Bought(msg.sender, _bundles);
        return true;
    }
    
    

    /// @dev Used to mark the smart contract as upgraded.
    /// @param _v2Address new address
    function upgradeContract(address _v2Address) external onlyCOO whenPaused {
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

    // @dev Allows the CEO to capture the balance available to the contract.
    function withdrawBalance() external onlyCFO {
        address tmp = address(this);
        cfoAddress.transfer(tmp.balance);
    }
}