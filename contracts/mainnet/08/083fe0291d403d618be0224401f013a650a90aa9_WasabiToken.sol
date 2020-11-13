// Dependency file: contracts/interface/IERC20.sol

//SPDX-License-Identifier: MIT
// pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// Dependency file: contracts/interface/ERC2917-Interface.sol

// pragma solidity >=0.6.6;
// import 'contracts/interface/IERC20.sol';

interface IERC2917 is IERC20 {

    /// @dev This emit when interests amount per block is changed by the owner of the contract.
    /// It emits with the old interests amount and the new interests amount.
    event InterestsPerBlockChanged (uint oldValue, uint newValue);

    /// @dev This emit when a users' productivity has changed
    /// It emits with the user's address and the the value after the change.
    event ProductivityIncreased (address indexed user, uint value);

    /// @dev This emit when a users' productivity has changed
    /// It emits with the user's address and the the value after the change.
    event ProductivityDecreased (address indexed user, uint value);

    
    /// @dev Return the current contract's interests rate per block.
    /// @return The amount of interests currently producing per each block.
    function interestsPerBlock() external view returns (uint);

    /// @notice Change the current contract's interests rate.
    /// @dev Note the best practice will be restrict the gross product provider's contract address to call this.
    /// @return The true/fase to notice that the value has successfully changed or not, when it succeed, it will emite the InterestsPerBlockChanged event.
    function changeInterestsPerBlock(uint value) external returns (bool);

    /// @notice It will get the productivity of given user.
    /// @dev it will return 0 if user has no productivity proved in the contract.
    /// @return user's productivity and overall productivity.
    function getProductivity(address user) external view returns (uint, uint);

    /// @notice increase a user's productivity.
    /// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
    /// @return true to confirm that the productivity added success.
    function increaseProductivity(address user, uint value) external returns (uint);

    /// @notice decrease a user's productivity.
    /// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
    /// @return true to confirm that the productivity removed success.
    function decreaseProductivity(address user, uint value) external returns (uint);

    /// @notice take() will return the interests that callee will get at current block height.
    /// @dev it will always calculated by block.number, so it will change when block height changes.
    /// @return amount of the interests that user are able to mint() at current block height.
    function take() external view returns (uint);

    /// @notice similar to take(), but with the block height joined to calculate return.
    /// @dev for instance, it returns (_amount, _block), which means at block height _block, the callee has accumulated _amount of interests.
    /// @return amount of interests and the block height.
    function takeWithBlock() external view returns (uint, uint);

    /// @notice mint the avaiable interests to callee.
    /// @dev once it mint, the amount of interests will transfer to callee's address.
    /// @return the amount of interests minted.
    function mint(address to) external returns (uint);
}


// Dependency file: contracts/libraries/Upgradable.sol

// pragma solidity >=0.5.16;

contract UpgradableProduct {
    address public impl;

    event ImplChanged(address indexed _oldImpl, address indexed _newImpl);

    constructor() public {
        impl = msg.sender;
    }

    modifier requireImpl() {
        require(msg.sender == impl, 'FORBIDDEN');
        _;
    }

    function upgradeImpl(address _newImpl) public requireImpl {
        require(_newImpl != address(0), 'INVALID_ADDRESS');
        require(_newImpl != impl, 'NO_CHANGE');
        address lastImpl = impl;
        impl = _newImpl;
        emit ImplChanged(lastImpl, _newImpl);
    }
}

contract UpgradableGovernance {
    address public governor;

    event GovernorChanged(address indexed _oldGovernor, address indexed _newGovernor);

    constructor() public {
        governor = msg.sender;
    }

    modifier requireGovernor() {
        require(msg.sender == governor, 'FORBIDDEN');
        _;
    }

    function upgradeGovernance(address _newGovernor) public requireGovernor {
        require(_newGovernor != address(0), 'INVALID_ADDRESS');
        require(_newGovernor != governor, 'NO_CHANGE');
        address lastGovernor = governor;
        governor = _newGovernor;
        emit GovernorChanged(lastGovernor, _newGovernor);
    }
}


// Dependency file: contracts/libraries/SafeMath.sol

// pragma solidity ^0.6.0;

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

// Root file: contracts/WasabiToken.sol

