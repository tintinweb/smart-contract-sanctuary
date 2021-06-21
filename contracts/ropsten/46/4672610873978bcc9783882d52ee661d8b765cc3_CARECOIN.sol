/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
        require(a >= b);
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

contract Ownable {
    address public owner;
    address public careFund;
    
    uint256 public maxSupply;

    //Care Fund
    uint256 public careFundFeePercentage;
    uint256 public burnFeePercentage;
    

    //Interest to Holders
    uint256 public interestRatePerYear;
    

    uint256 public CPNPrice;

    address[] public stakeholders;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event CareFundTransferred(
        address indexed previousCareFund,
        address indexed newCareFund
    );

    event CareFeeChanged(uint256 previousCareFee, uint256 newCareFee);
    event BurnFeeChanged(uint256 previousBurnFee, uint256 newBurnFee);

    event InterestRateChanged(
        uint256 previousInterestRatePerYear,
        uint256 newInterestRatePerYear
    );
    
    event ChangeCPNPrice(uint256 previousCPNPrice, uint256 newCPNPrice);
    
    event MaxSupplyChanged(uint256 previousMaxSupply, uint256 newMaxSupply);

    event Bought(address buyer, uint256 tokens);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function transferCareFund(address newCareFund) public onlyOwner {
        require(newCareFund != address(0));
        emit CareFundTransferred(careFund, newCareFund);
        careFund = newCareFund;
    }


    function changeCareFundFeePercentage(uint256 newCareFundFeePercentage) public onlyOwner {
        require(newCareFundFeePercentage >= 0);
        emit CareFeeChanged(careFundFeePercentage,newCareFundFeePercentage);
        careFundFeePercentage = newCareFundFeePercentage;
    }
    function changeBurnFeePercentage(uint256 newBurnFee) public onlyOwner {
        require(newBurnFee >= 0);

        burnFeePercentage = newBurnFee;
    }
function changeMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require(newMaxSupply >= 0);
        emit MaxSupplyChanged(maxSupply, newMaxSupply);
        maxSupply = newMaxSupply;
            
    }
    function changeInterestRatePerYear(uint256 newInterestRatePerYear)
        public
        onlyOwner
    {
        require(newInterestRatePerYear >= 0);
    emit InterestRateChanged(interestRatePerYear,newInterestRatePerYear);
        interestRatePerYear = newInterestRatePerYear;
    }


    function changeCPNPrice(uint256 newCPNPrice) public onlyOwner {
        require(newCPNPrice >= 1);
emit ChangeCPNPrice(CPNPrice,newCPNPrice);
        CPNPrice = newCPNPrice;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

abstract contract ERC20 is Ownable {
    using SafeMath for uint256;

    uint256 public totalSupply;
    

    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => bool) tokenBlacklist;
    mapping(address => uint256) balances;
    mapping(address => uint256) public interestCollectedAt;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Blacklist(address indexed blackListed, bool value);
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);

    event MintInterest(address indexed from, address indexed to, uint256 value);
    
    event MaxSupplyLeft(uint256 value);

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) internal returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function _blackList(address _address, bool _isBlackListed)
        internal
        returns (bool)
    {
        require(tokenBlacklist[_address] != _isBlackListed);
        tokenBlacklist[_address] = _isBlackListed;
        emit Blacklist(_address, _isBlackListed);
        return true;
    }

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who] - (_value);
        totalSupply = totalSupply - (_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        if(maxSupply >= totalSupply.add(amount))
        {
        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Mint(address(0), account, amount);
        emit Transfer(address(0), account, amount);
        }
        else{
            
           emit MaxSupplyLeft(maxSupply.sub(totalSupply));
        }
    }
}

