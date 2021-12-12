// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Interfaces/IOpportunityNFT.sol";
import "./Interfaces/IVault.sol";
import "./Interfaces/IOpportunity.sol";

struct WithdrawalOrder{
    address userAddress;
    uint tokenId;
}

contract SingleAssetVaultContract is Ownable, IVault {

    string public version = "SingleAssetVaultContractV3";

    address private _parent;
    string private _name;
    IOpportunityNFT private _opportunityNftInstance;
    IERC20 private _tokenInstance;

    uint private _withdrawalOrderNumber;
    mapping (uint => WithdrawalOrder) private _withdrawalOrderMap;
    uint private _withdrawalOrdersAmount;
    mapping(address => mapping(uint => bool)) private _withdrawalOrderCast;

    uint private _borrowedAmount;
    uint private _totalBalance;

    event WithdrawalOrderCreated(uint id, address indexed user, uint tokenId);
    
    constructor(address owner, string memory name, address opportunityNftAddress, address tokenAddress) {
        transferOwnership(owner);
        _name = name;
        _opportunityNftInstance = IOpportunityNFT(opportunityNftAddress);
        _tokenInstance = IERC20(tokenAddress);
        _parent = msg.sender;
        //_tokenInstance.approve(_parent, 2**256 - 1);
    }
    
    /////////////////////
    // Parent section //
    ////////////////////
    
    function createWithdrawalOrder(address user, uint tokenId) public override returns (bool) {
        require(msg.sender == _parent, "Sender is not a parent!");
        require(getWithdrawalOrderCast(user, tokenId), "Withdrawal order already cast!");
        _withdrawalOrderMap[_withdrawalOrderNumber] = WithdrawalOrder(user, tokenId);
        emit WithdrawalOrderCreated(_withdrawalOrderNumber, user, tokenId);
        _withdrawalOrderNumber++;
        _withdrawalOrdersAmount += ISingleAssetOpportunity(_parent).getTokensTokenAmount(tokenId);
        _withdrawalOrderCast[user][tokenId] = true;
        return true;
    }

    function fulfilLastWithdrawalOrder() public override returns (bool, uint) {
        require(msg.sender == _parent, "Sender is not a parent!");
        require(_withdrawalOrderNumber > 0, "There is no Withdrawal orders!");
        uint tokenId = _withdrawalOrderMap[_withdrawalOrderNumber - 1].tokenId;
        address userAddress = _withdrawalOrderMap[_withdrawalOrderNumber - 1].userAddress;
        uint tokenAmount = ISingleAssetOpportunity(_parent).getTokensTokenAmount(tokenId);
        bool destroyToken = false;

        if (_opportunityNftInstance.ownerOf(tokenId) == userAddress){
            _tokenInstance.transfer(_withdrawalOrderMap[_withdrawalOrderNumber - 1].userAddress, tokenAmount);
            _totalBalance -= tokenAmount;
            
            destroyToken = true;
        }

        _withdrawalOrderCast[userAddress][tokenId] = false;
        delete _withdrawalOrderMap[_withdrawalOrderNumber - 1];
        _withdrawalOrderNumber -= 1;
        _withdrawalOrdersAmount -=  tokenAmount;

        return (destroyToken, tokenId);
    }

    function executeNewDepositCode(uint amount) public override returns (bool) {
        require(msg.sender == _parent, "Sender is not a parent!");
        _totalBalance += amount;
        return true;
    }
    
    function executeNewWithdrawalCode(address reciever, uint tokenAmount) public override returns(bool) {
        require(msg.sender == _parent, "Sender is not a parent!");
        _totalBalance -= tokenAmount;
        _tokenInstance.transfer(reciever, tokenAmount);
        return true;
    }
    
    ////////////////////
    // Owner section //
    ///////////////////
    
    function setBorrowedAmmount(uint amount_) public onlyOwner override returns (bool) {
        _borrowedAmount = amount_;
        return true;
    }

    function borrowFunds(address to, uint amount) public onlyOwner override returns (bool) {
        _borrowedAmount += amount;
        _tokenInstance.transfer(to, amount);
        return true;
    }

    function returnFunds(uint amount) public onlyOwner override returns (bool) {
        _borrowedAmount -= amount;
        _tokenInstance.transferFrom(msg.sender, address(this), amount);
        return true;
    }
    
    function setParent(address parent) public onlyOwner override returns (bool) {
        _parent = parent;
        _tokenInstance.approve(parent, 2**256 - 1);
        return true;
    }
    
    function salvageTokensFromContract(address tokenAddress, address to, uint amount) public onlyOwner override {
        IERC20(tokenAddress).transfer(to, amount);
    }
    
    function killContract() public onlyOwner override {
        selfdestruct(payable(msg.sender));
    }
    
    ////////////////////
    // Public methods //
    ////////////////////
    
    function getParent() public view override returns (address) {
        return _parent;
    }
    
    function getTokenAddress() public view override returns (address) {
        return address(_tokenInstance);
    }
    
    function getOpportunityNftAddress() public view override returns (address) {
        return address(_opportunityNftInstance);
    }
    
    function getAvaliableBalance() public view override returns (uint) {
        return _totalBalance - _borrowedAmount;
    }
    
    function getTotalBalance() public view override returns (uint) {
        return _totalBalance;
    }
    
    function getBorrowedAmount() public view override returns (uint) {
        return _borrowedAmount;
    }
    
    function getWithdrawalOrderCount() public view override returns (uint) {
        return _withdrawalOrderNumber;
    }
    
    function getWithdrawalOrdersAmount() public view override returns (uint) {
        return _withdrawalOrdersAmount;
    }
    
    function getName() public view override returns (string memory) {
        return _name;
    }
    
    function getWithdrawalOrder(uint withdrawalOrderId) public view override returns (address, uint) {
        return (_withdrawalOrderMap[withdrawalOrderId].userAddress, _withdrawalOrderMap[withdrawalOrderId].tokenId);
    }

    function getWithdrawalOrderCast(address userAddress_, uint tokenId_) public view override returns (bool) {
        return _withdrawalOrderCast[userAddress_][tokenId_];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IOpportunityNFT is IERC721 {

    function issueNewToken(address user) external returns (uint256);
    function destroyToken(uint tokenId) external returns (bool);
    
    function addRemoveMinter(address _newMinterAddress) external returns (bool);
    function salvageTokensFromContract(address tokenAddress, address to, uint amount) external;
    function killContract() external;
    
    function isMinterAllowed(address minterAddress) external view returns (bool);
    function getNftParent(uint tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IVault {
    function createWithdrawalOrder(address user, uint tokenId) external returns (bool);
    function fulfilLastWithdrawalOrder() external returns (bool, uint);
    function executeNewDepositCode(uint amount) external returns (bool);
    function executeNewWithdrawalCode(address reciever, uint tokenAmount) external returns (bool);
    
    function setBorrowedAmmount(uint amount_) external returns (bool);
    function borrowFunds(address to, uint amount) external returns (bool);
    function returnFunds(uint amount) external returns (bool);
    function setParent(address parent) external returns (bool); 
    function salvageTokensFromContract(address tokenAddress, address to, uint amount) external;
    function killContract() external;
    
    function getParent() external view returns (address);
    function getTokenAddress() external view returns (address); 
    function getOpportunityNftAddress() external view returns (address); 
    function getAvaliableBalance() external view returns (uint);
    function getTotalBalance() external view returns (uint);
    function getBorrowedAmount() external view returns (uint); 
    function getWithdrawalOrderCount() external view returns (uint); 
    function getWithdrawalOrdersAmount() external view returns (uint);
    function getName() external view returns (string memory);
    function getWithdrawalOrder(uint withdrawalOrderId) external view returns (address, uint);
    function getWithdrawalOrderCast(address userAddress_, uint tokenId_) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpportunity {
    
    function changeVaultInstance(address vaultAddress) external returns(bool);
    function addToOpportunity(uint tokenAmount, uint startTimestamp, address userAddress) external returns(bool);
    function removeFromOpportunity(uint tokenId) external returns (bool);
    function fulfilLastWithdrawalOrder() external returns (bool);
    function batchFulfilLastWithdrawalOrder(uint _iterations) external returns (bool);
    function changeMaster(address newMasterAddress) external returns (bool);
    function changeMinAmount(uint minAmount) external returns (bool);
    function changeApy(uint apy) external returns (bool);
    function changeLockLenght(uint lockLenght) external returns (bool);
    
    function disableEnable() external returns (bool);
    
    function joinOpportunity(uint tokenAmount) external returns (bool);
    function exitOpportunity(uint tokenId) external returns (bool);
    
    function getIssuedNftCount() external returns (uint);
    
    function getMasterAddress() external view returns (address);
    function getTokenAddress() external view returns (address);
    function getVaultAddress() external view returns (address);
    function getNFTAddress() external view returns (address);
    function getName() external view returns (string memory);
    function getLockLenght() external view returns (uint);
    function getApy() external view returns (uint);
    function getMinAmount() external view returns (uint);
    function getActive() external view returns (bool);

}

interface ISingleAssetOpportunity {
    function getTokensTokenAmount(uint tokenId) external view returns (uint);
    function gettokenDetails(uint tokenId) external view returns (address baseToken, uint tokenAmount, uint startTimestamp, uint endTimestamp, uint apy, uint nfttokenId);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
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