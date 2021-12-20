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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

contract BaseCoverOffChain is Ownable {
    using Counters for Counters.Counter;

    event BuyProduct(uint256 indexed _productId, address _buyer);
    event SetExchangeAgent(address _setter, address _exchangeAgent);

    Counters.Counter public productIds;
    mapping(uint256 => address) private _ownerOf; // productId => owner
    mapping(address => uint64) private _balanceOf; // owner => balance We can think one user can buy max 2**64 products
    mapping(address => uint64[]) private _productsOf; // owner => productIds[]

    mapping(address => bool) public availableCurrencies;

    address public immutable WETH;
    address public exchangeAgent;
    address public devWallet;

    constructor(
        address _WETH,
        address _exchangeAgent,
        address _devWallet
    ) {
        WETH = _WETH;
        exchangeAgent = _exchangeAgent;
        devWallet = _devWallet;
    }

    modifier onlyAvailableToken(address _token) {
        require(availableCurrencies[_token], "Not allowed token");
        _;
    }

    receive() external payable {}

    function setExchangeAgent(address _exchangeAgent) external onlyOwner {
        require(_exchangeAgent != address(0), "ZERO Address");
        exchangeAgent = _exchangeAgent;
        emit SetExchangeAgent(msg.sender, _exchangeAgent);
    }

    function _setProductOwner(uint256 _prodId, address _owner) internal {
        _ownerOf[_prodId] = _owner;
    }

    function ownerOf(uint256 _prodId) public view returns (address) {
        require(_prodId < productIds.current() + 1, "Invalid product ID");
        return _ownerOf[_prodId];
    }

    function _increaseBalance(address _account) internal {
        _balanceOf[_account]++;
    }

    function balanceOf(address _account) public view returns (uint64) {
        return _balanceOf[_account];
    }

    function _buyProduct(address _buyer, uint256 _pid) internal {
        _productsOf[_buyer].push(uint64(_pid));
        emit BuyProduct(_pid, _buyer);
    }

    function productOf(address _owner, uint64 _idx) public view returns (uint64) {
        return _productsOf[_owner][_idx];
    }

    function addCurrency(address _currency) external onlyOwner {
        require(!availableCurrencies[_currency], "Already available");
        availableCurrencies[_currency] = true;
    }

    function removeCurrency(address _currency) external onlyOwner {
        require(availableCurrencies[_currency], "Not available yet");
        availableCurrencies[_currency] = false;
    }

    function permit(
        address _sender,
        bytes32 _digest,
        bytes memory sig
    ) internal pure virtual {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(sig);
        address recoveredAddress = ecrecover(_digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == _sender, "CoverCompared: INVALID_SIGNATURE");
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IExchangeAgent.sol";
import "../libs/TransferHelper.sol";
import "./BaseCoverOffChain.sol";

contract MSOCover is Ownable, ReentrancyGuard, BaseCoverOffChain {
    using Counters for Counters.Counter;

    event BuyMSO(
        uint256 indexed _productId,
        uint256 _amount,
        uint256 _priceInUSD,
        uint256 _conciergePrice,
        address _buyer,
        address _currency
    );

    struct Product {
        string policyId;
        uint256 priceInUSD;
        uint256 period;
        uint256 startTime;
        uint256 conciergePrice;
    }

    mapping(uint256 => Product) public products; // productId => product

    constructor(
        address _WETH,
        address _exchangeAgent,
        address _devWallet
    ) BaseCoverOffChain(_WETH, _exchangeAgent, _devWallet) {}

    /**
     * @dev buyProductByETH function:
     */
    function buyProductByETH(
        string memory policyId,
        uint256 priceInUSD,
        uint256 period,
        uint256 conciergePrice,
        bytes memory sig
    ) external payable nonReentrant {
        uint256 usdPrice = priceInUSD + conciergePrice;

        bytes32 digest = getSignedMsgHash(policyId, priceInUSD, period, conciergePrice);
        permit(msg.sender, digest, sig);

        uint256 tokenAmount = IExchangeAgent(exchangeAgent).getETHAmountForUSDC(usdPrice);
        require(msg.value >= tokenAmount, "Insufficient amount");
        if (msg.value > tokenAmount) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - tokenAmount);
        }
        TransferHelper.safeTransferETH(devWallet, tokenAmount);

        uint256 _pid = buyProduct(policyId, priceInUSD, period, conciergePrice, msg.sender);

        emit BuyMSO(_pid, tokenAmount, priceInUSD, conciergePrice, msg.sender, WETH);
    }

    /**
     * @dev buyProductByToken function:
     */
    function buyProductByToken(
        string calldata policyId,
        uint256 priceInUSD,
        uint256 period,
        address _token,
        uint256 conciergePrice,
        bytes memory sig
    ) external nonReentrant onlyAvailableToken(_token) {
        uint256 usdPrice = priceInUSD + conciergePrice;

        bytes32 digest = getSignedMsgHash(policyId, priceInUSD, period, conciergePrice);
        permit(msg.sender, digest, sig);

        uint256 tokenAmount = IExchangeAgent(exchangeAgent).getTokenAmountForUSDC(_token, usdPrice);
        TransferHelper.safeTransferFrom(_token, msg.sender, devWallet, tokenAmount);

        uint256 _pid = buyProduct(policyId, priceInUSD, period, conciergePrice, msg.sender);
        emit BuyMSO(_pid, tokenAmount, priceInUSD, conciergePrice, msg.sender, _token);
    }

    function buyProduct(
        string memory _policyId,
        uint256 priceInUSD,
        uint256 period,
        uint256 conciergePrice,
        address _sender
    ) private returns (uint256 _pid) {
        _pid = productIds.current();
        products[_pid] = Product({
            policyId: _policyId,
            priceInUSD: priceInUSD,
            period: period,
            startTime: block.timestamp,
            conciergePrice: conciergePrice
        });

        _setProductOwner(_pid, _sender);
        _increaseBalance(_sender);
        _buyProduct(_sender, _pid);
        productIds.increment();
    }

    function getSignedMsgHash(
        string memory productName,
        uint256 priceInUSD,
        uint256 period,
        uint256 conciergePrice
    ) internal pure returns (bytes32) {
        bytes32 msgHash = keccak256(abi.encodePacked(productName, priceInUSD, period, conciergePrice));
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
    }
}