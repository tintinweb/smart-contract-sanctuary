/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.6;



// Part: Context

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

// Part: SafeMath

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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

// Part: ERC20

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/math/SafeMath.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/GSN/Context.sol";

contract ERC20 is Context {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        // _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// Part: Ownable

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

// Part: CrowdCoin

contract CrowdCoin is ERC20{
    address reward_contract_address;
    bool init = false;

    constructor () public ERC20("CrowdCoin", "CWC"){
        // _mint(msg.sender, 100000 * (10 ** uint256(decimals())));
        // owner = msg.sender;
    }

    function set_reward_contract_address(address add)public{
        reward_contract_address = add;
    }

    function init_mint() public{
        require(init == false, 
        "CrowdCoin is already been minted");
        _mint(reward_contract_address, 10000000 * (10 ** uint256(decimals())));
        init = true;
    }

    function getBal(address bal) public view returns(uint256){
        return balanceOf(bal);
    }
}

// File: Reward.sol

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/access/Ownable.sol";

contract Reward is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint256;

    struct SurveyReward {
        address survey_owner;
        uint256 budget;
        uint256 target_number;
        uint256 top_perform_threshold;
        uint256 low_perform_threshold;
        uint256 max_reward;
    }

    struct UploadChecksum {
        string survey_title;
        string checksum;
    }

    CrowdCoin crowdcoin;
    address public contract_address;
    address public crowdcoin_address;
    uint256 public create_survey_cost;

    mapping(string => SurveyReward) public survey_rewards; //public survey key -> survey reward
    mapping(address => uint256) public dp_staking_rewards;
    mapping(uint256 => UploadChecksum) public uploadchecksum; // surveyid -> uploadchecksum
    address[] dp_stack;

    event Log_checksum(string survey_key, string space, string checksum);

    constructor() public Ownable() {
        // SAMPLE RECORD
        add_survey_reward(address(this), "PUBLIC_KEY", 10000, 1000, 75, 25);

        contract_address = address(this);
    }

    function set_coin(address _address) public onlyOwner {
        // SET COIN CONTRACT
        crowdcoin_address = _address;
        crowdcoin = CrowdCoin(crowdcoin_address);
        crowdcoin.set_reward_contract_address(contract_address);
        crowdcoin.init_mint(); //this contract account will have 10000000000 coins at the beginning
    }

    function get_max_reward(uint256 budget, uint256 target_number)
        public
        pure
        returns (uint256)
    {
        return budget / target_number;
    }

    function add_survey_reward(
        // SET CONTRACT REWARD DETAILS WHEN SURVEY IS CREATED
        address _survey_owner,
        string memory survey_public_key,
        uint256 _budget,
        uint256 _target_number,
        uint256 _top_perform_threshold,
        uint256 _low_perform_threshold
    ) public {
        uint256 _max_reward = get_max_reward(_budget, _target_number);
        // uint256 _min_reward_multiplier = get_min_reward(_top_perform_threshold, _budget);
        // uint256 _med_reward_multiplier = get_med_reward(_top_perform_threshold, _max_reward);

        survey_rewards[survey_public_key] = SurveyReward({
            survey_owner: _survey_owner,
            budget: _budget,
            target_number: _target_number,
            top_perform_threshold: _top_perform_threshold,
            low_perform_threshold: _low_perform_threshold,
            max_reward: _max_reward
            // min_reward_multiplier : _min_reward_multiplier,
            // med_reward_multiplier : _med_reward_multiplier
        });
    }

    function calculate_reward(
        address dp_address,
        string memory survey_key,
        uint256 performance
    ) public onlyOwner {
        // CALCULATE REWARD OF DATA PROVIDERS BASED ON THEIR PERFORMANCE
        uint256 reward;
        SurveyReward memory survey = survey_rewards[survey_key];
        if (performance >= survey.top_perform_threshold) {
            reward = survey.max_reward;
        } else if (performance <= survey.low_perform_threshold) {
            reward =
                (performance * survey.budget) /
                (survey.target_number * 3 * survey.top_perform_threshold);
        } else {
            reward =
                (performance * survey.budget) /
                (survey.target_number * survey.top_perform_threshold);
        }
        dp_staking_rewards[dp_address] =
            dp_staking_rewards[dp_address] +
            reward;
        dp_stack.push(dp_address);
    }

    function get_dp_stacking(address dp_address) public view returns (uint256) {
        return dp_staking_rewards[dp_address];
    }

    function distribute_all_rewards() public onlyOwner {
        //DISTRIBUTE ALL RECORDED REWARDS AT ONCE (not by survey, probably will call this function every 15 minutes and will transfer all rewards accumulated within the 15 mins)
        for (uint256 i = 0; i < dp_stack.length; i++) {
            address dp = dp_stack[i];
            uint256 received_rewards = dp_staking_rewards[dp] * (1 ether); // if not ganache
            // uint256 received_rewards = dp_staking_rewards[dp]; // if ganache
            if (received_rewards > 0) {
                crowdcoin.transferFrom(contract_address, dp, received_rewards);
            }
            dp_staking_rewards[dp] = 0; //reset dp_staking_rewards balance
        }
        delete dp_stack; //reset dp_stack records
    }

    function create_survey(
        address survey_owner_address,
        string memory survey_public_key,
        uint256 _budget,
        uint256 _target_number,
        uint256 _top_perform_threshold,
        uint256 _low_perform_threshold
    ) public {
        // uint256 sum;
        // sum = create_survey_cost + _budget;
        // // DEDUCT CREATE SURVEY COST + BUDGET FOT THE SURVEY
        // crowdcoin.transferFrom(survey_owner_address, contract_address, sum);
        add_survey_reward(
            survey_owner_address,
            survey_public_key,
            _budget,
            _target_number,
            _top_perform_threshold,
            _low_perform_threshold
        );
    }

    function upload_checksum(
        uint256 survey_id,
        string memory survey_title,
        string memory survey_checksum
    ) public {
        // uint256 sum;
        // sum = create_survey_cost + _budget;
        // // DEDUCT CREATE SURVEY COST + BUDGET FOT THE SURVEY
        // crowdcoin.transferFrom(survey_owner_address, contract_address, sum);
        add_upload_checksum(survey_id, survey_title, survey_checksum);
    }

    function add_upload_checksum(
        uint256 _survey_id,
        // SET CONTRACT REWARD DETAILS WHEN SURVEY IS CREATED
        string memory _survey_title,
        string memory _survey_checksum
    ) public {
        uploadchecksum[_survey_id] = UploadChecksum({
            survey_title: _survey_title,
            checksum: _survey_checksum
        });
    }

    function purchase_coin(address purchase, uint256 amount) public onlyOwner {
        // ADDRESS THAT PURCHASED THE REWARD POINTS
        crowdcoin.transferFrom(contract_address, purchase, amount);
    }

    function get_survey_reward_by_key(
        // SET CONTRACT REWARD DETAILS WHEN SURVEY IS CREATED
        string memory survey_public_key
    )
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    // uint256,
    // uint256
    {
        SurveyReward memory s = survey_rewards[survey_public_key];
        return (
            s.survey_owner,
            s.budget,
            s.target_number,
            s.top_perform_threshold,
            s.low_perform_threshold,
            s.max_reward
            // s.min_reward_multiplier,
            // s.med_reward_multiplier
        );
    }

    function log_checksum(
        string memory survey_key,
        string memory space,
        string memory checksum
    ) public {
        emit Log_checksum(survey_key, space, checksum);
    }
}