contract CARECOIN is ERC20, Pausable {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint256 public decimals;

    event Bought(uint256 amount);
    event Sold(uint256 amount);
    event DonatedToCareFund(address from, uint256 amount);
    event HelpedToCareFund(address from, uint256 amount);
    event BurnedForBetter(address from, uint256 amount);
    event InterestPaid(address to, uint256 value);
    event NoInterestToPay(address to);

    constructor(uint256 _supply,uint256 _maxsupply, address tokenOwner) {
        name = "Care Pay Network";
        symbol = "CPN";
        decimals = 18;
        totalSupply = _supply * 10**decimals;
        maxSupply = _maxsupply * 10**decimals;
        
        balances[tokenOwner] = totalSupply;
        owner = tokenOwner;

        careFundFeePercentage = 1;
        burnFeePercentage = 2;
        interestRatePerYear = 12;

        

        careFund = 0x6aaA85DBa918dA5f0EEDA8F1f43F91af85EAFd8d;
        CPNPrice = 10000;

        emit Transfer(address(0), tokenOwner, totalSupply);
    }

    function blackListAddress(address listAddress, bool isBlackListed)
        public
        whenNotPaused
        onlyOwner
        returns (bool success)
    {
        return super._blackList(listAddress, isBlackListed);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(tokenBlacklist[msg.sender] == false);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);

        if (_to != owner && _to != careFund && _from != owner) {
            HelpToCareFund(_from, _value);
            BurnForBetter(msg.sender, _value);
        }

        addStakeholder(_to);
        removeStakeholder(_from);

        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(tokenBlacklist[msg.sender] == false);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        if (_to != owner && _to != careFund && msg.sender != owner) {
            HelpToCareFund(msg.sender, _value);
            BurnForBetter(msg.sender, _value);
        }

        addStakeholder(_to);
        removeStakeholder(msg.sender);

        return true;
    }

