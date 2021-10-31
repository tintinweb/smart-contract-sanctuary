//SourceUnit: SaleChainCrowdsaleV2.sol

pragma solidity ^0.8.0;

interface MYToken {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface MYChain {
    function participantAmount(address account) external view returns (uint256);
    function parent(address account) external view returns (address);
}

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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract SaleChainCrowdsaleV2 is Ownable {
    using SafeMath for uint256;

    uint256 constant private SCH_RATE_10000_70000 = 103;
    uint256 constant private SCH_RATE_70000_300000 = 107;
    uint256 constant private SCH_RATE_300000_800000 = 114;
    uint256 constant private SCH_RATE_800000_up = 125;

    // Amount of wie for active participant
    uint256 constant private _activationCost = 100000000; // 100 TRX

    // Addresses where funds and token will be collected
    address payable private _acceleratorWallet;
    address payable private _teamFundWallet;
    address private _teamTokenWallet;
    address private _tokenWallet;

    uint256[] private _percentage = [1700, 1300, 700, 500, 250, 150, 100, 100, 75, 50, 50, 25];

    // The last crowdsale contract address
    MYChain _lastChain;

    // The token being sold
    MYToken _token;

    // Amount of wei raised
    uint256 private _weiRaised;

    // Amount of token sold
    uint256 private _totalSold;

    // Mapping from account to amount of participant
    mapping(address => uint256) private _participantAmount;

    // Mapping from account to activation status
    mapping(address => bool) private _participantStatus;

    // Mapping from account to parent participant
    mapping(address => address) private _parent;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param referrer who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, address indexed referrer, uint256 value, uint256 amount);

    /**
     * Event for account activation logging
     * @param beneficiary who actived account
     */
    event AccountActivation(address indexed beneficiary);

    /**
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param teamFundWallet Address where collected funds will be forwarded to
     * @param teamTokenWallet Address where minted tokens will be forwarded to team
     * @param acceleratorWallet Address where collected accelerator funds will be forwarded to
     * @param tokenWallet Address where allowance tokens to be sold
     * @param lastChain Address of the last crowdsale contract
     * @param token Address of the token being sold
     * @param totalSold Amount of the token sold
     */
    constructor (address payable teamFundWallet, address teamTokenWallet, address payable acceleratorWallet, address tokenWallet,
                MYChain lastChain, MYToken token, uint256 totalSold) public
        {
        _teamFundWallet = teamFundWallet;
        _acceleratorWallet = acceleratorWallet;
        _teamTokenWallet = teamTokenWallet;
        _lastChain = lastChain;
        _tokenWallet = tokenWallet;
        _token = token;
        _totalSold = totalSold;
    }

