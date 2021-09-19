/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IGenArtInterface {
    function getMaxMintForMembership(uint256 _membershipId)
        external
        view
        returns (uint256);

    function getMaxMintForOwner(address owner) external view returns (uint256);

    function upgradeGenArtTokenContract(address _genArtTokenAddress) external;

    function setAllowGen(bool allow) external;

    function genAllowed() external view returns (bool);

    function isGoldToken(uint256 _membershipId) external view returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _membershipId) external view returns (address);
}

interface IGenArt {
    function getTokensByOwner(address owner)
        external
        view
        returns (uint256[] memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function isGoldToken(uint256 _tokenId) external view returns (bool);
}

contract GenArtTreasury is Ownable {
    struct Partner {
        uint256 vestingAmount;
        uint256 claimedAmount;
        uint256 vestingBegin;
        uint256 vestingEnd;
    }

    using SafeMath for uint256;

    address genartToken;
    address genArtInterfaceAddress;
    address genArtMembershipAddress;
    uint256 vestingBegin;
    uint256 vestingEnd;

    // 100mm total token supply
    uint256 liqTokenAmount = 10_000_000 * 10**18; // 10mm
    uint256 treasuryTokenAmount = 37_000_000 * 10**18; // 37mm
    uint256 teamMemberTokenAmount = 3_750_000 * 10**18; // 4 team members: 15mm
    uint256 standardMemberTokenAmount = 4_000 * 10**18; // 5k members: 20mm
    uint256 goldMemberTokenAmount = 20_000 * 10**18; // 100 gold members: 2mm
    uint256 marketingTokenAmount = 6_000_000 * 10**18; // 6mm
    uint256 partnerTokenAmount = 10_000_000 * 10**18; // 10mm

    uint256 totalOwnerWithdrawAmount = 0; // total amount withdrawn by withdraw function
    uint256 spendPartnerTokens = 0;

    mapping(address => uint256) nonces;
    mapping(address => uint256) partnerClaims;
    mapping(address => uint256) teamClaimedAmount;
    mapping(uint256 => bool) membershipClaims;
    mapping(address => bool) teamMembers;
    mapping(address => Partner) partners;

    constructor(
        address genArtInterfaceAddress_,
        address genArtMembershipAddress_,
        uint256 vestingBegin_,
        uint256 vestingEnd_,
        address teamMember1_,
        address teamMember2_,
        address teamMember3_,
        address teamMember4_
    ) {
        require(
            vestingBegin_ >= block.timestamp,
            "GenArtTreasury: vesting begin too early"
        );
        require(
            vestingEnd_ > vestingBegin_,
            "GenArtTreasury: vesting end too early"
        );
        genArtMembershipAddress = genArtMembershipAddress_;
        genArtInterfaceAddress = genArtInterfaceAddress_;
        vestingBegin = vestingBegin_;
        vestingEnd = vestingEnd_;

        teamMembers[teamMember1_] = true;
        teamMembers[teamMember2_] = true;
        teamMembers[teamMember3_] = true;
        teamMembers[teamMember4_] = true;
    }

    function claimTokensAllMemberships() public {
        uint256[] memory memberships = IGenArt(genArtMembershipAddress)
            .getTokensByOwner(msg.sender);
        for (uint256 i = 0; i < memberships.length; i++) {
            claimTokensMembership(memberships[i]);
        }
    }

    function claimTokensMembership(uint256 membershipId_) public {
        if (!membershipClaims[membershipId_]) {
            address owner = IGenArt(genArtMembershipAddress).ownerOf(
                membershipId_
            );
            bool isGold = IGenArtInterface(genArtInterfaceAddress).isGoldToken(
                membershipId_
            );
            require(
                owner == msg.sender,
                "GenArtTreasury: only owner can claim tokens"
            );
            IERC20(genartToken).transfer(
                owner,
                (isGold ? goldMemberTokenAmount : standardMemberTokenAmount)
            );
            membershipClaims[membershipId_] = true;
        }
    }

    function withdraw(uint256 _amount, address _to) public onlyOwner {
        uint256 maxWithdrawAmount = liqTokenAmount +
            treasuryTokenAmount +
            marketingTokenAmount;
        uint256 newWithdrawAmount = _amount.add(totalOwnerWithdrawAmount);

        require(
            newWithdrawAmount <= maxWithdrawAmount,
            "GenArtTreasury: amount would excceed limit"
        );
        IERC20(genartToken).transfer(_to, _amount);
        totalOwnerWithdrawAmount = newWithdrawAmount;
    }

    function calcVestedAmount(
        uint256 startDate_,
        uint256 endDate_,
        uint256 amount_
    ) public view returns (uint256) {
        if (block.timestamp >= endDate_) {
            return amount_;
        }
        uint256 fractions = amount_.div(endDate_.sub(startDate_));
        return fractions.mul(block.timestamp.sub(startDate_));
    }

    function claimTokensTeamMember(address to_) public {
        address teamMember = msg.sender;

        require(
            teamMembers[teamMember],
            "GenArtTreasury: caller is not team member"
        );
        require(
            teamClaimedAmount[teamMember] < teamMemberTokenAmount,
            "GenArtTreasury: no tokens to claim"
        );
        uint256 vestedAmount = calcVestedAmount(
            vestingBegin,
            vestingEnd,
            teamMemberTokenAmount
        );

        uint256 payoutAmount = vestedAmount.sub(teamClaimedAmount[teamMember]);
        IERC20(genartToken).transfer(to_, payoutAmount);
        teamClaimedAmount[teamMember] = payoutAmount.add(
            teamClaimedAmount[teamMember]
        );
    }

    function claimTokensPartner(address to_) public {
        Partner memory partner = partners[msg.sender];
        require(
            block.number > nonces[msg.sender],
            "GenArtTreasury: another transaction in progress"
        );
        nonces[msg.sender] = block.number;
        require(
            partner.vestingAmount > 0,
            "GenArtTreasury: caller is not partner"
        );
        require(
            partner.claimedAmount < partner.vestingAmount,
            "GenArtTreasury: no tokens to claim"
        );
        uint256 vestedAmount = calcVestedAmount(
            partner.vestingBegin,
            partner.vestingEnd,
            partner.vestingAmount
        );
        uint256 payoutAmount = vestedAmount.sub(partner.claimedAmount);
        IERC20(genartToken).transfer(to_, payoutAmount);
        partners[msg.sender].claimedAmount = payoutAmount.add(
            partner.claimedAmount
        );
    }

    function addPartner(
        address wallet_,
        uint256 vestingBegin_,
        uint256 vestingEnd_,
        uint256 vestingAmount_
    ) public onlyOwner {
        require(
            partners[wallet_].vestingAmount == 0,
            "GenArtTreasury: partner already added"
        );
        require(spendPartnerTokens.add(vestingAmount_) <= partnerTokenAmount);
        partners[wallet_] = Partner({
            vestingBegin: vestingBegin_,
            vestingEnd: vestingEnd_,
            vestingAmount: vestingAmount_,
            claimedAmount: 0
        });

        spendPartnerTokens = spendPartnerTokens.add(vestingAmount_);
    }

    function updateGenArtInterfaceAddress(address newAddress_)
        public
        onlyOwner
    {
        genArtInterfaceAddress = newAddress_;
    }

    function updateGenArtTokenAddress(address newAddress_) public onlyOwner {
        genartToken = newAddress_;
    }
}