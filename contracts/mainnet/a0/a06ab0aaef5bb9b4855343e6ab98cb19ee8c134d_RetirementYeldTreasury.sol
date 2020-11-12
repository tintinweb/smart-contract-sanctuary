pragma solidity 0.5.17;

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

contract Ownable is Context {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address payable) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// @notice The contract that holds the retirement yeld funds and distributes them
contract RetirementYeldTreasury is Ownable {
  using SafeMath for uint256;
  IERC20 yeld;
  uint256 public constant timeBetweenRedeems = 1 days;

	struct Stake {
		uint256 timestamp;
    uint256 yeldBalance;
	}

	mapping(address => Stake) public stakes;
	uint256 public totalStaked;

  // Fallback function to receive payments
  function () external payable {}

  // To set the YELD contract address
  constructor (address _yeld) public {
    yeld = IERC20(_yeld);
  }

	/// Stake yeld. Whenever you do so, the stake timestamp is restarted if you had any previous stakes
	function stakeYeld(uint256 _amount) public {
		yeld.transferFrom(msg.sender, address(this), _amount);
		stakes[msg.sender] = Stake(now, stakes[msg.sender].yeldBalance.add(_amount));
		totalStaked = totalStaked.add(_amount);
	}

	function unstake(uint256 _amount) public {
		uint256 userBalance = stakes[msg.sender].yeldBalance;
		require(userBalance > 0 && _amount > 0, "You can't unstake less than zero");
		require(_amount <= userBalance, "You can't withdraw more than your balance");
		stakes[msg.sender] = Stake(now, stakes[msg.sender].yeldBalance.sub(_amount));
		totalStaked = totalStaked.sub(_amount);
		yeld.transfer(msg.sender, _amount);
	}

  /// Checks how much YELD the user currently has and sends him some eth based on that
  function redeemETH() public {
    require(now >= stakes[msg.sender].timestamp + timeBetweenRedeems, 'You must wait at least a day after the snapshot to redeem your earnings');
    // Calculate his holdings % in 1 per 10^18% instead of 1 per 100%
    uint256 burnedTokens = yeld.balanceOf(address(0));
    uint256 userPercentage = stakes[msg.sender].yeldBalance.mul(1e18).div(yeld.totalSupply().sub(burnedTokens));
    uint256 earnings = address(this).balance.mul(userPercentage).div(1e16);
    stakes[msg.sender] = Stake(now, stakes[msg.sender].yeldBalance);
    msg.sender.transfer(earnings);
  }

  function setYeld(address _yeld) public onlyOwner {
    yeld = IERC20(_yeld);
  }

	function extractETHIfStuck() public onlyOwner {
    owner().transfer(address(this).balance);
  }

  function extractTokensIfStuck(address _token, uint256 _amount) public onlyOwner {
    IERC20(_token).transfer(msg.sender, _amount);
  }
}