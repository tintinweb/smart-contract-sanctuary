// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./utils/uniq/SignatureVerify.sol";

contract UniqRedeem is Ownable, SignatureVerify {
    /// ----- VARIABLES ----- ///
    uint256 internal _transactionOffset;

    /// @dev Returns true if token was redeemed
    mapping(address => mapping(uint256 => mapping(uint256 => bool)))
        internal _isTokenRedeemedForPurpose;

    /// ----- EVENTS ----- ///
    event Redeemed(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _redeemerAddress,
        string _redeemerName,
        uint256[] _purposes
    );

    /// ----- VIEWS ----- ///
    /// @notice Returns true if token claimed
    function isTokenRedeemedForPurpose(
        address _address,
        uint256 _tokenId,
        uint256 _purpose
    ) external view returns (bool) {
        return _isTokenRedeemedForPurpose[_address][_tokenId][_purpose];
    }

    // ----- MESSAGE SIGNATURE ----- //
    function getMessageHash(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        uint256 _price,
        address _paymentTokenAddress,
        uint256 _timestamp
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _tokenContracts,
                    _tokenIds,
                    _purposes,
                    _price,
                    _paymentTokenAddress,
                    _timestamp
                )
            );
    }

    function verifySignature(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(
            _tokenContracts,
            _tokenIds,
            _purposes,
            _price,
            _paymentTokenAddress,
            _timestamp
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    /// ----- PUBLIC METHODS ----- ///
    function redeemManyTokens(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        string memory _redeemerName,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable {
        require(
            _tokenContracts.length == _tokenIds.length &&
                _tokenIds.length == _purposes.length,
            "Array length mismatch"
        );
        require(_timestamp + _transactionOffset >= block.timestamp, "Transaction timed out");
        require(
            verifySignature(
                _tokenContracts,
                _tokenIds,
                _purposes,
                _price,
                _paymentTokenAddress,
                _signature,
                _timestamp
            ),
            "Signature mismatch"
        );
        uint256 len = _tokenContracts.length;
        for (uint256 i = 0; i < len; i++) {
            require(
                !_isTokenRedeemedForPurpose[_tokenContracts[i]][_tokenIds[i]][
                    _purposes[i]
                ],
                "Can't be redeemed again"
            );
            IERC721 token = IERC721(_tokenContracts[i]);
            require(
                token.ownerOf(_tokenIds[i]) == msg.sender,
                "Redeemee needs to own this token"
            );
            _isTokenRedeemedForPurpose[_tokenContracts[i]][_tokenIds[i]][
                _purposes[i]
            ] = true;
            uint256[] memory purpose = new uint256[](1);
            purpose[0] = _purposes[i];
            emit Redeemed(
                _tokenContracts[i],
                _tokenIds[0],
                msg.sender,
                _redeemerName,
                purpose
            );
        }
        if (_price != 0) {
            if (_paymentTokenAddress == address(0)) {
                require(msg.value >= _price, "Not enough ether");
                if (_price < msg.value) {
                    payable(msg.sender).transfer(msg.value - _price);
                }
            } else {
                require(
                    IERC20(_paymentTokenAddress).transferFrom(
                        msg.sender,
                        address(this),
                        _price
                    )
                );
            }
        }
    }

    function redeemTokenForPurposes(
        address _tokenContract,
        uint256 _tokenId,
        uint256[] memory _purposes,
        string memory _redeemerName,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable {
        uint256 len = _purposes.length;
        require(_timestamp + _transactionOffset >= block.timestamp, "Transaction timed out");
        address[] memory _tokenContracts = new address[](len);
        uint256[] memory _tokenIds = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            _tokenContracts[i] = _tokenContract;
            _tokenIds[i] = _tokenId;
            require(
                !_isTokenRedeemedForPurpose[_tokenContract][_tokenId][
                    _purposes[i]
                ],
                "Can't be claimed again"
            );
            IERC721 token = IERC721(_tokenContract);
            require(
                token.ownerOf(_tokenId) == msg.sender,
                "Claimer needs to own this token"
            );
            _isTokenRedeemedForPurpose[_tokenContract][_tokenId][
                _purposes[i]
            ] = true;
        }
        require(
            verifySignature(
                _tokenContracts,
                _tokenIds,
                _purposes,
                _price,
                _paymentTokenAddress,
                _signature,
                _timestamp
            ),
            "Signature mismatch"
        );
        if (_price != 0) {
            if (_paymentTokenAddress == address(0)) {
                require(msg.value >= _price, "Not enough ether");
                if (_price < msg.value) {
                    payable(msg.sender).transfer(msg.value - _price);
                }
            } else {
                require(
                    IERC20(_paymentTokenAddress).transferFrom(
                        msg.sender,
                        address(this),
                        _price
                    )
                );
            }
        }
        emit Redeemed(
            _tokenContract,
            _tokenId,
            msg.sender,
            _redeemerName,
            _purposes
        );
    }

    /// ----- OWNER METHODS ----- ///
    constructor() {
        _transactionOffset = 2 hours;
    }

    function setTransactionOffset(uint256 _newOffset) external onlyOwner{
        _transactionOffset = _newOffset;
    }


    function setStatusesForTokens(address[] memory _tokenAddresses, uint256[] memory _tokenIds, uint256[] memory _purposes, bool[] memory isRedeemed) external onlyOwner{
        uint256 len = _tokenAddresses.length;
        require(len == _tokenIds.length && len == _purposes.length && len == isRedeemed.length, "Arrays lengths mismatch");
        for(uint i = 0; i < len; i++){
            _isTokenRedeemedForPurpose[_tokenAddresses[i]][_tokenIds[i]][_purposes[i]] = isRedeemed[i];
        }
    }

    /// @notice Withdraw/rescue erc20 tokens to owners address
    function withdrawERC20(address _address) external onlyOwner {
        uint256 val = IERC20(_address).balanceOf(address(this));
        Ierc20(_address).transfer(msg.sender, val);
    }

    function withdrawETH() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /// ----- PRIVATE METHODS ----- ///

    receive() external payable {}
}

interface Ierc20 {
    function transfer(address, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract SignatureVerify{

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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