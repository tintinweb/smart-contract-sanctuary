pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPositionToken.sol";

contract PosiTreasury is Ownable {

    address public positionStakingManager;
    address public insuranceFund;
    IPositionToken public posi;

    uint256 public maxMintAmount = 10*100000*10**18;

    modifier onlyCounterParty {
        require(positionStakingManager == msg.sender || insuranceFund == msg.sender, "not authorized");
        _;
    }

    constructor(IPositionToken _posi) {
        posi = _posi;
    }

    function myBalance() public view returns (uint256) {
        return posi.balanceOf(address(this));
    }

    function mint(address recipient, uint256 amount) public onlyCounterParty {
        if(myBalance() < amount){
            posi.mint(address(this), calulateMintAmount(amount));
        }
        posi.treasuryTransfer(recipient, amount);
    }

    function burn(uint256 amount) public onlyOwner {
        posi.burn(amount);
    }

    function setPositionStakingManager(address _newAddress) public onlyOwner {
        positionStakingManager = _newAddress;
    }

    function setInsuranceFund(address _newAddress) public onlyOwner {
        insuranceFund = _newAddress;
    }

    function setPosition(IPositionToken _newPosi) public onlyOwner {
        posi = _newPosi;
    }

    function setMaxMintAmount(uint256 amount) public onlyOwner {
        maxMintAmount = amount;
    }

    function calulateMintAmount(uint256 amount) private view returns (uint256 amountToMint) {
        uint256 baseAmount = posi.BASE_MINT();
        amountToMint = baseAmount*(amount/baseAmount+1);
        require(amountToMint < maxMintAmount, "Max exceed");
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

interface IPositionToken {
    function BASE_MINT() external view returns (uint256);
    function mint(address receiver, uint256 amount) external;
    function burn(uint amount) external;
    function treasuryTransfer(address[] memory recipients, uint256[] memory amounts) external;
    function treasuryTransfer(address recipient, uint256 amount) external;
    function transferTaxRate() external view returns (uint16) ;
    function balanceOf(address account) external view returns (uint256) ;
    function transfer(address to, uint value) external returns (bool);
    function isGenesisAddress(address account) external view returns (bool);
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

