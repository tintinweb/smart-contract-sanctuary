/**
 *Submitted for verification at polygonscan.com on 2021-11-08
*/

// File: contracts/token/ERC20/IERC20.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, basic interface.
 * @dev See https://eips.ethereum.org/EIPS/eip-20
 * @dev Note: The ERC-165 identifier for this interface is 0x36372b07.
 */
interface IERC20 {
    /**
     * @dev Emitted when tokens are transferred, including zero value transfers.
     * @param _from The account where the transferred tokens are withdrawn from.
     * @param _to The account where the transferred tokens are deposited to.
     * @param _value The amount of tokens being transferred.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * @dev Emitted when a successful call to {IERC20-approve(address,uint256)} is made.
     * @param _owner The account granting an allowance to `_spender`.
     * @param _spender The account being granted an allowance from `_owner`.
     * @param _value The allowance amount being granted.
     */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * @notice Returns the total token supply.
     * @return The total token supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the account balance of another account with address `owner`.
     * @param owner The account whose balance will be returned.
     * @return The account balance of another account with address `owner`.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * Transfers `value` amount of tokens to address `to`.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender does not have enough balance.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice Transfers `value` amount of tokens from address `from` to address `to`.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `from` does not have at least `value` of balance.
     * @dev Reverts if the sender is not `from` and has not been approved by `from` for at least `value`.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param from The emitter account.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * Sets `value` as the allowance from the caller to `spender`.
     *  IMPORTANT: Beware that changing an allowance with this method brings the risk
     *  that someone may use both the old and the new allowance by unfortunate
     *  transaction ordering. One possible solution to mitigate this race
     *  condition is to first reduce the spender's allowance to 0 and set the
     *  desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @dev Reverts if `spender` is the zero address.
     * @dev Emits the {IERC20-Approval} event.
     * @param spender The account being granted the allowance by the message caller.
     * @param value The allowance amount to grant.
     * @return True if the approval succeeds, false otherwise.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * Returns the amount which `spender` is allowed to spend on behalf of `owner`.
     * @param owner The account that has granted an allowance to `spender`.
     * @param spender The account that was granted an allowance by `owner`.
     * @return The amount which `spender` is allowed to spend on behalf of `owner`.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}

// File: contracts/interfaces/IGBotInventory.sol



pragma solidity >=0.7.6 <0.8.0;

interface IGBotInventory {
    function mintGBot(address to, uint256 nftId, uint256 metadata, bytes memory data) external;
    function getMetadata(uint256 tokenId) external view returns (uint256 metadata);
    function upgradeGBot(uint256 newMetadata, uint256 tokenId) external;

