// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './utils/Ownable.sol';
import './utils/HelperOwnable.sol';


interface ITokenPool {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
    function mint(address account, uint256 amount) external;
}

contract Pool is HelperOwnable, Ownable {
    ITokenPool public token;

    constructor(address _token) {
        token = ITokenPool(_token);
    }

    function pay(address _to, uint _amount) external onlyHelper returns (bool) {
        if(token.balanceOf(address(this)) >= _amount) {
            return token.transfer(_to, _amount);
        }
        else {
            token.mint(_to, _amount);
            return true;
        }
    }

    function transferHelperOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit HelperOwnershipTransferred(_helperContract, newOwner);
        _helperContract = newOwner;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Context.sol';

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
pragma solidity ^0.8.0;

import './Context.sol';

contract HelperOwnable is Context {
    address internal _helperContract;

    event HelperOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Returns the address of the current owner.
     */
    function helperContract() public view returns (address) {
        return _helperContract;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyHelper() {
        require(_helperContract == _msgSender(), "Ownable: caller is not the helper");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}