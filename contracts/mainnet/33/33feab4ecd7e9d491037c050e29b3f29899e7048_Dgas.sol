pragma solidity >=0.5.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract ERC20Token {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function _transfer(address from, address to, uint value) private {
        require(balanceOf[from] >= value, 'ERC20Token: INSUFFICIENT_BALANCE');
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        if (to == address(0)) { // burn
            totalSupply = totalSupply.sub(value);
        }
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(allowance[from][msg.sender] >= value, 'ERC20Token: INSUFFICIENT_ALLOWANCE');
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

}


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


/*
	The Objective of MintToken is to implement a decentralized staking mechanism, which calculates users' share
	by accumulating productiviy * time. And calculates users revenue from anytime t0 to t1 by the formula below:

        user_accumulated_productivity(time1) - user_accumulated_productivity(time0)
       _____________________________________________________________________________  * (gross_product(t1) - gross_product(t0))
       total_accumulated_productivity(time1) - total_accumulated_productivity(time0)

*/
contract MintToken is ERC20Token, UpgradableProduct, UpgradableGovernance {
    using SafeMath for uint;

    uint public mintCumulation;

    struct Production {
        uint amount;        	// how many tokens could be produced on block basis
        uint total;				// total produced tokens
        uint block;		        // last updated block number
    }

    Production public grossProduct = Production(0, 0, 0);

    struct Productivity {
        uint product;           // user's productivity
        uint total;             // total productivity
        uint block;             // record's block number
        uint user;              // accumulated products
        uint global;            // global accumulated products
        uint gross;             // global gross products
    }

    Productivity public global;
    mapping(address => Productivity)    public users;

    event AmountPerBlockChanged	(uint oldValue, uint newValue);
    event ProductivityIncreased	(address indexed user, uint value);
    event ProductivityDecreased (address indexed user, uint value);

    uint private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
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
    function _updateProductivity(Productivity storage user, uint value, bool increase) private {
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
    }

    // External function call
    // This function adjust how many token will be produced by each block, eg:
    // changeAmountPerBlock(100)
    // will set the produce rate to 100/block.
    function changeAmountPerBlock(uint value) external requireGovernor returns (bool) {
        uint old = grossProduct.amount;
        require(value != old, 'AMOUNT_PER_BLOCK_NO_CHANGE');

        uint product                = _computeBlockProduct();
        grossProduct.total          = grossProduct.total.add(product);
        grossProduct.block          = block.number;
        grossProduct.amount         = value;
        require(grossProduct.total <= uint(-1), 'BLOCK_PRODUCT_OVERFLOW');

        emit AmountPerBlockChanged(old, value);
        return true;
    }

    // External function call
    // This function increase user's productivity and updates the global productivity.
    // the users' actual share percentage will calculated by:
    // Formula:     user_productivity / global_productivity
    function increaseProductivity(address user, uint value) external requireImpl returns (bool) {
        require(value > 0, 'PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO');
        Productivity storage product        = users[user];

        if (product.block == 0) {
            product.gross = grossProduct.total.add(_computeBlockProduct());
        }
        
        _updateProductivity(product, value, true);
        emit ProductivityIncreased(user, value);
        return true;
    }

    // External function call 
    // This function will decreases user's productivity by value, and updates the global productivity
    // it will record which block this is happenning and accumulates the area of (productivity * time)
    function decreaseProductivity(address user, uint value) external requireImpl returns (bool) {
        Productivity storage product = users[user];

        require(value > 0 && product.total >= value, 'INSUFFICIENT_PRODUCTIVITY');
        
        _updateProductivity(product, value, false);
        emit ProductivityDecreased(user, value);
        return true;
    }


    // External function call
    // When user calls this function, it will calculate how many token will mint to user from his productivity * time
    // Also it calculates global token supply from last time the user mint to this time.
    function mint() external lock returns (uint) {
        (uint gp, uint userProduct, uint globalProduct, uint amount) = _computeUserProduct();
        require(amount > 0, 'NO_PRODUCTIVITY');
        Productivity storage product = users[msg.sender];
        product.gross   = gp;
        product.user    = userProduct;
        product.global  = globalProduct;

        balanceOf[msg.sender]   = balanceOf[msg.sender].add(amount);
        totalSupply             = totalSupply.add(amount);
        mintCumulation          = mintCumulation.add(amount);

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

    // Returns how many productivity a user has and global has.
    function getProductivity(address user) external view returns (uint, uint) {
        return (users[user].total, global.total);
    }

    // Returns the current gorss product rate.
    function amountPerBlock() external view returns (uint) {
        return grossProduct.amount;
    }

    // Returns how much a user could earn.
    function take() external view returns (uint) {
        (, , , uint amount) = _computeUserProduct();
        return amount;
    }

    // Returns how much a user could earn plus the giving block number.
    function takes() external view returns (uint, uint) {
        (, , , uint amount) = _computeUserProduct();
        return (amount, block.number);
    }
}

contract Dgas is MintToken {

    constructor() UpgradableProduct() UpgradableGovernance() public {
        name        = 'Demax Gas';
        symbol      = 'DGAS';
        decimals    = 18;
        grossProduct.amount = 100 * (10 ** 18);
        grossProduct.block  = block.number;
    }
}