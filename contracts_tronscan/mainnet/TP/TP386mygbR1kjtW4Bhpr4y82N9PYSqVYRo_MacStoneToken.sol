//SourceUnit: macStone — Token.sol

/*
 *  Our site https://macstone.fund/
 *  
 *  Token MacStome - MCST
 *  It is produced by the TRX staking method, approximate schemes are already available in the open spaces of DEFI.
 *  
 *  Everyone who stakes TRX to mine a token will have the opportunity to increase their percentage in the main MacStone.Fund project up to 5% (+ 2% for staking (0.1% for every 10k TRX) and + 3% for freezing tokens (0.1% for every 1000 MCST)).
 *  
 *  Referral program 5% in TRX from staking by your partner, 10% in tokens from mined by your partner.
 *  
 *  2% of staking will be transferred to the fund contract account.
 *  
 *  Also, for each stage of the steak, 3% will be taken to form a bonus account. The bonus account will be distributed at the end of each stage of token mining in an equal share of freezing token, between those who do not sell (or buy) the mined tokens and freeze them on the contract.
 *  
 *  Staking steps 9
 *  1. 4M tokens for 1 TRX you get 0.0288 MCST per day
 *  2. 3.8M tokens for 1 TRX you get 0.02448 MCST per day
 *  3. 3.6M tokens for 1 TRX you get 0.02016 MCST per day
 *  4. 3.4М tokens for 1 TRX you get 0.01584 MCST per day
 *  5. 3.1М tokens for 1 TRX you get 0.00864 MCST per day
 *  6. 2.8М tokens for 1 TRX you get 0.00432 MCST per day
 *  7. 2.5М tokens for 1 TRX you get 0.00288 MCST per day
 *  8. 2.1М tokens for 1 TRX you get 0.00230 MCST per day
 *  9. 1.7М tokens for 1 TRX you get 0.02016 MCST per day
 */