pragma solidity >=0.6.6;

// import 'contracts/interface/ERC2917-Interface.sol';
// import 'contracts/libraries/Upgradable.sol';
// import 'contracts/libraries/SafeMath.sol';

/*
    The Objective of ERC2917 Demo is to implement a decentralized staking mechanism, which calculates users' share
    by accumulating productiviy * time. And calculates users revenue from anytime t0 to t1 by the formula below:

        user_accumulated_productivity(time1) - user_accumulated_productivity(time0)
       _____________________________________________________________________________  * (gross_product(t1) - gross_product(t0))
       total_accumulated_productivity(time1) - total_accumulated_productivity(time0)

*/
contract WasabiToken is IERC2917, UpgradableProduct, UpgradableGovernance {
    using SafeMath for uint;

    uint public mintCumulation;
    uint public maxMintCumulation;

    struct Production {
        uint amount;            // how many tokens could be produced on block basis
        uint total;             // total produced tokens
        uint block;             // last updated block number
    }

    Production internal grossProduct = Production(0, 0, 0);

    struct Productivity {
        uint product;           // user's productivity
        uint total;             // total productivity
        uint block;             // record's block number
        uint user;              // accumulated products
        uint global;            // global accumulated products
        uint gross;             // global gross products
    }

    Productivity public global;
    mapping(address => Productivity) public users;

    uint private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // implementation of ERC20 interfaces.
    string override public name;
    string override public symbol;
    uint8 override public decimals = 18;
    uint override public totalSupply;

    mapping(address => uint) override public balanceOf;
    mapping(address => mapping(address => uint)) override public allowance;

    function _transfer(address from, address to, uint value) private {
        require(balanceOf[from] >= value, 'ERC20Token: INSUFFICIENT_BALANCE');
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        if (to == address(0)) { // burn
            totalSupply = totalSupply.sub(value);
        }
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        require(allowance[from][msg.sender] >= value, 'ERC20Token: INSUFFICIENT_ALLOWANCE');
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    // end of implementation of ERC20

    // creation of the interests token.
    constructor(uint _interestsRate, uint _maxMintCumulation) UpgradableProduct() UpgradableGovernance() public {
        name        = "Wasabi Swap";
        symbol      = "WASABI";
        decimals    = 18;

        maxMintCumulation = _maxMintCumulation;
        grossProduct.amount = _interestsRate;
        grossProduct.block  = block.number;
    }

    // When calling _computeBlockProduct() it calculates the area of productivity * time since last time and accumulate it.
    function _computeBlockProduct() private view returns (uint) {
        uint elapsed = block.number.sub(grossProduct.block);
        return grossProduct.amount.mul(elapsed);
    }

    // compute productivity returns total productivity of a user.
    function _computeProductivity(Productivity memory user) private view returns (uint) {
        uint blocks = block.number.sub(user.block);
        return user.total.mul(blocks);
    }

    // update users' productivity by value with boolean value indicating increase  or decrease.
    function _updateProductivity(Productivity storage user, uint value, bool increase) private returns (uint productivity) {
        user.product      = user.product.add(_computeProductivity(user));
        global.product    = global.product.add(_computeProductivity(global));

        require(global.product <= uint(-1), 'GLOBAL_PRODUCT_OVERFLOW');

        user.block      = block.number;
        global.block    = block.number;
        if(increase) {
            user.total   = user.total.add(value);
            global.total = global.total.add(value);
        }
        else {
            user.total   = user.total.sub(value);
            global.total = global.total.sub(value);
        }
        productivity = user.total;
    }

    // External function call
    // This function adjust how many token will be produced by each block, eg:
    // changeAmountPerBlock(100)
    // will set the produce rate to 100/block.
    function changeInterestsPerBlock(uint value) external override requireGovernor returns (bool) {
        uint old = grossProduct.amount;
        require(value != old, 'AMOUNT_PER_BLOCK_NO_CHANGE');

        uint product                = _computeBlockProduct();
        grossProduct.total          = grossProduct.total.add(product);
        grossProduct.block          = block.number;
        grossProduct.amount         = value;
        require(grossProduct.total <= uint(-1), 'BLOCK_PRODUCT_OVERFLOW');

        emit InterestsPerBlockChanged(old, value);
        return true;
    }

    // External function call
    // This function increase user's productivity and updates the global productivity.
    // the users' actual share percentage will calculated by:
    // Formula:     user_productivity / global_productivity
    function increaseProductivity(address user, uint value) external override requireImpl returns (uint) {
        if(mintCumulation >= maxMintCumulation)
            return 0;
        require(value > 0, 'PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO');
        Productivity storage product        = users[user];

        if (product.block == 0) {
            product.gross = grossProduct.total.add(_computeBlockProduct());
            product.global = global.product.add(_computeProductivity(global));
        }
        
        uint _productivity = _updateProductivity(product, value, true);
        emit ProductivityIncreased(user, value);
        return _productivity;
    }

    // External function call 
    // This function will decreases user's productivity by value, and updates the global productivity
    // it will record which block this is happenning and accumulates the area of (productivity * time)
    function decreaseProductivity(address user, uint value) external override requireImpl returns (uint) {
        if(mintCumulation >= maxMintCumulation)
            return 0;
        Productivity storage product = users[user];

        require(value > 0 && product.total >= value, 'INSUFFICIENT_PRODUCTIVITY');
        
        uint _productivity = _updateProductivity(product, value, false);
        emit ProductivityDecreased(user, value);
        return _productivity;
    }


    // External function call
    // When user calls this function, it will calculate how many token will mint to user from his productivity * time
    // Also it calculates global token supply from last time the user mint to this time.
    function mint(address to) external override lock returns (uint) {
        if(mintCumulation >= maxMintCumulation)
            return 0;

        (uint gp, uint userProduct, uint globalProduct, uint amount) = _computeUserProduct();

        if(amount == 0)
            return 0;

        Productivity storage product = users[msg.sender];
        product.gross   = gp;
        product.user    = userProduct;
        product.global  = globalProduct;

        if (mintCumulation.add(amount) > maxMintCumulation) {
            amount = mintCumulation.add(amount).sub(maxMintCumulation);
        }
        balanceOf[to]   = balanceOf[to].add(amount);
        totalSupply     = totalSupply.add(amount);
        mintCumulation  = mintCumulation.add(amount);

        emit Transfer(address(0), msg.sender, amount);
        return amount;
    }

    // Returns how many token he will be able to mint.
    function _computeUserProduct() private view returns (uint gp, uint userProduct, uint globalProduct, uint amount) {
        Productivity memory product    = users[msg.sender];

        gp              = grossProduct.total.add(_computeBlockProduct());
        userProduct     = product.product.add(_computeProductivity(product));
        globalProduct   = global.product.add(_computeProductivity(global));

        uint deltaBlockProduct  = gp.sub(product.gross);
        uint numerator          = userProduct.sub(product.user);
        uint denominator        = globalProduct.sub(product.global);

        if (denominator > 0) {
            amount = deltaBlockProduct.mul(numerator) / denominator;
        }
    }

    function burnAndReward(uint amountBurn, address rewardToken) public returns (uint amountReward) {
        uint totalReward = IERC20(rewardToken).balanceOf(address(this));
        require(totalReward > 0 && totalSupply > 0, "Invalid.");
        require(IERC20(rewardToken).balanceOf(msg.sender) >= amountBurn, "Insufficient.");

        amountReward = amountBurn.mul(totalReward).div(totalSupply);
        _transfer(msg.sender, address(0), amountBurn);
        IERC20(rewardToken).transfer(msg.sender, amountReward);
    }

    // Returns how many productivity a user has and global has.
    function getProductivity(address user) external override view returns (uint, uint) {
        return (users[user].total, global.total);
    }

    // Returns the current gorss product rate.
    function interestsPerBlock() external override view returns (uint) {
        return grossProduct.amount;
    }

    // Returns how much a user could earn.
    function take() external override view returns (uint) {
        if(mintCumulation >= maxMintCumulation)
            return 0;
        (, , , uint amount) = _computeUserProduct();
        return amount;
    }

    // Returns how much a user could earn plus the giving block number.
    function takeWithBlock() external override view returns (uint, uint) {
        if(mintCumulation >= maxMintCumulation)
            return (0, block.number);
        (, , , uint amount) = _computeUserProduct();
        return (amount, block.number);
    }
}