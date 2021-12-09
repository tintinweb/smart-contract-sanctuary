// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./ERC20Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Contract that will forward any incoming Ether to the creator of the contract
 *
 */
contract Forwarder is Ownable {
    // Address to which any funds sent to this contract will be forwarded
    address public parentAddress;
    event ForwarderDeposited(address from, uint256 value, bytes data);

    // override inherited ownable
    address private ownerAddress;

    function owner() public view override returns (address) {
        return ownerAddress;
    }

    function renounceOwnership() public override onlyOwner {
        emit OwnershipTransferred(ownerAddress, address(0));
        ownerAddress = address(0);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(ownerAddress, newOwner);
        ownerAddress = newOwner;
    }

    // qw's custom event
    event ParentSwitched(address currentParent, address newParent);

    function setParent(address _newParent) external onlyOwner {
        address _currentParent = parentAddress;
        parentAddress = _newParent;
        emit ParentSwitched(_currentParent, _newParent);
    }

    /**
     * Initialize the contract, and sets the destination address to that of the creator
     */
    function init(address _parentAddress, address _ownerAddress)
        external
        onlyUninitialized
    {
        parentAddress = _parentAddress;
        ownerAddress = _ownerAddress;

        uint256 value = address(this).balance;

        if (value == 0) {
            return;
        }

        (bool success, ) = parentAddress.call{value: value}("");
        require(success, "Flush failed");
        // NOTE: since we are forwarding on initialization,
        // we don't have the context of the original sender.
        // We still emit an event about the forwarding but set
        // the sender to the forwarder itself
        emit ForwarderDeposited(address(this), value, msg.data);
    }

    /**
     * Modifier that will execute internal code block only if the sender is the parent address
     */
    modifier onlyParent() {
        require(msg.sender == parentAddress, "Only Parent");
        _;
    }

    /**
     * Modifier that will execute internal code block only if the contract has not been initialized yet
     */
    modifier onlyUninitialized() {
        require(parentAddress == address(0x0), "Already initialized");
        _;
    }

    /**
     * Default function; Gets called when data is sent but does not match any other function
     */
    fallback() external payable {
        flush();
    }

    /**
     * Default function; Gets called when Ether is deposited with no data, and forwards it to the parent address
     */
    receive() external payable {
        flush();
    }

    /**
     * Execute a token transfer of the full balance from the forwarder token to the parent address
     * @param tokenContractAddress the address of the erc20 token contract
     */
    function flushTokens(address tokenContractAddress) external onlyParent {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        address forwarderAddress = address(this);
        uint256 forwarderBalance = instance.balanceOf(forwarderAddress);
        if (forwarderBalance == 0) {
            return;
        }

        TransferHelper.safeTransfer(
            tokenContractAddress,
            parentAddress,
            forwarderBalance
        );
    }

    /**
     * Flush the entire balance of the contract to the parent address.
     */
    function flush() public {
        uint256 value = address(this).balance;

        if (value == 0) {
            return;
        }

        (bool success, ) = parentAddress.call{value: value}("");
        require(success, "Flush failed");
        emit ForwarderDeposited(msg.sender, value, msg.data);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

/**
 * Contract that exposes the needed erc20 token functions
 */

abstract contract ERC20Interface {
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool success);

    // Get the account balance of another account with address _owner
    function balanceOf(address _owner)
        public
        view
        virtual
        returns (uint256 balance);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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