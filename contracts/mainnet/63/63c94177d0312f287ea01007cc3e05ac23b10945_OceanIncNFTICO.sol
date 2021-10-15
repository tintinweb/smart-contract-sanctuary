/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// File: contracts/IOceanIncNFTToken.sol

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IOceanIncNFTToken {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);
 
    function transferOwnership(address newOwner) external;
    
    function renounceMinter() external;
    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mint(address recipient, uint256 mintAmount) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

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
    constructor () {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/utils/SafeMath.sol

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            if (b > a) return (false, 0);
            return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            if (b == 0) return (false, 0);
            return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            if (b == 0) return (false, 0);
            return (true, a % b);
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b <= a, errorMessage);
            return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
            return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
            require(b > 0, errorMessage);
            return a % b;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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

    constructor () {
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

// File: contracts/crowdsale/Crowdsale.sol

pragma solidity ^0.8.0;

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is Context, ReentrancyGuard  {
    using SafeMath for uint256;

    // The token being sold
    IOceanIncNFTToken private _token;

    // Amount of wei raised
    uint256 private _weiRaised;

    // Address where funds are collected
    address payable private _wallet;

    // Sale price is 0.08 ETH
    uint256 internal _rate = 80000000000000000;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 mintAmount);

    /**
     * @param __wallet Address where collected funds will be forwarded to
     * @param __token Address of the token being sold
     */
    constructor (address payable __wallet, IOceanIncNFTToken __token) public {
        require(__wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(__token) != address(0), "Crowdsale: token is the zero address");

        _wallet = __wallet;
        _token = __token;
    }

    /**
     * @return the token being sold.
     */
    function token() public view virtual returns (IOceanIncNFTToken) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view virtual returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view virtual returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view virtual returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
    **/
    function buyNFT(address beneficiary, uint256 mintAmount) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, mintAmount, weiAmount);

        // update state ETH Amount
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, mintAmount);
        emit TokensPurchased(_msgSender(), beneficiary, mintAmount);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds(beneficiary, weiAmount);
        _postValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param mintAmount total no of tokens to be minted
     * @param weiAmount no of ETH sent
     */
    function _preValidatePurchase(address beneficiary, uint256 mintAmount, uint256 weiAmount) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param mintAmount Total mint tokens
     */
    function _processPurchase(address beneficiary, uint256 mintAmount) internal virtual {
        _deliverTokens(beneficiary, mintAmount);
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param mintAmount Total mint tokens
     */
    function _deliverTokens(address beneficiary, uint256 mintAmount) internal {
         
         /*********** COMMENTED REQUIRE BECAUSE IT WAS RETURNING BOOLEAN AND WE WERE LISTENING FROM THE INTERFACE THAT IT WILL RETURN BOOLEAN BUT IT REVERTS OUR TRANSACTION**************** */
         // Potentially dangerous assumption about the type of the token.
        require(
            token().mint(beneficiary, mintAmount)
            , "Crowdsale: transfer failed"
        );
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds(address /*beneficiary*/, uint256 /*weiAmount*/) internal virtual {
        _wallet.transfer(msg.value);
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view virtual {
        // solhint-disable-previous-line no-empty-blocks
    }
}

// File: contracts/crowdsale/validation/TimedCrowdsale.sol

pragma solidity ^0.8.0;



/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
abstract contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 internal _openingTime;
    uint256 private _closingTime;
    uint256 private _secondarySaleTime;
    /**
     * Event for crowdsale extending
     * @param newClosingTime new closing time
     * @param prevClosingTime old closing time
     */
    event TimedCrowdsaleExtended(uint256 prevClosingTime, uint256 newClosingTime);

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), "TimedCrowdsale: not open");
        _;
    }

     /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param __openingTime Crowdsale opening time
     * @param __closingTime Crowdsale closing time
     * @param __secondarySaleTime Crowdsale secondary time
     */
    constructor (uint256 __openingTime, uint256 __secondarySaleTime, uint256 __closingTime) {
        // solhint-disable-next-line not-rely-on-time
        require(__openingTime >= block.timestamp, "TimedCrowdsale: opening time is before current time");
        // solhint-disable-next-line max-line-length
        require(__secondarySaleTime > __openingTime, "TimedCrowdsale: opening time is not before secondary sale time");
        // solhint-disable-next-line max-line-length
        require(__closingTime > __secondarySaleTime, "TimedCrowdsale: secondary sale time is not before closing time");

        _openingTime = __openingTime;
        _closingTime = __closingTime;
        _secondarySaleTime = __secondarySaleTime;
    }

    /**
     * @return the crowdsale opening time.
     */
    function openingTime() public view virtual returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view virtual returns (uint256) {
        return _closingTime;
    }

       /**
     * @return the crowdsale secondary sale time.
     */
    function secondaryTime() public view virtual returns (uint256) {
        return _secondarySaleTime;
    }



    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view virtual returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view virtual returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;
    }

    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    function _extendTime(uint256 newClosingTime) internal virtual {
        require(!hasClosed(), "TimedCrowdsale: already closed");
        // solhint-disable-next-line max-line-length
        require(newClosingTime > _closingTime, "TimedCrowdsale: new closing time is before current closing time");

        emit TimedCrowdsaleExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }
}

