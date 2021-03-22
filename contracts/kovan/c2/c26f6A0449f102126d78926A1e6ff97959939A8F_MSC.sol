/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: contracts/Escrow.sol

pragma solidity ^0.5.0;




// client payment
// client payaout

contract Escrow is Ownable {
    IERC20 public token;
    
    mapping (bytes32 => mapping(address => uint)) payments;
    mapping (bytes32 => mapping(address => uint)) payouts;
    
    uint public totalPayouts;
    
    event PayoutCompleted(bytes32 policyId, address customer);
    
    constructor(address _token) public payable {
        token = IERC20(_token);
    }
    
    function processInsurancePayment(address client, bytes32 policyId) external onlyOwner {
        require(payments[policyId][client] > 0, "Premium payment does not exists for client.");
        require(payouts[policyId][client] > 0, "No payout exists for client.");
        uint256 amount = payouts[policyId][client];
        require(token.balanceOf(address(this)) >= amount, "Not enough collateral.");
        
        totalPayouts = totalPayouts + amount;
        payouts[policyId][client] = 0;
        
        token.transfer(address(client), amount);
        emit PayoutCompleted(policyId, client);
    }
    
    function addClientPayment(address client, uint amount, bytes32 policyId, uint claimPayouts) external onlyOwner {
        payments[policyId][client] = amount;
        payouts[policyId][client] = claimPayouts;
    }
    
    function withdrawTokens(address _recipient, uint256 _value) public onlyOwner {
        require(token.balanceOf(address(this)) >= _value, "Insufficient funds");
        token.transfer(_recipient, _value);
    }
    
    function withdrawErc20(IERC20 _token) public onlyOwner {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }
    
    function getClientPayment(bytes32 policyId, address client) public view returns(uint256) {
        return payments[policyId][client];
    }
    
    function getClientPayout(bytes32 policyId, address client) public view returns(uint256) {
        return payouts[policyId][client];
    }
    
    function _killContract(bool _forceKill) external onlyOwner {
        if(_forceKill == false) {
            require(token.balanceOf(address(this)) == 0, "Please withdraw Tokens");
            
        } //Require: TOKEN balances = 0
        selfdestruct(msg.sender); //kill
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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

// File: contracts/FlyionToken.sol

pragma solidity >0.5.0;



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract FlyionToken is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    constructor () public {
        _name = "FlyionNativeToken";
        _symbol = "FlyNt";
        _decimals = 18;

        _mint(msg.sender, 100000000*1e18);
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token for a specified address
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
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param from address The account whose tokens will be burned.
     * @param value uint256 The amount of token to be burned.
     */
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public returns (bool) {
        _mint(to, value);
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
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
    function _approve(address owner, address spender, uint256 value) internal {
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



//=== MERCHANT SPECIFIC FUNCTIONS =====

     /**
     * @dev public function that complements transfer adding bytes32 information about a product
     * Make sure to use the interface functions (below) in your "merchant" smart contract
     * @param shopId The smart contract whose tokens will be transfered to.
     * @param price The amount that will be transfered.
     * @param product The byte32 identifier for the product.
     */
     function buyProduct(address shopId, uint price, bytes32 product) public payable returns (bool success) {
        require(Shop_Interface(shopId)._getProductAvail(product) == true, "Product is not available");  //product is available
        require(Shop_Interface(shopId)._getProductPrice(product) == price, "Please pay the exact price"); //require identical price

        transfer(shopId, price); //payment token transfer
        Shop_Interface(shopId)._deliverProduct(product); //product delivery (triggers event on the shop side)
        return true;
     }

} ///=== END OF TOKEN CONTRACT CODE ===== ///

contract Shop_Interface { //specific interface to call functions coded in the shopId contract. Requirement = 3 functions.
    function _getProductAvail(bytes32 productId) public view returns (bool availability);
    function _getProductPrice(bytes32 productId) public view returns (uint price);
    function _deliverProduct(bytes32 productId) public returns (bool);
}   //NOTE: the shop needs to make sure that the products are listed correctly.

// File: contracts/MSC.sol

pragma solidity ^0.5.0;

///=== INTRODUCTION ====
/*

    Gas LIMIT by default in REMIX is too small. (contract = 4,657,843 gas)
    Note: current ETH mainnet limit is 8,003,923 (23 June 2019)

TESTING:
----------------------------------------------------------

1- [0x]SETUP contracts

TKN: 0xdcb182bd7058d319a339baebf6e8b65fc9d40873
ORC: 0xA85d02D443dE6990067ED011DeCc9b9e0719d8ce

MSC: 0x378B36062D92B1B7C7e32Ba6a0e627E332459E57

2- [TKN]SEND TOKENS TO MSC
3- [ORC]AUTHORIZE MSC in ORACLE contract

4- [MSC]CREATE POLICY    "AFR","100001","150001","600","10","200","2345678910","10"

policy : 0x906ca1323a687ffb08ea4cf907be15a83938607d879b8943c3216b3155ad95f5
flight : 0x2c8353deb12bd046b8cd4a8863afb0ee20dd73e34edb39e2e8b0cfd2bceaac33

5- [MSC]ACTIVATE POLICY
    _updateDelayTime = 0 will ask for callback 10min after _expectedArrDte
    [ORK] check how flight is written into the ORACLIZE variables, get queryId.

6- [TKN]BUY POLICY

7- [MSC]CHECK VARIABLES UPDATE
    policyDetails struct:
        nbClients, nbSeatsSold
        policyStatus = 1

    MasterPolicy struct:
        nbPolicies
        collateralRequired = OK

    tokenBalance:
        should cover collateral requirements


8- [ORC]SIMULATE CALLBACK with uintCallback function, test = 0 (will trigger token transfer)
    _MSCaddress required

    6a- from [ORC]
    6b- form external [0x]


*/
///=====================


///=== IMPORTS =====



///=== INTERFACES & CONTRACTS ===== used to query the other smartcontracts (using their address as parameter)

contract Authorizable is Ownable {

    mapping(address => bool) public authorized;
    address[] public authorizedList;


    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender);
        _;
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        require(_toAdd != address(0));
        authorized[_toAdd] = true;
        authorizedList.push(_toAdd); //push address in the array of authorized addresses
    }

    function removeAuthorized(address _toRemove) onlyOwner public {
        require(_toRemove != address(0));
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

    //experimental added by  Seb
    function removeAllAuthorized() onlyOwner public {
        uint iMax = getNbAuthorizedAddresses();
        for (uint i=0; i<iMax; i++) {authorized[authorizedList[i]] = false;}
        delete authorizedList;
        addAuthorized(msg.sender);
    }
    function getNbAuthorizedAddresses() public view returns(uint count) {
        return authorizedList.length;
    }
}

contract ERC20_Interface {
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function allowance(address owner, address spender) public returns (uint256);
    //event Transfer(address indexed from, address indexed to, uint tokens);
}

contract FlyionOracle_Interface { //Using an interface to interact with the Chainlink (or Oraclize) address (no need to recompile the whole thing)
    function triggerOracle(bytes32 _policyId, string memory _fltNum, uint256 _depDte, uint256 _expectedArrDte, uint256 _updateDelayTime, address _MSCaddress) public;
}

contract IEscrow { //Using an interface to interact with the Oraclize address (no need to recompile the whole thing)
    function withdrawTokens(address _recipient, uint256 _value) public;
    function addClientPayment(address client, uint amount, bytes32 policyId, uint claimPayouts) external;
    function processInsurancePayment(address client, bytes32 policyId) external;
    function transferOwnership(address newOwner) public;
}

///=== CONTRACT =====
contract MSC is Ownable, Authorizable { //remove Ownable? Check bytesize
    using SafeMath for uint256;

    ///--- EVENTS:
    event LogString(string);
    event LogUint256(string, uint256 number);
    event LogBytes32(string, bytes32 identifier);
    event LogAddress(string, address);
    event LogPurchasedProduct(address client, uint256 premiumPaid, bytes32 product);
    event PaymentDue(uint nbCustomers, bytes32 policyId, bytes32 flightId);
    ///--- STRUCTS & MAPPINGS:

    //masterpolicies------------------------------
    struct MasterPolicy {           //The MasterPolicy is a riskclass bucket, this is what gets funded in TOKENS
        uint8 nbPolicies;           //Total mb of nbPolicies in the MSC. ACTIVE ONES ONLY
        uint256 MaxCollateralRequired; //assuming all seats are sold
        uint256 collateralRequired; //Amount of collateral required to pay all the customers
    }

    //flights------------------------------
    struct FlightDetail {
        string fltNum; //name of the flight
        uint256 depDte; //departure date (local time)
        uint256 expectedArrDte; //expected arrival date (local time)
        uint actualArrDte; //actual Arrival Date given by Oracle
        uint256 fltStatus; //flight status (0=unknown, 1=on-time, 2=delayed, 3=cancelled, 4=other). Updated by Oracle or manually during tests
    }

    struct PolicyDetail { // ONE (1) policy = 1 flight  details
        //info
        bytes32 flightId;       // flightId that this policy is targetting (1 per policy)
        uint256 dlyTime;        // delay class proposed (45 or 180min)
        uint256 premium;        // product price. Can be recalibrated
        uint256 claimPayout;    // needs to be recalibrated: from AWS or from ETH -> Claim payment = in the subscription contract
                                // AWS way: means subscription can be ONLY from AWS (not open)
                                // AWS way : requires to segregate addresses & keys -> Creation/Modification/Cancellation vs. Subscription
                                // ETH way : requires a recalibration function (ownerOnly). DO 1st.
        uint expiryDte;         // expiry date of the policy

        //customers
        uint256 nbClients;
        uint256 nbSeatsMax;        //max nb of seats open on this policy
        uint256 nbSeatsSold;    // nbSeats open on this policy

        //control
        //uint rskCls;            //number between 1 and 10 = risk class (replaces "Hi", "Lo")
        uint8 policyStatus;       //0= created and locked, 1= active for subscription, 2= oracle answered (=payment), 3= payment processed
        uint256 claimPayoutBlock; //block# payout has been paid (traceability)
    }

    bytes32 flightId; //Hash of (fltNum, detDte), to be used with FlyionOraclize_Interface
    mapping(bytes32 => FlightDetail) public flightDetails;

    bytes32 policyId; //Hash of (flightId, dlyTime, premiumm, rskCls), used to identify policies and flights
    mapping(bytes32 => PolicyDetail) public policyDetails;

    bytes32[] public ArrayOfPolicies; //to count them and find them easily with this function:

    mapping (uint8 => MasterPolicy) public masterPolicy; //instiantiates the masterPolicies
    //Note: we can setup 128 MasterPolicies in the MSC, we limit to 1 at the moment using masterPolicy[0] in the code


    //--customers
    struct clientsSubscription {
        uint256 datePurchased;
        uint256 premiumPaid;
        uint256 claimPaid; //claimPayout at the moment of the subscription
        uint256 claimPayout;
        uint256 nbSeatsPurchased; //how many this client bought on this policy
    }

    //client subscriptions:
    mapping(address => mapping(bytes32 => clientsSubscription)) public clientsSubscriptions; //key = customers addresses
    //3d mapping (matrix)

    mapping(bytes32 => address[]) public ListOfCustomers; //per policyId
    mapping(address => bytes32[]) public ListofPoliciesSubscribed; //per client address


    //--- Public variables
    address public MscOwner;
    address public tokenAddress;
    address public oracleAddress; //will be payable in real
    address public escrowAddress;

    //MANUAL OVERRIDE:
    uint8 public PAYMT = 4; //used to stop operations from the callback (see MSC code)
                        //default = 4, the full set of operations
    function ___UDATEPAYMENT(uint8 _value) public onlyOwner {
        PAYMT = _value;
    } //allows to test different callback scenarions. PAYMT = 0 to 4 (0 manual step by step), 4= full payment)



    //--- MODIFIERS
    modifier onlyOracle() {
        require(msg.sender == oracleAddress || msg.sender == MscOwner, "only Oracle or Owner can use this function");
        _;
    }

    modifier flightExists(bytes32 _flightId) {
        require(flightDetails[_flightId].depDte > 0 , "Flight does not exist");
        _;
    }

    modifier policyExists(bytes32 _policyId) {
        require(policyDetails[_policyId].flightId[0] != 0 , "Policy does not exist");
        _;
    }

    modifier policyBindedToFlight(bytes32 _policyId, bytes32 _flightId) {
        require(flightDetails[_flightId].depDte > 0 , "Flight does not exist");
        require(policyDetails[_policyId].flightId[0] != 0 , "Policy does not exist");
        require(policyDetails[_policyId].flightId == _flightId , "Policy not attached to Flight");
        _;
    }

    modifier policySoldSeats(bytes32 _policyId) {
        require(policyDetails[_policyId].nbSeatsSold > 0 , "ZERO seats sold");
        _;
    }

    modifier policyPurcheasable(bytes32 _policyId) {
        require(policyDetails[_policyId].policyStatus == 1, "Policy is not Active");
        require(policyDetails[_policyId].expiryDte > block.timestamp-60, "EXPIRED!"); //60sec margin
        require(policyDetails[_policyId].nbSeatsSold < policyDetails[_policyId].nbSeatsMax, "SOLD OUT!");
        _;
    }

    modifier clientPurchasedPolicy(address _client, bytes32 _policyId) {
        require(clientsSubscriptions[_client][_policyId].nbSeatsPurchased > 0 , "Policy not purchased by client");
        _;
    }

    modifier policyCanProcessPayment(bytes32 _policyId) { //can process payment
        require(policyDetails[_policyId].claimPayoutBlock == 0, "Policy payout already happened - INFORMATION");
        require(policyDetails[_policyId].policyStatus == 2,"Policy status is NOT awaiting payment - INFORMATION");
        require(policyDetails[_policyId].nbSeatsSold >= 1, "ZERO seats sold for this Policy - INFORMATION");
        _;
    }

    modifier contractHasEnoughTokens(address _escrowAddress) { //can process payment
        uint256 requiredTokens = masterPolicy[0].collateralRequired;
        require(ERC20_Interface(tokenAddress).balanceOf(_escrowAddress) > requiredTokens, "Not enough collateral");
        _;
    }
    modifier clientEligibleToClaim(address _client, bytes32 _policyId) {
        require(_client != address(0), "Client address is 0x");
        require(clientsSubscriptions[_client][_policyId].claimPaid == 0, "Client already got paid");
        require(clientsSubscriptions[_client][_policyId].nbSeatsPurchased > 0, "Client did not purchase seats");
        _;
    }


    //--- CONSTRUCTOR:
    constructor(address _escrowAddress, address _orcAdr, address _currencyToken) public  {
        MscOwner = msg.sender;
        tokenAddress = _currencyToken; //Update public addresses of the token and the oracle //-> flnTkn Escrow [TODO]
        oracleAddress = _orcAdr;
        escrowAddress = _escrowAddress;

        //Initializes the masterPolicy details (always at ZERO)
        masterPolicy[0].nbPolicies = 0;
        masterPolicy[0].collateralRequired = 0; //not needed (can be calculated) but required for control

        //Authorize contracts to interact with MSC
        addAuthorized(oracleAddress);   //needed for the policy update by oracle (only authorized)
        emit LogString("MSC constructor executed");
    }

    //--- POLICY CREATION:
    //ADMIN: Create a Policy
    function createPolicy(
        string memory _fltNum,      // flightName (string that is FlightAware compatible)
        uint256 _depDte,            // departure date
        uint256 _expectedArrDte,    // arrival date (estimated, can be ZERO at this stage)
        uint256 _dlyTime,           // it's the product Class (example: 45 min or 180min delay)
        uint256 _premium,           // premium for the 45min entry (180min = _premium x2 at this stage)
        uint256 _claimPayout,       // claim payout (if flight is late). Initial instance beofre any recalibration
        uint256 _expiryDte,         // expiration date of the Policy
        uint256 _nbSeatsMax         // nb of seats open on this flight
    ) public onlyOwner
    returns(bytes32 __policyId) {

        if (_expiryDte == 0) {
            _expiryDte = _expectedArrDte - 3600*24*7;
        } //default = 2 weeks before flight arrival

        //calculate
        bytes32 _flightId = createFlightId(_fltNum, _depDte); //Id of the flights
        bytes32 _policyId = createPolicyId(_fltNum, _depDte, _expectedArrDte, _dlyTime, _premium, _claimPayout, _expiryDte, _nbSeatsMax); //Id of the Policy

        // require policy not to already exists
        require(policyDetails[_policyId].flightId != _flightId , "Policy already exists"); //we check if the policy exists

        //update of flight details, using flightId:
        flightDetails[_flightId].fltNum = _fltNum;      //creates an entry in the mapping for this policyID
        flightDetails[_flightId].depDte = _depDte;
        flightDetails[_flightId].expectedArrDte = _expectedArrDte;
        flightDetails[_flightId].actualArrDte = 0;      //unkown at this stage
        flightDetails[_flightId].fltStatus = 0;         //unkown at this stage (0=unknown, 1=on-time, 2=delay, 3=other)

        //update of policy details, using policyId:
        policyDetails[_policyId].flightId = _flightId;  //1 policy => 1 flight, but 1 flight can have multiple policies
        policyDetails[_policyId].dlyTime = _dlyTime;
        policyDetails[_policyId].premium = _premium;
        policyDetails[_policyId].claimPayout = _claimPayout;
        policyDetails[_policyId].expiryDte = _expiryDte;

        policyDetails[_policyId].nbSeatsMax = _nbSeatsMax;

        policyDetails[_policyId].policyStatus = 0;      //policy is created but inactive by default, need to activate it.
        policyDetails[_policyId].claimPayoutBlock = 0;  //initialized

        ArrayOfPolicies.push(_policyId);        //update ArrayOfpolicyDetails

        emit LogBytes32("Policy created", _policyId);
        return (_policyId);
    }


    //ADMIN: Activate a policy = triggers Oracle

    function forcePolicyStatus(bytes32 _policyId , uint8 _policyStatus) public onlyOwner {
        policyDetails[_policyId].policyStatus = _policyStatus;
        if(_policyStatus == 0) {
            masterPolicy[0].nbPolicies --;
            masterPolicy[0].MaxCollateralRequired -= policyDetails[_policyId].claimPayout * policyDetails[_policyId].nbSeatsMax;
            masterPolicy[0].collateralRequired -= policyDetails[_policyId].claimPayout * policyDetails[_policyId].nbSeatsSold;
        }
    }

    function activatePolicy(bytes32 _policyId , uint256 _updateDelayTime, uint _test) public
        onlyAuthorized
        policyExists(_policyId)
    {
        /* Activation triggers the Oracle  (to update the flight info in the future and ask a callback to Oraclize)
        It needs to be activated from the MSC to input the timing for the callback (needs date info)
        (futuredev: instead of calling oraclize twice, use the FLyion_Oracle database to gather info)*/
        require(policyDetails[_policyId].policyStatus == 0, "Policy already activated");

        // 0- update of MSC meta-variables
        masterPolicy[0].nbPolicies ++;   //we only update active policies.
        masterPolicy[0].MaxCollateralRequired += policyDetails[_policyId].claimPayout * policyDetails[_policyId].nbSeatsMax;

        // 1- resolve flight Info from _policyId
        bytes32 _flightId = policyDetails[_policyId].flightId;
        string memory _fltNum = flightDetails[_flightId].fltNum;
        uint256 _depDte = flightDetails[_flightId].depDte;
        uint256 _expectedArrDte = flightDetails[_flightId].expectedArrDte;

        // 3- activate Policy
        policyDetails[_policyId].claimPayoutBlock = 0;  // force claimPayoutDate to zero (allows payment)
        policyDetails[_policyId].policyStatus = 1;      //Policy is now active!!!

        // 4- trigger external call to Oracle (only if _test = 0)

        if(_updateDelayTime == 0){
            _updateDelayTime = _expectedArrDte + (3*3600);
        } //3h after exp.arrival

        if(_test == 0) {
            FlyionOracle_Interface(oracleAddress).triggerOracle(_policyId, _fltNum, _depDte, _expectedArrDte, _updateDelayTime, address(this));
        }

        emit LogBytes32("Policy Activated", _policyId);
    }

    /*  Later, the oracle will perform a callback and will trigger "updateFromOracle" function below:
        -> changePolicyStatus: avoids customers to subscribe once the callback is asked.
        -> updateFlightInformation: update flight arrival date in the MSC _flightId
        -> processPayments: loop ont he existing customers addresses and token transfer.
    we proceed to a MANUAL update for tests */

    //ADMIN:  updateFlight INFORMATION (called from ORACLE)
    function updateFromOracle(
        bytes32 _policyId,
        bytes32 _flightId,
        uint256 _actualArrDte,
        uint8 _fltStatus
        ) public
    onlyAuthorized
    {
        changePolicyStatus(_policyId, 2); //subscriptions closed, ready to pay.
        updateFlightInformation(_flightId, _actualArrDte, _fltStatus); //we can resolve that
        uint nbCustomers = getNbCustomers(_policyId);

        if (nbCustomers == 0 || _fltStatus == 1) {
            changePolicyStatus(_policyId, 3);
            emit LogBytes32("Policy completed", _policyId);
            return;
        }

        if (nbCustomers > 0 && _fltStatus == 2) {
            emit PaymentDue(nbCustomers, _policyId, _flightId);
        }
    }

    function changePolicyStatus(bytes32 _policyId, uint8 _policyStatus) internal policyExists(_policyId) {
        policyDetails[_policyId].policyStatus = _policyStatus; //0= locked, 1= active for subscription, 2= oracle answered (=payment), 3= payment processed
    }

    function updateFlightInformation(bytes32 _flightId, uint256 _actualArrDte, uint8 _fltStatus) internal flightExists(_flightId) {
    //flight details update:
        flightDetails[_flightId].actualArrDte = _actualArrDte;
        flightDetails[_flightId].fltStatus = _fltStatus;
    }

    function processPayments(bytes32 _policyId) public
        onlyAuthorized
        policyCanProcessPayment(_policyId)
        contractHasEnoughTokens(escrowAddress)
        returns(uint256 _nbClientsPaid, uint256 _nbSeatsPaid, uint256 _amountPaid)
    {
        require(PAYMT > 0, "Payments are disabled");
        // 1- loop on clients who subscribed and transfer of tokens
        uint256 nbCustomers = getNbCustomers(_policyId); //getter: see at the end of the code.
        if (nbCustomers > 1) {
            emit LogBytes32("Policy requires transfer", _policyId);
            return (0, 0, 0); //total
        }

        for (uint256 i = 0; i < nbCustomers; i++) {
            address _client = ListOfCustomers[_policyId][i];

            _amountPaid += clientsSubscriptions[_client][_policyId].nbSeatsPurchased*policyDetails[_policyId].claimPayout;
            _nbClientsPaid ++;
            _nbSeatsPaid += clientsSubscriptions[_client][_policyId].nbSeatsPurchased;

            tokenTransferClaimPayout(_client, _policyId, 0); //put test = 0 to actually transfer
        }

        // 3- policy status update & event log
        policyDetails[_policyId].claimPayoutBlock = block.timestamp; //update payout time.
        changePolicyStatus(_policyId, 3); //payments tx have been processed (awaiting mining)
        masterPolicy[0].collateralRequired -= _amountPaid; //update of the collateralRequired in the MSC
        masterPolicy[0].nbPolicies --;

        emit LogBytes32("Policy payout has been processed", _policyId);
        return(_nbClientsPaid, _nbSeatsPaid, _amountPaid); //total
    } //end of payments processing

    function tokenTransferClaimPayout(address _client, bytes32 _policyId, uint8 _test) internal clientEligibleToClaim(_client, _policyId) {

        uint256 _clientPayout = clientsSubscriptions[_client][_policyId].nbSeatsPurchased * policyDetails[_policyId].claimPayout;

        if(_test == 0) {
            IEscrow(escrowAddress).processInsurancePayment(address(_client), _policyId);
        }

        clientsSubscriptions[_client][_policyId].claimPaid = _clientPayout;
        //clientsSubscriptions[_client][_policyId].datePaid = block.timestamp; //future use ?
    }


    //CLIENT: Interaction with Policy. entry point is the PolicyID (because you can have 2 flightId for the same PolicyId)

    // 1- Client purchase (see ERC20_FLY token modification):
    // use 3 standard functions to make the MSC a "merchant" towards the token holders
    function _getProductAvail(bytes32 _productId) public view returns (bool availability) {
        //note: the shop needs to make sure that the products are listed correctly.
        return(policyDetails[_productId].policyStatus == 1);
    }

    function _getProductPrice(bytes32 _productId) public view returns (uint price) {
    //note: the shop needs to make sure that the products are listed correctly.
        return(policyDetails[_productId].premium);
    }


    function clientInsuranceSubscribe(
        address _client,
        bytes32 _policyId,
        uint256 seats
    ) public onlyAuthorized policyPurcheasable(_policyId) returns (bool success) {
        require(seats <= 3, "More then 3 seats");

        //do an actual transfer of tokens for payment (if allowed)
        // ERC20_Interface(tokenAddress).transferFrom(_client, address(this), policyDetails[_policyId].premium);

        //update ListofCustomers ARRAY

        ListOfCustomers[_policyId].push(_client); //for this _policyId we update the client list. (will be used to PAY them)
        policyDetails[_policyId].nbClients++;
        ListofPoliciesSubscribed[_client].push(_policyId); //for this client we update the list of policies he subscribed to

        // key = customers addresses, bytes32 = policyId, bool = true if policy is ongoing, false if not subscribed or paid/resolved
        //money:
        clientsSubscriptions[_client][_policyId].datePurchased = block.timestamp; //latest date
        clientsSubscriptions[_client][_policyId].claimPaid = 0; //no claim paid yet.
        clientsSubscriptions[_client][_policyId].claimPayout = 0; // to calculate payout

        //flight status & seats:
        clientsSubscriptions[_client][_policyId].nbSeatsPurchased = seats;
        policyDetails[_policyId].nbSeatsSold = policyDetails[_policyId].nbSeatsSold + seats;

        // update collateral required
        masterPolicy[0].collateralRequired += policyDetails[_policyId].claimPayout * seats;

        emit LogPurchasedProduct(_client, policyDetails[_policyId].premium, _policyId);
        // calculate payout for the user and provide it to the escrow

        IEscrow(escrowAddress).addClientPayment(
            _client, policyDetails[_policyId].premium, _policyId, policyDetails[_policyId].claimPayout * seats
        );

        return true;
    }

    ///--- PURE ADMIN FUNCTIONS: update of variables, override -----


    //Oraclize update //generates an error
    function update_Oraclize(address _newAddress) public onlyOwner { //payable in real
        removeAuthorized(oracleAddress);
        oracleAddress = _newAddress;
        addAuthorized(_newAddress);
    }

    function updateEscrow(address _newEscrow) public onlyOwner {
        escrowAddress = _newEscrow;
    }

    function updateToken(address _newToken) public onlyOwner {
        tokenAddress = _newToken;
    }

    //Killswitch
    function _killContract(bool _forceKill) public onlyOwner {
        if(_forceKill == false){
            require(ERC20_Interface(tokenAddress).balanceOf(escrowAddress) == 0, "Please withdraw Tokens");
        } //Require: TOKEN balances = 0
        selfdestruct(msg.sender); //kill --> make sure that the TOKEN balances are ZERO
    }

    function _checkTokenBalances() public view onlyOwner returns(uint256 _tokenBalance) {
        _tokenBalance = ERC20_Interface(tokenAddress).balanceOf(escrowAddress);
    }

    function _transferEscrowOwnership(address newOwner) public onlyOwner {
        IEscrow(escrowAddress).transferOwnership(newOwner);
    }

    function _withdrawFromEscrow() public onlyOwner {
        uint256 escrowBalance = _checkTokenBalances();
        IEscrow(escrowAddress).withdrawTokens(msg.sender, escrowBalance);
    }

  //Hash Calculation functions
    function createPolicyId(
        string memory _fltNum,
        uint256 _depDte,
        uint _expectedArrDte,
        uint256 _dlyTime,
        uint256 _premium,
        uint _claimPayout,
        uint256 _expiryDte,
        uint256 _nbSeatsMax
    ) public pure returns (bytes32) {

        return keccak256(abi.encodePacked(
            createFlightId(_fltNum, _depDte), _expectedArrDte, _dlyTime, _premium, _claimPayout, _expiryDte, _nbSeatsMax)
        );
    }

    function createFlightId(string memory _fltNum, uint256 _depDte) public pure returns (bytes32){
        return keccak256(abi.encodePacked(_fltNum, _depDte));
    }

  //getter function for array size retrieval
    function getNbCustomers(bytes32 _policyId) public view returns (uint256) {
        return ListOfCustomers[_policyId].length;
    }


} //--- END OF CODE -------------