// SPDX-License-Identifier: MIT
                                                                    
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IAlphaWolves {
    function balanceGenesis(address) external view returns (uint256);
    function mint(address wolfOwnerAddress, uint256 tokenId) external;
    function maxAlphaWolfSupply() external view returns (uint256);
}

interface IWolfMeat {
  function mint(address, uint256) external;
  function balanceOf(address) external returns (uint256);
  function burn(uint256) external;
  function burnFrom(address, uint256) external;
}

contract AlphaWolvesClone is Ownable {

    IAlphaWolves public AlphaWolves;
    IWolfMeat public WolfMeat;

    uint256 public maxGenCount;
    uint256 public betaWolfCount;

    event CloneWolfEvent(uint256 alphaWolfId);


    function setAlphaWolves(address AlphaWolvesAddress) external onlyOwner {
        AlphaWolves = IAlphaWolves(AlphaWolvesAddress);
    }

    function setWolfMeat(address _WolfMeatAddress) external onlyOwner {
        WolfMeat = IWolfMeat(_WolfMeatAddress);
    }

    modifier onlyWolfOwner(address wolfOwnerAddress) {
        uint256 wolvesOwned = AlphaWolves.balanceGenesis(wolfOwnerAddress);
        require(wolvesOwned > 0, "You do not have any wolves to clone");
        _;
    }

    function getClonePrice() public view returns(uint256){
        uint256 clonePrice;

        if (betaWolfCount > 4000) {
            clonePrice = 90;
        } else if (betaWolfCount > 3000) {
            clonePrice = 75;
        } else if (betaWolfCount > 2000) {
            clonePrice = 60;
        } else if (betaWolfCount > 1000) {
            clonePrice = 45;
        } else if (betaWolfCount >= 0) {
            clonePrice = 30;
        }

        return clonePrice;
    }

    //TODO: add authorization
    function clone(address wolfOwnerAddress) public onlyWolfOwner(wolfOwnerAddress) { 
        uint256 clonePrice = getClonePrice();
        uint256 meatTokensInWallet = WolfMeat.balanceOf(wolfOwnerAddress);
        require(meatTokensInWallet >= clonePrice, "You do not have enough MEAT to clone wolves");
        require(betaWolfCount < 5000, "Cannot clone any more beta wolves");
        //WolfMeat.burnFrom(wolfOwnerAddress, clonePrice); TODO: Look into the approve stuff
        uint256 numberOfMints = 1; //getRandomNumber();

        for (uint256 i = 0; i < numberOfMints; i++) {
            uint256 betaWolfId = betaWolfCount + AlphaWolves.maxAlphaWolfSupply() + 1;
            AlphaWolves.mint(wolfOwnerAddress, betaWolfId);
            betaWolfCount++;
        }
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