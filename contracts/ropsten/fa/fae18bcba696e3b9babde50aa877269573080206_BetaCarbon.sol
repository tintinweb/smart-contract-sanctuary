/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract BetaCarbon is ERC20Detailed {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    bool public paused = false;
    
    // ASSET PROTECTION DATA
    address public assetProtectionRole;
    mapping(address => bool) internal frozen;

    // SUPPLY CONTROL DATA
    address public supplyController;

    // OWNER DATA
    address public owner;
    address public proposedOwner;
    uint8 public constant DECIMALS = 18;
    bool public initialized = false;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("BetaCarbon", "NET1", DECIMALS) {
       
        initialize();
         _mint(0);
        pause();
    }
     function initialize() public {
        require(!initialized, "already initialized");
        owner = msg.sender;
        proposedOwner = address(0);
        assetProtectionRole = address(0);
        supplyController = msg.sender;
        initialized = true;
    }  

    // OWNABLE EVENTS
    event OwnershipTransferProposed(
        address indexed currentOwner,
        address indexed proposedOwner
    );
    event OwnershipTransferDisregarded(address indexed oldProposedOwner);
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    // PAUSABLE EVENTS
    event Pause();
    event Unpause();

// ASSET PROTECTION EVENTS
    event AddressFrozen(address indexed addr);
    event AddressUnfrozen(address indexed addr);
    event FrozenAddressWiped(address indexed addr);
    event AssetProtectionRoleSet(
        address indexed oldAssetProtectionRole,
        address indexed newAssetProtectionRole
    );

// SUPPLY CONTROL EVENTS
    event SupplyIncreased(address indexed to, uint256 value);
    event SupplyDecreased(address indexed from, uint256 value);
    event SupplyControllerSet(
        address indexed oldSupplyController,
        address indexed newSupplyController
    );
    
    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param me The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address me) public view returns (uint256) {
        return _balances[me];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param me address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address me, address spender) public view returns (uint256) {
        return _allowed[me][spender];
    }

    modifier whenNotPaused() {
        require(!paused, "whenNotPaused");
        _;
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
         require(to != address(0), "cannot transfer to address zero");
        require(!frozen[to] && !frozen[msg.sender], "address frozen");
        require(value <= _balances[msg.sender], "insufficient funds");
        _transfer(msg.sender, to, value);
        return true;
    }

   
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
         require(to != address(0), "cannot transfer to address zero");
        require(
            !frozen[to] && !frozen[from] && !frozen[msg.sender],
            "address frozen"
        );
        require(value <= _balances[from], "insufficient funds");
        require(value <= _allowed[from][msg.sender], "insufficient allowance");
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        //_approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "cannot transfer to address zero");

        require(value <= _balances[from], "insufficient funds");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

  

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param me The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address me, address spender, uint256 value) internal {
        require(spender != address(0));
        require(me != address(0));

        _allowed[me][spender] = value;
        emit Approval(me, spender, value);
    }

   

    modifier onlySupplyController() {
        require(msg.sender == supplyController, "onlySupplyController");
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(uint256 value) public onlySupplyController returns (bool) {
        _mint(value);
        return true;
    }
    
      /**
     * @dev Function to burn tokens

     * @param value The amount that will be burnt.
     * @return A boolean that indicates if the operation was successful.
     */
    function burn(uint256 value) public onlySupplyController returns (bool) {
        _burn(value);
        return true;
    }

     /**
     * @dev Increases the total supply by minting the specified number of tokens to the supply controller account.
     * @param _value The number of tokens to add.
     * @return A boolean that indicates if the operation was successful.
     */
    
    function _mint(uint256 _value)
        internal
        onlySupplyController
        returns (bool success)
    {
        _totalSupply = _totalSupply.add(_value);
        _balances[supplyController] = _balances[supplyController].add(_value);
        emit SupplyIncreased(supplyController, _value);
        emit Transfer(address(0), supplyController, _value);
        return true;
    }

     /**
     * @dev Decrease the total supply by burning the specified number of tokens to the supply controller account.
     * @param _value The number of tokens to burn.
     * @return A boolean that indicates if the operation was successful.
     */

     function _burn(uint256 _value)
        internal
        onlySupplyController
        returns (bool success)
    {
        require(_value <= _balances[supplyController], "not enough supply");
        //_value = _value* 10**18;
        _balances[supplyController] = _balances[supplyController].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit SupplyDecreased(supplyController, _value);
        emit Transfer(supplyController, address(0), _value);
        return true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }
     function pause() public onlyOwner {
        require(!paused, "already paused");
        paused = true;
        emit Pause();
    }

     function unpause() public onlyOwner {
        require(paused, "already unpaused");
        paused = false;
        emit Unpause();
    }

    /**
     * @dev Allows the current owner to begin transferring control of the contract to a proposedOwner
     * @param _proposedOwner The address to transfer ownership to.
    */

    function proposeOwner(address _proposedOwner) public onlyOwner {
        require(
            _proposedOwner != address(0),
            "cannot transfer ownership to address zero"
        );
        require(msg.sender != _proposedOwner, "caller already is owner");
        proposedOwner = _proposedOwner;
        emit OwnershipTransferProposed(owner, proposedOwner);
    }

    /**
     * @dev Allows the current owner or proposed owner to cancel transferring control of the contract to a proposedOwner
       commented out since this is not used
    */

    function disregardProposeOwner() public {
        require(
            msg.sender == proposedOwner || msg.sender == owner,
            "only proposedOwner or owner"
        );
        require(
            proposedOwner != address(0),
            "can only disregard a proposed owner that was previously set"
        );
        address _oldProposedOwner = proposedOwner;
        proposedOwner = address(0);
        emit OwnershipTransferDisregarded(_oldProposedOwner);
    }
 
    /**
     * @dev Allows the proposed owner to complete transferring control of the contract to the proposedOwner.
    */

    function claimOwnership() public {
        require(msg.sender == proposedOwner, "onlyProposedOwner");
        address _oldOwner = owner;
        owner = proposedOwner;
        proposedOwner = address(0);
        emit OwnershipTransferred(_oldOwner, owner);
    }  

      // ASSET PROTECTION FUNCTIONALITY

    /**
     * @dev Sets a new asset protection role address.
     * @param _newAssetProtectionRole The new address allowed to freeze/unfreeze addresses and seize their tokens.
     */

    function setAssetProtectionRole(address _newAssetProtectionRole) public {
        require(
            msg.sender == assetProtectionRole || msg.sender == owner,
            "only assetProtectionRole or Owner"
        );
        emit AssetProtectionRoleSet(
            assetProtectionRole,
            _newAssetProtectionRole
        );
        assetProtectionRole = _newAssetProtectionRole;
    }

    modifier onlyAssetProtectionRole() {
        require(msg.sender == assetProtectionRole, "onlyAssetProtectionRole");
        _;
    }

     /**
     * @dev Freezes an address balance from being transferred.
     * @param _addr The new address to freeze.
     */

    function freeze(address _addr) public onlyAssetProtectionRole {
        require(!frozen[_addr], "address already frozen");
        frozen[_addr] = true;
        emit AddressFrozen(_addr);
    }

    /**
     * @dev Unfreezes an address balance allowing transfer.
     * @param _addr The new address to unfreeze.
    */

    function unfreeze(address _addr) public onlyAssetProtectionRole {
        require(frozen[_addr], "address already unfrozen");
        frozen[_addr] = false;
        emit AddressUnfrozen(_addr);
    }

    /**
     * @dev Wipes the balance of a frozen address, burning the tokens
     * and setting the approval to zero.
     * @param _addr The new frozen address to wipe.
    */

    function wipeFrozenAddress(address _addr) public onlyAssetProtectionRole {
        require(frozen[_addr], "address is not frozen");
        uint256 _balance = _balances[_addr];
        _balances[_addr] = 0;
        _totalSupply = _totalSupply.sub(_balance);
        emit FrozenAddressWiped(_addr);
        emit SupplyDecreased(_addr, _balance);
        emit Transfer(_addr, address(0), _balance);
    }

    /**
     * @dev Gets whether the address is currently frozen.
     * @param _addr The address to check if frozen.
     * @return A bool representing whether the given address is frozen.
     */
    function isFrozen(address _addr) public view returns (bool) {
        return frozen[_addr];
    }
    // SUPPLY CONTROL FUNCTIONALITY

    /**
     * @dev Sets a new supply controller address.
     * @param _newSupplyController The address allowed to burn/mint tokens to control supply.
     */

    function setSupplyController(address _newSupplyController) public {
        require(
            msg.sender == supplyController || msg.sender == owner,
            "only SupplyController or Owner"
        );
        require(
            _newSupplyController != address(0),
            "cannot set supply controller to address zero"
        );
        emit SupplyControllerSet(supplyController, _newSupplyController);
        supplyController = _newSupplyController;
    }  
}