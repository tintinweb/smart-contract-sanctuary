/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


interface ibep20Contract {
    function transferPrivatePresale(address recipient, uint amount) external returns (bool);
}

contract PrivatePreSale1 {
    using SafeMath for uint;

    uint public constant _minimumDepositBNBAmount = 1 ether; // Minimum deposit is 1 BNB
    uint public constant _maximumDepositBNBAmount = 6400 ether; // Maximum deposit is 10 BNB

    uint public constant _bnbAmountCap = 1 ether; // Allow cap at 6400 BNB
    uint public constant _startPresale = 1642830967; // Private Sale starts at Sept 8 12am - Falta definir fecha
    uint public constant _endPresale = 1642917367; // Private Sale ends at Sept 14 12am

    uint constant public _Distribution1 = 1636934400; // 1 distribution - TGE date (15-Nov-21)
    uint constant public _Distribution2 = 1639526400; // 2 distribution - Month 1 (15-Dec-21)
    uint constant public _Distribution3 = 1642204800; // 3 distribution - Month 2 (15-Jan-22)
    uint constant public _Distribution4 = 1644883200; // 4 distribution - Month 3 (15-Feb-22)
    uint constant public _Distribution5 = 1647302400; // 5 distribution - Month 4 (15-Mar-22)
    uint constant public _Distribution6 = 1649980800; // 6 distribution - Month 5 (15-Apr-22)
    uint constant public _Distribution7 = 1652572800; // 7 distribution - Month 6 (15-May-22)
    uint constant public _Distribution8 = 1655251200; // 8 distribution - Month 7 (15-Jun-22)
    uint constant public _Distribution9 = 1657843200; // 9 distribution - Month 8 (15-Jul-22)
    uint constant public _Distribution10 = 1660521600; // 10 distribution - Month 9 (15-Aug-22)
    uint constant public _Distribution11 = 1663200000; // 11 distribution - Month 10 (15-Sep-22)
    uint constant public _Distribution12 = 1665792000; // 12 distribution - Month 11 (15-Oct-22)
    uint constant public _Distribution13 = 1668470400; // 13 distribution - Month 13 (15-Nov-22) 

    address payable public _admin; // Admin address
    address public _bep20Contract; // External bep20 contract

    uint public _totalAddressesDepositAmount; // Total addresses' deposit amount

    uint public _distribute1Index;  // index to start distribute1 TGE
    uint public _distribute2Index;  // index to start distribute2 (15-Dec-21)
    uint public _distribute3Index;  // index to start distribute3 (15-Jan-22)
    uint public _distribute4Index;  // index to start distribute4 (15-Feb-22)
    uint public _distribute5Index;  // index to start distribute5 (15-Mar-22)
    uint public _distribute6Index;  // index to start distribute6 (15-Apr-22)
    uint public _distribute7Index;  // index to start distribute7 (15-May-22)
    uint public _distribute8Index;  // index to start distribute8 (15-Jun-22)
    uint public _distribute9Index;  // index to start distribute9 (15-Jul-22)
    uint public _distribute10Index; // index to start distribute10 (15-Aug-22)
    uint public _distribute11ndex;  // index to start distribute11 (15-Sep-22)
    uint public _distribute12ndex;  // index to start distribute12 (15-Oct-22)
    uint public _distribute13ndex;  // index to start distribute13 (15-Nov-22)


    uint public _startDepositAddressIndex;  // start ID of deposit addresses list
    uint public _depositAddressesNumber;  // Number of deposit addresses
    mapping(uint => address) public _depositAddresses; // Deposit addresses
    mapping(address => bool) public _depositAddressesStatus; // Deposit addresses' whitelist status
    mapping(address => uint) public _depositAddressesBNBAmount; // Address' deposit amount

    mapping(address => uint) public _depositAddressesAwardedTotalErc20CoinAmount; // Total awarded ERC20 coin amount for an address
    mapping(address => uint) public _depositAddressesAwardedDistribution1Erc20CoinAmount; // Awarded 1st distribution ERC20 coin amount for an address
    mapping(address => uint) public _depositAddressesAwardedDistribution2Erc20CoinAmount; // Awarded 2nd distribution ERC20 coin amount for an address

    constructor(address erc20Contract) {
        _admin = payable(msg.sender);
        _bep20Contract = erc20Contract;
    }

    // Modifier
    modifier onlyAdmin() {
        require(_admin == msg.sender);
        _;
    }

    // Deposit event
    event Deposit(address indexed _from, uint _value);

    // Transfer owernship
    function transferOwnership(address payable admin) public onlyAdmin {
        require(admin != address(0), "Zero address");
        _admin = admin;
    }

    // Add deposit addresses and whitelist them
    function whiteListAddress(address[] calldata depositAddresses) external onlyAdmin {
        uint depositAddressesNumber = _depositAddressesNumber;
        for (uint i = 0; i < depositAddresses.length; i++) {
            if (!_depositAddressesStatus[depositAddresses[i]]) {
                _depositAddresses[depositAddressesNumber] = depositAddresses[i];
                _depositAddressesStatus[depositAddresses[i]] = true;
                depositAddressesNumber++;
            }
        }
        _depositAddressesNumber = depositAddressesNumber;
    }

    // Remove deposit addresses and unwhitelist them
    // number - number of addresses to process at once
    function removeWhiteListAddress() external onlyAdmin {
        require(block.timestamp < _startPresale, "Presale2 already started");
        uint i = _startDepositAddressIndex;
        uint last = _depositAddressesNumber;
        for (; i < last; i++) {
            delete _depositAddressesStatus[_depositAddresses[i]] ;
            delete _depositAddresses[i];
        }
        _startDepositAddressIndex = 0;
        _depositAddressesNumber = 0;
        _distribute1Index = 0;
        _distribute2Index = 0;
        _distribute3Index = 0;
        _distribute4Index = 0;
        _distribute5Index = 0;
        _distribute6Index = 0;
        _distribute7Index = 0;
        _distribute8Index = 0;
        _distribute9Index = 0;
        _distribute10Index = 0;
        _distribute11ndex = 0; 
        _distribute12ndex = 0;
        _distribute13ndex = 0;
    }

    // Receive BNB deposit
    receive() external payable {
        require(block.timestamp >= _startPresale && block.timestamp <= _endPresale,
        'Deposit rejected, presale1 has either not yet started or not yet overed');
        require(_totalAddressesDepositAmount < _bnbAmountCap, 'Deposit rejected, already reached the cap amount');
        require(_depositAddressesStatus[msg.sender], 'Deposit rejected, deposit address is not yet whitelisted');
        require(msg.value >= _minimumDepositBNBAmount, 'Deposit rejected, it is lesser than minimum amount');
        require(msg.value <= _bnbAmountCap - _totalAddressesDepositAmount, 'Deposit declined, it is more than the maximum amount available');
        require(_depositAddressesBNBAmount[msg.sender].add(msg.value) <= _maximumDepositBNBAmount,
        'Deposit rejected, every address cannot deposit more than 10 bnb');

        if(_totalAddressesDepositAmount.add(msg.value) > _bnbAmountCap){
            // If total deposit + deposit greater than bnb cap amount
            uint value = _bnbAmountCap.sub(_totalAddressesDepositAmount);
            _depositAddressesBNBAmount[msg.sender] = _depositAddressesBNBAmount[msg.sender].add(value);
            _totalAddressesDepositAmount = _totalAddressesDepositAmount.add(value);
            payable(msg.sender).transfer(msg.value.sub(value)); // Transfer back extra BNB

            _depositAddressesAwardedTotalErc20CoinAmount[msg.sender] = _depositAddressesAwardedTotalErc20CoinAmount[msg.sender].add(value.mul(2700));
            _depositAddressesAwardedDistribution1Erc20CoinAmount[msg.sender] = _depositAddressesAwardedDistribution1Erc20CoinAmount[msg.sender].add(value.mul(270));
            _depositAddressesAwardedDistribution2Erc20CoinAmount[msg.sender] = _depositAddressesAwardedDistribution2Erc20CoinAmount[msg.sender].add(value.mul(2430));

            emit Deposit(msg.sender, value);
        } else {
            _depositAddressesBNBAmount[msg.sender] = _depositAddressesBNBAmount[msg.sender].add(msg.value);
            _totalAddressesDepositAmount = _totalAddressesDepositAmount.add(msg.value);

            _depositAddressesAwardedTotalErc20CoinAmount[msg.sender] = _depositAddressesAwardedTotalErc20CoinAmount[msg.sender].add(msg.value.mul(2700));
            _depositAddressesAwardedDistribution1Erc20CoinAmount[msg.sender] = _depositAddressesAwardedDistribution1Erc20CoinAmount[msg.sender].add(msg.value.mul(270));
            _depositAddressesAwardedDistribution2Erc20CoinAmount[msg.sender] = _depositAddressesAwardedDistribution2Erc20CoinAmount[msg.sender].add(msg.value.mul(2430));

            emit Deposit(msg.sender, msg.value);
        }
    }

    // First distribution of ERC20 coin (Only 10% coin distributed)
    // number - number of addresses to process at once
    function distribute15Nov21(uint number) external {
        _distribute1Index = _distribute(_Distribution1, 37500, _distribute1Index, number);
    }

    // Second distribution of ERC20 coin (Only 90% coin distributed)
    // number - number of addresses to process at once
    function distribute15Dec21(uint number) external {
        _distribute2Index = _distribute(_Distribution2, 28125, _distribute2Index, number);
    }

    // Second distribution of ERC20 coin (Only 90% coin distributed)
    // number - number of addresses to process at once
    function distribute15Jan22(uint number) external {
        _distribute2Index = _distribute(_Distribution3, 28125, _distribute2Index, number);
    }

    // Second distribution of ERC20 coin (Only 90% coin distributed)
    // number - number of addresses to process at once
    function distribute15Febn22(uint number) external {
        _distribute2Index = _distribute(_Distribution4, 28125, _distribute2Index, number);
    }

    // Second distribution of ERC20 coin (Only 90% coin distributed)
    // number - number of addresses to process at once
    function distribute15Mar22(uint number) external {
        _distribute2Index = _distribute(_Distribution5, 28125, _distribute2Index, number);
    }

    // Second distribution of ERC20 coin (Only 90% coin distributed)
    // number - number of addresses to process at once
    function distribute15Apr22(uint number) external {
        _distribute2Index = _distribute(_Distribution6, 28125, _distribute2Index, number);
    }

    // Second distribution of ERC20 coin (Only 90% coin distributed)
    // number - number of addresses to process at once
    function distribute15May22(uint number) external {
        _distribute2Index = _distribute(_Distribution7, 28125, _distribute2Index, number);
    }

    // Second distribution of ERC20 coin (Only 90% coin distributed)
    // number - number of addresses to process at once
    function distribute15Jun22(uint number) external {
        _distribute2Index = _distribute(_Distribution8, 28125, _distribute2Index, number);
    }

    // Second distribution of ERC20 coin (Only 90% coin distributed)
    // number - number of addresses to process at once
    function distribute15Jul22(uint number) external {
        _distribute2Index = _distribute(_Distribution9, 28125, _distribute2Index, number);
    }

    // Second distribution of ERC20 coin (Only 90% coin distributed)
    // number - number of addresses to process at once
    function distribute15Aug22(uint number) external {
        _distribute2Index = _distribute(_Distribution10, 28125, _distribute2Index, number);
    }

    // Second distribution of ERC20 coin (Only 90% coin distributed)
    // number - number of addresses to process at once
    function distribute15Sep22(uint number) external {
        _distribute2Index = _distribute(_Distribution11, 28125, _distribute2Index, number);
    }

    // Second distribution of ERC20 coin (Only 90% coin distributed)
    // number - number of addresses to process at once
    function distribute15Oct22(uint number) external {
        _distribute2Index = _distribute(_Distribution12, 28125, _distribute2Index, number);
    }

    // Second distribution of ERC20 coin (Only 90% coin distributed)
    // number - number of addresses to process at once
    function distribute15Novt22(uint number) external {
        _distribute2Index = _distribute(_Distribution13, 28125, _distribute2Index, number);
    }

    // Main distribution logic
    function _distribute(uint date, uint amount, uint i, uint number) private returns (uint){
        require(block.timestamp > date, "Distribution fail, have not reached the distribution date");
        require(_depositAddressesNumber > 0, 'Distribution fail, Moses didnt do his job');

        ibep20Contract erc20Contract = ibep20Contract(_bep20Contract);

        uint last = i + number;
        if (last > _depositAddressesNumber) last = _depositAddressesNumber;
        require(i < last, "Already distributed");

        for (; i < last; i++) {
            address depositor = _depositAddresses[i];
            uint deposited = _depositAddressesBNBAmount[depositor];
            if (deposited != 0)
                erc20Contract.transferPrivatePresale(depositor, deposited.mul(amount) / 100);
        }
        return i;
    }

    // Allow admin to withdraw all the deposited BNB
    function withdrawAll() external onlyAdmin {
        _admin.transfer(address(this).balance);
    }
}