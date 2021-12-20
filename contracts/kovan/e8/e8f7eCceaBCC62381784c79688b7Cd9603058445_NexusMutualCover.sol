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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers.
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IExchangeAgent {
    function getNeededTokenAmount(
        address _token0,
        address _token1,
        uint256 _desiredAmount
    ) external returns (uint256);

    function getTokenAmountForUSDC(address _token, uint256 _desiredAmount) external returns (uint256);

    function getETHAmountForUSDC(uint256 _desiredAmount) external view returns (uint256);

    function getTokenAmountForETH(address _token, uint256 _desiredAmount) external returns (uint256);

    function swapTokenWithETH(
        address _token,
        uint256 _amount,
        uint256 _desiredAmount
    ) external;

    function swapTokenWithToken(
        address _token0,
        address _token1,
        uint256 _amount,
        uint256 _desiredAmount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface INexusMutual {
    function buyCover(
        address contractAddress,
        address coverAsset,
        uint256 sumAssured,
        uint16 coverPeriod,
        uint8 coverType,
        uint256 maxPriceWithFee,
        bytes calldata data
    ) external payable returns (uint256);

    function ETH() external view returns (address);

    function feePercentage() external view returns (uint256);

    function gateway() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.0;

interface INexusMutualGateway {
    enum ClaimStatus {
        IN_PROGRESS,
        ACCEPTED,
        REJECTED
    }
    enum CoverType {
        SIGNED_QUOTE_CONTRACT_COVER
    }

    function getCoverPrice(
        address contractAddress,
        address coverAsset,
        uint256 sumAssured,
        uint16 coverPeriod,
        CoverType coverType,
        bytes calldata data
    ) external view returns (uint256 coverPrice);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libs/TransferHelper.sol";

contract BaseCoverOnChain is Ownable {
    event BuyProduct(uint256 indexed _productId, address _buyer);
    event WithdrawAsset(address _user, address _to, address _token, uint256 _amount);

    using Counters for Counters.Counter;
    Counters.Counter public productIds;
    mapping(address => bool) public availableCurrencies;

    // address public immutable WETH;
    address public exchangeAgent;

    constructor(address _CVR, address _exchangeAgent) {
        availableCurrencies[_CVR] = true;
        exchangeAgent = _exchangeAgent;
    }

    modifier onlyAvailableToken(address _token) {
        require(availableCurrencies[_token], "Not allowed token");
        _;
    }

    receive() external payable {}

    function addCurrency(address _currency) external onlyOwner {
        require(!availableCurrencies[_currency], "Already available");
        availableCurrencies[_currency] = true;
    }

    function removeCurrency(address _currency) external onlyOwner {
        require(availableCurrencies[_currency], "Not available yet");
        availableCurrencies[_currency] = false;
    }

    /**
     * @dev For reflect tokens, we should deposit some tokens at contract directly,
     * We will withdraw tokens deposited at contract through this function
     */
    function withdrawAsset(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        TransferHelper.safeTransfer(_token, _to, _amount);
        WithdrawAsset(msg.sender, _to, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {INexusMutual} from "../interfaces/INexusMutual.sol";
import {INexusMutualGateway} from "../interfaces/INexusMutualGateway.sol";
import "../interfaces/IExchangeAgent.sol";
import "../libs/TransferHelper.sol";
import "./BaseCoverOnChain.sol";

contract NexusMutualCover is ERC721Holder, BaseCoverOnChain {
    event BuyNexusMutual(uint256 indexed pid, address _buyToken, uint256 _tokenAmount);

    address public immutable distributor;

    constructor(
        address _CVR,
        address _exchangeAgent,
        address _distributor
    ) BaseCoverOnChain(_CVR, _exchangeAgent) {
        distributor = _distributor;
    }

    /**
     * @dev return maxPriceWithFee value
     */
    function getProductPrice(
        address contractAddress,
        address coverAsset,
        uint256 sumAssured,
        uint16 coverPeriod,
        uint8 coverType,
        bytes calldata data
    ) public view returns (uint256) {
        address nexusGateWay = INexusMutual(distributor).gateway();
        uint256 coverPrice = INexusMutualGateway(nexusGateWay).getCoverPrice(
            contractAddress,
            coverAsset,
            sumAssured,
            coverPeriod,
            INexusMutualGateway.CoverType(coverType),
            data
        );
        uint256 _feePercentage = INexusMutual(distributor).feePercentage();
        uint256 coverPriceWithFee = (_feePercentage * coverPrice) / 10000 + coverPrice;

        return coverPriceWithFee;
    }

    /**
     * @dev User will buy product directly using his ETH
     */
    function buyCoverByETH(
        address contractAddress,
        address coverAsset,
        uint256 sumAssured,
        uint16 coverPeriod,
        uint8 coverType,
        uint256 maxPriceWithFee,
        bytes calldata data
    ) external payable {
        address _weth = INexusMutual(distributor).ETH();
        require(coverAsset == _weth, "Should pay in ETH");
        uint256 productPrice = getProductPrice(contractAddress, coverAsset, sumAssured, coverPeriod, coverType, data);

        require(msg.value >= productPrice, "Insufficient amount");
        if (msg.value > productPrice) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - productPrice);
        }

        uint256 productId = INexusMutual(distributor).buyCover{value: productPrice}(
            contractAddress,
            coverAsset,
            sumAssured,
            coverPeriod,
            coverType,
            maxPriceWithFee,
            data
        );

        buyCover(productId);

        emit BuyNexusMutual(productId, coverAsset, productPrice);
    }

    function buyCoverByToken(
        address[] memory _assets, // _token, contractAddress, coverAsset
        uint256 sumAssured,
        uint16 coverPeriod,
        uint8 coverType,
        uint256 maxPriceWithFee,
        bytes calldata data
    ) external payable onlyAvailableToken(_assets[0]) {
        require(_assets.length == 3, "Assets param length should be 3");
        uint256 productPrice = getProductPrice(_assets[1], _assets[2], sumAssured, coverPeriod, coverType, data);

        uint256 amount;
        uint256 value;

        if (_assets[2] == INexusMutual(distributor).ETH()) {
            amount = IExchangeAgent(exchangeAgent).getTokenAmountForETH(_assets[0], productPrice);
            value = productPrice;
        } else {
            amount = IExchangeAgent(exchangeAgent).getNeededTokenAmount(_assets[0], _assets[2], productPrice);
        }

        TransferHelper.safeTransferFrom(_assets[0], msg.sender, address(this), amount);
        TransferHelper.safeApprove(_assets[0], exchangeAgent, amount);

        if (_assets[2] == INexusMutual(distributor).ETH()) {
            IExchangeAgent(exchangeAgent).swapTokenWithETH(_assets[0], amount, productPrice);
        } else {
            IExchangeAgent(exchangeAgent).swapTokenWithToken(_assets[0], _assets[2], amount, productPrice);
            TransferHelper.safeApprove(_assets[2], distributor, productPrice);
        }

        uint256 productId = INexusMutual(distributor).buyCover{value: value}(
            _assets[1],
            _assets[2],
            sumAssured,
            coverPeriod,
            coverType,
            maxPriceWithFee,
            data
        );

        buyCover(productId);
        emit BuyNexusMutual(productId, _assets[0], amount);
    }

    function buyCover(uint256 productId) private {
        IERC721(distributor).transferFrom(address(this), msg.sender, productId);
    }
}