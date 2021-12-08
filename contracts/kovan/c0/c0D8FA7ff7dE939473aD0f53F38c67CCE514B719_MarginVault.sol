/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity =0.6.10;

pragma experimental ABIEncoderV2;

import {SafeMath} from "../packages/oz/SafeMath.sol";

/**
 * MarginVault Error Codes
 * V1: invalid short otoken amount
 * V2: invalid short otoken index
 * V3: short otoken address mismatch
 * V4: invalid long otoken amount
 * V5: invalid long otoken index
 * V6: long otoken address mismatch
 * V7: invalid collateral amount
 * V8: invalid collateral token index
 * V9: collateral token address mismatch
 */

/**
 * @title MarginVault
 * @author Opyn Team
 * @notice A library that provides the Controller with a Vault struct and the functions that manipulate vaults.
 * Vaults describe discrete position combinations of long options, short options, and collateral assets that a user can have.
 */
library MarginVault {
    using SafeMath for uint256;

    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens a user has shorted (i.e. written) against this vault
        address[] shortOtokens;
        // addresses of oTokens a user has bought and deposited in this vault
        // user can be long oTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long oTokens will be 'deposited' in vaults to act as collateral in order to write oTokens against (i.e. in spreads)
        address[] longOtokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address in shortOtokens
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address in longOtokens
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
    }

    /**
     * @dev increase the short oToken balance in a vault when a new oToken is minted
     * @param _vault vault to add or increase the short position in
     * @param _shortOtoken address of the _shortOtoken being minted from the user's vault
     * @param _amount number of _shortOtoken being minted from the user's vault
     * @param _index index of _shortOtoken in the user's vault.shortOtokens array
     */
    function addShort(
        Vault storage _vault,
        address _shortOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "V1");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.shortOtokens.length) && (_index == _vault.shortAmounts.length)) {
            _vault.shortOtokens.push(_shortOtoken);
            _vault.shortAmounts.push(_amount);
        } else {
            require((_index < _vault.shortOtokens.length) && (_index < _vault.shortAmounts.length), "V2");
            address existingShort = _vault.shortOtokens[_index];
            require((existingShort == _shortOtoken) || (existingShort == address(0)), "V3");

            _vault.shortAmounts[_index] = _vault.shortAmounts[_index].add(_amount);
            _vault.shortOtokens[_index] = _shortOtoken;
        }
    }

    /**
     * @dev decrease the short oToken balance in a vault when an oToken is burned
     * @param _vault vault to decrease short position in
     * @param _shortOtoken address of the _shortOtoken being reduced in the user's vault
     * @param _amount number of _shortOtoken being reduced in the user's vault
     * @param _index index of _shortOtoken in the user's vault.shortOtokens array
     */
    function removeShort(
        Vault storage _vault,
        address _shortOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed short oToken exists in the vault at the specified index
        require(_index < _vault.shortOtokens.length, "V2");
        require(_vault.shortOtokens[_index] == _shortOtoken, "V3");

        uint256 newShortAmount = _vault.shortAmounts[_index].sub(_amount);

        if (newShortAmount == 0) {
            delete _vault.shortOtokens[_index];
        }
        _vault.shortAmounts[_index] = newShortAmount;
    }

    /**
     * @dev increase the long oToken balance in a vault when an oToken is deposited
     * @param _vault vault to add a long position to
     * @param _longOtoken address of the _longOtoken being added to the user's vault
     * @param _amount number of _longOtoken the protocol is adding to the user's vault
     * @param _index index of _longOtoken in the user's vault.longOtokens array
     */
    function addLong(
        Vault storage _vault,
        address _longOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "V4");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.longOtokens.length) && (_index == _vault.longAmounts.length)) {
            _vault.longOtokens.push(_longOtoken);
            _vault.longAmounts.push(_amount);
        } else {
            require((_index < _vault.longOtokens.length) && (_index < _vault.longAmounts.length), "V5");
            address existingLong = _vault.longOtokens[_index];
            require((existingLong == _longOtoken) || (existingLong == address(0)), "V6");

            _vault.longAmounts[_index] = _vault.longAmounts[_index].add(_amount);
            _vault.longOtokens[_index] = _longOtoken;
        }
    }

    /**
     * @dev decrease the long oToken balance in a vault when an oToken is withdrawn
     * @param _vault vault to remove a long position from
     * @param _longOtoken address of the _longOtoken being removed from the user's vault
     * @param _amount number of _longOtoken the protocol is removing from the user's vault
     * @param _index index of _longOtoken in the user's vault.longOtokens array
     */
    function removeLong(
        Vault storage _vault,
        address _longOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed long oToken exists in the vault at the specified index
        require(_index < _vault.longOtokens.length, "V5");
        require(_vault.longOtokens[_index] == _longOtoken, "V6");

        uint256 newLongAmount = _vault.longAmounts[_index].sub(_amount);

        if (newLongAmount == 0) {
            delete _vault.longOtokens[_index];
        }
        _vault.longAmounts[_index] = newLongAmount;
    }

    /**
     * @dev increase the collateral balance in a vault
     * @param _vault vault to add collateral to
     * @param _collateralAsset address of the _collateralAsset being added to the user's vault
     * @param _amount number of _collateralAsset being added to the user's vault
     * @param _index index of _collateralAsset in the user's vault.collateralAssets array
     */
    function addCollateral(
        Vault storage _vault,
        address _collateralAsset,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "V7");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.collateralAssets.length) && (_index == _vault.collateralAmounts.length)) {
            _vault.collateralAssets.push(_collateralAsset);
            _vault.collateralAmounts.push(_amount);
        } else {
            require((_index < _vault.collateralAssets.length) && (_index < _vault.collateralAmounts.length), "V8");
            address existingCollateral = _vault.collateralAssets[_index];
            require((existingCollateral == _collateralAsset) || (existingCollateral == address(0)), "V9");

            _vault.collateralAmounts[_index] = _vault.collateralAmounts[_index].add(_amount);
            _vault.collateralAssets[_index] = _collateralAsset;
        }
    }

    /**
     * @dev decrease the collateral balance in a vault
     * @param _vault vault to remove collateral from
     * @param _collateralAsset address of the _collateralAsset being removed from the user's vault
     * @param _amount number of _collateralAsset being removed from the user's vault
     * @param _index index of _collateralAsset in the user's vault.collateralAssets array
     */
    function removeCollateral(
        Vault storage _vault,
        address _collateralAsset,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed collateral exists in the vault at the specified index
        require(_index < _vault.collateralAssets.length, "V8");
        require(_vault.collateralAssets[_index] == _collateralAsset, "V9");

        uint256 newCollateralAmount = _vault.collateralAmounts[_index].sub(_amount);

        if (newCollateralAmount == 0) {
            delete _vault.collateralAssets[_index];
        }
        _vault.collateralAmounts[_index] = newCollateralAmount;
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

/* solhint-disable */
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}