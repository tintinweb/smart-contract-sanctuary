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

// Dependency file: contracts/WasabiToken.sol

// pragma solidity >=0.6.6;

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


// Dependency file: contracts/libraries/TransferHelper.sol


// pragma solidity >=0.6.0;

library SushiHelper {
    function deposit(address masterChef, uint256 pid, uint256 amount) internal {
        (bool success, bytes memory data) = masterChef.call(abi.encodeWithSelector(0xe2bbb158, pid, amount));
        require(success && data.length == 0, "SushiHelper: DEPOSIT FAILED");
    }

    function withdraw(address masterChef, uint256 pid, uint256 amount) internal {
        (bool success, bytes memory data) = masterChef.call(abi.encodeWithSelector(0x441a3e70, pid, amount));
        require(success && data.length == 0, "SushiHelper: WITHDRAW FAILED");
    }

    function pendingSushi(address masterChef, uint256 pid, address user) internal returns (uint256 amount) {
        (bool success, bytes memory data) = masterChef.call(abi.encodeWithSelector(0x195426ec, pid, user));
        require(success && data.length != 0, "SushiHelper: WITHDRAW FAILED");
        amount = abi.decode(data, (uint256));
    }

    uint public constant _nullID = 0xffffffffffffffffffffffffffffffff;
    function nullID() internal pure returns(uint) {
        return _nullID;
    }
}


library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// Dependency file: contracts/interface/IWasabi.sol

// pragma solidity >=0.5.0;

interface IWasabi {
    function getOffer(address  _lpToken,  uint index) external view returns (address offer);
    function getOfferLength(address _lpToken) external view returns (uint length);
    function pool(address _token) external view returns (uint);
    function increaseProductivity(uint amount) external;
    function decreaseProductivity(uint amount) external;
    function tokenAddress() external view returns(address);
    function addTakerOffer(address _offer, address _user) external returns (uint);
    function getUserOffer(address _user, uint _index) external view returns (address);
    function getUserOffersLength(address _user) external view returns (uint length);
    function getTakerOffer(address _user, uint _index) external view returns (address);
    function getTakerOffersLength(address _user) external view returns (uint length);
    function offerStatus() external view returns(uint amountIn, address masterChef, uint sushiPid);
    function cancel(address _from, address _sushi, uint amountWasabi) external ;
    function take(address taker,uint amountWasabi) external;
    function payback(address _from) external;
    function close(address _from, uint8 _state, address _sushi) external  returns (address tokenToOwner, address tokenToTaker, uint amountToOwner, uint amountToTaker);
    function upgradeGovernance(address _newGovernor) external;
    function acceptToken() external view returns(address);
    function rewardAddress() external view returns(address);
    function getTokensLength() external view returns (uint);
    function tokens(uint _index) external view returns(address);
    function offers(address _offer) external view returns(address tokenIn, address tokenOut, uint amountIn, uint amountOut, uint expire, uint interests, uint duration);
    function getRateForOffer(address _offer) external view returns (uint offerFeeRate, uint offerInterestrate);
}


// Dependency file: contracts/WasabiOffer.sol

// pragma solidity >=0.5.16;
// import "contracts/libraries/SafeMath.sol";
// import "contracts/libraries/TransferHelper.sol";
// import "contracts/interface/IERC20.sol";
// import "contracts/interface/IWasabi.sol";
// import "contracts/WasabiToken.sol";

interface IMasterChef {
    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function poolLength() external view returns (uint256);
}

