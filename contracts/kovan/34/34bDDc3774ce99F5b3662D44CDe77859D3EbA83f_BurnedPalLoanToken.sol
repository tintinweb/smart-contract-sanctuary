//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import {Errors} from  "./utils/Errors.sol";
import "./utils/SafeMath.sol";
import "./PalLoanTokenInterface.sol";



/** @title bPalLoanToken contract  */
/// @author Paladin
contract BurnedPalLoanToken{
    using SafeMath for uint;

    //Storage

    // Token name
    string public name;
    // Token symbol
    string public symbol;

    //Token Minter contract : PalLoanToken
    address public minter;

    uint256 public totalSupply;
    // Mapping from token ID to owner address
    mapping(uint256 => address) private owners;

    // Mapping owner address to token count
    mapping(address => uint256[]) private balances;


    //Modifiers
    modifier authorized() {
        //allows only the palLoanToken contract to call methds
        require(msg.sender == minter, Errors.CALLER_NOT_MINTER);
        _;
    }


    //Events

    /** @notice Event when a new token is minted */
    event NewBurnedLoanToken(address indexed to, uint256 indexed tokenId);


    //Constructor
    constructor(string memory _name, string memory _symbol) {
        //ERC721 parameters
        name = _name;
        symbol = _symbol;
        minter = msg.sender;
        totalSupply = 0;
    }



    //Functions


    //URI method
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return PalLoanTokenInterface(minter).tokenURI(tokenId);
    }

    /**
    * @notice Return the user balance (total number of token owned)
    * @param owner Address of the user
    * @return uint256 : number of token owned (in this contract only)
    */
    function balanceOf(address owner) external view returns (uint256){
        require(owner != address(0), "ERC721: balance query for the zero address");
        return balances[owner].length;
    }


    /**
    * @notice Return owner of the token
    * @param tokenId Id of the token
    * @return address : owner address
    */
    function ownerOf(uint256 tokenId) external view returns (address){
        return owners[tokenId];
    }

    
    /**
    * @notice Return the list of all tokens owned by the user
    * @dev Return the list of user's tokens
    * @param owner User address
    * @return uint256[] : list of owned tokens
    */
    function tokensOf(address owner) external view returns(uint256[] memory){
        return balances[owner];
    }

    

    /**
    * @notice Mint a new token to the given address with the given Id
    * @dev Mint the new token with the correct Id (from the previous burned token)
    * @param to Address of the user to mint the token to
    * @param tokenId Id of the token to mint
    * @return bool : success
    */
    function mint(address to, uint256 tokenId) external returns(bool){
        require(to != address(0), "ERC721: mint to the zero address");

        //Update Supply
        totalSupply = totalSupply.add(1);

        //Add the new token to storage
        balances[to].push(tokenId);
        owners[tokenId] = to;

        //Emit the correct Event
        emit NewBurnedLoanToken(to, tokenId);

        return true;
    }


}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

library Errors {
    // Admin error
    string public constant CALLER_NOT_ADMIN = '1'; // 'The caller must be the admin'
    string public constant CALLER_NOT_CONTROLLER = '29'; // 'The caller must be the admin or the controller'
    string public constant CALLER_NOT_ALLOWED_POOL = '30';  // 'The caller must be a palPool listed in tle controller'
    string public constant CALLER_NOT_MINTER = '31';

    // ERC20 type errors
    string public constant FAIL_TRANSFER = '2';
    string public constant FAIL_TRANSFER_FROM = '3';
    string public constant BALANCE_TOO_LOW = '4';
    string public constant ALLOWANCE_TOO_LOW = '5';
    string public constant SELF_TRANSFER = '6';

    // PalPool errors
    string public constant INSUFFICIENT_CASH = '9';
    string public constant INSUFFICIENT_BALANCE = '10';
    string public constant FAIL_DEPOSIT = '11';
    string public constant FAIL_LOAN_INITIATE = '12';
    string public constant FAIL_BORROW = '13';
    string public constant ZERO_BORROW = '27';
    string public constant BORROW_INSUFFICIENT_FEES = '23';
    string public constant LOAN_CLOSED = '14';
    string public constant NOT_LOAN_OWNER = '15';
    string public constant LOAN_OWNER = '16';
    string public constant FAIL_LOAN_EXPAND = '17';
    string public constant NOT_KILLABLE = '18';
    string public constant RESERVE_FUNDS_INSUFFICIENT = '19';
    string public constant FAIL_MINT = '20';
    string public constant FAIL_BURN = '21';
    string public constant FAIL_WITHDRAW = '24';
    string public constant FAIL_CLOSE_BORROW = '25';
    string public constant FAIL_KILL_BORROW = '26';
    string public constant ZERO_ADDRESS = '22';
    string public constant INVALID_PARAMETERS = '28'; 
    string public constant FAIL_LOAN_DELEGATEE_CHANGE = '32';
    string public constant FAIL_LOAN_TOKEN_BURN = '33';

}

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./utils/IERC721.sol";

/** @title palLoanToken Interface  */
/// @author Paladin
interface PalLoanTokenInterface is IERC721 {

    //Events

    /** @notice Event when a new Loan Token is minted */
    event NewLoanToken(address palPool, address indexed owner, address indexed palLoan, uint256 indexed tokenId);
    /** @notice Event when a Loan Token is burned */
    event BurnLoanToken(address palPool, address indexed owner, address indexed palLoan, uint256 indexed tokenId);


    //Functions
    function mint(address to, address palPool, address palLoan) external returns(uint256);
    function burn(uint256 tokenId) external returns(bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function tokenOfByIndex(address owner, uint256 tokenIdex) external view returns (uint256);
    function loanOf(uint256 tokenId) external view returns(address);
    function poolOf(uint256 tokenId) external view returns(address);
    function loansOf(address owner) external view returns(address[] memory);
    function tokensOf(address owner) external view returns(uint256[] memory);
    function loansOfForPool(address owner, address palPool) external view returns(address[] memory);
    function allTokensOf(address owner) external view returns(uint256[] memory);
    function allLoansOf(address owner) external view returns(address[] memory);
    function allLoansOfForPool(address owner, address palPool) external view returns(address[] memory);
    function allOwnerOf(uint256 tokenId) external view returns(address);

    function isBurned(uint256 tokenId) external view returns(bool);

    //Admin functions
    function setNewController(address _newController) external;
    function setNewBaseURI(string memory _newBaseURI) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IERC165.sol";

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

pragma solidity ^0.7.6;

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

