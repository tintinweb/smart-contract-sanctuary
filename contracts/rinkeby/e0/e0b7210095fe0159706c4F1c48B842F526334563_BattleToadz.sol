/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/battletoadz.sol


pragma solidity ^0.8.0;






contract BattleToadz is Ownable, IERC721Receiver, Pausable {

    event DepositedToad(address indexed _owner, uint toadId);
    event WithdrewToad(address _owner, uint toadId);
    event DepositedStack(address _owner, uint amount);
    event WithdrewStack(address _owner, uint amount);

    event OfferedToadFight(address _owner, uint16 toadId);
    event OfferedStackFight(address _owner, uint16 toadId, uint16 stack);
    event CancelToadFight(address _owner, uint16 toadId);
    event CancelStackFight(address _owner, uint16 toadId);
    event WonToadFight(address indexed _owner, uint16 toadId, uint16 indexed victim);
    event WonStackFight(address indexed _owner, uint16 toadId, uint16 victim, uint16 stack);
    

    address public stackedtoadzaddress;
    address public stackaddress;

    uint16 public stackPerFight = 1000; //Needs to be multiple of 100;
    uint256 public fightFee = uint256(stackPerFight) * 10 ** 18;

    mapping (uint16 => address) toadOwner;
    mapping (address => uint16) stackOwned; // 1 = 100 stack

    mapping (uint16 => bool) toadReadyToFight;
    mapping (uint16 => uint16) toadReadyForStackFight;


    constructor(
      address _stackedtoadzaddress,
      address _stackaddress
    ) {
        stackedtoadzaddress = _stackedtoadzaddress;
        stackaddress = _stackaddress;
        approveStack();  
    }

    function approveStack() private { 
      IERC20(stackaddress).approve(address(this), 9999999999999999999999999);
    }

    function setStackedToadAddress(address addy) public onlyOwner {
        stackedtoadzaddress = addy;
    }

    function setStackAddress(address addy) public onlyOwner {
        stackaddress = addy;
    }

    function setStackPerFight(uint16 amt) public onlyOwner {
        require(amt % 100 == 0, "Amount must be a multiple of 100");
        stackPerFight = amt;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    modifier ownsToad(uint16 toadId) {
        require(msg.sender == toadOwner[toadId], "You don't own this toad or it's not staked");
        _;
    }

    function depositToads(uint[] calldata toadIds) public whenNotPaused {
        for(uint i = 0; i < toadIds.length; i++) {
            IERC721(stackedtoadzaddress).safeTransferFrom(
            msg.sender,
            address(this),
            toadIds[i]
        );

        toadOwner[uint16(toadIds[i])] = msg.sender;
        emit DepositedToad(msg.sender, toadIds[i]);
        }
    }

    function withdrawToads(uint[] calldata toadIds) public whenNotPaused {
        for(uint i = 0; i < toadIds.length; i++) {
            require(msg.sender == toadOwner[uint16(toadIds[i])]);
            IERC721(stackedtoadzaddress).safeTransferFrom(
            address(this),
            msg.sender,
            toadIds[i]
        );

        toadOwner[uint16(toadIds[i])] = address(this);
        emit WithdrewToad(msg.sender, toadIds[i]);
        }
    }

    function depositStack(uint256 amount) public whenNotPaused {
        uint16 amountToDeposit = uint16(amount / (10 ** 18));
        require(amountToDeposit > 0 && amountToDeposit % 100 == 0, "Can only deposit amounts in 100 increments");
        require(IERC20(stackaddress).balanceOf(msg.sender) >= amount, "User has insufficent stack balance");
        IERC20(stackaddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );


        stackOwned[msg.sender] += (amountToDeposit / 100);
        emit DepositedStack(msg.sender, amount);
    }

    function withdrawStack(uint256 amount) public whenNotPaused {
        uint16 amountToWithdraw = uint16(amount / (10 ** 18));
        require(amountToWithdraw > 0 && amountToWithdraw % 100 == 0, "Can only withdraw amounts in 100 Stack increments");
        require(IERC20(stackaddress).balanceOf(address(this)) >= amount, "Contract has run out of $STACK");
        require((stackOwned[msg.sender] * 100) >= amountToWithdraw, "User hasn't deposited this much stack");
        IERC20(stackaddress).transferFrom(
            address(this),
            msg.sender,
            amount
        );

        stackOwned[msg.sender] -= (amountToWithdraw / 100);
        emit WithdrewStack(msg.sender, amount);
    }

    function offerToadToFight(uint16 toadId) public whenNotPaused {
        require(msg.sender == toadOwner[toadId], "You don't own this toad or it's not staked");
        require((stackOwned[msg.sender] * 100) >= stackPerFight, "Not enough stack credited to afford the cost to fight");

        stackOwned[msg.sender] -= (stackPerFight / 100);

        toadReadyToFight[toadId] = true;

        emit OfferedToadFight(msg.sender, toadId);
    }

    function cancelOfferToadToFight(uint16 toadId) public whenNotPaused ownsToad(toadId) {
        require(toadReadyToFight[toadId] == true, "This toad isn't currently offered for a fight");

        toadReadyToFight[toadId] = false;

        emit CancelToadFight(msg.sender, toadId);
    }

    function fightToadForToad(uint16 toadId, uint16 victim) public whenNotPaused ownsToad(toadId) {
        require((stackOwned[msg.sender] * 100) >= stackPerFight, "Not enough stack credited to afford the cost to fight");
        require(toadReadyToFight[victim] == true, "This toad isn't available to fight");

        uint randomNum = uint(keccak256(abi.encode(block.difficulty, block.timestamp, toadId + victim)));
        bool win = randomNum % 2 == 0;
        stackOwned[msg.sender] -= (stackPerFight / 100);

        if(win) {
            emit WonToadFight(msg.sender, toadId, victim);
            toadOwner[victim] = msg.sender;
        } else {
            emit WonToadFight(toadOwner[victim], victim, toadId);
            toadOwner[toadId] = toadOwner[victim];
        }

        toadReadyToFight[victim] = false;
    }

    function offerStackFight(uint16 toadId, uint256 stackCost) public whenNotPaused ownsToad(toadId) {
        uint16 currentlyOffered = toadReadyForStackFight[toadId];
        require(currentlyOffered == 0, "You already offered this toad to fight");
        uint16 amountOfStack = uint16(stackCost / (10**18));
        require(amountOfStack > 0 && amountOfStack % 100 == 0, "Must be in a multiple of 100");
        require((stackOwned[msg.sender] * 100) * 10 ** 18 >= stackCost, "Not enough stack credited to afford the cost to fight");

        stackOwned[msg.sender] -= amountOfStack;

        toadReadyForStackFight[toadId] = amountOfStack;

        emit OfferedStackFight(msg.sender, toadId, amountOfStack);
    }


    function fightToadForStack(uint16 toadId, uint16 victim) public whenNotPaused ownsToad(toadId) {
        uint16 stackCost = toadReadyForStackFight[victim];
        require(stackCost > 0, "This toad isn't offering a fight for stack");
        require(stackOwned[msg.sender] >= stackCost, "Not enough stack credited to afford the cost to fight");

        uint randomNum = uint(keccak256(abi.encode(block.difficulty, block.timestamp, toadId + victim)));
        bool win = randomNum % 2 == 0;
        stackOwned[msg.sender] -= (stackPerFight / 100);

        if(win) {
            emit WonStackFight(msg.sender, toadId, victim, stackCost);
            stackOwned[msg.sender] += (stackCost * 2);
        } else {
            emit WonStackFight(toadOwner[victim], victim, toadId, stackCost);
            stackOwned[toadOwner[victim]] += (stackCost * 2);
        }

        toadReadyForStackFight[victim] = 0;
    }

    function cancelOfferStackToFight(uint16 toadId) public whenNotPaused ownsToad(toadId) {
        require(toadReadyForStackFight[toadId] > 0, "This toad isn't currently offered for a fight");

        stackOwned[msg.sender] += (toadReadyForStackFight[toadId] / 100);
        toadReadyForStackFight[toadId] = 0;

        emit CancelStackFight(msg.sender, toadId);
    }
    
    function isReadyToFight(bool stack, uint16 toadId) public view returns (bool) {
        if(stack) {
            return toadReadyForStackFight[toadId] > 0;
        } else {
            return toadReadyToFight[toadId];
        }
    }

    function getFightStackValue(uint16 toadId) public view returns (uint16) {
        return toadReadyForStackFight[toadId];
    }

    function getStakedToadOwner(address _owner, uint16 toadId) public view returns (bool) {
        return toadOwner[toadId] == _owner;
    }


    function withdrawContractStack() public onlyOwner {
        IERC20(stackaddress).transferFrom(
            address(this),
            owner(),
            IERC20(stackaddress).balanceOf(address(this))
        );

    }
    

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}