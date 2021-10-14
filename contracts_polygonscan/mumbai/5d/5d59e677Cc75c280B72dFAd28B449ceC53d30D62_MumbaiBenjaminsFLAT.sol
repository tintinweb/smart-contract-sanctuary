/**
 *Submitted for verification at polygonscan.com on 2021-10-13
*/

pragma solidity ^0.8.9;
//SPDX-License-Identifier: NONE

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

pragma solidity ^0.8.9;
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



pragma solidity ^0.8.9;

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



pragma solidity ^0.8.9;
abstract contract Pausable is Context {
   
    event Paused(address account);

    
    event Unpaused(address account);

    bool private _paused;

    
    constructor () {
      //  _paused = false;
    }

    
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

   
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity ^0.8.9;
contract BNJICurve is Ownable, Pausable{   

  uint256 USDCscale = 10**6;  

  uint256 curveFactor = 800000;

  function calcPriceForTokenMint(
    uint256 supply,    
    uint256 tokensToMint) public view returns (uint256)
  { 
    require(tokensToMint > 0, "BNJICurve: Must mint more than 0 tokens");  
    
    uint256 supplySquared = supply*supply;    

    uint256 supplyAfterMint = supply + tokensToMint;    
    uint256 supplyAfterMintSquared = supplyAfterMint * supplyAfterMint; 

    uint256 step1 = supplyAfterMintSquared - supplySquared; 
    
    uint256 step2 = step1 * USDCscale;
   
    uint256 totalPriceForTokensMintingNowInUSDC6digits = step2 / curveFactor;  
        
    uint256 takeOffFactor = 10 ** 4;
    
    uint256 rest = totalPriceForTokensMintingNowInUSDC6digits % takeOffFactor;
    
    uint256 mintResultWithCentsroundedDown = totalPriceForTokensMintingNowInUSDC6digits - rest;
    
    // returning price for specified token amount
    return mintResultWithCentsroundedDown;        
  }

  function calcReturnForTokenBurn(
    uint256 supply,    
    uint256 tokensToBurn) public view returns (uint256)
  {
    // validate input
    
    require(supply > 0 && tokensToBurn > 0 && supply >= tokensToBurn, "BNJICurve: Sending args must be larger than 0");   
    
    uint256 supplyAfterBurn = supply - tokensToBurn; 

    uint256 supplySquared = supply * supply; 
    uint256 supplyAfterBurnSquared = supplyAfterBurn * supplyAfterBurn;
    
    uint256 step1 = supplySquared - supplyAfterBurnSquared;    
   
    uint256 step2 = step1 * USDCscale ;
    
    uint256 returnForTokenBurnInUSDC6digits = step2/ 800000 ;
    
    uint256 takeOffFactor = 10 ** 4;
   
    uint256 rest = returnForTokenBurnInUSDC6digits % takeOffFactor;
   
    uint256 burnResultWithCentsroundedDown = returnForTokenBurnInUSDC6digits - rest;    

    return burnResultWithCentsroundedDown;    
  }
  
  // function for owner to withdraw any ERC20 token that has accumulated
  function updateCurveFactor (uint256 newCurveFactor) public onlyOwner {
    curveFactor = newCurveFactor;
  }

  // function for owner to withdraw any ERC20 token that has accumulated
  function withdrawERC20 (address ERC20ContractAddress, uint256 amount) public onlyOwner {
    IERC20 ERC20Instance = IERC20(ERC20ContractAddress);        
    ERC20Instance.transfer(msg.sender, amount);         
  }

  // pausing funcionality from OpenZeppelin's Pausable
  function pause() public onlyOwner {
    _pause();
  }

  // unpausing funcionality from OpenZeppelin's Pausable
  function unpause() public onlyOwner {
    _unpause();
  }

}

pragma solidity ^0.8.9;
library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

pragma solidity ^0.8.9;
interface ILendingPool {
	
	event Deposit(
		address indexed reserve,
		address user,
		address indexed onBehalfOf,
		uint256 amount,
		uint16 indexed referral
	);

	
	event Withdraw(
		address indexed reserve,
		address indexed user,
		address indexed to,
		uint256 amount
	);

	event Borrow(
		address indexed reserve,
		address user,
		address indexed onBehalfOf,
		uint256 amount,
		uint256 borrowRateMode,
		uint256 borrowRate,
		uint16 indexed referral
	);

	
	event Repay(
		address indexed reserve,
		address indexed user,
		address indexed repayer,
		uint256 amount
	);

	
	event Swap(address indexed reserve, address indexed user, uint256 rateMode);

	
	event ReserveUsedAsCollateralEnabled(
		address indexed reserve,
		address indexed user
	);

	event ReserveUsedAsCollateralDisabled(
		address indexed reserve,
		address indexed user
	);


	event RebalanceStableBorrowRate(
		address indexed reserve,
		address indexed user
	);

	
	event FlashLoan(
		address indexed target,
		address indexed initiator,
		address indexed asset,
		uint256 amount,
		uint256 premium,
		uint16 referralCode
	);

	
	event Paused();

	
	event Unpaused();


	event LiquidationCall(
		address indexed collateralAsset,
		address indexed debtAsset,
		address indexed user,
		uint256 debtToCover,
		uint256 liquidatedCollateralAmount,
		address liquidator,
		bool receiveAToken
	);

	
	event ReserveDataUpdated(
		address indexed reserve,
		uint256 liquidityRate,
		uint256 stableBorrowRate,
		uint256 variableBorrowRate,
		uint256 liquidityIndex,
		uint256 variableBorrowIndex
	);

	
	function deposit(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	
	function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);

	
	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		uint16 referralCode,
		address onBehalfOf
	) external;


	function repay(
		address asset,
		uint256 amount,
		uint256 rateMode,
		address onBehalfOf
	) external returns (uint256);

	function swapBorrowRateMode(address asset, uint256 rateMode) external;

	
	function rebalanceStableBorrowRate(address asset, address user) external;

	
	function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
		external;

	
	function liquidationCall(
		address collateralAsset,
		address debtAsset,
		address user,
		uint256 debtToCover,
		bool receiveAToken
	) external;

	
	function flashLoan(
		address receiverAddress,
		address[] calldata assets,
		uint256[] calldata amounts,
		uint256[] calldata modes,
		address onBehalfOf,
		bytes calldata params,
		uint16 referralCode
	) external;

	
	function getUserAccountData(address user)
		external
		view
		returns (
			uint256 totalCollateralETH,
			uint256 totalDebtETH,
			uint256 availableBorrowsETH,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		);

	function initReserve(
		address reserve,
		address aTokenAddress,
		address stableDebtAddress,
		address variableDebtAddress,
		address interestRateStrategyAddress
	) external;

	function setReserveInterestRateStrategyAddress(
		address reserve,
		address rateStrategyAddress
	) external;

	function setConfiguration(address reserve, uint256 configuration) external;

	
	function getConfiguration(address asset)
		external
		view
		returns (DataTypes.ReserveConfigurationMap memory);

	
	function getUserConfiguration(address user)
		external
		view
		returns (DataTypes.UserConfigurationMap memory);

	
	function getReserveNormalizedIncome(address asset)
		external
		view
		returns (uint256);

	
	function getReserveNormalizedVariableDebt(address asset)
		external
		view
		returns (uint256);

	
	function getReserveData(address asset)
		external
		view
		returns (DataTypes.ReserveData memory);

	function finalizeTransfer(
		address asset,
		address from,
		address to,
		uint256 amount,
		uint256 balanceFromAfter,
		uint256 balanceToBefore
	) external;

	function getReservesList() external view returns (address[] memory);

	function getAddressesProvider()
		external
		view
		returns (ILendingPoolAddressesProvider);

	function setPause(bool val) external;

	function paused() external view returns (bool);
}

