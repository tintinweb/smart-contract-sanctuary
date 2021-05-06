// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/Bank/IComptroller.sol";
import "../interfaces/Bank/IVaultLibrary.sol";
import "../interfaces/Bank/IRegistry.sol";
import "../interfaces/Bank/ITreasury.sol";
import "../interfaces/Bank/IfxToken.sol";
import "../interfaces/IValidator.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/Bank/IOracle.sol";

// Comment this out for production, it's a debug tool
// import "hardhat/console.sol";

contract Comptroller is
    IComptroller,
    IRegistry,
    IValidator,
    Ownable,
    ReentrancyGuard
{
    using SafeMath for uint256;

    // Registry state variables
    address public mintRewardToken;
    address public poolRewardToken;
    address payable public override treasury;
    address public override vaultLibrary;
    address public immutable override WETH;

    // Comptroller state variables
    address[] public collateralTokens;
    mapping(address => bool) public isCollateralValid;
    mapping(address => CollateralData) public collateralDetails;
    address[] public validFxTokens;
    mapping(address => bool) public override isFxTokenValid;
    mapping(address => TokenData) public tokenDetails;

    // Oracles
    // fxAsset => oracle address
    mapping(address => address) public oracles;

    constructor(
        address _mintRewardToken,
        address _poolRewardToken,
        address _weth
    ) {
        mintRewardToken = _mintRewardToken;
        poolRewardToken = _poolRewardToken;
        WETH = _weth;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // Modifiers
    modifier validFxToken(address token) {
        require(isFxTokenValid[token], "IF");
        _;
    }

    /**
     * @notice allows a user to deposit ETH and mint fxTokens in a single transaction
     * @param tokenAmount the amount of fxTokens the user wants
     * @param token the token to mint
     * @param deadline the time on which the transaction is invalid.
     */
    function mintWithEth(
        uint256 tokenAmount,
        address token,
        uint256 deadline
    )
        external
        payable
        override
        dueBy(deadline)
        validFxToken(token)
        nonReentrant
    {
        require(isCollateralValid[WETH], "WE");

        // Update interest.
        Treasury().updateVaultInterest(msg.sender, token);

        // Calculate fee with current amount and increase token amount to include fee.
        uint256 feeTokens =
            tokenAmount.mul(Treasury().mintFeePerMille()).div(1000);
        tokenAmount = tokenAmount.add(feeTokens);

        // Check the vault ratio is correct (fxToken <-> WETH)
        uint256 quote = getTokenPrice(token);
        require(
            VaultLibrary().getFreeCollateralAsEth(msg.sender, token).add(
                msg.value
            ) >=
                VaultLibrary().getMinimumCollateral(
                    tokenAmount,
                    collateralDetails[WETH].mintCR,
                    quote
                ),
            "CR"
        );

        // Mint tokens and fee
        uint256 balanceBefore = IfxToken(token).balanceOf(msg.sender);
        IfxToken(token).mint(msg.sender, tokenAmount.sub(feeTokens));
        IfxToken(token).mint(Treasury().FeeRecipient(), feeTokens);
        assert(
            IfxToken(token).balanceOf(msg.sender) ==
                balanceBefore.add(tokenAmount).sub(feeTokens)
        );

        // Update debt position
        uint256 debtPosition = Treasury().getDebt(msg.sender, token);
        Treasury().updateDebtPosition(msg.sender, tokenAmount, token, true);
        assert(
            debtPosition.add(tokenAmount) ==
                Treasury().getDebt(msg.sender, token)
        );

        // Convert to wETH
        IWETH(WETH).deposit{value: msg.value}();
        assert(IERC20(WETH).approve(treasury, msg.value));

        // Deposit in the treasury
        balanceBefore = Treasury().getCollateralBalance(
            msg.sender,
            WETH,
            token
        );
        Treasury().depositCollateral(msg.sender, msg.value, WETH, token);
        assert(
            Treasury().getCollateralBalance(msg.sender, WETH, token) ==
                msg.value.add(balanceBefore)
        );

        emit MintToken(quote, tokenAmount.sub(feeTokens), token);
    }

    // Mint with ERC20 as collateral
    function mint(
        uint256 tokenAmountDesired,
        address token,
        address collateralToken,
        address to,
        uint256 deadline
    ) external override dueBy(deadline) nonReentrant {
        require(isCollateralValid[collateralToken], "IC");

        // Update interest.
        Treasury().updateVaultInterest(msg.sender, token);
    }

    /**
     * @notice allows an user to mint fxTokens with existing collateral
     * @param tokenAmount the amount of fxTokens the user wants
     * @param token the token to mint
     * @param deadline the time on which the transaction is invalid.
     */
    function mintWithoutCollateral(
        uint256 tokenAmount,
        address token,
        uint256 deadline
    ) external override dueBy(deadline) validFxToken(token) {
        // Update interest.
        Treasury().updateVaultInterest(msg.sender, token);

        // Calculate fee with current amount and increase token amount to include fee.
        uint256 feeTokens =
            tokenAmount.mul(Treasury().mintFeePerMille()).div(1000);
        tokenAmount = tokenAmount.add(feeTokens);

        // Check the vault ratio is correct (fxToken <-> collateral)
        uint256 quote = getTokenPrice(token);
        require(
            VaultLibrary().getFreeCollateralAsEth(msg.sender, token) >=
                VaultLibrary().getMinimumCollateral(
                    tokenAmount,
                    collateralDetails[WETH].mintCR,
                    quote
                ),
            "CR"
        );

        // Mint tokens and fee
        uint256 balanceBefore = IfxToken(token).balanceOf(msg.sender);
        IfxToken(token).mint(msg.sender, tokenAmount.sub(feeTokens));
        IfxToken(token).mint(Treasury().FeeRecipient(), feeTokens);
        assert(
            IfxToken(token).balanceOf(msg.sender) ==
                balanceBefore.add(tokenAmount).sub(feeTokens)
        );

        // Update debt position
        uint256 debtPosition = Treasury().getDebt(msg.sender, token);
        Treasury().updateDebtPosition(msg.sender, tokenAmount, token, true);
        assert(
            debtPosition.add(tokenAmount) ==
                Treasury().getDebt(msg.sender, token)
        );

        emit MintToken(quote, tokenAmount, token);
    }

    /**
     * @notice allows an user to burn fxTokens
     * @param amount the amount of fxTokens to burn
     * @param token the token to burn
     * @param deadline the time on which the transaction is invalid.
     */
    function burn(
        uint256 amount,
        address token,
        uint256 deadline
    ) external override dueBy(deadline) validFxToken(token) {
        // Token balance must be higher or equal than burn amount.
        require(IfxToken(token).balanceOf(msg.sender) >= amount, "IA");
        // Treasury debt must be higher or equal to burn amount.
        require(Treasury().getDebt(msg.sender, token) >= amount, "IA");
        // Update vault interest before burning.
        Treasury().updateVaultInterest(msg.sender, token);

        // Withdraw fee.
        uint256 fee = calculateBurnFee(amount, token);
        Treasury().forceWithdrawCollateral(
            msg.sender,
            WETH,
            Treasury().FeeRecipient(),
            fee,
            token
        );

        // Burn tokens
        uint256 balanceBefore = IfxToken(token).balanceOf(msg.sender);
        IfxToken(token).burn(msg.sender, amount);
        assert(
            IfxToken(token).balanceOf(msg.sender) == balanceBefore.sub(amount)
        );

        // Update debt position
        uint256 debtPositionBefore = Treasury().getDebt(msg.sender, token);
        Treasury().updateDebtPosition(msg.sender, amount, token, false);
        assert(
            Treasury().getDebt(msg.sender, token) ==
                debtPositionBefore.sub(amount)
        );

        emit BurnToken(amount, token);
    }

    /**
     * @notice buy collateral from a vault at a 1:1 asset/collateral ratio
     * @dev token must have been pre-approved for transfer with input amount
     * @param amount the amount of fxTokens to redeem with
     * @param token the fxToken to buy collateral with
     * @param from the account to purchase from
     * @param deadline the deadline for the transaction
     */
    function buyCollateral(
        uint256 amount,
        address token,
        address from,
        uint256 deadline
    )
        external
        override
        dueBy(deadline)
        validFxToken(token)
        returns (
            uint256[] memory collateralAmounts,
            address[] memory collateralTypes
        )
    {
        {
            // Sender must have enough balance.
            require(IfxToken(token).balanceOf(msg.sender) >= amount, "IA");
            // Update vault interest.
            Treasury().updateVaultInterest(from, token);
            uint256 allowedAmount =
                VaultLibrary().getAllowedBuyCollateralFromTokenAmount(
                    amount,
                    token,
                    from
                );
            require(allowedAmount > 0, "IA");
            if (amount > allowedAmount) amount = allowedAmount;
            // Vault must have a debt >= amount.
            require(Treasury().getDebt(from, token) >= amount, "IA");
        }
        // Vault must have enough collateral.
        uint256 amountEth = getTokenPrice(token).mul(amount).div(1 ether);
        bool metAmount = false;
        (collateralTypes, collateralAmounts, metAmount) = VaultLibrary()
            .getCollateralForAmount(from, token, amountEth);
        require(metAmount, "CA");
        // Burn token.
        IfxToken(token).burn(msg.sender, amount);
        // Reduce vault debt and withdraw collateral to user.
        Treasury().updateDebtPosition(from, amount, token, false);
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            Treasury().forceWithdrawCollateral(
                from,
                collateralTokens[i],
                msg.sender,
                collateralAmounts[i],
                token
            );
        }
        emit Redeem(from, token, amount, collateralAmounts, collateralTypes);
    }

    /**
     * @notice calculates burn fee and requires sender to have enough free collateral to cover fee amount after burning
     * @param tokenAmount the amount of fxTokens being burned
     * @param token the token to burn
     */
    function calculateBurnFee(uint256 tokenAmount, address token)
        private
        view
        returns (uint256 feePrice)
    {
        uint256 unitPrice = getTokenPrice(token);
        // Fee price in ETH from Treasury
        uint256 feePerMille = Treasury().burnFeePerMille();
        feePrice = tokenAmount.mul(feePerMille).div(1000).mul(unitPrice).div(
            1 ether
        );
        uint256 available =
            VaultLibrary().getFreeCollateralAsEth(msg.sender, token).add(
                unitPrice
                    .mul(tokenAmount)
                    .mul(VaultLibrary().getMinimumRatio(msg.sender, token))
                    .div(1 ether)
                    .div(100)
            );
    }

    function setFxToken(
        address token,
        uint256 _liquidateCR,
        uint256 rewardRatio
    ) public override onlyOwner {
        if (!isFxTokenValid[token]) {
            validFxTokens.push(token);
            isFxTokenValid[token] = true;
        }
        tokenDetails[token] = TokenData({
            rewardRatio: rewardRatio,
            liquidateCR: _liquidateCR
        });
    }

    function removeFxToken(address token)
        external
        override
        onlyOwner
        validFxToken(token)
    {
        uint256 tokenIndex = validFxTokens.length + 1;
        for (uint256 i = 0; i < validFxTokens.length; i++) {
            if (validFxTokens[i] == token) {
                tokenIndex = i;
                break;
            }
        }
        delete tokenDetails[token];
        delete isFxTokenValid[token];
        if (tokenIndex < validFxTokens.length - 1) {
            delete validFxTokens[tokenIndex];
            validFxTokens[tokenIndex] = validFxTokens[validFxTokens.length - 1];
            validFxTokens.pop();
        } else {
            delete validFxTokens[tokenIndex];
        }
    }

    function setCollateralToken(
        address _token,
        uint256 _mintCR,
        uint256 _liquidationRank,
        uint256 _stabilityFee,
        uint256 _liquidationFee
    ) public override onlyOwner {
        if (!isCollateralValid[_token]) {
            collateralTokens.push(_token);
            isCollateralValid[_token] = true;
        }
        collateralDetails[_token] = CollateralData({
            mintCR: _mintCR,
            liquidationRank: _liquidationRank,
            stabilityFee: _stabilityFee,
            liquidationFee: _liquidationFee
        });
    }

    function removeCollateralToken(address token) external override onlyOwner {
        // Cannot remove a token, as this would orphan user collateral. Mark it invalid instead.
        delete isCollateralValid[token];
    }

    function setContracts(address _treasury, address _vaultLibrary)
        external
        override
        onlyOwner
    {
        require(_treasury != address(0), "IZ");
        require(_vaultLibrary != address(0), "IZ");
        treasury = payable(_treasury);
        vaultLibrary = _vaultLibrary;
    }

    function setMintToken(address token) external override onlyOwner {
        mintRewardToken = token;
    }

    /**
     * @notice Returns the amount of ETH required to purchase 1 unit of token
     * @param token the fxToken to get the price of
     * @return quote The price of 1 token in ETH
     */
    function getTokenPrice(address token)
        public
        view
        override
        returns (uint256 quote)
    {
        if (token == WETH) return 1 ether;
        if (oracles[token] == address(0)) return 1 ether;

        quote = IOracle(oracles[token]).getRate(token);
    }

    function getAllCollateralTypes()
        external
        view
        override
        returns (address[] memory collateral)
    {
        collateral = collateralTokens;
    }

    /**
     * @notice Returns the entire array of valid fxTokens
     * @return tokens the valid tokens
     */
    function getAllFxTokens()
        external
        view
        override
        returns (address[] memory tokens)
    {
        tokens = validFxTokens;
    }

    function getCollateralDetails(address collateral)
        external
        view
        override
        returns (CollateralData memory)
    {
        return collateralDetails[collateral];
    }

    function getTokenDetails(address token)
        external
        view
        override
        returns (TokenData memory)
    {
        return tokenDetails[token];
    }

    /**
     * @notice sets an oracle for a given fxToken
     * @param _fxToken the fxToken to set the oracle for
     * @param _oracle the oracle to use for the fxToken
     */
    function setOracle(address _fxToken, address _oracle)
        external
        override
        onlyOwner
    {
        require(_fxToken != address(0), "IZ");
        require(_oracle != address(0), "IZ");
        oracles[_fxToken] = _oracle;
    }

    function VaultLibrary() private view returns (IVaultLibrary) {
        return IVaultLibrary(vaultLibrary);
    }

    function Treasury() private view returns (ITreasury) {
        return ITreasury(treasury);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IComptroller {
    // Structs
    struct TokenData {
        uint256 liquidateCR;
        uint256 rewardRatio;
    }
    struct CollateralData {
        uint256 mintCR;
        uint256 liquidationRank;
        uint256 stabilityFee;
        uint256 liquidationFee;
    }
    // Events
    event MintToken(
        uint256 tokenRate,
        uint256 amountMinted,
        address indexed token
    );
    event BurnToken(uint256 amountBurned, address indexed token);
    event Redeem(
        address from,
        address token,
        uint256 tokenAmount,
        uint256[] collateralAmounts,
        address[] collateralTypes
    );

    // Mint with ETH as collateral
    function mintWithEth(
        uint256 tokenAmountDesired,
        address fxToken,
        uint256 deadline
    ) external payable;

    // Mint with ERC20 as collateral
    function mint(
        uint256 amountDesired,
        address fxToken,
        address collateralToken,
        address to,
        uint256 deadline
    ) external;

    function mintWithoutCollateral(
        uint256 tokenAmountDesired,
        address token,
        uint256 deadline
    ) external;

    // Burn to withdraw collateral
    function burn(
        uint256 amount,
        address token,
        uint256 deadline
    ) external;

    // Buy collateral with fxTokens
    function buyCollateral(
        uint256 amount,
        address token,
        address from,
        uint256 deadline
    )
        external
        returns (
            uint256[] memory collateralAmounts,
            address[] memory collateralTypes
        );

    // Add/Update/Remove a token
    function setFxToken(
        address token,
        uint256 _liquidateCR,
        uint256 rewardRatio
    ) external;

    // Update tokens
    function removeFxToken(address token) external;

    function setCollateralToken(
        address _token,
        uint256 _mintCR,
        uint256 _liquidationRank,
        uint256 _stabilityFee,
        uint256 _liquidationFee
    ) external;

    function removeCollateralToken(address token) external;

    // Getters
    function getTokenPrice(address token) external view returns (uint256 quote);

    function getAllCollateralTypes()
        external
        view
        returns (address[] memory collateral);

    function getAllFxTokens() external view returns (address[] memory tokens);

    function getCollateralDetails(address collateral)
        external
        view
        returns (CollateralData memory);

    function getTokenDetails(address token)
        external
        view
        returns (TokenData memory);

    function WETH() external view returns (address);

    function treasury() external view returns (address payable);

    function vaultLibrary() external view returns (address);

    function setOracle(address fxToken, address oracle) external;

    function isFxTokenValid(address fxToken) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IVaultLibrary {
    enum CollateralRatioType {Minting, Redeem, Liquidation}

    function setContracts(address comptroller, address treasury) external;

    function doesMeetRatio(
        address account,
        address fxToken,
        CollateralRatioType crt
    ) external view returns (bool);

    function getCollateralRequiredAsEth(
        uint256 assetAmount,
        address fxToken,
        CollateralRatioType crt
    ) external view returns (uint256);

    function getFreeCollateralAsEth(address account, address fxToken)
        external
        view
        returns (uint256);

    function getMinimumRatio(address account, address fxToken)
        external
        view
        returns (uint256 ratio);

    function getMinimumCollateral(
        uint256 tokenAmount,
        uint256 ratio,
        uint256 unitPrice
    ) external view returns (uint256 minimum);

    function getDebtAsEth(address account, address fxToken)
        external
        view
        returns (uint256 debt);

    function getTotalCollateralBalanceAsEth(address account, address fxToken)
        external
        view
        returns (uint256 balance);

    function getCurrentRatio(address account, address fxToken)
        external
        view
        returns (uint256 ratio);

    function getCollateralForAmount(
        address account,
        address fxToken,
        uint256 amountEth
    )
        external
        view
        returns (
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts,
            bool metAmount
        );

    function calculateInterest(address user, address fxToken)
        external
        view
        returns (uint256 interest);

    function getInterestRate(address user, address fxToken)
        external
        view
        returns (uint256);

    function getLiquidationFee(address account, address fxToken)
        external
        view
        returns (uint256 fee);

    function getCollateralShares(address account, address fxToken)
        external
        view
        returns (uint256[] memory shares);

    function tokensRequiredForCrIncrease(
        uint256 crTarget,
        uint256 debt,
        uint256 collateral
    ) external pure returns (uint256 amount);

    function getCollateralTypesSortedByLiquidationRank()
        external
        view
        returns (address[] memory sortedCollateralTypes);

    function getAllowedBuyCollateralFromTokenAmount(
        uint256 amount,
        address token,
        address from
    ) external view returns (uint256 allowedAmount);

    function quickSort(
        uint256[] memory array,
        int256 left,
        int256 right
    ) external pure;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IRegistry {
    function setContracts(address treasury, address vaultLibrary) external;

    function setMintToken(address token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ITreasury {
    // Structs
    struct Vault {
        uint256 debt;
        // Collateral token address => balance
        mapping(address => uint256) collateralBalance;
        uint256 issuanceDelta; // Used for charging interest
    }
    // Events
    event UpdateDebt(address indexed account, address indexed fxToken);
    event UpdateCollateral(
        address indexed account,
        address indexed fxToken,
        address indexed collateralToken
    );

    // State changing functions
    function updateDebtPosition(
        address account,
        uint256 amount,
        address fxToken,
        bool increase
    ) external;

    function depositCollateral(
        address account,
        uint256 depositAmount,
        address collateralType,
        address fxToken
    ) external;

    function depositCollateralETH(address account, address fxToken)
        external
        payable;

    function withdrawCollateral(
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function withdrawCollateralETH(
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function withdrawCollateralFrom(
        address from,
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function forceWithdrawCollateral(
        address from,
        address collateralToken,
        address to,
        uint256 amount,
        address fxToken
    ) external;

    function withdrawAnyCollateral(
        address from,
        address to,
        uint256 amount,
        address fxToken
    )
        external
        returns (
            address[] memory collateralTypes,
            uint256[] memory collateralAmounts
        );

    function updateVaultInterest(address user, address fxToken) external;

    // Variable setters
    function setContracts(address comptroller, address vaultLibrary) external;

    function setRewardToken(address token, bytes32 which) external;

    function setCollateralInterestRate(address collateral, uint256 ratePerMille)
        external;

    function setFeeRecipient(address feeRecipient) external;

    function setFees(
        uint256 withdrawFeePerMille,
        uint256 mintFeePerMille,
        uint256 burnFeePerMille
    ) external;

    // Getters
    function getCollateralBalance(
        address account,
        address collateralType,
        address fxToken
    ) external view returns (uint256 balance);

    function getBalance(address account, address fxToken)
        external
        view
        returns (address[] memory collateral, uint256[] memory balances);

    function getDebt(address owner, address fxToken)
        external
        view
        returns (uint256 _debt);

    function interestRate(address collateral)
        external
        view
        returns (uint256 rate);

    function getInterestLastUpdateDate(address account, address fxToken)
        external
        view
        returns (uint256 date);

    function FeeRecipient() external view returns (address);

    function mintFeePerMille() external view returns (uint256);

    function burnFeePerMille() external view returns (uint256);

    function withdrawFeePerMille() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IfxToken is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

interface IValidator {
    modifier dueBy(uint256 date) {
        require(block.timestamp <= date, "Transaction has exceeded deadline");
        _;
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid Address");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <=0.7.6;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IOracle {
    /**
     * @notice Returns the price of 1 fxAsset in ETH
     * @param fxAsset the asset to get a rate for
     * @return unitPrice the cost of a single fxAsset in ETH
     */
    function getRate(address fxAsset) external view returns (uint256 unitPrice);

    /**
     * @notice A setter function to add or update an oracle for a given fx asset.
     * @param fxAsset the asset to update
     * @param oracle the oracle to set for the fxAsset
     */
    function setOracle(address fxAsset, address oracle) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}