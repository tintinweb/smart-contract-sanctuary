// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDragonEgg.sol";
contract DragonEggMinter is Ownable {

    address[] public tokens;
    constructor() {
        tokens.push(address(0x07523E89548235649dF7B9bE70C9e75161a0cFc8));
        tokens.push(address(0x52B0c7F0652047702Fd15688138F70a7feFF3FA2));
        tokens.push(address(0xEAFdA4cea45FB96f3ff98b2cA94f5f706483ed01));
        tokens.push(address(0xBB85355c0aA271d72E33936aD64B62F45cAbFa6a));
    }

    /**
    Testing purpose, do not deploy on prod
    */
    function mintAll(uint amount, address[] calldata receivers) public {
        for(uint i = 0; i < tokens.length; i++) {
            for(uint j = 0; j < receivers.length; j++) {
                mint(tokens[i], receivers[j], amount);
            }
        }
    }
    /**
    Testing purpose, do not deploy on prod
    */

    function mint(address token, address to, uint amount) public  {
        for(uint i=0;i<amount;i++) {
            IDragonEgg(token).mint(to);
        }
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

pragma solidity ^0.8.0;

interface IDragonEgg {
    function mint(address to) external returns(uint tokenId);
    function changeUseTokenUriFlag(bool newUseTokenIdInUri) external;
    function changeBaseURI(string calldata newBaseUri) external;
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