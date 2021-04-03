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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.8.0;

import "../access/Ownable.sol";

contract LandOracle is Ownable {
    uint256 public lastLandIndexTokenPerEth;
    uint256 public landPriceInMana;

    constructor() public {}

    mapping(address => bool) public oracleWhitelist;

    modifier OracleWhitelist() {
        require(
            oracleWhitelist[msg.sender] == true,
            "You don't have permission to update the price."
        );
        _;
    }

    function setOracleWhitelist(address _address) public onlyOwner {
        oracleWhitelist[_address] = true;
    }

    /**
     * Returns the latest ETH price in USD
     */
    //  1800 aka 18000000000000000000000
    function getLatestETHPrice() public view returns (uint256) {
        int256 ETHprice = 194708712224;
        return uint256(ETHprice);
    }

    // 1.1 aka 1100000000000000000
    // How much mana for 1 eth = 1800 * 1.1
    function getLatestManaPrice() public view returns (uint256) {
        int256 MANAprice = 998893000000000000;
        return uint256(MANAprice);
    }

    //1944931696795680320000
    function ManaPerEth() public view returns (uint256) {
        uint256 ManaPrice = getLatestManaPrice();
        uint256 ETHPrice = getLatestETHPrice();
        return (ManaPrice * ETHPrice) / 1e8;
    }

    function LandIndexTokenPerEth() public returns (uint256) {
        // Possibly doesn't set the landPriceInMana while running this function
        // Possibly takes previous landPriceInMana when calling the function.
        requestLandData();
        uint256 manaPerEth = ManaPerEth();
        // 40 000 / (1.1 * 1800) = 20
        // One token will cost 20 ETH
        // 1944931696795680320000 * 1e18 / 51624533333333340000000
        lastLandIndexTokenPerEth = (manaPerEth * 1e18) / landPriceInMana;
        return lastLandIndexTokenPerEth;
    }

    function requestLandData() public OracleWhitelist {
        fulfill(51624533333333340000000);
    }

    /**
     * Receive the response in the form of uint256
     */

    function fulfill(uint256 _landPriceInMana) public {
        landPriceInMana = _landPriceInMana;
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
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