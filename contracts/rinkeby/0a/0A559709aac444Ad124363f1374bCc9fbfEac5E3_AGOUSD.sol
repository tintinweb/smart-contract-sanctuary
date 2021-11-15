// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// import "./openZeppelin/SafeMath.sol";
// import "./openZeppelin/Context.sol";

import "./ERC20Custom.sol";
import "./Operator.sol";
import "./CNUSD.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IDollar.sol";

contract AGOUSD is ERC20Custom, IDollar, Operator {
    using SafeMath for uint256;

    // ERC20
    string public override symbol;
    string public override name;
    uint8 public constant override decimals = 18;
    uint256 public constant genesis_supply = 5000 ether; // 5000 will be mited at genesis for liq pool seeding

    // CONTRACTS
    address public treasury;

    // FLAGS
    bool public initialized;

    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
        require(ITreasury(treasury).hasPool(msg.sender), "!pools");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(string memory _name,  string memory _symbol, address _treasury){
        name = _name;
        symbol = _symbol;
        treasury = _treasury;
    }

    function initialize() external onlyOperator {
        require(!initialized, "alreadyInitialized");
        initialized = true;
        _mint(_msgSender(), genesis_supply);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Burn DOLLAR. Can be used by Pool only
    function poolBurnFrom(address _address, uint256 _amount) external override onlyPools {
        super._burnFrom(_address, _amount);
        emit DollarBurned(_address, msg.sender, _amount);
    }

    // Mint DOLLAR. Can be used by Pool only
    function poolMint(address _address, uint256 _amount) external override onlyPools {
        super._mint(_address, _amount);
        emit DollarMinted(msg.sender, _address, _amount);
    }

    function setTreasuryAddress(address _treasury) public onlyOperator {
        treasury = _treasury;
    }

    /* ========== EVENTS ========== */
    event DollarBurned(address indexed from, address indexed to, uint256 amount);// Track DOLLAR burned
    event DollarMinted(address indexed from, address indexed to, uint256 amount);// Track DOLLAR minted
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./openZeppelin/SafeMath.sol";
import "./openZeppelin/Context.sol";
import "./openZeppelin/IERC20.sol";

import "./ERC20Custom.sol";
import "./interfaces/ITreasury.sol";
import "./Operator.sol";

contract CNUSD is ERC20Custom, Operator {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // ERC20 - Token
    string public override symbol;
    string public override name;
    uint8 public constant override decimals = 18;

    // CONTRACTS
    address public treasury;

    // FLAGS
    bool public initialized;

    // DISTRIBUTION
    uint256 public constant COMMUNITY_REWARD_ALLOCATION = 80000000 ether; // 80M
    uint256 public constant DEV_FUND_ALLOCATION = 20000000 ether; // 20M
    uint256 public constant VESTING_DURATION = 1 days;//365 days; // 12 months
    uint256 public startTime; // Start time of vesting duration
    uint256 public endTime; // End of vesting duration
    address public devFund;
    address public rewardController; // Holding SHARE tokens to distribute into Liquiditiy Mining Pools
    uint256 public devFundLastClaimed;
    uint256 public devFundEmissionRate = DEV_FUND_ALLOCATION / VESTING_DURATION;
    uint256 public communityRewardClaimed;

    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
        require(ITreasury(treasury).hasPool(msg.sender), "!pools");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(string memory _name, string memory _symbol,  address _treasury){
        name = _name;
        symbol = _symbol;
        treasury = _treasury;
    }

    function initialize(
        address _devFund,
        address _rewardController,
        uint256 _startTime
    ) external onlyOperator {
        require(!initialized, "alreadyInitialized");
        require(_rewardController != address(0), "!rewardController");
        initialized = true;
        devFund = _devFund;
        rewardController = _rewardController;
        startTime = _startTime;
        endTime = _startTime + VESTING_DURATION;
        devFundLastClaimed = _startTime;

        _mint(msg.sender, 5000 ether);
    }

    function claimCommunityRewards(uint256 amount) external onlyOperator {
        require(amount > 0, "invalidAmount");
        require(initialized, "!initialized");
        require(rewardController != address(0), "!rewardController");
        uint256 _remainingRewards = COMMUNITY_REWARD_ALLOCATION.sub(communityRewardClaimed);
        require(amount <= _remainingRewards, "exceedRewards");
        communityRewardClaimed = communityRewardClaimed.add(amount);
        _mint(rewardController, amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setTreasuryAddress(address _treasury) external onlyOperator {
        treasury = _treasury;
    }

    function setDevFund(address _devFund) external {
        require(msg.sender == devFund, "!dev");
        require(_devFund != address(0), "zero");
        devFund = _devFund;
    }

    // This function is what other Pools will call to mint new SHARE
    function poolMint(address m_address, uint256 m_amount) external onlyPools {
        super._mint(m_address, m_amount);
        emit ShareMinted(address(this), m_address, m_amount);
    }

    // This function is what other pools will call to burn SHARE
    function poolBurnFrom(address b_address, uint256 b_amount) external onlyPools {
        super._burnFrom(b_address, b_amount);
        emit ShareBurned(b_address, address(this), b_amount);
    }

    function unclaimedDevFund() public view returns (uint256 _pending) {
        uint256 _now = block.timestamp;
        if (_now > endTime) _now = endTime;
        if (devFundLastClaimed >= _now) return 0;
        _pending = _now.sub(devFundLastClaimed).mul(devFundEmissionRate);
    }

    function claimDevFundRewards() external {
        require(msg.sender == devFund, "!dev");
        uint256 _pending = unclaimedDevFund();
        if (_pending > 0 && devFund != address(0)) {
            _mint(devFund, _pending);
            devFundLastClaimed = block.timestamp;
        }
    }

    /* ========== EVENTS ========== */

    // Track Share burned
    event ShareBurned(address indexed from, address indexed to, uint256 amount);

    // Track Share minted
    event ShareMinted(address indexed from, address indexed to, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./openZeppelin/SafeMath.sol";
import "./openZeppelin/Context.sol";
import "./openZeppelin/IERC20.sol";

abstract contract ERC20Custom is Context, IERC20 {
	using SafeMath for uint256;

	mapping (address => uint256) internal _balances;
	mapping (address => mapping (address => uint256)) internal _allowances;
	uint256 private _totalSupply;

	function totalSupply() public view override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view override returns (uint256) {
		return _balances[account];
	}

	function allowance(address owner, address spender) public view virtual override returns (uint256) {
		return _allowances[owner][spender];
	}
	
	function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}


	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
		return true;
	}

	function _transfer(address sender, address recipient, uint256 amount) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(sender, recipient, amount);

		_balances[sender] = _balances[sender].sub(amount);
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	}

	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	function burn(uint256 amount) public virtual {
		_burn(_msgSender(), amount);
	}

	function burnFrom(address account, uint256 amount) public virtual {
		uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount);

		_approve(account, _msgSender(), decreasedAllowance);
		_burn(account, amount);
	}

	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");

		_beforeTokenTransfer(account, address(0), amount);

		_balances[account] = _balances[account].sub(amount);
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

	function _approve(address owner, address spender, uint256 amount) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _burnFrom(address account, uint256 amount) internal virtual {
		_burn(account, amount);
		_approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount));
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./openZeppelin/Context.sol";
import "./openZeppelin/Ownable.sol";

abstract contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor(){
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IDollar {
    function poolBurnFrom(address _address, uint256 _amount) external;

    function poolMint(address _address, uint256 m_amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEpoch {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./IEpoch.sol";

interface ITreasury is IEpoch {
    function hasPool(address _address) external view returns (bool);

    function info()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function epochInfo()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {return 0;}
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

