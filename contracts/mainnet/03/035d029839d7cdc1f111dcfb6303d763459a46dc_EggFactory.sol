pragma solidity ^0.4.18;

/// @title manages special access privileges.
/// @author Axiom Zen (https://www.axiomzen.co)
/// @dev See KittyAccessControl

contract AccessControl {
      /// @dev Emited when contract is upgraded - See README.md for updgrade plan
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

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

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
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
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCEO whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }
}

pragma solidity ^0.4.18;

contract EggFactory is AccessControl{
    
    event EggOpened(address eggOwner, uint256 eggId, uint256 amount);
    event EggBought(address eggOwner, uint256 eggId, uint256 amount);
    
    // @dev Sanity check that allows us to ensure that we are pointing to the
    //  right auction in our setEggFactoryAddress() call.
    bool public isEggFactory = true;

    address public vaultAddress;

    // @dev Scheme of egg
    struct EggScheme{
        uint256 id;
        uint256 stock; // max available eggs. zero for unlimited
        uint256 purchased; // purchased eggs
        uint256 customGene; // custom gene for future beast
        uint256 maxAllowedToBuy; // max amount allowed to buy on single transaction. zero for unnlimited
        
        uint256 increase; // price increase. zero for no increase
        uint256 price; // base price of the egg
        
        bool active; // is the egg active to be bought
        bool open; // is the egg active to be opened 
        bool isEggScheme;
    }

    // Mapping of existing eggs 
    // @dev: uint256 is the ID of the egg scheme
    mapping (uint256 => EggScheme) public eggs;
    uint256[] public eggsIndexes;
    
    uint256[] public activeEggs;
    mapping (uint256 => uint256) indexesActiveEggs;

    // Mapping of eggs owned by an address
    // @dev: owner => ( eggId => eggsAmount )
    mapping ( address => mapping ( uint256 => uint256 ) ) public eggsOwned;
    

    // Extend constructor
    function EggFactory(address _vaultAddress) public {
        vaultAddress = _vaultAddress;
        ceoAddress = msg.sender;
    }

    // Verify existence of id to avoid collision
    function eggExists( uint _eggId) internal view returns(bool) {
        return eggs[_eggId].isEggScheme;
    }

    function listEggsIds() external view returns(uint256[]){
        return eggsIndexes;
    }
    
    function listActiveEggs() external view returns(uint256[]){
        return activeEggs;
    }

    // Get the amount of purchased eggs of a struct
    function getPurchased(uint256 _eggId) external view returns(uint256){
        return eggs[_eggId].purchased;
    }

    // Set a new address for vault contract
    function setVaultAddress(address _vaultAddress) public onlyCEO returns (bool) {
        require( _vaultAddress != address(0x0) );
        vaultAddress = _vaultAddress;
    }
    
    function setActiveStatusEgg( uint256 _eggId, bool state ) public onlyCEO returns (bool){
        require(eggExists(_eggId));
        eggs[_eggId].active = state;

        if(state) {
            uint newIndex = activeEggs.push(_eggId);
            indexesActiveEggs[_eggId] = uint256(newIndex-1);
        }
        else {
            indexesActiveEggs[activeEggs[activeEggs.length-1]] = indexesActiveEggs[_eggId];
            activeEggs[indexesActiveEggs[_eggId]] = activeEggs[activeEggs.length-1]; 
            delete activeEggs[activeEggs.length-1];
            activeEggs.length--;
        }
        
        return true;
    }
    
    function setOpenStatusEgg( uint256 _eggId, bool state ) public onlyCEO returns (bool){
        require(eggExists(_eggId));
        eggs[_eggId].open = state;
        return true;
    }

    // Add modifier of onlyCOO
    function createEggScheme( uint256 _eggId, uint256 _stock, uint256 _maxAllowedToBuy, uint256 _customGene, uint256 _price, uint256 _increase, bool _active, bool _open ) public onlyCEO returns (bool){
        require(!eggExists(_eggId));
        
        eggs[_eggId].isEggScheme = true;
        
        eggs[_eggId].id = _eggId;
        eggs[_eggId].stock = _stock;
        eggs[_eggId].maxAllowedToBuy = _maxAllowedToBuy;
        eggs[_eggId].purchased = 0;
        eggs[_eggId].customGene = _customGene;
        eggs[_eggId].price = _price;
        eggs[_eggId].increase = _increase;
        
        setActiveStatusEgg(_eggId,_active);
        setOpenStatusEgg(_eggId,_open);
        
        eggsIndexes.push(_eggId);
        return true;
    }

    function buyEgg(uint256 _eggId, uint256 _amount) public payable returns(bool){
        require(eggs[_eggId].active == true);
        require((currentEggPrice(_eggId)*_amount) == msg.value);
        require(eggs[_eggId].maxAllowedToBuy == 0 || _amount<=eggs[_eggId].maxAllowedToBuy);
        require(eggs[_eggId].stock == 0 || eggs[_eggId].purchased+_amount<=eggs[_eggId].stock); // until max
        
        vaultAddress.transfer(msg.value); // transfer the amount to vault
        
        eggs[_eggId].purchased += _amount;
        eggsOwned[msg.sender][_eggId] += _amount;

        emit EggBought(msg.sender, _eggId, _amount);
    } 
    
    function currentEggPrice( uint256 _eggId ) public view returns (uint256) {
        return eggs[_eggId].price + (eggs[_eggId].purchased * eggs[_eggId].increase);
    }
    
    function openEgg(uint256 _eggId, uint256 _amount) external {
        require(eggs[_eggId].open == true);
        require(eggsOwned[msg.sender][_eggId] >= _amount);
        
        eggsOwned[msg.sender][_eggId] -= _amount;
        emit EggOpened(msg.sender, _eggId, _amount);
    }
}