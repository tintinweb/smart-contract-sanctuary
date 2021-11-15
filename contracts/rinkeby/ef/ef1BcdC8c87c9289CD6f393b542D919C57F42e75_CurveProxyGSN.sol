//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "./interface/IERC20.sol";


interface StableSwapPool {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(uint256[5] memory amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(uint256[6] memory amounts, uint256 min_mint_amount)
        external;

    function remove_liquidity(uint256 amounts, uint256[2] memory min_amounts)
        external;

    function remove_liquidity(uint256 amounts, uint256[3] memory min_amounts)
        external;

    function remove_liquidity(uint256 amounts, uint256[4] memory min_amounts)
        external;

    function remove_liquidity(uint256 amounts, uint256[5] memory min_amounts)
        external;

    function remove_liquidity(uint256 amounts, uint256[6] memory min_amounts)
        external;

    function remove_liquidity_imbalance(
        uint256[2] memory amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity_imbalance(
        uint256[3] memory amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity_imbalance(
        uint256[4] memory amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity_imbalance(
        uint256[5] memory amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity_imbalance(
        uint256[6] memory amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;
}

contract CurveProxyGSN is BaseRelayRecipient {
    using EnumerableSet for EnumerableSet.AddressSet;

    address owner;

    //pool_address => enumerable_token_set
    mapping(address => EnumerableSet.AddressSet) private pool;
    //pool_address => lp_token_address
    mapping(address => address) private lp_token;

    constructor(address _forwarder) {
        trustedForwarder = _forwarder;
    }

    function setPool(
        address _swap,
        address _lp_token,
        address[] memory _coins
    ) public {
        for (uint256 i = 0; i < _coins.length; i++) {
            pool[_swap].add(_coins[i]);
        }
        lp_token[_swap] = _lp_token;
    }

    function add_liquidity_2pool(
        address _swap,
        uint256[2] memory _amounts,
        uint256 _min_mint_amount
    ) external {
        for (uint256 i = 0; i < _amounts.length; i++) {
            IERC20(pool[_swap].at(i)).transferFrom(
                _msgSender(),
                address(this),
                _amounts[i]
            );
            IERC20(pool[_swap].at(i)).approve(address(_swap), _amounts[i]);
        }
        StableSwapPool(_swap).add_liquidity(_amounts, _min_mint_amount);
        IERC20(lp_token[_swap]).transfer(
            _msgSender(),
            IERC20(lp_token[_swap]).balanceOf(address(this))
        );
    }

    function add_liquidity_3pool(
        address _swap,
        uint256[3] memory _amounts,  // List of amounts of coins to deposit
        uint256 _min_mint_amount     // Minimum amount of LP tokens to mint from the deposit
    ) external {
        for (uint256 i = 0; i < _amounts.length; i++) {
            IERC20(pool[_swap].at(i)).transferFrom(
                _msgSender(),
                address(this),
                _amounts[i]
            );
            IERC20(pool[_swap].at(i)).approve(address(_swap), _amounts[i]);
        }
        StableSwapPool(_swap).add_liquidity(_amounts, _min_mint_amount);
        IERC20(lp_token[_swap]).transfer(
            _msgSender(),
            IERC20(lp_token[_swap]).balanceOf(address(this))
        );
    }

    function add_liquidity_4pool(
        address _swap,
        uint256[4] memory _amounts,  // List of amounts of coins to deposit
        uint256 _min_mint_amount     // Minimum amount of LP tokens to mint from the deposit
    ) external {
        for (uint256 i = 0; i < _amounts.length; i++) {
            IERC20(pool[_swap].at(i)).transferFrom(
                _msgSender(),
                address(this),
                _amounts[i]
            );
            IERC20(pool[_swap].at(i)).approve(address(_swap), _amounts[i]);
        }
        StableSwapPool(_swap).add_liquidity(_amounts, _min_mint_amount);
        IERC20(lp_token[_swap]).transfer(
            _msgSender(),
            IERC20(lp_token[_swap]).balanceOf(address(this))
        );
    }

    function add_liquidity_5pool(
        address _swap,
        uint256[5] memory _amounts,  // List of amounts of coins to deposit
        uint256 _min_mint_amount     // Minimum amount of LP tokens to mint from the deposit
    ) external {
        for (uint256 i = 0; i < _amounts.length; i++) {
            IERC20(pool[_swap].at(i)).transferFrom(
                _msgSender(),
                address(this),
                _amounts[i]
            );
            IERC20(pool[_swap].at(i)).approve(address(_swap), _amounts[i]);
        }
        StableSwapPool(_swap).add_liquidity(_amounts, _min_mint_amount);
        IERC20(lp_token[_swap]).transfer(
            _msgSender(),
            IERC20(lp_token[_swap]).balanceOf(address(this))
        );
    }

    function add_liquidity_6pool(
        address _swap,
        uint256[6] memory _amounts,  // List of amounts of coins to deposit
        uint256 _min_mint_amount     // Minimum amount of LP tokens to mint from the deposit
    ) external {
        for (uint256 i = 0; i < _amounts.length; i++) {
            IERC20(pool[_swap].at(i)).transferFrom(
                _msgSender(),
                address(this),
                _amounts[i]
            );
            IERC20(pool[_swap].at(i)).approve(address(_swap), _amounts[i]);
        }
        StableSwapPool(_swap).add_liquidity(_amounts, _min_mint_amount);
        IERC20(lp_token[_swap]).transfer(
            _msgSender(),
            IERC20(lp_token[_swap]).balanceOf(address(this))
        );
    }

    function exchange(
        address _swap,
        int128 _i,      //Index value for the coin to send
        int128 _j,      //Index value of the coin to receive
        uint256 _dx,    //Amount of i being exchanged
        uint256 _min_dy //Minimum amount of j to receive
    ) external {
        IERC20(pool[_swap].at(uint256(_i))).transferFrom(
            _msgSender(),
            address(this),
            _dx
        );
        IERC20(pool[_swap].at(uint256(_i))).approve(address(_swap), _dx);
        StableSwapPool(_swap).exchange(_i, _j, _dx, _min_dy);
        IERC20(pool[_swap].at(uint256(_j))).transfer(
            _msgSender(),
            IERC20(pool[_swap].at(uint256(_j))).balanceOf(address(this))
        );
    }

    function remove_liquidity_2pool(
        address _swap,
        uint256 _amounts,               //Quantity of LP tokens to burn in the withdrawal
        uint256[2] memory _min_amounts  //Minimum amounts of underlying coins to receive
    ) external {
        IERC20(lp_token[_swap]).transferFrom(
            _msgSender(),
            address(this),
            _amounts
        );
        IERC20(lp_token[_swap]).approve(address(_swap), _amounts);
        StableSwapPool(_swap).remove_liquidity(_amounts, _min_amounts);

        for (uint256 i = 0; i < _min_amounts.length; i++) {
            if (_min_amounts[i] != 0)
                IERC20(pool[_swap].at(i)).transfer(
                    _msgSender(),
                    IERC20(pool[_swap].at(i)).balanceOf(address(this))
                );
        }
    }

    function remove_liquidity_3pool(
        address _swap,
        uint256 _amounts,               //Quantity of LP tokens to burn in the withdrawal
        uint256[3] memory _min_amounts  //Minimum amounts of underlying coins to receive
    ) external {
        IERC20(lp_token[_swap]).transferFrom(
            _msgSender(),
            address(this),
            _amounts
        );
        IERC20(lp_token[_swap]).approve(address(_swap), _amounts);
        StableSwapPool(_swap).remove_liquidity(_amounts, _min_amounts);

        for (uint256 i = 0; i < _min_amounts.length; i++) {
            if (_min_amounts[i] != 0)
                IERC20(pool[_swap].at(i)).transfer(
                    _msgSender(),
                    IERC20(pool[_swap].at(i)).balanceOf(address(this))
                );
        }
    }

    function remove_liquidity_4pool(
        address _swap,
        uint256 _amounts,               //Quantity of LP tokens to burn in the withdrawal
        uint256[4] memory _min_amounts  //Minimum amounts of underlying coins to receive
    ) external {
        IERC20(lp_token[_swap]).transferFrom(
            _msgSender(),
            address(this),
            _amounts
        );
        IERC20(lp_token[_swap]).approve(address(_swap), _amounts);
        StableSwapPool(_swap).remove_liquidity(_amounts, _min_amounts);

        for (uint256 i = 0; i < _min_amounts.length; i++) {
            if (_min_amounts[i] != 0)
                IERC20(pool[_swap].at(i)).transfer(
                    _msgSender(),
                    IERC20(pool[_swap].at(i)).balanceOf(address(this))
                );
        }
    }

    function remove_liquidity_5pool(
        address _swap,
        uint256 _amounts,               //Quantity of LP tokens to burn in the withdrawal
        uint256[5] memory _min_amounts  //Minimum amounts of underlying coins to receive
    ) external {
        IERC20(lp_token[_swap]).transferFrom(
            _msgSender(),
            address(this),
            _amounts
        );
        IERC20(lp_token[_swap]).approve(address(_swap), _amounts);
        StableSwapPool(_swap).remove_liquidity(_amounts, _min_amounts);

        for (uint256 i = 0; i < _min_amounts.length; i++) {
            if (_min_amounts[i] != 0)
                IERC20(pool[_swap].at(i)).transfer(
                    _msgSender(),
                    IERC20(pool[_swap].at(i)).balanceOf(address(this))
                );
        }
    }

    function remove_liquidity_6pool(
        address _swap,
        uint256 _amounts,               //Quantity of LP tokens to burn in the withdrawal
        uint256[6] memory _min_amounts  //Minimum amounts of underlying coins to receive
    ) external {
        IERC20(lp_token[_swap]).transferFrom(
            _msgSender(),
            address(this),
            _amounts
        );
        IERC20(lp_token[_swap]).approve(address(_swap), _amounts);
        StableSwapPool(_swap).remove_liquidity(_amounts, _min_amounts);

        for (uint256 i = 0; i < _min_amounts.length; i++) {
            if (_min_amounts[i] != 0)
                IERC20(pool[_swap].at(i)).transfer(
                    _msgSender(),
                    IERC20(pool[_swap].at(i)).balanceOf(address(this))
                );
        }
    }

    function remove_liquidity_imbalance_2pool(
        address _swap,
        uint256[2] memory _amounts, //List of amounts of underlying coins to withdraw
        uint256 _max_burn_amount    //Maximum amount of LP token to burn in the withdrawal
    ) external {
        IERC20(lp_token[_swap]).transferFrom(
            _msgSender(),
            address(this),
            _max_burn_amount
        );
        IERC20(lp_token[_swap]).approve(address(_swap), 0);
        IERC20(lp_token[_swap]).approve(address(_swap), _max_burn_amount);
        StableSwapPool(_swap).remove_liquidity_imbalance(
            _amounts,
            _max_burn_amount
        );

        for (uint256 i = 0; i < _amounts.length; i++) {
            if (_amounts[i] != 0)
                IERC20(pool[_swap].at(i)).transfer(_msgSender(), _amounts[i]);
        }

        IERC20(lp_token[_swap]).transfer(
            _msgSender(),
            IERC20(lp_token[_swap]).balanceOf(address(this))
        );
    }

    function remove_liquidity_imbalance_3pool(
        address _swap,
        uint256[3] memory _amounts, //List of amounts of underlying coins to withdraw
        uint256 _max_burn_amount    //Maximum amount of LP token to burn in the withdrawal
    ) external {
        IERC20(lp_token[_swap]).transferFrom(
            _msgSender(),
            address(this),
            _max_burn_amount
        );
        IERC20(lp_token[_swap]).approve(address(_swap), 0);
        IERC20(lp_token[_swap]).approve(address(_swap), _max_burn_amount);
        StableSwapPool(_swap).remove_liquidity_imbalance(
            _amounts,
            _max_burn_amount
        );

        for (uint256 i = 0; i < _amounts.length; i++) {
            if (_amounts[i] != 0)
                IERC20(pool[_swap].at(i)).transfer(_msgSender(), _amounts[i]);
        }

        IERC20(lp_token[_swap]).transfer(
            _msgSender(),
            IERC20(lp_token[_swap]).balanceOf(address(this))
        );
    }

    function remove_liquidity_imbalance_4pool(
        address _swap,
        uint256[4] memory _amounts, //List of amounts of underlying coins to withdraw
        uint256 _max_burn_amount    //Maximum amount of LP token to burn in the withdrawal
    ) external {
        IERC20(lp_token[_swap]).transferFrom(
            _msgSender(),
            address(this),
            _max_burn_amount
        );
        IERC20(lp_token[_swap]).approve(address(_swap), 0);
        IERC20(lp_token[_swap]).approve(address(_swap), _max_burn_amount);
        StableSwapPool(_swap).remove_liquidity_imbalance(
            _amounts,
            _max_burn_amount
        );

        for (uint256 i = 0; i < _amounts.length; i++) {
            if (_amounts[i] != 0)
                IERC20(pool[_swap].at(i)).transfer(_msgSender(), _amounts[i]);
        }

        IERC20(lp_token[_swap]).transfer(
            _msgSender(),
            IERC20(lp_token[_swap]).balanceOf(address(this))
        );
    }

    function remove_liquidity_imbalance_5pool(
        address _swap,
        uint256[5] memory _amounts, //List of amounts of underlying coins to withdraw
        uint256 _max_burn_amount    //Maximum amount of LP token to burn in the withdrawal
    ) external {
        IERC20(lp_token[_swap]).transferFrom(
            _msgSender(),
            address(this),
            _max_burn_amount
        );
        IERC20(lp_token[_swap]).approve(address(_swap), 0);
        IERC20(lp_token[_swap]).approve(address(_swap), _max_burn_amount);
        StableSwapPool(_swap).remove_liquidity_imbalance(
            _amounts,
            _max_burn_amount
        );

        for (uint256 i = 0; i < _amounts.length; i++) {
            if (_amounts[i] != 0)
                IERC20(pool[_swap].at(i)).transfer(_msgSender(), _amounts[i]);
        }

        IERC20(lp_token[_swap]).transfer(
            _msgSender(),
            IERC20(lp_token[_swap]).balanceOf(address(this))
        );
    }

    function remove_liquidity_imbalance_6pool(
        address _swap,
        uint256[6] memory _amounts, //List of amounts of underlying coins to withdraw
        uint256 _max_burn_amount    //Maximum amount of LP token to burn in the withdrawal
    ) external {
        IERC20(lp_token[_swap]).transferFrom(
            _msgSender(),
            address(this),
            _max_burn_amount
        );
        IERC20(lp_token[_swap]).approve(address(_swap), 0);
        IERC20(lp_token[_swap]).approve(address(_swap), _max_burn_amount);
        StableSwapPool(_swap).remove_liquidity_imbalance(
            _amounts,
            _max_burn_amount
        );

        for (uint256 i = 0; i < _amounts.length; i++) {
            if (_amounts[i] != 0)
                IERC20(pool[_swap].at(i)).transfer(_msgSender(), _amounts[i]);
        }

        IERC20(lp_token[_swap]).transfer(
            _msgSender(),
            IERC20(lp_token[_swap]).balanceOf(address(this))
        );
    }

    function remove_liquidity_one_coin(
        address _swap,
        uint256 _token_amount, //Amount of LP tokens to burn in the withdrawal
        int128 _i,             //Index value of the coin to withdraw
        uint256 _min_amount    //Minimum amount of coin to receive
    ) external {
        IERC20(lp_token[_swap]).transferFrom(
            _msgSender(),
            address(this),
            _token_amount
        );
        IERC20(lp_token[_swap]).approve(address(_swap), 0);
        IERC20(lp_token[_swap]).approve(address(_swap), _token_amount);
        StableSwapPool(_swap).remove_liquidity_one_coin(
            _token_amount,
            _i,
            _min_amount
        );
        IERC20(pool[_swap].at(uint256(_i))).transfer(
            _msgSender(),
            IERC20(pool[_swap].at(uint256(_i))).balanceOf(address(this))
        );
    }

    string public override versionRecipient = "2.2.0";
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable no-inline-assembly
pragma solidity >=0.7.6;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return payable(msg.sender);
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal override virtual view returns (bytes memory ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes memory);

    function versionRecipient() external virtual view returns (string memory);
}

