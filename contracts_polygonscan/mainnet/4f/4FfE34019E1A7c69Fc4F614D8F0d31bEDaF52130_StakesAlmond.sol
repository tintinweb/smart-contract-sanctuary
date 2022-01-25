// SPDX-License-Identifier: MIT

/**

MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMWWNXXKKKKKKKXXXXKKKKKKXXNWWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWNXKKKKXXNWWWWMMWWWWMWWWWNXXXKKKXNWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMWNXKKKXNWMMMMMMMMMNOdxKWMMMMMMMMWNXKKKXNWMMMMMMMMMMMMMM
MMMMMMMMMMMMMWXKKKNWMMMMMMMMMMMMNx:;;l0WMMMMMMMMMMMWNK0KXWMMMMMMMMMMMM
MMMMMMMMMMMWXKKXWMMMMMMMMMMMMMMXd:;;;;cOWMMMMMMMMMMMMMWXKKXWMMMMMMMMMM
MMMMMMMMMWNKKXWMMMMMMMMMMMMMMWKo;;col:;:kNMMMMMMMMMMMMMMWX0KNWMMMMMMMM
MMMMMMMMWX0XWMMMMMMMMMMMMMMMWOl;;oKWXkc;:dXMMMMMMMMMMMMMMMWX0XWMMMMMMM
MMMMMMMNKKNWMMMMMMMMMMMMMMMNkc;:dXMMMWOc;;oKWMMMMMMMMMMMMMMWNKKNMMMMMM
MMMMMMNKKNMMMMMMMMMMMMMMMMNx:;:xNMMMMMW0l;;l0WMMMMMMMWMMMMMMMNKKNMMMMM
MMMMMNKKNMMMMMMMMMMMMMMMMXd:;ckNMMMMMMMMKo:;cOWMMMMXkxkXWMMMMMNKKNMMMM
MMMMWK0NMMMMMMMMMMMMMMMWKo;;l0WMMMMMMMMMMXx:;:xNMMW0lccxXMMMMMMN0KWMMM
MMMMX0XWMMMMMMWWMMMMMMWOl;;oKWMMMMMMMMMMMMNkc;:dXMMNklcoKMMMMMMMX0XMMM
MMMWKKNMMWK0OkkkkkkKWNkc;:dXMMMMMMMMMMMMMMMWOl;;oKWMXdcxNMMMMMMMNKKWMM
MMMN0XWMMWNXX0OdlccdKOc;:xNMMMWXKKXNWNNNNWWMW0o;;l0WNkdKWMMMMMMMWX0NMM
MMMX0XMMMMMMMMMN0dlcdOxoONMMMMW0xdddddodxk0KNWXd:;l0Kx0WMMMMMMMMMX0XMM
MMMX0NMMMMMMMMMMWXxlcoOXWMMMMWKkolclodkKNNNNWWMNxcxOkKWMMMMMMMMMMX0XMM
MMMX0XMMMMMMMMMMMMNklclkNMMWXklccodxdodKWMMMMMMMNKOkKWMMMMMMMMMMMX0XMM
MMMN0XWMMMMMMMMMMMMNOoclxXN0occcdKX0xlco0WMMMMMMNOOXMMMMMMMMMMMMMX0NMM
MMMWKKWMMMMMMMMMMMMMW0dccoxocccdKWMWNklclONMMMMXOONMMMMMMMMMMMMMWKKWMM
MMMMX0XMMMMMMMMMMMMMMWKdcccccco0WMMMMNOoclkNWWKk0NMMMMMMMMMMMMMMX0XWMM
MMMMWKKNMMMMMMMMMMMMMMMXxlcccckNMMMMMMW0oclxK0kKWMMMMMMMMMMMMMMNKKWMMM
MMMMMN0KWMMMMMMMMMMMMMMMNklccoKWMMMMMMMWKdlcoxKWMMMMMMMMMMMMMMWK0NMMMM
MMMMMMN0KWMMMMMMMMMMMMMMMNOod0KXWMMMMMMNK0xoxXWMMMMMMMMMMMMMMWK0NMMMMM
MMMMMMMN0KNMMMMMMMMMMMMMMMWXKkll0WMMMMXdcoOKNMMMMMMMMMMMMMMMNK0NMMMMMM
MMMMMMMMNK0XWMMMMMMMMMMMMMMMNd:;cOWMWKo:;c0WMMMMMMMMMMMMMMWX0KNMMMMMMM
MMMMMMMMMWXKKNWMMMMMMMMMMMMMMXd:;cx0kl;;l0WMMMMMMMMMMMMMWNKKXWMMMMMMMM
MMMMMMMMMMMWX0KNWMMMMMMMMMMMMMNkc;;::;:oKWMMMMMMMMMMMMWNK0XWMMMMMMMMMM
MMMMMMMMMMMMMNXKKXNWMMMMMMMMMMMWOc;;;:dXMMMMMMMMMMMWNXKKXWMMMMMMMMMMMM
MMMMMMMMMMMMMMMWNKKKXNWMMMMMMMMMW0l:ckNMMMMMMMMMWNXKKKNWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWNXKKKXXNWWWMMMMX0KWMMMWWWNXXKKKXNWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMWWNXXKKKKKXXXXXXXXXXKKKKXXNWWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNNNNNNNNNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM


---------------------- [ WPSmartContracts.com ] ----------------------

                       [ Blockchain Made Easy ]


    |
    |  Advanced Stakes v.1
    |
    |----------------------------
    |
    |  Flavor
    |
    |  >  Almond: Fully featured ERC-20 Staking contract with maturity 
    |             time an annual interest in a dual token system
    |

*/