function BurnForBetter(address from, uint256 amount)
        internal
        returns (bool)
    {
        uint256 bal = balanceOf(from);

        uint256 burnAmount = (amount.mul(burnFeePercentage)).div(100);

        if (bal >= (burnAmount)) {
            balances[from] = balances[from].sub(burnAmount);
            totalSupply = totalSupply.sub(burnAmount);
            

            emit BurnedForBetter(from, burnAmount);
            emit Transfer(from, address(0), burnAmount);
            
        }
        return true;
    }
    function HelpToCareFund(address from, uint256 amount)
        internal
        returns (bool)
    {
        uint256 bal = balanceOf(from);

        uint256 careFundAmount = (amount.mul(careFundFeePercentage)).div(100);

        if (bal >= (careFundAmount)) {
            balances[from] = balances[from].sub(careFundAmount);
            balances[careFund] = balances[careFund].add(careFundAmount);

            emit HelpedToCareFund(from, careFundAmount);
            emit Transfer(from, careFund, careFundAmount);
        }
        return true;
    }

    function DonateToCareFund(uint256 amount) public returns (bool) {
        address from = msg.sender;
        uint256 bal = balanceOf(from);

        require(bal >= amount, "You do not have enough CPN to donate.");

        balances[from] = balances[from].sub(amount);
        balances[careFund] = balances[careFund].add(amount);

        emit DonatedToCareFund(from, amount);
        emit Transfer(from, careFund, amount);

        return true;
    }

    function isStakeholder(address _address)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder) internal {
        if (_stakeholder != owner && _stakeholder != careFund) {
            uint256 Bal = balanceOf(_stakeholder);

            //  require(Bal > 0 , "Balance is less than Zero.");
            if (Bal > 0) {
                (bool _isStakeholder, ) = isStakeholder(_stakeholder);
                if (!_isStakeholder) {
                    stakeholders.push(_stakeholder);
                    interestCollectedAt[_stakeholder] = (block.timestamp -
                        1 days);
                }
            }
        }
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder) internal {
        uint256 Bal = balanceOf(_stakeholder);
        //require(Bal <= 0 , 'Balance is not Zero.');

        if (Bal <= 0) {
            (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
            if (_isStakeholder) {
                stakeholders[s] = stakeholders[stakeholders.length - 1];
                stakeholders.pop();
            }
        }
    }

    /**
     * @notice A simple method that calculates the rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     */

    function calculateMyInterest(address _stakeholder)
        public
        view
        returns (uint256)
    {
        if (balanceOf(_stakeholder) == 0) {
            return (0);
        } else {
            uint256 lastCollectedAt = interestCollectedAt[_stakeholder];
            require(
                lastCollectedAt != 0,
                "Interest Last Collection Time Not Available."
            );
            uint256 daysSinceLastCollect =
                ((block.timestamp.sub(lastCollectedAt)).div(86400));

            uint256 newInterests =
                daysSinceLastCollect.mul(
                    (
                        (
                            (balanceOf(_stakeholder).mul(interestRatePerYear))
                                .div(100)
                        )
                            .div(365)
                    )
                );

            return (newInterests);
        }
    }

    function collectMyInterest() public returns (bool) {
        address collector = msg.sender;
        require(collector != address(0));

        uint256 bal = balances[collector];
        require(bal > 0, "Balance is  Zero.");

        uint256 newInterests = calculateMyInterest(collector);
        require(newInterests > 0, "Interest will be available after 1 Day.");

      if(maxSupply >= totalSupply.add(newInterests))
        {

        totalSupply = totalSupply.add(newInterests);
        balances[collector] = balances[collector].add(newInterests);
        emit MintInterest(address(0), collector, newInterests);

        interestCollectedAt[collector] = block.timestamp;
        emit InterestPaid(collector, newInterests);
       }
       else{
           emit MaxSupplyLeft(maxSupply.sub(totalSupply));
           
       }
        return true;
    }

    /**
     * @notice A method to distribute rewards to all stakeholders.
     */
    function distributeInterest(uint256 from, uint256 to)
        public
        onlyOwner
        returns (bool)
    {
        uint256 totalStakeholders = stakeholders.length;
        require(to < totalStakeholders, "Not enough stakeholders in To");
        require(from < totalStakeholders, "Not enough stakeholders in From");

        for (uint256 s = from; s <= to; s += 1) {
            address stakeholder = stakeholders[s];
            uint256 bal = balances[stakeholder];
            if (bal > 0) {
                uint256 interest = calculateMyInterest(stakeholder);

                if (interest > 0) {
                    mint(stakeholder, interest);
                    emit InterestPaid(stakeholder, interest);

                    interestCollectedAt[stakeholder] = block.timestamp;
                } else {
                    emit NoInterestToPay(stakeholder);
                }
            }
        }
        return true;
    }

    receive() external payable {
        require(msg.value > 0);
    }

    //demo only allows ANYONE to withdraw
    function withdrawAll() public onlyOwner {
        address payable s = payable(msg.sender);
        require(s.send(address(this).balance));
    }

    function withdrawETH(uint256 _amount) public onlyOwner {
        uint256 ethBal = address(this).balance;
        require(_amount <= ethBal, "Not enough ETH in Contract.");

        address payable s = payable(msg.sender);
        require(s.send(_amount));
    }

    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function EthToToken(uint256 weiAmount) public view returns (uint256 val) {
        require(weiAmount > 0, "You need to send some ether");

        uint256 tokenWeiAmount =
            ((multiply(weiAmount, (10**decimals)) / 1 ether) * CPNPrice);

        return (tokenWeiAmount);
    }

    function buyTokens() public payable returns (bool) {
        address buyer = msg.sender;
        require(buyer != address(0));
        require(tokenBlacklist[buyer] == false, "Buyer is blacklist address.");

        uint256 weiAmount = msg.value;
        require(weiAmount > 0, "You need to send some ether");

        uint256 tokenWeiAmount =
            ((multiply(weiAmount, (10**decimals)) / 1 ether) * CPNPrice);

        require(
            balances[owner] >= tokenWeiAmount,
            "Owner do not have enough Tokens."
        );

        balances[owner] = balances[owner].sub(tokenWeiAmount);
        balances[buyer] = balances[buyer].add(tokenWeiAmount);

        addStakeholder(buyer);
        emit Bought(buyer, tokenWeiAmount);

        return true;
    }
}