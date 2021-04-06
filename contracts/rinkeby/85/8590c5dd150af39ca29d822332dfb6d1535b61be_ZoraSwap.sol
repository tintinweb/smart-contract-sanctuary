/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity ^0.5.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

interface IERC1155 {
    // Events

    /**
     * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
     *   Operator MUST be msg.sender
     *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
     *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
     *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
     *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
     */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _amount
    );

    /**
     * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
     *   Operator MUST be msg.sender
     *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
     *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
     *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
     *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
     */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _amounts
    );

    /**
     * @dev MUST emit when an approval is updated
     */
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /**
     * @dev MUST emit when the URI is updated for a token ID
     *   URIs are defined in RFC 3986
     *   The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema"
     */
    event URI(string _amount, uint256 indexed _id);

    /**
     * @notice Transfers amount of an _id from the _from address to the _to address specified
     * @dev MUST emit TransferSingle event on success
     * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
     * MUST throw if `_to` is the zero address
     * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
     * MUST throw on any other error
     * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _amount  Transfered amount
     * @param _data    Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external;

    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @dev MUST emit TransferBatch event on success
     * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
     * MUST throw if `_to` is the zero address
     * MUST throw if length of `_ids` is not the same as length of `_amounts`
     * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
     * MUST throw on any other error
     * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
     * @param _from     Source addresses
     * @param _to       Target addresses
     * @param _ids      IDs of each token type
     * @param _amounts  Transfer amounts per token type
     * @param _data     Additional data with no specified format, sent in call to `_to`
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external;

    /**
     * @notice Get the balance of an account's Tokens
     * @param _owner  The address of the token holder
     * @param _id     ID of the Token
     * @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param _owners The addresses of the token holders
     * @param _ids    ID of the Tokens
     * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
     * @dev MUST emit the ApprovalForAll event on success
     * @param _operator  Address to add to the set of authorized operators
     * @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Queries the approval status of an operator for a given owner
     * @param _owner     The owner of the Tokens
     * @param _operator  Address of authorized operator
     * @return           True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

interface IERC1155Metadata {
    /***********************************|
    |     Metadata Public Function s    |
    |__________________________________*/

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     *      URIs are assumed to be deterministically generated based on token ID
     *      Token IDs are assumed to be represented in their hex format in URIs
     * @return URI string
     */
    function uri(uint256 _id) external view returns (string memory);
}

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
        require(c / a == b, "SafeMath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }
}

