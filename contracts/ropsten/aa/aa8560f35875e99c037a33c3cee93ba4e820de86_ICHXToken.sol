pragma solidity 0.4.24;

// File: contracts/commons/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: contracts/flavours/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions". It has two-stage ownership transfer.
 */
contract Ownable {

    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Allows the current owner to prepare transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// File: contracts/flavours/Lockable.sol

/**
 * @title Lockable
 * @dev Base contract which allows children to
 *      implement main operations locking mechanism.
 */
contract Lockable is Ownable {
    event Lock();
    event Unlock();

    bool public locked = false;

    /**
     * @dev Modifier to make a function callable
    *       only when the contract is not locked.
     */
    modifier whenNotLocked() {
        require(!locked);
        _;
    }

    /**
     * @dev Modifier to make a function callable
     *      only when the contract is locked.
     */
    modifier whenLocked() {
        require(locked);
        _;
    }

    /**
     * @dev called by the owner to locke, triggers locked state
     */
    function lock() public onlyOwner whenNotLocked {
        locked = true;
        emit Lock();
    }

    /**
     * @dev called by the owner
     *      to unlock, returns to unlocked state
     */
    function unlock() public onlyOwner whenLocked {
        locked = false;
        emit Unlock();
    }
}

// File: contracts/base/BaseFixedERC20Token.sol

contract BaseFixedERC20Token is Lockable {
    using SafeMath for uint;

    /// @dev ERC20 Total supply
    uint public totalSupply;

    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) private allowed;

    /// @dev Fired if token is transferred according to ERC20 spec
    event Transfer(address indexed from, address indexed to, uint value);

    /// @dev Fired if token withdrawal is approved according to ERC20 spec
    event Approval(address indexed owner, address indexed spender, uint value);

    /**
     * @dev Gets the balance of the specified address
     * @param owner_ The address to query the the balance of
     * @return An uint representing the amount owned by the passed address
     */
    function balanceOf(address owner_) public view returns (uint balance) {
        return balances[owner_];
    }

    /**
     * @dev Transfer token for a specified address
     * @param to_ The address to transfer to.
     * @param value_ The amount to be transferred.
     */
    function transfer(address to_, uint value_) public whenNotLocked returns (bool) {
        require(to_ != address(0) && value_ <= balances[msg.sender]);
        // SafeMath.sub will throw an exception if there is not enough balance
        balances[msg.sender] = balances[msg.sender].sub(value_);
        balances[to_] = balances[to_].add(value_);
        emit Transfer(msg.sender, to_, value_);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from_ address The address which you want to send tokens from
     * @param to_ address The address which you want to transfer to
     * @param value_ uint the amount of tokens to be transferred
     */
    function transferFrom(address from_, address to_, uint value_) public whenNotLocked returns (bool) {
        require(to_ != address(0) && value_ <= balances[from_] && value_ <= allowed[from_][msg.sender]);
        balances[from_] = balances[from_].sub(value_);
        balances[to_] = balances[to_].add(value_);
        allowed[from_][msg.sender] = allowed[from_][msg.sender].sub(value_);
        emit Transfer(from_, to_, value_);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering
     *
     * To change the approve amount you first have to reduce the addresses
     * allowance to zero by calling `approve(spender_, 0)` if it is not
     * already 0 to mitigate the race condition described in:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @param spender_ The address which will spend the funds.
     * @param value_ The amount of tokens to be spent.
     */
    function approve(address spender_, uint value_) public whenNotLocked returns (bool) {
        if (value_ != 0 && allowed[msg.sender][spender_] != 0) {
            revert();
        }
        allowed[msg.sender][spender_] = value_;
        emit Approval(msg.sender, spender_, value_);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender
     * @param owner_ address The address which owns the funds
     * @param spender_ address The address which will spend the funds
     * @return A uint specifying the amount of tokens still available for the spender
     */
    function allowance(address owner_, address spender_) public view returns (uint) {
        return allowed[owner_][spender_];
    }
}

// File: contracts/base/BaseICOToken.sol

/**
 * @dev Not mintable, ERC20 compliant token, distributed by ICO.
 */
contract BaseICOToken is BaseFixedERC20Token {

    /// @dev Available supply of tokens
    uint public availableSupply;

    /// @dev ICO smart contract allowed to distribute public funds for this
    address public ico;

    /// @dev Fired if investment for `amount` of tokens performed by `to` address
    event ICOTokensInvested(address indexed to, uint amount);

    /// @dev ICO contract changed for this token
    event ICOChanged(address indexed icoContract);

    modifier onlyICO() {
        require(msg.sender == ico);
        _;
    }

    /**
     * @dev Not mintable, ERC20 compliant token, distributed by ICO.
     * @param totalSupply_ Total tokens supply.
     */
    constructor(uint totalSupply_) public {
        locked = true;
        totalSupply = totalSupply_;
        availableSupply = totalSupply_;
    }

    /**
     * @dev Set address of ICO smart-contract which controls token
     * initial token distribution.
     * @param ico_ ICO contract address.
     */
    function changeICO(address ico_) public onlyOwner {
        ico = ico_;
        emit ICOChanged(ico);
    }

    /**
     * @dev Assign `amountWei_` of wei converted into tokens to investor identified by `to_` address.
     * @param to_ Investor address.
     * @param amountWei_ Number of wei invested
     * @param ethTokenExchangeRatio_ Number of tokens in 1Eth
     * @return Amount of invested tokens
     */
    function icoInvestmentWei(address to_, uint amountWei_, uint ethTokenExchangeRatio_) public returns (uint);

    function isValidICOInvestment(address to_, uint amount_) internal view returns (bool) {
        return to_ != address(0) && amount_ <= availableSupply;
    }
}

// File: contracts/flavours/SelfDestructible.sol

/**
 * @title SelfDestructible
 * @dev The SelfDestructible contract has an owner address, and provides selfDestruct method
 * in case of deployment error.
 */
contract SelfDestructible is Ownable {

    function selfDestruct(uint8 v, bytes32 r, bytes32 s) public onlyOwner {
        if (ecrecover(prefixedHash(), v, r, s) != owner) {
            revert();
        }
        selfdestruct(owner);
    }

    function originalHash() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
                "Signed for Selfdestruct",
                address(this),
                msg.sender
            ));
    }

    function prefixedHash() internal view returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, originalHash()));
    }
}

