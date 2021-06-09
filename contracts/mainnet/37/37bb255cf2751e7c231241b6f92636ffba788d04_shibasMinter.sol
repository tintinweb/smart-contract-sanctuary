/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @openzeppelin/contracts/GSN/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File contracts/minter.sol

pragma solidity ^0.6.6;

interface Shibas
{
    function mint (address mint_to) external;
    function balanceOf (address query) external returns (uint256);
}

contract shibasMinter is  Pausable{
    address public shibasAddress=0xF6980461628CF54a234d39b1c52FeCcfFB5A9407;
    Shibas shibas;
    constructor() public
    {
        shibas=Shibas(shibasAddress);
    }
    function mintShibas (uint256 qty) external whenNotPaused
    {
        if (qty==0){
            qty=1;
        }
        require (qty <=5,"can only mint 5 at a time");
        uint256 balance = shibas.balanceOf(address(msg.sender));
        require (balance <20,"limited to 20");
        if ((qty+balance)>=20){
            qty= 20-balance;
        }
        for (uint i = 1; i <= qty; i++) {
            shibas.mint(address(msg.sender));
        }
    }
}