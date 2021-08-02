/**
 *Submitted for verification at polygonscan.com on 2021-08-01
*/

pragma solidity ^0.7.0;

// SiriCoin is a token made on #Polygon with a very low difficulty, that allows mining it through browser !!!
// In browser mining we tru$t !!



interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
	
	function _chainId() internal pure returns (uint256) {
		uint256 id;
		assembly {
			id := chainid()
		}
		return id;
	}
	
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract SiriCoin is Owned {
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowances;
	uint256 public _totalSupply;
	uint8 public decimals = 18;
	string public name = "SiriCoin";
	string public symbol = "SC";
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

	uint public timeOfLastProof;
	uint256 public _MINIMUM_TARGET = 2**16;
	uint256 public _MAXIMUM_TARGET = 2**245;
	uint256 public miningTarget = _MAXIMUM_TARGET;
	uint256 public timeOfLastReadjust;
	uint256 public baseReward = 50000000000000000000;
	uint32 public blocktime = 150;
	uint public epochCount = 1;
	bytes32 public currentChallenge;
	uint public epochLenght = 600; // epoch lenght in seconds (10 minutes there)
	mapping (uint256 => bytes32) epochs;
	event Mint(address indexed from, uint rewardAmount, uint epochCount, bytes32 newChallengeNumber);
	
	address public minerOfLastBlock;
	
	using SafeMath for uint256;
	
	function totalSupply() public view returns (uint256) {
		return _totalSupply - balances[address(0)];
	}
	
	function balanceOf(address guy) public view returns (uint256) {
		if (guy == address(0)) { return 0; }
		return balances[guy];
	}
	
	function allowance(address owner, address spender) public view returns (uint256) {
		return allowances[owner][spender];
	}
	
    function approve(address spender, uint tokens) public returns (bool success) {
        allowances[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        approve(spender, allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        approve(spender, allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
	
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
		approve(spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
	
	function _transfer(address from, address to, uint256 amount) internal {
		balances[from] = balances[from].sub(amount);
		balances[to] = balances[to].add(amount);
		emit Transfer(from, to, amount);
	}
	
	function transfer(address to, uint256 amount) public returns (bool) {
		_transfer(msg.sender, to, amount);
		return true;
	}
	
	function transferFrom(address from, address to, uint256 amount) public returns (bool) {
		allowances[from][msg.sender] = allowances[from][msg.sender].sub(amount);
		_transfer(from, to, amount);
		return true;
	}

	function getMiningDifficulty() public view returns (uint) {
		return _MAXIMUM_TARGET/miningTarget;
	}

	function getChallengeNumber() public view returns (bytes32) {
		return currentChallenge;
	}
	

	function getMiningReward() public view returns (uint256) {
		return baseReward;
	}

	function calcMiningTarget() public view returns (uint256) {
		return miningTargetForDelay(block.timestamp - timeOfLastReadjust);
	}

	function miningTargetForDelay(uint256 blockdelay) public view returns (uint256) {
			uint256 calculatedTarget = netTargetForDelay(blockdelay);
			if (calculatedTarget >= _MAXIMUM_TARGET) {
				return _MAXIMUM_TARGET;
			} else if (calculatedTarget < _MINIMUM_TARGET) {
				return _MINIMUM_TARGET;
			} else {
				return calculatedTarget;
			}
	}

	function netTargetForDelay(uint256 blockdelay) public view returns (uint256) {
		return (miningTarget*(blockdelay))/(blocktime*128);
	}

	function _newEpoch(uint256 _nonce) internal {
		currentChallenge = bytes32(keccak256(abi.encodePacked(_nonce, currentChallenge, blockhash(block.number - 1), "Bernie Sanders here")));
		if ((epochCount%128) == 0) {
			miningTarget = calcMiningTarget();
			timeOfLastReadjust = block.timestamp;
		}
		if ((epochCount%210000) == 0) {
			baseReward = baseReward/10;
			baseReward = baseReward/2;
			baseReward = baseReward*10;
		}
		timeOfLastProof = block.timestamp;
		epochCount += 1;
	}

	function getMiningTarget() public view returns (uint256) {
		return miningTarget;
	}

	function changeDifficulty(uint256 _difficulty) public onlyOwner {
		require(_difficulty > 0);
		miningTarget = _MAXIMUM_TARGET/_difficulty;
	}

	function _mint(uint256 nonce, bytes32 challenge_digest, address _miner) public returns (bool) {
		bytes32 n = keccak256(abi.encodePacked(currentChallenge, _miner, nonce));
		require(challenge_digest == n);
		require(n <= bytes32(miningTarget));
		
		balances[_miner] = balances[_miner].add(getMiningReward());
		_totalSupply = _totalSupply.add(getMiningReward());
		emit Mint(_miner, getMiningReward(), epochCount, currentChallenge);
		emit Transfer(address(0), _miner, getMiningReward());
		_newEpoch(nonce);
		minerOfLastBlock = _miner;
		return true;
	}


	function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {
		return _mint(nonce, challenge_digest, msg.sender);
	}
}