// File: contracts/crowdsale/validation/CappedCrowdsale.sol

pragma solidity ^0.8.0;



/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
abstract contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 internal _cap;
    uint256 internal _minted;

    /**
     * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
     * @param cap Max amount of wei to be contributed
     */
    constructor (uint256 cap) {
        require(cap > 0, "CappedCrowdsale: cap is 0");
        _cap = cap;
    }

    /**
     * @return the cap of the crowdsale.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @return the minted of the crowdsale.
     */
    function minted() public view returns (uint256) {
        return _minted;
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return _minted >= _cap;
    }

    function incrementMinted(uint256 amountOfTokens) internal virtual {
        _minted +=  amountOfTokens;
    }

    function currentMinted() public view returns (uint256) {
        return _minted;
    }
}

// File: contracts/OceanIncNFTICO.sol

pragma solidity ^0.8.0;

contract OceanIncNFTICO is Crowdsale, CappedCrowdsale, TimedCrowdsale, Ownable {
    using SafeMath for uint256;

    /* Track investor contributions */
    uint256 public investorHardCap = 10; // 10 NFT
    mapping(address => uint256) public contributions;

    /* Crowdsale Stages */
    enum CrowdsaleStage {
        PreICO,
        ICO
    }

    /* Default to presale stage */
    CrowdsaleStage public stage = CrowdsaleStage.PreICO;

    constructor(
        address payable _wallet,
        IOceanIncNFTToken _token,
        uint256 _cap,
        uint256 _openingTime,
        uint256 _secondarySaleTime,
        uint256 _closingTime
    )
        public
        Crowdsale(_wallet, _token)
        CappedCrowdsale(_cap)
        TimedCrowdsale(_openingTime, _secondarySaleTime, _closingTime)
    {}

    /**
     * @dev Returns the amount contributed so far by a sepecific user.
     * @param _beneficiary Address of contributor
     * @return User contribution so far
     */
    function getUserContribution(address _beneficiary)
        public
        view
        returns (uint256)
    {
        return contributions[_beneficiary];
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect investor min/max funding cap.
     * @param _beneficiary Token purchaser
     */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 mintAmount,
        uint256 weiAmount
    ) internal virtual override onlyWhileOpen {
        // Check how many NFT are minted
        require(currentMinted() <= _cap, "OceanIncNFTICO: cap exceeded");

        require(weiAmount != 0, "OceanIncNFTICO: ETH sent 0");

        require(
            weiAmount.div(mintAmount) == rate(),
            "OceanIncNFTICO: Invalid ETH Amount"
        );

        require(
            _beneficiary != address(0),
            "OceanIncNFTICO: beneficiary zero address"
        );

        // Check max minting limit
        uint256 _existingContribution = contributions[_beneficiary];
        uint256 _newContribution = _existingContribution.add(mintAmount);
        require(
            _newContribution <= investorHardCap,
            "OceanIncNFTICO: No of Mint greater than MaxCap"
        );
        contributions[_beneficiary] = _newContribution;
        incrementMinted(mintAmount);
    }

    function extendTime(uint256 closingTime) public virtual onlyOwner {
        _extendTime(closingTime);
    }

    function extractETH() public virtual {
        wallet().transfer(address(this).balance);
    }

    /**
     * @dev If goal is Reached then change to change to ICO Stage
     * etc.)
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount)
        internal
        virtual
        override
    {
         if ((currentMinted() >= 1250 || block.timestamp > secondaryTime()) && stage == CrowdsaleStage.PreICO) {
            stage = CrowdsaleStage.ICO;
            _rate = 100000000000000000;             // 0.1ETH
            _openingTime = secondaryTime();         // Set opening time to secondary time
        }
        super._updatePurchasingState(_beneficiary, _weiAmount);
    }

    /**
     * @dev enables token transfers, called when owner calls finalize()
     */
    function finalization() public onlyOwner {
        token().renounceMinter();
    }
}