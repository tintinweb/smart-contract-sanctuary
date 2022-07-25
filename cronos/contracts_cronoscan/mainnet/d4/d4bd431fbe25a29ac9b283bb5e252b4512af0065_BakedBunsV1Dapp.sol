/**
 *Submitted for verification at cronoscan.com on 2022-05-30
*/

// SPDX-License-Identifier: MIT

//BAKED BUNS V1 DAPP
//WELCOME BAKERS - Invest CRO to Hire Bakers to Bake Buns, 
//Re-bake your Buns and Collect your paycheck in CRO every day!
//VISIT OUR WHITEPAPER DOCS.BAKEDBUNS.FARM

pragma solidity 0.8.7;

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract BakedBunsV1Dapp is Context, Ownable {
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
 
    using SafeMath for uint256;

    uint256 constant public TIME_PER_KEEPER = 1440000; // 6 % a day, i.e. 1/0.06 days = 86400/0.06 = 1440000
    uint256 constant private PSN = 10000;
    uint256 constant private PSNH = 5000;
    uint256 constant public councilFee = 3; // 3%

    mapping (address => uint256) public keepers; // basis for display: 6 decimal places
    mapping (address => uint256) public claimedTime; // basis for display: 6 decimal places
    mapping (address => uint256) public lastConstruct;
    mapping (address => address) public referrals;
    uint256 public marketTime; // basis for display: 6 decimal places

    mapping (address => bool) public whitelisters;

    address payable public treasuryWallet;
    address payable public marketingWallet;
    address payable public devWallet2;

    uint256 public whitelistUNIX;
    uint256 public publicUNIX;
    uint256 public nextInterventionUNIX;
    uint256 public interventionStep = 604800; // 14 days
    
    constructor(address _treasuryWallet, address _marketingWallet, address _devWallet2, uint256 _whitelistUNIX, uint256 _whitelistLength) {
        treasuryWallet = payable(_treasuryWallet);
        marketingWallet = payable(_marketingWallet);
        devWallet2 = payable(_devWallet2);
        
        whitelistUNIX = _whitelistUNIX;
        publicUNIX = SafeMath.add(whitelistUNIX, _whitelistLength);
        nextInterventionUNIX = SafeMath.add(publicUNIX, interventionStep);

        seedWhitelist();
    }
    
    function syncTKeepers(address ref) public checkLaunchTime {        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 timeUsed = getMyTime(msg.sender);
        uint256 newKeepers = SafeMath.div(timeUsed,TIME_PER_KEEPER);
        keepers[msg.sender] = SafeMath.add(keepers[msg.sender],newKeepers);
        claimedTime[msg.sender] = 0;
        lastConstruct[msg.sender] = block.timestamp;
        
        //send referral time
        claimedTime[referrals[msg.sender]] = SafeMath.add(claimedTime[referrals[msg.sender]],SafeMath.div(timeUsed,8));
        
        //boost market to nerf miners hoarding
        marketTime=SafeMath.add(marketTime, timeUsed.mul(15).div(100));
    }
    
    function desyncTime() public checkLaunchTime {
        uint256 hasTime = getMyTime(msg.sender);
        uint256 timeValue = calculateTimeSell(hasTime);
        uint256 fee = getCouncilFee(timeValue);
        claimedTime[msg.sender] = 0;
        lastConstruct[msg.sender] = block.timestamp;
        marketTime = SafeMath.add(marketTime,hasTime);

        treasuryWallet.transfer(fee.div(3));
        marketingWallet.transfer(fee.div(3));
        devWallet2.transfer(fee.div(3));
        
        payable (msg.sender).transfer(SafeMath.sub(timeValue,fee));
    }
    
    function fabricateTime(address ref) public payable checkLaunchTime {
        uint256 timeBought = calculateTimeBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        timeBought = SafeMath.sub(timeBought,getCouncilFee(timeBought));
        uint256 fee = getCouncilFee(msg.value);
        
        treasuryWallet.transfer(fee.div(3));
        marketingWallet.transfer(fee.div(3));
        devWallet2.transfer(fee.div(3));
        
        claimedTime[msg.sender] = SafeMath.add(claimedTime[msg.sender],timeBought).mul(getProgressiveMultiplier()).div(10000);
        syncTKeepers(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateTimeSell(uint256 time) public view returns(uint256) {
        return calculateTrade(time,marketTime,address(this).balance);
    }
    
    function calculateTimeBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketTime);
    }
    
    function calculateTimeBuySimple(uint256 eth) public view returns(uint256) {
        return calculateTimeBuy(eth,address(this).balance);
    }
    
    function getCouncilFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,councilFee),100);
    }
    
    function seedMarket() public payable onlyOwner {
        require(marketTime == 0, "Bad init: already initialized");
        require(msg.value == 1 ether, "Bad init: amount of CRO");
        marketTime = TIME_PER_KEEPER.mul(100000);
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyKeepers(address adr) public view returns(uint256) {
        return keepers[adr];
    }
    
    function getMyTime(address adr) public view returns(uint256) {
        return SafeMath.add(claimedTime[adr],getTimeSinceLastConstruct(adr));
    }
    
    function getTimeSinceLastConstruct(address adr) public view returns(uint256) {
        uint256 secondsPassed=SafeMath.sub(block.timestamp,lastConstruct[adr]);
        return SafeMath.mul(secondsPassed,keepers[adr]);
    }


    modifier checkLaunchTime() {
        require(block.timestamp >= whitelistUNIX, "Protocol not launched yet!");
        if(block.timestamp < publicUNIX) {
            require(whitelisters[msg.sender], "Wallet not whitelisted for early launch!");
        }
        _;
    }

    function getProgressiveMultiplier() public view returns(uint256) {
        uint256 x = block.timestamp;
        if(x <= publicUNIX) {
            return 10000;
        }
        x = x.sub(publicUNIX).mul(10000).div(6); // should be +1/6% after first month to become 7%
        return x.div(30).div(86400).add(10000);
    }

    function councilIntervention(uint256 interventionType) public onlyOwner {
        require(block.timestamp >= nextInterventionUNIX, "Cannot intervene yet!");
        require(interventionType <= 2, "Unrecognized type of intervention.");
        nextInterventionUNIX = SafeMath.add(block.timestamp, interventionStep);

        // interventionType == 0: waive (in balanced market)
        if(interventionType == 1) { // boost for new entrants (in recessionary market)
            marketTime = marketTime.mul(11).div(10);
        }
        if(interventionType == 2) { // burn (in very expansionary market)
            marketTime = marketTime.mul(9).div(10);
        }
    }

    function whitelistAdd(address adr) public onlyOwner {
        whitelisters[adr] = true;
    }

    function whitelistRemove(address adr) public onlyOwner {
        whitelisters[adr] = false;
    }

    function seedWhitelist() internal {
    whitelistAdd(address(0x520c873b97b71f30C57FBB52b42928A3839aa925));
	whitelistAdd(address(0xef8BE16533f2dB28a64D1C64773e4Dd202D39cDe));
	 	

    }
}