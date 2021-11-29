// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/ICHYME.sol";
import "./interfaces/IERC20Burnable.sol";



/// @title Split and Merge Token Chyme
/// TODO: Add reentrancy guard
contract Alchemist is ReentrancyGuard, Initializable {

    ICHYME public Chyme;
    IERC20Burnable public steady;
    IERC20Burnable public elixir;
    address public steadyAddr;
    address public elixirAddr;
    address public priceOracle;

    event Split(address indexed source, uint256 splitAmount, int256 price);
    event Merge(address indexed source, uint256 mergedAmount, int256 price);

    struct TokenInfo {
        uint256 balance;
        uint256 amount;
    }

    function initialize( address _Chyme,
        address _Steady,
        address _Elixir,
        address _priceOracle) public initializer {
        __Alchemist_init(  _Chyme,
         _Steady,
         _Elixir,
         _priceOracle);
    }

    function __Alchemist_init(
        address _Chyme,
        address _Steady,
        address _Elixir,
        address _priceOracle
    )  internal initializer {
        Chyme = ICHYME(_Chyme);
        steady = IERC20Burnable(_Steady);
        elixir = IERC20Burnable(_Elixir);
        steadyAddr = _Steady;
        elixirAddr = _Elixir;
        priceOracle = _priceOracle; // 0x34BCe86EEf8516282FEE6B5FD19824163C2B5914;
    }

    function getSteadyAddr() public view returns(address) {
        return steadyAddr;
    }

    function getElixirAddr() public view returns(address) {
        return elixirAddr;
    }

    /// @dev This splits an amount of Chyme into two parts one is Steady tokens which is the 3/4 the token in dollar value
    /// @dev The rest is in Elixir tokens which is 1/4th of the token in original form
    function split(uint256 amount) 
        external 
        nonReentrant() 
        returns (bool) 
    {

        require(amount >= 10); //minimum amount that can be split is 10 units or 0.0000001 Grams
        uint256 balanceOfSender = Chyme.balanceOf(msg.sender);
        require(amount <= balanceOfSender, "You do not have enough Chyme");

        //minimumn price of 0.00000001 and max price of 100000000000
        int256 price = priceFromOracle();

        uint256 sChymeamt = (amount * 75 * uint256(price)) / 10000000000; // should have twice the amount of Steady.
        //transfer the Chyme tokens to the splitter contract
        Chyme.transferFrom(msg.sender, address(this), amount);
        steady.mint(msg.sender, sChymeamt);
        elixir.mint(msg.sender, (amount * 25 ) / 100 / 10 * 10);

        // Remove this


        //
        emit Split(msg.sender, amount, price);
        return true;
    }

    /// @notice This merges an amount of Chyme from two parts one part Steady tokens and another Elixir tokens
    /// @dev Pass in the total amount of Chyme that you expect, it will increase the allowance accordingly
    function merge(uint256 ChymeAmountToMerge) 
        external 
        nonReentrant() 
        returns (bool) 
    {
        require(ChymeAmountToMerge >= 10); //minimum amount that can be merged is 10 units or 0.0000001 Grams

        TokenInfo memory __elixir;
        TokenInfo memory __steady;

        int256 price = priceFromOracle();
       
        __steady.amount = (ChymeAmountToMerge * 75 * uint256(price)) / 10000000000;
        __elixir.amount = (ChymeAmountToMerge * 25) / 100;
        __steady.balance = IERC20Burnable(steady).balanceOf(msg.sender);
        __elixir.balance = IERC20Burnable(elixir).balanceOf(msg.sender);

        require(__elixir.amount <= __elixir.balance, "Need more Elixir");
        require(__steady.amount <= __steady.balance, "Need more Steady");
        //approve Chyme from this address to the msg.sender
        Chyme.approve(msg.sender, ChymeAmountToMerge);



        elixir.burnFrom(msg.sender, __elixir.amount);
        steady.burnFrom(msg.sender, __steady.amount);

        emit Merge(msg.sender, ChymeAmountToMerge, price);
        return true;
    }

    /// @dev Oracle price for Chyme utilizing chainlink
    function priceFromOracle() public view returns (int256 price) {
        // bytes memory payload = abi.encodeWithSignature("getLatestPrice()");
        bytes memory payload = abi.encodeWithSignature("latestAnswer()");
        (, bytes memory returnData) = address(priceOracle).staticcall(payload);
        (price) = abi.decode(returnData, (int256));
        //minimumn price of 0.00000001 and max price of 1 Trillion
        require(price >= 1 && price <= 1000000000000000000000000000000, "Oracle price is out of range");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ICHYME {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    
    function approve(
        address spender, 
        uint256 addedValue
    ) external returns (bool);

    function balanceOf(address owner) 
    external 
    view 
    returns (uint256);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20Burnable {
    function mint(address to, uint256 amount) external;   
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address owner) external view returns (uint256);
}