// File: contracts/interface/ERC20Token.sol

interface ERC20Token {
    function transferFrom(address from_, address to_, uint value_) external returns (bool);
    function transfer(address to_, uint value_) external returns (bool);
    function balanceOf(address owner_) external returns (uint);
}

// File: contracts/flavours/Withdrawal.sol

/**
 * @title Withdrawal
 * @dev The Withdrawal contract has an owner address, and provides method for withdraw funds and tokens, if any
 */
contract Withdrawal is Ownable {

    // withdraw funds, if any, only for owner
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    // withdraw stuck tokens, if any, only for owner
    function withdrawTokens(address _someToken) public onlyOwner {
        ERC20Token someToken = ERC20Token(_someToken);
        uint balance = someToken.balanceOf(address(this));
        someToken.transfer(owner, balance);
    }
}

// File: contracts/ICHXToken.sol

/**
 * @title ICHX token contract.
 */
contract ICHXToken is BaseICOToken, SelfDestructible, Withdrawal {
    using SafeMath for uint;

    string public constant name = "IceChain";

    string public constant symbol = "ICHX";

    uint8 public constant decimals = 18;

    uint internal constant ONE_TOKEN = 1e18;

    constructor(uint totalSupplyTokens_,
            uint companyTokens_) public
        BaseICOToken(totalSupplyTokens_.mul(ONE_TOKEN)) {
        require(availableSupply == totalSupply);

        balances[owner] = companyTokens_.mul(ONE_TOKEN);

        availableSupply = availableSupply
            .sub(balances[owner]);

        emit Transfer(0, address(this), balances[owner]);
        emit Transfer(address(this), owner, balances[owner]);
    }

    // Disable direct payments
    function() external payable {
        revert();
    }

    /**
     * @dev Assign `amountWei_` of wei converted into tokens to investor identified by `to_` address.
     * @param to_ Investor address.
     * @param amountWei_ Number of wei invested
     * @param ethTokenExchangeRatio_ Number of tokens in 1 Eth
     * @return Amount of invested tokens
     */
    function icoInvestmentWei(address to_, uint amountWei_, uint ethTokenExchangeRatio_) public onlyICO returns (uint) {
        uint amount = amountWei_.mul(ethTokenExchangeRatio_).mul(ONE_TOKEN).div(1 ether);
        require(isValidICOInvestment(to_, amount));
        availableSupply = availableSupply.sub(amount);
        balances[to_] = balances[to_].add(amount);
        emit ICOTokensInvested(to_, amount);
        return amount;
    }
}