/**
 * Copyright 2018 ZeroEx Intl.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;

        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

contract ZoraSwap is Ownable {
    using SafeMath for uint256;
    using Address for address;

    // TokenType Definition
    enum TokenType {T20, T1155, T721}

    struct ZoraCollection {
        address sellerAddr;
        address sellerTokenAddr;
        uint256 sellerTokenId;
        uint256 sellerTokenAmount;
        TokenType sellerTokenType;

        address buyerTokenAddr;
        uint256 buyerTokenId;
        uint256 buyerTokenAmount;
        TokenType buyerTokenType;

        uint256 leftAmount;
        bool isActive;        
    }

    uint256 public listIndex;
    mapping(uint256 => ZoraCollection) public swapList;

    bool public emergencyStop;

    address payable public feeCollector;

    address public ZORA;
    uint256 public ZORA_DECIMALS;

    event SwapCreated(
        uint256 listIndex,
        address sellerTokenAddr,
        uint256 sellerTokenId,
        uint256 sellerTokenAmount,
        uint256 sellerTokenType,
        address buyerTokenAddr,
        uint256 buyerTokenId,
        uint256 buyerTokenAmount,
        uint256 buyerTokenType);
    event NFTSwapped(uint256 listIndex, uint256 leftAmount);
    event SwapClosed(uint256 listIndex);


    modifier onlyListOwner(uint256 listId) {
        require(
            swapList[listId].sellerAddr == msg.sender,
            "ZoraSwap: not your list"
        );
        _;
    }

    modifier onlyNotEmergency() {
        require(emergencyStop == false, "ZoraSwap: emergency stop");
        _;
    }

    constructor() public {
        feeCollector = msg.sender;
        listIndex = 0;
        emergencyStop = false;
        //ZORA = address(0xD8E3FB3b08eBA982F2754988d70D57eDc0055ae6); // mainnet
        ZORA = address(0x64bFa0e3E5ebE7E8bF7d4bFb2Bb1FB7Ae109d18b); // mainnet
        ZORA_DECIMALS=9;
    }

    function clearEmergency() external onlyOwner {
        emergencyStop = true;
    }

    function stopEmergency() external onlyOwner {
        emergencyStop = false;
    }

    function createSwap(
        address sellerTokenAddr,
        uint256 sellerTokenId,
        uint256 sellerTokenAmount,
        uint256 sellerTokenType,
        address buyerTokenAddr,
        uint256 buyerTokenId,
        uint256 buyerTokenAmount,
        uint256 buyerTokenType
    ) external payable onlyNotEmergency {
        if (sellerTokenType == uint256(TokenType.T1155)) {
            IERC1155 _t1155Contract = IERC1155(sellerTokenAddr);
            require(
                _t1155Contract.balanceOf(msg.sender, sellerTokenId) >=
                    sellerTokenAmount,
                "ZoraSwap: Seller do not have nft"
            );
            require(
                _t1155Contract.isApprovedForAll(
                    msg.sender,
                    address(this)
                ) == true,
                "ZoraSwap: Must be approved"
            );
        } else if(sellerTokenType == uint256(TokenType.T721)) {
            require(
                sellerTokenAmount == 1,
                "ZoraSwap: Don't support T721 Batch Swap"
            );
            IERC721 _t721Contract = IERC721(sellerTokenAddr);
            require(
                _t721Contract.ownerOf(sellerTokenId) == msg.sender,
                "ZoraSwap: Seller do not have nft"
            );
            require(
                _t721Contract.isApprovedForAll(
                    msg.sender,
                    address(this)
                ) == true,
                "ZoraSwap: Must be approved"
            );
        } else {
            revert("Token Type is Invalid");
        }

        IERC20 ZORA_CONTRACT = IERC20(ZORA);
        uint256 zoraBalance = ZORA_CONTRACT.balanceOf(msg.sender);
        if (zoraBalance >= 5 * (10 ** ZORA_DECIMALS)) {
            require(msg.value >= 0, "ZoraSwap: out of fee");
        } else if (zoraBalance >= 15 * (10 ** (ZORA_DECIMALS - 1))) {
            require(msg.value >= 3 * (10**16), "ZoraSwap: out of fee");
            feeCollector.transfer(msg.value);
        } else {
            require(msg.value >= 5 * (10**16), "ZoraSwap: out of fee");
            feeCollector.transfer(msg.value);
        }

        uint256 _index = listIndex;
        swapList[_index].sellerAddr = msg.sender;
        swapList[_index].sellerTokenAddr = sellerTokenAddr;
        swapList[_index].sellerTokenId = sellerTokenId;
        swapList[_index].sellerTokenAmount = sellerTokenAmount;
        swapList[_index].sellerTokenType = TokenType(sellerTokenType);
        swapList[_index].buyerTokenAddr = buyerTokenAddr;
        swapList[_index].buyerTokenId = buyerTokenId;
        swapList[_index].buyerTokenAmount = buyerTokenAmount;
        swapList[_index].buyerTokenType = TokenType(buyerTokenType);
        swapList[_index].leftAmount = sellerTokenAmount;
        swapList[_index].isActive = true;
        
        _incrementListId();
        emit SwapCreated(
            _index,
            sellerTokenAddr,
            sellerTokenId,
            sellerTokenAmount,
            uint256(sellerTokenType),
            buyerTokenAddr,
            buyerTokenId,
            buyerTokenAmount,
            uint256(buyerTokenType)
        );
    }

    function _sendToken(
        TokenType tokenType,
        address contractAddr,
        uint256 tokenId,
        address from,
        address to,
        uint256 amount,
        uint256 listId
    ) internal {
        if (tokenType == TokenType.T1155) {
            IERC1155(contractAddr).safeTransferFrom(from, to, tokenId, amount, "");
        } else if (tokenType == TokenType.T721) {
            IERC721(contractAddr).safeTransferFrom(from, to, tokenId, "");
        } else {
            IERC20(contractAddr).transferFrom(from, to, swapList[listId].sellerTokenAmount * amount);
        }
    }

    function swapNFT(
        uint256 listId,
        uint256 tokenAmount
    ) external payable onlyNotEmergency {
        require(tokenAmount >= 1, "ZoraSwap: expected more than 1 amount");
        address lister = swapList[listId].sellerAddr;
        
        require(swapList[listId].leftAmount >= tokenAmount, 
            "ZoraSwap: exceed current supply"
        );

        require(swapList[listId].isActive == true, 
            "ZoraSwap: Swap is closed"
        );

        IERC20 ZORA_CONTRACT = IERC20(ZORA);
        uint256 zoraBalance = ZORA_CONTRACT.balanceOf(msg.sender);
        if (zoraBalance >= 5 * (10 ** ZORA_DECIMALS)) {
            require(msg.value >= 0, "ZoraSwap: out of fee");
        } else if (zoraBalance >= 15 * (10 ** (ZORA_DECIMALS - 1))) {
            require(msg.value >= 3 * (10**16), "ZoraSwap: out of fee");
            feeCollector.transfer(msg.value);
        } else {
            require(msg.value >= 5 * (10**16), "ZoraSwap: out of fee");
            feeCollector.transfer(msg.value);
        }

        if(swapList[listId].buyerTokenType == TokenType.T1155) {
            IERC1155 _t1155Contract = IERC1155(swapList[listId].buyerTokenAddr);
            require(
                _t1155Contract.balanceOf(msg.sender, swapList[listId].buyerTokenId) >= tokenAmount,
                "ZoraSwap: Do not have nft"
            );
            require(
                _t1155Contract.isApprovedForAll(
                    msg.sender,
                    address(this)
                ) == true,
                "ZoraSwap: Must be approved"
            );
            _t1155Contract.safeTransferFrom(
                msg.sender,
                lister,
                swapList[listId].buyerTokenId,
                tokenAmount,
                ""
            );
        } else if(swapList[listId].buyerTokenType == TokenType.T721) {
            IERC721 _t721Contract = IERC721(swapList[listId].buyerTokenAddr);
            require(
                tokenAmount == 1,
                "ZoraSwap: Don't support T721 Batch Swap"
            );
            require(
                _t721Contract.ownerOf(swapList[listId].buyerTokenId) == msg.sender,
                "ZoraSwap: Do not have nft"
            );
            require(
                _t721Contract.isApprovedForAll(msg.sender, address(this)) ==
                    true,
                "ZoraSwap: Must be approved"
            );
            _t721Contract.safeTransferFrom(
                msg.sender,
                lister,
                swapList[listId].buyerTokenId,
                ""
            );
        } else if(swapList[listId].buyerTokenType == TokenType.T20) {
            IERC20 _t20Contract = IERC20(swapList[listId].buyerTokenAddr);
            uint256 amount = swapList[listId].buyerTokenAmount.mul(tokenAmount);
            require(
                _t20Contract.balanceOf(msg.sender) >= amount,
                "ZoraSwap: Do not enough funds"
            );
            require(
                _t20Contract.allowance(msg.sender, address(this)) >=
                    amount,
                "ZoraSwap: Must be approved"
            );
            _t20Contract.transferFrom(msg.sender, lister, amount);
        } else {
            revert("ZoraSwap: Buyer's Token Type is Invalid");
        }
        _sendToken(
            swapList[listId].sellerTokenType,
            swapList[listId].sellerTokenAddr,
            swapList[listId].sellerTokenId,
            lister,
            msg.sender,
            tokenAmount,
            listId
        );
        swapList[listId].leftAmount = swapList[listId].leftAmount.sub(tokenAmount);
        if (swapList[listId].leftAmount == 0) {
            swapList[listId].isActive = false;
        }
        emit NFTSwapped(listId, swapList[listId].leftAmount);
    }

    function closeList(uint256 listId)
        external
        onlyListOwner(listId)
    {
        swapList[listId].isActive = false;
        emit SwapClosed(listId);
    }

    function _incrementListId() internal {
        listIndex = listIndex.add(1);
    }
}