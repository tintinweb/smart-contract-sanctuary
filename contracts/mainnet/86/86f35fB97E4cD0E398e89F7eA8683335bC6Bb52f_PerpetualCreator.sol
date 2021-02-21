// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Lockable.sol";

/**
 * @title A contract to track a whitelist of addresses.
 */
contract AddressWhitelist is Ownable, Lockable {
    enum Status { None, In, Out }
    mapping(address => Status) public whitelist;

    address[] public whitelistIndices;

    event AddedToWhitelist(address indexed addedAddress);
    event RemovedFromWhitelist(address indexed removedAddress);

    /**
     * @notice Adds an address to the whitelist.
     * @param newElement the new address to add.
     */
    function addToWhitelist(address newElement) external nonReentrant() onlyOwner {
        // Ignore if address is already included
        if (whitelist[newElement] == Status.In) {
            return;
        }

        // Only append new addresses to the array, never a duplicate
        if (whitelist[newElement] == Status.None) {
            whitelistIndices.push(newElement);
        }

        whitelist[newElement] = Status.In;

        emit AddedToWhitelist(newElement);
    }

    /**
     * @notice Removes an address from the whitelist.
     * @param elementToRemove the existing address to remove.
     */
    function removeFromWhitelist(address elementToRemove) external nonReentrant() onlyOwner {
        if (whitelist[elementToRemove] != Status.Out) {
            whitelist[elementToRemove] = Status.Out;
            emit RemovedFromWhitelist(elementToRemove);
        }
    }

    /**
     * @notice Checks whether an address is on the whitelist.
     * @param elementToCheck the address to check.
     * @return True if `elementToCheck` is on the whitelist, or False.
     */
    function isOnWhitelist(address elementToCheck) external view nonReentrantView() returns (bool) {
        return whitelist[elementToCheck] == Status.In;
    }

    /**
     * @notice Gets all addresses that are currently included in the whitelist.
     * @dev Note: This method skips over, but still iterates through addresses. It is possible for this call to run out
     * of gas if a large number of addresses have been removed. To reduce the likelihood of this unlikely scenario, we
     * can modify the implementation so that when addresses are removed, the last addresses in the array is moved to
     * the empty index.
     * @return activeWhitelist the list of addresses on the whitelist.
     */
    function getWhitelist() external view nonReentrantView() returns (address[] memory activeWhitelist) {
        // Determine size of whitelist first
        uint256 activeCount = 0;
        for (uint256 i = 0; i < whitelistIndices.length; i++) {
            if (whitelist[whitelistIndices[i]] == Status.In) {
                activeCount++;
            }
        }

        // Populate whitelist
        activeWhitelist = new address[](activeCount);
        activeCount = 0;
        for (uint256 i = 0; i < whitelistIndices.length; i++) {
            address addr = whitelistIndices[i];
            if (whitelist[addr] == Status.In) {
                activeWhitelist[activeCount] = addr;
                activeCount++;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MultiRole.sol";
import "../interfaces/ExpandedIERC20.sol";

/**
 * @title An ERC20 with permissioned burning and minting. The contract deployer will initially
 * be the owner who is capable of adding new roles.
 */
contract ExpandedERC20 is ExpandedIERC20, ERC20, MultiRole {
    enum Roles {
        // Can set the minter and burner.
        Owner,
        // Addresses that can mint new tokens.
        Minter,
        // Addresses that can burn tokens that address owns.
        Burner
    }

    /**
     * @notice Constructs the ExpandedERC20.
     * @param _tokenName The name which describes the new token.
     * @param _tokenSymbol The ticker abbreviation of the name. Ideally < 5 chars.
     * @param _tokenDecimals The number of decimals to define token precision.
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) public ERC20(_tokenName, _tokenSymbol) {
        _setupDecimals(_tokenDecimals);
        _createExclusiveRole(uint256(Roles.Owner), uint256(Roles.Owner), msg.sender);
        _createSharedRole(uint256(Roles.Minter), uint256(Roles.Owner), new address[](0));
        _createSharedRole(uint256(Roles.Burner), uint256(Roles.Owner), new address[](0));
    }

    /**
     * @dev Mints `value` tokens to `recipient`, returning true on success.
     * @param recipient address to mint to.
     * @param value amount of tokens to mint.
     * @return True if the mint succeeded, or False.
     */
    function mint(address recipient, uint256 value)
        external
        override
        onlyRoleHolder(uint256(Roles.Minter))
        returns (bool)
    {
        _mint(recipient, value);
        return true;
    }

    /**
     * @dev Burns `value` tokens owned by `msg.sender`.
     * @param value amount of tokens to burn.
     */
    function burn(uint256 value) external override onlyRoleHolder(uint256(Roles.Burner)) {
        _burn(msg.sender, value);
    }

    /**
     * @notice Add Minter role to account.
     * @dev The caller must have the Owner role.
     * @param account The address to which the Minter role is added.
     */
    function addMinter(address account) external virtual override {
        addMember(uint256(Roles.Minter), account);
    }

    /**
     * @notice Add Burner role to account.
     * @dev The caller must have the Owner role.
     * @param account The address to which the Burner role is added.
     */
    function addBurner(address account) external virtual override {
        addMember(uint256(Roles.Burner), account);
    }

    /**
     * @notice Reset Owner role to account.
     * @dev The caller must have the Owner role.
     * @param account The new holder of the Owner role.
     */
    function resetOwner(address account) external virtual override {
        resetMember(uint256(Roles.Owner), account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title Library for fixed point arithmetic on uints
 */
library FixedPoint {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_SCALING_FACTOR = 10**18;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    struct Unsigned {
        uint256 rawValue;
    }

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
        return Unsigned(a.mul(FP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 mulRaw = a.rawValue.mul(b.rawValue);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
        if (mod != 0) {
            return Unsigned(mulFloor.add(1));
        } else {
            return Unsigned(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
        uint256 divFloor = aScaled.div(b.rawValue);
        uint256 mod = aScaled.mod(b.rawValue);
        if (mod != 0) {
            return Unsigned(divFloor.add(1));
        } else {
            return Unsigned(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(a.rawValue.div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    struct Signed {
        int256 rawValue;
    }

    function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
        require(a.rawValue >= 0, "Negative value provided");
        return Unsigned(uint256(a.rawValue));
    }

    function fromUnsigned(Unsigned memory a) internal pure returns (Signed memory) {
        require(a.rawValue <= uint256(type(int256).max), "Unsigned too large");
        return Signed(int256(a.rawValue));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
        return Signed(a.mul(SFP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled int256 from an `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 mulRaw = a.rawValue.mul(b.rawValue);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(mulTowardsZero.add(valueToAdd));
        } else {
            return Signed(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Signed` by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled int256 by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by an `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
        int256 divTowardsZero = aScaled.div(b.rawValue);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % b.rawValue;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(divTowardsZero.add(valueToAdd));
        } else {
            return Signed(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(a.rawValue.div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises an `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed memory a, uint256 b) internal pure returns (Signed memory output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
contract Lockable {
    bool private _notEntered;

    constructor() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    /**
     * @dev Designed to prevent a view-only method from being re-entered during a call to a `nonReentrant()` state-changing method.
     */
    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    // Internal methods are used to avoid copying the require statement's bytecode to every `nonReentrant()` method.
    // On entry into a function, `_preEntranceCheck()` should always be called to check if the function is being re-entered.
    // Then, if the function modifies state, it should call `_postEntranceSet()`, perform its logic, and then call `_postEntranceReset()`.
    // View-only methods can simply call `_preEntranceCheck()` to make sure that it is not being re-entered.
    function _preEntranceCheck() internal view {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

library Exclusive {
    struct RoleMembership {
        address member;
    }

    function isMember(RoleMembership storage roleMembership, address memberToCheck) internal view returns (bool) {
        return roleMembership.member == memberToCheck;
    }

    function resetMember(RoleMembership storage roleMembership, address newMember) internal {
        require(newMember != address(0x0), "Cannot set an exclusive role to 0x0");
        roleMembership.member = newMember;
    }

    function getMember(RoleMembership storage roleMembership) internal view returns (address) {
        return roleMembership.member;
    }

    function init(RoleMembership storage roleMembership, address initialMember) internal {
        resetMember(roleMembership, initialMember);
    }
}

library Shared {
    struct RoleMembership {
        mapping(address => bool) members;
    }

    function isMember(RoleMembership storage roleMembership, address memberToCheck) internal view returns (bool) {
        return roleMembership.members[memberToCheck];
    }

    function addMember(RoleMembership storage roleMembership, address memberToAdd) internal {
        require(memberToAdd != address(0x0), "Cannot add 0x0 to a shared role");
        roleMembership.members[memberToAdd] = true;
    }

    function removeMember(RoleMembership storage roleMembership, address memberToRemove) internal {
        roleMembership.members[memberToRemove] = false;
    }

    function init(RoleMembership storage roleMembership, address[] memory initialMembers) internal {
        for (uint256 i = 0; i < initialMembers.length; i++) {
            addMember(roleMembership, initialMembers[i]);
        }
    }
}

/**
 * @title Base class to manage permissions for the derived class.
 */
abstract contract MultiRole {
    using Exclusive for Exclusive.RoleMembership;
    using Shared for Shared.RoleMembership;

    enum RoleType { Invalid, Exclusive, Shared }

    struct Role {
        uint256 managingRole;
        RoleType roleType;
        Exclusive.RoleMembership exclusiveRoleMembership;
        Shared.RoleMembership sharedRoleMembership;
    }

    mapping(uint256 => Role) private roles;

    event ResetExclusiveMember(uint256 indexed roleId, address indexed newMember, address indexed manager);
    event AddedSharedMember(uint256 indexed roleId, address indexed newMember, address indexed manager);
    event RemovedSharedMember(uint256 indexed roleId, address indexed oldMember, address indexed manager);

    /**
     * @notice Reverts unless the caller is a member of the specified roleId.
     */
    modifier onlyRoleHolder(uint256 roleId) {
        require(holdsRole(roleId, msg.sender), "Sender does not hold required role");
        _;
    }

    /**
     * @notice Reverts unless the caller is a member of the manager role for the specified roleId.
     */
    modifier onlyRoleManager(uint256 roleId) {
        require(holdsRole(roles[roleId].managingRole, msg.sender), "Can only be called by a role manager");
        _;
    }

    /**
     * @notice Reverts unless the roleId represents an initialized, exclusive roleId.
     */
    modifier onlyExclusive(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Exclusive, "Must be called on an initialized Exclusive role");
        _;
    }

    /**
     * @notice Reverts unless the roleId represents an initialized, shared roleId.
     */
    modifier onlyShared(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Shared, "Must be called on an initialized Shared role");
        _;
    }

    /**
     * @notice Whether `memberToCheck` is a member of roleId.
     * @dev Reverts if roleId does not correspond to an initialized role.
     * @param roleId the Role to check.
     * @param memberToCheck the address to check.
     * @return True if `memberToCheck` is a member of `roleId`.
     */
    function holdsRole(uint256 roleId, address memberToCheck) public view returns (bool) {
        Role storage role = roles[roleId];
        if (role.roleType == RoleType.Exclusive) {
            return role.exclusiveRoleMembership.isMember(memberToCheck);
        } else if (role.roleType == RoleType.Shared) {
            return role.sharedRoleMembership.isMember(memberToCheck);
        }
        revert("Invalid roleId");
    }

    /**
     * @notice Changes the exclusive role holder of `roleId` to `newMember`.
     * @dev Reverts if the caller is not a member of the managing role for `roleId` or if `roleId` is not an
     * initialized, ExclusiveRole.
     * @param roleId the ExclusiveRole membership to modify.
     * @param newMember the new ExclusiveRole member.
     */
    function resetMember(uint256 roleId, address newMember) public onlyExclusive(roleId) onlyRoleManager(roleId) {
        roles[roleId].exclusiveRoleMembership.resetMember(newMember);
        emit ResetExclusiveMember(roleId, newMember, msg.sender);
    }

    /**
     * @notice Gets the current holder of the exclusive role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, exclusive role.
     * @param roleId the ExclusiveRole membership to check.
     * @return the address of the current ExclusiveRole member.
     */
    function getMember(uint256 roleId) public view onlyExclusive(roleId) returns (address) {
        return roles[roleId].exclusiveRoleMembership.getMember();
    }

    /**
     * @notice Adds `newMember` to the shared role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, SharedRole or if the caller is not a member of the
     * managing role for `roleId`.
     * @param roleId the SharedRole membership to modify.
     * @param newMember the new SharedRole member.
     */
    function addMember(uint256 roleId, address newMember) public onlyShared(roleId) onlyRoleManager(roleId) {
        roles[roleId].sharedRoleMembership.addMember(newMember);
        emit AddedSharedMember(roleId, newMember, msg.sender);
    }

    /**
     * @notice Removes `memberToRemove` from the shared role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, SharedRole or if the caller is not a member of the
     * managing role for `roleId`.
     * @param roleId the SharedRole membership to modify.
     * @param memberToRemove the current SharedRole member to remove.
     */
    function removeMember(uint256 roleId, address memberToRemove) public onlyShared(roleId) onlyRoleManager(roleId) {
        roles[roleId].sharedRoleMembership.removeMember(memberToRemove);
        emit RemovedSharedMember(roleId, memberToRemove, msg.sender);
    }

    /**
     * @notice Removes caller from the role, `roleId`.
     * @dev Reverts if the caller is not a member of the role for `roleId` or if `roleId` is not an
     * initialized, SharedRole.
     * @param roleId the SharedRole membership to modify.
     */
    function renounceMembership(uint256 roleId) public onlyShared(roleId) onlyRoleHolder(roleId) {
        roles[roleId].sharedRoleMembership.removeMember(msg.sender);
        emit RemovedSharedMember(roleId, msg.sender, msg.sender);
    }

    /**
     * @notice Reverts if `roleId` is not initialized.
     */
    modifier onlyValidRole(uint256 roleId) {
        require(roles[roleId].roleType != RoleType.Invalid, "Attempted to use an invalid roleId");
        _;
    }

    /**
     * @notice Reverts if `roleId` is initialized.
     */
    modifier onlyInvalidRole(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Invalid, "Cannot use a pre-existing role");
        _;
    }

    /**
     * @notice Internal method to initialize a shared role, `roleId`, which will be managed by `managingRoleId`.
     * `initialMembers` will be immediately added to the role.
     * @dev Should be called by derived contracts, usually at construction time. Will revert if the role is already
     * initialized.
     */
    function _createSharedRole(
        uint256 roleId,
        uint256 managingRoleId,
        address[] memory initialMembers
    ) internal onlyInvalidRole(roleId) {
        Role storage role = roles[roleId];
        role.roleType = RoleType.Shared;
        role.managingRole = managingRoleId;
        role.sharedRoleMembership.init(initialMembers);
        require(
            roles[managingRoleId].roleType != RoleType.Invalid,
            "Attempted to use an invalid role to manage a shared role"
        );
    }

    /**
     * @notice Internal method to initialize an exclusive role, `roleId`, which will be managed by `managingRoleId`.
     * `initialMember` will be immediately added to the role.
     * @dev Should be called by derived contracts, usually at construction time. Will revert if the role is already
     * initialized.
     */
    function _createExclusiveRole(
        uint256 roleId,
        uint256 managingRoleId,
        address initialMember
    ) internal onlyInvalidRole(roleId) {
        Role storage role = roles[roleId];
        role.roleType = RoleType.Exclusive;
        role.managingRole = managingRoleId;
        role.exclusiveRoleMembership.init(initialMember);
        require(
            roles[managingRoleId].roleType != RoleType.Invalid,
            "Attempted to use an invalid role to manage an exclusive role"
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./Timer.sol";

/**
 * @title Base class that provides time overrides, but only if being run in test mode.
 */
abstract contract Testable {
    // If the contract is being run on the test network, then `timerAddress` will be the 0x0 address.
    // Note: this variable should be set on construction and never modified.
    address public timerAddress;

    /**
     * @notice Constructs the Testable contract. Called by child contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(address _timerAddress) internal {
        timerAddress = _timerAddress;
    }

    /**
     * @notice Reverts if not running in test mode.
     */
    modifier onlyIfTest {
        require(timerAddress != address(0x0));
        _;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set current Testable time to.
     */
    function setCurrentTime(uint256 time) external onlyIfTest {
        Timer(timerAddress).setCurrentTime(time);
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        if (timerAddress != address(0x0)) {
            return Timer(timerAddress).getCurrentTime();
        } else {
            return now; // solhint-disable-line not-rely-on-time
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer {
    uint256 private currentTime;

    constructor() public {
        currentTime = now; // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint256 time) external {
        currentTime = time;
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint256 for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ERC20 interface that includes burn and mint methods.
 */
abstract contract ExpandedIERC20 is IERC20 {
    /**
     * @notice Burns a specific amount of the caller's tokens.
     * @dev Only burns the caller's tokens, so it is safe to leave this method permissionless.
     */
    function burn(uint256 value) external virtual;

    /**
     * @notice Mints tokens and adds them to the balance of the `to` address.
     * @dev This method should be permissioned to only allow designated parties to mint tokens.
     */
    function mint(address to, uint256 value) external virtual returns (bool);

    function addMinter(address account) external virtual;

    function addBurner(address account) external virtual;

    function resetOwner(address account) external virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ERC20 interface that includes the decimals read only method.
 */
interface IERC20Standard is IERC20 {
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should be displayed to a user as `5,05`
     * (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei. This is the value
     * {ERC20} uses, unless {_setupDecimals} is called.
     *
     * NOTE: This information is only used for _display_ purposes: it in no way affects any of the arithmetic
     * of the contract, including {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title EmergencyShutdownable contract.
 * @notice Any contract that inherits this contract will have an emergency shutdown timestamp state variable.
 * This contract provides modifiers that can be used by children contracts to determine if the contract is
 * in the shutdown state. The child contract is expected to implement the logic that happens
 * once a shutdown occurs.
 */

abstract contract EmergencyShutdownable {
    using SafeMath for uint256;

    /****************************************
     * EMERGENCY SHUTDOWN DATA STRUCTURES *
     ****************************************/

    // Timestamp used in case of emergency shutdown. 0 if no shutdown has been triggered.
    uint256 public emergencyShutdownTimestamp;

    /****************************************
     *              MODIFIERS               *
     ****************************************/

    modifier notEmergencyShutdown() {
        _notEmergencyShutdown();
        _;
    }

    modifier isEmergencyShutdown() {
        _isEmergencyShutdown();
        _;
    }

    /****************************************
     *          EXTERNAL FUNCTIONS          *
     ****************************************/

    constructor() public {
        emergencyShutdownTimestamp = 0;
    }

    /****************************************
     *          INTERNAL FUNCTIONS          *
     ****************************************/

    function _notEmergencyShutdown() internal view {
        // Note: removed require string to save bytecode.
        require(emergencyShutdownTimestamp == 0);
    }

    function _isEmergencyShutdown() internal view {
        // Note: removed require string to save bytecode.
        require(emergencyShutdownTimestamp != 0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../common/implementation/Lockable.sol";
import "../../common/implementation/FixedPoint.sol";
import "../../common/implementation/Testable.sol";

import "../../oracle/interfaces/StoreInterface.sol";
import "../../oracle/interfaces/FinderInterface.sol";
import "../../oracle/interfaces/AdministrateeInterface.sol";
import "../../oracle/implementation/Constants.sol";

/**
 * @title FeePayer contract.
 * @notice Provides fee payment functionality for the ExpiringMultiParty contract.
 * contract is abstract as each derived contract that inherits `FeePayer` must implement `pfc()`.
 */

abstract contract FeePayer is AdministrateeInterface, Testable, Lockable {
    using SafeMath for uint256;
    using FixedPoint for FixedPoint.Unsigned;
    using SafeERC20 for IERC20;

    /****************************************
     *      FEE PAYER DATA STRUCTURES       *
     ****************************************/

    // The collateral currency used to back the positions in this contract.
    IERC20 public collateralCurrency;

    // Finder contract used to look up addresses for UMA system contracts.
    FinderInterface public finder;

    // Tracks the last block time when the fees were paid.
    uint256 private lastPaymentTime;

    // Tracks the cumulative fees that have been paid by the contract for use by derived contracts.
    // The multiplier starts at 1, and is updated by computing cumulativeFeeMultiplier * (1 - effectiveFee).
    // Put another way, the cumulativeFeeMultiplier is (1 - effectiveFee1) * (1 - effectiveFee2) ...
    // For example:
    // The cumulativeFeeMultiplier should start at 1.
    // If a 1% fee is charged, the multiplier should update to .99.
    // If another 1% fee is charged, the multiplier should be 0.99^2 (0.9801).
    FixedPoint.Unsigned public cumulativeFeeMultiplier;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event RegularFeesPaid(uint256 indexed regularFee, uint256 indexed lateFee);
    event FinalFeesPaid(uint256 indexed amount);

    /****************************************
     *              MODIFIERS               *
     ****************************************/

    // modifier that calls payRegularFees().
    modifier fees virtual {
        // Note: the regular fee is applied on every fee-accruing transaction, where the total change is simply the
        // regular fee applied linearly since the last update. This implies that the compounding rate depends on the
        // frequency of update transactions that have this modifier, and it never reaches the ideal of continuous
        // compounding. This approximate-compounding pattern is common in the Ethereum ecosystem because of the
        // complexity of compounding data on-chain.
        payRegularFees();
        _;
    }

    /**
     * @notice Constructs the FeePayer contract. Called by child contracts.
     * @param _collateralAddress ERC20 token that is used as the underlying collateral for the synthetic.
     * @param _finderAddress UMA protocol Finder used to discover other protocol contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(
        address _collateralAddress,
        address _finderAddress,
        address _timerAddress
    ) public Testable(_timerAddress) {
        collateralCurrency = IERC20(_collateralAddress);
        finder = FinderInterface(_finderAddress);
        lastPaymentTime = getCurrentTime();
        cumulativeFeeMultiplier = FixedPoint.fromUnscaledUint(1);
    }

    /****************************************
     *        FEE PAYMENT FUNCTIONS         *
     ****************************************/

    /**
     * @notice Pays UMA DVM regular fees (as a % of the collateral pool) to the Store contract.
     * @dev These must be paid periodically for the life of the contract. If the contract has not paid its regular fee
     * in a week or more then a late penalty is applied which is sent to the caller. If the amount of
     * fees owed are greater than the pfc, then this will pay as much as possible from the available collateral.
     * An event is only fired if the fees charged are greater than 0.
     * @return totalPaid Amount of collateral that the contract paid (sum of the amount paid to the Store and caller).
     * This returns 0 and exit early if there is no pfc, fees were already paid during the current block, or the fee rate is 0.
     */
    function payRegularFees() public nonReentrant() returns (FixedPoint.Unsigned memory totalPaid) {
        StoreInterface store = _getStore();
        uint256 time = getCurrentTime();
        FixedPoint.Unsigned memory collateralPool = _pfc();

        // Exit early if there is no collateral from which to pay fees.
        if (collateralPool.isEqual(0)) {
            // Note: set the lastPaymentTime in this case so the contract is credited for paying during periods when it
            // has no locked collateral.
            lastPaymentTime = time;
            return totalPaid;
        }

        // Exit early if fees were already paid during this block.
        if (lastPaymentTime == time) {
            return totalPaid;
        }

        (FixedPoint.Unsigned memory regularFee, FixedPoint.Unsigned memory latePenalty) =
            store.computeRegularFee(lastPaymentTime, time, collateralPool);
        lastPaymentTime = time;

        totalPaid = regularFee.add(latePenalty);
        if (totalPaid.isEqual(0)) {
            return totalPaid;
        }
        // If the effective fees paid as a % of the pfc is > 100%, then we need to reduce it and make the contract pay
        // as much of the fee that it can (up to 100% of its pfc). We'll reduce the late penalty first and then the
        // regular fee, which has the effect of paying the store first, followed by the caller if there is any fee remaining.
        if (totalPaid.isGreaterThan(collateralPool)) {
            FixedPoint.Unsigned memory deficit = totalPaid.sub(collateralPool);
            FixedPoint.Unsigned memory latePenaltyReduction = FixedPoint.min(latePenalty, deficit);
            latePenalty = latePenalty.sub(latePenaltyReduction);
            deficit = deficit.sub(latePenaltyReduction);
            regularFee = regularFee.sub(FixedPoint.min(regularFee, deficit));
            totalPaid = collateralPool;
        }

        emit RegularFeesPaid(regularFee.rawValue, latePenalty.rawValue);

        _adjustCumulativeFeeMultiplier(totalPaid, collateralPool);

        if (regularFee.isGreaterThan(0)) {
            collateralCurrency.safeIncreaseAllowance(address(store), regularFee.rawValue);
            store.payOracleFeesErc20(address(collateralCurrency), regularFee);
        }

        if (latePenalty.isGreaterThan(0)) {
            collateralCurrency.safeTransfer(msg.sender, latePenalty.rawValue);
        }
        return totalPaid;
    }

    /**
     * @notice Gets the current profit from corruption for this contract in terms of the collateral currency.
     * @dev This is equivalent to the collateral pool available from which to pay fees. Therefore, derived contracts are
     * expected to implement this so that pay-fee methods can correctly compute the owed fees as a % of PfC.
     * @return pfc value for equal to the current profit from corruption denominated in collateral currency.
     */
    function pfc() external view override nonReentrantView() returns (FixedPoint.Unsigned memory) {
        return _pfc();
    }

    /**
     * @notice Removes excess collateral balance not counted in the PfC by distributing it out pro-rata to all sponsors.
     * @dev Multiplying the `cumulativeFeeMultiplier` by the ratio of non-PfC-collateral :: PfC-collateral effectively
     * pays all sponsors a pro-rata portion of the excess collateral.
     * @dev This will revert if PfC is 0 and this contract's collateral balance > 0.
     */
    function gulp() external nonReentrant() {
        _gulp();
    }

    /****************************************
     *         INTERNAL FUNCTIONS           *
     ****************************************/

    // Pays UMA Oracle final fees of `amount` in `collateralCurrency` to the Store contract. Final fee is a flat fee
    // charged for each price request. If payer is the contract, adjusts internal bookkeeping variables. If payer is not
    // the contract, pulls in `amount` of collateral currency.
    function _payFinalFees(address payer, FixedPoint.Unsigned memory amount) internal {
        if (amount.isEqual(0)) {
            return;
        }

        if (payer != address(this)) {
            // If the payer is not the contract pull the collateral from the payer.
            collateralCurrency.safeTransferFrom(payer, address(this), amount.rawValue);
        } else {
            // If the payer is the contract, adjust the cumulativeFeeMultiplier to compensate.
            FixedPoint.Unsigned memory collateralPool = _pfc();

            // The final fee must be < available collateral or the fee will be larger than 100%.
            // Note: revert reason removed to save bytecode.
            require(collateralPool.isGreaterThan(amount));

            _adjustCumulativeFeeMultiplier(amount, collateralPool);
        }

        emit FinalFeesPaid(amount.rawValue);

        StoreInterface store = _getStore();
        collateralCurrency.safeIncreaseAllowance(address(store), amount.rawValue);
        store.payOracleFeesErc20(address(collateralCurrency), amount);
    }

    function _gulp() internal {
        FixedPoint.Unsigned memory currentPfc = _pfc();
        FixedPoint.Unsigned memory currentBalance = FixedPoint.Unsigned(collateralCurrency.balanceOf(address(this)));
        if (currentPfc.isLessThan(currentBalance)) {
            cumulativeFeeMultiplier = cumulativeFeeMultiplier.mul(currentBalance.div(currentPfc));
        }
    }

    function _pfc() internal view virtual returns (FixedPoint.Unsigned memory);

    function _getStore() internal view returns (StoreInterface) {
        return StoreInterface(finder.getImplementationAddress(OracleInterfaces.Store));
    }

    function _computeFinalFees() internal view returns (FixedPoint.Unsigned memory finalFees) {
        StoreInterface store = _getStore();
        return store.computeFinalFee(address(collateralCurrency));
    }

    // Returns the user's collateral minus any fees that have been subtracted since it was originally
    // deposited into the contract. Note: if the contract has paid fees since it was deployed, the raw
    // value should be larger than the returned value.
    function _getFeeAdjustedCollateral(FixedPoint.Unsigned memory rawCollateral)
        internal
        view
        returns (FixedPoint.Unsigned memory collateral)
    {
        return rawCollateral.mul(cumulativeFeeMultiplier);
    }

    // Converts a user-readable collateral value into a raw value that accounts for already-assessed fees. If any fees
    // have been taken from this contract in the past, then the raw value will be larger than the user-readable value.
    function _convertToRawCollateral(FixedPoint.Unsigned memory collateral)
        internal
        view
        returns (FixedPoint.Unsigned memory rawCollateral)
    {
        return collateral.div(cumulativeFeeMultiplier);
    }

    // Decrease rawCollateral by a fee-adjusted collateralToRemove amount. Fee adjustment scales up collateralToRemove
    // by dividing it by cumulativeFeeMultiplier. There is potential for this quotient to be floored, therefore
    // rawCollateral is decreased by less than expected. Because this method is usually called in conjunction with an
    // actual removal of collateral from this contract, return the fee-adjusted amount that the rawCollateral is
    // decreased by so that the caller can minimize error between collateral removed and rawCollateral debited.
    function _removeCollateral(FixedPoint.Unsigned storage rawCollateral, FixedPoint.Unsigned memory collateralToRemove)
        internal
        returns (FixedPoint.Unsigned memory removedCollateral)
    {
        FixedPoint.Unsigned memory initialBalance = _getFeeAdjustedCollateral(rawCollateral);
        FixedPoint.Unsigned memory adjustedCollateral = _convertToRawCollateral(collateralToRemove);
        rawCollateral.rawValue = rawCollateral.sub(adjustedCollateral).rawValue;
        removedCollateral = initialBalance.sub(_getFeeAdjustedCollateral(rawCollateral));
    }

    // Increase rawCollateral by a fee-adjusted collateralToAdd amount. Fee adjustment scales up collateralToAdd
    // by dividing it by cumulativeFeeMultiplier. There is potential for this quotient to be floored, therefore
    // rawCollateral is increased by less than expected. Because this method is usually called in conjunction with an
    // actual addition of collateral to this contract, return the fee-adjusted amount that the rawCollateral is
    // increased by so that the caller can minimize error between collateral added and rawCollateral credited.
    // NOTE: This return value exists only for the sake of symmetry with _removeCollateral. We don't actually use it
    // because we are OK if more collateral is stored in the contract than is represented by rawTotalPositionCollateral.
    function _addCollateral(FixedPoint.Unsigned storage rawCollateral, FixedPoint.Unsigned memory collateralToAdd)
        internal
        returns (FixedPoint.Unsigned memory addedCollateral)
    {
        FixedPoint.Unsigned memory initialBalance = _getFeeAdjustedCollateral(rawCollateral);
        FixedPoint.Unsigned memory adjustedCollateral = _convertToRawCollateral(collateralToAdd);
        rawCollateral.rawValue = rawCollateral.add(adjustedCollateral).rawValue;
        addedCollateral = _getFeeAdjustedCollateral(rawCollateral).sub(initialBalance);
    }

    // Scale the cumulativeFeeMultiplier by the ratio of fees paid to the current available collateral.
    function _adjustCumulativeFeeMultiplier(FixedPoint.Unsigned memory amount, FixedPoint.Unsigned memory currentPfc)
        internal
    {
        FixedPoint.Unsigned memory effectiveFee = amount.divCeil(currentPfc);
        cumulativeFeeMultiplier = cumulativeFeeMultiplier.mul(FixedPoint.fromUnscaledUint(1).sub(effectiveFee));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../common/implementation/Lockable.sol";
import "../../common/implementation/FixedPoint.sol";
import "../../common/implementation/Testable.sol";

import "../../oracle/implementation/Constants.sol";
import "../../oracle/interfaces/OptimisticOracleInterface.sol";
import "../perpetual-multiparty/ConfigStoreInterface.sol";

import "./EmergencyShutdownable.sol";
import "./FeePayer.sol";

/**
 * @title FundingRateApplier contract.
 * @notice Provides funding rate payment functionality for the Perpetual contract.
 */

abstract contract FundingRateApplier is EmergencyShutdownable, FeePayer {
    using FixedPoint for FixedPoint.Unsigned;
    using FixedPoint for FixedPoint.Signed;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /****************************************
     * FUNDING RATE APPLIER DATA STRUCTURES *
     ****************************************/

    struct FundingRate {
        // Current funding rate value.
        FixedPoint.Signed rate;
        // Identifier to retrieve the funding rate.
        bytes32 identifier;
        // Tracks the cumulative funding payments that have been paid to the sponsors.
        // The multiplier starts at 1, and is updated by computing cumulativeFundingRateMultiplier * (1 + effectivePayment).
        // Put another way, the cumulativeFeeMultiplier is (1 + effectivePayment1) * (1 + effectivePayment2) ...
        // For example:
        // The cumulativeFundingRateMultiplier should start at 1.
        // If a 1% funding payment is paid to sponsors, the multiplier should update to 1.01.
        // If another 1% fee is charged, the multiplier should be 1.01^2 (1.0201).
        FixedPoint.Unsigned cumulativeMultiplier;
        // Most recent time that the funding rate was updated.
        uint256 updateTime;
        // Most recent time that the funding rate was applied and changed the cumulative multiplier.
        uint256 applicationTime;
        // The time for the active (if it exists) funding rate proposal. 0 otherwise.
        uint256 proposalTime;
    }

    FundingRate public fundingRate;

    // Remote config store managed an owner.
    ConfigStoreInterface public configStore;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event FundingRateUpdated(int256 newFundingRate, uint256 indexed updateTime, uint256 reward);

    /****************************************
     *              MODIFIERS               *
     ****************************************/

    // This is overridden to both pay fees (which is done by applyFundingRate()) and apply the funding rate.
    modifier fees override {
        // Note: the funding rate is applied on every fee-accruing transaction, where the total change is simply the
        // rate applied linearly since the last update. This implies that the compounding rate depends on the frequency
        // of update transactions that have this modifier, and it never reaches the ideal of continuous compounding.
        // This approximate-compounding pattern is common in the Ethereum ecosystem because of the complexity of
        // compounding data on-chain.
        applyFundingRate();
        _;
    }

    // Note: this modifier is intended to be used if the caller intends to _only_ pay regular fees.
    modifier regularFees {
        payRegularFees();
        _;
    }

    /**
     * @notice Constructs the FundingRateApplier contract. Called by child contracts.
     * @param _fundingRateIdentifier identifier that tracks the funding rate of this contract.
     * @param _collateralAddress address of the collateral token.
     * @param _finderAddress Finder used to discover financial-product-related contracts.
     * @param _configStoreAddress address of the remote configuration store managed by an external owner.
     * @param _tokenScaling initial scaling to apply to the token value (i.e. scales the tracking index).
     * @param _timerAddress address of the timer contract in test envs, otherwise 0x0.
     */
    constructor(
        bytes32 _fundingRateIdentifier,
        address _collateralAddress,
        address _finderAddress,
        address _configStoreAddress,
        FixedPoint.Unsigned memory _tokenScaling,
        address _timerAddress
    ) public FeePayer(_collateralAddress, _finderAddress, _timerAddress) EmergencyShutdownable() {
        uint256 currentTime = getCurrentTime();
        fundingRate.updateTime = currentTime;
        fundingRate.applicationTime = currentTime;

        // Seed the cumulative multiplier with the token scaling, from which it will be scaled as funding rates are
        // applied over time.
        fundingRate.cumulativeMultiplier = _tokenScaling;

        fundingRate.identifier = _fundingRateIdentifier;
        configStore = ConfigStoreInterface(_configStoreAddress);
    }

    /**
     * @notice This method takes 3 distinct actions:
     * 1. Pays out regular fees.
     * 2. If possible, resolves the outstanding funding rate proposal, pulling the result in and paying out the rewards.
     * 3. Applies the prevailing funding rate over the most recent period.
     */
    function applyFundingRate() public regularFees() nonReentrant() {
        _applyEffectiveFundingRate();
    }

    /**
     * @notice Proposes a new funding rate. Proposer receives a reward if correct.
     * @param rate funding rate being proposed.
     * @param timestamp time at which the funding rate was computed.
     */
    function proposeNewRate(FixedPoint.Signed memory rate, uint256 timestamp)
        external
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory totalBond)
    {
        require(fundingRate.proposalTime == 0, "Proposal in progress");
        _validateFundingRate(rate);

        // Timestamp must be after the last funding rate update time, within the last 30 minutes.
        uint256 currentTime = getCurrentTime();
        uint256 updateTime = fundingRate.updateTime;
        require(
            timestamp > updateTime && timestamp >= currentTime.sub(_getConfig().proposalTimePastLimit),
            "Invalid proposal time"
        );

        // Set the proposal time in order to allow this contract to track this request.
        fundingRate.proposalTime = timestamp;

        OptimisticOracleInterface optimisticOracle = _getOptimisticOracle();

        // Set up optimistic oracle.
        bytes32 identifier = fundingRate.identifier;
        bytes memory ancillaryData = _getAncillaryData();
        // Note: requestPrice will revert if `timestamp` is less than the current block timestamp.
        optimisticOracle.requestPrice(identifier, timestamp, ancillaryData, collateralCurrency, 0);
        totalBond = FixedPoint.Unsigned(
            optimisticOracle.setBond(
                identifier,
                timestamp,
                ancillaryData,
                _pfc().mul(_getConfig().proposerBondPct).rawValue
            )
        );

        // Pull bond from caller and send to optimistic oracle.
        if (totalBond.isGreaterThan(0)) {
            collateralCurrency.safeTransferFrom(msg.sender, address(this), totalBond.rawValue);
            collateralCurrency.safeIncreaseAllowance(address(optimisticOracle), totalBond.rawValue);
        }

        optimisticOracle.proposePriceFor(
            msg.sender,
            address(this),
            identifier,
            timestamp,
            ancillaryData,
            rate.rawValue
        );
    }

    // Returns a token amount scaled by the current funding rate multiplier.
    // Note: if the contract has paid fees since it was deployed, the raw value should be larger than the returned value.
    function _getFundingRateAppliedTokenDebt(FixedPoint.Unsigned memory rawTokenDebt)
        internal
        view
        returns (FixedPoint.Unsigned memory tokenDebt)
    {
        return rawTokenDebt.mul(fundingRate.cumulativeMultiplier);
    }

    function _getOptimisticOracle() internal view returns (OptimisticOracleInterface) {
        return OptimisticOracleInterface(finder.getImplementationAddress(OracleInterfaces.OptimisticOracle));
    }

    function _getConfig() internal returns (ConfigStoreInterface.ConfigSettings memory) {
        return configStore.updateAndGetCurrentConfig();
    }

    function _getLatestFundingRate() internal returns (FixedPoint.Signed memory) {
        uint256 proposalTime = fundingRate.proposalTime;

        // If there is no pending proposal then return the current funding rate, otherwise
        // check to see if we can update the funding rate.
        if (proposalTime != 0) {
            // Attempt to update the funding rate.
            OptimisticOracleInterface optimisticOracle = _getOptimisticOracle();
            bytes32 identifier = fundingRate.identifier;
            bytes memory ancillaryData = _getAncillaryData();

            // Try to get the price from the optimistic oracle. This call will revert if the request has not resolved
            // yet. If the request has not resolved yet, then we need to do additional checks to see if we should
            // "forget" the pending proposal and allow new proposals to update the funding rate.
            try optimisticOracle.getPrice(identifier, proposalTime, ancillaryData) returns (int256 price) {
                // If successful, determine if the funding rate state needs to be updated.
                // If the request is more recent than the last update then we should update it.
                uint256 lastUpdateTime = fundingRate.updateTime;
                if (proposalTime >= lastUpdateTime) {
                    // Update funding rates
                    fundingRate.rate = FixedPoint.Signed(price);
                    fundingRate.updateTime = proposalTime;

                    // If there was no dispute, send a reward.
                    FixedPoint.Unsigned memory reward = FixedPoint.fromUnscaledUint(0);
                    OptimisticOracleInterface.Request memory request =
                        optimisticOracle.getRequest(address(this), identifier, proposalTime, ancillaryData);
                    if (request.disputer == address(0)) {
                        reward = _pfc().mul(_getConfig().rewardRatePerSecond).mul(proposalTime.sub(lastUpdateTime));
                        if (reward.isGreaterThan(0)) {
                            _adjustCumulativeFeeMultiplier(reward, _pfc());
                            collateralCurrency.safeTransfer(request.proposer, reward.rawValue);
                        }
                    }

                    // This event will only be emitted after the fundingRate struct's "updateTime" has been set
                    // to the latest proposal's proposalTime, indicating that the proposal has been published.
                    // So, it suffices to just emit fundingRate.updateTime here.
                    emit FundingRateUpdated(fundingRate.rate.rawValue, fundingRate.updateTime, reward.rawValue);
                }

                // Set proposal time to 0 since this proposal has now been resolved.
                fundingRate.proposalTime = 0;
            } catch {
                // Stop tracking and allow other proposals to come in if:
                // - The requester address is empty, indicating that the Oracle does not know about this funding rate
                //   request. This is possible if the Oracle is replaced while the price request is still pending.
                // - The request has been disputed.
                OptimisticOracleInterface.Request memory request =
                    optimisticOracle.getRequest(address(this), identifier, proposalTime, ancillaryData);
                if (request.disputer != address(0) || request.proposer == address(0)) {
                    fundingRate.proposalTime = 0;
                }
            }
        }
        return fundingRate.rate;
    }

    // Constraining the range of funding rates limits the PfC for any dishonest proposer and enhances the
    // perpetual's security. For example, let's examine the case where the max and min funding rates
    // are equivalent to +/- 500%/year. This 1000% funding rate range allows a 8.6% profit from corruption for a
    // proposer who can deter honest proposers for 74 hours:
    // 1000%/year / 360 days / 24 hours * 74 hours max attack time = ~ 8.6%.
    // How would attack work? Imagine that the market is very volatile currently and that the "true" funding
    // rate for the next 74 hours is -500%, but a dishonest proposer successfully proposes a rate of +500%
    // (after a two hour liveness) and disputes honest proposers for the next 72 hours. This results in a funding
    // rate error of 1000% for 74 hours, until the DVM can set the funding rate back to its correct value.
    function _validateFundingRate(FixedPoint.Signed memory rate) internal {
        require(
            rate.isLessThanOrEqual(_getConfig().maxFundingRate) &&
                rate.isGreaterThanOrEqual(_getConfig().minFundingRate)
        );
    }

    // Fetches a funding rate from the Store, determines the period over which to compute an effective fee,
    // and multiplies the current multiplier by the effective fee.
    // A funding rate < 1 will reduce the multiplier, and a funding rate of > 1 will increase the multiplier.
    // Note: 1 is set as the neutral rate because there are no negative numbers in FixedPoint, so we decide to treat
    // values < 1 as "negative".
    function _applyEffectiveFundingRate() internal {
        // If contract is emergency shutdown, then the funding rate multiplier should no longer change.
        if (emergencyShutdownTimestamp != 0) {
            return;
        }

        uint256 currentTime = getCurrentTime();
        uint256 paymentPeriod = currentTime.sub(fundingRate.applicationTime);

        fundingRate.cumulativeMultiplier = _calculateEffectiveFundingRate(
            paymentPeriod,
            _getLatestFundingRate(),
            fundingRate.cumulativeMultiplier
        );

        fundingRate.applicationTime = currentTime;
    }

    function _calculateEffectiveFundingRate(
        uint256 paymentPeriodSeconds,
        FixedPoint.Signed memory fundingRatePerSecond,
        FixedPoint.Unsigned memory currentCumulativeFundingRateMultiplier
    ) internal pure returns (FixedPoint.Unsigned memory newCumulativeFundingRateMultiplier) {
        // Note: this method uses named return variables to save a little bytecode.

        // The overall formula that this function is performing:
        //   newCumulativeFundingRateMultiplier =
        //   (1 + (fundingRatePerSecond * paymentPeriodSeconds)) * currentCumulativeFundingRateMultiplier.
        FixedPoint.Signed memory ONE = FixedPoint.fromUnscaledInt(1);

        // Multiply the per-second rate over the number of seconds that have elapsed to get the period rate.
        FixedPoint.Signed memory periodRate = fundingRatePerSecond.mul(SafeCast.toInt256(paymentPeriodSeconds));

        // Add one to create the multiplier to scale the existing fee multiplier.
        FixedPoint.Signed memory signedPeriodMultiplier = ONE.add(periodRate);

        // Max with 0 to ensure the multiplier isn't negative, then cast to an Unsigned.
        FixedPoint.Unsigned memory unsignedPeriodMultiplier =
            FixedPoint.fromSigned(FixedPoint.max(signedPeriodMultiplier, FixedPoint.fromUnscaledInt(0)));

        // Multiply the existing cumulative funding rate multiplier by the computed period multiplier to get the new
        // cumulative funding rate multiplier.
        newCumulativeFundingRateMultiplier = currentCumulativeFundingRateMultiplier.mul(unsignedPeriodMultiplier);
    }

    function _getAncillaryData() internal view returns (bytes memory) {
        // Note: when ancillary data is passed to the optimistic oracle, it should be tagged with the token address
        // whose funding rate it's trying to get.
        return abi.encodePacked(_getTokenAddress());
    }

    function _getTokenAddress() internal view virtual returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
import "../../common/implementation/ExpandedERC20.sol";
import "../../common/implementation/Lockable.sol";

/**
 * @title Burnable and mintable ERC20.
 * @dev The contract deployer will initially be the only minter, burner and owner capable of adding new roles.
 */

contract SyntheticToken is ExpandedERC20, Lockable {
    /**
     * @notice Constructs the SyntheticToken.
     * @param tokenName The name which describes the new token.
     * @param tokenSymbol The ticker abbreviation of the name. Ideally < 5 chars.
     * @param tokenDecimals The number of decimals to define token precision.
     */
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) public ExpandedERC20(tokenName, tokenSymbol, tokenDecimals) nonReentrant() {}

    /**
     * @notice Add Minter role to account.
     * @dev The caller must have the Owner role.
     * @param account The address to which the Minter role is added.
     */
    function addMinter(address account) external override nonReentrant() {
        addMember(uint256(Roles.Minter), account);
    }

    /**
     * @notice Remove Minter role from account.
     * @dev The caller must have the Owner role.
     * @param account The address from which the Minter role is removed.
     */
    function removeMinter(address account) external nonReentrant() {
        removeMember(uint256(Roles.Minter), account);
    }

    /**
     * @notice Add Burner role to account.
     * @dev The caller must have the Owner role.
     * @param account The address to which the Burner role is added.
     */
    function addBurner(address account) external override nonReentrant() {
        addMember(uint256(Roles.Burner), account);
    }

    /**
     * @notice Removes Burner role from account.
     * @dev The caller must have the Owner role.
     * @param account The address from which the Burner role is removed.
     */
    function removeBurner(address account) external nonReentrant() {
        removeMember(uint256(Roles.Burner), account);
    }

    /**
     * @notice Reset Owner role to account.
     * @dev The caller must have the Owner role.
     * @param account The new holder of the Owner role.
     */
    function resetOwner(address account) external override nonReentrant() {
        resetMember(uint256(Roles.Owner), account);
    }

    /**
     * @notice Checks if a given account holds the Minter role.
     * @param account The address which is checked for the Minter role.
     * @return bool True if the provided account is a Minter.
     */
    function isMinter(address account) public view nonReentrantView() returns (bool) {
        return holdsRole(uint256(Roles.Minter), account);
    }

    /**
     * @notice Checks if a given account holds the Burner role.
     * @param account The address which is checked for the Burner role.
     * @return bool True if the provided account is a Burner.
     */
    function isBurner(address account) public view nonReentrantView() returns (bool) {
        return holdsRole(uint256(Roles.Burner), account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./SyntheticToken.sol";
import "../../common/interfaces/ExpandedIERC20.sol";
import "../../common/implementation/Lockable.sol";

/**
 * @title Factory for creating new mintable and burnable tokens.
 */

contract TokenFactory is Lockable {
    /**
     * @notice Create a new token and return it to the caller.
     * @dev The caller will become the only minter and burner and the new owner capable of assigning the roles.
     * @param tokenName used to describe the new token.
     * @param tokenSymbol short ticker abbreviation of the name. Ideally < 5 chars.
     * @param tokenDecimals used to define the precision used in the token's numerical representation.
     * @return newToken an instance of the newly created token interface.
     */
    function createToken(
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals
    ) external nonReentrant() returns (ExpandedIERC20 newToken) {
        SyntheticToken mintableToken = new SyntheticToken(tokenName, tokenSymbol, tokenDecimals);
        mintableToken.addMinter(msg.sender);
        mintableToken.addBurner(msg.sender);
        mintableToken.resetOwner(msg.sender);
        newToken = ExpandedIERC20(address(mintableToken));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ConfigStoreInterface.sol";
import "../../common/implementation/Testable.sol";
import "../../common/implementation/Lockable.sol";
import "../../common/implementation/FixedPoint.sol";

/**
 * @notice ConfigStore stores configuration settings for a perpetual contract and provides an interface for it
 * to query settings such as reward rates, proposal bond sizes, etc. The configuration settings can be upgraded
 * by a privileged account and the upgraded changes are timelocked.
 */
contract ConfigStore is ConfigStoreInterface, Testable, Lockable, Ownable {
    using SafeMath for uint256;
    using FixedPoint for FixedPoint.Unsigned;

    /****************************************
     *        STORE DATA STRUCTURES         *
     ****************************************/

    // Make currentConfig private to force user to call getCurrentConfig, which returns the pendingConfig
    // if its liveness has expired.
    ConfigStoreInterface.ConfigSettings private currentConfig;

    // Beginning on `pendingPassedTimestamp`, the `pendingConfig` can be published as the current config.
    ConfigStoreInterface.ConfigSettings public pendingConfig;
    uint256 public pendingPassedTimestamp;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event ProposedNewConfigSettings(
        address indexed proposer,
        uint256 rewardRate,
        uint256 proposerBond,
        uint256 timelockLiveness,
        int256 maxFundingRate,
        int256 minFundingRate,
        uint256 proposalTimePastLimit,
        uint256 proposalPassedTimestamp
    );
    event ChangedConfigSettings(
        uint256 rewardRate,
        uint256 proposerBond,
        uint256 timelockLiveness,
        int256 maxFundingRate,
        int256 minFundingRate,
        uint256 proposalTimePastLimit
    );

    /****************************************
     *                MODIFIERS             *
     ****************************************/

    // Update config settings if possible.
    modifier updateConfig() {
        _updateConfig();
        _;
    }

    /**
     * @notice Construct the Config Store. An initial configuration is provided and set on construction.
     * @param _initialConfig Configuration settings to initialize `currentConfig` with.
     * @param _timerAddress Address of testable Timer contract.
     */
    constructor(ConfigSettings memory _initialConfig, address _timerAddress) public Testable(_timerAddress) {
        _validateConfig(_initialConfig);
        currentConfig = _initialConfig;
    }

    /**
     * @notice Returns current config or pending config if pending liveness has expired.
     * @return ConfigSettings config settings that calling financial contract should view as "live".
     */
    function updateAndGetCurrentConfig()
        external
        override
        updateConfig()
        nonReentrant()
        returns (ConfigStoreInterface.ConfigSettings memory)
    {
        return currentConfig;
    }

    /**
     * @notice Propose new configuration settings. New settings go into effect after a liveness period passes.
     * @param newConfig Configuration settings to publish after `currentConfig.timelockLiveness` passes from now.
     * @dev Callable only by owner. Calling this while there is already a pending proposal will overwrite the pending proposal.
     */
    function proposeNewConfig(ConfigSettings memory newConfig) external onlyOwner() nonReentrant() updateConfig() {
        _validateConfig(newConfig);

        // Warning: This overwrites a pending proposal!
        pendingConfig = newConfig;

        // Use current config's liveness period to timelock this proposal.
        pendingPassedTimestamp = getCurrentTime().add(currentConfig.timelockLiveness);

        emit ProposedNewConfigSettings(
            msg.sender,
            newConfig.rewardRatePerSecond.rawValue,
            newConfig.proposerBondPct.rawValue,
            newConfig.timelockLiveness,
            newConfig.maxFundingRate.rawValue,
            newConfig.minFundingRate.rawValue,
            newConfig.proposalTimePastLimit,
            pendingPassedTimestamp
        );
    }

    /**
     * @notice Publish any pending configuration settings if there is a pending proposal that has passed liveness.
     */
    function publishPendingConfig() external nonReentrant() updateConfig() {}

    /****************************************
     *         INTERNAL FUNCTIONS           *
     ****************************************/

    // Check if pending proposal can overwrite the current config.
    function _updateConfig() internal {
        // If liveness has passed, publish proposed configuration settings.
        if (_pendingProposalPassed()) {
            currentConfig = pendingConfig;

            _deletePendingConfig();

            emit ChangedConfigSettings(
                currentConfig.rewardRatePerSecond.rawValue,
                currentConfig.proposerBondPct.rawValue,
                currentConfig.timelockLiveness,
                currentConfig.maxFundingRate.rawValue,
                currentConfig.minFundingRate.rawValue,
                currentConfig.proposalTimePastLimit
            );
        }
    }

    function _deletePendingConfig() internal {
        delete pendingConfig;
        pendingPassedTimestamp = 0;
    }

    function _pendingProposalPassed() internal view returns (bool) {
        return (pendingPassedTimestamp != 0 && pendingPassedTimestamp <= getCurrentTime());
    }

    // Use this method to constrain values with which you can set ConfigSettings.
    function _validateConfig(ConfigStoreInterface.ConfigSettings memory config) internal pure {
        // We don't set limits on proposal timestamps because there are already natural limits:
        // - Future: price requests to the OptimisticOracle must be in the past---we can't add further constraints.
        // - Past: proposal times must always be after the last update time, and  a reasonable past limit would be 30
        //   mins, meaning that no proposal timestamp can be more than 30 minutes behind the current time.

        // Make sure timelockLiveness is not too long, otherwise contract might not be able to fix itself
        // before a vulnerability drains its collateral.
        require(config.timelockLiveness <= 7 days && config.timelockLiveness >= 1 days, "Invalid timelockLiveness");

        // The reward rate should be modified as needed to incentivize honest proposers appropriately.
        // Additionally, the rate should be less than 100% a year => 100% / 360 days / 24 hours / 60 mins / 60 secs
        // = 0.0000033
        FixedPoint.Unsigned memory maxRewardRatePerSecond = FixedPoint.fromUnscaledUint(33).div(1e7);
        require(config.rewardRatePerSecond.isLessThan(maxRewardRatePerSecond), "Invalid rewardRatePerSecond");

        // We don't set a limit on the proposer bond because it is a defense against dishonest proposers. If a proposer
        // were to successfully propose a very high or low funding rate, then their PfC would be very high. The proposer
        // could theoretically keep their "evil" funding rate alive indefinitely by continuously disputing honest
        // proposers, so we would want to be able to set the proposal bond (equal to the dispute bond) higher than their
        // PfC for each proposal liveness window. The downside of not limiting this is that the config store owner
        // can set it arbitrarily high and preclude a new funding rate from ever coming in. We suggest setting the
        // proposal bond based on the configuration's funding rate range like in this discussion:
        // https://github.com/UMAprotocol/protocol/issues/2039#issuecomment-719734383

        // We also don't set a limit on the funding rate max/min because we might need to allow very high magnitude
        // funding rates in extraordinarily volatile market situations. Note, that even though we do not bound
        // the max/min, we still recommend that the deployer of this contract set the funding rate max/min values
        // to bound the PfC of a dishonest proposer. A reasonable range might be the equivalent of [+200%/year, -200%/year].
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/implementation/FixedPoint.sol";

interface ConfigStoreInterface {
    // All of the configuration settings available for querying by a perpetual.
    struct ConfigSettings {
        // Liveness period (in seconds) for an update to currentConfig to become official.
        uint256 timelockLiveness;
        // Reward rate paid to successful proposers. Percentage of 1 E.g., .1 is 10%.
        FixedPoint.Unsigned rewardRatePerSecond;
        // Bond % (of given contract's PfC) that must be staked by proposers. Percentage of 1, e.g. 0.0005 is 0.05%.
        FixedPoint.Unsigned proposerBondPct;
        // Maximum funding rate % per second that can be proposed.
        FixedPoint.Signed maxFundingRate;
        // Minimum funding rate % per second that can be proposed.
        FixedPoint.Signed minFundingRate;
        // Funding rate proposal timestamp cannot be more than this amount of seconds in the past from the latest
        // update time.
        uint256 proposalTimePastLimit;
    }

    function updateAndGetCurrentConfig() external returns (ConfigSettings memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./PerpetualLiquidatable.sol";

/**
 * @title Perpetual Multiparty Contract.
 * @notice Convenient wrapper for Liquidatable.
 */
contract Perpetual is PerpetualLiquidatable {
    /**
     * @notice Constructs the Perpetual contract.
     * @param params struct to define input parameters for construction of Liquidatable. Some params
     * are fed directly into the PositionManager's constructor within the inheritance tree.
     */
    constructor(ConstructorParams memory params)
        public
        PerpetualLiquidatable(params)
    // Note: since there is no logic here, there is no need to add a re-entrancy guard.
    {

    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/interfaces/ExpandedIERC20.sol";
import "../../common/interfaces/IERC20Standard.sol";
import "../../oracle/implementation/ContractCreator.sol";
import "../../common/implementation/Testable.sol";
import "../../common/implementation/AddressWhitelist.sol";
import "../../common/implementation/Lockable.sol";
import "../common/TokenFactory.sol";
import "../common/SyntheticToken.sol";
import "./PerpetualLib.sol";
import "./ConfigStore.sol";

/**
 * @title Perpetual Contract creator.
 * @notice Factory contract to create and register new instances of perpetual contracts.
 * Responsible for constraining the parameters used to construct a new perpetual. This creator contains a number of constraints
 * that are applied to newly created contract. These constraints can evolve over time and are
 * initially constrained to conservative values in this first iteration. Technically there is nothing in the
 * Perpetual contract requiring these constraints. However, because `createPerpetual()` is intended
 * to be the only way to create valid financial contracts that are registered with the DVM (via _registerContract),
  we can enforce deployment configurations here.
 */
contract PerpetualCreator is ContractCreator, Testable, Lockable {
    using FixedPoint for FixedPoint.Unsigned;

    /****************************************
     *     PERP CREATOR DATA STRUCTURES      *
     ****************************************/

    // Immutable params for perpetual contract.
    struct Params {
        address collateralAddress;
        bytes32 priceFeedIdentifier;
        bytes32 fundingRateIdentifier;
        string syntheticName;
        string syntheticSymbol;
        FixedPoint.Unsigned collateralRequirement;
        FixedPoint.Unsigned disputeBondPct;
        FixedPoint.Unsigned sponsorDisputeRewardPct;
        FixedPoint.Unsigned disputerDisputeRewardPct;
        FixedPoint.Unsigned minSponsorTokens;
        FixedPoint.Unsigned tokenScaling;
        uint256 withdrawalLiveness;
        uint256 liquidationLiveness;
    }
    // Address of TokenFactory used to create a new synthetic token.
    address public tokenFactoryAddress;

    event CreatedPerpetual(address indexed perpetualAddress, address indexed deployerAddress);
    event CreatedConfigStore(address indexed configStoreAddress, address indexed ownerAddress);

    /**
     * @notice Constructs the Perpetual contract.
     * @param _finderAddress UMA protocol Finder used to discover other protocol contracts.
     * @param _tokenFactoryAddress ERC20 token factory used to deploy synthetic token instances.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     */
    constructor(
        address _finderAddress,
        address _tokenFactoryAddress,
        address _timerAddress
    ) public ContractCreator(_finderAddress) Testable(_timerAddress) nonReentrant() {
        tokenFactoryAddress = _tokenFactoryAddress;
    }

    /**
     * @notice Creates an instance of perpetual and registers it within the registry.
     * @param params is a `ConstructorParams` object from Perpetual.
     * @return address of the deployed contract.
     */
    function createPerpetual(Params memory params, ConfigStore.ConfigSettings memory configSettings)
        public
        nonReentrant()
        returns (address)
    {
        require(bytes(params.syntheticName).length != 0, "Missing synthetic name");
        require(bytes(params.syntheticSymbol).length != 0, "Missing synthetic symbol");

        // Create new config settings store for this contract and reset ownership to the deployer.
        ConfigStore configStore = new ConfigStore(configSettings, timerAddress);
        configStore.transferOwnership(msg.sender);
        emit CreatedConfigStore(address(configStore), configStore.owner());

        // Create a new synthetic token using the params.
        TokenFactory tf = TokenFactory(tokenFactoryAddress);

        // If the collateral token does not have a `decimals()` method,
        // then a default precision of 18 will be applied to the newly created synthetic token.
        uint8 syntheticDecimals = _getSyntheticDecimals(params.collateralAddress);
        ExpandedIERC20 tokenCurrency = tf.createToken(params.syntheticName, params.syntheticSymbol, syntheticDecimals);
        address derivative = PerpetualLib.deploy(_convertParams(params, tokenCurrency, address(configStore)));

        // Give permissions to new derivative contract and then hand over ownership.
        tokenCurrency.addMinter(derivative);
        tokenCurrency.addBurner(derivative);
        tokenCurrency.resetOwner(derivative);

        _registerContract(new address[](0), derivative);

        emit CreatedPerpetual(derivative, msg.sender);

        return derivative;
    }

    /****************************************
     *          PRIVATE FUNCTIONS           *
     ****************************************/

    // Converts createPerpetual params to Perpetual constructor params.
    function _convertParams(
        Params memory params,
        ExpandedIERC20 newTokenCurrency,
        address configStore
    ) private view returns (Perpetual.ConstructorParams memory constructorParams) {
        // Known from creator deployment.
        constructorParams.finderAddress = finderAddress;
        constructorParams.timerAddress = timerAddress;

        // Enforce configuration constraints.
        require(params.withdrawalLiveness != 0, "Withdrawal liveness cannot be 0");
        require(params.liquidationLiveness != 0, "Liquidation liveness cannot be 0");
        _requireWhitelistedCollateral(params.collateralAddress);

        // We don't want perpetual deployers to be able to intentionally or unintentionally set
        // liveness periods that could induce arithmetic overflow, but we also don't want
        // to be opinionated about what livenesses are "correct", so we will somewhat
        // arbitrarily set the liveness upper bound to 100 years (5200 weeks). In practice, liveness
        // periods even greater than a few days would make the perpetual unusable for most users.
        require(params.withdrawalLiveness < 5200 weeks, "Withdrawal liveness too large");
        require(params.liquidationLiveness < 5200 weeks, "Liquidation liveness too large");

        // To avoid precision loss or overflows, prevent the token scaling from being too large or too small.
        FixedPoint.Unsigned memory minScaling = FixedPoint.Unsigned(1e8); // 1e-10
        FixedPoint.Unsigned memory maxScaling = FixedPoint.Unsigned(1e28); // 1e10
        require(
            params.tokenScaling.isGreaterThan(minScaling) && params.tokenScaling.isLessThan(maxScaling),
            "Invalid tokenScaling"
        );

        // Input from function call.
        constructorParams.configStoreAddress = configStore;
        constructorParams.tokenAddress = address(newTokenCurrency);
        constructorParams.collateralAddress = params.collateralAddress;
        constructorParams.priceFeedIdentifier = params.priceFeedIdentifier;
        constructorParams.fundingRateIdentifier = params.fundingRateIdentifier;
        constructorParams.collateralRequirement = params.collateralRequirement;
        constructorParams.disputeBondPct = params.disputeBondPct;
        constructorParams.sponsorDisputeRewardPct = params.sponsorDisputeRewardPct;
        constructorParams.disputerDisputeRewardPct = params.disputerDisputeRewardPct;
        constructorParams.minSponsorTokens = params.minSponsorTokens;
        constructorParams.withdrawalLiveness = params.withdrawalLiveness;
        constructorParams.liquidationLiveness = params.liquidationLiveness;
        constructorParams.tokenScaling = params.tokenScaling;
    }

    // IERC20Standard.decimals() will revert if the collateral contract has not implemented the decimals() method,
    // which is possible since the method is only an OPTIONAL method in the ERC20 standard:
    // https://eips.ethereum.org/EIPS/eip-20#methods.
    function _getSyntheticDecimals(address _collateralAddress) public view returns (uint8 decimals) {
        try IERC20Standard(_collateralAddress).decimals() returns (uint8 _decimals) {
            return _decimals;
        } catch {
            return 18;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Perpetual.sol";

/**
 * @title Provides convenient Perpetual Multi Party contract utilities.
 * @dev Using this library to deploy Perpetuals allows calling contracts to avoid importing the full bytecode.
 */
library PerpetualLib {
    /**
     * @notice Returns address of new Perpetual deployed with given `params` configuration.
     * @dev Caller will need to register new Perpetual with the Registry to begin requesting prices. Caller is also
     * responsible for enforcing constraints on `params`.
     * @param params is a `ConstructorParams` object from Perpetual.
     * @return address of the deployed Perpetual contract
     */
    function deploy(Perpetual.ConstructorParams memory params) public returns (address) {
        Perpetual derivative = new Perpetual(params);
        return address(derivative);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./PerpetualPositionManager.sol";

import "../../common/implementation/FixedPoint.sol";

/**
 * @title PerpetualLiquidatable
 * @notice Adds logic to a position-managing contract that enables callers to liquidate an undercollateralized position.
 * @dev The liquidation has a liveness period before expiring successfully, during which someone can "dispute" the
 * liquidation, which sends a price request to the relevant Oracle to settle the final collateralization ratio based on
 * a DVM price. The contract enforces dispute rewards in order to incentivize disputers to correctly dispute false
 * liquidations and compensate position sponsors who had their position incorrectly liquidated. Importantly, a
 * prospective disputer must deposit a dispute bond that they can lose in the case of an unsuccessful dispute.
 */
contract PerpetualLiquidatable is PerpetualPositionManager {
    using FixedPoint for FixedPoint.Unsigned;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /****************************************
     *     LIQUIDATION DATA STRUCTURES      *
     ****************************************/

    // Because of the check in withdrawable(), the order of these enum values should not change.
    enum Status { Uninitialized, PreDispute, PendingDispute, DisputeSucceeded, DisputeFailed }

    struct LiquidationData {
        // Following variables set upon creation of liquidation:
        address sponsor; // Address of the liquidated position's sponsor
        address liquidator; // Address who created this liquidation
        Status state; // Liquidated (and expired or not), Pending a Dispute, or Dispute has resolved
        uint256 liquidationTime; // Time when liquidation is initiated, needed to get price from Oracle
        // Following variables determined by the position that is being liquidated:
        FixedPoint.Unsigned tokensOutstanding; // Synthetic tokens required to be burned by liquidator to initiate dispute
        FixedPoint.Unsigned lockedCollateral; // Collateral locked by contract and released upon expiry or post-dispute
        // Amount of collateral being liquidated, which could be different from
        // lockedCollateral if there were pending withdrawals at the time of liquidation
        FixedPoint.Unsigned liquidatedCollateral;
        // Unit value (starts at 1) that is used to track the fees per unit of collateral over the course of the liquidation.
        FixedPoint.Unsigned rawUnitCollateral;
        // Following variable set upon initiation of a dispute:
        address disputer; // Person who is disputing a liquidation
        // Following variable set upon a resolution of a dispute:
        FixedPoint.Unsigned settlementPrice; // Final price as determined by an Oracle following a dispute
        FixedPoint.Unsigned finalFee;
    }

    // Define the contract's constructor parameters as a struct to enable more variables to be specified.
    // This is required to enable more params, over and above Solidity's limits.
    struct ConstructorParams {
        // Params for PerpetualPositionManager only.
        uint256 withdrawalLiveness;
        address configStoreAddress;
        address collateralAddress;
        address tokenAddress;
        address finderAddress;
        address timerAddress;
        bytes32 priceFeedIdentifier;
        bytes32 fundingRateIdentifier;
        FixedPoint.Unsigned minSponsorTokens;
        FixedPoint.Unsigned tokenScaling;
        // Params specifically for PerpetualLiquidatable.
        uint256 liquidationLiveness;
        FixedPoint.Unsigned collateralRequirement;
        FixedPoint.Unsigned disputeBondPct;
        FixedPoint.Unsigned sponsorDisputeRewardPct;
        FixedPoint.Unsigned disputerDisputeRewardPct;
    }

    // This struct is used in the `withdrawLiquidation` method that disperses liquidation and dispute rewards.
    // `payToX` stores the total collateral to withdraw from the contract to pay X. This value might differ
    // from `paidToX` due to precision loss between accounting for the `rawCollateral` versus the
    // fee-adjusted collateral. These variables are stored within a struct to avoid the stack too deep error.
    struct RewardsData {
        FixedPoint.Unsigned payToSponsor;
        FixedPoint.Unsigned payToLiquidator;
        FixedPoint.Unsigned payToDisputer;
        FixedPoint.Unsigned paidToSponsor;
        FixedPoint.Unsigned paidToLiquidator;
        FixedPoint.Unsigned paidToDisputer;
    }

    // Liquidations are unique by ID per sponsor
    mapping(address => LiquidationData[]) public liquidations;

    // Total collateral in liquidation.
    FixedPoint.Unsigned public rawLiquidationCollateral;

    // Immutable contract parameters:
    // Amount of time for pending liquidation before expiry.
    // !!Note: The lower the liquidation liveness value, the more risk incurred by sponsors.
    //       Extremely low liveness values increase the chance that opportunistic invalid liquidations
    //       expire without dispute, thereby decreasing the usability for sponsors and increasing the risk
    //       for the contract as a whole. An insolvent contract is extremely risky for any sponsor or synthetic
    //       token holder for the contract.
    uint256 public liquidationLiveness;
    // Required collateral:TRV ratio for a position to be considered sufficiently collateralized.
    FixedPoint.Unsigned public collateralRequirement;
    // Percent of a Liquidation/Position's lockedCollateral to be deposited by a potential disputer
    // Represented as a multiplier, for example 1.5e18 = "150%" and 0.05e18 = "5%"
    FixedPoint.Unsigned public disputeBondPct;
    // Percent of oraclePrice paid to sponsor in the Disputed state (i.e. following a successful dispute)
    // Represented as a multiplier, see above.
    FixedPoint.Unsigned public sponsorDisputeRewardPct;
    // Percent of oraclePrice paid to disputer in the Disputed state (i.e. following a successful dispute)
    // Represented as a multiplier, see above.
    FixedPoint.Unsigned public disputerDisputeRewardPct;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event LiquidationCreated(
        address indexed sponsor,
        address indexed liquidator,
        uint256 indexed liquidationId,
        uint256 tokensOutstanding,
        uint256 lockedCollateral,
        uint256 liquidatedCollateral,
        uint256 liquidationTime
    );
    event LiquidationDisputed(
        address indexed sponsor,
        address indexed liquidator,
        address indexed disputer,
        uint256 liquidationId,
        uint256 disputeBondAmount
    );
    event DisputeSettled(
        address indexed caller,
        address indexed sponsor,
        address indexed liquidator,
        address disputer,
        uint256 liquidationId,
        bool disputeSucceeded
    );
    event LiquidationWithdrawn(
        address indexed caller,
        uint256 paidToLiquidator,
        uint256 paidToDisputer,
        uint256 paidToSponsor,
        Status indexed liquidationStatus,
        uint256 settlementPrice
    );

    /****************************************
     *              MODIFIERS               *
     ****************************************/

    modifier disputable(uint256 liquidationId, address sponsor) {
        _disputable(liquidationId, sponsor);
        _;
    }

    modifier withdrawable(uint256 liquidationId, address sponsor) {
        _withdrawable(liquidationId, sponsor);
        _;
    }

    /**
     * @notice Constructs the liquidatable contract.
     * @param params struct to define input parameters for construction of Liquidatable. Some params
     * are fed directly into the PositionManager's constructor within the inheritance tree.
     */
    constructor(ConstructorParams memory params)
        public
        PerpetualPositionManager(
            params.withdrawalLiveness,
            params.collateralAddress,
            params.tokenAddress,
            params.finderAddress,
            params.priceFeedIdentifier,
            params.fundingRateIdentifier,
            params.minSponsorTokens,
            params.configStoreAddress,
            params.tokenScaling,
            params.timerAddress
        )
    {
        require(params.collateralRequirement.isGreaterThan(1));
        require(params.sponsorDisputeRewardPct.add(params.disputerDisputeRewardPct).isLessThan(1));

        // Set liquidatable specific variables.
        liquidationLiveness = params.liquidationLiveness;
        collateralRequirement = params.collateralRequirement;
        disputeBondPct = params.disputeBondPct;
        sponsorDisputeRewardPct = params.sponsorDisputeRewardPct;
        disputerDisputeRewardPct = params.disputerDisputeRewardPct;
    }

    /****************************************
     *        LIQUIDATION FUNCTIONS         *
     ****************************************/

    /**
     * @notice Liquidates the sponsor's position if the caller has enough
     * synthetic tokens to retire the position's outstanding tokens. Liquidations above
     * a minimum size also reset an ongoing "slow withdrawal"'s liveness.
     * @dev This method generates an ID that will uniquely identify liquidation for the sponsor. This contract must be
     * approved to spend at least `tokensLiquidated` of `tokenCurrency` and at least `finalFeeBond` of `collateralCurrency`.
     * @dev This contract must have the Burner role for the `tokenCurrency`.
     * @param sponsor address of the sponsor to liquidate.
     * @param minCollateralPerToken abort the liquidation if the position's collateral per token is below this value.
     * @param maxCollateralPerToken abort the liquidation if the position's collateral per token exceeds this value.
     * @param maxTokensToLiquidate max number of tokens to liquidate.
     * @param deadline abort the liquidation if the transaction is mined after this timestamp.
     * @return liquidationId ID of the newly created liquidation.
     * @return tokensLiquidated amount of synthetic tokens removed and liquidated from the `sponsor`'s position.
     * @return finalFeeBond amount of collateral to be posted by liquidator and returned if not disputed successfully.
     */
    function createLiquidation(
        address sponsor,
        FixedPoint.Unsigned calldata minCollateralPerToken,
        FixedPoint.Unsigned calldata maxCollateralPerToken,
        FixedPoint.Unsigned calldata maxTokensToLiquidate,
        uint256 deadline
    )
        external
        notEmergencyShutdown()
        fees()
        nonReentrant()
        returns (
            uint256 liquidationId,
            FixedPoint.Unsigned memory tokensLiquidated,
            FixedPoint.Unsigned memory finalFeeBond
        )
    {
        // Check that this transaction was mined pre-deadline.
        require(getCurrentTime() <= deadline, "Mined after deadline");

        // Retrieve Position data for sponsor
        PositionData storage positionToLiquidate = _getPositionData(sponsor);

        tokensLiquidated = FixedPoint.min(maxTokensToLiquidate, positionToLiquidate.tokensOutstanding);
        require(tokensLiquidated.isGreaterThan(0));

        // Starting values for the Position being liquidated. If withdrawal request amount is > position's collateral,
        // then set this to 0, otherwise set it to (startCollateral - withdrawal request amount).
        FixedPoint.Unsigned memory startCollateral = _getFeeAdjustedCollateral(positionToLiquidate.rawCollateral);
        FixedPoint.Unsigned memory startCollateralNetOfWithdrawal = FixedPoint.fromUnscaledUint(0);
        if (positionToLiquidate.withdrawalRequestAmount.isLessThanOrEqual(startCollateral)) {
            startCollateralNetOfWithdrawal = startCollateral.sub(positionToLiquidate.withdrawalRequestAmount);
        }

        // Scoping to get rid of a stack too deep error.
        {
            FixedPoint.Unsigned memory startTokens = positionToLiquidate.tokensOutstanding;

            // The Position's collateralization ratio must be between [minCollateralPerToken, maxCollateralPerToken].
            require(
                maxCollateralPerToken.mul(startTokens).isGreaterThanOrEqual(startCollateralNetOfWithdrawal),
                "CR is more than max liq. price"
            );
            // minCollateralPerToken >= startCollateralNetOfWithdrawal / startTokens.
            require(
                minCollateralPerToken.mul(startTokens).isLessThanOrEqual(startCollateralNetOfWithdrawal),
                "CR is less than min liq. price"
            );
        }

        // Compute final fee at time of liquidation.
        finalFeeBond = _computeFinalFees();

        // These will be populated within the scope below.
        FixedPoint.Unsigned memory lockedCollateral;
        FixedPoint.Unsigned memory liquidatedCollateral;

        // Scoping to get rid of a stack too deep error. The amount of tokens to remove from the position
        // are not funding-rate adjusted because the multiplier only affects their redemption value, not their
        // notional.
        {
            FixedPoint.Unsigned memory ratio = tokensLiquidated.div(positionToLiquidate.tokensOutstanding);

            // The actual amount of collateral that gets moved to the liquidation.
            lockedCollateral = startCollateral.mul(ratio);

            // For purposes of disputes, it's actually this liquidatedCollateral value that's used. This value is net of
            // withdrawal requests.
            liquidatedCollateral = startCollateralNetOfWithdrawal.mul(ratio);

            // Part of the withdrawal request is also removed. Ideally:
            // liquidatedCollateral + withdrawalAmountToRemove = lockedCollateral.
            FixedPoint.Unsigned memory withdrawalAmountToRemove =
                positionToLiquidate.withdrawalRequestAmount.mul(ratio);
            _reduceSponsorPosition(sponsor, tokensLiquidated, lockedCollateral, withdrawalAmountToRemove);
        }

        // Add to the global liquidation collateral count.
        _addCollateral(rawLiquidationCollateral, lockedCollateral.add(finalFeeBond));

        // Construct liquidation object.
        // Note: All dispute-related values are zeroed out until a dispute occurs. liquidationId is the index of the new
        // LiquidationData that is pushed into the array, which is equal to the current length of the array pre-push.
        liquidationId = liquidations[sponsor].length;
        liquidations[sponsor].push(
            LiquidationData({
                sponsor: sponsor,
                liquidator: msg.sender,
                state: Status.PreDispute,
                liquidationTime: getCurrentTime(),
                tokensOutstanding: _getFundingRateAppliedTokenDebt(tokensLiquidated),
                lockedCollateral: lockedCollateral,
                liquidatedCollateral: liquidatedCollateral,
                rawUnitCollateral: _convertToRawCollateral(FixedPoint.fromUnscaledUint(1)),
                disputer: address(0),
                settlementPrice: FixedPoint.fromUnscaledUint(0),
                finalFee: finalFeeBond
            })
        );

        // If this liquidation is a subsequent liquidation on the position, and the liquidation size is larger than
        // some "griefing threshold", then re-set the liveness. This enables a liquidation against a withdraw request to be
        // "dragged out" if the position is very large and liquidators need time to gather funds. The griefing threshold
        // is enforced so that liquidations for trivially small # of tokens cannot drag out an honest sponsor's slow withdrawal.

        // We arbitrarily set the "griefing threshold" to `minSponsorTokens` because it is the only parameter
        // denominated in token currency units and we can avoid adding another parameter.
        FixedPoint.Unsigned memory griefingThreshold = minSponsorTokens;
        if (
            positionToLiquidate.withdrawalRequestPassTimestamp > 0 && // The position is undergoing a slow withdrawal.
            positionToLiquidate.withdrawalRequestPassTimestamp > getCurrentTime() && // The slow withdrawal has not yet expired.
            tokensLiquidated.isGreaterThanOrEqual(griefingThreshold) // The liquidated token count is above a "griefing threshold".
        ) {
            positionToLiquidate.withdrawalRequestPassTimestamp = getCurrentTime().add(withdrawalLiveness);
        }

        emit LiquidationCreated(
            sponsor,
            msg.sender,
            liquidationId,
            _getFundingRateAppliedTokenDebt(tokensLiquidated).rawValue,
            lockedCollateral.rawValue,
            liquidatedCollateral.rawValue,
            getCurrentTime()
        );

        // Destroy tokens
        tokenCurrency.safeTransferFrom(msg.sender, address(this), tokensLiquidated.rawValue);
        tokenCurrency.burn(tokensLiquidated.rawValue);

        // Pull final fee from liquidator.
        collateralCurrency.safeTransferFrom(msg.sender, address(this), finalFeeBond.rawValue);
    }

    /**
     * @notice Disputes a liquidation, if the caller has enough collateral to post a dispute bond
     * and pay a fixed final fee charged on each price request.
     * @dev Can only dispute a liquidation before the liquidation expires and if there are no other pending disputes.
     * This contract must be approved to spend at least the dispute bond amount of `collateralCurrency`. This dispute
     * bond amount is calculated from `disputeBondPct` times the collateral in the liquidation.
     * @param liquidationId of the disputed liquidation.
     * @param sponsor the address of the sponsor whose liquidation is being disputed.
     * @return totalPaid amount of collateral charged to disputer (i.e. final fee bond + dispute bond).
     */
    function dispute(uint256 liquidationId, address sponsor)
        external
        disputable(liquidationId, sponsor)
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory totalPaid)
    {
        LiquidationData storage disputedLiquidation = _getLiquidationData(sponsor, liquidationId);

        // Multiply by the unit collateral so the dispute bond is a percentage of the locked collateral after fees.
        FixedPoint.Unsigned memory disputeBondAmount =
            disputedLiquidation.lockedCollateral.mul(disputeBondPct).mul(
                _getFeeAdjustedCollateral(disputedLiquidation.rawUnitCollateral)
            );
        _addCollateral(rawLiquidationCollateral, disputeBondAmount);

        // Request a price from DVM. Liquidation is pending dispute until DVM returns a price.
        disputedLiquidation.state = Status.PendingDispute;
        disputedLiquidation.disputer = msg.sender;

        // Enqueue a request with the DVM.
        _requestOraclePrice(disputedLiquidation.liquidationTime);

        emit LiquidationDisputed(
            sponsor,
            disputedLiquidation.liquidator,
            msg.sender,
            liquidationId,
            disputeBondAmount.rawValue
        );
        totalPaid = disputeBondAmount.add(disputedLiquidation.finalFee);

        // Pay the final fee for requesting price from the DVM.
        _payFinalFees(msg.sender, disputedLiquidation.finalFee);

        // Transfer the dispute bond amount from the caller to this contract.
        collateralCurrency.safeTransferFrom(msg.sender, address(this), disputeBondAmount.rawValue);
    }

    /**
     * @notice After a dispute has settled or after a non-disputed liquidation has expired,
     * anyone can call this method to disperse payments to the sponsor, liquidator, and disputer.
     * @dev If the dispute SUCCEEDED: the sponsor, liquidator, and disputer are eligible for payment.
     * If the dispute FAILED: only the liquidator receives payment. This method deletes the liquidation data.
     * This method will revert if rewards have already been dispersed.
     * @param liquidationId uniquely identifies the sponsor's liquidation.
     * @param sponsor address of the sponsor associated with the liquidation.
     * @return data about rewards paid out.
     */
    function withdrawLiquidation(uint256 liquidationId, address sponsor)
        public
        withdrawable(liquidationId, sponsor)
        fees()
        nonReentrant()
        returns (RewardsData memory)
    {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);

        // Settles the liquidation if necessary. This call will revert if the price has not resolved yet.
        _settle(liquidationId, sponsor);

        // Calculate rewards as a function of the TRV.
        // Note: all payouts are scaled by the unit collateral value so all payouts are charged the fees pro rata.
        // TODO: Do we also need to apply some sort of funding rate adjustment to account for multiplier changes
        // since liquidation time?
        FixedPoint.Unsigned memory feeAttenuation = _getFeeAdjustedCollateral(liquidation.rawUnitCollateral);
        FixedPoint.Unsigned memory settlementPrice = liquidation.settlementPrice;
        FixedPoint.Unsigned memory tokenRedemptionValue =
            liquidation.tokensOutstanding.mul(settlementPrice).mul(feeAttenuation);
        FixedPoint.Unsigned memory collateral = liquidation.lockedCollateral.mul(feeAttenuation);
        FixedPoint.Unsigned memory disputerDisputeReward = disputerDisputeRewardPct.mul(tokenRedemptionValue);
        FixedPoint.Unsigned memory sponsorDisputeReward = sponsorDisputeRewardPct.mul(tokenRedemptionValue);
        FixedPoint.Unsigned memory disputeBondAmount = collateral.mul(disputeBondPct);
        FixedPoint.Unsigned memory finalFee = liquidation.finalFee.mul(feeAttenuation);

        // There are three main outcome states: either the dispute succeeded, failed or was not updated.
        // Based on the state, different parties of a liquidation receive different amounts.
        // After assigning rewards based on the liquidation status, decrease the total collateral held in this contract
        // by the amount to pay each party. The actual amounts withdrawn might differ if _removeCollateral causes
        // precision loss.
        RewardsData memory rewards;
        if (liquidation.state == Status.DisputeSucceeded) {
            // If the dispute is successful then all three users should receive rewards:

            // Pay DISPUTER: disputer reward + dispute bond + returned final fee
            rewards.payToDisputer = disputerDisputeReward.add(disputeBondAmount).add(finalFee);

            // Pay SPONSOR: remaining collateral (collateral - TRV) + sponsor reward
            rewards.payToSponsor = sponsorDisputeReward.add(collateral.sub(tokenRedemptionValue));

            // Pay LIQUIDATOR: TRV - dispute reward - sponsor reward
            // If TRV > Collateral, then subtract rewards from collateral
            // NOTE: This should never be below zero since we prevent (sponsorDisputePct+disputerDisputePct) >= 0 in
            // the constructor when these params are set.
            rewards.payToLiquidator = tokenRedemptionValue.sub(sponsorDisputeReward).sub(disputerDisputeReward);

            // Transfer rewards and debit collateral
            rewards.paidToLiquidator = _removeCollateral(rawLiquidationCollateral, rewards.payToLiquidator);
            rewards.paidToSponsor = _removeCollateral(rawLiquidationCollateral, rewards.payToSponsor);
            rewards.paidToDisputer = _removeCollateral(rawLiquidationCollateral, rewards.payToDisputer);

            collateralCurrency.safeTransfer(liquidation.disputer, rewards.paidToDisputer.rawValue);
            collateralCurrency.safeTransfer(liquidation.liquidator, rewards.paidToLiquidator.rawValue);
            collateralCurrency.safeTransfer(liquidation.sponsor, rewards.paidToSponsor.rawValue);

            // In the case of a failed dispute only the liquidator can withdraw.
        } else if (liquidation.state == Status.DisputeFailed) {
            // Pay LIQUIDATOR: collateral + dispute bond + returned final fee
            rewards.payToLiquidator = collateral.add(disputeBondAmount).add(finalFee);

            // Transfer rewards and debit collateral
            rewards.paidToLiquidator = _removeCollateral(rawLiquidationCollateral, rewards.payToLiquidator);

            collateralCurrency.safeTransfer(liquidation.liquidator, rewards.paidToLiquidator.rawValue);

            // If the state is pre-dispute but time has passed liveness then there was no dispute. We represent this
            // state as a dispute failed and the liquidator can withdraw.
        } else if (liquidation.state == Status.PreDispute) {
            // Pay LIQUIDATOR: collateral + returned final fee
            rewards.payToLiquidator = collateral.add(finalFee);

            // Transfer rewards and debit collateral
            rewards.paidToLiquidator = _removeCollateral(rawLiquidationCollateral, rewards.payToLiquidator);

            collateralCurrency.safeTransfer(liquidation.liquidator, rewards.paidToLiquidator.rawValue);
        }

        emit LiquidationWithdrawn(
            msg.sender,
            rewards.paidToLiquidator.rawValue,
            rewards.paidToDisputer.rawValue,
            rewards.paidToSponsor.rawValue,
            liquidation.state,
            settlementPrice.rawValue
        );

        // Free up space after collateral is withdrawn by removing the liquidation object from the array.
        delete liquidations[sponsor][liquidationId];

        return rewards;
    }

    /**
     * @notice Gets all liquidation information for a given sponsor address.
     * @param sponsor address of the position sponsor.
     * @return liquidationData array of all liquidation information for the given sponsor address.
     */
    function getLiquidations(address sponsor)
        external
        view
        nonReentrantView()
        returns (LiquidationData[] memory liquidationData)
    {
        return liquidations[sponsor];
    }

    /****************************************
     *          INTERNAL FUNCTIONS          *
     ****************************************/

    // This settles a liquidation if it is in the PendingDispute state. If not, it will immediately return.
    // If the liquidation is in the PendingDispute state, but a price is not available, this will revert.
    function _settle(uint256 liquidationId, address sponsor) internal {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);

        // Settlement only happens when state == PendingDispute and will only happen once per liquidation.
        // If this liquidation is not ready to be settled, this method should return immediately.
        if (liquidation.state != Status.PendingDispute) {
            return;
        }

        // Get the returned price from the oracle. If this has not yet resolved will revert.
        liquidation.settlementPrice = _getOraclePrice(liquidation.liquidationTime);

        // Find the value of the tokens in the underlying collateral.
        FixedPoint.Unsigned memory tokenRedemptionValue =
            liquidation.tokensOutstanding.mul(liquidation.settlementPrice);

        // The required collateral is the value of the tokens in underlying * required collateral ratio.
        FixedPoint.Unsigned memory requiredCollateral = tokenRedemptionValue.mul(collateralRequirement);

        // If the position has more than the required collateral it is solvent and the dispute is valid (liquidation is invalid)
        // Note that this check uses the liquidatedCollateral not the lockedCollateral as this considers withdrawals.
        bool disputeSucceeded = liquidation.liquidatedCollateral.isGreaterThanOrEqual(requiredCollateral);
        liquidation.state = disputeSucceeded ? Status.DisputeSucceeded : Status.DisputeFailed;

        emit DisputeSettled(
            msg.sender,
            sponsor,
            liquidation.liquidator,
            liquidation.disputer,
            liquidationId,
            disputeSucceeded
        );
    }

    function _pfc() internal view override returns (FixedPoint.Unsigned memory) {
        return super._pfc().add(_getFeeAdjustedCollateral(rawLiquidationCollateral));
    }

    function _getLiquidationData(address sponsor, uint256 liquidationId)
        internal
        view
        returns (LiquidationData storage liquidation)
    {
        LiquidationData[] storage liquidationArray = liquidations[sponsor];

        // Revert if the caller is attempting to access an invalid liquidation
        // (one that has never been created or one has never been initialized).
        require(
            liquidationId < liquidationArray.length && liquidationArray[liquidationId].state != Status.Uninitialized
        );
        return liquidationArray[liquidationId];
    }

    function _getLiquidationExpiry(LiquidationData storage liquidation) internal view returns (uint256) {
        return liquidation.liquidationTime.add(liquidationLiveness);
    }

    // These internal functions are supposed to act identically to modifiers, but re-used modifiers
    // unnecessarily increase contract bytecode size.
    // source: https://blog.polymath.network/solidity-tips-and-tricks-to-save-gas-and-reduce-bytecode-size-c44580b218e6
    function _disputable(uint256 liquidationId, address sponsor) internal view {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);
        require(
            (getCurrentTime() < _getLiquidationExpiry(liquidation)) && (liquidation.state == Status.PreDispute),
            "Liquidation not disputable"
        );
    }

    function _withdrawable(uint256 liquidationId, address sponsor) internal view {
        LiquidationData storage liquidation = _getLiquidationData(sponsor, liquidationId);
        Status state = liquidation.state;

        // Must be disputed or the liquidation has passed expiry.
        require(
            (state > Status.PreDispute) ||
                ((_getLiquidationExpiry(liquidation) <= getCurrentTime()) && (state == Status.PreDispute)),
            "Liquidation not withdrawable"
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../common/implementation/FixedPoint.sol";
import "../../common/interfaces/ExpandedIERC20.sol";

import "../../oracle/interfaces/OracleInterface.sol";
import "../../oracle/interfaces/IdentifierWhitelistInterface.sol";
import "../../oracle/implementation/Constants.sol";

import "../common/FundingRateApplier.sol";

/**
 * @title Financial contract with priceless position management.
 * @notice Handles positions for multiple sponsors in an optimistic (i.e., priceless) way without relying
 * on a price feed. On construction, deploys a new ERC20, managed by this contract, that is the synthetic token.
 */

contract PerpetualPositionManager is FundingRateApplier {
    using SafeMath for uint256;
    using FixedPoint for FixedPoint.Unsigned;
    using SafeERC20 for IERC20;
    using SafeERC20 for ExpandedIERC20;

    /****************************************
     *  PRICELESS POSITION DATA STRUCTURES  *
     ****************************************/

    // Represents a single sponsor's position. All collateral is held by this contract.
    // This struct acts as bookkeeping for how much of that collateral is allocated to each sponsor.
    struct PositionData {
        FixedPoint.Unsigned tokensOutstanding;
        // Tracks pending withdrawal requests. A withdrawal request is pending if `withdrawalRequestPassTimestamp != 0`.
        uint256 withdrawalRequestPassTimestamp;
        FixedPoint.Unsigned withdrawalRequestAmount;
        // Raw collateral value. This value should never be accessed directly -- always use _getFeeAdjustedCollateral().
        // To add or remove collateral, use _addCollateral() and _removeCollateral().
        FixedPoint.Unsigned rawCollateral;
    }

    // Maps sponsor addresses to their positions. Each sponsor can have only one position.
    mapping(address => PositionData) public positions;

    // Keep track of the total collateral and tokens across all positions to enable calculating the
    // global collateralization ratio without iterating over all positions.
    FixedPoint.Unsigned public totalTokensOutstanding;

    // Similar to the rawCollateral in PositionData, this value should not be used directly.
    // _getFeeAdjustedCollateral(), _addCollateral() and _removeCollateral() must be used to access and adjust.
    FixedPoint.Unsigned public rawTotalPositionCollateral;

    // Synthetic token created by this contract.
    ExpandedIERC20 public tokenCurrency;

    // Unique identifier for DVM price feed ticker.
    bytes32 public priceIdentifier;

    // Time that has to elapse for a withdrawal request to be considered passed, if no liquidations occur.
    // !!Note: The lower the withdrawal liveness value, the more risk incurred by the contract.
    //       Extremely low liveness values increase the chance that opportunistic invalid withdrawal requests
    //       expire without liquidation, thereby increasing the insolvency risk for the contract as a whole. An insolvent
    //       contract is extremely risky for any sponsor or synthetic token holder for the contract.
    uint256 public withdrawalLiveness;

    // Minimum number of tokens in a sponsor's position.
    FixedPoint.Unsigned public minSponsorTokens;

    // Expiry price pulled from the DVM in the case of an emergency shutdown.
    FixedPoint.Unsigned public emergencyShutdownPrice;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
    event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
    event RequestWithdrawal(address indexed sponsor, uint256 indexed collateralAmount);
    event RequestWithdrawalExecuted(address indexed sponsor, uint256 indexed collateralAmount);
    event RequestWithdrawalCanceled(address indexed sponsor, uint256 indexed collateralAmount);
    event PositionCreated(address indexed sponsor, uint256 indexed collateralAmount, uint256 indexed tokenAmount);
    event NewSponsor(address indexed sponsor);
    event EndedSponsorPosition(address indexed sponsor);
    event Redeem(address indexed sponsor, uint256 indexed collateralAmount, uint256 indexed tokenAmount);
    event Repay(address indexed sponsor, uint256 indexed numTokensRepaid, uint256 indexed newTokenCount);
    event EmergencyShutdown(address indexed caller, uint256 shutdownTimestamp);
    event SettleEmergencyShutdown(
        address indexed caller,
        uint256 indexed collateralReturned,
        uint256 indexed tokensBurned
    );

    /****************************************
     *               MODIFIERS              *
     ****************************************/

    modifier onlyCollateralizedPosition(address sponsor) {
        _onlyCollateralizedPosition(sponsor);
        _;
    }

    modifier noPendingWithdrawal(address sponsor) {
        _positionHasNoPendingWithdrawal(sponsor);
        _;
    }

    /**
     * @notice Construct the PerpetualPositionManager.
     * @dev Deployer of this contract should consider carefully which parties have ability to mint and burn
     * the synthetic tokens referenced by `_tokenAddress`. This contract's security assumes that no external accounts
     * can mint new tokens, which could be used to steal all of this contract's locked collateral.
     * We recommend to only use synthetic token contracts whose sole Owner role (the role capable of adding & removing roles)
     * is assigned to this contract, whose sole Minter role is assigned to this contract, and whose
     * total supply is 0 prior to construction of this contract.
     * @param _withdrawalLiveness liveness delay, in seconds, for pending withdrawals.
     * @param _collateralAddress ERC20 token used as collateral for all positions.
     * @param _tokenAddress ERC20 token used as synthetic token.
     * @param _finderAddress UMA protocol Finder used to discover other protocol contracts.
     * @param _priceIdentifier registered in the DVM for the synthetic.
     * @param _fundingRateIdentifier Unique identifier for DVM price feed ticker for child financial contract.
     * @param _minSponsorTokens minimum amount of collateral that must exist at any time in a position.
     * @param _tokenScaling initial scaling to apply to the token value (i.e. scales the tracking index).
     * @param _timerAddress Contract that stores the current time in a testing environment. Set to 0x0 for production.
     */
    constructor(
        uint256 _withdrawalLiveness,
        address _collateralAddress,
        address _tokenAddress,
        address _finderAddress,
        bytes32 _priceIdentifier,
        bytes32 _fundingRateIdentifier,
        FixedPoint.Unsigned memory _minSponsorTokens,
        address _configStoreAddress,
        FixedPoint.Unsigned memory _tokenScaling,
        address _timerAddress
    )
        public
        FundingRateApplier(
            _fundingRateIdentifier,
            _collateralAddress,
            _finderAddress,
            _configStoreAddress,
            _tokenScaling,
            _timerAddress
        )
    {
        require(_getIdentifierWhitelist().isIdentifierSupported(_priceIdentifier));

        withdrawalLiveness = _withdrawalLiveness;
        tokenCurrency = ExpandedIERC20(_tokenAddress);
        minSponsorTokens = _minSponsorTokens;
        priceIdentifier = _priceIdentifier;
    }

    /****************************************
     *          POSITION FUNCTIONS          *
     ****************************************/

    /**
     * @notice Transfers `collateralAmount` of `collateralCurrency` into the specified sponsor's position.
     * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
     * at least `collateralAmount` of `collateralCurrency`.
     * @param sponsor the sponsor to credit the deposit to.
     * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
     */
    function depositTo(address sponsor, FixedPoint.Unsigned memory collateralAmount)
        public
        notEmergencyShutdown()
        noPendingWithdrawal(sponsor)
        fees()
        nonReentrant()
    {
        require(collateralAmount.isGreaterThan(0));
        PositionData storage positionData = _getPositionData(sponsor);

        // Increase the position and global collateral balance by collateral amount.
        _incrementCollateralBalances(positionData, collateralAmount);

        emit Deposit(sponsor, collateralAmount.rawValue);

        // Move collateral currency from sender to contract.
        collateralCurrency.safeTransferFrom(msg.sender, address(this), collateralAmount.rawValue);
    }

    /**
     * @notice Transfers `collateralAmount` of `collateralCurrency` into the caller's position.
     * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
     * at least `collateralAmount` of `collateralCurrency`.
     * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
     */
    function deposit(FixedPoint.Unsigned memory collateralAmount) public {
        // This is just a thin wrapper over depositTo that specified the sender as the sponsor.
        depositTo(msg.sender, collateralAmount);
    }

    /**
     * @notice Transfers `collateralAmount` of `collateralCurrency` from the sponsor's position to the sponsor.
     * @dev Reverts if the withdrawal puts this position's collateralization ratio below the global collateralization
     * ratio. In that case, use `requestWithdrawal`. Might not withdraw the full requested amount to account for precision loss.
     * @param collateralAmount is the amount of collateral to withdraw.
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function withdraw(FixedPoint.Unsigned memory collateralAmount)
        public
        notEmergencyShutdown()
        noPendingWithdrawal(msg.sender)
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        require(collateralAmount.isGreaterThan(0));
        PositionData storage positionData = _getPositionData(msg.sender);

        // Decrement the sponsor's collateral and global collateral amounts. Check the GCR between decrement to ensure
        // position remains above the GCR within the withdrawal. If this is not the case the caller must submit a request.
        amountWithdrawn = _decrementCollateralBalancesCheckGCR(positionData, collateralAmount);

        emit Withdrawal(msg.sender, amountWithdrawn.rawValue);

        // Move collateral currency from contract to sender.
        // Note: that we move the amount of collateral that is decreased from rawCollateral (inclusive of fees)
        // instead of the user requested amount. This eliminates precision loss that could occur
        // where the user withdraws more collateral than rawCollateral is decremented by.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
    }

    /**
     * @notice Starts a withdrawal request that, if passed, allows the sponsor to withdraw from their position.
     * @dev The request will be pending for `withdrawalLiveness`, during which the position can be liquidated.
     * @param collateralAmount the amount of collateral requested to withdraw
     */
    function requestWithdrawal(FixedPoint.Unsigned memory collateralAmount)
        public
        notEmergencyShutdown()
        noPendingWithdrawal(msg.sender)
        nonReentrant()
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(
            collateralAmount.isGreaterThan(0) &&
                collateralAmount.isLessThanOrEqual(_getFeeAdjustedCollateral(positionData.rawCollateral))
        );

        // Update the position object for the user.
        positionData.withdrawalRequestPassTimestamp = getCurrentTime().add(withdrawalLiveness);
        positionData.withdrawalRequestAmount = collateralAmount;

        emit RequestWithdrawal(msg.sender, collateralAmount.rawValue);
    }

    /**
     * @notice After a passed withdrawal request (i.e., by a call to `requestWithdrawal` and waiting
     * `withdrawalLiveness`), withdraws `positionData.withdrawalRequestAmount` of collateral currency.
     * @dev Might not withdraw the full requested amount in order to account for precision loss or if the full requested
     * amount exceeds the collateral in the position (due to paying fees).
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function withdrawPassedRequest()
        external
        notEmergencyShutdown()
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(
            positionData.withdrawalRequestPassTimestamp != 0 &&
                positionData.withdrawalRequestPassTimestamp <= getCurrentTime(),
            "Invalid withdraw request"
        );

        // If withdrawal request amount is > position collateral, then withdraw the full collateral amount.
        // This situation is possible due to fees charged since the withdrawal was originally requested.
        FixedPoint.Unsigned memory amountToWithdraw = positionData.withdrawalRequestAmount;
        if (positionData.withdrawalRequestAmount.isGreaterThan(_getFeeAdjustedCollateral(positionData.rawCollateral))) {
            amountToWithdraw = _getFeeAdjustedCollateral(positionData.rawCollateral);
        }

        // Decrement the sponsor's collateral and global collateral amounts.
        amountWithdrawn = _decrementCollateralBalances(positionData, amountToWithdraw);

        // Reset withdrawal request by setting withdrawal amount and withdrawal timestamp to 0.
        _resetWithdrawalRequest(positionData);

        // Transfer approved withdrawal amount from the contract to the caller.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);

        emit RequestWithdrawalExecuted(msg.sender, amountWithdrawn.rawValue);
    }

    /**
     * @notice Cancels a pending withdrawal request.
     */
    function cancelWithdrawal() external notEmergencyShutdown() nonReentrant() {
        PositionData storage positionData = _getPositionData(msg.sender);
        // No pending withdrawal require message removed to save bytecode.
        require(positionData.withdrawalRequestPassTimestamp != 0);

        emit RequestWithdrawalCanceled(msg.sender, positionData.withdrawalRequestAmount.rawValue);

        // Reset withdrawal request by setting withdrawal amount and withdrawal timestamp to 0.
        _resetWithdrawalRequest(positionData);
    }

    /**
     * @notice Creates tokens by creating a new position or by augmenting an existing position. Pulls `collateralAmount
     * ` into the sponsor's position and mints `numTokens` of `tokenCurrency`.
     * @dev This contract must have the Minter role for the `tokenCurrency`.
     * @dev Reverts if minting these tokens would put the position's collateralization ratio below the
     * global collateralization ratio. This contract must be approved to spend at least `collateralAmount` of
     * `collateralCurrency`.
     * @param collateralAmount is the number of collateral tokens to collateralize the position with
     * @param numTokens is the number of tokens to mint from the position.
     */
    function create(FixedPoint.Unsigned memory collateralAmount, FixedPoint.Unsigned memory numTokens)
        public
        notEmergencyShutdown()
        fees()
        nonReentrant()
    {
        PositionData storage positionData = positions[msg.sender];

        // Either the new create ratio or the resultant position CR must be above the current GCR.
        require(
            (_checkCollateralization(
                _getFeeAdjustedCollateral(positionData.rawCollateral).add(collateralAmount),
                positionData.tokensOutstanding.add(numTokens)
            ) || _checkCollateralization(collateralAmount, numTokens)),
            "Insufficient collateral"
        );

        require(positionData.withdrawalRequestPassTimestamp == 0);
        if (positionData.tokensOutstanding.isEqual(0)) {
            require(numTokens.isGreaterThanOrEqual(minSponsorTokens));
            emit NewSponsor(msg.sender);
        }

        // Increase the position and global collateral balance by collateral amount.
        _incrementCollateralBalances(positionData, collateralAmount);

        // Add the number of tokens created to the position's outstanding tokens.
        positionData.tokensOutstanding = positionData.tokensOutstanding.add(numTokens);

        totalTokensOutstanding = totalTokensOutstanding.add(numTokens);

        emit PositionCreated(msg.sender, collateralAmount.rawValue, numTokens.rawValue);

        // Transfer tokens into the contract from caller and mint corresponding synthetic tokens to the caller's address.
        collateralCurrency.safeTransferFrom(msg.sender, address(this), collateralAmount.rawValue);

        // Note: revert reason removed to save bytecode.
        require(tokenCurrency.mint(msg.sender, numTokens.rawValue));
    }

    /**
     * @notice Burns `numTokens` of `tokenCurrency` and sends back the proportional amount of `collateralCurrency`.
     * @dev Can only be called by a token sponsor. Might not redeem the full proportional amount of collateral
     * in order to account for precision loss. This contract must be approved to spend at least `numTokens` of
     * `tokenCurrency`.
     * @dev This contract must have the Burner role for the `tokenCurrency`.
     * @param numTokens is the number of tokens to be burnt for a commensurate amount of collateral.
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function redeem(FixedPoint.Unsigned memory numTokens)
        public
        notEmergencyShutdown()
        noPendingWithdrawal(msg.sender)
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(numTokens.isLessThanOrEqual(positionData.tokensOutstanding));

        FixedPoint.Unsigned memory fractionRedeemed = numTokens.div(positionData.tokensOutstanding);
        FixedPoint.Unsigned memory collateralRedeemed =
            fractionRedeemed.mul(_getFeeAdjustedCollateral(positionData.rawCollateral));

        // If redemption returns all tokens the sponsor has then we can delete their position. Else, downsize.
        if (positionData.tokensOutstanding.isEqual(numTokens)) {
            amountWithdrawn = _deleteSponsorPosition(msg.sender);
        } else {
            // Decrement the sponsor's collateral and global collateral amounts.
            amountWithdrawn = _decrementCollateralBalances(positionData, collateralRedeemed);

            // Decrease the sponsors position tokens size. Ensure it is above the min sponsor size.
            FixedPoint.Unsigned memory newTokenCount = positionData.tokensOutstanding.sub(numTokens);
            require(newTokenCount.isGreaterThanOrEqual(minSponsorTokens));
            positionData.tokensOutstanding = newTokenCount;

            // Update the totalTokensOutstanding after redemption.
            totalTokensOutstanding = totalTokensOutstanding.sub(numTokens);
        }

        emit Redeem(msg.sender, amountWithdrawn.rawValue, numTokens.rawValue);

        // Transfer collateral from contract to caller and burn callers synthetic tokens.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
        tokenCurrency.safeTransferFrom(msg.sender, address(this), numTokens.rawValue);
        tokenCurrency.burn(numTokens.rawValue);
    }

    /**
     * @notice Burns `numTokens` of `tokenCurrency` to decrease sponsors position size, without sending back `collateralCurrency`.
     * This is done by a sponsor to increase position CR. Resulting size is bounded by minSponsorTokens.
     * @dev Can only be called by token sponsor. This contract must be approved to spend `numTokens` of `tokenCurrency`.
     * @dev This contract must have the Burner role for the `tokenCurrency`.
     * @param numTokens is the number of tokens to be burnt from the sponsor's debt position.
     */
    function repay(FixedPoint.Unsigned memory numTokens)
        public
        notEmergencyShutdown()
        noPendingWithdrawal(msg.sender)
        fees()
        nonReentrant()
    {
        PositionData storage positionData = _getPositionData(msg.sender);
        require(numTokens.isLessThanOrEqual(positionData.tokensOutstanding));

        // Decrease the sponsors position tokens size. Ensure it is above the min sponsor size.
        FixedPoint.Unsigned memory newTokenCount = positionData.tokensOutstanding.sub(numTokens);
        require(newTokenCount.isGreaterThanOrEqual(minSponsorTokens));
        positionData.tokensOutstanding = newTokenCount;

        // Update the totalTokensOutstanding after redemption.
        totalTokensOutstanding = totalTokensOutstanding.sub(numTokens);

        emit Repay(msg.sender, numTokens.rawValue, newTokenCount.rawValue);

        // Transfer the tokens back from the sponsor and burn them.
        tokenCurrency.safeTransferFrom(msg.sender, address(this), numTokens.rawValue);
        tokenCurrency.burn(numTokens.rawValue);
    }

    /**
     * @notice If the contract is emergency shutdown then all token holders and sponsors can redeem their tokens or
     * remaining collateral for underlying at the prevailing price defined by a DVM vote.
     * @dev This burns all tokens from the caller of `tokenCurrency` and sends back the resolved settlement value of
     * `collateralCurrency`. Might not redeem the full proportional amount of collateral in order to account for
     * precision loss. This contract must be approved to spend `tokenCurrency` at least up to the caller's full balance.
     * @dev This contract must have the Burner role for the `tokenCurrency`.
     * @dev Note that this function does not call the updateFundingRate modifier to update the funding rate as this
     * function is only called after an emergency shutdown & there should be no funding rate updates after the shutdown.
     * @return amountWithdrawn The actual amount of collateral withdrawn.
     */
    function settleEmergencyShutdown()
        external
        isEmergencyShutdown()
        fees()
        nonReentrant()
        returns (FixedPoint.Unsigned memory amountWithdrawn)
    {
        // Set the emergency shutdown price as resolved from the DVM. If DVM has not resolved will revert.
        if (emergencyShutdownPrice.isEqual(FixedPoint.fromUnscaledUint(0))) {
            emergencyShutdownPrice = _getOracleEmergencyShutdownPrice();
        }

        // Get caller's tokens balance and calculate amount of underlying entitled to them.
        FixedPoint.Unsigned memory tokensToRedeem = FixedPoint.Unsigned(tokenCurrency.balanceOf(msg.sender));
        FixedPoint.Unsigned memory totalRedeemableCollateral =
            _getFundingRateAppliedTokenDebt(tokensToRedeem).mul(emergencyShutdownPrice);

        // If the caller is a sponsor with outstanding collateral they are also entitled to their excess collateral after their debt.
        PositionData storage positionData = positions[msg.sender];
        if (_getFeeAdjustedCollateral(positionData.rawCollateral).isGreaterThan(0)) {
            // Calculate the underlying entitled to a token sponsor. This is collateral - debt in underlying with
            // the funding rate applied to the outstanding token debt.

            FixedPoint.Unsigned memory tokenDebtValueInCollateral =
                _getFundingRateAppliedTokenDebt(positionData.tokensOutstanding).mul(emergencyShutdownPrice);
            FixedPoint.Unsigned memory positionCollateral = _getFeeAdjustedCollateral(positionData.rawCollateral);

            // If the debt is greater than the remaining collateral, they cannot redeem anything.
            FixedPoint.Unsigned memory positionRedeemableCollateral =
                tokenDebtValueInCollateral.isLessThan(positionCollateral)
                    ? positionCollateral.sub(tokenDebtValueInCollateral)
                    : FixedPoint.Unsigned(0);

            // Add the number of redeemable tokens for the sponsor to their total redeemable collateral.
            totalRedeemableCollateral = totalRedeemableCollateral.add(positionRedeemableCollateral);

            // Reset the position state as all the value has been removed after settlement.
            delete positions[msg.sender];
            emit EndedSponsorPosition(msg.sender);
        }

        // Take the min of the remaining collateral and the collateral "owed". If the contract is undercapitalized,
        // the caller will get as much collateral as the contract can pay out.
        FixedPoint.Unsigned memory payout =
            FixedPoint.min(_getFeeAdjustedCollateral(rawTotalPositionCollateral), totalRedeemableCollateral);

        // Decrement total contract collateral and outstanding debt.
        amountWithdrawn = _removeCollateral(rawTotalPositionCollateral, payout);
        totalTokensOutstanding = totalTokensOutstanding.sub(tokensToRedeem);

        emit SettleEmergencyShutdown(msg.sender, amountWithdrawn.rawValue, tokensToRedeem.rawValue);

        // Transfer tokens & collateral and burn the redeemed tokens.
        collateralCurrency.safeTransfer(msg.sender, amountWithdrawn.rawValue);
        tokenCurrency.safeTransferFrom(msg.sender, address(this), tokensToRedeem.rawValue);
        tokenCurrency.burn(tokensToRedeem.rawValue);
    }

    /****************************************
     *        GLOBAL STATE FUNCTIONS        *
     ****************************************/

    /**
     * @notice Premature contract settlement under emergency circumstances.
     * @dev Only the governor can call this function as they are permissioned within the `FinancialContractAdmin`.
     * Upon emergency shutdown, the contract settlement time is set to the shutdown time. This enables withdrawal
     * to occur via the `settleEmergencyShutdown` function.
     */
    function emergencyShutdown() external override notEmergencyShutdown() fees() nonReentrant() {
        // Note: revert reason removed to save bytecode.
        require(msg.sender == _getFinancialContractsAdminAddress());

        emergencyShutdownTimestamp = getCurrentTime();
        _requestOraclePrice(emergencyShutdownTimestamp);

        emit EmergencyShutdown(msg.sender, emergencyShutdownTimestamp);
    }

    /**
     * @notice Theoretically supposed to pay fees and move money between margin accounts to make sure they
     * reflect the NAV of the contract. However, this functionality doesn't apply to this contract.
     * @dev This is supposed to be implemented by any contract that inherits `AdministrateeInterface` and callable
     * only by the Governor contract. This method is therefore minimally implemented in this contract and does nothing.
     */
    function remargin() external override {
        return;
    }

    /**
     * @notice Accessor method for a sponsor's collateral.
     * @dev This is necessary because the struct returned by the positions() method shows
     * rawCollateral, which isn't a user-readable value.
     * @dev TODO: This method does not account for any pending regular fees that have not yet been withdrawn
     * from this contract, for example if the `lastPaymentTime != currentTime`. Future work should be to add
     * logic to this method to account for any such pending fees.
     * @param sponsor address whose collateral amount is retrieved.
     * @return collateralAmount amount of collateral within a sponsors position.
     */
    function getCollateral(address sponsor)
        external
        view
        nonReentrantView()
        returns (FixedPoint.Unsigned memory collateralAmount)
    {
        // Note: do a direct access to avoid the validity check.
        return _getFeeAdjustedCollateral(positions[sponsor].rawCollateral);
    }

    /**
     * @notice Accessor method for the total collateral stored within the PerpetualPositionManager.
     * @return totalCollateral amount of all collateral within the position manager.
     */
    function totalPositionCollateral()
        external
        view
        nonReentrantView()
        returns (FixedPoint.Unsigned memory totalCollateral)
    {
        return _getFeeAdjustedCollateral(rawTotalPositionCollateral);
    }

    function getFundingRateAppliedTokenDebt(FixedPoint.Unsigned memory rawTokenDebt)
        external
        view
        nonReentrantView()
        returns (FixedPoint.Unsigned memory totalCollateral)
    {
        return _getFundingRateAppliedTokenDebt(rawTokenDebt);
    }

    /****************************************
     *          INTERNAL FUNCTIONS          *
     ****************************************/

    // Reduces a sponsor's position and global counters by the specified parameters. Handles deleting the entire
    // position if the entire position is being removed. Does not make any external transfers.
    function _reduceSponsorPosition(
        address sponsor,
        FixedPoint.Unsigned memory tokensToRemove,
        FixedPoint.Unsigned memory collateralToRemove,
        FixedPoint.Unsigned memory withdrawalAmountToRemove
    ) internal {
        PositionData storage positionData = _getPositionData(sponsor);

        // If the entire position is being removed, delete it instead.
        if (
            tokensToRemove.isEqual(positionData.tokensOutstanding) &&
            _getFeeAdjustedCollateral(positionData.rawCollateral).isEqual(collateralToRemove)
        ) {
            _deleteSponsorPosition(sponsor);
            return;
        }

        // Decrement the sponsor's collateral and global collateral amounts.
        _decrementCollateralBalances(positionData, collateralToRemove);

        // Ensure that the sponsor will meet the min position size after the reduction.
        positionData.tokensOutstanding = positionData.tokensOutstanding.sub(tokensToRemove);
        require(positionData.tokensOutstanding.isGreaterThanOrEqual(minSponsorTokens));

        // Decrement the position's withdrawal amount.
        positionData.withdrawalRequestAmount = positionData.withdrawalRequestAmount.sub(withdrawalAmountToRemove);

        // Decrement the total outstanding tokens in the overall contract.
        totalTokensOutstanding = totalTokensOutstanding.sub(tokensToRemove);
    }

    // Deletes a sponsor's position and updates global counters. Does not make any external transfers.
    function _deleteSponsorPosition(address sponsor) internal returns (FixedPoint.Unsigned memory) {
        PositionData storage positionToLiquidate = _getPositionData(sponsor);

        FixedPoint.Unsigned memory startingGlobalCollateral = _getFeeAdjustedCollateral(rawTotalPositionCollateral);

        // Remove the collateral and outstanding from the overall total position.
        rawTotalPositionCollateral = rawTotalPositionCollateral.sub(positionToLiquidate.rawCollateral);
        totalTokensOutstanding = totalTokensOutstanding.sub(positionToLiquidate.tokensOutstanding);

        // Reset the sponsors position to have zero outstanding and collateral.
        delete positions[sponsor];

        emit EndedSponsorPosition(sponsor);

        // Return fee-adjusted amount of collateral deleted from position.
        return startingGlobalCollateral.sub(_getFeeAdjustedCollateral(rawTotalPositionCollateral));
    }

    function _pfc() internal view virtual override returns (FixedPoint.Unsigned memory) {
        return _getFeeAdjustedCollateral(rawTotalPositionCollateral);
    }

    function _getPositionData(address sponsor)
        internal
        view
        onlyCollateralizedPosition(sponsor)
        returns (PositionData storage)
    {
        return positions[sponsor];
    }

    function _getIdentifierWhitelist() internal view returns (IdentifierWhitelistInterface) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }

    function _getOracle() internal view returns (OracleInterface) {
        return OracleInterface(finder.getImplementationAddress(OracleInterfaces.Oracle));
    }

    function _getFinancialContractsAdminAddress() internal view returns (address) {
        return finder.getImplementationAddress(OracleInterfaces.FinancialContractsAdmin);
    }

    // Requests a price for `priceIdentifier` at `requestedTime` from the Oracle.
    function _requestOraclePrice(uint256 requestedTime) internal {
        _getOracle().requestPrice(priceIdentifier, requestedTime);
    }

    // Fetches a resolved Oracle price from the Oracle. Reverts if the Oracle hasn't resolved for this request.
    function _getOraclePrice(uint256 requestedTime) internal view returns (FixedPoint.Unsigned memory price) {
        // Create an instance of the oracle and get the price. If the price is not resolved revert.
        int256 oraclePrice = _getOracle().getPrice(priceIdentifier, requestedTime);

        // For now we don't want to deal with negative prices in positions.
        if (oraclePrice < 0) {
            oraclePrice = 0;
        }
        return FixedPoint.Unsigned(uint256(oraclePrice));
    }

    // Fetches a resolved Oracle price from the Oracle. Reverts if the Oracle hasn't resolved for this request.
    function _getOracleEmergencyShutdownPrice() internal view returns (FixedPoint.Unsigned memory) {
        return _getOraclePrice(emergencyShutdownTimestamp);
    }

    // Reset withdrawal request by setting the withdrawal request and withdrawal timestamp to 0.
    function _resetWithdrawalRequest(PositionData storage positionData) internal {
        positionData.withdrawalRequestAmount = FixedPoint.fromUnscaledUint(0);
        positionData.withdrawalRequestPassTimestamp = 0;
    }

    // Ensure individual and global consistency when increasing collateral balances. Returns the change to the position.
    function _incrementCollateralBalances(
        PositionData storage positionData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _addCollateral(positionData.rawCollateral, collateralAmount);
        return _addCollateral(rawTotalPositionCollateral, collateralAmount);
    }

    // Ensure individual and global consistency when decrementing collateral balances. Returns the change to the
    // position. We elect to return the amount that the global collateral is decreased by, rather than the individual
    // position's collateral, because we need to maintain the invariant that the global collateral is always
    // <= the collateral owned by the contract to avoid reverts on withdrawals. The amount returned = amount withdrawn.
    function _decrementCollateralBalances(
        PositionData storage positionData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _removeCollateral(positionData.rawCollateral, collateralAmount);
        return _removeCollateral(rawTotalPositionCollateral, collateralAmount);
    }

    // Ensure individual and global consistency when decrementing collateral balances. Returns the change to the position.
    // This function is similar to the _decrementCollateralBalances function except this function checks position GCR
    // between the decrements. This ensures that collateral removal will not leave the position undercollateralized.
    function _decrementCollateralBalancesCheckGCR(
        PositionData storage positionData,
        FixedPoint.Unsigned memory collateralAmount
    ) internal returns (FixedPoint.Unsigned memory) {
        _removeCollateral(positionData.rawCollateral, collateralAmount);
        require(_checkPositionCollateralization(positionData), "CR below GCR");
        return _removeCollateral(rawTotalPositionCollateral, collateralAmount);
    }

    // These internal functions are supposed to act identically to modifiers, but re-used modifiers
    // unnecessarily increase contract bytecode size.
    // source: https://blog.polymath.network/solidity-tips-and-tricks-to-save-gas-and-reduce-bytecode-size-c44580b218e6
    function _onlyCollateralizedPosition(address sponsor) internal view {
        require(_getFeeAdjustedCollateral(positions[sponsor].rawCollateral).isGreaterThan(0));
    }

    // Note: This checks whether an already existing position has a pending withdrawal. This cannot be used on the
    // `create` method because it is possible that `create` is called on a new position (i.e. one without any collateral
    // or tokens outstanding) which would fail the `onlyCollateralizedPosition` modifier on `_getPositionData`.
    function _positionHasNoPendingWithdrawal(address sponsor) internal view {
        require(_getPositionData(sponsor).withdrawalRequestPassTimestamp == 0);
    }

    /****************************************
     *          PRIVATE FUNCTIONS          *
     ****************************************/

    function _checkPositionCollateralization(PositionData storage positionData) private view returns (bool) {
        return
            _checkCollateralization(
                _getFeeAdjustedCollateral(positionData.rawCollateral),
                positionData.tokensOutstanding
            );
    }

    // Checks whether the provided `collateral` and `numTokens` have a collateralization ratio above the global
    // collateralization ratio.
    function _checkCollateralization(FixedPoint.Unsigned memory collateral, FixedPoint.Unsigned memory numTokens)
        private
        view
        returns (bool)
    {
        FixedPoint.Unsigned memory global =
            _getCollateralizationRatio(_getFeeAdjustedCollateral(rawTotalPositionCollateral), totalTokensOutstanding);
        FixedPoint.Unsigned memory thisChange = _getCollateralizationRatio(collateral, numTokens);
        return !global.isGreaterThan(thisChange);
    }

    function _getCollateralizationRatio(FixedPoint.Unsigned memory collateral, FixedPoint.Unsigned memory numTokens)
        private
        pure
        returns (FixedPoint.Unsigned memory ratio)
    {
        return numTokens.isLessThanOrEqual(0) ? FixedPoint.fromUnscaledUint(0) : collateral.div(numTokens);
    }

    function _getTokenAddress() internal view override returns (address) {
        return address(tokenCurrency);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Stores common interface names used throughout the DVM by registration in the Finder.
 */
library OracleInterfaces {
    bytes32 public constant Oracle = "Oracle";
    bytes32 public constant IdentifierWhitelist = "IdentifierWhitelist";
    bytes32 public constant Store = "Store";
    bytes32 public constant FinancialContractsAdmin = "FinancialContractsAdmin";
    bytes32 public constant Registry = "Registry";
    bytes32 public constant CollateralWhitelist = "CollateralWhitelist";
    bytes32 public constant OptimisticOracle = "OptimisticOracle";
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../interfaces/FinderInterface.sol";
import "../../common/implementation/AddressWhitelist.sol";
import "./Registry.sol";
import "./Constants.sol";

/**
 * @title Base contract for all financial contract creators
 */
abstract contract ContractCreator {
    address internal finderAddress;

    constructor(address _finderAddress) public {
        finderAddress = _finderAddress;
    }

    function _requireWhitelistedCollateral(address collateralAddress) internal view {
        FinderInterface finder = FinderInterface(finderAddress);
        AddressWhitelist collateralWhitelist =
            AddressWhitelist(finder.getImplementationAddress(OracleInterfaces.CollateralWhitelist));
        require(collateralWhitelist.isOnWhitelist(collateralAddress), "Collateral not whitelisted");
    }

    function _registerContract(address[] memory parties, address contractToRegister) internal {
        FinderInterface finder = FinderInterface(finderAddress);
        Registry registry = Registry(finder.getImplementationAddress(OracleInterfaces.Registry));
        registry.registerContract(parties, contractToRegister);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/implementation/MultiRole.sol";
import "../interfaces/RegistryInterface.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Registry for financial contracts and approved financial contract creators.
 * @dev Maintains a whitelist of financial contract creators that are allowed
 * to register new financial contracts and stores party members of a financial contract.
 */
contract Registry is RegistryInterface, MultiRole {
    using SafeMath for uint256;

    /****************************************
     *    INTERNAL VARIABLES AND STORAGE    *
     ****************************************/

    enum Roles {
        Owner, // The owner manages the set of ContractCreators.
        ContractCreator // Can register financial contracts.
    }

    // This enum is required because a `WasValid` state is required
    // to ensure that financial contracts cannot be re-registered.
    enum Validity { Invalid, Valid }

    // Local information about a contract.
    struct FinancialContract {
        Validity valid;
        uint128 index;
    }

    struct Party {
        address[] contracts; // Each financial contract address is stored in this array.
        // The address of each financial contract is mapped to its index for constant time look up and deletion.
        mapping(address => uint256) contractIndex;
    }

    // Array of all contracts that are approved to use the UMA Oracle.
    address[] public registeredContracts;

    // Map of financial contract contracts to the associated FinancialContract struct.
    mapping(address => FinancialContract) public contractMap;

    // Map each party member to their their associated Party struct.
    mapping(address => Party) private partyMap;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event NewContractRegistered(address indexed contractAddress, address indexed creator, address[] parties);
    event PartyAdded(address indexed contractAddress, address indexed party);
    event PartyRemoved(address indexed contractAddress, address indexed party);

    /**
     * @notice Construct the Registry contract.
     */
    constructor() public {
        _createExclusiveRole(uint256(Roles.Owner), uint256(Roles.Owner), msg.sender);
        // Start with no contract creators registered.
        _createSharedRole(uint256(Roles.ContractCreator), uint256(Roles.Owner), new address[](0));
    }

    /****************************************
     *        REGISTRATION FUNCTIONS        *
     ****************************************/

    /**
     * @notice Registers a new financial contract.
     * @dev Only authorized contract creators can call this method.
     * @param parties array of addresses who become parties in the contract.
     * @param contractAddress address of the contract against which the parties are registered.
     */
    function registerContract(address[] calldata parties, address contractAddress)
        external
        override
        onlyRoleHolder(uint256(Roles.ContractCreator))
    {
        FinancialContract storage financialContract = contractMap[contractAddress];
        require(contractMap[contractAddress].valid == Validity.Invalid, "Can only register once");

        // Store contract address as a registered contract.
        registeredContracts.push(contractAddress);

        // No length check necessary because we should never hit (2^127 - 1) contracts.
        financialContract.index = uint128(registeredContracts.length.sub(1));

        // For all parties in the array add them to the contract's parties.
        financialContract.valid = Validity.Valid;
        for (uint256 i = 0; i < parties.length; i = i.add(1)) {
            _addPartyToContract(parties[i], contractAddress);
        }

        emit NewContractRegistered(contractAddress, msg.sender, parties);
    }

    /**
     * @notice Adds a party member to the calling contract.
     * @dev msg.sender will be used to determine the contract that this party is added to.
     * @param party new party for the calling contract.
     */
    function addPartyToContract(address party) external override {
        address contractAddress = msg.sender;
        require(contractMap[contractAddress].valid == Validity.Valid, "Can only add to valid contract");

        _addPartyToContract(party, contractAddress);
    }

    /**
     * @notice Removes a party member from the calling contract.
     * @dev msg.sender will be used to determine the contract that this party is removed from.
     * @param partyAddress address to be removed from the calling contract.
     */
    function removePartyFromContract(address partyAddress) external override {
        address contractAddress = msg.sender;
        Party storage party = partyMap[partyAddress];
        uint256 numberOfContracts = party.contracts.length;

        require(numberOfContracts != 0, "Party has no contracts");
        require(contractMap[contractAddress].valid == Validity.Valid, "Remove only from valid contract");
        require(isPartyMemberOfContract(partyAddress, contractAddress), "Can only remove existing party");

        // Index of the current location of the contract to remove.
        uint256 deleteIndex = party.contractIndex[contractAddress];

        // Store the last contract's address to update the lookup map.
        address lastContractAddress = party.contracts[numberOfContracts - 1];

        // Swap the contract to be removed with the last contract.
        party.contracts[deleteIndex] = lastContractAddress;

        // Update the lookup index with the new location.
        party.contractIndex[lastContractAddress] = deleteIndex;

        // Pop the last contract from the array and update the lookup map.
        party.contracts.pop();
        delete party.contractIndex[contractAddress];

        emit PartyRemoved(contractAddress, partyAddress);
    }

    /****************************************
     *         REGISTRY STATE GETTERS       *
     ****************************************/

    /**
     * @notice Returns whether the contract has been registered with the registry.
     * @dev If it is registered, it is an authorized participant in the UMA system.
     * @param contractAddress address of the financial contract.
     * @return bool indicates whether the contract is registered.
     */
    function isContractRegistered(address contractAddress) external view override returns (bool) {
        return contractMap[contractAddress].valid == Validity.Valid;
    }

    /**
     * @notice Returns a list of all contracts that are associated with a particular party.
     * @param party address of the party.
     * @return an array of the contracts the party is registered to.
     */
    function getRegisteredContracts(address party) external view override returns (address[] memory) {
        return partyMap[party].contracts;
    }

    /**
     * @notice Returns all registered contracts.
     * @return all registered contract addresses within the system.
     */
    function getAllRegisteredContracts() external view override returns (address[] memory) {
        return registeredContracts;
    }

    /**
     * @notice checks if an address is a party of a contract.
     * @param party party to check.
     * @param contractAddress address to check against the party.
     * @return bool indicating if the address is a party of the contract.
     */
    function isPartyMemberOfContract(address party, address contractAddress) public view override returns (bool) {
        uint256 index = partyMap[party].contractIndex[contractAddress];
        return partyMap[party].contracts.length > index && partyMap[party].contracts[index] == contractAddress;
    }

    /****************************************
     *           INTERNAL FUNCTIONS         *
     ****************************************/

    function _addPartyToContract(address party, address contractAddress) internal {
        require(!isPartyMemberOfContract(party, contractAddress), "Can only register a party once");
        uint256 contractIndex = partyMap[party].contracts.length;
        partyMap[party].contracts.push(contractAddress);
        partyMap[party].contractIndex[contractAddress] = contractIndex;

        emit PartyAdded(contractAddress, party);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/implementation/FixedPoint.sol";

/**
 * @title Interface that all financial contracts expose to the admin.
 */
interface AdministrateeInterface {
    /**
     * @notice Initiates the shutdown process, in case of an emergency.
     */
    function emergencyShutdown() external;

    /**
     * @notice A core contract method called independently or as a part of other financial contract transactions.
     * @dev It pays fees and moves money between margin accounts to make sure they reflect the NAV of the contract.
     */
    function remargin() external;

    /**
     * @notice Gets the current profit from corruption for this contract in terms of the collateral currency.
     * @dev This is equivalent to the collateral pool available from which to pay fees. Therefore, derived contracts are
     * expected to implement this so that pay-fee methods can correctly compute the owed fees as a % of PfC.
     * @return pfc value for equal to the current profit from corruption denominated in collateral currency.
     */
    function pfc() external view returns (FixedPoint.Unsigned memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

/**
 * @title Interface for whitelists of supported identifiers that the oracle can provide prices for.
 */
interface IdentifierWhitelistInterface {
    /**
     * @notice Adds the provided identifier as a supported identifier.
     * @dev Price requests using this identifier will succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function addSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Removes the identifier from the whitelist.
     * @dev Price requests using this identifier will no longer succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function removeSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Checks whether an identifier is on the whitelist.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     * @return bool if the identifier is supported (or not).
     */
    function isIdentifierSupported(bytes32 identifier) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OptimisticOracleInterface {
    // Struct representing the state of a price request.
    enum State {
        Invalid, // Never requested.
        Requested, // Requested, no other actions taken.
        Proposed, // Proposed, but not expired or disputed yet.
        Expired, // Proposed, not disputed, past liveness.
        Disputed, // Disputed, but no DVM price returned yet.
        Resolved, // Disputed and DVM price is available.
        Settled // Final price has been set in the contract (can get here from Expired or Resolved).
    }

    // Struct representing a price request.
    struct Request {
        address proposer; // Address of the proposer.
        address disputer; // Address of the disputer.
        IERC20 currency; // ERC20 token used to pay rewards and fees.
        bool settled; // True if the request is settled.
        bool refundOnDispute; // True if the requester should be refunded their reward on dispute.
        int256 proposedPrice; // Price that the proposer submitted.
        int256 resolvedPrice; // Price resolved once the request is settled.
        uint256 expirationTime; // Time at which the request auto-settles without a dispute.
        uint256 reward; // Amount of the currency to pay to the proposer on settlement.
        uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
        uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
        uint256 customLiveness; // Custom liveness value set by the requester.
    }

    // This value must be <= the Voting contract's `ancillaryBytesLimit` value otherwise it is possible
    // that a price can be requested to this contract successfully, but cannot be disputed because the DVM refuses
    // to accept a price request made with ancillary data length of a certain size.
    uint256 public constant ancillaryBytesLimit = 8192;

    /**
     * @notice Requests a new price.
     * @param identifier price identifier being requested.
     * @param timestamp timestamp of the price being requested.
     * @param ancillaryData ancillary data representing additional args being passed with the price request.
     * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
     * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
     *               which could make sense if the contract requests and proposes the value in the same call or
     *               provides its own reward system.
     * @return totalBond default bond (final fee) + final fee that the proposer and disputer will be required to pay.
     * This can be changed with a subsequent call to setBond().
     */
    function requestPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Set the proposal bond associated with a price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param bond custom bond amount to set.
     * @return totalBond new bond + final fee that the proposer and disputer will be required to pay. This can be
     * changed again with a subsequent call to setBond().
     */
    function setBond(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 bond
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Sets the request to refund the reward if the proposal is disputed. This can help to "hedge" the caller
     * in the event of a dispute-caused delay. Note: in the event of a dispute, the winner still receives the other's
     * bond, so there is still profit to be made even if the reward is refunded.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     */
    function setRefundOnDispute(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual;

    /**
     * @notice Sets a custom liveness value for the request. Liveness is the amount of time a proposal must wait before
     * being auto-resolved.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param customLiveness new custom liveness.
     */
    function setCustomLiveness(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 customLiveness
    ) external virtual;

    /**
     * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
     * from this proposal. However, any bonds are pulled from the caller.
     * @param proposer address to set as the proposer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePriceFor(
        address proposer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) public virtual returns (uint256 totalBond);

    /**
     * @notice Proposes a price value for an existing price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @param proposedPrice price being proposed.
     * @return totalBond the amount that's pulled from the proposer's wallet as a bond. The bond will be returned to
     * the proposer once settled if the proposal is correct.
     */
    function proposePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
     * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
     * @param disputer address to set as the disputer.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was value (the proposal was incorrect).
     */
    function disputePriceFor(
        address disputer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public virtual returns (uint256 totalBond);

    /**
     * @notice Disputes a price value for an existing price request with an active proposal.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return totalBond the amount that's pulled from the disputer's wallet as a bond. The bond will be returned to
     * the disputer once settled if the dispute was valid (the proposal was incorrect).
     */
    function disputePrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (uint256 totalBond);

    /**
     * @notice Retrieves a price that was previously requested by a caller. Reverts if the request is not settled
     * or settleable. Note: this method is not view so that this call may actually settle the price request if it
     * hasn't been settled.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return resolved price.
     */
    function getPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (int256);

    /**
     * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
     * the returned bonds as well as additional rewards.
     */
    function settle(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) external virtual returns (uint256 payout);

    /**
     * @notice Gets the current data structure containing all information about a price request.
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the Request data structure.
     */
    function getRequest(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (Request memory);

    function getState(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (State);

    /**
     * @notice Checks if a given request has resolved or been settled (i.e the optimistic oracle has a price).
     * @param requester sender of the initial price request.
     * @param identifier price identifier to identify the existing request.
     * @param timestamp timestamp to identify the existing request.
     * @param ancillaryData ancillary data of the price being requested.
     * @return the State.
     */
    function hasPrice(
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData
    ) public view virtual returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OracleInterface {
    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     */
    function requestPrice(bytes32 identifier, uint256 time) public virtual;

    /**
     * @notice Whether the price for `identifier` and `time` is available.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @return bool if the DVM has resolved to a price for the given identifier and timestamp.
     */
    function hasPrice(bytes32 identifier, uint256 time) public view virtual returns (bool);

    /**
     * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @return int256 representing the resolved price for the given identifier and timestamp.
     */
    function getPrice(bytes32 identifier, uint256 time) public view virtual returns (int256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

/**
 * @title Interface for a registry of contracts and contract creators.
 */
interface RegistryInterface {
    /**
     * @notice Registers a new contract.
     * @dev Only authorized contract creators can call this method.
     * @param parties an array of addresses who become parties in the contract.
     * @param contractAddress defines the address of the deployed contract.
     */
    function registerContract(address[] calldata parties, address contractAddress) external;

    /**
     * @notice Returns whether the contract has been registered with the registry.
     * @dev If it is registered, it is an authorized participant in the UMA system.
     * @param contractAddress address of the contract.
     * @return bool indicates whether the contract is registered.
     */
    function isContractRegistered(address contractAddress) external view returns (bool);

    /**
     * @notice Returns a list of all contracts that are associated with a particular party.
     * @param party address of the party.
     * @return an array of the contracts the party is registered to.
     */
    function getRegisteredContracts(address party) external view returns (address[] memory);

    /**
     * @notice Returns all registered contracts.
     * @return all registered contract addresses within the system.
     */
    function getAllRegisteredContracts() external view returns (address[] memory);

    /**
     * @notice Adds a party to the calling contract.
     * @dev msg.sender must be the contract to which the party member is added.
     * @param party address to be added to the contract.
     */
    function addPartyToContract(address party) external;

    /**
     * @notice Removes a party member to the calling contract.
     * @dev msg.sender must be the contract to which the party member is added.
     * @param party address to be removed from the contract.
     */
    function removePartyFromContract(address party) external;

    /**
     * @notice checks if an address is a party in a contract.
     * @param party party to check.
     * @param contractAddress address to check against the party.
     * @return bool indicating if the address is a party of the contract.
     */
    function isPartyMemberOfContract(address party, address contractAddress) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../common/implementation/FixedPoint.sol";

/**
 * @title Interface that allows financial contracts to pay oracle fees for their use of the system.
 */
interface StoreInterface {
    /**
     * @notice Pays Oracle fees in ETH to the store.
     * @dev To be used by contracts whose margin currency is ETH.
     */
    function payOracleFees() external payable;

    /**
     * @notice Pays oracle fees in the margin currency, erc20Address, to the store.
     * @dev To be used if the margin currency is an ERC20 token rather than ETH.
     * @param erc20Address address of the ERC20 token used to pay the fee.
     * @param amount number of tokens to transfer. An approval for at least this amount must exist.
     */
    function payOracleFeesErc20(address erc20Address, FixedPoint.Unsigned calldata amount) external;

    /**
     * @notice Computes the regular oracle fees that a contract should pay for a period.
     * @param startTime defines the beginning time from which the fee is paid.
     * @param endTime end time until which the fee is paid.
     * @param pfc "profit from corruption", or the maximum amount of margin currency that a
     * token sponsor could extract from the contract through corrupting the price feed in their favor.
     * @return regularFee amount owed for the duration from start to end time for the given pfc.
     * @return latePenalty for paying the fee after the deadline.
     */
    function computeRegularFee(
        uint256 startTime,
        uint256 endTime,
        FixedPoint.Unsigned calldata pfc
    ) external view returns (FixedPoint.Unsigned memory regularFee, FixedPoint.Unsigned memory latePenalty);

    /**
     * @notice Computes the final oracle fees that a contract should pay at settlement.
     * @param currency token used to pay the final fee.
     * @return finalFee amount due.
     */
    function computeFinalFee(address currency) external view returns (FixedPoint.Unsigned memory);
}

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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.6.0;


/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}