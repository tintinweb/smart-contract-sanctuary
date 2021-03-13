// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

/**
 * @title Factory for deploying option contracts.
 * @author Primitive
 */

import { Option, SafeMath } from "../../primitives/Option.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OptionTemplateLib } from "../../libraries/OptionTemplateLib.sol";
import { NullCloneConstructor } from "../NullCloneConstructor.sol";
import { CloneLib } from "../../libraries/CloneLib.sol";
import { IOptionFactory } from "../../interfaces/IOptionFactory.sol";

contract OptionFactory is IOptionFactory, Ownable, NullCloneConstructor {
    using SafeMath for uint256;

    address public override optionTemplate;

    constructor(address registry) public {
        transferOwnership(registry);
    }

    /**
     * @dev Deploys the bytecode for the Option contract.
     */
    function deployOptionTemplate() public override {
        optionTemplate = OptionTemplateLib.deployTemplate();
    }

    /**
     * @dev Deploys a create2 clone of the option template contract.
     * @param underlyingToken The address of the underlying ERC-20 token.
     * @param strikeToken The address of the strike ERC-20 token.
     * @param base The quantity of underlying tokens per unit of quote amount of strike tokens.
     * @param quote The quantity of strike tokens per unit of base amount of underlying tokens.
     * @param expiry The unix timestamp for option expiry.
     */
    function deployClone(
        address underlyingToken,
        address strikeToken,
        uint256 base,
        uint256 quote,
        uint256 expiry
    ) external override onlyOwner returns (address) {
        require(optionTemplate != address(0x0), "ERR_NO_DEPLOYED_TEMPLATE");

        // Calculates the salt for create2.
        bytes32 salt = keccak256(
            abi.encodePacked(
                OptionTemplateLib.OPTION_SALT(),
                underlyingToken,
                strikeToken,
                base,
                quote,
                expiry
            )
        );

        // Deploys the clone using the template contract and calculated salt.
        address optionAddress = CloneLib.create2Clone(
            optionTemplate,
            uint256(salt)
        );

        // Sets the initial state of the option with the parameter arguments.
        Option(optionAddress).initialize(
            underlyingToken,
            strikeToken,
            base,
            quote,
            expiry
        );

        return optionAddress;
    }

    /**
     * @dev Only the factory can call the initRedeemToken function to set the redeem token address.
     * This function is only callable by the Registry contract (the owner).
     */
    function initRedeemToken(address optionAddress, address redeemAddress)
        external
        override
        onlyOwner
    {
        Option(optionAddress).initRedeemToken(redeemAddress);
    }

    /**
     * @dev Calculates the option token's address using the five option parameters.
     * @return The address of the option with the parameter arguments.
     */
    function calculateOptionAddress(
        address underlyingToken,
        address strikeToken,
        uint256 base,
        uint256 quote,
        uint256 expiry
    ) external override view returns (address) {
        // Calculates the salt using the parameter arguments and the salt used in the template contract
        // create2 deployment.
        bytes32 salt = keccak256(
            abi.encodePacked(
                OptionTemplateLib.OPTION_SALT(),
                underlyingToken,
                strikeToken,
                base,
                quote,
                expiry
            )
        );
        address optionAddress = CloneLib.deriveInstanceAddress(
            optionTemplate,
            salt
        );
        return optionAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

/**
 * @title   Vanilla Option Token
 * @notice  This is a low-level contract that is designed to be interacted with by
 *          other sophisticated smart contracts which have important safety checks,
 *          and not by externally owned accounts.
 *          Incorrect usage through direct interaction from externally owned accounts
 *          can lead to the loss of funds.
 *          Use Primitive's Trader.sol contract to interact with this contract safely.
 * @author  Primitive
 */

import { IOption } from "../interfaces/IOption.sol";
import { IRedeem } from "../interfaces/IRedeem.sol";
import { IFlash } from "../interfaces/IFlash.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20 } from "./ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract Option is IOption, ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct OptionParameters {
        address underlyingToken;
        address strikeToken;
        uint256 base;
        uint256 quote;
        uint256 expiry;
    }

    OptionParameters public optionParameters;

    // solhint-disable-next-line const-name-snakecase
    uint256 public override underlyingCache;
    uint256 public override strikeCache;
    address public override redeemToken;
    address public override factory;
    bool private _notEntered;

    string public constant name = "Primitive V1 Option";
    string public constant symbol = "PRM";
    uint8 public constant decimals = 18;

    event Mint(address indexed from, uint256 outOptions, uint256 outRedeems);
    event Exercise(
        address indexed from,
        uint256 outUnderlyings,
        uint256 inStrikes
    );
    event Redeem(address indexed from, uint256 inRedeems);
    event Close(address indexed from, uint256 outUnderlyings);
    event UpdatedCacheBalances(uint256 underlyingCache, uint256 strikeCache);
    event InitializedRedeem(
        address indexed caller,
        address indexed redeemToken
    );

    // solhint-disable-next-line no-empty-blocks
    constructor() public {}

    /**
     * @dev Sets the intial state for the contract. Only called immediately after deployment.
     * @param underlyingToken The address of the underlying asset.
     * @param strikeToken The address of the strike asset.
     * @param base The quantity of underlying tokens per quote amount of strike tokens.
     * @param quote The quantity of strike tokens per base amount of underlying tokens.
     * @param expiry The expiration date for the option.
     */
    function initialize(
        address underlyingToken,
        address strikeToken,
        uint256 base,
        uint256 quote,
        uint256 expiry
    ) public {
        require(factory == address(0x0), "ERR_IS_INITIALIZED");
        require(underlyingToken != strikeToken, "ERR_SAME_ASSETS");
        require(base > 0, "ERR_BASE_ZERO");
        require(quote > 0, "ERR_QUOTE_ZERO");
        require(expiry >= block.timestamp, "ERR_EXPIRY");
        factory = msg.sender;
        optionParameters = OptionParameters(
            underlyingToken,
            strikeToken,
            base,
            quote,
            expiry
        );
        _notEntered = true;
    }

    modifier notExpired {
        // solhint-disable-next-line not-rely-on-time
        require(isNotExpired(), "ERR_EXPIRED");
        _;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    /**
     * @dev Called after the option contract is initialized, and a redeem token has been deployed.
     * @notice Entangles a redeem token to this option contract permanently.
     * @param redeemToken_ The address of the redeem token.
     */
    function initRedeemToken(address redeemToken_) external override {
        require(msg.sender == factory, "ERR_NOT_OWNER");
        require(redeemToken == address(0x0), "ERR_REDEEM_INITIALIZED");
        redeemToken = redeemToken_;
        emit InitializedRedeem(msg.sender, redeemToken_);
    }

    /**
     * @dev Updates the cached balances to match the actual current balances.
     * Attempting to transfer tokens to this contract directly, in a separate transaction,
     * is incorrect and could result in loss of funds. Calling this function will permanently lock any excess
     * underlying or strike tokens which were erroneously sent to this contract.
     */
    function updateCacheBalances() external override nonReentrant {
        _updateCacheBalances(
            IERC20(optionParameters.underlyingToken).balanceOf(address(this)),
            IERC20(optionParameters.strikeToken).balanceOf(address(this))
        );
    }

    /**
     * @dev Sets the cache balances to new values.
     */
    function _updateCacheBalances(
        uint256 underlyingBalance,
        uint256 strikeBalance
    ) private {
        underlyingCache = underlyingBalance;
        strikeCache = strikeBalance;
        emit UpdatedCacheBalances(underlyingBalance, strikeBalance);
    }

    /* === STATE MUTABLE === */

    /**
     * @dev Warning: This low-level function should be called from a contract which performs important safety checks.
     * This function should never be called directly by an externally owned account.
     * A sophsticated smart contract should make the important checks to make sure the correct amount of tokens
     * are transferred into this contract prior to the function call. If an incorrect amount of tokens are transferred
     * into this contract, and this function is called, it can result in the loss of funds.
     * Mints optionTokens at a 1:1 ratio to underlyingToken deposits. Also mints Redeem tokens at a base:quote ratio.
     * @notice inUnderlyings = outOptionTokens. inUnderlying / strike ratio = outRedeemTokens.
     * @param receiver The newly minted tokens are sent to the receiver address.
     */
    function mintOptions(address receiver)
        external
        override
        nonReentrant
        notExpired
        returns (uint256, uint256)
    {
        // Save on gas because this variable is used twice.
        uint256 underlyingBalance = IERC20(optionParameters.underlyingToken)
            .balanceOf(address(this));

        // Mint optionTokens equal to the difference between current and cached balance of underlyingTokens.
        uint256 inUnderlyings = underlyingBalance.sub(underlyingCache);

        // Calculate the quantity of redeemTokens to mint.
        uint256 outRedeems = inUnderlyings.mul(optionParameters.quote).div(
            optionParameters.base
        );
        require(outRedeems > 0, "ERR_ZERO");

        // Mint the optionTokens and redeemTokens.
        IRedeem(redeemToken).mint(receiver, outRedeems);
        _mint(receiver, inUnderlyings);

        // Update the underlyingCache.
        _updateCacheBalances(underlyingBalance, strikeCache);
        emit Mint(msg.sender, inUnderlyings, outRedeems);
        return (inUnderlyings, outRedeems);
    }

    /**
     * @dev Warning: This low-level function should be called from a contract which performs important safety checks.
     * This function should never be called directly by an externally owned account.
     * A sophsticated smart contract should make the important checks to make sure the correct amount of tokens
     * are transferred into this contract prior to the function call. If an incorrect amount of tokens are transferred
     * into this contract, and this function is called, it can result in the loss of funds.
     * Sends out underlyingTokens then checks to make sure they are returned or paid for.
     * This function enables flash exercises and flash loans. Only smart contracts who implement
     * their own IFlash interface should be calling this function to initiate a flash exercise/loan.
     * @notice If the underlyingTokens are returned, only the fee has to be paid.
     * @param receiver The outUnderlyings are sent to the receiver address.
     * @param outUnderlyings Quantity of underlyingTokens to safeTransfer to receiver optimistically.
     * @param data Passing in any abritrary data will trigger the flash exercise callback function.
     */
    function exerciseOptions(
        address receiver,
        uint256 outUnderlyings,
        bytes calldata data
    ) external override nonReentrant notExpired returns (uint256, uint256) {
        // Store the cached balances and token addresses in memory.
        address underlyingToken = optionParameters.underlyingToken;
        //(uint256 _underlyingCache, uint256 _strikeCache) = getCacheBalances();

        // Require outUnderlyings > 0 and balance of underlyings >= outUnderlyings.
        require(outUnderlyings > 0, "ERR_ZERO");
        require(
            IERC20(underlyingToken).balanceOf(address(this)) >= outUnderlyings,
            "ERR_BAL_UNDERLYING"
        );

        // Optimistically safeTransfer out underlyingTokens.
        IERC20(underlyingToken).safeTransfer(receiver, outUnderlyings);
        if (data.length > 0)
            IFlash(receiver).primitiveFlash(msg.sender, outUnderlyings, data);

        // Store in memory for gas savings.
        uint256 strikeBalance = IERC20(optionParameters.strikeToken).balanceOf(
            address(this)
        );
        uint256 underlyingBalance = IERC20(underlyingToken).balanceOf(
            address(this)
        );

        // Calculate the differences.
        uint256 inStrikes = strikeBalance.sub(strikeCache);
        uint256 inUnderlyings = underlyingBalance.sub(
            underlyingCache.sub(outUnderlyings)
        ); // will be > 0 if underlyingTokens are returned.

        // Either underlyingTokens or strikeTokens must be sent into the contract.
        require(inStrikes > 0 || inUnderlyings > 0, "ERR_ZERO");

        // Calculate the remaining amount of underlyingToken that needs to be paid for.
        uint256 remainder = inUnderlyings > outUnderlyings
            ? 0
            : outUnderlyings.sub(inUnderlyings);

        // Calculate the expected payment of strikeTokens.
        uint256 payment = remainder.mul(optionParameters.quote).div(
            optionParameters.base
        );

        // Assumes the cached optionToken balance is 0, which is what it should be.
        uint256 inOptions = balanceOf(address(this));

        // Enforce the invariants.
        require(inStrikes >= payment, "ERR_STRIKES_INPUT");
        require(inOptions >= remainder, "ERR_OPTIONS_INPUT");

        // Burn the optionTokens at a 1:1 ratio to outUnderlyings.
        _burn(address(this), inOptions);

        // Update the cached balances.
        _updateCacheBalances(underlyingBalance, strikeBalance);
        emit Exercise(msg.sender, outUnderlyings, inStrikes);
        return (inStrikes, inOptions);
    }

    /**
     * @dev Warning: This low-level function should be called from a contract which performs important safety checks.
     * This function should never be called directly by an externally owned account.
     * A sophsticated smart contract should make the important checks to make sure the correct amount of tokens
     * are transferred into this contract prior to the function call. If an incorrect amount of tokens are transferred
     * into this contract, and this function is called, it can result in the loss of funds.
     * Burns redeemTokens to withdraw strikeTokens at a ratio of 1:1.
     * @notice inRedeemTokens = outStrikeTokens. Only callable when strikeTokens are in the contract.
     * @param receiver The inRedeems quantity of strikeTokens are sent to the receiver address.
     */
    function redeemStrikeTokens(address receiver)
        external
        override
        nonReentrant
        returns (uint256)
    {
        address strikeToken = optionParameters.strikeToken;
        address _redeemToken = redeemToken;
        uint256 strikeBalance = IERC20(strikeToken).balanceOf(address(this));
        uint256 inRedeems = IERC20(_redeemToken).balanceOf(address(this));

        // Difference between redeemTokens balance and cache.
        require(inRedeems > 0, "ERR_ZERO");
        require(strikeBalance >= inRedeems, "ERR_BAL_STRIKE");

        // Burn redeemTokens in the contract. Send strikeTokens to receiver.
        IRedeem(_redeemToken).burn(address(this), inRedeems);
        IERC20(strikeToken).safeTransfer(receiver, inRedeems);

        // Current balances.
        strikeBalance = IERC20(strikeToken).balanceOf(address(this));

        // Update the cached balances.
        _updateCacheBalances(underlyingCache, strikeBalance);
        emit Redeem(msg.sender, inRedeems);
        return inRedeems;
    }

    /**
     * @dev Warning: This low-level function should be called from a contract which performs important safety checks.
     * This function should never be called directly by an externally owned account.
     * A sophsticated smart contract should make the important checks to make sure the correct amount of tokens
     * are transferred into this contract prior to the function call. If an incorrect amount of tokens are transferred
     * into this contract, and this function is called, it can result in the loss of funds.
     * If the option has expired, burn redeem tokens to withdraw underlying tokens.
     * If the option is not expired, burn option and redeem tokens to withdraw underlying tokens.
     * @notice inRedeemTokens / strike ratio = outUnderlyingTokens && inOptionTokens >= outUnderlyingTokens.
     * @param receiver The outUnderlyingTokens are sent to the receiver address.
     */
    function closeOptions(address receiver)
        external
        override
        nonReentrant
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Stores addresses and balances locally for gas savings.
        address underlyingToken = optionParameters.underlyingToken;
        address _redeemToken = redeemToken;
        uint256 underlyingBalance = IERC20(underlyingToken).balanceOf(
            address(this)
        );
        uint256 optionBalance = balanceOf(address(this));
        uint256 inRedeems = IERC20(_redeemToken).balanceOf(address(this));

        // The quantity of underlyingToken to send out it still determined by the quantity of inRedeems.
        // inRedeems is in units of strikeTokens, which is converted to underlyingTokens
        // by multiplying inRedeems by the strike ratio, which is base / quote.
        // This outUnderlyings quantity is checked against inOptions.
        // inOptions must be greater than or equal to outUnderlyings (1 option burned per 1 underlying purchased).
        // optionBalance must be greater than or equal to outUnderlyings.
        // Neither inRedeems or inOptions can be zero.
        uint256 outUnderlyings = inRedeems.mul(optionParameters.base).div(
            optionParameters.quote
        );

        // Assumes the cached balance is 0 so inOptions = balance of optionToken.
        // If optionToken is expired, optionToken does not need to be sent in. Only redeemToken.
        // solhint-disable-next-line not-rely-on-time
        uint256 inOptions = isNotExpired() ? optionBalance : outUnderlyings;
        require(inRedeems > 0 && inOptions > 0, "ERR_ZERO");
        require(
            inOptions >= outUnderlyings && underlyingBalance >= outUnderlyings,
            "ERR_BAL_UNDERLYING"
        );

        // Burn optionTokens. optionTokens are only sent into contract when not expired.
        // solhint-disable-next-line not-rely-on-time
        if (isNotExpired()) {
            _burn(address(this), inOptions);
        }

        // Send underlyingTokens to user.
        // Burn redeemTokens held in the contract.
        // User does not receive extra underlyingTokens if there was extra optionTokens in the contract.
        // User receives outUnderlyings proportional to inRedeems.
        IRedeem(_redeemToken).burn(address(this), inRedeems);
        IERC20(underlyingToken).safeTransfer(receiver, outUnderlyings);

        // Current balances of underlyingToken and redeemToken.
        underlyingBalance = IERC20(underlyingToken).balanceOf(address(this));

        // Update the cached balances.
        _updateCacheBalances(underlyingBalance, strikeCache);
        emit Close(msg.sender, outUnderlyings);
        return (inRedeems, inOptions, outUnderlyings);
    }

    /* === VIEW === */

    /**
     * @dev Returns the previously saved balances of underlying and strike tokens.
     */
    function getCacheBalances()
        public
        override
        view
        returns (uint256, uint256)
    {
        return (underlyingCache, strikeCache);
    }

    /**
     * @dev Returns the underlying, strike, and redeem token addresses.
     */
    function getAssetAddresses()
        public
        override
        view
        returns (
            address,
            address,
            address
        )
    {
        return (
            optionParameters.underlyingToken,
            optionParameters.strikeToken,
            redeemToken
        );
    }

    /**
     * @dev Returns the strike token address.
     */
    function getStrikeTokenAddress() public override view returns (address) {
        return optionParameters.strikeToken;
    }

    /**
     * @dev Returns the underlying token address.
     */
    function getUnderlyingTokenAddress()
        public
        override
        view
        returns (address)
    {
        return optionParameters.underlyingToken;
    }

    /**
     * @dev Returns the base value option parameter.
     */
    function getBaseValue() public override view returns (uint256) {
        return optionParameters.base;
    }

    /**
     * @dev Returns the quote value option parameter.
     */
    function getQuoteValue() public override view returns (uint256) {
        return optionParameters.quote;
    }

    /**
     * @dev Returns the expiry timestamp option parameter.
     */
    function getExpiryTime() public override view returns (uint256) {
        return optionParameters.expiry;
    }

    /**
     * @dev Returns the option parameters and redeem token address.
     */
    function getParameters()
        public
        override
        view
        returns (
            address _underlyingToken,
            address _strikeToken,
            address _redeemToken,
            uint256 _base,
            uint256 _quote,
            uint256 _expiry
        )
    {
        OptionParameters memory _optionParameters = optionParameters;
        _underlyingToken = _optionParameters.underlyingToken;
        _strikeToken = _optionParameters.strikeToken;
        _redeemToken = redeemToken;
        _base = _optionParameters.base;
        _quote = _optionParameters.quote;
        _expiry = _optionParameters.expiry;
    }

    /**
     * @dev Internal function to check if the option is expired.
     */
    function isNotExpired() internal view returns (bool) {
        return optionParameters.expiry >= block.timestamp;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { Option } from "../primitives/Option.sol";

library OptionTemplateLib {
    // solhint-disable-next-line max-line-length
    bytes32
        private constant _OPTION_SALT = 0x56f3a99c8e36689645460020839ea1340cbbb2e507b7effe3f180a89db85dd87; // keccak("primitive-option")

    // solhint-disable-next-line func-name-mixedcase
    function OPTION_SALT() internal pure returns (bytes32) {
        return _OPTION_SALT;
    }

    /**
     * @dev Deploys a clone of the deployed Option.sol contract.
     */
    function deployTemplate() external returns (address implementationAddress) {
        bytes memory creationCode = type(Option).creationCode;
        implementationAddress = Create2.deploy(0, _OPTION_SALT, creationCode);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

contract NullCloneConstructor {
    // solhint-disable-next-line no-empty-blocks
    function cloneConstructor(bytes memory consData) public {
        // blank
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title Create2 Clone Factory Library
 * @author Alan Lu, Gnosis.
 *         Raymond Pulver IV.
 */

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

library CloneLib {
    /**
     * @dev Calls internal creation computation function.
     */
    function computeCreationCode(address target)
        internal
        view
        returns (bytes memory clone)
    {
        clone = computeCreationCode(address(this), target);
    }

    /**
     * @dev Computes the Clone's creation code.
     */
    function computeCreationCode(address deployer, address target)
        internal
        pure
        returns (bytes memory clone)
    {
        bytes memory consData = abi.encodeWithSignature(
            "cloneConstructor(bytes)",
            new bytes(0)
        );
        clone = new bytes(99 + consData.length);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(
                add(clone, 0x20),
                0x3d3d606380380380913d393d73bebebebebebebebebebebebebebebebebebebe
            )
            mstore(
                add(clone, 0x2d),
                mul(deployer, 0x01000000000000000000000000)
            )
            mstore(
                add(clone, 0x41),
                0x5af4602a57600080fd5b602d8060366000396000f3363d3d373d3d3d363d73be
            )
            mstore(add(clone, 0x60), mul(target, 0x01000000000000000000000000))
            mstore(
                add(clone, 116),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
        }
        for (uint256 i = 0; i < consData.length; i++) {
            clone[i + 99] = consData[i];
        }
    }

    /**
     * @dev Calls Open Zeppelin's Create2.computeAddress() to get an address for the clone.
     */
    function deriveInstanceAddress(address target, bytes32 salt)
        internal
        view
        returns (address)
    {
        return
            Create2.computeAddress(
                salt,
                keccak256(computeCreationCode(target))
            );
    }

    /**
     * @dev Calls Open Zeppelin's Create2.computeAddress() to get an address for the clone.
     */
    function deriveInstanceAddress(
        address from,
        address target,
        bytes32 salt
    ) internal pure returns (address) {
        return
            Create2.computeAddress(
                salt,
                keccak256(computeCreationCode(from, target)),
                from
            );
    }

    /**
     * @dev Computs creation code, and then instantiates it with create2.
     */
    function create2Clone(address target, uint256 saltNonce)
        internal
        returns (address result)
    {
        bytes memory clone = computeCreationCode(target);
        bytes32 salt = bytes32(saltNonce);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let len := mload(clone)
            let data := add(clone, 0x20)
            result := create2(0, data, len, salt)
        }

        require(result != address(0), "ERR_CREATE2_FAIL");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

interface IOptionFactory {
    function deployClone(
        address underlyingToken,
        address strikeToken,
        uint256 base,
        uint256 quote,
        uint256 expiry
    ) external returns (address);

    function initRedeemToken(address optionAddress, address redeemAddress)
        external;

    function deployOptionTemplate() external;

    function optionTemplate() external returns (address);

    function calculateOptionAddress(
        address underlyingToken,
        address strikeToken,
        uint256 base,
        uint256 quote,
        uint256 expiry
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IOption is IERC20 {
    function mintOptions(address receiver) external returns (uint256, uint256);

    function exerciseOptions(
        address receiver,
        uint256 outUnderlyings,
        bytes calldata data
    ) external returns (uint256, uint256);

    function redeemStrikeTokens(address receiver) external returns (uint256);

    function closeOptions(address receiver)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function redeemToken() external view returns (address);

    function getStrikeTokenAddress() external view returns (address);

    function getUnderlyingTokenAddress() external view returns (address);

    function getBaseValue() external view returns (uint256);

    function getQuoteValue() external view returns (uint256);

    function getExpiryTime() external view returns (uint256);

    function underlyingCache() external view returns (uint256);

    function strikeCache() external view returns (uint256);

    function factory() external view returns (address);

    function getCacheBalances() external view returns (uint256, uint256);

    function getAssetAddresses()
        external
        view
        returns (
            address,
            address,
            address
        );

    function getParameters()
        external
        view
        returns (
            address _underlyingToken,
            address _strikeToken,
            address _redeemToken,
            uint256 _base,
            uint256 _quote,
            uint256 _expiry
        );

    function initRedeemToken(address _redeemToken) external;

    function updateCacheBalances() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IRedeem is IERC20 {
    function optionToken() external view returns (address);

    function factory() external view returns (address);

    function mint(address user, uint256 amount) external;

    function burn(address user, uint256 amount) external;

    function initialize(address _factory, address _optionToken) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

interface IFlash {
    function primitiveFlash(
        address receiver,
        uint256 outUnderlyings,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Modifies name, symbol, and decimals by deleting them. Implemented as constants in parent contract.
 */

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    /* function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    } */

    // ======= WARNING: ADDED FUNCTIONS =========

    /* function _setupName(string memory name_) internal {
        _name = name_;
    }

    function _setupSymbol(string memory symbol_) internal {
        _symbol = symbol_;
    } */

    // ======= END ADDED FUNCTIONS =========

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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(bytes20(_data << 96));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

/**
 * @title Protocol Registry Contract for Deployed Options.
 * @author Primitive
 */

import { IOption } from "../interfaces/IOption.sol";
import { IRegistry } from "../interfaces/IRegistry.sol";
import { IOptionFactory } from "../interfaces/IOptionFactory.sol";
import { IRedeemFactory } from "../interfaces/IRedeemFactory.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract Registry is IRegistry, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    address public override optionFactory;
    address public override redeemFactory;

    mapping(address => bool) private verifiedTokens;
    mapping(uint256 => bool) private verifiedExpiries;
    address[] public allOptionClones;

    event UpdatedOptionFactory(address indexed optionFactory_);
    event UpdatedRedeemFactory(address indexed redeemFactory_);
    event VerifiedToken(address indexed token);
    event VerifiedExpiry(uint256 expiry);
    event UnverifiedToken(address indexed token);
    event UnverifiedExpiry(uint256 expiry);
    event DeployedOptionClone(
        address indexed from,
        address indexed optionAddress,
        address indexed redeemAddress
    );

    constructor() public {
        transferOwnership(msg.sender);
    }

    /**
     * @dev Pauses the deployOption function.
     */
    function pauseDeployments() external override onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the deployOption function.
     */
    function unpauseDeployments() external override onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the option factory contract to use for deploying clones.
     * @param optionFactory_ The address of the option factory.
     */
    function setOptionFactory(address optionFactory_)
        external
        override
        onlyOwner
    {
        optionFactory = optionFactory_;
        emit UpdatedOptionFactory(optionFactory_);
    }

    /**
     * @dev Sets the redeem factory contract to use for deploying clones.
     * @param redeemFactory_ The address of the redeem factory.
     */
    function setRedeemFactory(address redeemFactory_)
        external
        override
        onlyOwner
    {
        redeemFactory = redeemFactory_;
        emit UpdatedRedeemFactory(redeemFactory_);
    }

    /**
     * @dev Sets an ERC-20 token verification status to true.
     * @notice A "verified" token is a standard ERC-20 token that we have tested with the option contract.
     *         An example of an "unverified" token is a non-standard ERC-20 token which has not been tested.
     */
    function verifyToken(address tokenAddress) external override onlyOwner {
        require(tokenAddress != address(0x0), "ERR_ZERO_ADDRESS");
        verifiedTokens[tokenAddress] = true;
        emit VerifiedToken(tokenAddress);
    }

    /**
     * @dev Sets a verified token's verification status to false.
     */
    function unverifyToken(address tokenAddress) external override onlyOwner {
        verifiedTokens[tokenAddress] = false;
        emit UnverifiedToken(tokenAddress);
    }

    /**
     * @dev Sets an expiry timestamp's verification status to true.
     * @notice A mapping of standardized, "verified", timestamps for the options.
     */
    function verifyExpiry(uint256 expiry) external override onlyOwner {
        require(expiry >= now, "ERR_EXPIRED_TIMESTAMP");
        verifiedExpiries[expiry] = true;
        emit VerifiedExpiry(expiry);
    }

    /**
     * @dev Sets an expiry timestamp's verification status to false.
     * @notice A mapping of standardized, "verified", timestamps for the options.
     */
    function unverifyExpiry(uint256 expiry) external override onlyOwner {
        verifiedExpiries[expiry] = false;
        emit UnverifiedExpiry(expiry);
    }

    /**
     * @dev Deploys an option contract clone with create2.
     * @param underlyingToken The address of the ERC-20 underlying token.
     * @param strikeToken The address of the ERC-20 strike token.
     * @param base The quantity of underlying tokens per unit of quote amount of strike tokens.
     * @param quote The quantity of strike tokens per unit of base amount of underlying tokens.
     * @param expiry The unix timestamp of the option's expiration date.
     * @return The address of the deployed option clone.
     */
    function deployOption(
        address underlyingToken,
        address strikeToken,
        uint256 base,
        uint256 quote,
        uint256 expiry
    ) external override nonReentrant whenNotPaused returns (address) {
        // Validation checks for option parameters.
        require(base > 0, "ERR_BASE_ZERO");
        require(quote > 0, "ERR_QUOTE_ZERO");
        require(expiry >= now, "ERR_EXPIRY");
        require(underlyingToken != strikeToken, "ERR_SAME_ASSETS");
        require(
            underlyingToken != address(0x0) && strikeToken != address(0x0),
            "ERR_ZERO_ADDRESS"
        );

        // Deploy option and redeem contract clones.
        address optionAddress = IOptionFactory(optionFactory).deployClone(
            underlyingToken,
            strikeToken,
            base,
            quote,
            expiry
        );
        address redeemAddress = IRedeemFactory(redeemFactory).deployClone(
            optionAddress
        );

        // Add the clone to the allOptionClones address array.
        allOptionClones.push(optionAddress);

        // Initialize the new option contract's paired redeem token.
        IOptionFactory(optionFactory).initRedeemToken(
            optionAddress,
            redeemAddress
        );
        emit DeployedOptionClone(msg.sender, optionAddress, redeemAddress);
        return optionAddress;
    }

    /**
     * @dev Calculates the option address deployed with create2 using the parameter arguments.
     * @param underlyingToken The address of the ERC-20 underlying token.
     * @param strikeToken The address of the ERC-20 strike token.
     * @param base The quantity of underlying tokens per unit of quote amount of strike tokens.
     * @param quote The quantity of strike tokens per unit of base amount of underlying tokens.
     * @param expiry The unix timestamp of the option's expiration date.
     * @return The address of the option with the parameter arguments.
     */
    function calculateOptionAddress(
        address underlyingToken,
        address strikeToken,
        uint256 base,
        uint256 quote,
        uint256 expiry
    ) public override view returns (address) {
        address optionAddress = IOptionFactory(optionFactory)
            .calculateOptionAddress(
            underlyingToken,
            strikeToken,
            base,
            quote,
            expiry
        );
        return optionAddress;
    }

    /**
     * @dev Checks an option address to see if it has verified assets and expiry time.
     * @param optionAddress The address of the option token.
     * @return bool If the option has verified underlying and strike tokens, and expiry time.
     */
    function isVerifiedOption(address optionAddress)
        external
        override
        view
        returns (bool)
    {
        IOption option = IOption(optionAddress);
        address underlyingToken = option.getUnderlyingTokenAddress();
        address strikeToken = option.getStrikeTokenAddress();
        uint256 expiry = option.getExpiryTime();
        bool verifiedUnderlying = isVerifiedToken(underlyingToken);
        bool verifiedStrike = isVerifiedToken(strikeToken);
        bool verifiedExpiry = isVerifiedExpiry(expiry);
        return verifiedUnderlying && verifiedStrike && verifiedExpiry;
    }

    /**
     * @dev Returns the length of the allOptionClones address array.
     */
    function getAllOptionClonesLength() public view returns (uint256) {
        return allOptionClones.length;
    }

    /**
     * @dev Checks the verifiedTokens private mapping and returns verification status of token.
     * @return bool Verified or not verified.
     */
    function isVerifiedToken(address tokenAddress) public view returns (bool) {
        return verifiedTokens[tokenAddress];
    }

    /**
     * @dev Checks the verifiedExpiries private mapping and returns verification status of token.
     * @return bool Verified or not verified.
     */
    function isVerifiedExpiry(uint256 expiry) public view returns (bool) {
        return verifiedExpiries[expiry];
    }

    /**
     * @dev Gets the option address and returns address zero if not yet deployed.
     * @notice Will calculate the option address using the parameter arguments.
     *         Checks the code size of the address to see if the contract has been deployed yet.
     *         If contract has not been deployed, returns address zero.
     * @param underlyingToken The address of the ERC-20 underlying token.
     * @param strikeToken The address of the ERC-20 strike token.
     * @param base The quantity of underlying tokens per unit of quote amount of strike tokens.
     * @param quote The quantity of strike tokens per unit of base amount of underlying tokens.
     * @param expiry The unix timestamp of the option's expiration date.
     * @return The address of the option with the parameter arguments.
     */
    function getOptionAddress(
        address underlyingToken,
        address strikeToken,
        uint256 base,
        uint256 quote,
        uint256 expiry
    ) public override view returns (address) {
        address optionAddress = calculateOptionAddress(
            underlyingToken,
            strikeToken,
            base,
            quote,
            expiry
        );
        uint32 size = checkCodeSize(optionAddress);
        if (size > 0) {
            return optionAddress;
        } else {
            return address(0x0);
        }
    }

    /**
     * @dev Checks the code size of a target address and returns the uint32 size.
     * @param target The address to check code size.
     */
    function checkCodeSize(address target) private view returns (uint32) {
        uint32 size;
        assembly {
            size := extcodesize(target)
        }
        return size;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

interface IRegistry {
    function pauseDeployments() external;

    function unpauseDeployments() external;

    function deployOption(
        address underlyingToken,
        address strikeToken,
        uint256 base,
        uint256 quote,
        uint256 expiry
    ) external returns (address);

    function setOptionFactory(address optionFactory_) external;

    function setRedeemFactory(address redeemFactory_) external;

    function optionFactory() external returns (address);

    function redeemFactory() external returns (address);

    function verifyToken(address tokenAddress) external;

    function verifyExpiry(uint256 expiry) external;

    function unverifyToken(address tokenAddress) external;

    function unverifyExpiry(uint256 expiry) external;

    function calculateOptionAddress(
        address underlyingToken,
        address strikeToken,
        uint256 base,
        uint256 quote,
        uint256 expiry
    ) external view returns (address);

    function getOptionAddress(
        address underlyingToken,
        address strikeToken,
        uint256 base,
        uint256 quote,
        uint256 expiry
    ) external view returns (address);

    function isVerifiedOption(address optionAddress)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

interface IRedeemFactory {
    function deployClone(address optionToken) external returns (address);

    function deployRedeemTemplate() external;

    function redeemTemplate() external returns (address);
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";

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

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BadERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
    {
        _transfer(_msgSender(), recipient, amount);
    }

    function allowance(address owner, address spender)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    // solhint-disable-next-line no-empty-blocks
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        // do nothing
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @title   Trader Library
 * @notice  Internal functions that can be used to safeTransfer
 *          tokens into the option contract then call respective option contract functions.
 * @author  Primitive
 */

import { IOption } from "../interfaces/IOption.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library TraderLib {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Conducts important safety checks to safely mint option tokens.
     * @param optionToken The address of the option token to mint.
     * @param mintQuantity The quantity of option tokens to mint.
     * @param receiver The address which receives the minted option tokens.
     */
    function safeMint(
        IOption optionToken,
        uint256 mintQuantity,
        address receiver
    ) internal returns (uint256, uint256) {
        require(mintQuantity > 0, "ERR_ZERO");
        IERC20(optionToken.getUnderlyingTokenAddress()).safeTransferFrom(
            msg.sender,
            address(optionToken),
            mintQuantity
        );
        (uint256 outputOptions, uint256 outputRedeems) = optionToken
            .mintOptions(receiver);
        return (outputOptions, outputRedeems);
    }

    /**
     * @dev Swaps strikeTokens to underlyingTokens using the strike ratio as the exchange rate.
     * @notice Burns optionTokens, option contract receives strikeTokens, user receives underlyingTokens.
     * @param optionToken The address of the option contract.
     * @param exerciseQuantity Quantity of optionTokens to exercise.
     * @param receiver The underlyingTokens are sent to the receiver address.
     */
    function safeExercise(
        IOption optionToken,
        uint256 exerciseQuantity,
        address receiver
    ) internal returns (uint256, uint256) {
        require(exerciseQuantity > 0, "ERR_ZERO");
        require(
            IERC20(address(optionToken)).balanceOf(msg.sender) >=
                exerciseQuantity,
            "ERR_BAL_OPTIONS"
        );

        // Calculate quantity of strikeTokens needed to exercise quantity of optionTokens.
        uint256 inputStrikes = exerciseQuantity
            .mul(optionToken.getQuoteValue())
            .div(optionToken.getBaseValue());
        require(
            IERC20(optionToken.getStrikeTokenAddress()).balanceOf(msg.sender) >=
                inputStrikes,
            "ERR_BAL_STRIKE"
        );
        IERC20(optionToken.getStrikeTokenAddress()).safeTransferFrom(
            msg.sender,
            address(optionToken),
            inputStrikes
        );
        IERC20(address(optionToken)).safeTransferFrom(
            msg.sender,
            address(optionToken),
            exerciseQuantity
        );

        uint256 inputOptions;
        (inputStrikes, inputOptions) = optionToken.exerciseOptions(
            receiver,
            exerciseQuantity,
            new bytes(0)
        );
        return (inputStrikes, inputOptions);
    }

    /**
     * @dev Burns redeemTokens to withdraw available strikeTokens.
     * @notice inputRedeems = outputStrikes.
     * @param optionToken The address of the option contract.
     * @param redeemQuantity redeemQuantity of redeemTokens to burn.
     * @param receiver The strikeTokens are sent to the receiver address.
     */
    function safeRedeem(
        IOption optionToken,
        uint256 redeemQuantity,
        address receiver
    ) internal returns (uint256) {
        require(redeemQuantity > 0, "ERR_ZERO");
        require(
            IERC20(optionToken.redeemToken()).balanceOf(msg.sender) >=
                redeemQuantity,
            "ERR_BAL_REDEEM"
        );
        // There can be the case there is no available strikes to redeem, causing a revert.
        IERC20(optionToken.redeemToken()).safeTransferFrom(
            msg.sender,
            address(optionToken),
            redeemQuantity
        );
        uint256 inputRedeems = optionToken.redeemStrikeTokens(receiver);
        return inputRedeems;
    }

    /**
     * @dev Burn optionTokens and redeemTokens to withdraw underlyingTokens.
     * @notice The redeemTokens to burn is equal to the optionTokens * strike ratio.
     * inputOptions = inputRedeems / strike ratio = outUnderlyings
     * @param optionToken The address of the option contract.
     * @param closeQuantity Quantity of optionTokens to burn.
     * (Implictly will burn the strike ratio quantity of redeemTokens).
     * @param receiver The underlyingTokens are sent to the receiver address.
     */
    function safeClose(
        IOption optionToken,
        uint256 closeQuantity,
        address receiver
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(closeQuantity > 0, "ERR_ZERO");
        require(
            IERC20(address(optionToken)).balanceOf(msg.sender) >= closeQuantity,
            "ERR_BAL_OPTIONS"
        );

        // Calculate the quantity of redeemTokens that need to be burned. (What we mean by Implicit).
        uint256 inputRedeems = closeQuantity
            .mul(optionToken.getQuoteValue())
            .div(optionToken.getBaseValue());
        require(
            IERC20(optionToken.redeemToken()).balanceOf(msg.sender) >=
                inputRedeems,
            "ERR_BAL_REDEEM"
        );
        IERC20(optionToken.redeemToken()).safeTransferFrom(
            msg.sender,
            address(optionToken),
            inputRedeems
        );
        IERC20(address(optionToken)).safeTransferFrom(
            msg.sender,
            address(optionToken),
            closeQuantity
        );

        uint256 inputOptions;
        uint256 outUnderlyings;
        (inputRedeems, inputOptions, outUnderlyings) = optionToken.closeOptions(
            receiver
        );
        return (inputRedeems, inputOptions, outUnderlyings);
    }

    /**
     * @dev Burn redeemTokens to withdraw underlyingTokens and strikeTokens from expired options.
     * @param optionToken The address of the option contract.
     * @param unwindQuantity Quantity of option tokens used to calculate the amount of redeem tokens to burn.
     * @param receiver The underlyingTokens are sent to the receiver address and the redeemTokens are burned.
     */
    function safeUnwind(
        IOption optionToken,
        uint256 unwindQuantity,
        address receiver
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Checks
        require(unwindQuantity > 0, "ERR_ZERO");
        // solhint-disable-next-line not-rely-on-time
        require(
            optionToken.getExpiryTime() < block.timestamp,
            "ERR_NOT_EXPIRED"
        );

        // Calculate amount of redeems required
        uint256 inputRedeems = unwindQuantity
            .mul(optionToken.getQuoteValue())
            .div(optionToken.getBaseValue());
        require(
            IERC20(optionToken.redeemToken()).balanceOf(msg.sender) >=
                inputRedeems,
            "ERR_BAL_REDEEM"
        );
        IERC20(optionToken.redeemToken()).safeTransferFrom(
            msg.sender,
            address(optionToken),
            inputRedeems
        );

        uint256 inputOptions;
        uint256 outUnderlyings;
        (inputRedeems, inputOptions, outUnderlyings) = optionToken.closeOptions(
            receiver
        );

        return (inputRedeems, inputOptions, outUnderlyings);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @title Test Flash Exercise contract
 * @author Primitive
 */

/**
 * A flash exercise is initiated by the exerciseOptions() function in the Option.sol contract.
 * Warning: Only correctly implemented wrapper smart contracts can safely execute these flash features.
 * Underlying tokens will be sent to the msg.sender of the exerciseOptions() call first.
 * The msg.sender should be a smart contract that implements the IFlash interface, which has a single
 * function: primitiveFlash().
 * The callback function primitiveFlash() can be triggered by passing in any arbritrary data to the
 * exerciseOptions() function. If the length of the data is greater than 0, it triggers the callback.
 * The implemented primitiveFlash() callback is where customized operations can be undertaken using the
 * underlying tokens received from the flash exercise.
 * After the callback function (whether its called or not), the exerciseOptions() function checks to see
 * if it has been paid the correct amount of strike and option tokens (an actual exercise of the option),
 * or if it has received the same quantity of underlying tokens back (a flash loan).
 */

import { IOption } from "../option/interfaces/IOption.sol";
import { IFlash } from "../option/interfaces/IFlash.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Flash is IFlash {
    using SafeMath for uint256;

    address public optionToken;

    event FlashExercise(address indexed from);

    constructor(address _optionToken) public {
        optionToken = _optionToken;
    }

    function goodFlashLoan(uint256 amount) external {
        // Call the exerciseOptions function and trigger the fallback function by passing in data
        IOption(optionToken).exerciseOptions(
            address(this),
            amount,
            new bytes(1)
        );
    }

    function badFlashLoan(uint256 amount) external {
        // Call the exerciseOptions function and trigger the fallback function by passing in data
        // bytes(2) will cause our implemented flash exercise to fail
        IOption(optionToken).exerciseOptions(
            address(this),
            amount,
            new bytes(2)
        );
    }

    /**
     * @dev An implemented primitiveFlash callback function that matches the interface in Option.sol.
     * @notice Calling the exerciseOptions() function in the Option contract will trigger this callback function.
     * @param receiver The account which receives the underlying tokens.
     * @param outUnderlyings The quantity of underlying tokens received as a flash loan.
     * @param data Any data that will be passed as an argument to the original exerciseOptions() call.
     */
    function primitiveFlash(
        address receiver,
        uint256 outUnderlyings,
        bytes calldata data
    ) external override {
        // Get the underlying token address.
        address underlyingToken = IOption(optionToken)
            .getUnderlyingTokenAddress();
        // In our test case we pass in the data param with bytes(1).
        bool good = keccak256(abi.encodePacked(data)) ==
            keccak256(abi.encodePacked(new bytes(1)));
        // If the flash exercise went through, we return the loaned underlyings.
        if (good) {
            IERC20(underlyingToken).transfer(optionToken, outUnderlyings);
        }
        emit FlashExercise(receiver);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @title   Option test contract.
 * @author  Primitive
 */

import "../option/primitives/Option.sol";

contract OptionTest is Option {
    // solhint-disable-next-line no-empty-blocks
    constructor() public Option() {}

    function setExpiry(uint256 expiry) public {
        optionParameters.expiry = expiry;
    }

    function setRedeemToken(address redeem) public {
        redeemToken = redeem;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { Redeem } from "../primitives/Redeem.sol";

library RedeemTemplateLib {
    // solhint-disable-next-line max-line-length
    bytes32
        private constant _REDEEM_SALT = 0xe7383acf78b06b8f24cfa7359d041702736fa6a58e63dd38afea80889c4636e2; // keccak("primitive-redeem")

    // solhint-disable-next-line func-name-mixedcase
    function REDEEM_SALT() internal pure returns (bytes32) {
        return _REDEEM_SALT;
    }

    /**
     * @dev Deploys a clone of the deployed Redeem.sol contract.
     */
    function deployTemplate() external returns (address implementationAddress) {
        bytes memory creationCode = type(Redeem).creationCode;
        implementationAddress = Create2.deploy(0, _REDEEM_SALT, creationCode);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.2;

/**
 * @title   Redeem Token
 * @notice  A token that is redeemable for it's paird option token's assets.
 * @author  Primitive
 */

import { IRedeem } from "../interfaces/IRedeem.sol";
import { ERC20 } from "./ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract Redeem is IRedeem, ERC20 {
    using SafeMath for uint256;

    address public override factory;
    address public override optionToken;

    string public constant name = "Primitive V1 Redeem";
    string public constant symbol = "RDM";
    uint8 public constant decimals = 18;

    // solhint-disable-next-line no-empty-blocks
    constructor() public {}

    /**
     * @dev Sets the initial state for the redeem token. Called only once and immediately after deployment.
     * @param factory_ The address of the factory contract which handles the deployment.
     * @param optionToken_ The address of the option token which this redeem token will be paired with.
     */
    function initialize(address factory_, address optionToken_)
        public
        override
    {
        require(factory == address(0x0), "ERR_IS_INITIALIZED");
        factory = factory_;
        optionToken = optionToken_;
    }

    /**
     * @dev Mints redeem tokens. Only callable by the paired option contract.
     * @param to The address to mint redeem tokens to.
     * @param amount The quantity of redeem tokens to mint.
     */
    function mint(address to, uint256 amount) external override {
        require(msg.sender == optionToken, "ERR_NOT_VALID");
        _mint(to, amount);
    }

    /**
     * @dev Burns redeem tokens. Only callable by the paired option contract.
     * @param to The address to burn redeem tokens from.
     * @param amount The quantity of redeem tokens to burn.
     */
    function burn(address to, uint256 amount) external override {
        require(msg.sender == optionToken, "ERR_NOT_VALID");
        _burn(to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

/**
 * @title Protocol Factory Contract for Redeem Tokens.
 * @notice Uses cloning technology on a deployed template contract.
 * @author Primitive
 */

import { Redeem, SafeMath } from "../../primitives/Redeem.sol";
import { RedeemTemplateLib } from "../../libraries/RedeemTemplateLib.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { CloneLib } from "../../libraries/CloneLib.sol";
import { NullCloneConstructor } from "../NullCloneConstructor.sol";
import { IRedeemFactory } from "../../interfaces/IRedeemFactory.sol";

contract RedeemFactory is IRedeemFactory, Ownable, NullCloneConstructor {
    using SafeMath for uint256;

    address public override redeemTemplate;

    constructor(address registry) public {
        transferOwnership(registry);
    }

    /**
     * @dev Deploys the full bytecode of the Redeem contract to be used as a template for clones.
     */
    function deployRedeemTemplate() public override {
        redeemTemplate = RedeemTemplateLib.deployTemplate();
    }

    /**
     * @dev Deploys a cloned instance of the template Redeem contract.
     * @param optionToken The address of the option token which this redeem clone will be paired with.
     * @return redeemAddress The address of the deployed Redeem token clone.
     */
    function deployClone(address optionToken)
        external
        override
        onlyOwner
        returns (address)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                RedeemTemplateLib.REDEEM_SALT(),
                owner(),
                optionToken
            )
        );
        address redeemAddress = CloneLib.create2Clone(
            redeemTemplate,
            uint256(salt)
        );
        Redeem(redeemAddress).initialize(owner(), optionToken);
        return redeemAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public returns (bool) {
        _mint(to, value);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public returns (bool) {
        _mint(to, value);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DAI is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public returns (bool) {
        _mint(to, value);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

import { IOption } from "./IOption.sol";

interface ITrader {
    function safeMint(
        IOption optionToken,
        uint256 mintQuantity,
        address receiver
    ) external returns (uint256, uint256);

    function safeExercise(
        IOption optionToken,
        uint256 exerciseQuantity,
        address receiver
    ) external returns (uint256, uint256);

    function safeRedeem(
        IOption optionToken,
        uint256 redeemQuantity,
        address receiver
    ) external returns (uint256);

    function safeClose(
        IOption optionToken,
        uint256 closeQuantity,
        address receiver
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function safeUnwind(
        IOption optionToken,
        uint256 unwindQuantity,
        address receiver
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

/**
 * @title   Trader
 * @notice  Abstracts the interfacing with the protocol's option contract for ease-of-use.
 * @author  Primitive
 */

import { IOption } from "../interfaces/IOption.sol";
import { ITrader } from "../interfaces/ITrader.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { TraderLib } from "../libraries/TraderLib.sol";

contract Trader is ITrader, ReentrancyGuard {
    using SafeMath for uint256;

    address payable public weth;

    event TraderMint(
        address indexed from,
        address indexed option,
        uint256 outputOptions,
        uint256 outputRedeems
    );
    event TraderExercise(
        address indexed from,
        address indexed option,
        uint256 outUnderlyings,
        uint256 inStrikes
    );
    event TraderRedeem(
        address indexed from,
        address indexed option,
        uint256 inRedeems
    );
    event TraderClose(
        address indexed from,
        address indexed option,
        uint256 inOptions
    );

    event TraderUnwind(
        address indexed from,
        address indexed option,
        uint256 inOptions
    );

    constructor(address payable _weth) public {
        weth = _weth;
    }

    /**
     * @dev Mint options at a 1:1 ratio with deposited underlying tokens.
     * @notice Also mints redeems at a strike ratio to the deposited underlyings.
     * Warning: Calls msg.sender with safeTransferFrom.
     * @param optionToken The address of the option contract.
     * @param mintQuantity Quantity of options to mint and underlyingToken to deposit.
     * @param receiver The newly minted options and redeems are sent to the receiver address.
     */
    function safeMint(
        IOption optionToken,
        uint256 mintQuantity,
        address receiver
    ) external override nonReentrant returns (uint256, uint256) {
        (uint256 outputOptions, uint256 outputRedeems) = TraderLib.safeMint(
            optionToken,
            mintQuantity,
            receiver
        );
        emit TraderMint(
            msg.sender,
            address(optionToken),
            outputOptions,
            outputRedeems
        );
        return (outputOptions, outputRedeems);
    }

    /**
     * @dev Swaps strikeTokens to underlyingTokens using the strike ratio as the exchange rate.
     * @notice Burns optionTokens, option contract receives strikeTokens, user receives underlyingTokens.
     * @param optionToken The address of the option contract.
     * @param exerciseQuantity Quantity of optionTokens to exercise.
     * @param receiver The underlyingTokens are sent to the receiver address.
     */
    function safeExercise(
        IOption optionToken,
        uint256 exerciseQuantity,
        address receiver
    ) external override nonReentrant returns (uint256, uint256) {
        (uint256 inStrikes, uint256 inOptions) = TraderLib.safeExercise(
            optionToken,
            exerciseQuantity,
            receiver
        );
        emit TraderExercise(
            msg.sender,
            address(optionToken),
            exerciseQuantity,
            inStrikes
        );

        return (inStrikes, inOptions);
    }

    /**
     * @dev Burns redeemTokens to withdraw available strikeTokens.
     * @notice inRedeems = outStrikes.
     * @param optionToken The address of the option contract.
     * @param redeemQuantity redeemQuantity of redeemTokens to burn.
     * @param receiver The strikeTokens are sent to the receiver address.
     */
    function safeRedeem(
        IOption optionToken,
        uint256 redeemQuantity,
        address receiver
    ) external override nonReentrant returns (uint256) {
        uint256 inRedeems = TraderLib.safeRedeem(
            optionToken,
            redeemQuantity,
            receiver
        );
        emit TraderRedeem(msg.sender, address(optionToken), inRedeems);
        return inRedeems;
    }

    /**
     * @dev Burn optionTokens and redeemTokens to withdraw underlyingTokens.
     * @notice The redeemTokens to burn is equal to the optionTokens * strike ratio.
     * inOptions = inRedeems / strike ratio = outUnderlyings
     * @param optionToken The address of the option contract.
     * @param closeQuantity Quantity of optionTokens to burn.
     * (Implictly will burn the strike ratio quantity of redeemTokens).
     * @param receiver The underlyingTokens are sent to the receiver address.
     */
    function safeClose(
        IOption optionToken,
        uint256 closeQuantity,
        address receiver
    )
        external
        override
        nonReentrant
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 inRedeems,
            uint256 inOptions,
            uint256 outUnderlyings
        ) = TraderLib.safeClose(optionToken, closeQuantity, receiver);
        emit TraderClose(msg.sender, address(optionToken), inOptions);
        return (inRedeems, inOptions, outUnderlyings);
    }

    /**
     * @dev Burn redeemTokens to withdraw underlyingTokens and strikeTokens from expired options.
     * @param optionToken The address of the option contract.
     * @param unwindQuantity Quantity of option tokens used to calculate the amount of redeem tokens to burn.
     * @param receiver The underlyingTokens and redeemTokens are sent to the receiver address.
     */
    function safeUnwind(
        IOption optionToken,
        uint256 unwindQuantity,
        address receiver
    )
        external
        override
        nonReentrant
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 inRedeems,
            uint256 inOptions,
            uint256 outUnderlyings
        ) = TraderLib.safeUnwind(optionToken, unwindQuantity, receiver);
        emit TraderUnwind(msg.sender, address(optionToken), inOptions);
        return (inRedeems, inOptions, outUnderlyings);
    }
}