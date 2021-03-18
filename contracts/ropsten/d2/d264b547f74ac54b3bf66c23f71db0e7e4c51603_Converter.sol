/**
 *Submitted for verification at Etherscan.io on 2021-03-18
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

// File: contracts/interfaces/IWBCERT.sol

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title   IWBCERT
 * @author  BlockCerts
 *
 * Interface for WBCERT(ERC20 compatible) token
 */
contract IWBCERT {
    function mint(address _to, uint256 _amount) external {}

    function burn(address _from, uint256 _amount) external {}
}

// File: contracts/Converter.sol

pragma solidity >=0.6.0 <0.9.0;



contract Converter is Ownable {
    IWBCERT wbcert;

    event ConvertToBCBC(
        address indexed _fromEthereum,
        address indexed _toBCBC,
        uint256 _amount
    );

    event ConvertToEthereum(
        address indexed _fromBCBC,
        address indexed _toEthereum,
        uint256 _amount
    );

    constructor(IWBCERT _wbcert) public {
        wbcert = _wbcert;
    }

    /**
     *  Send funds to the account after him freezed tokens on ethereum network
     *
     *  @param _fromEthereum            frozen tokens account
     *  @param _toBCBC                  funds receiver
     *  @param _amount                  amount of frozen tokens
     */
    function convertToBCBC(
        address _fromEthereum,
        address _toBCBC,
        uint256 _amount
    ) public onlyOwner {
        wbcert.burn(_fromEthereum, _amount);
        emit ConvertToBCBC(_fromEthereum, _toBCBC, _amount);
    }

    /**
     *  Freeze funds for receive they on the ethereum network
     *
     *  @param _fromBCBC                  funds receiver
     *  @param _toEthereum            frozen tokens account
     *  @param _amount                  amount of frozen tokens
     */
    function convertToEthereum(
        address _fromBCBC,
        address _toEthereum,
        uint256 _amount
    ) public onlyOwner {
        wbcert.mint(_toEthereum, _amount);
        emit ConvertToEthereum(_fromBCBC, _toEthereum, _amount);
    }

    // receive() external payable {}
}