pragma solidity ^0.8.2;

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor(address _owner) {
        owner = _owner;
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() public view returns (address) {
        return owner;
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// Using consensys implementation of ERC-20, because of decimals

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md

abstract contract EIP20Interface {
    /* This is a slight change to the EIP20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance The balance
    function balanceOf(address _owner) virtual public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) virtual public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) virtual public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*
Implements EIP20 token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
*/

contract EIP20 is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) override public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        uint256 the_allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && the_allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (the_allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) override public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) override public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) override public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

/**
 * 
 * Stakes is an interest gain contract for ERC-20 tokens
 * 
 * asset is the EIP20 token to deposit
 * asset2 is the EIP20 token to get interest
 * interest_rate: percentage rate of token1
 * interest_rate2: percentage rate of token2
 * maturity is the time in seconds after which is safe to end the stake
 * penalization for ending a stake before maturity time
 * lower_amount is the minimum amount for creating a stake
 * 
 */
contract StakesAlmond is Owner, ReentrancyGuard {

    using SafeMath for uint256;

    // token to deposit
    EIP20 public asset;

    // token to pay interest
    EIP20 public asset2;

    // stakes history
    struct Record {
        uint256 from;
        uint256 amount;
        uint256 gain;
        uint256 gain2;
        uint256 penalization;
        uint256 to;
        bool ended;
    }

    // contract parameters
    uint8 public interest_rate;
    uint8 public interest_rate2;
    uint256 public maturity;
    uint8 public penalization;
    uint256 public lower_amount;

    // conversion ratio for token1 and token2
    // 1:10 ratio will be: 
    // ratio1 = 1 
    // ratio2 = 10
    uint256 public ratio1;
    uint256 public ratio2;

    mapping(address => Record[]) public ledger;

    event StakeStart(address indexed user, uint256 value, uint256 index);
    event StakeEnd(address indexed user, uint256 value, uint256 penalty, uint256 interest, uint256 index);
    
    constructor(
        EIP20 _erc20, EIP20 _erc20_2, address _owner, uint8 _rate, uint8 _rate2, uint256 _maturity, 
        uint8 _penalization, uint256 _lower, uint256 _ratio1, uint256 _ratio2) Owner(_owner) {
        require(_penalization<=100, "Penalty has to be an integer between 0 and 100");
        asset = _erc20;
        asset2 = _erc20_2;
        ratio1 = _ratio1;
        ratio2 = _ratio2;
        interest_rate = _rate;
        interest_rate2 = _rate2;
        maturity = _maturity;
        penalization = _penalization;
        lower_amount = _lower;
    }
    
    function start(uint256 _value) external {
        require(_value >= lower_amount, "Invalid value");
        asset.transferFrom(msg.sender, address(this), _value);
        ledger[msg.sender].push(Record(block.timestamp, _value, 0, 0, 0, 0, false));
        emit StakeStart(msg.sender, _value, ledger[msg.sender].length-1);
    }

    function end(uint256 i) external nonReentrant {

        require(i < ledger[msg.sender].length, "Invalid index");
        require(ledger[msg.sender][i].ended==false, "Invalid stake");
        
        // penalization
        if(block.timestamp.sub(ledger[msg.sender][i].from) < maturity) {

            uint256 _penalization = ledger[msg.sender][i].amount.mul(penalization).div(100);
            asset.transfer(msg.sender, ledger[msg.sender][i].amount.sub(_penalization));
            asset.transfer(getOwner(), _penalization);
            ledger[msg.sender][i].penalization = _penalization;
            ledger[msg.sender][i].to = block.timestamp;
            ledger[msg.sender][i].ended = true;
            emit StakeEnd(msg.sender, ledger[msg.sender][i].amount, _penalization, 0, i);

        // interest gained
        } else {
            
            // interest is calculated in asset2
            uint256 _interest = get_gains(msg.sender, i);

            // check that the owner can pay interest before trying to pay, token 1
            if (_interest>0 && asset.allowance(getOwner(), address(this)) >= _interest && asset.balanceOf(getOwner()) >= _interest) {
                asset.transferFrom(getOwner(), msg.sender, _interest);
            } else {
                _interest = 0;
            }

            // interest is calculated in asset2
            uint256 _interest2 = get_gains2(msg.sender, i);

            // check that the owner can pay interest before trying to pay, token 1
            if (_interest2>0 && asset2.allowance(getOwner(), address(this)) >= _interest2 && asset2.balanceOf(getOwner()) >= _interest2) {
                asset2.transferFrom(getOwner(), msg.sender, _interest2);
            } else {
                _interest2 = 0;
            }

            // the original asset is returned to the investor
            asset.transfer(msg.sender, ledger[msg.sender][i].amount);
            ledger[msg.sender][i].gain = _interest;
            ledger[msg.sender][i].gain2 = _interest2;
            ledger[msg.sender][i].to = block.timestamp;
            ledger[msg.sender][i].ended = true;
            emit StakeEnd(msg.sender, ledger[msg.sender][i].amount, 0, _interest, i);

        }
    }

    function set(EIP20 _erc20, EIP20 _erc20_2, uint256 _lower, uint256 _maturity, uint8 _rate, uint8 _rate2, uint8 _penalization, uint256 _ratio1, uint256 _ratio2) public isOwner {
        require(_penalization<=100, "Invalid value");
        asset = _erc20;
        asset2 = _erc20_2;
        ratio1 = _ratio1;
        ratio2 = _ratio2;
        lower_amount = _lower;
        maturity = _maturity;
        interest_rate = _rate;
        interest_rate2 = _rate2;
        penalization = _penalization;
    }

    // calculate interest of the token 1 to the current date time
    function get_gains(address _address, uint256 _rec_number) public view returns (uint256) {
        uint256 _record_seconds = block.timestamp.sub(ledger[_address][_rec_number].from);
        uint256 _year_seconds = 365*24*60*60;
        return _record_seconds.mul(
            ledger[_address][_rec_number].amount.mul(interest_rate).div(100)
        ).div(_year_seconds);
    }

    // calculate interest to the current date time
    function get_gains2(address _address, uint256 _rec_number) public view returns (uint256) {
        uint256 _record_seconds = block.timestamp.sub(ledger[_address][_rec_number].from);
        uint256 _year_seconds = 365*24*60*60;
        // now we calculate the value of the transforming the staked asset (asset) into the asset2
        // first we calculate the ratio
        uint256 value_in_asset2 = ledger[_address][_rec_number].amount.mul(ratio2).div(ratio1);
        // now we transform into decimals of the asset2
        value_in_asset2 = value_in_asset2.mul(10**asset2.decimals()).div(10**asset.decimals());
        uint256 interest = _record_seconds.mul(
            value_in_asset2.mul(interest_rate2).div(100)
        ).div(_year_seconds);
        // now lets calculate the interest rate based on the converted value in asset 2
        return interest;
    }

    function ledger_length(address _address) public view 
        returns (uint256) {
        return ledger[_address].length;
    }

}