    /**
     * @return the amount of token sold
     */
    function totalSold() public view returns (uint256) {
        return _totalSold;
    }
    
    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        uint256 dec = 10 ** 21;
        return dec.div(_totalSold.mul(2336).sub(4050600000000000));
    }

    /**
     * @dev Getter for the amount of participant by an account.
     */
    function participantAmount(address account) public view returns (uint256) {
        if (_participantAmount[account] > 0)
            return _participantAmount[account];
        else
            return _lastChain.participantAmount(account);
    }

    /**
     * @dev Getter for the status of participant by an account.
     */
    function participantStatus(address account) public view returns (bool) {
        return _participantStatus[account];
    }

    /**
     * @dev Getter the address of parent participant.
     */
    function parent(address account) public view returns (address) {
        if (_parent[account] != address(0))
            return _parent[account];
        else
            return _lastChain.parent(account);
    }

    /**
     * @return the address where accelerator funds will be collected.
     */
    function acceleratorWallet() public view returns (address payable) {
        return _acceleratorWallet;
    }

    /**
     * set the address where accelerator funds will be collected.
     */
    function setAcceleratorWallet(address payable account) public onlyOwner {
        require(account != address(0), "Accelerator wallet is the zero address");
        _acceleratorWallet = account;
    }

    /**
     * @return the address where team funds will be collected.
     */
    function teamFundWallet() public view returns (address payable) {
        return _teamFundWallet;
    }

    /**
     * set the address where team funds will be collected.
     */
    function setTeamFundWallet(address payable account) public onlyOwner {
        require(account != address(0), "Team Fund wallet is the zero address");
        _teamFundWallet = account;
    }

    /**
     * @return the address where team tokens will be collected.
     */
    function teamTokenWallet() public view returns (address) {
        return _teamTokenWallet;
    }

    /**
     * set the address where team tokens will be collected.
     */
    function setTeamTokenWallet(address account) public onlyOwner {
        require(account != address(0), "Team Token wallet is the zero address");
        _teamTokenWallet = account;
    }

    /**
     * @return the address where allowance tokens to be sold.
     */
    function tokenWallet() public view returns (address) {
        return _tokenWallet;
    }

    /**
     * set the address where allowance tokens to be sold.
     */
    function setTokenWallet(address account) public onlyOwner {
        require(account != address(0), "Token wallet is the zero address");
        _tokenWallet = account;
    }

    /**
     * transfer previous chain to the new contract.
     * @param preChainParents Address parent of the last chain
     * @param preChainChild Address participant of the last chain
     * @param amounts uint256 participant amount of the last chain
     */
    function setPreParticipant(address[] memory preChainParents, address[] memory preChainChild, uint256[] memory amounts) public onlyOwner {
        for(uint i = 0; i < preChainParents.length; i++) {
            _parent[preChainChild[i]] = preChainParents[i];
            _participantAmount[preChainChild[i]] = amounts[i];
        }
    }

    /**
     * transfer active Accont the new contract.
     * @param accounts Recipient of the token purchase
     */
    function setActiveAccounts(address[] memory accounts) public onlyOwner {
        for(uint i = 0; i < accounts.length; i++) {
            _participantStatus[accounts[i]] = true;
        }
    }

    /**
     * @dev transfer contract balance to accelerator wallet.
     * This amount may have been sent to the contractor incorrectly and directly
     */
    function transferBalance() public {
        _acceleratorWallet.transfer(address(this).balance);
    }

     /**
     * @dev function to activate account on the chain
     * @param beneficiary Recipient of the token purchase
     */
    function accountActivation(address beneficiary) public payable {
        require(_participantStatus[beneficiary] == false, "Already activated the account");
        require(participantAmount(beneficiary) > 0, "Beneficiary must be participant in crowdsale already");
        require(msg.value >= _activationCost, "Cost of activation must be 100 TRX");
        _acceleratorWallet.transfer(msg.value);
        _participantStatus[beneficiary] = true;
        emit AccountActivation(beneficiary);
    }

     /**
     * @dev function to purchase via reffral account
     * @param beneficiary Recipient of the token purchase
     * @param referrer Refer purchaser to purchase token
     */
    function buyTokensWithRefer(address beneficiary, address referrer) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, referrer, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        _deliverTokens(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, referrer, weiAmount, tokens);

        _updatePurchasingState(beneficiary, referrer, weiAmount);

        _forwardFunds(referrer);
    }

    /**
     * @dev function to revert contributions if the rules are violated
     * @param beneficiary Address performing the token purchase
     * @param referrer Refer purchaser to purchase token
     * @param weiAmount Value in sun involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, address referrer, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Beneficiary is the zero address");
        require(weiAmount >= 500000000, "Contributions must be at least 500 TRX during the crowdsale");
        require(referrer != beneficiary, "Beneficiary participant can't referrer to self");
        require(participantAmount(referrer) > 0, "Referrer participant not exist in the SaleChain!");
        require(parent(beneficiary) == address(0) || parent(beneficiary) == referrer, "Invalid referrer participant");
    }

    /**
     * @dev function to enable a custom phased distribution
     * @param weiAmount Value in sun to be converted into tokens
     * @return Number of tokens that can be purchased with the specified sun amount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 amount = weiAmount.div(1000000).mul(rate());
        if (amount >= 80000000000) {
            return amount.mul(SCH_RATE_800000_up).div(100);
        } else if (amount >= 30000000000) {
            return amount.mul(SCH_RATE_300000_800000).div(100);
        } else if (amount >= 7000000000) {
            return amount.mul(SCH_RATE_70000_300000).div(100);
        } else if (amount >= 1000000000) {
            return amount.mul(SCH_RATE_10000_70000).div(100);
        } else {
            return amount;
        }
    }

    /**
     * @dev function to add functionality for distribution.
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of tokens purchased
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transferFrom(_tokenWallet, beneficiary, tokenAmount);
        _token.transferFrom(_tokenWallet, _teamTokenWallet, tokenAmount.mul(5).div(95));
        _totalSold = _totalSold.add(tokenAmount.add(tokenAmount.mul(5).div(95)));
    }

    /**
     * @dev function to check for validity (current user contributions, etc.)
     * @param beneficiary Address receiving the tokens
     * @param referrer Refer purchaser to purchase token
     * @param weiAmount Value in sun involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, address referrer, uint256 weiAmount) internal {
        if (parent(beneficiary) == address(0)){
            _parent[beneficiary] = referrer;
        }
        _participantAmount[beneficiary] = participantAmount(beneficiary).add(weiAmount);
        _participantStatus[beneficiary] = true;
    }

    /**
     * @dev Determines how TRX is stored/forwarded on purchases.
     * @param referrer Refer purchaser to purchase token
     */
    function _forwardFunds(address referrer) internal {
        uint256 amount = msg.value;
        uint256 relased = 0;
        uint256 levelNo = 0;
        uint256 value = 0;
        address payable ParticipantWallet = payable(referrer);

        while(ParticipantWallet != address(0) && levelNo < 12){
            if (_participantStatus[ParticipantWallet] == true){
                uint256 minAmount = Math.min(amount, participantAmount(ParticipantWallet));
                value = minAmount.mul(_percentage[levelNo]).div(10000);
                relased = relased.add(value);
                ParticipantWallet.transfer(value);
            }
            ParticipantWallet = payable(parent(ParticipantWallet));
            levelNo = levelNo.add(1);
        }

        value = amount.mul(20).div(100);
        _teamFundWallet.transfer(value);
        relased = relased.add(value);

        amount = amount.sub(relased);
        _acceleratorWallet.transfer(amount);
    }
}