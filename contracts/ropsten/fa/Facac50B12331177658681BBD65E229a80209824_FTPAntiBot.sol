// SPDX-License-Identifier: MIT
// po-dev
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FTPAntiBot is Context, Ownable {
    bool private m_TradeOpen = true;
    mapping(address => bool) private m_IgnoreTradeList;
    mapping(address => bool) private m_WhiteList;
    mapping(address => bool) private m_BlackList;

    address private m_UniswapV2Pair;
    address private m_UniswapV2Router =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    event addressScanned(
        address _address,
        address safeAddress,
        address _origin
    );
    event blockRegistered(address _recipient, address _sender);

    function setUniswapV2Pair(address pairAddress) external onlyOwner {
        m_UniswapV2Pair = pairAddress;
    }

    function getUniswapV2Pair() external view returns (address) {
        return m_UniswapV2Pair;
    }

    function setWhiteList(address _address) external onlyOwner {
        m_WhiteList[_address] = true;
    }

    function removeWhiteList(address _address) external onlyOwner {
        m_WhiteList[_address] = false;
    }

    function isWhiteListed(address _address) external view returns (bool) {
        return m_WhiteList[_address];
    }

    function setBlackList(address _address) external onlyOwner {
        m_BlackList[_address] = true;
    }

    function removeBlackList(address _address) external onlyOwner {
        m_BlackList[_address] = false;
    }

    function isBlackListed(address _address) external view returns (bool) {
        return m_BlackList[_address];
    }

    function setTradeOpen(bool tradeOpen) external onlyOwner {
        m_TradeOpen = tradeOpen;
    }

    function getTradeOpen() external view returns (bool) {
        return m_TradeOpen;
    }

    function scanAddress(
        address _address,
        address safeAddress,
        address _origin
    ) external returns (bool) {
        emit addressScanned(_address, safeAddress, _origin);
        return false;
    }

    function registerBlock(address _sender, address _recipient) external {
        if (!m_TradeOpen)
            require(!_isTrade(_sender, _recipient), "Can't Trade");

        require(
            !m_BlackList[_sender] && !m_BlackList[_recipient],
            "Address is in blacklist"
        );
        emit blockRegistered(_recipient, _sender);
    }

    function _isBuy(address _sender, address _recipient)
        private
        view
        returns (bool)
    {
        return
            _sender == m_UniswapV2Pair &&
            _recipient != address(m_UniswapV2Router) &&
            !m_WhiteList[_recipient];
    }

    function _isSale(address _sender, address _recipient)
        private
        view
        returns (bool)
    {
        return
            _recipient == m_UniswapV2Pair &&
            _sender != address(m_UniswapV2Router) &&
            m_WhiteList[_sender];
    }

    function _isTrade(address _sender, address _recipient)
        private
        view
        returns (bool)
    {
        return _isBuy(_sender, _recipient) || _isSale(_sender, _recipient);
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