    /**
     * Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return balance uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * Gets the owner of the specified ID
     * @param tokenId uint256 ID to query the owner of
     * @return owner address currently marked as the owner of the given ID
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

        /**
     * Safely transfers the ownership of a given token ID to another address
     *
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
// File: contracts/utils/access/IERC173.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC-173 Contract Ownership Standard
 * Note: the ERC-165 identifier for this interface is 0x7f5828d0
 */
interface IERC173 {
    /**
     * Event emited when ownership of a contract changes.
     * @param previousOwner the previous owner.
     * @param newOwner the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * Get the address of the owner
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * Set the address of the new owner of the contract
     * Set newOwner to address(0) to renounce any ownership.
     * @dev Emits an {OwnershipTransferred} event.
     * @param newOwner The address of the new owner of the contract. Using the zero address means renouncing ownership.
     */
    function transferOwnership(address newOwner) external;
}

// File: contracts/metatx/ManagedIdentity.sol



pragma solidity >=0.7.6 <0.8.0;

/*
 * Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner.
 */
abstract contract ManagedIdentity {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}
// File: contracts/utils/Pausable.sol



pragma solidity >=0.7.6 <0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is ManagedIdentity {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

     /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
// File: contracts/utils/access/Ownable.sol



pragma solidity >=0.7.6 <0.8.0;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is ManagedIdentity, IERC173 {
    address internal _owner;

    /**
     * Initializes the contract, setting the deployer as the initial owner.
     * @dev Emits an {IERC173-OwnershipTransferred(address,address)} event.
     */
    constructor(address owner_) {
        _owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    /**
     * Gets the address of the current contract owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * See {IERC173-transferOwnership(address)}
     * @dev Reverts if the sender is not the current contract owner.
     * @param newOwner the address of the new owner. Use the zero address to renounce the ownership.
     */
    function transferOwnership(address newOwner) public virtual override {
        _requireOwnership(_msgSender());
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    /**
     * @dev Reverts if `account` is not the contract owner.
     * @param account the account to test.
     */
    function _requireOwnership(address account) internal virtual {
        require(account == this.owner(), "Ownable: not the owner");
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}
// File: contracts/token/ERC721/IERC721Receiver.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC721 Non-Fungible Token Standard, Tokens Receiver.
 * Interface for any contract that wants to support safeTransfers from ERC721 asset contracts.
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 * @dev Note: The ERC-165 identifier for this interface is 0x150b7a02.
 */
interface IERC721Receiver {
    /**
     * Handles the receipt of an NFT.
     * @dev The ERC721 smart contract calls this function on the recipient
     *  after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     *  otherwise the caller will revert the transaction. The selector to be
     *  returned can be obtained as `this.onERC721Received.selector`. This
     *  function MAY throw to revert and reject the transfer.
     * @dev Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/game/GBotUpgrader/GBotUpgraderMock.sol



pragma solidity >=0.7.6 <0.8.0;






contract GBotUpgraderMock is IERC721Receiver, Ownable, Pausable {
    
IGBotInventory private gBotContract;
IERC20 payToken;
address payable public payoutWallet;
mapping(address => uint[]) private previousOwners;

 struct COP {
        uint256 strength;
        uint256 speed;
        uint256 battery;
        uint256 HP;
        uint256 attack;
        uint256 defense;
        uint256 critical;
        uint256 luck;
        uint256 special;
    }


// Constants
uint256 internal constant STRENGTH_BITS = 166; //8
uint256 internal constant SPEED_BITS = 158; //8
uint256 internal constant BATTERY_BITS = 150; //8
uint256 internal constant HP_BITS = 142; //8
uint256 internal constant ATTACK_BITS = 134; //8
uint256 internal constant DEFENSE_BITS = 126; //8
uint256 internal constant CRITICAL_BITS = 118; //8
uint256 internal constant LUCK_BITS = 110; //8
uint256 internal constant SPECIAL_BITS = 102; //8

// Bitwise operations
    uint constant internal ONE = uint(1);
    uint constant internal ONES = uint(~0);
    uint256 internal constant VISUALS_BITS = 206;

//Events
event GBotReceived(address indexed operator,
        address indexed from,
        uint256 tokenId,
        bytes indexed data);
event GBotReturned(uint256 indexed tokenId, address indexed owner);
event GBotUpgraded(address indexed owner, uint256 tokenId, uint256 cost, uint256 newMetadata);

constructor(
        address gBotInventory_,
        address payToken_,
        address payable payoutWallet_
    ) Ownable(msg.sender) {
        require(payoutWallet_ != address(0), "Payout: zero address");
        require(payToken_ != address(0), "PayToken: zero address");
        payoutWallet = payoutWallet_;
        payToken = IERC20(payToken_);
        gBotContract = IGBotInventory(gBotInventory_);
    }


function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external virtual override whenNotPaused returns (bytes4) {
        emit GBotReceived(operator,from,tokenId,data);
        return this.onERC721Received.selector;
    }


function upgradeGBot(
    uint256 newMetadata,
    uint256 tokenId)
     public virtual {
        // Check owner
        address owner = gBotContract.ownerOf(tokenId);
        require(owner==msg.sender, "Upgrader: Not the rightful owner");

        // Get metadata
        uint256 metadata = gBotContract.getMetadata(tokenId);
        
        //Get COP for current metadata
        uint256 currentCop = calculateCop(metadata);
        //Get COP for new metadata
        uint256 newCop = calculateCop(newMetadata);

        // Calculate cost
        uint256 cost = (newCop-currentCop) * 5 ether;
        uint256 balance = payToken.balanceOf(msg.sender);
        require(cost <= balance, "Not enough GMEE");

        // Check allowance
        uint256 allowance = payToken.allowance(msg.sender, address(this));
        require(allowance >= cost, "Check the token allowance");        
        
        // Upgrade properties
        gBotContract.upgradeGBot(newMetadata, tokenId);

        // Pay in GMEE
        payToken.transferFrom(msg.sender, payoutWallet, cost);
        
        // Transfer token to the Upgrader
        gBotContract.safeTransferFrom(msg.sender, address(this), tokenId);

        // Save owner to owners
        previousOwners[msg.sender].push(tokenId);
        emit GBotUpgraded(msg.sender, tokenId, cost, newMetadata);
}

function returnGBot(uint256 tokenId) public {
        bool isOwner = isRightfulOwner(tokenId);
        require(isOwner==true, "Upgrader: Not the rightful owner");
        gBotContract.safeTransferFrom(address(this), msg.sender, tokenId);
        emit GBotReturned(tokenId,msg.sender);
    }

function addRightfulOwner(address _owner, uint256 tokenId) private {
    previousOwners[_owner].push(tokenId);
}

function getGBotsForUser(address _owner) public view returns (uint[] memory) {
    return previousOwners[_owner];
}

function isRightfulOwner(uint256 tokenId) private view returns (bool){
    uint[] memory tokenIds = previousOwners[msg.sender];
    uint arrayLength = tokenIds.length;
    for (uint i=0; i<arrayLength; i++) {
        if(tokenIds[i]==tokenId){
            return true;
        }
    }
    return false;
}

function getTokenPosition(uint[] memory tokenIds, uint256 tokenId) private pure returns (uint256){
    uint arrayLength = tokenIds.length;
    for (uint i=0; i<arrayLength; i++) {
        if(tokenIds[i]==tokenId){
            return i;
        }
    }
    return 0;
}


 function getMetadataForProperty(uint256 metadataId, uint256 position) internal pure returns (uint256) {
       uint bits = 8;
       if (position == VISUALS_BITS) {
            bits = 16;
        }
       require(0 < bits && position < 256 && position + bits <= 256);
        return metadataId >> position & ONES >> 256 - bits;
   }

    function calculateCop(uint256 metadata) private pure returns (uint256){
        COP memory copData;
        copData.strength= getMetadataForProperty(metadata, STRENGTH_BITS);
        copData.speed= getMetadataForProperty(metadata, SPEED_BITS);
        copData.battery= getMetadataForProperty(metadata, BATTERY_BITS);
        copData.HP= getMetadataForProperty(metadata, HP_BITS);
        copData.attack= getMetadataForProperty(metadata, ATTACK_BITS);
        copData.defense= getMetadataForProperty(metadata, DEFENSE_BITS);
        copData.critical= getMetadataForProperty(metadata, CRITICAL_BITS);
        copData.luck = getMetadataForProperty(metadata, LUCK_BITS);
        copData.special = getMetadataForProperty(metadata, SPECIAL_BITS);
        uint256 sum = (copData.strength+copData.speed+copData.battery+copData.HP+copData.attack+copData.defense+copData.critical+copData.luck+copData.special);
        return sum/9;
    }
}