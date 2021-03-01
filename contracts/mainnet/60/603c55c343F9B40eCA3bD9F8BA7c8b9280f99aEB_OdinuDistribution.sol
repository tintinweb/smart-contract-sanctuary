/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

contract Ownable {
    address public owner;
    address private _nextOwner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, 'Only the owner of the contract can do that');
        _;
    }
    
    function transferOwnership(address nextOwner) public onlyOwner {
        _nextOwner = nextOwner;
    }
    
    function takeOwnership() public {
        require(msg.sender == _nextOwner, 'Must be given ownership to do that');
        emit OwnershipTransferred(owner, _nextOwner);
        owner = _nextOwner;
    }
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b != 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract OdinuDistribution is Ownable {
    using SafeMath for uint256;
    
    // 0 - SEED
    // 1 - PRIVATE
    // 2 - TEAM
    // 3 - ADVISOR
    // 4 - ECOSYSTEM
    // 5 - LIQUIDITY
    // 6 - RESERVE
    enum POOL{SEED, PRIVATE, TEAM, ADVISOR, ECOSYSTEM, LIQUIDITY, RESERVE}
    
    mapping (POOL => uint) public pools;
    
    uint256 public totalSupply;
    string public constant name = "Odinu";
    uint256 public constant decimals = 18;
    string public constant symbol = "ODU";
    address[] public participants;
    
    bool private isActive;
    uint256 private scanLength = 150;
    uint256 private continuePoint;
    uint256[] private deletions;
    
    mapping (address => uint256) private balances;
    mapping (address => mapping(address => uint256)) private allowances;
    mapping (address => uint256) public lockoutPeriods;
    mapping (address => uint256) public lockoutBalances;
    mapping (address => uint256) public lockoutReleaseRates;
    
    event Active(bool isActive);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Burn(address indexed tokenOwner, uint tokens);
    
    constructor () {
        pools[POOL.SEED] = 15000000 * 10**decimals;
        pools[POOL.PRIVATE] = 16000000 * 10**decimals;
        pools[POOL.TEAM] = 18400000 * 10**decimals;
        pools[POOL.ADVISOR] = 10350000 * 10**decimals;
        pools[POOL.ECOSYSTEM] = 14375000 * 10**decimals;
        pools[POOL.LIQUIDITY] = 8625000 * 10**decimals;
        pools[POOL.RESERVE] = 32250000 * 10**decimals;
        
        totalSupply = pools[POOL.SEED] + pools[POOL.PRIVATE] + pools[POOL.TEAM] + pools[POOL.ADVISOR] + pools[POOL.ECOSYSTEM] + pools[POOL.LIQUIDITY] + pools[POOL.RESERVE];

        // Give POLS private sale directly
        uint pols = 2000000 * 10**decimals;
        pools[POOL.PRIVATE] = pools[POOL.PRIVATE].sub(pols);
        balances[address(0xeFF02cB28A05EebF76cB6aF993984731df8479b1)] = pols;
        
        // Give LIQUIDITY pool their half directly
        uint liquid = pools[POOL.LIQUIDITY].div(2);
        pools[POOL.LIQUIDITY] = pools[POOL.LIQUIDITY].sub(liquid);
        balances[address(0xd6221a4f8880e9Aa355079F039a6012555556974)] = liquid;
    }
    
    function _isTradeable() internal view returns (bool) {
        return isActive;
    }
    
    function isTradeable() public view returns (bool) {
        return _isTradeable();
    }
    
    function setTradeable() external onlyOwner {
        require (!isActive, "Can only set tradeable when its not already tradeable");
        isActive = true;
        Active(true);
    }
    
    function setScanLength(uint256 len) external onlyOwner {
        scanLength = len;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint) {
        return allowances[tokenOwner][spender];
    }
    
    function spendable(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner].sub(lockoutBalances[tokenOwner]);
    }
    
    function transfer(address to, uint tokens) public returns (bool) {
        require (_isTradeable(), "Contract is not tradeable yet");
        require (balances[msg.sender].sub(lockoutBalances[msg.sender]) >= tokens, "Must have enough spendable tokens");
        require (tokens > 0, "Must transfer non-zero amount");
        require (to != address(0), "Cannot send to the 0 address");
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    
    function approve(address spender, uint tokens) public returns (bool) {
        _approve(msg.sender, spender, tokens);
        return true;
    }
    
    function _approve(address owner, address spender, uint tokens) internal {
        require (owner != address(0), "Cannot approve from the 0 address");
        require (spender != address(0), "Cannot approve the 0 address");
        
        allowances[owner][spender] = tokens;
        Approval(owner, spender, tokens);
    }
    
    function burn(uint tokens) public {
        require (balances[msg.sender].sub(lockoutBalances[msg.sender]) >= tokens, "Must have enough spendable tokens");
        require (tokens > 0, "Must burn non-zero amount");
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        totalSupply = totalSupply.sub(tokens);
        Burn(msg.sender, tokens);
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool) {
        require (_isTradeable(), "Contract is not trading yet");
        require (balances[from].sub(lockoutBalances[from]) >= tokens, "Must have enough spendable tokens");
        require (allowances[from][msg.sender] >= tokens, "Must be approved to spend that much");
        require (tokens > 0, "Must transfer non-zero amount");
        require (from != address(0), "Cannot send from the 0 address");
        require (to != address(0), "Cannot send to the 0 address");
        
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowances[from][msg.sender] = allowances[from][msg.sender].sub(tokens);
        Transfer(from, to, tokens);
        return true;
    }
    
    function addParticipants(POOL pool, address[] calldata _participants, uint256[] calldata _stakes) external onlyOwner {
        require (pool >= POOL.SEED && pool <= POOL.RESERVE, "Must select a valid pool");
        require (_participants.length == _stakes.length, "Must have equal array sizes");
        
        uint lockoutPeriod;
        uint lockoutReleaseRate;
        
        if (pool == POOL.SEED) {
            lockoutPeriod = 1;
            lockoutReleaseRate = 5;
        } else if (pool == POOL.PRIVATE) {
            lockoutReleaseRate = 4;
        } else if (pool == POOL.TEAM) {
            lockoutPeriod = 12;
            lockoutReleaseRate = 12;
        } else if (pool == POOL.ADVISOR) {
            lockoutPeriod = 6;
            lockoutReleaseRate = 6;
        } else if (pool == POOL.ECOSYSTEM) {
            lockoutPeriod = 3;
            lockoutReleaseRate = 9;
        } else if (pool == POOL.LIQUIDITY) {
            lockoutReleaseRate = 1;
            lockoutPeriod = 1;
        } else if (pool == POOL.RESERVE) {
            lockoutReleaseRate = 18;
        }
        
        uint256 sum;
        uint256 len = _participants.length;
        for (uint256 i = 0; i < len; i++) {
            address p = _participants[i];
            require(lockoutBalances[p] == 0, "Participants can't be involved in multiple lock ups simultaneously");
        
            participants.push(p);
            lockoutBalances[p] = _stakes[i];
            balances[p] = balances[p].add(_stakes[i]);
            lockoutPeriods[p] = lockoutPeriod;
            lockoutReleaseRates[p] = lockoutReleaseRate;
            sum = sum.add(_stakes[i]);
        }
        
        require(sum <= pools[pool], "Insufficient amount left in pool for this");
        pools[pool] = pools[pool].sub(sum);
    }
    
    function finalizeParticipants(POOL pool) external onlyOwner {
        uint leftover = pools[pool];
        pools[pool] = 0;
        totalSupply = totalSupply.sub(leftover);
    }
    
    /**
     * For each account with an active lockout, if their lockout has expired 
     * then release their lockout at the lockout release rate
     * If the lockout release rate is 0, assume its all released at the date
     * Only do max 100 at a time, call repeatedly which it returns true
     */
    function updateRelease() external onlyOwner returns (bool) {
        uint scan = scanLength;
        uint len = participants.length;
        uint continueAddScan = continuePoint.add(scan);
        for (uint i = continuePoint; i < len && i < continueAddScan; i++) {
            address p = participants[i];
            if (lockoutPeriods[p] > 0) {
                lockoutPeriods[p]--;
            } else if (lockoutReleaseRates[p] > 0) {
                uint rate = lockoutReleaseRates[p];
                
                uint release;
                if (rate == 18) {
                    // First release of reserve is 12.5%
                    release = lockoutBalances[p].div(8);
                } else {
                    release = lockoutBalances[p].div(lockoutReleaseRates[p]);
                }
                
                lockoutBalances[p] = lockoutBalances[p].sub(release);
                lockoutReleaseRates[p]--;
            } else {
                deletions.push(i);
            }
        }
        continuePoint = continuePoint.add(scan);
        if (continuePoint >= len) {
            continuePoint = 0;
            while (deletions.length > 0) {
                uint index = deletions[deletions.length-1];
                deletions.pop();

                participants[index] = participants[participants.length - 1];
                participants.pop();
            }
            return false;
        }
        
        return true;
    }
}