pragma solidity 0.5.10;

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
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface TRC20 {
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Implementation of the {TRC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
 * allowances. See {TRC20-approve}.
 */
contract ERC20 is Context, TRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _totalSupply = 100000 * (10 ** 8);

    constructor() public {
        _balances[msg.sender] = _totalSupply;
    }

    /**
     * @dev See {TRC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {TRC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {TRC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {TRC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {TRC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {TRC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {TRC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {TRC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

interface HourglassInterface {
    function getFund() external payable;
    function addGameFunds(address player, uint value) external;
}

contract MacStoneToken is ERC20 {   
    struct Stage {
        uint amount;
        uint tokenInBlock;
        uint stakeAmount;
        uint mintAmount;
        uint startBlock;
        uint changeBlock;
        uint endBlock;
        uint bonusAmount;
        uint freezAmount;
    } 
      
    struct Investor {
        bool registered;
        address referrer;
        uint bonusRef;
        uint bonusRefTron;
        uint deposits;
        uint depositAt;
        uint stageAt;
        uint tempTokenAmount;
        uint freezAmount;
        uint freezAt;
        uint stageFreezAt;
        uint tempFreezWithdrawn;
    } 
      
    struct InvestorToFather {
        uint gameValueTRX;
        uint gameValueToken;
        uint gameValueTRXAt;
        uint gameValueTokenAt;
    }

    /* ERC20 constants */
    string public constant name = "MacStone Token";
    string public constant symbol = "MCST";
    uint8 public constant decimals = 8;
    
    uint DAY = 28800;
    uint MIN_DEPOSIT = 1e8;
    uint public numStage = 0;
    uint multTokenFather = 3*10**10;
    uint multTRXFather = 2*10**11;
    uint multFatherDay = 28800 * 7;
    uint divPl = 10**6;
    
    Stage[] public stages;
    
    address payable public owner;
    mapping (address => Investor) public investors;
    mapping (address => InvestorToFather) public investorsFather;
    bool public work = true;
    bool public fatherStatus = true;
    
    modifier checkOwner(){        
        require(msg.sender == owner);
        _;
    }

    modifier fatherActive(){
        require(fatherStatus);
        _;
    }
    
    address public constant _fatherAddress = 0xA8810A4A27c889b4529Ed2df5eA49eF0e1D2f485; 
    HourglassInterface constant fatherContract = HourglassInterface(_fatherAddress);
    
    constructor(address payable _owner) public {
        owner = _owner;
        
        stages.push(Stage( 4000000 * (10 ** 8), 100, 0, 0, block.number, block.number+1, 0, 0, 0));
        stages.push(Stage( 3800000 * (10 ** 8), 85, 0, 0, 0, 0, 0, 0, 0));
        stages.push(Stage( 3600000 * (10 ** 8), 70, 0, 0, 0, 0, 0, 0, 0));
        stages.push(Stage( 3400000 * (10 ** 8), 55, 0, 0, 0, 0, 0, 0, 0));
        stages.push(Stage( 3100000 * (10 ** 8), 30, 0, 0, 0, 0, 0, 0, 0));
        stages.push(Stage( 2800000 * (10 ** 8), 15, 0, 0, 0, 0, 0, 0, 0));
        stages.push(Stage( 2500000 * (10 ** 8), 10, 0, 0, 0, 0, 0, 0, 0));
        stages.push(Stage( 2100000 * (10 ** 8), 8, 0, 0, 0, 0, 0, 0, 0));
        stages.push(Stage( 1700000 * (10 ** 8), 7, 0, 0, 0, 0, 0, 0, 0));
    }
    
    function stakeFund(address referrer) external payable {
        require(msg.value >= MIN_DEPOSIT, "Bad amount");
        require(work, "Staking end");
        
        uint reward = 0;
        
        owner.transfer(msg.value / 10);
        
        if(!investors[msg.sender].registered) {
            
            investors[msg.sender].registered = true;
            
            if(referrer != msg.sender && referrer!=address(0))
                investors[msg.sender].referrer = referrer;
                
        }else{
            investors[msg.sender].tempTokenAmount += stakingResult(msg.sender);
        }
        
        if(investors[msg.sender].referrer != address(0))
            investors[investors[msg.sender].referrer].bonusRefTron += msg.value / 20;
        else
            reward += msg.value / 20;
            
        stages[numStage].stakeAmount += msg.value;
        stages[numStage].bonusAmount += msg.value * 3 / 100;
        
        checkStage();
        
        reward += msg.value * 2 / 100;
        
        if(fatherStatus){
            fatherContract.getFund.value(reward)();
            
            if(investorsFather[msg.sender].gameValueTRXAt!=0 && (investorsFather[msg.sender].gameValueTRXAt + multFatherDay) < block.number){
                investorsFather[msg.sender].gameValueTRX = 0;
                investorsFather[msg.sender].gameValueTRXAt = 0;
            }
            
            if(investorsFather[msg.sender].gameValueTRX < multTRXFather && investorsFather[msg.sender].gameValueTRXAt==0){
                
                uint sendToFatherValue = 0;
                
                if(investorsFather[msg.sender].gameValueTRX + msg.value > multTRXFather)
                    sendToFatherValue = multTRXFather - investorsFather[msg.sender].gameValueTRX;
                else
                    sendToFatherValue = msg.value;
                    
                fatherContract.addGameFunds(msg.sender, sendToFatherValue);
                
                investorsFather[msg.sender].gameValueTRX += msg.value;
                if(investorsFather[msg.sender].gameValueTRX > multTRXFather && investorsFather[msg.sender].gameValueTRXAt==0)
                    investorsFather[msg.sender].gameValueTRXAt = block.number;
            }
            
        }else{
            stages[numStage].bonusAmount += reward; 
        }
        
        investors[msg.sender].stageAt = numStage;
        investors[msg.sender].depositAt = block.number;
        investors[msg.sender].deposits += msg.value;
    }
    
    function stakingResult(address user) public view returns (uint amount){
        Investor storage investor = investors[user];
        
        if(investor.stageAt != numStage){
            
            for (uint i = investor.stageAt; i <= numStage; i++) {
                
                if(i!=numStage && investor.depositAt > stages[i].startBlock && stages[i].endBlock < block.number)
                    amount += (stages[i].endBlock - investor.depositAt)*stages[i].tokenInBlock*investor.deposits / divPl;
                
                if(i!=numStage && investor.depositAt < stages[i].startBlock && stages[i].endBlock < block.number)    
                    amount += (stages[i].endBlock - stages[i].startBlock)*stages[i].tokenInBlock*investor.deposits / divPl;
                        
                if(i == numStage)
                    amount += (block.number - stages[i].startBlock)*stages[i].tokenInBlock*investor.deposits / divPl;
                
            }
        }else{
            if(investor.depositAt < block.number)
                amount = (block.number - investor.depositAt)*stages[numStage].tokenInBlock*investor.deposits / divPl;
        }
    }
    
    function stakingResultLast(address user) public view returns (uint amount){
        Investor storage investor = investors[user];
        
        if(investor.stageAt != numStage)
            amount = (block.number - stages[numStage].startBlock)*stages[numStage].tokenInBlock*investor.deposits / divPl;
        else
            amount = (block.number - investor.depositAt)*stages[numStage].tokenInBlock*investor.deposits / divPl;
    }
    
        uint amount;
        uint tokenInBlock;
        uint stakeAmount;
        uint mintAmount;
        uint startBlock;
        uint changeBlock;
        uint endBlock;
        uint bonusAmount;
        uint freezAmount;
        
    function stakingEndToken() public view returns (uint amount){
        amount = (stages[numStage].amount - (stages[numStage].tokenInBlock*(block.number - stages[numStage].changeBlock)*stages[numStage].stakeAmount / divPl + stages[numStage].mintAmount))/10**8;
    }
    
    function unStakeFund() external {
        
        uint unstakeAmount = investors[msg.sender].deposits;
        uint tokenTempAmount = stakingResult(msg.sender);
        
        if(tokenTempAmount > 0)
            investors[msg.sender].tempTokenAmount += tokenTempAmount;

        investors[msg.sender].stageAt = 0;
        investors[msg.sender].depositAt = 0;
        investors[msg.sender].deposits = 0;
        
        stages[numStage].stakeAmount -= unstakeAmount;
        checkStage();
        
        msg.sender.transfer(unstakeAmount * 80 / 100);
    }
    
    function withdrawnToken() external {
        uint tokenAmount;
        
        tokenAmount = stakingResult(msg.sender);
        
        if(investors[msg.sender].tempTokenAmount > 0){
            tokenAmount += investors[msg.sender].tempTokenAmount;
            investors[msg.sender].tempTokenAmount = 0;
        }     
        
        if(tokenAmount > 0){
            
            investors[msg.sender].depositAt = block.number;
            investors[msg.sender].stageAt = numStage;
            
            if(investors[msg.sender].referrer != address(0)){
                investors[investors[msg.sender].referrer].bonusRef += tokenAmount / 10;
            }
            
            _mint(msg.sender, tokenAmount);
        }
    }
    
    function withdrawnReferrer() external {
        
        if(investors[msg.sender].bonusRef > 0){
            
            _mint(msg.sender, investors[msg.sender].bonusRef);
            investors[msg.sender].bonusRef = 0;
        }
        
        if(investors[msg.sender].bonusRefTron > 0){
            msg.sender.transfer(investors[msg.sender].bonusRefTron);
            investors[msg.sender].bonusRefTron = 0;
        }
    }
    
    function checkStage() internal {
        
        if(work){
            
            if(stages[numStage].endBlock < block.number && stages[numStage].endBlock != 0){
                
                if(numStage == 8)
                    work = false;
                    
                if(numStage < 8){
                    uint oldStadeNum = numStage;
                    numStage += 1;
                    
                    stages[oldStadeNum].mintAmount = stages[oldStadeNum].amount;
                    stages[numStage].startBlock = stages[oldStadeNum].endBlock;
                    stages[numStage].changeBlock = stages[oldStadeNum].endBlock+1;
                    stages[numStage].stakeAmount = stages[oldStadeNum].stakeAmount;
                    stages[numStage].freezAmount = stages[oldStadeNum].freezAmount;
                }
            }
            
            if(stages[numStage].startBlock != stages[numStage].changeBlock && stages[numStage].changeBlock < block.number){
                
                stages[numStage].mintAmount += (block.number - stages[numStage].changeBlock) * stages[numStage].stakeAmount * stages[numStage].tokenInBlock / divPl;
                
                if(stages[numStage].mintAmount > stages[numStage].amount)
                    stages[numStage].mintAmount = stages[numStage].amount;
                    
                stages[numStage].changeBlock = block.number;
                
                if(stages[numStage].stakeAmount!=0)
                    stages[numStage].endBlock = stages[numStage].changeBlock + (stages[numStage].amount - stages[numStage].mintAmount) * divPl / stages[numStage].tokenInBlock / stages[numStage].stakeAmount;
            }
        }
    }
    
    function freezToken(uint amount) external{
        
        _burn(msg.sender, amount);
        
        if(investors[msg.sender].freezAmount > 0){
            uint tempBonus = _freezResult(msg.sender);
            
            if(tempBonus > 0)
                investors[msg.sender].tempFreezWithdrawn += tempBonus;
        }
        
        investors[msg.sender].freezAmount += amount; 
        investors[msg.sender].stageFreezAt = numStage;
        investors[msg.sender].freezAt = block.number;
        
        stages[numStage].freezAmount += amount;
        
        if(fatherStatus){
            
            if(investorsFather[msg.sender].gameValueTokenAt!=0 && (investorsFather[msg.sender].gameValueTokenAt + multFatherDay) < block.number){
                investorsFather[msg.sender].gameValueToken = 0;
                investorsFather[msg.sender].gameValueTokenAt = 0;
            }
            
            if(investorsFather[msg.sender].gameValueToken < multTokenFather && investorsFather[msg.sender].gameValueTokenAt==0){
                
                uint sendToFatherValue = 0;
                uint changeAmount = amount/10**2;
                
                if(investorsFather[msg.sender].gameValueToken + changeAmount >multTokenFather)
                    sendToFatherValue = multTokenFather - investorsFather[msg.sender].gameValueToken;
                else
                    sendToFatherValue = changeAmount;
                    
                fatherContract.addGameFunds(msg.sender, sendToFatherValue*10);
                
                investorsFather[msg.sender].gameValueToken += changeAmount;
                if(investorsFather[msg.sender].gameValueToken > multTokenFather && investorsFather[msg.sender].gameValueTokenAt==0)
                    investorsFather[msg.sender].gameValueTokenAt = block.number;
            }
        }   
        
    }
    
    function _freezResult(address user) public view returns (uint amount){
        Investor storage investor = investors[user];
        
        for (uint i = investor.stageFreezAt; i < numStage; i++) {
                
            if(stages[i].startBlock < investor.freezAt && stages[i].endBlock < block.number) {
                amount += investor.freezAmount * stages[i].bonusAmount * 100 / stages[i].freezAmount / 100;
            }   
        }
    }
    
    function unFreezToken(uint amount) external{
        require(investors[msg.sender].freezAmount >= amount, "Bad amount");
        
        if(investors[msg.sender].freezAmount > 0){
            uint tempBonus = _freezResult(msg.sender);
            
            if(tempBonus > 0)
                investors[msg.sender].tempFreezWithdrawn += tempBonus;
        }        
        
        investors[msg.sender].freezAmount -= amount;
        investors[msg.sender].freezAt = block.number; 
        investors[msg.sender].stageFreezAt = numStage;
        
        stages[numStage].freezAmount -= amount;
        
        _mint(msg.sender, amount);
    }
    
    function withdrawnFreezBonus() external{
        require(investors[msg.sender].tempFreezWithdrawn > 0, "No Freez Bonus");
            msg.sender.transfer(investors[msg.sender].tempFreezWithdrawn);
            investors[msg.sender].tempFreezWithdrawn = 0;
    }
    
    function setFatherActive(bool _status) checkOwner() public{
        fatherStatus = _status;
    }
}