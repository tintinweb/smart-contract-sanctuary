/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

pragma solidity ^0.7.0;

//SPDX-License-Identifier: MIT



interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

interface minterInterface {
	function mintTo(address to, uint256 tokens) external;
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
	
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

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


contract staking is Owned {
	using SafeMath for uint256;
	uint256 public apr = 5;
	mapping (address => uint256) public userApr;
	mapping (address => uint256) stakedBalances;
	mapping (address => uint256) public lastClaim;
	mapping (address => bool) _hasStaked;
	uint256 totalStakedAmount;


	ERC20Interface token;
	minterInterface minter;
	
	address public tokenAddress = 0x423E89EFf21AA9B30B15a71Fc4A341174e8D01D6;
	
	constructor() {
		token = ERC20Interface(tokenAddress); // it will be staked token interface
		minter = minterInterface(tokenAddress); // it's interface of contract that will give (most of time mint) rewards
	}


	function giveRewards(address staker, uint256 amount) internal {
		minter.mintTo(staker, amount);
	}


	function stakedBalanceOf(address _guy) public view returns (uint256) {
		return stakedBalances[_guy];
	}

	function changeAPR(uint256 _apr) public onlyOwner {
		require(_apr>=0);
		apr = _apr;
	}
	

	function _stakeIn(address user, uint256 _amount) internal {
		if(_hasStaked[user]) {
			_claimEarnings(user);
		}
		else {
			lastClaim[user] = block.timestamp;
			_hasStaked[user] = true;
		}
		require(_amount > 0, "Amount shall be positive... who wants negative interests ?");
		userApr[user] = apr;
		stakedBalances[user] = stakedBalances[user].add(_amount);
		token.transferFrom(user, address(this), _amount);
		totalStakedAmount = totalStakedAmount.add(_amount);
	}

	function _withdrawStake(address user, uint256 amount) internal {
		require(_hasStaked[user]);
		require(stakedBalances[user] >= amount, "You do not have enought... try a lower amount !");
		require(amount > 0, "Hmmm, stop thinking negative... and USE A POSITIVE AMOUNT");
		_claimEarnings(user);
		stakedBalances[user] = stakedBalances[user].sub(amount);
		token.transfer(user, amount);
		userApr[user] = apr;
		totalStakedAmount = totalStakedAmount.sub(amount);
	}

	function stakeIn(uint256 _amount) public {
		_stakeIn(msg.sender, _amount);
	}

	function withdrawStake(uint256 amount) public {
		_withdrawStake(msg.sender, amount);
	}

	function _claimEarnings(address _guy) internal {
		require(_hasStaked[_guy], "Hmm... empty. Normal, you shall stake-in first !");
		uint256 rewards = pendingRewards(_guy);
		giveRewards(_guy, rewards);
		lastClaim[_guy] = block.timestamp;
	}

	function pendingRewards(address _guy) public view returns (uint256) {
		return (stakedBalances[_guy]*userApr[_guy]*(block.timestamp - lastClaim[_guy]))/3153600000;
	}

	function claimStakingRewards() public {
		_claimEarnings(msg.sender);
	}

	function getCurrentAPR() public view returns (uint256) {
		return apr;
	}

	function totalStaked() public view returns (uint256) {
		return totalStakedAmount;
	}

	function getUserAPR(address _guy) public view returns (uint256) {
		if(_hasStaked[_guy]) {
			return userApr[_guy];
		}
		else {
			return apr;
		}
	}
	
	function receiveApproval(address from, uint256 tokens, address asset, bytes memory data) public {
		// dont worry for the unused params - it's a generic method
		require(msg.sender == tokenAddress);
		_stakeIn(from, tokens);
	}
}