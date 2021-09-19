/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

/**
 * RisingSun's INF token.
 * Controlled time based and auth based emission.
 * Both quantities limited by the contract.
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IAuth {
    function authorizeFor(address adr, string memory permissionName) external;
    function authorizeForMultiplePermissions(address adr, string[] calldata permissionNames) external;
    function authorizeForAllPermissions(address adr) external;
}

enum Permission {
    Authorize,
    Unauthorize,
    LockPermissions,

    AdjustVariables,
    Emission,
	AdjustMinting,
	GameEmission
}

abstract contract Auth is IAuth {
    struct PermissionLock {
        bool isLocked;
        uint64 expiryTime;
    }

    address public owner;
    mapping(address => mapping(uint => bool)) private authorizations; // uint is permission index
    
    uint constant NUM_PERMISSIONS = 7; // always has to be adjusted when Permission element is added or removed
    mapping(string => uint) permissionNameToIndex;
    mapping(uint => string) permissionIndexToName;

    mapping(uint => PermissionLock) lockedPermissions;

    constructor(address owner_) {
        owner = owner_;
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[owner_][i] = true;
        }

        permissionNameToIndex["Authorize"] = uint(Permission.Authorize);
        permissionNameToIndex["Unauthorize"] = uint(Permission.Unauthorize);
        permissionNameToIndex["LockPermissions"] = uint(Permission.LockPermissions);
        permissionNameToIndex["AdjustVariables"] = uint(Permission.AdjustVariables);
        permissionNameToIndex["Emission"] = uint(Permission.Emission);
		permissionNameToIndex["AdjustMinting"] = uint(Permission.AdjustMinting);
		permissionNameToIndex["GameEmission"] = uint(Permission.GameEmission);

        permissionIndexToName[uint(Permission.Authorize)] = "Authorize";
        permissionIndexToName[uint(Permission.Unauthorize)] = "Unauthorize";
        permissionIndexToName[uint(Permission.LockPermissions)] = "LockPermissions";
        permissionIndexToName[uint(Permission.AdjustVariables)] = "AdjustVariables";
        permissionIndexToName[uint(Permission.Emission)] = "Emission";
		permissionIndexToName[uint(Permission.AdjustMinting)] = "AdjustMinting";
		permissionIndexToName[uint(Permission.GameEmission)] = "GameEmission";
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownership required."); _;
    }

    function authorizedFor(Permission permission) internal view {
        require(!lockedPermissions[uint(permission)].isLocked, "Permission is locked.");
        require(isAuthorizedFor(msg.sender, permission), string(abi.encodePacked("Not authorized. You need the permission ", permissionIndexToName[uint(permission)])));
    }

    function authorizeFor(address adr, string memory permissionName) public override {
        authorizedFor(Permission.Authorize);
        uint permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = true;
        emit AuthorizedFor(adr, permissionName, permIndex);
    }

    function authorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public override {
        authorizedFor(Permission.Authorize);
        for (uint i; i < permissionNames.length; i++) {
            uint permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = true;
            emit AuthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    function authorizeForAllPermissions(address adr) public override {
        authorizedFor(Permission.Authorize);
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[adr][i] = true;
        }
    }

    function unauthorizeFor(address adr, string memory permissionName) public {
        authorizedFor(Permission.Unauthorize);
        require(adr != owner, "Can't unauthorize owner");

        uint permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = false;
        emit UnauthorizedFor(adr, permissionName, permIndex);
    }

    function unauthorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public {
        authorizedFor(Permission.Unauthorize);
        require(adr != owner, "Can't unauthorize owner");

        for (uint i; i < permissionNames.length; i++) {
            uint permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = false;
            emit UnauthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    function unauthorizeForAllPermissions(address adr) public {
        authorizedFor(Permission.Unauthorize);
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[adr][i] = false;
        }
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorizedFor(address adr, string memory permissionName) public view returns (bool) {
        return authorizations[adr][permissionNameToIndex[permissionName]];
    }

    function isAuthorizedFor(address adr, Permission permission) public view returns (bool) {
        return authorizations[adr][uint(permission)];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        address oldOwner = owner;
        owner = adr;
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[oldOwner][i] = false;
            authorizations[owner][i] = true;
        }
        emit OwnershipTransferred(oldOwner, owner);
    }

    function getPermissionNameToIndex(string memory permissionName) public view returns (uint) {
        return permissionNameToIndex[permissionName];
    }

    function getPermissionUnlockTime(string memory permissionName) public view returns (uint) {
        return lockedPermissions[permissionNameToIndex[permissionName]].expiryTime;
    }

    function isLocked(string memory permissionName) public view returns (bool) {
        return lockedPermissions[permissionNameToIndex[permissionName]].isLocked;
    }

    function lockPermission(string memory permissionName, uint64 time) public virtual {
        authorizedFor(Permission.LockPermissions);

        uint permIndex = permissionNameToIndex[permissionName];
        uint64 expiryTime = uint64(block.timestamp) + time;
        lockedPermissions[permIndex] = PermissionLock(true, expiryTime);
        emit PermissionLocked(permissionName, permIndex, expiryTime);
    }

    function unlockPermission(string memory permissionName) public virtual {
        require(block.timestamp > getPermissionUnlockTime(permissionName) , "Permission is locked until the expiry time.");
        uint permIndex = permissionNameToIndex[permissionName];
        lockedPermissions[permIndex].isLocked = false;
        emit PermissionUnlocked(permissionName, permIndex);
    }

    event PermissionLocked(string permissionName, uint permissionIndex, uint64 expiryTime);
    event PermissionUnlocked(string permissionName, uint permissionIndex);
    event OwnershipTransferred(address from, address to);
    event AuthorizedFor(address adr, string permissionName, uint permissionIndex);
    event UnauthorizedFor(address adr, string permissionName, uint permissionIndex);
}

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDexFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Influence is Auth, IBEP20 {

	string constant _name = "Influence";
    string constant _symbol = "INF";
    uint8 constant _decimals = 9;
	uint256 _totalSupply = 0;

	mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
	mapping (address => bool) isFeeExempt;

	uint256 stakingFee = 0;
	address stakingAddress;
    uint256 feeDenominator = 1000;
	bool public feeOnNonTrade = false;

	IDexRouter public router;
	address pairToken; // Token to be paired with
    address tokenPair; // LP Pair with the token
	mapping (address => bool) public isPair;  // Taxable pairs

	// Emissions
	bool public emissionActive = false; // Whether regular emission is active
	uint64 _lastMint; // Last mint from regular emission
	uint256 _tokensEmittedPerSecond = 0 gwei; // Tokens minted per second on regular emission

	uint64 _lastAdminMint; // Last admin special mint
	uint256 _specialTokensPerSecond = 0.05 gwei; // Seconds it takes to be able for admin to mint a new token.
	uint256 _maxSpecialMint = 1_000_000 gwei; // Max tokens that can be minted at once from special mint. Limits in case long time without minting.

	uint64 _lastGameMint; // Last game mint
	uint256 _gameTokensPerSecond = 10 gwei; // Seconds it takes for the game to generate a token.
	uint256 _maxGameMint = 1_000_000 gwei; // Max tokens that can be minted at once from game rewards.

	// Rewards
	uint256 public winnerAward = 50 gwei;
	uint256 public loserAward = 10 gwei;

	constructor(uint256 initialMint, address _router, address _token) Auth(msg.sender) {
		router = IDexRouter(_router);
		pairToken = _token;
        tokenPair = IDexFactory(router.factory()).createPair(_token, address(this));
		isPair[tokenPair] = true;
        _allowances[address(this)][address(router)] = type(uint256).max;

		// Should the tax be activated.
		isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

		// Token emision starts counting from the moment the contract is created.
		_lastMint = uint64(block.timestamp);

		_mint(msg.sender, initialMint);
	}

	// IBEP20 implementations
	receive() external payable {}
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

	function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
			require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(amount > 0, "Amount can't be 0");
		require(amount <= _balances[sender], "Insufficient Balance");

		if (emissionActive && stakingAddress != address(0)) {
			emissionForStaking();
		}

        _balances[sender] -= amount;

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        _balances[recipient] += amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

	function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
		require(amount <= _balances[sender], "Insufficient Balance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

	function shouldTakeFee(address sender, address recipient) internal view returns(bool) {
		if (stakingFee == 0 || stakingAddress == address(0) || isFeeExempt[sender] || isFeeExempt[recipient]) {
			return false;
		}

		return isPair[tokenPair] || feeOnNonTrade;
	}

	function takeFee(address sender, uint256 amount) internal returns(uint256) {
		uint256 feeAmount = amount * stakingFee / feeDenominator;

        _balances[stakingAddress] += feeAmount;
        emit Transfer(sender, stakingAddress, feeAmount);

        return amount - feeAmount;
	}

	function setPair(address pair) external {
		authorizedFor(Permission.AdjustVariables);
        isPair[pair] = true;
    }
    
    function removePair(address pair) external {
		authorizedFor(Permission.AdjustVariables);
        isPair[pair] = false;
    }

	/**
	 * This is an INTERNAL function, that means it can NOT be called from outside the contract.
	 */
	function _mint(address to, uint256 amount) internal {
		require(to != address(0), "ERC20: mint to the zero address");

		_totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
	}

	function setWinnerAward(uint256 award) external {
		authorizedFor(Permission.AdjustVariables);
		winnerAward = award;
	}
    
    function setLoserAward(uint256 award) external {
		authorizedFor(Permission.AdjustVariables);
		loserAward = award;
	}

	function setEmissionActive(bool active) external {
		authorizedFor(Permission.AdjustMinting);
		emissionActive = active;
	}

	function setStakingAddress(address addy) external {
		authorizedFor(Permission.AdjustVariables);
		stakingAddress = addy;
	}

	function setSpecialMintLimit(uint256 limit) external {
		authorizedFor(Permission.AdjustMinting);
		_maxSpecialMint = limit;
	}

	function setTokensEmittedPerSecond(uint256 amount) external {
		authorizedFor(Permission.AdjustMinting);
		_tokensEmittedPerSecond = amount;
	}

	function setSpecialTokensPerSecond(uint256 amount) external {
		authorizedFor(Permission.AdjustMinting);
		_specialTokensPerSecond = amount;
	}

	function setGameTokensPerSecond(uint256 amount) external {
		authorizedFor(Permission.AdjustMinting);
		_gameTokensPerSecond = amount;
	}

	function setGameMintLimit(uint256 limit) external {
		authorizedFor(Permission.AdjustMinting);
		_maxGameMint = limit;
	}
    
    function setFeeOnNonTrade(bool fee) external {
		authorizedFor(Permission.AdjustVariables);
		feeOnNonTrade = fee;
	}

    function setFees(uint stakingFee_, uint denom_) external {
		authorizedFor(Permission.AdjustVariables);
		
        require(stakingFee_ <= denom_ * 5 / 100, "Fee too high");
        
        stakingFee = stakingFee_;
        feeDenominator = denom_;
	}

	/**
	 * Emits the token to the staking contract that should have been minted up to now.
	 * Public because it can either be called internally or by the staking contract when checking rewards.
	 */
	function emissionForStaking() public {
		require(emissionActive, "Emission is not active.");
		require(stakingAddress != address(0), "Staking is not set up.");
		uint256 secs = block.timestamp - _lastMint;
		_lastMint = uint64(block.timestamp);
		_mint(stakingAddress, secs * _tokensEmittedPerSecond);
	}

	/**
	 * @dev Given a number of tokens per second, calculates how many is possible to mint since a specific set time.
	 */
	function getMintableTokensFromTime(uint64 timestamp, uint256 tokenPerSecond, uint256 maxTokens) public view returns (uint256) {
		if (timestamp > block.timestamp) {
        	return 0;
		}

    	uint256 tokens = (block.timestamp - timestamp) * tokenPerSecond;
		if (tokens > maxTokens) {
			tokens = maxTokens;
		}
		return tokens;
	}

	function getSpecialMintableTokensFromTime(uint64 timestamp) public view returns (uint256) {
		return getMintableTokensFromTime(timestamp, _specialTokensPerSecond, _maxSpecialMint);
	}

	function specialEmission(uint256 amount) external {
		authorizedFor(Permission.Emission);
		uint256 mintableTokens = getSpecialMintableTokensFromTime(_lastAdminMint);
		require(mintableTokens > 0, "Nothing to mint yet.");
		require(amount <= mintableTokens, "You cannot mint that much now!");
		uint64 timeToTake = uint64(amount / _specialTokensPerSecond);
		if (mintableTokens >= _maxSpecialMint) {
			_lastAdminMint = uint64(block.timestamp - uint64(_maxSpecialMint / _specialTokensPerSecond) + timeToTake);
		} else {
			_lastAdminMint = uint64(_lastAdminMint + timeToTake);
		}

		_mint(msg.sender, amount);
	}

	function getGameMintableTokensFromTime(uint64 timestamp) public view returns (uint256) {
		return getMintableTokensFromTime(timestamp, _gameTokensPerSecond, _maxGameMint);
	}

	function incrementBalancesWithAvailable(address[] calldata addresses, uint256[] calldata values) external {
		authorizedFor(Permission.GameEmission);
		require(addresses.length == values.length, "Addresses and rewards must be the same!");
		uint256 mintableTokens = getGameMintableTokensFromTime(_lastGameMint);
		require(mintableTokens > 0, "Nothing to mint yet.");
		uint256 amount = 0;
		for (uint256 i = 0; i < addresses.length; i++) {
			// If the next mint would get us above mint limit, break and keep mints done.
			// This ensures a fair distribution within limits, next ones can be called after.
			if (amount + values[i] > mintableTokens) {
				break;
			}
			_mint(addresses[i], values[i]);
			amount += values[i];
		}
		_takeGameMintTime(mintableTokens, amount);
	}
	
	function incrementBalances(address[] calldata addresses, uint256[] calldata values, uint valuesTotal) external {
		authorizedFor(Permission.GameEmission);
		require(addresses.length == values.length, "Addresses and rewards must be the same!");
		uint256 mintableTokens = getGameMintableTokensFromTime(_lastGameMint);
		require(mintableTokens > 0, "Nothing to mint yet.");
		// sanity check from user-provided valuesTotal to avoid a revert later
		require(valuesTotal <= mintableTokens, "You cannot mint that much now!");
		uint256 amount = 0;
		for (uint256 i = 0; i < addresses.length; i++) {
			if (amount + values[i] > mintableTokens) {
				revert('You cannot mint that much now, reverting.');
			}
			_mint(addresses[i], values[i]);
			amount += values[i];
		}
		_takeGameMintTime(mintableTokens, amount);
	}

	function incrementWinnerBalances(address[] calldata addresses) external {
		authorizedFor(Permission.GameEmission);
		// Calculate how many tokens the game has mint from the allowed per day.
		uint256 mintableTokens = getGameMintableTokensFromTime(_lastGameMint);
		// The called rewards must be within bounds of tokens allowed to mint since last mint.
		require(mintableTokens > 0, "Nothing to mint yet.");
		uint256 amount = addresses.length * winnerAward;
		require(amount <= mintableTokens, "You cannot mint that much now!");
		// Mint all winner awards.
		for (uint256 i = 0; i < addresses.length; i++) {
			_mint(addresses[i], winnerAward);
		}
		_takeGameMintTime(mintableTokens, amount);
	}
    
    function incrementLoserBalances(address[] calldata addresses) external {
		authorizedFor(Permission.GameEmission);
		// Calculate how many tokens the game has mint from the allowed per day.
		uint256 mintableTokens = getGameMintableTokensFromTime(_lastGameMint);
		// The called rewards must be within bounds of tokens allowed to mint since last mint.
		require(mintableTokens > 0, "Nothing to mint yet.");
		uint256 amount = addresses.length * loserAward;
		require(amount <= mintableTokens, "You cannot mint that much now!");
		// Mint all winner awards.
		for (uint256 i = 0; i < addresses.length; i++) {
			_mint(addresses[i], loserAward);
		}
		_takeGameMintTime(mintableTokens, amount);
	}

	function _takeGameMintTime(uint256 mintableTokens, uint256 amount) internal {
		// Take time from available time for mint so next call considers these minted tokens on the total mintable.
		uint64 timeToTake = uint64(amount / _gameTokensPerSecond);
		if (mintableTokens >= _maxGameMint) {
			_lastGameMint = uint64(block.timestamp - uint64(_maxGameMint / _gameTokensPerSecond) + timeToTake);
		} else {
			_lastGameMint = uint64(_lastGameMint + timeToTake);
		}
	}
	
    function rescueStuckTokens(address tokenAdr, uint256 amount) external {
        authorizedFor(Permission.AdjustVariables);
        require(IBEP20(tokenAdr).transfer(msg.sender, amount), "Transfer failed");
    }

    function rescueStuckBNB(uint256 amount) external {
        authorizedFor(Permission.AdjustVariables);
        (bool success,) = payable(msg.sender).call{ value: amount }("");
        require(success, "Failed to send BNB");
    }
}