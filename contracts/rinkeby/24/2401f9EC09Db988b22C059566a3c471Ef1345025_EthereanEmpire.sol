pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EthereansInterface.sol";
import "./InvaderTokenInterface.sol";
import "./EmpireDropsInterface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Etherean Empire utility system
/// @author inexplicable.eth
/// @notice Etherean holders must interface through this contract to mint Invader utility tokens

contract EthereanEmpire is Ownable {

using SafeMath for uint256;

event EmpireCreated(address owner, string name, string motto);
event EmpireNameChanged(address owner, string newName);
event EmpireMottoChanged(address owner, string newMotto);
event RewardClaimed(address claimer, uint amount);
event DropCreated(uint tokenId, string title, string description, string artist, uint cost, uint supply, uint end);
event DropMinted(address minter, uint dropId);


struct Empire {
    string name;
    string motto;
    bool exists;
    uint lastUpdated;
}

struct Drop {
    uint tokenId;
    string title;
    string description;
    string artist;
    uint cost; //18 decimal INVDR token
    uint supply;
    uint end;
    bool exists;
    mapping(address => uint) owners;
}

uint public EMPIRE_CREATION_FEE = 50000000000000000; //.05E
uint public ETHEREAN_MIN = 3;
uint public EMPIRE_EDIT_FEE = 200 ether;
uint public numDrops = 0;
address public ETHEREANS_CONTRACT_ADDRESS;
address public INVADER_CONTRACT_ADDRESS;
address public EMPIRE_DROPS_CONTRACT_ADDRESS;
uint constant public END_REWARDS = 1735693200; //Wednesday, January 1, 2025 1:00:00 AM
EthereansInterface private ethereanContract;
InvaderTokenInterface private invaderContract;
EmpireDropsInterface private empireDropsContract;

mapping(address => Empire) public empires;
address[] private empireAddresses;
mapping(uint => Drop) public drops;

/// @notice Initializes the smart contract with reference to the official Ethereans ERC721 contract & utility token
constructor(address _ethereansAddress, address _invaderAddress) {
    ETHEREANS_CONTRACT_ADDRESS = _ethereansAddress;
    ethereanContract = EthereansInterface(_ethereansAddress);

    INVADER_CONTRACT_ADDRESS = _invaderAddress;
    invaderContract = InvaderTokenInterface(_invaderAddress);
}

function setEthereansContractAddress(address _contractAddress) external onlyOwner() {
    ETHEREANS_CONTRACT_ADDRESS = _contractAddress;
    ethereanContract = EthereansInterface(_contractAddress);
}

function setEmpireDropsContractAddress(address _contractAddress) external onlyOwner() {
    EMPIRE_DROPS_CONTRACT_ADDRESS = _contractAddress;
    empireDropsContract = EmpireDropsInterface(_contractAddress);
}

/// @notice Creates a new empire if minimum etherean balance in wallet is met as well as creation fee
function newEmpire(string memory _name, string memory _motto) public payable {
    require(empires[msg.sender].exists == false, "Only one empire per wallet.");
    require(msg.value == EMPIRE_CREATION_FEE, "Did not meet ETH requirement.");
    require(ethereanContract.balanceOf(msg.sender) >= ETHEREAN_MIN, "Did not meet minimum ethereans requirement.");
    empires[msg.sender] = Empire(_name, _motto, true, block.timestamp);
    empireAddresses.push(msg.sender);
    payable(owner()).transfer(EMPIRE_CREATION_FEE);
    emit EmpireCreated(msg.sender, _name, _motto);
}

function newDrop(uint _tokenId, string memory _title, string memory _description, string memory _artist, uint _cost, uint _supply, uint _end) external onlyOwner() {
    require(_tokenId >= 0, "Must supply a tokenId");
    require(_supply > 0, "Supply must be greater than 1.");
    require(block.timestamp < _end, "End date must be set in the future");
    numDrops = numDrops.add(1);
    Drop storage d = drops[numDrops];
    d.tokenId = _tokenId;
    d.title = _title;
    d.description = _description;
    d.artist = _artist;
    d.cost = _cost;
    d.supply = _supply;
    d.end = _end;
    d.exists = true;
    emit DropCreated(_tokenId, _title, _description, _artist, _cost, _supply, _end);
} 

function getEmpireAddresses() public view returns (address[] memory) {
    return empireAddresses;
}

function setEmpireCreationFee(uint _newFee) external onlyOwner(){
    EMPIRE_CREATION_FEE = _newFee;
}

function setEmpireEditFee(uint _newFee) external onlyOwner(){
    EMPIRE_EDIT_FEE = _newFee;
}

modifier hasEmpire {
    require(empires[msg.sender].exists == true, "Does not own empire.");
    _;
}

function changeName(string memory _newName) external hasEmpire(){
    invaderContract.burnFrom(msg.sender, EMPIRE_EDIT_FEE);
    empires[msg.sender].name = _newName;
    emit EmpireNameChanged(msg.sender, _newName);
}

function changeMotto(string memory _newMotto) external hasEmpire(){
    invaderContract.burnFrom(msg.sender, EMPIRE_EDIT_FEE);
    empires[msg.sender].motto = _newMotto;
    emit EmpireMottoChanged(msg.sender, _newMotto);
}

/// @dev Claim function is only available for wallets who have created an empire and have maintained minimum etherean balance requirement at time of claim. The claim amount is determined by: elapsed time (since last claim or empire creation) x ethereans balance x multiplier bonus. Users can claim past the END_REWARDS timestamp if pending rewards are available, but will not be able to claim additional tokens after that last action.
function claimReward() external hasEmpire() {
    uint ethereanBalance = ethereanContract.balanceOf(msg.sender);
    require(ethereanBalance >= ETHEREAN_MIN, "Did not meet minimum ethereans requirement to claim rewards.");
    uint rewardsPerEtherean = getRewardsPerEtherean(ethereanBalance);
    uint currentTime = min(block.timestamp, END_REWARDS);
    Empire storage e = empires[msg.sender];
    uint elapsedTime = currentTime.sub(e.lastUpdated);
    require(elapsedTime > 0, "No rewards available.");
    uint rewardAmount = elapsedTime.mul(ethereanBalance).mul(rewardsPerEtherean).mul(10**18).div(86400);
    invaderContract.claimReward(msg.sender, rewardAmount);
    e.lastUpdated = currentTime;
    emit RewardClaimed(msg.sender, rewardAmount);
}

function mintDrop(uint _dropId) external hasEmpire(){
    Drop storage drop = drops[_dropId];
    require(drop.exists == true, "Drop does not exist.");
    require(block.timestamp < drop.end, "Drop has expired.");
    require(drop.owners[msg.sender] == 0, "Only one drop allowed per empire");
    uint ethereanBalance = ethereanContract.balanceOf(msg.sender);
    require(ethereanBalance >= ETHEREAN_MIN, "Did not meet minimum ethereans requirement to mint drop.");
    if (drop.cost > 0) {
        invaderContract.burnFrom(msg.sender, drop.cost);
    }
    empireDropsContract.mint(msg.sender, drop.tokenId);
    drop.owners[msg.sender] = 1;
    emit DropMinted(msg.sender, _dropId);
}

function min(uint a, uint b) internal pure returns (uint) {
		return a < b ? a : b;
	}

/// @notice Returns the multiplier based on ethereans held in wallet. The base yield per day for an etherean is 10, so a return value of 11 is treated as 1.1x multiplier.
function getRewardsPerEtherean(uint ethereanBalance) internal pure returns (uint) {
    if (ethereanBalance < 6) 
        return 10;
    if (ethereanBalance < 18)
        return 11;
    if (ethereanBalance < 72)
        return 12;
    return 13;
}

function withdraw() public onlyOwner() {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
}

function recoverERC20(address _tokenAddress, uint _tokenAmount) public onlyOwner() {
    IERC20(_tokenAddress).transfer(owner(), _tokenAmount);
}

function recoverERC721(address _tokenAddress, uint _tokenId) public onlyOwner() {
    IERC721(_tokenAddress).safeTransferFrom(address(this), owner(), _tokenId);
}

}

pragma solidity ^0.8.0;

interface InvaderTokenInterface {
    function claimReward(address owner, uint amount) external;

    function burnFrom(address from, uint amount) external;
}

pragma solidity ^0.8.0;

interface EthereansInterface {
    function balanceOf(address owner) external view returns (uint256 balance);
}

pragma solidity ^0.8.0;

interface EmpireDropsInterface {
    function mint(address from, uint tokenId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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