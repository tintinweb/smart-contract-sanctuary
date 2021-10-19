pragma solidity ^0.8.7;

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

import './ERC20.sol';

contract ExcaliburToken is ERC20 {
    using SafeMath for uint256;
    using SafeMath for uint;

    address public admin;
    address private taxAddress;
    address private charityAddress;
    
    uint private dt100;
    uint private dt63;
    uint private dt47;
    uint private dt22;
    uint private dt11;
    uint private dt4;
    
    uint256 private immutable _cap;

    constructor() ERC20('ExcaliburToken', 'EXBR') {
        _mint(msg.sender, 21000000000 * 10 ** 18); // 21 Billion tokens minted
        admin = msg.sender;
        _cap = totalSupply(); // Initial minting is also the capped amount
    }

    /**
     * This function allows transferring the ownership to another person
     */
    function transferOwner(address _admin) external payable {
        require(msg.sender == admin, 'Only the admin of EXBR can transfer ownership');
        admin = _admin;
    }
        
    /**
     * This function returns the hard cap of the token
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }
    
    /**
     *  Minting function that takes taxation into account
     */
    function mint(address to, uint amount) external {
        require(msg.sender == admin, 'Only the admin of EXBR is allowed to mint new tokens');
        require(ERC20.totalSupply() + amount <= cap(), 'ERC20Capped: cap exceeded');
        _mint(to, amount);
    }
    
    /**
     * Burn function to burn tokens and decrease the totalSupply, but not the hard cap!
     */
    function burn(uint amount) external {
        require(msg.sender == admin, 'Only the admin of EXBR is allowed to burn tokens');    
        _burn(msg.sender, amount);
    }

    /**
     * BeginParams function that sets taxAddress, charityAddress and startDate for tax levels  
     */
    function setBeginParams(address _taxAddress, address _charityAddress, uint startDate) external payable {
        require(msg.sender == admin, 'Only the admin of the EXBR is allowed to set the tax address');
        taxAddress = _taxAddress;
        charityAddress = _charityAddress;
        dt100 = SafeMath.add(startDate, 7*24*3600);
        dt63 = SafeMath.add(startDate, 20*24*3600);
        dt47 = SafeMath.add(startDate, 33*24*3600);
        dt22 = SafeMath.add(startDate, 45*24*3600);
        dt11 = SafeMath.add(startDate, 50*24*3600);
        dt4 = SafeMath.add(startDate, 55*24*3600);
    }
    
    /**
     * Tax Address setter function
     */
    function setTaxAddress(address _taxAddress) external  payable {
        require(msg.sender == admin, 'Only the admin of EXBR is allowed to set the tax address');
        taxAddress = _taxAddress;
    }

    /**
     * Charity Address setter function
     */
    function setCharityAddress(address _charityAddress) external  payable {
        require(msg.sender == admin, 'Only the admin of EXBR is allowed to set the charity address');
        charityAddress = _charityAddress;
    }

    /**
     * Start Date setter function that determines the tax dates for the tax levels
     * use: https://wtools.io/convert-date-time-to-unix-time for getting UNIX time in seconds
     */
    function setTaxLevelOffSet(uint startDate) external  payable {
        require(msg.sender == admin, 'Only the admin can set the Tax level offset date');
        // startdate is seconds since 01-01-1970 00:00:00 
        dt100 = SafeMath.add(startDate, 7*24*3600);
        dt63 = SafeMath.add(startDate, 20*24*3600);
        dt47 = SafeMath.add(startDate, 33*24*3600);
        dt22 = SafeMath.add(startDate, 45*24*3600);
        dt11 = SafeMath.add(startDate, 50*24*3600);
        dt4 = SafeMath.add(startDate, 55*24*3600);
    }

    /**
     * Overriding the transfer function from ERC20 to make sure we get the taxLevel in there as well.
     */
    function transfer(address recipient, uint256 amount) public virtual override(ERC20) returns (bool) {
        if (msg.sender == admin || msg.sender == taxAddress || msg.sender == charityAddress) {
            // Admin, taxAddress and charityAddress can send tokens without taxation/charity. 
            // This is to enable presale and token distribution
            _transfer(msg.sender, recipient, amount);
        }
        else {
             require(dt100 != 0, 'Admin has to specify TaxLevel Offset first');
            // calculate taxLevel
            uint currentTime = block.timestamp;
            uint taxLevel = 50;
            uint charityLevel = 50;
           
            if (currentTime <= dt100 ) {
                taxLevel = 50; //  Sell before 7 days, 100% tax
                charityLevel = 50;
            } 
            else if (currentTime <= dt63) {
                taxLevel = 33; // Sell between 8-20 days, 63% tax
                charityLevel = 30;
            }
            else if (currentTime <= dt47) {
                taxLevel = 27; // SELL between 21-33 days, 47% tax
                charityLevel = 20;
            }
            else if (currentTime <= dt22) {
                taxLevel = 12; // Sell between 34-45 days, 22% tax
                charityLevel = 10;
            }
            else if (currentTime <= dt11) {
                taxLevel = 6; // Sell between 46-50 days, 11% tax
                charityLevel = 5;
            }
            else if (currentTime <= dt4) {
                taxLevel = 2; // Sell between 51-55 days, 4% tax
                charityLevel = 2;
            }
            else {
                taxLevel = 1; // Sell after 56days, 1% tax
                charityLevel = 0;
            }
            uint amountToTax = SafeMath.div(SafeMath.mul(amount,taxLevel), 100);
            uint amountToCharity = SafeMath.div(SafeMath.mul(amount, charityLevel), 100);
            uint amountToTransfer = SafeMath.sub(amount, amountToTax);
            
            _transfer(msg.sender, recipient, amountToTransfer);
            _transfer(msg.sender, taxAddress, amountToTax);
            _transfer(msg.sender, charityAddress, amountToCharity);

            assert(SafeMath.add(amountToTransfer, SafeMath.add(amountToCharity, amountToTax)) == amount);
        }
        return true;

    }
}