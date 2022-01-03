// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";
import "../library/SafeERC20.sol";
import "../library/Console.sol";
import "../library/SafeMath.sol";

contract SignDAOWhitelistIDO is Crowdsale, TimedCrowdsale, Console {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 public merkleRoot60mph;
    bytes32 public merkleRoot80mph;

    // avax amount
    uint256 private personalCap60 = 5 * 10 ** 18;
    // avax amount
    uint256 private personalCap80 = 10 * 10 ** 18;

    // avax amount
    uint256 private personalMinimum = 1 * 10 ** 18;


    enum WL_TYPE {
        WL_NOWL_TYPE,
        WL_60MPH_TYPE,
        WL_80MPH_TYPE
    }

    enum CLAIM_STAGE {
        // cant claim
        CLAIM_STAGE_NO_CLAIM,
        // can claim 1/4
        CLAIM_STAGE_1,
        // can claim 1/2
        CLAIM_STAGE_2,
        // can claim 1/4
        CLAIM_STAGE_3
    }

    CLAIM_STAGE public currentClaimStage;

    // each sign token is INIT_PRICE avax
    //           Sign Amount      * (10 ** 9) -------> the sign digitals
    // (avax digitals / INIT_PRICE) *

    uint256 public constant INIT_PRICE = (10 ** 18 * 5) / 100;

    // the avax max raised amount
    uint256 public constant MAX_IDO_QUOTA = ((60000 * 10 ** 9 * 5) / 100) * 10 ** 9;

    struct Investor {
        WL_TYPE whitelistType;
        // sign amount;
        uint256 purchasedAmount;
        // sign amount
        uint256 claimedAmount;
    }

    event LogEvent(uint256 date, string value);

    /*
         1 - 60mph
         2 - 80mph
       */
    mapping(address => Investor) public whiteListAddressMap;

    bool public emergencyPause;

    /*
      constructor(uint personalCap60_,
          uint personalCap80_,
          bytes32 merkleRoot60mph_,
          bytes32 merkleRoot80mph_,
          uint256 numerator_,
          uint256 denominator_,
          address wallet_,
          IERC20 subject_,
          IERC20 token_,
          uint256 openingTime,
          uint256 closingTime)
      Crowdsale(numerator_, denominator_, wallet_, subject_, token_)
      TimedCrowdsale(openingTime, closingTime)
      {
          merkleRoot60mph = merkleRoot60mph_;
          merkleRoot80mph = merkleRoot80mph_;

          personalCap60 = personalCap60_;
          personalCap80 = personalCap80_;
      } */

    constructor()
    Crowdsale(1, 10 ** 9, address(0), IERC20(address(0)), IERC20(address(0)))
    TimedCrowdsale(0, 0)
    {
        currentClaimStage = CLAIM_STAGE.CLAIM_STAGE_NO_CLAIM;
        emergencyPause = false;
        _owner = msg.sender;
    }

    /**
     * (0.05 * 10 ** 18) avax ---------> (1 * 10 ** 9 ) sign
     */
    function avaxToSign(uint256 avaxAmount_) private pure returns (uint256) {
        return (avaxAmount_ * 100 * (10 ** 9)) / 5 / (10 ** 18);
    }

    /**
     * (100 * 10 ** 9) sign --------> 5 avax
     *   (10 ** 9) * (5 / 100) * (10 ** 18)
     */
    function signToAvax(uint256 signAmount_) private pure returns (uint256) {
        return (signAmount_ * 5 * (10 ** 18)) / 100 / (10 ** 9);
    }

    /**
     *
     */
    function bytesToAddress(bytes32 _input) private pure returns (address) {
        return address(uint160(uint256(_input)));
    }

    function toString(address account) public pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(bytes32 valueBytes32) public pure returns (string memory) {
        return toString(abi.encodePacked(valueBytes32));
    }

    function toString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function toBytes(address a)
    public pure returns (bytes32)
    {
        bytes32 result;
        bytes memory encodedAddress = abi.encodePacked(a);

        for (uint i = 0; i < 32; i++) {
            result |= bytes32(encodedAddress[i] & 0xFF) >> (i * 8);
        }
        return result;
    }

    function checkWhiteListed(
        bytes32[] calldata proof_,
        address investor_,
        uint256[] calldata positions_
    ) public view returns (WL_TYPE) {
        // 1. check merkleRoot (og wl)
        if (verifyAccountInTheMerkleTreeOrNot(
                proof_,
                merkleRoot60mph,
                keccak256(abi.encodePacked(investor_)),
                positions_)
        )
        {
            return WL_TYPE.WL_60MPH_TYPE;
        }

        if (verifyAccountInTheMerkleTreeOrNot(
                proof_,
                merkleRoot80mph,
                keccak256(abi.encodePacked(investor_)),
                positions_)
        )
        {
            return WL_TYPE.WL_80MPH_TYPE;
        }

        // 2. check the additional whiteList mapping (in case any neglected wl)
        if (whiteListAddressMap[investor_].whitelistType == WL_TYPE.WL_60MPH_TYPE) {
            return WL_TYPE.WL_60MPH_TYPE;
        }

        if (whiteListAddressMap[investor_].whitelistType == WL_TYPE.WL_80MPH_TYPE) {
            return WL_TYPE.WL_80MPH_TYPE;
        }

        return WL_TYPE.WL_NOWL_TYPE;
    }

    function setEmergencyPause(bool emergencyPause_) external onlyOwner
    {
        emergencyPause = emergencyPause_;
    }

    function setCurrentClaimStage(CLAIM_STAGE currentClaimStage_) external onlyOwner
    {
        require(currentClaimStage_ == CLAIM_STAGE.CLAIM_STAGE_1 ||
                currentClaimStage_ == CLAIM_STAGE.CLAIM_STAGE_2 ||
                currentClaimStage_ == CLAIM_STAGE.CLAIM_STAGE_3, "Not valid claim stage");

        currentClaimStage = currentClaimStage_;
    }

    function setPersonalCap60(uint256 personalCap60_) external onlyOwner {
        personalCap60 = personalCap60_;
    }

    function setPersonalCap80(uint256 personalCap80_) external onlyOwner {
        personalCap80 = personalCap80_;
    }

    function setPersonalMinimum(uint256 personalMinimum_) external onlyOwner {
        personalMinimum = personalMinimum_;
    }

    function setRoot60mph(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot60mph = merkleRoot_;
    }

    function setRoot80mph(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot80mph = merkleRoot_;
    }

    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }

    /**
     * check how many Sign tokens the investors can claim
     */
    function checkWalletIDOBalance(address investor)
    public
    view
    returns (uint256)
    {
        require(
            whiteListAddressMap[investor].whitelistType != WL_TYPE.WL_NOWL_TYPE,
            "This investor didn't purchase"
        );

        return
        (whiteListAddressMap[investor].purchasedAmount -
        whiteListAddressMap[investor].claimedAmount) / 10 ** 9;
    }

    /**
     * This function is for verifying if the address is in the original wl.
     */
    function verifyAccountInTheMerkleTreeOrNot(
        bytes32[] calldata proof_,
        bytes32 root_,
        bytes32 leaf_,
        uint256[] calldata positions_
    ) public pure returns (bool) {
        bytes32 computedHash = leaf_;

        for (uint256 i; i < proof_.length; i++) {
            bytes32 proofElement = proof_[i];

            if (positions_[i] == 1) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == root_;
    }

    /**
     * The amount should be the exact amount for the original ERC20 token
     * The amount is the amount of avax
     */
    function buyTokens(
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256[] calldata positions_
    ) external onlyWhileOpen nonReentrant {
        log("Check the map", whiteListAddressMap[msg.sender].purchasedAmount);
        require(amount > 0, "SignDAOIDO: amount is 0");
        require(!emergencyPause, "SignDAOIDO: emergency paused");
        require(amount >= personalMinimum, "SignDAOIDO: at least buy 1 avax");

        require(subjectRaised < MAX_IDO_QUOTA, "Already raised max supply");

        WL_TYPE wlResult = checkWhiteListed(merkleProof, msg.sender, positions_);


        if (wlResult == WL_TYPE.WL_NOWL_TYPE) {
            revert("SignDaoIDO: not a license holder.");
        } else if (wlResult == WL_TYPE.WL_60MPH_TYPE) {
            if (
                signToAvax(whiteListAddressMap[msg.sender].purchasedAmount) >= personalCap60
            ) {
                revert("SignDaoIDO: 60mph already used up all his quota");
            }

            if (
                amount + signToAvax(whiteListAddressMap[msg.sender].purchasedAmount) >
                personalCap60
            ) {
                amount =
                personalCap60 -
                signToAvax(whiteListAddressMap[msg.sender].purchasedAmount);
            }
        } else if (wlResult == WL_TYPE.WL_80MPH_TYPE) {
            if (
                signToAvax(whiteListAddressMap[msg.sender].purchasedAmount) >=
                personalCap80
            ) {
                revert("SignDaoIDO: 80mph already used up all his quota");
            }

            if (
                amount + signToAvax(whiteListAddressMap[msg.sender].purchasedAmount) >
                personalCap80
            ) {
                amount =
                personalCap80 -
                signToAvax(whiteListAddressMap[msg.sender].purchasedAmount);
            }
        }

        // the amount is AVAX subject
        subject.safeTransferFrom(msg.sender, wallet, amount);

        // update state
        subjectRaised += amount;

        if (whiteListAddressMap[msg.sender].whitelistType == WL_TYPE.WL_NOWL_TYPE) {
            whiteListAddressMap[msg.sender].whitelistType = wlResult;
        }

        whiteListAddressMap[msg.sender].purchasedAmount += avaxToSign(amount);
        emit TokenPurchased(msg.sender, amount);
    }

    /**
     * Allow investors to claim their token when the IDO event ends
     */
    function claim() external nonReentrant
    {
        require(!emergencyPause, "SignDaoIDO: emergency paused");
        require(address(token) != address(0), "SignDaoIDO: token not set");

        if (currentClaimStage == CLAIM_STAGE.CLAIM_STAGE_NO_CLAIM) {
            revert("Sorry, can't claim right now");
        }

        // sign amount
        uint256 claimedAmount = whiteListAddressMap[msg.sender].claimedAmount;
        // sign amount
        uint256 purchasedAmount = whiteListAddressMap[msg.sender].purchasedAmount;

        // sign amount
        uint256 amount = 0;

        if (currentClaimStage == CLAIM_STAGE.CLAIM_STAGE_1) {
            if (claimedAmount >= (purchasedAmount * 1) / 4) {
                revert("SignDaoIDO, only can claim 1/4 in stage 1");
            }

            amount = (purchasedAmount / 4 - claimedAmount);

            token.safeTransferFrom(wallet, msg.sender, amount);
            whiteListAddressMap[msg.sender].claimedAmount += amount;
            emit TokenClaimed(msg.sender, amount);
        }

        if (currentClaimStage == CLAIM_STAGE.CLAIM_STAGE_2) {
            if (claimedAmount >= (purchasedAmount * 3) / 4) {
                revert("SignDaoIDO, only can claim 3/4 in stage 2");
            }

            amount = ((purchasedAmount * 3) / 4 - claimedAmount);

            token.safeTransferFrom(wallet, msg.sender, amount);
            whiteListAddressMap[msg.sender].claimedAmount += amount;
            emit TokenClaimed(msg.sender, amount);
        }

        if (currentClaimStage == CLAIM_STAGE.CLAIM_STAGE_3) {
            if (
                claimedAmount >= whiteListAddressMap[msg.sender].purchasedAmount * 1
            ) {
                revert("already claimed");
            }
            amount = (purchasedAmount - claimedAmount);
            token.safeTransferFrom(wallet, msg.sender, amount);
            whiteListAddressMap[msg.sender].claimedAmount += amount;
            emit TokenClaimed(msg.sender, amount);
        }
    }

    /**
     * Add investors to the whitelist
     * @param wlInvestor_ The potential inverstor's wallet address to be added.
     * @param wlType_ The whitelist time to be set
     *         default - not whiteListed
     *         1 - 60mph
     *         2 - 80mph
     */
    function setWhitelistAddress(address[] memory wlInvestor_, WL_TYPE wlType_) public onlyOwner
    {
        //maximum investor is 500
        require(wlInvestor_.length <= 500);
        require(wlType_ == WL_TYPE.WL_60MPH_TYPE
            || wlType_ == WL_TYPE.WL_80MPH_TYPE,
            "Not valid white list type");

        for (uint256 i = 0; i < wlInvestor_.length; i++) {
            whiteListAddressMap[wlInvestor_[i]].whitelistType = wlType_;
            whiteListAddressMap[wlInvestor_[i]].purchasedAmount = 0;
            whiteListAddressMap[wlInvestor_[i]].claimedAmount = 0;
        }

        emit LogEvent(block.timestamp, "set whitelist successfully");
    }

    /**
     * get the amount of SIGN token an investor could purchase
     */
    function getLeftPurchasedAmount(
        bytes32[] calldata proof_,
        uint256[] calldata positions_) public view returns (uint)
    {
        WL_TYPE wlType = checkWhiteListed(proof_, msg.sender, positions_);

        if (wlType == WL_TYPE.WL_NOWL_TYPE) {
            return 0;
        }

        else if (wlType == WL_TYPE.WL_60MPH_TYPE)
        {
            return personalCap60 - whiteListAddressMap[msg.sender].purchasedAmount;
        }

        else if (wlType == WL_TYPE.WL_80MPH_TYPE)
        {
            return personalCap80 - whiteListAddressMap[msg.sender].purchasedAmount;
        }
        return 0;
    }

    /**
     * check left to be claimed amount
     */
    function leftClaimableAmount() public view returns (uint)
    {
        uint purchasedTokenAmount = whiteListAddressMap[msg.sender].purchasedAmount;
        uint claimedAmount = whiteListAddressMap[msg.sender].claimedAmount;

        if (purchasedTokenAmount == 0 ||
            whiteListAddressMap[msg.sender].whitelistType == WL_TYPE.WL_NOWL_TYPE ||
            claimedAmount >= purchasedTokenAmount ||
            address(token) == address(0))
        {
            return 0;
        }

        // stage 1
        if (currentClaimStage == CLAIM_STAGE.CLAIM_STAGE_1) {
            if (claimedAmount >= (purchasedTokenAmount * 1) / 4) {
                return 0;
            }
            return purchasedTokenAmount * 1 / 4 - claimedAmount;
        }

        // stage 2
        if (currentClaimStage == CLAIM_STAGE.CLAIM_STAGE_2) {
            if (claimedAmount >= (purchasedTokenAmount * 3) / 4) {
                return 0;
            }
            return purchasedTokenAmount * 3 / 4 - claimedAmount;
        }

        // stage 3
        if (currentClaimStage == CLAIM_STAGE.CLAIM_STAGE_3) {
            if (claimedAmount > purchasedTokenAmount) {
                return 0;
            }
            return purchasedTokenAmount - claimedAmount;
        }
        return 0;
    }

    /**
     *
     */
    function canClaim() public view returns (bool) {
        uint purchasedTokenAmount = whiteListAddressMap[msg.sender].purchasedAmount;

        uint claimedAmount = whiteListAddressMap[msg.sender].claimedAmount;

        uint toBeClaimedAmount;

        // if this msg.sender didn't purchase any
        if (purchasedTokenAmount == 0 ||
            whiteListAddressMap[msg.sender].whitelistType == WL_TYPE.WL_NOWL_TYPE ||
            claimedAmount >= purchasedTokenAmount ||
            address(token) == address(0)
        ) {
            return false;
        }

        // stage 1
        if (currentClaimStage == CLAIM_STAGE.CLAIM_STAGE_1) {
            if (claimedAmount >= (purchasedTokenAmount * 1) / 4) {
                return false;
            }

            toBeClaimedAmount = purchasedTokenAmount * 1 / 4 - claimedAmount;

            if (token.allowance(wallet, address(this)) < toBeClaimedAmount
                || token.balanceOf(wallet) < toBeClaimedAmount)
            {
                return false;
            }
            return true;
        }

        // stage 2
        if (currentClaimStage == CLAIM_STAGE.CLAIM_STAGE_2) {
            if (claimedAmount >= (purchasedTokenAmount * 3) / 4) {
                return false;
            }
            toBeClaimedAmount = purchasedTokenAmount * 3 / 4 - claimedAmount;

            if (token.allowance(wallet, address(this)) < toBeClaimedAmount
                || token.balanceOf(wallet) < toBeClaimedAmount)
            {
                return false;
            }
            return true;
        }

        // stage 3
        if (currentClaimStage == CLAIM_STAGE.CLAIM_STAGE_3) {
            if (claimedAmount >= purchasedTokenAmount * 1) {
                return false;
            }
            toBeClaimedAmount = purchasedTokenAmount - claimedAmount;

            if (token.allowance(wallet, address(this)) < toBeClaimedAmount
                || token.balanceOf(wallet) < toBeClaimedAmount)
            {
                return false;
            }
            return true;
        }

        // default
        return false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

  function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
      return mul( multiplier_, supply_ );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.5;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity >=0.7.5;

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity >=0.7.5;

import "./Context.sol";

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
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity >=0.7.5;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity >=0.7.5;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

contract Console {
    event LogUint(string, uint);
    function log(string memory s , uint x) internal {
    emit LogUint(s, x);
    }
 
    event LogInt(string, int);
    function log(string memory s , int x) internal {
    emit LogInt(s, x);
    }
 
    event LogBytes(string, bytes);
    function log(string memory s , bytes memory x) internal {
    emit LogBytes(s, x);
    }
 
    event LogBytes32(string, bytes32);
    function log(string memory s , bytes32 x) internal {
    emit LogBytes32(s, x);
    }
 
    event LogAddress(string, address);
    function log(string memory s , address x) internal {
    emit LogAddress(s, x);
    }
 
    event LogBool(string, bool);
    function log(string memory s , bool x) internal {
    emit LogBool(s, x);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.5;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.7.5;
import "./Crowdsale.sol";

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
abstract contract TimedCrowdsale is Crowdsale {
    uint public openingTime;
    uint public closingTime;
    bool private timeframeEnabled = false;

    /**
     * Event for crowdsale extending
     * @param newClosingTime new closing time
     * @param prevClosingTime old closing time
     */
    event TimedCrowdsaleExtended(uint prevClosingTime, uint newClosingTime);

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        if (timeframeEnabled == true)
        {
          require(isOpen(), "TimedCrowdsale: not open");
        }
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param openingTime_ Crowdsale opening time
     * @param closingTime_ Crowdsale closing time
     */
    constructor (uint openingTime_, uint closingTime_) {
        openingTime = openingTime_;
        closingTime = closingTime_;
        timeframeEnabled = true;
    }
    function setOpeningTime(uint openingTime_) public onlyOwner() {
        openingTime = openingTime_;
    }

    function setClosingTime(uint closingTime_) public onlyOwner() {
        closingTime = closingTime_;
    }

    /**
     * @dev this is to enable the time frame
     * @param timeframeEnabled_ set the time frame
     */
    function setTimeframeEnabled(bool timeframeEnabled_) public onlyOwner {
        timeframeEnabled = timeframeEnabled_;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        if (!timeframeEnabled) {
            return true;
        }
        else {
            return block.timestamp >= openingTime && block.timestamp <= closingTime;
        }
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        if (timeframeEnabled) {
            return block.timestamp > closingTime;
        } else {
            return false;
        }
    }

    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    function extendTime(uint newClosingTime) external onlyOwner {
        // solhint-disable-next-line max-line-length
        require(newClosingTime > closingTime, "TimedCrowdsale: new closing time is before current closing time");

        emit TimedCrowdsaleExtended(closingTime, newClosingTime);
        closingTime = newClosingTime;
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

import "../library/Context.sol";
import "../library/ReentrancyGuard.sol";
import "../library/IERC20.sol";
import "../library/Ownable.sol";

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with avax. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is Context, ReentrancyGuard, Ownable {
    // The token being sold
    IERC20 public token;

    // The token being used to buy token
    IERC20 public subject;

    // Address where funds are collected
    address public wallet;

    uint public numerator;
    uint public denominator;

    uint public subjectRaised;

    mapping(address => uint) public purchasedAddresses;
    mapping(address => bool) public claimed;

    event TokenPurchased(address indexed user, uint value);
    event TokenClaimed(address indexed user, uint value);

    constructor (uint numerator_, uint denominator_, address wallet_, IERC20 subject_, IERC20 token_) {
        setParameters(numerator_, denominator_, wallet_, subject_, token_);
    }

    function setParameters(
        uint numerator_,
        uint denominator_,
        address wallet_,
        IERC20 subject_,
        IERC20 token_
    ) public onlyOwner {
//        require(numerator_ > 0 && denominator_ > 0, "Crowdsale: rate is 0");
//        require(wallet_ != address(0), "Crowdsale: wallet is the zero address");
//        require(address(subject_) != address(0), "Crowdsale: subject is the zero address");
        numerator = numerator_;
        denominator = denominator_;
        wallet = wallet_;
        token = token_;
        subject = subject_;
    }

    function setToken(IERC20 token_) external onlyOwner
    {
        require(address(token_) != address(0), "Crowdsale: token is the zero address");
        token = token_;
    }

    function setWallet(address newWallet_) external onlyOwner {
        require(address(newWallet_) != address(0), "Crowdsale: new wallet is the zero address");
        wallet = newWallet_;
    }

    function getTokenAmount(uint amount) public view returns (uint) {
        return amount * numerator / denominator;
    }

    function emergencyWithdraw(address token_) external onlyOwner {
        IERC20(token_).transfer(msg.sender, IERC20(token_).balanceOf(address(this)));
    }
}