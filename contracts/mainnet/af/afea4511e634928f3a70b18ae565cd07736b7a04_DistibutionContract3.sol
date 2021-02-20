/**
 *Submitted for verification at Etherscan.io on 2021-02-20
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-28
*/

/**
 *Submitted for verification at Etherscan.io on 2018-09-01
*/

pragma solidity 0.5.8; 

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
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
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.



contract DistibutionContract3 is Pausable {
    using SafeMath for uint256;

    uint256 constant public decimals = 1 ether;
    address[] public tokenOwners ; /* Tracks distributions mapping (iterable) */
    uint256 public TGEDate = 0; /* Date From where the distribution starts (TGE) */
    uint256 constant public month = 30 days;
    uint256 constant public year = 365 days;
    uint256 public lastDateDistribution = 0;
    
    mapping(address => DistributionStep[]) public distributions; /* Distribution object */
    
    ERC20 public erc20;

    struct DistributionStep {
        uint256 amountAllocated;
        uint256 currentAllocated;
        uint256 unlockDay;
        uint256 amountSent;
    }

    constructor() public{
        
        /* Private Sale 3 */
        setInitialDistribution(0x6B8b3A59527c3DD984c508f27413a4c7B4352EEd, 80000, 1*month);
        setInitialDistribution(0x6B8b3A59527c3DD984c508f27413a4c7B4352EEd, 80000, 2*month);
        setInitialDistribution(0x6B8b3A59527c3DD984c508f27413a4c7B4352EEd, 80000, 3*month);

        setInitialDistribution(0x8e76aB487a510cc62f5dE305e98fc738aeC82405, 60000, 1*month);
        setInitialDistribution(0x8e76aB487a510cc62f5dE305e98fc738aeC82405, 60000, 2*month);
        setInitialDistribution(0x8e76aB487a510cc62f5dE305e98fc738aeC82405, 60000, 3*month);

        setInitialDistribution(0xd6C5e78cc909014e26620d8ff4dB4463C792E310, 130000, 1*month);
        setInitialDistribution(0xd6C5e78cc909014e26620d8ff4dB4463C792E310, 130000, 2*month);
        setInitialDistribution(0xd6C5e78cc909014e26620d8ff4dB4463C792E310, 130000, 3*month);

        setInitialDistribution(0xFc6EFF3ECE4FD66B3C97d53605A93a4E5963bBf0, 50000, 1*month);
        setInitialDistribution(0xFc6EFF3ECE4FD66B3C97d53605A93a4E5963bBf0, 50000, 2*month);
        setInitialDistribution(0xFc6EFF3ECE4FD66B3C97d53605A93a4E5963bBf0, 50000, 3*month);

        setInitialDistribution(0xB50c06686657C2f2131fd04918bF20840B83Bd51, 30000, 1*month);
        setInitialDistribution(0xB50c06686657C2f2131fd04918bF20840B83Bd51, 30000, 2*month);
        setInitialDistribution(0xB50c06686657C2f2131fd04918bF20840B83Bd51, 30000, 3*month);

        setInitialDistribution(0x1f4e65DED886DC708a278f05ea107244A8161bf7, 30000, 1*month);
        setInitialDistribution(0x1f4e65DED886DC708a278f05ea107244A8161bf7, 30000, 2*month);
        setInitialDistribution(0x1f4e65DED886DC708a278f05ea107244A8161bf7, 30000, 3*month);

        setInitialDistribution(0x883aD562D0a83569dA00DdF88C96C348519c0030, 25000, 1*month);
        setInitialDistribution(0x883aD562D0a83569dA00DdF88C96C348519c0030, 25000, 2*month);
        setInitialDistribution(0x883aD562D0a83569dA00DdF88C96C348519c0030, 25000, 3*month);

        setInitialDistribution(0xEEff483b297016938400575043752A2d10d7579A, 50000, 1*month);
        setInitialDistribution(0xEEff483b297016938400575043752A2d10d7579A, 50000, 2*month);
        setInitialDistribution(0xEEff483b297016938400575043752A2d10d7579A, 50000, 3*month);

        setInitialDistribution(0x0Ed67dAaacf97acF041cc65f04A632a8811347fF, 70000, 1*month);
        setInitialDistribution(0x0Ed67dAaacf97acF041cc65f04A632a8811347fF, 70000, 2*month);
        setInitialDistribution(0x0Ed67dAaacf97acF041cc65f04A632a8811347fF, 70000, 3*month);

        setInitialDistribution(0xA7cC7B0f40763a5baEc1AF3f631eb7B6e56cacD4, 17500, 1*month);
        setInitialDistribution(0xA7cC7B0f40763a5baEc1AF3f631eb7B6e56cacD4, 17500, 2*month);
        setInitialDistribution(0xA7cC7B0f40763a5baEc1AF3f631eb7B6e56cacD4, 17500, 3*month);

        setInitialDistribution(0xB90e7F5fE86775ea8A2ea5241d8D745265F721D2, 100000, 1*month);
        setInitialDistribution(0xB90e7F5fE86775ea8A2ea5241d8D745265F721D2, 100000, 2*month);
        setInitialDistribution(0xB90e7F5fE86775ea8A2ea5241d8D745265F721D2, 100000, 3*month);

        setInitialDistribution(0x778C029675d3e2435Cf4C207E981D37c2174bec8, 40000, 1*month);
        setInitialDistribution(0x778C029675d3e2435Cf4C207E981D37c2174bec8, 40000, 2*month);
        setInitialDistribution(0x778C029675d3e2435Cf4C207E981D37c2174bec8, 40000, 3*month);

        setInitialDistribution(0xE1176052966f14802BB3755bbdfcaA712B4708e8, 17500, 1*month);
        setInitialDistribution(0xE1176052966f14802BB3755bbdfcaA712B4708e8, 17500, 2*month);
        setInitialDistribution(0xE1176052966f14802BB3755bbdfcaA712B4708e8, 17500, 3*month);

        setInitialDistribution(0x3c87E00da8551C73032496Aa60D9BD980510CBAF, 70000, 1*month);
        setInitialDistribution(0x3c87E00da8551C73032496Aa60D9BD980510CBAF, 70000, 2*month);
        setInitialDistribution(0x3c87E00da8551C73032496Aa60D9BD980510CBAF, 70000, 3*month);

        setInitialDistribution(0x53A2f447C61152917493679F8105811198648d81, 60000, 1*month);
        setInitialDistribution(0x53A2f447C61152917493679F8105811198648d81, 60000, 2*month);
        setInitialDistribution(0x53A2f447C61152917493679F8105811198648d81, 60000, 3*month);

        setInitialDistribution(0x7Da633fcF51838e688676AD30C2cC6A08c59c316, 10000, 1*month);
        setInitialDistribution(0x7Da633fcF51838e688676AD30C2cC6A08c59c316, 10000, 2*month);
        setInitialDistribution(0x7Da633fcF51838e688676AD30C2cC6A08c59c316, 10000, 3*month);

        setInitialDistribution(0x7Aa48800c1f5cb80A670cB66635dD382237777c6, 30000, 1*month);
        setInitialDistribution(0x7Aa48800c1f5cb80A670cB66635dD382237777c6, 30000, 2*month);
        setInitialDistribution(0x7Aa48800c1f5cb80A670cB66635dD382237777c6, 30000, 3*month);

        setInitialDistribution(0x5FD7E077dA76E286bD0A50bC545A5883108C364f, 40000, 1*month);
        setInitialDistribution(0x5FD7E077dA76E286bD0A50bC545A5883108C364f, 40000, 2*month);
        setInitialDistribution(0x5FD7E077dA76E286bD0A50bC545A5883108C364f, 40000, 3*month);

        setInitialDistribution(0x9aA562422Ed5079E5C3C38A0733392543653C3db, 120000, 1*month);
        setInitialDistribution(0x9aA562422Ed5079E5C3C38A0733392543653C3db, 120000, 2*month);
        setInitialDistribution(0x9aA562422Ed5079E5C3C38A0733392543653C3db, 120000, 3*month);

    }

    function setTokenAddress(address _tokenAddress) external onlyOwner whenNotPaused  {
        erc20 = ERC20(_tokenAddress);
    }
    
    function safeGuardAllTokens(address _address) external onlyOwner whenPaused  { /* In case of needed urgency for the sake of contract bug */
        require(erc20.transfer(_address, erc20.balanceOf(address(this))));
    }

    function setTGEDate(uint256 _time) external onlyOwner whenNotPaused  {
        TGEDate = _time;
    }

    /**
    *   Should allow any address to trigger it, but since the calls are atomic it should do only once per day
     */

    function triggerTokenSend() external whenNotPaused  {
        /* Require TGE Date already been set */
        require(TGEDate != 0, "TGE date not set yet");
        /* TGE has not started */
        require(block.timestamp > TGEDate, "TGE still hasn´t started");
        /* Test that the call be only done once per day */
        require(block.timestamp.sub(lastDateDistribution) > 1 days, "Can only be called once a day");
        lastDateDistribution = block.timestamp;
        /* Go thru all tokenOwners */
        for(uint i = 0; i < tokenOwners.length; i++) {
            /* Get Address Distribution */
            DistributionStep[] memory d = distributions[tokenOwners[i]];
            /* Go thru all distributions array */
            for(uint j = 0; j < d.length; j++){
                if( (block.timestamp.sub(TGEDate) > d[j].unlockDay) /* Verify if unlockDay has passed */
                    && (d[j].currentAllocated > 0) /* Verify if currentAllocated > 0, so that address has tokens to be sent still */
                ){
                    uint256 sendingAmount;
                    sendingAmount = d[j].currentAllocated;
                    distributions[tokenOwners[i]][j].currentAllocated = distributions[tokenOwners[i]][j].currentAllocated.sub(sendingAmount);
                    distributions[tokenOwners[i]][j].amountSent = distributions[tokenOwners[i]][j].amountSent.add(sendingAmount);
                    require(erc20.transfer(tokenOwners[i], sendingAmount));
                }
            }
        }   
    }

    function setInitialDistribution(address _address, uint256 _tokenAmount, uint256 _unlockDays) internal onlyOwner whenNotPaused {
        /* Add tokenOwner to Eachable Mapping */
        bool isAddressPresent = false;

        /* Verify if tokenOwner was already added */
        for(uint i = 0; i < tokenOwners.length; i++) {
            if(tokenOwners[i] == _address){
                isAddressPresent = true;
            }
        }
        /* Create DistributionStep Object */
        DistributionStep memory distributionStep = DistributionStep(_tokenAmount * decimals, _tokenAmount * decimals, _unlockDays, 0);
        /* Attach */
        distributions[_address].push(distributionStep);

        /* If Address not present in array of iterable token owners */
        if(!isAddressPresent){
            tokenOwners.push(_address);
        }
    }
}