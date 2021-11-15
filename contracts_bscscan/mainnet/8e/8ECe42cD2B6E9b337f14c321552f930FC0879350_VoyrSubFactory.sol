// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.6;
// SPDX-License-Identifier: GPL


import "@openzeppelin/contracts/access/Ownable.sol";
import "./VoyrSubscriptions.sol";

/// @author DrGorilla.eth / Voyager Media Group
/// @title Memories Factory
/// @notice this is the factory and controller for subscription contracts.
/// Each contract created by this factory is init with the name 'VOYR SUB' 
/// and the symbol 'id XX' (where XX is the creator id)

contract VoyrSubFactory is Ownable {

    uint256 current_id = 1;

    mapping(address => uint256) public creatorIds; //when called, will return 0 if not a creator
    mapping(uint256 => VoyrSubscriptions) public child_contracts; //id -> sub contract

    constructor () {}

    function newCreator(address _creator, address token_adr) external {
        require(creatorIds[_creator] == 0, "already creator");
        string memory current_id_str = string(abi.encodePacked("id ", uint2str(current_id)));
        VoyrSubscriptions _adr = new VoyrSubscriptions(_creator, current_id_str, token_adr);
        child_contracts[current_id] = _adr;
        creatorIds[_creator] = current_id;
        current_id++;
    }

    /// @dev send the sub to creator_id from user to the burn address + cancel any ongoing sub
    function burn(uint256 creator_id, address user) external onlyOwner {
        child_contracts[creator_id].burn(user);
    }

    /// @dev create a new sub and mint if needed
    function give(uint256 creator_id, address receiver, uint256 length) external onlyOwner {
        child_contracts[creator_id].sendSubscription(receiver, length);
    }

    function setPrice(uint256 creator_id, uint256 price) external onlyOwner {
        child_contracts[creator_id].setCurrentPrice(price);
    }

    function suspendCreator(uint256 creator_id) external onlyOwner {
        child_contracts[creator_id].pause();
    }

    function resumeCreator(uint256 creator_id) external onlyOwner {
        child_contracts[creator_id].resume();
    }

    function deleteCreator(uint256 creator_id) external onlyOwner {
        child_contracts[creator_id].pause();
        address _creator = child_contracts[creator_id].getCreator();
        delete child_contracts[creator_id];
        delete creatorIds[_creator];
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }


}

pragma solidity ^0.8.6;

// SPDX-License-Identifier: GPL

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/// @author DrGorilla.eth / Voyager Media Group
/// @title Memories Subscription: individual creators
/// @notice this is the generic NFT compatible subscription token.
/// @dev This contract is non-custodial. Accepted token is set by factory. totalySupply is, de facto, tthe current id minted,
/// prices are expressed in wei per seconds.

contract VoyrSubscriptions is IERC721, Ownable {

    uint256 public totalSupply;
    uint256 public subscription_length = 30 days;
    uint256 public price; //for one period (ie for 30 days by default)

    bool paused;

    address creator;

    string private _symbol;

    IERC20 payment_token;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _owned;  //
    mapping(address => uint256) public expirations; //adr->timestamp of the end of current subscription

    modifier onlyAdmin {
        require(msg.sender == creator || msg.sender == owner(), "Sub: unauthorized");
        _;
    }

    constructor(address _creator, string memory _id, address token_adr) {
        _symbol = _id;
        creator = _creator;
        payment_token = IERC20(token_adr);
        totalSupply = 1; //0 reserved for invalid entry
    }

    function balanceOf(address _owner) public view virtual override returns (uint256) {
        require(_owner != address(0), "Sub: balance query for the zero address");
        if(_owned[_owner] != 0) return 1;
        return 0;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address _owner = _owners[tokenId];
        require(_owner != address(0), "Sub: owner query for nonexistent token");
        return _owner;
    }

    function name() public view virtual returns (string memory) {
        return "VOYR SUB";
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function newSub(uint256 number_of_periods) external {
        require(number_of_periods != 0, "Sub: Invalid sub duration");
        if(_owned[msg.sender] != 0) renewSub(number_of_periods);
        else {
            uint256 current_id = totalSupply;
            _owned[msg.sender] = current_id;
            _owners[current_id] = msg.sender;
            emit Transfer(address(this), msg.sender, current_id);
            totalSupply++;
            _processPayment(number_of_periods);
        }
    }

    function renewSub(uint256 number_of_periods) public {
        require(number_of_periods != 0, "Sub: Invalid sub duration");
        require(_owned[msg.sender] != 0, "Sub: No sub owned");
        _processPayment(number_of_periods);
    }

    function _processPayment(uint256 number_of_periods) internal {
        require(!paused, "Creator paused");
        uint256 to_pay = price  * number_of_periods;
        uint256 total_duration = subscription_length * number_of_periods;
        require(payment_token.allowance(msg.sender, address(this)) >= to_pay, "IERC20: insuf approval");
        
        expirations[msg.sender] = expirations[msg.sender] >= block.timestamp ?  expirations[msg.sender] + total_duration : block.timestamp + total_duration;
        
        payment_token.transferFrom(msg.sender, creator, to_pay);
    }

    function setCurrentPrice(uint256 _price) external onlyAdmin {
        price = _price;
    }

    function setSubscriptionLength(uint256 _length) external onlyAdmin {
        subscription_length = _length;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function resume() external onlyOwner {
        paused = false;
    }

    function burn(address _adr) external onlyOwner {
        require(_owned[_adr] != 0, "Sub burn: no token owned");
        uint256 id = _owned[_adr];
        delete _owned[_adr];
        _owners[id] = address(0);
        delete expirations[_adr];

        emit Transfer(_adr, address(0), id);
    }
    
    function sendSubscription(address _adr, uint256 length) external onlyOwner {
        if(_owned[_adr] == 0) {
            _owned[_adr] = totalSupply;
            _owners[totalSupply] = _adr;
            emit Transfer(address(this), _adr, totalSupply);
            totalSupply++;
        }
        expirations[_adr] = expirations[_adr] >= block.timestamp ?  expirations[_adr] + length : block.timestamp + length;
    }

    function setPaymentToken(address _token) external onlyAdmin {
        payment_token = IERC20(_token);
        require(payment_token.totalSupply() != 0, "Set payment: Invalid ERC20");
    }

    /// @dev frontend integration: prefer accessing the mapping itself to compare with Date.now() (instead of last block timestamp)
    function subscriptionActive() external view returns (bool) {
        return expirations[msg.sender] >= block.timestamp;
    }

    function getCreator() external view returns (address) {
        return creator;
    }


/// @dev no use case:
    function approve(address to, uint256 tokenId) public virtual override {}
    function getApproved(uint256 tokenId) public view virtual override returns (address) {return address(0);}
    function setApprovalForAll(address operator, bool approved) public virtual override {}
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {return false;}
    function transferFrom(address from,address to,uint256 tokenId) public virtual override {}
    function safeTransferFrom(address from,address to,uint256 tokenId) public virtual override {}
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes memory _data) public virtual override {}
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {return false;} 

}