pragma solidity ^0.8.9;
interface ILendingPoolAddressesProvider {
	event MarketIdSet(string newMarketId);
	event LendingPoolUpdated(address indexed newAddress);
	event ConfigurationAdminUpdated(address indexed newAddress);
	event EmergencyAdminUpdated(address indexed newAddress);
	event LendingPoolConfiguratorUpdated(address indexed newAddress);
	event LendingPoolCollateralManagerUpdated(address indexed newAddress);
	event PriceOracleUpdated(address indexed newAddress);
	event LendingRateOracleUpdated(address indexed newAddress);
	event ProxyCreated(bytes32 id, address indexed newAddress);
	event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

	function getMarketId() external view returns (string memory);

	function setMarketId(string calldata marketId) external;

	function setAddress(bytes32 id, address newAddress) external;

	function setAddressAsProxy(bytes32 id, address impl) external;

	function getAddress(bytes32 id) external view returns (address);

	function getLendingPool() external view returns (address);

	function setLendingPoolImpl(address pool) external;

	function getLendingPoolConfigurator() external view returns (address);

	function setLendingPoolConfiguratorImpl(address configurator) external;

	function getLendingPoolCollateralManager() external view returns (address);

	function setLendingPoolCollateralManager(address manager) external;

	function getPoolAdmin() external view returns (address);

