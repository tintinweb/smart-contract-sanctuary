/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-14
*/

pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED

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
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256 r) {
        require(m != 0, "SafeMath: to ceil number shall not be zero");
        return (a + m - 1) / m * m;
    }
}


// ----------------------------------------------------------------------------
// BEP Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only allowed by owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

// ----------------------------------------------------------------------------
// BEP20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract ICO is Owned {
    using SafeMath for uint256;
    uint256 public decimals = 18;
    address payable InvestmentStorageAddress = 0xFA7466A078f679CAd7b09F7aC949509dC24400de;
    address LEWT = 0xEE5b86e70eE40c7b002a99a9D07194455b5Ec695;
    
    struct PHASE {
        uint256 startDate;
        uint256 endDate;
        uint256 totalTokens;
        uint256 soldTokens;
        uint256 releaseDate;
        uint256 price;
        uint256 minPurchase;
        uint256 maxPurchase;
    }
    mapping(uint256 => PHASE) public phases;
    
    mapping(address => mapping(uint256 => uint256)) public purchased;
    
    event TokenPurchased(address by, uint256 _bnbSent, uint256 _tokensPurchased);
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        owner = 0xF5d9127062ef094389fAE07DA59b55071325824C;
        phases[1].startDate = 1627776000; // 1st august, 2021 12 am gmt
        phases[1].endDate = 1629590399; // 21st august, 2021 11:59 pm gmt
        phases[2].startDate = 1629590400; // 1st august, 2021, 12 am gmt
        phases[2].endDate = 1631318399; // 10 sep, 2021 11:59 pm gmt 
        phases[3].startDate = 1631318400; // 11th sep, 2021 12 am gmt
        phases[3].endDate = 1633046399; // 30th sep, 2021 11:59 pm gmt
        
        phases[1].totalTokens = 1500000 * 10 ** (decimals);
        phases[2].totalTokens = 1000000 * 10 ** (decimals);
        phases[3].totalTokens = 800000 * 10 ** (decimals);
        
        phases[1].releaseDate = 1648771200; // 1st april 2022
        phases[2].releaseDate = 1643673600; // 1st feb 2022
        phases[3].releaseDate = 1635724800; // 1st nov 2021
        
        phases[1].price = 600; // 1 bnb = 600 tokens @ rate of $300 1 token = $0.50
        phases[2].price = 400; // 1 bnb = 400 tokens @ rate of $320 1 token = $0.80
        phases[3].price = 250; // 1 bnb = 250 tokens @ rate of $300 1 token = $1.20
        
        phases[1].minPurchase = 200; // $100 @ rate of $300 1 token = $0.50
        phases[2].minPurchase = 125; // $100 @ rate of $320 1 token = $0.80
        phases[3].minPurchase = 167; // $200 @ rate of $300 1 token = $1.20
        
        phases[1].maxPurchase = 4000; // $2000 @ rate of $300 1 token = $0.50
        phases[2].maxPurchase = 1875; // $1500 @ rate of $320 1 token = $0.80
        phases[3].maxPurchase = 833; // $1000 @ rate of $300 1 token = $1.20
    }
    
    // the contract accepts BNBs
    receive() external payable {
        uint256 tokens = _calculateTokens(msg.value);
        uint256 _p = _getPhase();
        _preValidatePurchase(tokens, _p);
        purchaseToken(tokens, _p);
        InvestmentStorageAddress.transfer(msg.value);
    }
    
    function _preValidatePurchase(uint256 _tokens, uint256 _phase) private view{
        require(purchased[msg.sender][_phase].add(_tokens) > phases[_phase].minPurchase && purchased[msg.sender][_phase].add(_tokens) < phases[_phase].maxPurchase, "Purchase limit exceeds");
    } 
    
    // tokens purchased can be claimed after the release date
    function purchaseToken(uint256 _bnbAmount, uint256 _phase) private {
        purchased[msg.sender][_phase] = purchased[msg.sender][_phase].add(_calculateTokens(_bnbAmount));
        emit TokenPurchased(msg.sender, _bnbAmount, _calculateTokens(_bnbAmount));
    }
    
    function _calculateTokens(uint256 _busdAmount) private view returns(uint256 _tokens){
        uint256 p = _getPhase();
        return _busdAmount.mul(phases[p].price);
    }
    
    function _getPhase() public view returns(uint256 phase){
        if(block.timestamp > phases[1].startDate && block.timestamp <= phases[1].endDate){ //phase 1
            return 1;
        } else if(block.timestamp > phases[2].startDate && block.timestamp <= phases[2].endDate){ //phase 2
            return 2;
        } else if(block.timestamp > phases[3].startDate && block.timestamp <= phases[3].endDate){ //phase 3
            return 3;
        }
    }
    
    function _getClaimableTokens() private returns(uint256 _ct){
        uint256 claimabale;
        if(purchased[msg.sender][3] > 0 && phases[3].releaseDate < block.timestamp){
            claimabale = purchased[msg.sender][3];
            purchased[msg.sender][3] = 0;
        }
        
        if(purchased[msg.sender][2] > 0 && phases[2].releaseDate < block.timestamp){
            claimabale = claimabale.add(purchased[msg.sender][2]);
            purchased[msg.sender][2] = 0;
        }
        
        if(purchased[msg.sender][1] > 0 && phases[1].releaseDate < block.timestamp){
            claimabale = claimabale.add(purchased[msg.sender][1]);
            purchased[msg.sender][1] = 0;
        }
        
        return claimabale;
    }
    
    function ClaimTokens() external {
        uint256 toClaim = _getClaimableTokens();
        require(toClaim > 0, "nothing to be claimed");
        require(IBEP20(LEWT).transfer(msg.sender, toClaim), "Error sending tokens");
    }
}