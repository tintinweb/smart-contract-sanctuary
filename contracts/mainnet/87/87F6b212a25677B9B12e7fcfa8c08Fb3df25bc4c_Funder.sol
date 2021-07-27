/*
    Copyright 2021 Empty Set Squad <[email protected]>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Funder is Ownable {
    uint256 private constant ONE_PERCENT = 16_500_000 ether;
    uint256 private constant DEFI_PULSE_TREASURY_AMOUNT = 5_000_000 ether;

    address private constant EMPTY_SET_TREASURY = address(0x460661bd4A5364A3ABCc9cfc4a8cE7038d05Ea22);
    address private constant DEFI_PULSE_TREASURY = address(0x866613c804Be33e9D7899a41D4EfE880c0de1FaD);

    IRegistry public registry;
    address public incentivizerUniswap;
    address public incentivizerCurve;
    address public sn2Vester;
    address public dfpVester;
    address public eqlVester;

    constructor(
        IRegistry _registry,
        address _incentivizerUniswap,
        address _incentivizerCurve,
        address _sn2Vester,
        address _dfpVester,
        address _eqlVester
    ) public {
        registry = _registry;
        incentivizerUniswap = _incentivizerUniswap;
        incentivizerCurve = _incentivizerCurve;
        sn2Vester = _sn2Vester;
        dfpVester = _dfpVester;
        eqlVester = _eqlVester;
    }

    function distribute() external onlyOwner {
        IStake stake = registry.stake();

        // Mint
        uint256 stakeAmount;
        stakeAmount += ONE_PERCENT * 103;                                // Migrator
        stakeAmount += (ONE_PERCENT * 3) + DEFI_PULSE_TREASURY_AMOUNT;   // Treasuries
        stakeAmount += ONE_PERCENT * 3;                                  // Incentivizers
        stakeAmount += ONE_PERCENT * 9;                                  // Grants
        stake.mint(stakeAmount);

        // Migrator
        stake.transfer(registry.migrator(), ONE_PERCENT * 103);

        // Treasury
        stake.transfer(EMPTY_SET_TREASURY, ONE_PERCENT * 3);
        stake.transfer(DEFI_PULSE_TREASURY, DEFI_PULSE_TREASURY_AMOUNT);

        // Incentivizer
        if (incentivizerUniswap != address(0)) stake.transfer(incentivizerUniswap, ONE_PERCENT * 1); // Uniswap
        if (incentivizerCurve != address(0)) stake.transfer(incentivizerCurve, ONE_PERCENT * 2); // Curve

        // Grants
        if (sn2Vester != address(0)) stake.transfer(sn2Vester, ONE_PERCENT * 2);
        if (dfpVester != address(0)) stake.transfer(dfpVester, ONE_PERCENT * 1);
        if (eqlVester != address(0)) stake.transfer(eqlVester, ONE_PERCENT * 6);

        stake.transfer(registry.reserve(), stake.balanceOf(address(this)));

        // Renounce ownership
        stake.transferOwnership(registry.reserve());
    }
}

contract IStake is IERC20 {
    function mint(uint256 amount) external;
    function transferOwnership(address newOwner) external;
}

interface IRegistry {
    function migrator() external returns (address);
    function stake() external returns (IStake);
    function reserve() external returns (address);
}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
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