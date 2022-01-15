// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./libraries/SafeMath.sol";
import "./libraries/Ownable.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IGodzillaERC721.sol";
import "./interfaces/IERC721Receiver.sol";

contract GodzillaTrade is Ownable, IERC721Receiver {
    using SafeMath for uint256;
    event Sell(
        address indexed owner,
        address indexed token,
        uint256 indexed tokenId,
        uint256 amount
    );

    event CloseSell(
        address indexed owner,
        address indexed token,
        uint256 indexed tokenId,
        uint256 amount
    );

    event SuccessTrade(
        address indexed owner,
        address indexed to,
        address token,
        uint256 indexed tokenId,
        uint256 amount
    );

    IGodzillaERC721 private _erc721;
    mapping(address => bool) public supportTokens;

    mapping(uint256 => uint256) public prices;
    mapping(uint256 => address) public tokens;
    mapping(uint256 => address) public owners;
    mapping(uint256 => bool) public isSells;
    mapping(uint256 => uint256) public tokenIndexs;
    uint256[] public tokenIds;

    uint256 public initRate = 0;
    uint256 public devRate = 300;
    address public devAddress;

    constructor(address __erc721, address[] memory _supportTokens) {
        _erc721 = IGodzillaERC721(__erc721);
        devAddress = _msgSender();
        for (uint256 i = 0; i < _supportTokens.length; i++) {
            supportTokens[_supportTokens[i]] = true;
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function updateSupportToken(address _token, bool _on)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        supportTokens[_token] = _on;
        return true;
    }

    function updateTradeRate(uint256 _initRate, uint256 _devRate)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        initRate = _initRate;
        devRate = _devRate;
        return true;
    }

    function erc721() public view returns (address) {
        return address(_erc721);
    }

    function tokenIdsLength() public view returns (uint256) {
        return tokenIds.length;
    }

    function updateErc721(address _token)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        _erc721 = IGodzillaERC721(_token);
        return true;
    }

    function exitTokenId(uint256 tokenId)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        require(
            _erc721.ownerOf(tokenId) == address(this),
            "GodzillaStaking: not Staking"
        );
        address token = tokens[tokenId];
        uint256 amount = prices[tokenId];
        removeTrade(tokenId);
        _erc721.transferFrom(address(this), owners[tokenId], tokenId);
        emit CloseSell(_msgSender(), token, tokenId, amount);
        return true;
    }

    // 挂卖
    function sell(
        uint256 tokenId,
        address token,
        uint256 amount
    ) public virtual returns (bool) {
        require(supportTokens[token], "GodzillaTrade: token not Support");
        address owner = _erc721.ownerOf(tokenId);
        require(
            address(this) == _erc721.getApproved(tokenId) ||
                _erc721.isApprovedForAll(owner, address(this)),
            "GodzillaTrade: Please authorize"
        );
        require(
            _msgSender() == owner ||
                _erc721.isApprovedForAll(owner, _msgSender()),
            "GodzillaTrade: sell caller is not owner nor approved for all"
        );
        require(amount > 0, "GodzillaTrade: price not zero");
        tokenIndexs[tokenId] = tokenIds.length;
        tokenIds.push(tokenId);
        prices[tokenId] = amount;
        isSells[tokenId] = true;
        tokens[tokenId] = token;
        owners[tokenId] = owner;
        _erc721.transferFrom(owner, address(this), tokenId);
        emit Sell(_msgSender(), token, tokenId, amount);

        return true;
    }

    // 取消挂卖
    function closeSell(uint256 tokenId) public virtual returns (bool) {
        require(isSells[tokenId], "GodzillaTrade: not Sell");
        address owner = owners[tokenId];
        require(
            _msgSender() == owner ||
                _erc721.isApprovedForAll(owner, _msgSender()),
            "GodzillaTrade: sell caller is not owner nor approved for all"
        );
        address token = tokens[tokenId];
        uint256 amount = prices[tokenId];
        removeTrade(tokenId);
        _erc721.transferFrom(address(this), owner, tokenId);
        emit CloseSell(_msgSender(), token, tokenId, amount);
        return true;
    }

    // 删除挂卖信息
    function removeTrade(uint256 tokenId) private {
        isSells[tokenId] = false;
        uint256 lastTokenIndex = tokenIds.length - 1;
        uint256 tokenIndex = tokenIndexs[tokenId];
        uint256 lastTokenId = tokenIds[lastTokenIndex];

        tokenIds[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        tokenIndexs[lastTokenId] = tokenIndex; // Update the moved token's index

        delete tokenIndexs[tokenId];
        tokenIds.pop();
    }

    // 购买
    function buy(uint256 tokenId) public virtual returns (bool) {
        require(isSells[tokenId], "GodzillaTrade: not Sell");
        address owner = owners[tokenId];

        address initAddress = _erc721.godzillaInitAddress(tokenId);
        uint256 price = prices[tokenId];
        if (initRate > 0 && initAddress != owner) {
            uint256 initBonus = price.mul(initRate).div(10000);
            TransferHelper.safeTransferFrom(
                tokens[tokenId],
                _msgSender(),
                initAddress,
                initBonus
            );
            price = price.sub(initBonus);
        }
        if (devRate > 0 && devAddress != address(0)) {
            uint256 devBonus = price.mul(devRate).div(10000);
            TransferHelper.safeTransferFrom(
                tokens[tokenId],
                _msgSender(),
                devAddress,
                devBonus
            );
            price = price.sub(devBonus);
        }

        TransferHelper.safeTransferFrom(
            tokens[tokenId],
            _msgSender(),
            owner,
            price
        );

        _erc721.transferFrom(address(this), _msgSender(), tokenId);

        removeTrade(tokenId);

        emit SuccessTrade(
            owner,
            _msgSender(),
            tokens[tokenId],
            tokenId,
            prices[tokenId]
        );
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Context.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./IERC721Enumerable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IGodzillaERC721 is IERC721Enumerable {
    function mint(
        address account,
        uint256 tokenId,
        uint256[] memory attrs
    ) external returns (bool);

    function burn(uint256 tokenId) external returns (bool);

    function startTokenURI(uint256 tokenId, string memory _url)
        external
        returns (bool);

    function godzillaInfo(uint256 tokenId)
        external
        view
        returns (
            uint16,
            uint16,
            uint256,
            uint256,
            address,
            uint256
        );

    function godzillaStakingInfo(uint256 tokenId)
        external
        view
        returns (uint256, uint256);

    function godzillaInitAddress(uint256 tokenId)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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