contract Offer {
    using SafeMath for uint256;
    //
    enum OfferState {Created, Opened, Taken, Paidback, Expired, Closed}
    address public wasabi;
    address public owner;
    address public taker;
    address public sushi;

    uint8 public state = 0;

    event StateChange(
        uint256 _prev,
        uint256 _curr,
        address from,
        address to,
        address indexed token,
        uint256 indexed amount
    );

    constructor() public {
        wasabi = msg.sender;
    }

    function getState() public view returns (uint256 _state) {
        _state = uint256(state);
    }

    function transferToken(
        address token,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == wasabi, "WASABI OFFER : TRANSFER PERMISSION DENY");
        TransferHelper.safeTransfer(token, to, amount);
    }

    function initialize(
        address _owner,
        address _sushi,
        uint256 sushiPid,
        address tokenIn,
        address masterChef,
        uint256 amountIn
    ) external {
        require(msg.sender == wasabi, "WASABI OFFER : INITIALIZE PERMISSION DENY");
        require(state == 0);
        owner = _owner;
        sushi = _sushi;
        state = 1;
        if (sushiPid != SushiHelper.nullID()) {
            TransferHelper.safeApprove(tokenIn, masterChef, amountIn);
            SushiHelper.deposit(masterChef, sushiPid, amountIn);
        }
    }

    function cancel() public returns (uint256 amount) {
        require(msg.sender == owner, "WASABI OFFER : CANCEL SENDER IS OWNER");
        (uint256 _amount, address _masterChef, uint256 _sushiPid) = IWasabi(
            wasabi
        )
            .offerStatus();
        state = 5;
        if (_sushiPid != SushiHelper.nullID()) {
            SushiHelper.withdraw(_masterChef, _sushiPid, _amount);
        }
        amount = WasabiToken(IWasabi(wasabi).tokenAddress()).mint(address(this));
        IWasabi(wasabi).cancel(msg.sender, sushi, amount);
    }

    function take() external {
        require(state == 1, "WASABI OFFER : TAKE STATE ERROR");
        require(msg.sender != owner, "WASABI OFFER : TAKE SENDER IS OWNER");
        state = 2;
        address tokenAddress = IWasabi(wasabi).tokenAddress();
        uint256 amountWasabi = WasabiToken(tokenAddress).mint(address(this));
        IWasabi(wasabi).take(msg.sender, amountWasabi);
        taker = msg.sender;
    }

    function payback() external {
        require(state == 2, "WASABI: payback");
        state = 3;
        IWasabi(wasabi).payback(msg.sender);

        (uint256 _amount, address _masterChef, uint256 _sushiPid) = IWasabi(
            wasabi
        )
            .offerStatus();

        if (_sushiPid != SushiHelper.nullID()) {
            SushiHelper.withdraw(_masterChef, _sushiPid, _amount);
        }
        uint8 oldState = state;
        state = 5;
        
        IWasabi(wasabi).close(msg.sender, oldState, sushi);
    }

    function close()
        external
        returns (
            address,
            address,
            uint256,
            uint256
        )
    {
        require(state != 5, "WASABI OFFER : TAKE STATE ERROR");
        (uint256 _amount, address _masterChef, uint256 _sushiPid) = IWasabi(
            wasabi
        )
            .offerStatus();
        if (_sushiPid != SushiHelper.nullID()) {
            SushiHelper.withdraw(_masterChef, _sushiPid, _amount);
        }
        uint8 oldState = state;
        state = 5;
        return IWasabi(wasabi).close(msg.sender, oldState, sushi);
    }

    function getEstimatedWasabi() external view returns (uint256 amount) {
        address tokenAddress = IWasabi(wasabi).tokenAddress();
        amount = WasabiToken(tokenAddress).take();
    }

    function getEstimatedSushi() external view returns (uint256 amount) {
        (, address _masterChef, uint256 _sushiPid) = IWasabi(wasabi)
            .offerStatus();
        if(_sushiPid < IMasterChef(_masterChef).poolLength())
        {
            amount = IMasterChef(_masterChef).pendingSushi(
                _sushiPid,
                address(this)
            );    
        }
    }
}


// Root file: contracts/Wasabi.sol

pragma solidity >=0.5.16;
// import 'contracts/interface/IERC20.sol';
// import 'contracts/WasabiToken.sol';
// import 'contracts/WasabiOffer.sol';
// import 'contracts/libraries/TransferHelper.sol';

