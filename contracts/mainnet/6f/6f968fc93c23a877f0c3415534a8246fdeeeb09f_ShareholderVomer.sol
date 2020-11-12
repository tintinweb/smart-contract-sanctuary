pragma solidity ^0.5.16;

/**
Get profit every month with a contract Shareholder VOMER!
*
* - OBTAINING 20%, 15% or 10% PER 1 MONTH. (percentages are charged in equal parts every 1 sec)
* - lifetime payments
* - unprecedentedly reliable
* - bring luck
* - first minimum contribution from 2 eth, all next from 0.01 eth
* - Currency and Payment - ETH
* - Contribution allocation schemes:
* - 100% of payments - 5% percent for support and 25% percent for partner
*
* VOMER.net
*
* RECOMMENDED GAS LIMIT: 200,000
* RECOMMENDED GAS PRICE: https://ethgasstation.info/
* DO NOT TRANSFER DIRECTLY FROM AN EXCHANGE (only use your ETH wallet, from which you have a private key)
* You can check payments on the website etherscan.io, in the “Internal Txns” tab of your wallet.
*
* Partner 25%.
* Developers 5%

* Restart of the contract is also absent. If there is no money in the Fund, payments are stopped and resumed after the Fund is filled. Thus, the contract will work forever!
*
* How to use:
* 1. Send from your ETH wallet to the address of the smart contract
* 2. Confirm your transaction in the history of your application or etherscan.io, indicating the address of your wallet.
* Take profit by sending any amount of eth to contract (profit is calculated every second).
*
**/

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

contract ERC20Token
{
    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

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
        require(c >= a);

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
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    uint256 constant WAD = 10 ** 18;

    function wdiv(uint x, uint y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function wmul(uint x, uint y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
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
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address payable public owner = msg.sender;
    address payable public newOwnerCandidate;

    modifier onlyOwner()
    {
        assert(msg.sender == owner);
        _;
    }

    function changeOwnerCandidate(address payable newOwner) public onlyOwner {
        newOwnerCandidate = newOwner;
    }

    function acceptOwner() public {
        require(msg.sender == newOwnerCandidate);
        owner = newOwnerCandidate;
    }
}

contract ShareholderVomer is Initializable
{
    using SafeMath for *;

    address payable public owner;
    address payable public newOwnerCandidate;

    address payable public support1;
    address payable public support2;

    struct InvestorData {
        uint128 fundsVMR;
        uint128 totalProfit;
        uint128 pendingReward;
        uint64 lastDatetime;
        uint8 percent;
    }
    
    uint256 public totalUsers;
    
    mapping (address => InvestorData) investors;

    uint256 public rateIn;
    uint256 public rateOut;

    modifier onlyOwner()
    {
        assert(msg.sender == owner);
        _;
    }

    function initialize() initializer public {
        address payable _owner = 0xBF165e10878628768939f0415d7df2A9d52f0aB0;
        owner = _owner;
        support1 = _owner;
        support2 = _owner;
        rateIn = 10**18;
        rateOut = 10**18;
    }

    function setSupport1(address payable _newAddress) public onlyOwner {
        require(_newAddress != address(0));
        support1 = _newAddress;
    }
    
    function setSupport2(address payable _newAddress) public onlyOwner {
        require(_newAddress != address(0));
        support2 = _newAddress;
    }
    
    function setRateIn_Wei(uint256 _newValue) public onlyOwner {
        require(_newValue > 0);
        rateIn = _newValue;
    }
    
    function setRateOut_Wei(uint256 _newValue) public onlyOwner {
        require(_newValue > 0);
        rateOut = _newValue;
    }

    function withdraw(uint256 amount)  public onlyOwner {
        owner.transfer(amount);
    }


    function changeOwnerCandidate(address payable newOwner) public onlyOwner {
        newOwnerCandidate = newOwner;
    }

    function acceptOwner() public {
        require(msg.sender == newOwnerCandidate);
        owner = newOwnerCandidate;
    }

    // function for transfer any token from contract
    function transferTokens (address token, address target, uint256 amount) onlyOwner public
    {
        ERC20Token(token).transfer(target, amount);
    }

    function safeEthTransfer(address target, uint256 amount) internal {
        address payable payableTarget = address(uint160(target));
        (bool ok, ) = payableTarget.call.value(amount)("");
        require(ok);
    }
    
    function getInfo(address investor) view public returns (uint256 contractBalance, uint128 depositVMR, uint128 lastDatetime, uint128 totalProfit, uint128 percent, uint256 _totalUsers, uint256 pendingRewardVMR, uint256 pendingRewardETH)
    {
        contractBalance = address(this).balance;
        InvestorData memory data = investors[investor];
        depositVMR = data.fundsVMR;
        lastDatetime = data.lastDatetime;
        totalProfit = data.totalProfit;
        percent = data.percent;
        _totalUsers = totalUsers;
        
        pendingRewardVMR = depositVMR.mul(data.percent).div(100).mul(block.timestamp - data.lastDatetime).div(30 days);
            
        pendingRewardVMR = uint128(data.pendingReward.add(pendingRewardVMR));
        
        pendingRewardETH = uint128(pendingRewardVMR.wmul(rateOut));
    }
    
    function () payable external
    {
        require(msg.sender == tx.origin); // prevent bots to interact with contract

        if (msg.sender == owner) return;

        InvestorData storage data = investors[msg.sender];
        
        uint128 _lastDatetime = data.lastDatetime;
        uint128 _fundsVMR = data.fundsVMR;
        uint256 _rateIn = rateIn;
        
        if (msg.value > 0)
        {
            support1.transfer(msg.value.mul(25).div(100)); // 25%
            support2.transfer(msg.value.mul(5).div(100));  // 5%
        }

        if (_fundsVMR != 0) {
            // N% per 30 days
            uint256 rewardVMR = _fundsVMR.mul(data.percent).div(100).mul(block.timestamp - _lastDatetime).div(30 days);
            
            uint128 _pendingReward = data.pendingReward;
            if (_fundsVMR < 1 ether) {
                data.pendingReward = uint128(_pendingReward.add(rewardVMR));
            } else {
                rewardVMR = rewardVMR.add(_pendingReward);
                data.totalProfit = uint128(data.totalProfit.add(uint128(rewardVMR)));
            
                uint256 rewardETH = rewardVMR.wmul(rateOut);
            
                if (_pendingReward > 0) data.pendingReward = 0;
                
                if (rewardETH > 0) safeEthTransfer(msg.sender, rewardETH);
            }
        }
        
        if (_lastDatetime == 0 && _fundsVMR == 0) { // new user !
            uint256 _totalUsers = totalUsers;
            
            if (_totalUsers <= 1000) {
                data.percent = 20;
                _fundsVMR = uint128((0.3 ether).wmul(_rateIn)); // bonus
            } else if (_totalUsers <= 10000) {
                data.percent = 15;
                _fundsVMR = uint128((0.2 ether).wmul(_rateIn)); // bonus
            } else {
                data.percent = 10; 
                _fundsVMR = uint128((0.1 ether).wmul(_rateIn)); // bonus
            }
            
            totalUsers = _totalUsers + 1;
        }

        data.lastDatetime = uint64(block.timestamp);
        data.fundsVMR = uint128(_fundsVMR.add(msg.value.mul(70).div(100).wmul(_rateIn)));

    }
}