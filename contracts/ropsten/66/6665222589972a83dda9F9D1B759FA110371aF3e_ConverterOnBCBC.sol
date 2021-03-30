/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts/ConverterOnBCBC.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;


/**
 *  This contract should be deployed on Ethereum
 */
contract ConverterOnBCBC is Ownable {
    /**
     *  Event when the bridge unlocked BCERTs on BCBC
     *
     *  @param _fromEthereum            funds sender on Ethereum network
     *  @param _toBCBC                  funds receiver on BCBC network
     *  @param _amount                  amount to convert
     */
    event Unlocked(
        address indexed _fromEthereum,
        address indexed _toBCBC,
        uint256 _amount
    );

    /**
     *  Event when user sent BCERTs to this contract to convert to WBCERT.
     *
     *  @param _fromBCBC                funds sender on BCBC network
     *  @param _toEthereum              funds receiver on Ethereum network
     *  @param _amount                  amount to convert
     */
    event ConvertToEthereum(
        address indexed _fromBCBC,
        address indexed _toEthereum,
        uint256 _amount
    );

    constructor() public {}

    /**
     *  When the bridge receives the event ConvertToBCBC on Ethereum network
     *  it will unlock BCERTs on BCBC Network and transfer to the receiver.
     *  This function can be only called by owner(the bridge)
     *
     *  @param _fromEthereum            funds sender on Ethereum network
     *  @param _toBCBC                  funds receiver on BCBC network
     *  @param _amount                  amount to convert
     */
    function unlock(
        address _fromEthereum,
        address payable _toBCBC,
        uint256 _amount
    ) public onlyOwner {
        require(address(this).balance >= _amount, "insufficient balance");

        _toBCBC.transfer(_amount);
        emit Unlocked(_fromEthereum, _toBCBC, _amount);
    }

    /**
     *  Accept/unlock BCERTs and emit an event ConvertToEthereum.
     *  When the bridge receives the event ConvertToEthereum on BCBC network,
     *  mint same mount of WBCERTs on Ethereum and transfer to the receiver
     *
     *  @param _toEthereum              funds receiver on Ethereum network
     */
    function convertToEthereum(address _toEthereum) public payable {
        require(msg.value > 0, "zero not allowed");
        emit ConvertToEthereum(msg.sender, _toEthereum, msg.value);
    }
}