contract Wasabi is UpgradableGovernance
{
    using SafeMath for uint;
    address public rewardAddress;
    address public tokenAddress;
    address public sushiAddress;
    address public teamAddress;
    address public masterChef;
    address public acceptToken;
    bytes32 public contractCodeHash;
    mapping(address => address[]) public allOffers;
    uint public feeRate;
    uint public interestRate;
    uint public startBlock;

    struct SushiStruct {
        uint val;
        bool isValid;
    }
    
    mapping(address => uint) public offerStats;
    mapping(address => address[]) public userOffers;
    mapping(address => uint) public pool;
    mapping(address => address[]) public takerOffers;
    mapping(address => SushiStruct) public sushiPids;
    address[] public tokens;
  
    struct OfferStruct {
        address tokenIn;
        address tokenOut;
        uint amountIn;
        uint amountOut;
        uint expire;
        uint interests;
        uint duration;
        uint feeRate;
        uint interestrate;
        address owner;
        address taker;
        address masterChef;
        uint sushiPid;
        uint productivity;
    }
    
    mapping(address => OfferStruct) public offers;

    function setPoolShare(address _token, uint _share) requireGovernor public {
        if (pool[_token] == 0) {
            tokens.push(_token);
        }
        pool[_token] = _share;
    }

    function setTeamAddress(address _newAddress) requireGovernor public {
        teamAddress = _newAddress;
    }

    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    function getTokensLength() external view returns (uint) {
        return tokens.length;
    }

    function setFeeRate(uint _feeRate) requireGovernor public  {
        feeRate = _feeRate;
    }

    function setInterestRate(uint _interestRate) requireGovernor public  {
        interestRate = _interestRate;
    }

    function setStartBlock(uint _startBlock) requireGovernor public  {
        startBlock = _startBlock;
    }

    function setSushiPid(address _token, uint _pid) requireGovernor public  {
        sushiPids[_token].val = _pid;
        sushiPids[_token].isValid = true;
    }

    function getRateForOffer(address _offer) external view returns (uint offerFeeRate, uint offerInterestrate) {
        OfferStruct memory offer = offers[_offer];
        offerFeeRate = offer.feeRate;
        offerInterestrate = offer.interestrate;
    }

    event OfferCreated(address indexed _tokenIn, address indexed _tokenOut, uint _amountIn, uint _amountOut, uint _duration, uint _interests, address indexed _offer);
    event OfferChanged(address indexed _offer, uint _state);

    constructor(address _rewardAddress, address _wasabiTokenAddress, address _sushiAddress, address _masterChef, address _acceptToken, address _teamAddress) public  {
        rewardAddress = _rewardAddress;
        teamAddress = _teamAddress;
        tokenAddress = _wasabiTokenAddress;
        sushiAddress = _sushiAddress;
        masterChef = _masterChef;
        feeRate = 100;
        interestRate = 1000;
        acceptToken = _acceptToken;
    }

    function createOffer(
        address[2] memory _addrs,
        uint[4] memory _uints) public returns(address offer, uint productivity) 
    {
        require(_addrs[0] != _addrs[1],     "WASABI: INVALID TOKEN IN&OUT");
        require(_uints[3] < _uints[1],      "WASABI: INVALID INTERESTS");
        require(pool[_addrs[0]] > 0,        "WASABI: INVALID TOKEN");
        require(_uints[1] > 0,              "WASABI: INVALID AMOUNT OUT");
        // require(_tokenOut == 0xdAC17F958D2ee523a2206206994597C13D831ec7, "only support USDT by now.");
        require(_addrs[1] == acceptToken, "WASABI: ONLY USDT SUPPORTED");
        require(block.number >= startBlock, "WASABI: NOT READY");

        bytes memory bytecode = type(Offer).creationCode;
        if (uint(contractCodeHash) == 0) {
            contractCodeHash = keccak256(bytecode);
        }
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, _addrs[0], _addrs[1], _uints[0], _uints[1], _uints[2], _uints[3], block.number));
        assembly {
            offer := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        productivity = pool[_addrs[0]] * _uints[0];
        uint sushiPid = sushiPids[_addrs[0]].isValid ? sushiPids[_addrs[0]].val : SushiHelper.nullID();

        offers[offer] = OfferStruct({
            productivity:productivity,
            tokenIn: _addrs[0],
            tokenOut: _addrs[1],
            amountIn: _uints[0],
            amountOut :_uints[1],
            expire :0,
            interests:_uints[3],
            duration:_uints[2],
            feeRate:feeRate,
            interestrate:interestRate,
            owner:msg.sender,
            taker:address(0),
            masterChef:masterChef,
            sushiPid:sushiPid
        });
        WasabiToken(tokenAddress).increaseProductivity(offer, productivity);
        TransferHelper.safeTransferFrom(_addrs[0], msg.sender, offer, _uints[0]);
        offerStats[offer] = 1;
        Offer(offer).initialize(msg.sender, sushiAddress, sushiPid, _addrs[0], masterChef, _uints[0]);
        
        allOffers[_addrs[0]].push(offer);
    
        userOffers[msg.sender].push(offer);

        emit OfferCreated(_addrs[0], _addrs[1], _uints[0], _uints[1], _uints[2], _uints[3], offer);
    }
    
    function cancel(address _from, address sushi, uint amountWasabi) external {
        require(offerStats[msg.sender] != 0, "WASABI: CANCEL OFFER NOT FOUND");
        OfferStruct storage offer = offers[msg.sender];

        // send mined WASABI to owner.
        if (offer.productivity > 0) {
            WasabiToken(tokenAddress).decreaseProductivity(msg.sender, offer.productivity);
            uint amountWasabiTeam = amountWasabi.mul(1).div(10);
            Offer(msg.sender).transferToken(tokenAddress, teamAddress, amountWasabiTeam);
            Offer(msg.sender).transferToken(tokenAddress, offer.owner, amountWasabi - amountWasabiTeam);
        }

        // send mined SUSHI to owner.
        if(offer.sushiPid != SushiHelper.nullID()) {
            Offer(msg.sender).transferToken(sushi,_from, IERC20(sushi).balanceOf(msg.sender));
        }

        // send collateral to owner.
        Offer(msg.sender).transferToken(offer.tokenIn, offer.owner, offer.amountIn);
        
        OfferChanged(msg.sender, Offer(msg.sender).state());
    }
    
    function take(address _from, uint amountWasabi) external {
        require(offerStats[msg.sender] != 0, "WASABI: TAKE OFFER NOT FOUND");
        OfferStruct storage offer = offers[msg.sender];
        offer.taker = _from;
        offer.expire = offer.duration.add(block.number);

        // send fees to reward address.
        uint platformFee = offer.amountOut.mul(offer.feeRate).div(10000); 
        uint feeAmount = platformFee.add(offer.interests.mul(offer.interestrate).div(10000)); 
        TransferHelper.safeTransferFrom(offer.tokenOut, _from, rewardAddress, feeAmount);
        
        // send lend money to owner.
        uint amountToOwner = offer.amountOut.sub(offer.interests.add(platformFee));
        TransferHelper.safeTransferFrom(offer.tokenOut, _from, offer.owner, amountToOwner); 
        
        // send the rest the the contract.
        TransferHelper.safeTransferFrom(offer.tokenOut, _from, msg.sender, offer.amountOut.sub(amountToOwner).sub(feeAmount));        

        // mint WASABI to the owner and cut 1/10 to the reward address.
        if (offer.productivity > 0) {
            WasabiToken(tokenAddress).decreaseProductivity(msg.sender, offer.productivity);
            uint amountWasabiTeam = amountWasabi.mul(1).div(10);
            Offer(msg.sender).transferToken(tokenAddress, teamAddress, amountWasabiTeam);
            Offer(msg.sender).transferToken(tokenAddress, offer.owner, amountWasabi - amountWasabiTeam);
        }
        
        addTakerOffer(msg.sender, _from);
        OfferChanged(msg.sender, Offer(msg.sender).state());
    }
    

    function payback(address _from) external {
        require(offerStats[msg.sender] != 0, "WASABI: PAYBACK OFFER NOT FOUND");
        OfferStruct storage offer = offers[msg.sender];
        TransferHelper.safeTransferFrom(offer.tokenOut, _from, msg.sender, offer.amountOut);
        OfferChanged(msg.sender, Offer(msg.sender).state());
    }
    
    function close(address _from, uint8 _state, address sushi) external returns (address tokenToOwner, address tokenToTaker, uint amountToOwner, uint amountToTaker) {
        require(offerStats[msg.sender] != 0, "WASABI: CLOSE OFFER NOT FOUND");
        OfferStruct storage offer = offers[msg.sender];
        require(_state == 3 || block.number >= offer.expire, "WASABI: INVALID STATE");
        require(_from == offer.owner || _from == offer.taker, "WASABI: INVALID CALLEE");

        // if paid back.
        if(_state == 3) {
            amountToTaker = offer.amountOut.add(offer.interests.sub(offer.interests.mul(offer.interestrate).div(10000)));
            tokenToTaker = offer.tokenOut;
            Offer(msg.sender).transferToken(tokenToTaker,  offer.taker, amountToTaker);
            amountToOwner = offer.amountIn;
            tokenToOwner = offer.tokenIn;
            Offer(msg.sender).transferToken(tokenToOwner, offer.owner, amountToOwner);
            if(offer.sushiPid != SushiHelper.nullID())
                Offer(msg.sender).transferToken(sushi, offer.owner, IERC20(sushi).balanceOf(msg.sender));
        }
        // deal with if the offer expired.
        else if(block.number >= offer.expire) {
            amountToTaker = offer.amountIn;
            tokenToTaker = offer.tokenIn;
            Offer(msg.sender).transferToken(tokenToTaker, offer.taker, amountToTaker);

            uint  amountRest = IERC20(offer.tokenOut).balanceOf(msg.sender);
            Offer(msg.sender).transferToken(offer.tokenOut, offer.taker, amountRest);
            if(offer.sushiPid != SushiHelper.nullID())
                Offer(msg.sender).transferToken(sushi, offer.taker, IERC20(sushi).balanceOf(msg.sender));
        }
        OfferChanged(msg.sender, Offer(msg.sender).state());
    }
    
    function offerStatus() external view returns(uint amountIn, address _masterChef, uint sushiPid) {
        OfferStruct storage offer = offers[msg.sender];
        amountIn = offer.amountIn;
        _masterChef = offer.masterChef;
        sushiPid = offer.sushiPid;
    }
    
 
    function  getOffer(address  _lpToken,  uint index) external view returns (address offer) {
        offer = allOffers[_lpToken][index];
    }

    function getOfferLength(address _lpToken) external view returns (uint length) {
        length = allOffers[_lpToken].length;
    }

    function getUserOffer(address _user, uint _index) external view returns (address) {
        return userOffers[_user][_index];
    }

    function getUserOffersLength(address _user) external view returns (uint length) {
        length = userOffers[_user].length;
    }

    function addTakerOffer(address _offer, address _user) public returns (uint) {
        require(msg.sender == _offer, 'WASABI: FORBIDDEN');
        takerOffers[_user].push(_offer);
        return takerOffers[_user].length;
    }

    function getTakerOffer(address _user, uint _index) external view returns (address) {
        return takerOffers[_user][_index];
    }

    function getTakerOffersLength(address _user) external view returns (uint length) {
        length = takerOffers[_user].length;
    }
}