	function setPoolAdmin(address admin) external;

	function getEmergencyAdmin() external view returns (address);

	function setEmergencyAdmin(address admin) external;

	function getPriceOracle() external view returns (address);

	function setPriceOracle(address priceOracle) external;

	function getLendingRateOracle() external view returns (address);

	function setLendingRateOracle(address lendingRateOracle) external;
}


pragma solidity ^0.8.9;
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    
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

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

   
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


pragma solidity ^0.8.9;
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.9;
interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.9;
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

   
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

   
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

   
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

   
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity ^0.8.9;
contract MumbaiBenjaminsFLAT is ERC20, BNJICurve, ReentrancyGuard {   // <==== changed_ for Mumbai testnet
  using SafeMath for uint256;
 
  address public addressOfThisContract;

  address private feeReceiver; 
  address private accumulatedReceiver;   

  address[] private stakers;
  address[] private internalAddresses;

  mapping (address => uint256) private ownedBenjamins;
  mapping (address => uint256) private internalBenjamins;
  mapping (address => uint256) private totalStakedByUser;
  mapping (address => bool) private isOnStakingList;
  mapping (address => bool) private isOnInternalList;
  mapping (address => Stake[]) private usersStakingPositions;
  mapping (address => Stake[]) private internalStakingPositions;  

  struct Stake {
    address stakingAddress;
    uint256 stakeID;
    uint256 tokenAmount;    
    uint256 stakeCreatedTimestamp; 
    bool unstaked;
  }

  uint8 private amountDecimals;
  uint256 largestUint = type(uint256).max;

  uint256 centsScale4digits = 10000;
  uint256 dollarScale6dec = 1000000;

  uint256 stakingPeriodInSeconds = 1; // 86400; <===== XXXXX, changed_ only for testing

  uint256 tier_0_feeMod = 100;
  uint256 tier_1_feeMod = 95;
  uint256 tier_2_feeMod = 85;
  uint256 tier_3_feeMod = 70;
  uint256 tier_4_feeMod = 50;
  uint256 tier_5_feeMod = 25;   

  ILendingPool public polygonLendingPool;
  IERC20 public polygonUSDC;
  IERC20 public polygonAMUSDC;

  event SpecifiedMintEvent (address sender, uint256 tokenAmount, uint256 priceForMintingIn6dec);  

  event SpecifiedBurnEvent (address sender, uint256 tokenAmount, uint256 returnForBurning);  

  event LendingPoolDeposit (uint256 amount);
  
  event LendingPoolWithdrawal (uint256 amount);

  constructor() ERC20("MumbaiBenjamins", "MumBenj") {     // <==== changed_ for Mumbai testnet
    addressOfThisContract = address(this);
    //feeReceiver = feeReceiverAddress;
    amountDecimals = 0;
    //polygonUSDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);               <==== changed_ for Mumbai testnet
    //polygonAMUSDC = IERC20(0x1a13F4Ca1d028320A707D99520AbFefca3998b7F);             <==== changed_ for Mumbai testnet
    //polygonLendingPool = ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);  <==== changed_ for Mumbai testnet       
    
    polygonUSDC = IERC20(0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e);               // <==== changed_ for Mumbai testnet
    polygonAMUSDC = IERC20(0x2271e3Fef9e15046d09E1d78a8FF038c691E9Cf9);             // <==== changed_ for Mumbai testnet
    polygonLendingPool = ILendingPool(0x9198F13B08E299d85E096929fA9781A1E3d5d827);  // <==== changed_ for Mumbai testnet   

    //approveLendingPool(largestUint);    
    pause();
  }

  receive() external payable {   
  }


  function approveLendingPool (uint256 amountToApprove) public onlyOwner {   
    polygonUSDC.approve(address(polygonLendingPool), amountToApprove);       
  }

  
  function decimals() public view override returns (uint8) {
    return amountDecimals;
  }
  
  function findUsersLevelFeeModifier (address user) private view returns (uint256 usersFee) {

    uint256 usersStakedBalance = checkStakedBenjamins(user);
    
    if (usersStakedBalance < 20) {
      return tier_0_feeMod;
    }
    else if (usersStakedBalance >= 20 && usersStakedBalance < 40 ) {
      return tier_1_feeMod;
    }    
    else if (usersStakedBalance >= 40 && usersStakedBalance < 60) {
      return tier_2_feeMod;
    }
    else if (usersStakedBalance >= 60 && usersStakedBalance < 80) {
      return tier_3_feeMod;
    }  
    else if (usersStakedBalance >= 80 && usersStakedBalance < 100) {
      return tier_4_feeMod;
    } 
    else if (usersStakedBalance >= 100 ) {
      return tier_5_feeMod;
    } 
    
  }

  function getUsersActiveAndBurnableStakes (address userToCheck) public view returns (Stake[] memory stakeArray){    

    uint256 timestampNow = uint256(block.timestamp);

    uint256 nrOfActiveBurnableStakes;

    Stake[] memory usersStakeArray = usersStakingPositions[userToCheck];
  
    for (uint256 index = 0; index < usersStakeArray.length; index++) {       
                           
      uint256 unlockTimeStamp = usersStakeArray[index].stakeCreatedTimestamp + stakingPeriodInSeconds;  
      
      // each time an active and burnable stake is found, nrOfActiveBurnableStakes is increased by 1
      if (usersStakeArray[index].unstaked == false && unlockTimeStamp <= timestampNow ) {
        nrOfActiveBurnableStakes++;
      }    

    }

    if (nrOfActiveBurnableStakes == 0){
      return new Stake[](0);
    }

    else {
      // 'activeBurnableStakes' array with hardcoded length, defined by active stakes found above
      Stake[] memory activeBurnableStakes = new Stake[](nrOfActiveBurnableStakes);      

      // index position in activeBurnableStakes array
      uint256 newIndex = 0 ;

      for (uint256 k = 0; k < activeBurnableStakes.length; k++) {
        
        // each time an active stake is found, its details are put into the next position in the 'activeBurnableStakes' array
        if (usersStakeArray[k].unstaked == false) {
          activeBurnableStakes[newIndex].stakingAddress = usersStakeArray[newIndex].stakingAddress;
          activeBurnableStakes[newIndex].stakeID = usersStakeArray[newIndex].stakeID;
          activeBurnableStakes[newIndex].tokenAmount = usersStakeArray[newIndex].tokenAmount;
          activeBurnableStakes[newIndex].stakeCreatedTimestamp = usersStakeArray[newIndex].stakeCreatedTimestamp;
          activeBurnableStakes[newIndex].unstaked = usersStakeArray[newIndex].unstaked;
          newIndex++;
        }         

      }
      // returning activeBurnableStakes array
      return activeBurnableStakes; 

    } 
    
  }   

  function buyLevels(uint256 amountOfLevels) public whenNotPaused {
    specifiedAmountMint(amountOfLevels * 20);
  }

  function specifiedAmountMint(uint256 amount) internal whenNotPaused nonReentrant returns (uint256) {   
    
    require((amount % 20 == 0), "BNJ, specifiedAmountMint: Amount must be divisible by 20");       
    
    uint256 priceForMintingIn6dec = calcSpecMintReturn(amount);
    
    uint256 usersFeeModifier = findUsersLevelFeeModifier( msg.sender ); 

    uint256 feeIn6dec = ((priceForMintingIn6dec * usersFeeModifier) /100) /100;
    
    uint256 roundThisDown = feeIn6dec % (10**4);
    
    uint256 feeRoundedDownIn6dec = feeIn6dec - roundThisDown;
    
    uint256 endPriceIn6dec = priceForMintingIn6dec + feeRoundedDownIn6dec;
    
    uint256 polygonUSDCbalanceIn6dec = polygonUSDC.balanceOf( msg.sender ) ;
    
    uint256 USDCAllowancein6dec = polygonUSDC.allowance(msg.sender, addressOfThisContract); 
    
    require (endPriceIn6dec <= polygonUSDCbalanceIn6dec, "BNJ, specifiedAmountMint: Not enough USDC"); 
    require (endPriceIn6dec <= USDCAllowancein6dec, "BNJ, specifiedAmountMint: Not enough allowance in USDC for payment" );
    require (priceForMintingIn6dec >= 5000000, "BNJ, specifiedAmountMint: Minimum minting value of $5 USDC" );
    
    polygonUSDC.transferFrom(msg.sender, feeReceiver, feeRoundedDownIn6dec);   

    polygonUSDC.transferFrom(msg.sender, addressOfThisContract, priceForMintingIn6dec);  

    depositIntoLendingPool(priceForMintingIn6dec);      
  
    // minting to Benjamins contract itself
    _mint(addressOfThisContract, amount);
    emit SpecifiedMintEvent(msg.sender, amount, priceForMintingIn6dec);

    // this is the user's balance of tokens
    ownedBenjamins[msg.sender] += amount;

    uint256 amountOfLevelsToBuy = amount / 20;

    for (uint256 index = 0; index < amountOfLevelsToBuy; index++) {
      stakeTokens(msg.sender, 20);
    }     

    return priceForMintingIn6dec;   
  }  

  function calcSpecMintReturn(uint256 amount) public view returns (uint256 mintPrice) {
    return calcPriceForTokenMint(totalSupply(), amount); 
  }      

  function sellLevels(uint256 amountOfLevels) public whenNotPaused {
    specifiedAmountBurn(amountOfLevels * 20);
  }

  function specifiedAmountBurn(uint256 amount) internal whenNotPaused nonReentrant returns (uint256) {    

    require((amount % 20) == 0, "BNJ, specifiedAmountMint: Amount must be divisible by 20");   

    uint256 tokenBalance = checkStakedBenjamins(msg.sender);    
     
    require(amount > 0, "Amount to burn must be more than zero.");  
    require(tokenBalance >= amount, "Users tokenBalance must be equal to or more than amount to burn.");             
    
    uint256 returnForBurningIn6dec = calcSpecBurnReturn(amount);
    
    require (returnForBurningIn6dec >= 5000000, "BNJ, specifiedAmountBurn: Minimum burning value is $5 USDC" );

    uint256 usersFeeModifier = findUsersLevelFeeModifier( msg.sender );

    uint256 feeIn6dec = ((returnForBurningIn6dec * usersFeeModifier) /100) / 100;   
    
    uint256 roundThisDown = feeIn6dec % (10**4);
    
    uint256 feeRoundedDown = feeIn6dec - roundThisDown;
   
    uint256 endReturnIn6dec = returnForBurningIn6dec - feeRoundedDown;      

    uint256 amountOfLevelsToSell = amount / 20;

    for (uint256 index = 0; index < amountOfLevelsToSell; index++) {
      unstakeTokens(msg.sender, 20);
    }   

    // this is the user's balance of tokens
    ownedBenjamins[msg.sender] -= amount;

    _burn(addressOfThisContract, amount);      
    emit SpecifiedBurnEvent(msg.sender, amount, returnForBurningIn6dec);      


    withdrawFromLendingPool(returnForBurningIn6dec); 

    polygonUSDC.transfer(feeReceiver, feeRoundedDown);
    polygonUSDC.transfer(msg.sender, endReturnIn6dec);     
    
    

    return returnForBurningIn6dec;   
  }

  function calcSpecBurnReturn(uint256 amount) public view returns (uint256 burnReturn) { 
    return calcReturnForTokenBurn(totalSupply(), amount); 
  }      

  function stakeTokens(address stakingUserAddress, uint256 amountOfTokensToStake) private {
    uint256 tokensOwned = checkOwnedBenjamins( stakingUserAddress ) ;    

    require (amountOfTokensToStake <= tokensOwned, 'BNJ, stakeTokens: Not enough tokens'); 

    if (!isOnStakingList[stakingUserAddress]) {
      stakers.push(stakingUserAddress);
      isOnStakingList[stakingUserAddress] = true;
    }

    uint256 stakeID = usersStakingPositions[stakingUserAddress].length;

    Stake memory newStake = Stake({ 
      stakingAddress: address(stakingUserAddress),
      stakeID: uint256(stakeID),
      tokenAmount: uint256(amountOfTokensToStake),      
      stakeCreatedTimestamp: uint256(block.timestamp),
      unstaked: false       
    });        

    usersStakingPositions[stakingUserAddress].push(newStake);

    totalStakedByUser[stakingUserAddress] += amountOfTokensToStake;
  }

  function unstakeTokens(address stakingUserAddress, uint256 amountOfTokensToUnstake) private {

    uint256 tokensStaked = checkStakedBenjamins( stakingUserAddress ) ;    

    require (amountOfTokensToUnstake <= tokensStaked, 'BNJ, unstakeTokens: Not enough tokens'); 
   
    Stake[] memory usersActiveBurnableStakess = getUsersActiveAndBurnableStakes(stakingUserAddress);

    require (usersActiveBurnableStakess.length > 0, 'BNJ, unstakeTokens: No burnable staking positions found. Consider time since staking.');

    uint256 newestActiveStake = usersActiveBurnableStakess.length - 1;

    uint256 stakeIDtoUnstake = usersActiveBurnableStakess[newestActiveStake].stakeID;    

    for (uint256 unStIndex = 0; unStIndex < usersStakingPositions[stakingUserAddress].length; unStIndex++) {
      if (usersStakingPositions[stakingUserAddress][unStIndex].stakeID == stakeIDtoUnstake ) {
        usersStakingPositions[stakingUserAddress][unStIndex].unstaked = true;
      }
    }    

    totalStakedByUser[stakingUserAddress] -= amountOfTokensToUnstake;
  }

  function checkOwnedBenjamins(address userToCheck) private view returns (uint256 usersOwnedBNJIs){
    return ownedBenjamins[userToCheck];
  }

  function showInternalAddresses() public view onlyOwner returns (address[] memory) {
    return internalAddresses;  
  }

 function showStakersAddresses() public view onlyOwner returns (address[] memory) {
    return stakers;  
  }
  
  
  function checkStakedBenjamins(address userToCheck) public view returns (uint256 usersStakedBNJIs){   // XXXXX <=======changed_ this only for testing, should be private visibility
    uint256 usersTotalStake = totalStakedByUser[userToCheck];
   
    return usersTotalStake;
  }   

  function depositIntoLendingPool(uint256 amount) private {    
		polygonLendingPool.deposit(address(polygonUSDC), amount, addressOfThisContract, 0);    
    emit LendingPoolDeposit(amount);
	}

	function withdrawFromLendingPool(uint256 amount) private whenNotPaused {
		polygonLendingPool.withdraw(address(polygonUSDC), amount, addressOfThisContract);
    emit LendingPoolWithdrawal(amount);
	}
 
  
  function internalMint(uint256 amount, address holderOfInternalMint) public onlyOwner returns (uint256) {
   
    if (!isOnInternalList[holderOfInternalMint]) {
      internalAddresses.push(holderOfInternalMint);
      isOnInternalList[holderOfInternalMint] = true;
    }
    
    require(amount > 0, "BNJ, internalMint: Amount must be more than zero.");        
    require(amount % 20 == 0, "BNJ, internalMint: Amount must be divisible by 20");   
    
    uint256 priceForMintingIn6dec = calcSpecMintReturn(amount);    

    uint256 polygonUSDCbalanceIn6dec = polygonUSDC.balanceOf( msg.sender ) ;   

    uint256 USDCAllowancein6dec = polygonUSDC.allowance(msg.sender, addressOfThisContract);     
    
    require (priceForMintingIn6dec <= polygonUSDCbalanceIn6dec, "BNJ, internalMint: Not enough USDC"); 
    require (priceForMintingIn6dec <= USDCAllowancein6dec, "BNJ, internalMint: Not enough allowance in USDC for payment" );
    require (priceForMintingIn6dec >= 5000000, "BNJ, internalMint: Minimum minting value of $5 USDC" );      

    polygonUSDC.transferFrom(msg.sender, addressOfThisContract, priceForMintingIn6dec);
    depositIntoLendingPool(priceForMintingIn6dec);    
  
    // minting to Benjamins contract itself
    _mint(addressOfThisContract, amount);
    emit SpecifiedMintEvent(msg.sender, amount, priceForMintingIn6dec);

    // this is the user's balance of tokens
    internalBenjamins[holderOfInternalMint] += amount;    

    return priceForMintingIn6dec; 
  }

  function internalBurn(uint256 amount) public whenNotPaused nonReentrant returns (uint256) {   

    require(amount % 20 == 0, "BNJ, internalBurn: Amount must be divisible by 20");   

    uint256 tokenBalance = internalBenjamins[msg.sender];  
     
    require(amount > 0, "Amount to burn must be more than zero.");  
    require(tokenBalance >= amount, "Users tokenBalance must be equal to or more than amount to burn.");             
    
    uint256 returnForBurningIn6dec = calcSpecBurnReturn(amount);    

    require (returnForBurningIn6dec >= 5000000, "BNJ, internalBurn: Minimum burning value is $5 USDC" );    

    // this is the user's balance of tokens
    internalBenjamins[msg.sender] -= amount;

    _burn(addressOfThisContract, amount);      
    emit SpecifiedBurnEvent(msg.sender, amount, returnForBurningIn6dec);  

    withdrawFromLendingPool(returnForBurningIn6dec); 
   
    polygonUSDC.transfer(msg.sender, returnForBurningIn6dec);  

    return returnForBurningIn6dec;   
  }

  function showAllUsersStakes(address userToCheck) public view onlyOwner returns (Stake[] memory stakeArray) { 
    return usersStakingPositions[userToCheck];
  }

  function showInternalBenjamins (address userToCheck) public view onlyOwner returns (uint256) {   
    return internalBenjamins[userToCheck];
  }

  function getInternalActiveStakes(address userToCheck) public view onlyOwner returns (Stake[] memory stakeArray){

    uint256 nrOfActiveStakes;

    Stake[] memory usersStakeArray = internalStakingPositions[userToCheck];

    for (uint256 index = 0; index < usersStakeArray.length; index++) { 

      // each time an active stake is found, nrOfActiveStakes is increased by 1
      if (usersStakeArray[index].unstaked == false) {
        nrOfActiveStakes++;
      }     
    }

    if (nrOfActiveStakes == 0){
      return new Stake[](0);
    }

    else {
      // 'activeStakes' array with hardcoded length, defined by active stakes found above
      Stake[] memory activeStakes = new Stake[](nrOfActiveStakes);      

      // index position in activeStakes array
      uint256 newIndex = 0 ;

      for (uint256 k = 0; k < activeStakes.length; k++) {
        
        // each time an active stake is found, its details are put into the next position in the 'activeStakes' array
        if (usersStakeArray[k].unstaked == false) {
          activeStakes[newIndex].stakingAddress = usersStakeArray[newIndex].stakingAddress;
          activeStakes[newIndex].stakeID = usersStakeArray[newIndex].stakeID;          
          activeStakes[newIndex].tokenAmount = usersStakeArray[newIndex].tokenAmount;
          activeStakes[newIndex].stakeCreatedTimestamp = usersStakeArray[newIndex].stakeCreatedTimestamp;
          activeStakes[newIndex].unstaked = usersStakeArray[newIndex].unstaked;
          newIndex++;
        }         

      }
      // returning activeStakes array
      return activeStakes; 

    } 
    
  } 

  function calcAccumulated() public view onlyOwner returns (uint256 accumulatedAmount) {
    uint256 allTokensValue = calcAllTokensValue();
    uint256 allTokensValueBuffered = (allTokensValue * 97) / 100;

    uint256 allAMUSDC = polygonAMUSDC.balanceOf(addressOfThisContract);

    uint256 accumulated = allTokensValueBuffered - allAMUSDC;
    return accumulated;

  }   

  function withdrawAccumulated(uint256 amount) public onlyOwner {
    polygonAMUSDC.transfer(accumulatedReceiver, amount);
  } 

  function depositUSDCBuffer (uint256 amount) public onlyOwner {
    polygonLendingPool.deposit(address(polygonUSDC), amount, addressOfThisContract, 0);    
    emit LendingPoolDeposit(amount);
  } 

  function calcAllTokensValue() public view onlyOwner returns (uint256 allTokensReturn) {
    return calcReturnForTokenBurn(totalSupply(), totalSupply()); 
  }

  function updateStakingPeriodInSeconds (uint256 newstakingPeriodInSeconds) public onlyOwner {
    stakingPeriodInSeconds = newstakingPeriodInSeconds;
  }  

  function updateFeeReceiver(address newAddress) public onlyOwner {
    require(newAddress != address(0), "updateFeeReceiver: newAddress cannot be the zero address");
    feeReceiver = newAddress;
  }

  function updateAccumulatedReceiver(address newAddress) public onlyOwner {
    require(newAddress != address(0), "updateAccumulatedReceiver: newAddress cannot be the zero address");
    accumulatedReceiver = newAddress;
  }  

  function updatePolygonUSDC(address newAddress) public onlyOwner {
    require(newAddress != address(0), "updatePolygonUSDC: newAddress cannot be the zero address");
    polygonUSDC = IERC20(newAddress);
  }

  function updatePolygonAMUSDCC(address newAddress) public onlyOwner {
    require(newAddress != address(0), "updatePolygonAMUSDCC: newAddress cannot be the zero address");
    polygonAMUSDC = IERC20(newAddress);
  }

  function updatePolygonLendingPool(address newAddress) public onlyOwner {
    require(newAddress != address(0), "updatePolygonLendingPool: newAddress cannot be the zero address");
    polygonLendingPool = ILendingPool(newAddress);
  }
    
  function updateTier0feeMod (uint256 newtier0feeMod) public onlyOwner {
    tier_0_feeMod = newtier0feeMod;
  }

  function updateTier1feeMod (uint256 newtier1feeMod) public onlyOwner {
    tier_1_feeMod = newtier1feeMod;
  }

  function updateTier2feeMod (uint256 newtier2feeMod) public onlyOwner {
    tier_2_feeMod = newtier2feeMod;
  }

  function updateTier3feeMod (uint256 newtier3feeMod) public onlyOwner {
    tier_3_feeMod = newtier3feeMod;
  }

  function updateTier4feeMod (uint256 newtier4feeMod) public onlyOwner {
    tier_4_feeMod = newtier4feeMod;
  } 

  function updateTier5feeMod (uint256 newtier4feeMod) public onlyOwner {
    tier_5_feeMod = newtier4feeMod;
  }   

}