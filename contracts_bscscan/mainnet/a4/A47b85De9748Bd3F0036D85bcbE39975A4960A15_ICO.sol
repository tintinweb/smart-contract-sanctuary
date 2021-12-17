/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

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

contract ICO {
    using SafeMath for uint;

    struct Sale {
        address buyer;
        uint tokenAmount;
        uint investAmount;
    }

    uint public constant DEV_FEE = 8;//8%
    uint public constant PERCENT_DIVIDER = 100;
    address public devAddress = address(0xE870d687eEf07ee7dd5A25c569976925b82972E6);
    address public owner = address(0x12F68d81FbD03ec5306Dd9B898BC5c6a30DdbD50);
    uint public constant MIN_INVEST_AMOUNT = 0.1 ether;
    uint public constant MAX_INVEST_AMOUNT = 4 ether;


    mapping(address => Sale) public sales;
    mapping(uint => address) public investors;
    uint public totalInverstorsCount;
    address public admin;
    uint public initDate;
    uint public BNBtoToken = 980;

    uint constant public HARDCAP = 600 ether;
    uint public totalInvested;
    uint public totalTokenSale;
    bool public isActive = true;

    event SaleEvent (address indexed _investor, uint indexed _investAmount, uint indexed _tokenAmount);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }

    modifier saleIsActive() {
        require(isActive, 'sale is not active');
        _;
    }

    function buy() external payable saleIsActive {
        require(msg.value >= MIN_INVEST_AMOUNT, "msg.value must be greater than MIN_INVEST_AMOUNT");
        require(msg.value <= MAX_INVEST_AMOUNT, "msg.value must be less than MAX_INVEST_AMOUNT");
        uint amount = msg.value;
        if(amount > getReserveToInvest()) {
            amount = getReserveToInvest();
            payable(msg.sender).transfer(msg.value.sub(amount));
            isActive = false;
        }

        Sale memory sale = sales[msg.sender];

        if(sale.investAmount == 0) {
            sales[msg.sender].buyer = msg.sender;
            investors[totalInverstorsCount] = msg.sender;
            totalInverstorsCount = totalInverstorsCount.add(1);
        }

        uint tokenAmount = msg.value.mul(BNBtoToken);

        sales[msg.sender].tokenAmount = sale.tokenAmount.add(tokenAmount);
        sales[msg.sender].investAmount = sale.investAmount.add(amount);

        totalInvested = totalInvested.add(amount);
        totalTokenSale = totalTokenSale.add(tokenAmount);
        uint dev_fee = amount.mul(DEV_FEE).div(PERCENT_DIVIDER);
        payable(devAddress).transfer(dev_fee);
        payable(owner).transfer(amount.sub(dev_fee));
        emit SaleEvent(msg.sender, amount, tokenAmount);
    }

    function withdrawDividens(uint amount) public onlyAdmin {
        uint dev_fee = amount.mul(DEV_FEE).div(PERCENT_DIVIDER);
        payable(devAddress).transfer(dev_fee);
        payable(owner).transfer(amount.sub(dev_fee));
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function finish() external onlyAdmin {
        isActive = false;
        if(getBalance() > 0) {
            withdrawDividens(getBalance());
        }
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    function getReserveToInvest() public view returns (uint) {
        return HARDCAP.sub(totalInvested);
    }

    function getAllInvestorsAdress() public view returns (address[] memory) {
        address[] memory _investors = new address[](totalInverstorsCount);
        for(uint i; i < totalInverstorsCount; i++) {
            _investors[i] = investors[i];
        }
        return _investors;
    }

    function getAllTokens() public view returns (uint[] memory) {
        uint[] memory _tokens = new uint[](totalInverstorsCount);
        for(uint i; i < totalInverstorsCount; i++) {
            _tokens[i] = sales[investors[i]].tokenAmount;
        }
        return _tokens;
    }

    function getAllInvestorAndTokes() public view returns (Sale[] memory) {
        Sale[] memory _investors = new Sale[](totalInverstorsCount);
        for(uint i; i < totalInverstorsCount; i++) {
            _investors[i] = sales[investors[i]];
        }
        return _investors;
    }

    function getAllInvestorAndTokesByindex(uint _first, uint last) public view returns (Sale[] memory) {
        uint length = last.sub(_first).add(1);
        Sale[] memory _investors = new Sale[](length);
        for(uint i; i < length; i++) {
            _investors[i] = sales[investors[_first + i]];
        }
        return _investors;
    }

    struct SaleToken {
        address buyer;
        uint tokenAmount;
    }

    function getAllInvestors() external view returns (SaleToken[] memory) {	
        SaleToken[] memory _investors = new SaleToken[](totalInverstorsCount);
        for(uint i; i < totalInverstorsCount; i++) {
            _investors[i] = SaleToken(investors[i], sales[investors[i]].tokenAmount);
        }
        return _investors;
    }
    

    function getTokensByInvestor(address investor) public view returns (uint) {
        return sales[investor].tokenAmount;
    }

    function getInvestByInvestor(address investor) public view returns (uint) {
        return sales[investor].investAmount;
    }



}