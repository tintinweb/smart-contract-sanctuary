pragma solidity ^0.6.12;

import "./lib/SafeMath.sol";
import "./interfaces/IObelixFarming.sol";

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ObelixToken {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;

    uint256 public _stakedTotalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address payable public owner;

    IObelixFarming public obelixFarming;

    address payable public OBELIXFund = 0x4Ac6D22bBc27677Ed47b5284A3299D25B5F33a54;
    address payable public Maximus = 0xF224f3D60da3eB287c43c780Be7AA3499D1faF75;
    address payable public buybacksUTY = 0x70ecA57C0478F3C3BfAFf082a140eCF84CDad826;
    address payable public buybacksOBELIX = 0x8a24Fef3c74f1557b4BeF51929B8CaA2d4561A98;
    address payable public Founder = 0xBc1a689ECF468920d5d689386668d701D40800e0;
    address payable public SenateCouncil = 0x75f2239D15a774702A34175C32686FF360EBCBdD;

    address public UniswapPair;

    struct Staker {
        uint256 stakedBalance;
        uint256 startTimestamp;
    }

    mapping(address => Staker) public stakers;

    mapping(bytes32 => bool) public profitsDistributed;

    mapping(bytes32 => bool) public profitsDistributedFarmers;

    uint32 public currentProfitsDistributed;

    bool public EnableProfitDistribution;
    uint256 AmountToDistribute;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() public {
        _name = "OBELIX Token";
        _symbol = "OBELIX";
        _decimals = 18;
        owner = msg.sender;
        _totalSupply = 5000E18;
        _balances[address(this)] = 335625E16;
        _balances[OBELIXFund] = 700E18;
        _balances[Founder] = 94375E16;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function DistributeProfitsOBELIX() external {
        require(EnableProfitDistribution, "Distribution is disabled");
        require(
            !getProfitsDistributed(msg.sender),
            "Profits already distributed"
        );

        Staker memory staker = stakers[msg.sender];

        uint256 daysStaked = block.timestamp.sub(staker.startTimestamp) / 86400;

        require(
            daysStaked >= 14,
            "You must stake for 14 days to claim profits"
        );

        uint256 distribution = AmountToDistribute / 2;

        uint256 eth = mulDiv(
            distribution,
            staker.stakedBalance,
            _stakedTotalSupply.add(_balances[UniswapPair])
        );

        setProfitsDistributed(msg.sender);

        msg.sender.transfer(eth);
    }

    function CalculateDistributeProfitsOBELIX(address staker)
        external
        view
        returns (uint256)
    {
        if (!EnableProfitDistribution || getProfitsDistributed(staker)) {
            return 0;
        }
        Staker memory staker = stakers[msg.sender];

        uint256 daysStaked = block.timestamp.sub(staker.startTimestamp) / 86400;

        if (daysStaked >= 14) {
            return 0;
        }

        uint256 distribution = AmountToDistribute / 2;

        uint256 eth = mulDiv(
            distribution,
            staker.stakedBalance,
            _stakedTotalSupply.add(_balances[UniswapPair])
        );
        return eth;
    }

    function StakeOBELIX(uint256 amount) external {
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        Staker storage staker = stakers[msg.sender];
        if (staker.startTimestamp == 0 || staker.stakedBalance == 0) {
            staker.startTimestamp = block.timestamp;
        } else {
            uint256 percent = mulDiv(1000000, amount, staker.stakedBalance); // This is not really 'percent' it is just a number that represents the totalAmount as a fraction of the recipientBalance
            if (percent.add(staker.startTimestamp) > block.timestamp) {
                // We represent the 'percent' or 'penalty' as seconds and add to the recipient's unix time
                staker.startTimestamp = block.timestamp; // Receiving too many tokens resets your holding time
            } else {
                staker.startTimestamp = staker.startTimestamp.add(percent);
            }
        }
        staker.stakedBalance = staker.stakedBalance.add(amount);
        _stakedTotalSupply = _stakedTotalSupply.add(amount);
    }

    function UnstakeOBELIX(uint256 amount) external {
        Staker storage staker = stakers[msg.sender];
        staker.stakedBalance = staker.stakedBalance.sub(amount);
        staker.startTimestamp = block.timestamp;
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _stakedTotalSupply = _stakedTotalSupply.sub(amount);
    }

    function DistributeProfitsOBELIXFund() external {
        require(msg.sender == owner || msg.sender == OBELIXFund);
        require(EnableProfitDistribution, "Distribution is disabled");
        uint256 eth = mulDiv(AmountToDistribute, 8, 100);
        OBELIXFund.transfer(eth);
    }

    function DistributeMaximusFounder() external {
        require(
            msg.sender == owner ||
                msg.sender == Maximus ||
                msg.sender == Founder
        );
        require(EnableProfitDistribution, "Distribution is disabled");
        uint256 eth = mulDiv(AmountToDistribute, 5, 100);
        Maximus.transfer(eth / 2);
        Founder.transfer(eth / 2);
    }

    function DistributeBuybacks() external {
        require(
            msg.sender == owner ||
                msg.sender == buybacksUTY ||
                msg.sender == buybacksOBELIX
        );
        require(EnableProfitDistribution, "Distribution is disabled");
        uint256 eth = mulDiv(AmountToDistribute, 7, 100);
        buybacksOBELIX.transfer(eth / 2);
        buybacksUTY.transfer(eth / 2);
    }

    function DistributeProfitsOBELIXFarmer() external {
        require(EnableProfitDistribution, "Distribution is disabled");
        require(
            !getProfitsDistributedFarmers(msg.sender),
            "Profits already distributed to farmer"
        );

        (uint256 tokens, uint256 startTimestamp) = obelixFarming
            .estimateOBELIXProvidedWithStartTimestamp(msg.sender);

        uint256 daysStaked = block.timestamp.sub(startTimestamp) / 86400;

        require(
            daysStaked >= 14,
            "You must stake for 14 days to claim profits"
        );

        uint256 distribution = AmountToDistribute / 2;

        uint256 eth = mulDiv(
            distribution,
            tokens,
            _stakedTotalSupply.add(_balances[UniswapPair])
        );

        setProfitsDistributedFarmers(msg.sender);

        msg.sender.transfer(eth);
    }

    function CalculateDistributeProfitsOBELIXFarmer(address staker)
        external
        view
        returns (uint256)
    {
        if (!EnableProfitDistribution || getProfitsDistributedFarmers(staker)) {
            return 0;
        }
        (uint256 tokens, uint256 startTimestamp) = obelixFarming
            .estimateOBELIXProvidedWithStartTimestamp(msg.sender);

        uint256 daysStaked = block.timestamp.sub(startTimestamp) / 86400;

        require(
            daysStaked >= 14,
            "You must stake for 14 days to claim profits"
        );

        uint256 distribution = AmountToDistribute / 2;

        uint256 eth = mulDiv(
            distribution,
            tokens,
            _stakedTotalSupply.add(_balances[UniswapPair])
        );
        return eth;
    }

    function DistributeProfitSenateCouncil() external {
        require(msg.sender == owner || msg.sender == SenateCouncil);
        require(EnableProfitDistribution, "Distribution is disabled");
        uint256 eth = mulDiv(AmountToDistribute, 30, 100);
        SenateCouncil.transfer(eth);
    }

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
     * @dev Total number of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function getStakerDaysStaked(address staker)
        external
        view
        returns (uint256)
    {
        return block.timestamp.sub(stakers[staker].startTimestamp) / 86400;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowed[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowed[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }

    function UpdateEnableProfitDistribution(bool _enable) external onlyOwner {
        EnableProfitDistribution = _enable;
        if (_enable == false) {
            AmountToDistribute = 0;
            deleteProfitsDistributed();
        }
    }

    function getProfitsDistributed(address holder)
        internal
        view
        returns (bool)
    {
        bytes32 key = keccak256(
            abi.encodePacked(currentProfitsDistributed, holder)
        );
        return profitsDistributed[key];
    }

    function getProfitsDistributedFarmers(address holder)
        internal
        view
        returns (bool)
    {
        bytes32 key = keccak256(
            abi.encodePacked(currentProfitsDistributed, holder)
        );
        return profitsDistributedFarmers[key];
    }

    function setProfitsDistributedFarmers(address holder) internal {
        bytes32 key = keccak256(
            abi.encodePacked(currentProfitsDistributed, holder)
        );
        profitsDistributedFarmers[key] = true;
    }

    function setProfitsDistributed(address holder) internal {
        bytes32 key = keccak256(
            abi.encodePacked(currentProfitsDistributed, holder)
        );
        profitsDistributed[key] = true;
    }

    function deleteProfitsDistributed() internal {
        currentProfitsDistributed++;
    }

    function TransferOwnership(address payable newOwner) external onlyOwner {
        owner = newOwner;
    }

    function updateObelixFarming(address _farming) external onlyOwner {
        obelixFarming = IObelixFarming(_farming);
    }

    function updateObelixFund(address payable obelixFund) external onlyOwner {
        OBELIXFund = obelixFund;
    }

    function updateUniswapPair(address _UniswapPair) external onlyOwner {
        UniswapPair = _UniswapPair;
    }

    function transferETH(uint256 amount) external onlyOwner {
        owner.transfer(amount);
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        assert(h < z);
        uint256 mm = mulmod(x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        return l * r;
    }

    function fullMul(uint256 x, uint256 y)
        private
        pure
        returns (uint256 l, uint256 h)
    {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    fallback() external payable {
        AmountToDistribute = AmountToDistribute.add(msg.value);
    }

    receive() external payable {
        AmountToDistribute = AmountToDistribute.add(msg.value);
    }
}

pragma solidity 0.6.12;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.12;

interface IObelixFarming {
    function estimateOBELIXProvidedWithStartTimestamp(address _staker) external view returns (uint256, uint256);
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