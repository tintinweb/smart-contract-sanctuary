// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * Contract that exposes the needed erc20 token functions
*/

abstract contract ERC20Interface {

    /*
    * @dev Send _value amount of tokens to address _to
    * @param _to The destination address
    * @param _value The amount to sent
    */
    function transfer(address _to, uint256 _value) public virtual returns (bool success);

    /*
    * @dev Get the account balance of another account with address _owner
    * @param _owner The address owner
    */
    function balanceOf(address _owner) public virtual view returns (uint256 balance);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * Contract that exposes the needed erc721 token functions
*/

abstract contract ERC721Interface {

    /*
    * @dev Send _tokenId token to address _to
    * @param _from The address where the token is assigned
    * @param _to The destination address of the token
    * @param _tokenId The token id
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual;

    /*
    * @dev Get the balance of this contract of address owner
    * @param _owner The address where we want to know the balance
    */
    function balanceOf(address _owner) public virtual view returns (uint256 balance);

    /*
    * @dev Returns a token ID owned by owner at a given index of its token list. Use along with balanceOf to enumerate all of owner's tokens.
    * @param _owner The owner address
    * @param _index The index of the token (related to balanceOf)
    */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public virtual view returns (uint256 tokenId);

    /*
    * @dev Returns if the operator is allowed to manage all of the assets of owner.
    * @param _owner The owner address
    * @param _operator The operator address
    */
    function isApprovedForAll(address _owner, address _operator) public virtual view returns (bool approved);

    /*
    * @dev Approve or remove operator as an operator for the caller. Operators can call transferFrom or safeTransferFrom for any token owned by the caller.
    * @param _owner The operator address
    * @param _approved Flag is approved or not
    */
    function setApprovalForAll(address _operator, bool _approved) public virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import './ERC20Interface.sol';
import './ERC721Interface.sol';

contract GenuWallet is Ownable, Pausable, IERC721Receiver {

    /*
     * Constants
    */

    bytes4 private constant ERC721_RECEIVED = 0x150b7a02; // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`

    /*
     * Events
    */
    event Deposited(address indexed from, uint256 indexed value);
    event Transacted(address indexed msgSender, address indexed toAddress, uint256 indexed value);
    event TransactedERC721(address indexed msgSender, address indexed toAddress, uint256[] indexed tokenIds);

    /**
      * Gets called when a transaction is received with data that does not match any other method
    */
    fallback() external payable {
        // Fire deposited event if we are receiving funds
        emit Deposited(msg.sender, msg.value);
    }

    /**
      * Gets called when a transaction is received with ether and no data
    */
    receive() external payable {
        // Fire deposited event if we are receiving funds
        emit Deposited(msg.sender, msg.value);
    }

    /**
      * @dev Pause the contract
    */
    function pause() public onlyOwner {
        _pause();
    }

    /**
      * @dev Unpause the contract
    */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
      * @dev Get the balance of this contract related to token ERC721 contract address passed as argument
      * @param tokenContractAddress The contract address
    */
    function balanceOfERC721(address tokenContractAddress) public view onlyOwner returns(uint256) {
        ERC721Interface _instance = ERC721Interface(tokenContractAddress);
        address _contractAddress = address(this);
        uint256 _balance = _instance.balanceOf(_contractAddress);
        return _balance;
    }

    /**
      * @dev Get the balance of this contract related to token ERC20 contract address passed as argument
      * @param tokenContractAddress The contract address
    */
    function balanceOfERC20(address tokenContractAddress) public view onlyOwner returns(uint256) {
        ERC20Interface _instance = ERC20Interface(tokenContractAddress);
        address _contractAddress = address(this);
        uint256 _balance = _instance.balanceOf(_contractAddress);
        return _balance;
    }

    /**
      * Send Funds to the address specified
      *
      * @param toAddress the destination address to send an outgoing transaction
      * @param value the amount in Wei to be sent
    */
    function sendFunds(address toAddress, uint256 value, bytes calldata data) external onlyOwner whenNotPaused {
        // Success, send the transaction
        (bool success, ) = toAddress.call{ value: value }(data);
        require(success, 'Call execution failed');

        emit Transacted(msg.sender, toAddress, value);
    }

    /*
      * Send tokens ERC2O to the address specified
      *
      * @param toAddress the destination address to send an outgoing transaction
      * @param value the amount in tokens to be sent
      * @param tokenContractAddress the address of the erc20 token contract
    */
    function sendTokensERC20(address toAddress, uint256 value, address tokenContractAddress) external onlyOwner whenNotPaused {
        TransferHelper.safeTransfer(tokenContractAddress, toAddress, value);
    }

    /**
      * Send ERC721 tokens to the address specified
      *
      * @param toAddress the destination address to send an outgoing transaction
      * @param tokenIds the tokens to transfer
      * @param tokenContractAddress the address of the erc20 token contract
    */
    function sendTokensERC721(address toAddress, uint256[] calldata tokenIds, address tokenContractAddress) external onlyOwner whenNotPaused {
        require(tokenIds.length > 0, "tokenIds must be an array of length greater than zero.");

        ERC721Interface _instance = ERC721Interface(tokenContractAddress);
        address _contractAddress = address(this);
        require(_instance.balanceOf(_contractAddress) > 0, "The balance is equal to zero. No items found for this contract address.");

        if (_instance.isApprovedForAll(_contractAddress, toAddress) == false) {
            _instance.setApprovalForAll(toAddress, true);
        }

        for(uint256 i = 0; i < tokenIds.length; i++) {
            _instance.safeTransferFrom(_contractAddress, toAddress, tokenIds[i]);
        }

        emit TransactedERC721(msg.sender, toAddress, tokenIds);
    }

    /**
      * @dev Override
      * @param operator The address operator
      * @param from The address from
      * @param tokenId The token id
      * @param data The data
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        return ERC721_RECEIVED;
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "berlin",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}