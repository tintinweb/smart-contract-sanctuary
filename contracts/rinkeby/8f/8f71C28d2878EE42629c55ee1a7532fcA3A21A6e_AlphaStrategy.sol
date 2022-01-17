// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./libraries/SafeERC20.sol";
import "../utils/Pausable.sol";
import "./libraries/Math.sol";
import "./libraries/Data.sol";
import "./AdminInterface.sol";
import "./AlphaToken.sol";
import "./DepositNFT.sol";
import "./WithdrawalNFT.sol";


/**
 * @title Alpha Strategy 
 * @dev Implementation of the strategy Alpha
 */

contract AlphaStrategy is Pausable {
    using SafeERC20 for IERC20;
    using Math for uint256;
    // Alpha token variables
    uint256 AMOUNT_SCALE_DECIMALS = 1;
    uint256 public MAX_AMOUNT_DEPOSIT = 1000000 * 1e18;
    uint256 public MAX_AMOUNT_WITHDRAW = 1000000 * 1e18;
    uint256 public  TIME_WITHDRAW_MANAGER ;
    uint256  public _COEFF_SCALE_DECIMALS_F;
    uint256 public  _COEFF_SCALE_DECIMALS_P; 
    uint256  _DEPOSIT_FEE_RATE;
    uint256 public _ALPHA_PRICE;
    uint256 public _ALPHA_PRICE_WAVG;
   

    bool public CAN_CANCEL = false; 
    address _treasury;

    uint256 tokenIdDeposit = 1;
    uint256 tokenIdWithdraw = 1;
    uint256 public withdrawAmountTotal;
    uint256 public depositAmountTotal;

    uint256[] public acceptedWithdrawPerAddress;
  
    AdminInterface public admin;
    IERC20 public stableToken;
    AlphaToken public alphaToken;
    DepositNFT public depositNFT;
    WithdrawalNFT public withdrawalNFT;


    /**
     * Init
     */
    constructor(address _admin, address _stableTokenAddress, address _alphaToken,
     address _depositNFTAdress, address _withdrawalNFTAdress) {
       require(
            _admin != address(0),
            "Formation Fi: admin address is the zero address"
        );
        require(
            _stableTokenAddress != address(0),
            "Formation Fi: Stable token address is the zero address"
        );
         require(
           _alphaToken != address(0),
            "Formation Fi: Alpha token address is the zero address"
        );
        require(
           _depositNFTAdress != address(0),
            "Formation Fi: withdrawal NFT address is the zero address"
        );
         require(
            _withdrawalNFTAdress != address(0),
            "Formation Fi: withdrawal NFT address is the zero address"
        );
        
        admin = AdminInterface(_admin);
        stableToken = IERC20(_stableTokenAddress);
        alphaToken = AlphaToken(_alphaToken);
        depositNFT = DepositNFT(_depositNFTAdress);
        withdrawalNFT = WithdrawalNFT(_withdrawalNFTAdress);
        uint8 _stableTokenDecimals = ERC20(_stableTokenAddress).decimals();
        if (_stableTokenDecimals == 6) {
         AMOUNT_SCALE_DECIMALS= 1e12;
        }
    }

    /*
     *  Modifiers
     */

     modifier onlyManager() {
         address _manager = admin.manager();
        require(msg.sender == _manager, "Formation Fi: Caller is not the manager");
        _;
    }
    modifier canCancel() {
        bool  _CAN_CANCEL = admin.CAN_CANCEL();
        require(_CAN_CANCEL == true, "Formation Fi: Cancel feature is not available");
        _;
    }

    /**
     * @dev getter functions.
     */
    function getTVL() public view returns (uint256) {
        return (admin.ALPHA_PRICE() * alphaToken.totalSupply()) 
        / admin.COEFF_SCALE_DECIMALS_P();
    }
   function updateAdminData() internal {
      _COEFF_SCALE_DECIMALS_F = admin.COEFF_SCALE_DECIMALS_F();
      _COEFF_SCALE_DECIMALS_P= admin.COEFF_SCALE_DECIMALS_P(); 
      _DEPOSIT_FEE_RATE = admin.DEPOSIT_FEE_RATE();
      _ALPHA_PRICE = admin.ALPHA_PRICE();
      _ALPHA_PRICE_WAVG = admin.ALPHA_PRICE_WAVG();
    }

    // deposits
    function finalizeDeposits() external 
        whenNotPaused onlyManager {
        uint256 _feeStable;
        uint256 _amountStable;
        uint256 _depositAlpha;
        uint256 _feeStableTotal = 0;
        uint256 _depositAlphaTotal = 0; 
        uint256 _amountStableTotal = 0;
        uint256 _maxDepositAmount = 0;
        uint256 _tokenIdDeposit;
        uint256 _totalSupply = alphaToken.totalSupply();
        uint256 size = depositNFT.userSize();
        address[] memory _users = depositNFT.getArray() ;
        Data.State _state;
        updateAdminData();
        if (admin.netDepositInd() == 1) {
         _maxDepositAmount = admin.netAmountEvent() + (withdrawAmountTotal * _ALPHA_PRICE) 
         / _COEFF_SCALE_DECIMALS_P;
        }
        else {
           _maxDepositAmount = depositAmountTotal;
        }
        for (uint256 i = 0; i < size ; i++) {
            require(
            _users[i]!= address(0),
            "Formation Fi: user address is the zero address"
            );
            ( _state , _amountStable , )= depositNFT.pendingDepositPerAddress(_users[i]);
            if (_state != Data.State.PENDING) {
                continue;
            }
             if (_maxDepositAmount <= _amountStableTotal) {
                break;
            }
            _amountStable = Math.min(_maxDepositAmount  - _amountStableTotal ,  _amountStable);
            _feeStable =  (_amountStable * _DEPOSIT_FEE_RATE ) /
                _COEFF_SCALE_DECIMALS_F;
             depositAmountTotal =  depositAmountTotal - _amountStable;
            _feeStableTotal = _feeStableTotal + _feeStable;
            _depositAlpha = ((_amountStable - _feeStable) * AMOUNT_SCALE_DECIMALS *
             _COEFF_SCALE_DECIMALS_P) / _ALPHA_PRICE;
            _depositAlphaTotal = _depositAlphaTotal + _depositAlpha;
             _amountStableTotal = _amountStableTotal + _amountStable;
            alphaToken.mint(_users[i], _depositAlpha);
           
            _tokenIdDeposit = depositNFT.getTokenId(_users[i]);
            depositNFT.updateDepositData( _users[i],  _tokenIdDeposit, _amountStable, false);
            alphaToken.addAmountDeposit(_users[i],  _depositAlpha );
            alphaToken.addTimeDeposit(_users[i], block.timestamp);
            }
          _ALPHA_PRICE_WAVG  = (( _totalSupply * _ALPHA_PRICE_WAVG) + (_depositAlphaTotal * _ALPHA_PRICE)) /
            ( _totalSupply + _depositAlphaTotal);
        admin.updateAlphaPriceWAVG(_ALPHA_PRICE_WAVG);

       if (admin.MANAGEMENT_FEE_TIME() == 0){
         admin.updateManagementFeeTime(block.timestamp);   
       }
        stableToken.transfer(admin.treasury(), _feeStableTotal);
       
    }

    // withdrawals
    function finalizeWithdrawals() external
        whenNotPaused onlyManager {
        uint256 tokensToBurn = 0;
        uint256 _amountLP;
        uint256  _amountStable;
        uint256 _tokenIdWithdraw;
        uint _netDepositInd = admin.netDepositInd();
        Data.State _state;
        uint256 size = withdrawalNFT.userSize();
        address[] memory _users = withdrawalNFT.getArray() ;
        updateAdminData();
        if (_netDepositInd == 0) {
           calculateAcceptedWithdrawRequests( _users );
        }  
        for (uint256 i = 0; i < size; i++) {
            require(
            _users[i]!= address(0),
            "Formation Fi: user address is the zero address"
            );
            ( _state , _amountLP, )= withdrawalNFT.pendingWithdrawPerAddress(_users[i]);
            if (_state != Data.State.PENDING) {
                continue;
            }
            if ( _netDepositInd == 0){
            _amountLP = acceptedWithdrawPerAddress[i];
            }
            withdrawAmountTotal = withdrawAmountTotal - _amountLP ;
            _amountStable = (_amountLP *  _ALPHA_PRICE) / 
            (_COEFF_SCALE_DECIMALS_P * AMOUNT_SCALE_DECIMALS);
             admin.transferStableToken(_users[i], _amountStable);
            _tokenIdWithdraw = withdrawalNFT.getTokenId(_users[i]);
            withdrawalNFT.updateWithdrawData( _users[i],  _tokenIdWithdraw, _amountLP, false);
            tokensToBurn = tokensToBurn + _amountLP;
            alphaToken.updateDepositDataExternal(_users[i], _amountLP);
        }
        alphaToken.burn(address(this), tokensToBurn);
        delete acceptedWithdrawPerAddress; 
    }

function calculateAcceptedWithdrawRequests(address[] memory _users) 
        internal {
        require (_users.length > 0, "Formation Fi: no users provided ");
        require (admin.netDepositInd() == 0, "Formation Fi: It is a net deposit case ");
        uint256 _amountLP;
        uint256 _amountLPTotal = 0;
        uint256 _maxWithdrawAmount;
        Data.State _state;
          _maxWithdrawAmount = ((admin.netAmountEvent() + depositAmountTotal) 
          * admin.COEFF_SCALE_DECIMALS_P()) /(admin.ALPHA_PRICE() * withdrawAmountTotal);  

        for (uint256 i = 0; i < _users.length; i++) {
            require(
            _users[i]!= address(0),
            "Formation Fi: user address is the zero address"
            );
           ( _state , _amountLP, )= withdrawalNFT.pendingWithdrawPerAddress(_users[i]);
            if (_state != Data.State.PENDING) {
                continue;
            }
            _amountLP = Math.min((_maxWithdrawAmount * _amountLP), _amountLP); 
            _amountLPTotal = _amountLPTotal + _amountLP;
            acceptedWithdrawPerAddress.push(_amountLP);
            }   
        }

    function calculateNetDepositInd() public onlyManager {
        admin.calculateNetDepositInd(depositAmountTotal, withdrawAmountTotal);
    }
    function calculateNetAmountEvent() public onlyManager {
    admin.calculateNetAmountEvent( depositAmountTotal,  withdrawAmountTotal,
    MAX_AMOUNT_DEPOSIT,  MAX_AMOUNT_WITHDRAW);
    }


    /**
     * @dev user-centric actions
     * Mapped Structs with Delete-enabled Index approach
     */
    function depositRequest(uint256 _amount) external whenNotPaused {
        require(_amount * AMOUNT_SCALE_DECIMALS >= admin.MIN_AMOUNT(), 
        "Formation Fi: amount does not satisfy minimum deposit amount");
        if (depositNFT.balanceOf(msg.sender)==0){
        depositNFT.mint(msg.sender, tokenIdDeposit, _amount);
        tokenIdDeposit = tokenIdDeposit +1;
        }
        else {
        uint256 _tokenIdDeposit = depositNFT.getTokenId(msg.sender);
        depositNFT.updateDepositData (msg.sender,  _tokenIdDeposit, _amount, true);
        }
        depositAmountTotal = depositAmountTotal + _amount; 
        stableToken.transferFrom(msg.sender, address(admin), _amount);
    }

    function cancelDepositRequest(uint256 _amount) external whenNotPaused canCancel {
        uint256 _tokenIdDeposit = depositNFT.getTokenId(msg.sender);
        depositNFT.updateDepositData(msg.sender,  _tokenIdDeposit, _amount, false);
        depositAmountTotal = depositAmountTotal - _amount; 
        admin.transferStableToken(msg.sender, _amount);
        
    }

    function withdrawRequest(uint256 _amount) external whenNotPaused {
        require ( _amount > 0, "Formation Fi: amount is zero");
        require((alphaToken.balanceOf(msg.sender)) >= _amount,
         "Formation Fi: amount exceeds user balance");
        require (alphaToken.ChecklWithdrawalRequest(msg.sender, _amount, admin.LOCKUP_PERIOD_USER()),
         "Formation Fi: Manager Position locked");
        withdrawalNFT.mint(msg.sender, tokenIdWithdraw, _amount);
        tokenIdWithdraw = tokenIdWithdraw +1;
        withdrawAmountTotal = withdrawAmountTotal + _amount;
        alphaToken.transferFrom(msg.sender, address(this), _amount);
         
    }

    function cancelWithdrawalRequest( uint256 _amount) external whenNotPaused {
         require ( _amount > 0, "Formation Fi: amount is zero");
         uint256 _tokenIdWithdraw = withdrawalNFT.getTokenId(msg.sender);
         withdrawalNFT.updateWithdrawData(msg.sender, _tokenIdWithdraw, _amount, false);
         alphaToken.transfer(msg.sender, _amount);
    }
    

    
    

   
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x95d89b41)
        );
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x06fdde03)
        );
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(0x313ce567)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: Transfer failed"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x23b872dd, from, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TransferFrom failed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

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
        require(!paused, "Transaction is not available");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "Transaction is available");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.4;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
library Data {

enum State {
        NONE,
        PENDING,
        READY
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./libraries/SafeERC20.sol";
import "../utils/Pausable.sol";
import "./libraries/Math.sol";
import "./AlphaToken.sol";

/**
 * @title AlphaToken
 * @dev Implementation of the LP Token "ALPHA".
 */

contract AdminInterface is Pausable {
    using SafeERC20 for IERC20;
    uint256  public COEFF_SCALE_DECIMALS_F = 1e4;
    uint256  public COEFF_SCALE_DECIMALS_P = 1e6;

    // fees
    uint256 public DEPOSIT_FEE_RATE = 50;
    uint256 public MANAGEMENT_FEE_RATE = 200;
    uint256 public PERFORMANCE_FEE_RATE = 2000;
    uint256 public AMOUNT_SCALE_DECIMALS =1;
    uint256 public SECONDES_PER_YEAR = 86400 * 365;  
    uint256 public PERFORMANCE_FEES = 0;
    uint256 public MANAGEMENT_FEES = 0;
    uint256 public MANAGEMENT_FEE_TIME = 0;
    uint256 public TIME_WITHDRAW_MANAGER =0;
    uint256 public SLIPPAGE_TOLERANCE = 200;

     // deposits
    uint256 public MIN_AMOUNT = 1000 * 1e18;
    // withdrawals
    uint256 public LOCKUP_PERIOD_MANAGER = 2 hours; 
    uint256 public LOCKUP_PERIOD_USER = 7 days; 
   
    bool public CAN_CANCEL = false; 

    uint public netDepositInd= 0;
    uint256 public netAmountEvent =0;
    // price
    uint256 public ALPHA_PRICE = 1000000;
    uint256 public ALPHA_PRICE_WAVG = 1000000;

    // portfolio management
    address public manager;
    address public treasury; 
    address public alphaStrategy;

    AlphaToken public alphaToken;
    IERC20 public stableToken;
    constructor( address _manager, address _treasury, address _stableTokenAddress,
     address _alphaToken) {
        require(
            _manager != address(0),
            "Formation Fi: manager address is the zero address"
        );
         require(
           _treasury != address(0),
            "Formation Fi:  treasury address is the zero address"
            );
         require(
            _stableTokenAddress != address(0),
            "Formation Fi: Stable token address is the zero address"
        );
         require(
           _alphaToken != address(0),
            "Formation Fi: Alpha token address is the zero address"
        );
        manager = _manager;
        treasury = _treasury; 
        stableToken = IERC20(_stableTokenAddress);
        alphaToken = AlphaToken(_alphaToken);
        uint8 _stableTokenDecimals = ERC20(_stableTokenAddress).decimals();
        if (_stableTokenDecimals == 6) {
         AMOUNT_SCALE_DECIMALS= 1e12;
        }


     }
      modifier onlyAlphaStrategy() {
        require(alphaStrategy != address(0),
            "Formation Fi: alphaStrategy is the zero address"
        );

        require(msg.sender == alphaStrategy,
             "Formation Fi: Caller is not the alphaStrategy"
        );
        _;
    }

     modifier onlyManager() {
        require(msg.sender == manager, 
        "Formation Fi: Caller is not the manager");
        _;
    }
    modifier canCancel() {
        require(CAN_CANCEL == true, "Formation Fi: Cancel feature is not available");
        _;
    }

    // manager functions

    function setTreasury(address _treasury) external onlyOwner {
        require(
            _treasury != address(0),
            "Formation Fi: manager address is the zero address"
        );
        treasury = _treasury;
    }

    function setManager(address _manager) external onlyOwner {
        require(
            _manager != address(0),
            "Formation Fi: manager address is the zero address"
        );
        manager = _manager;
    }

    function setAlphaStrategy(address _alphaStrategy) public onlyOwner {
         require(
            _alphaStrategy!= address(0),
            "Formation Fi: alphaStrategy is the zero address"
        );
         alphaStrategy = _alphaStrategy;
    } 


     function setStableToken(address _stableTokenAddress) public onlyOwner {
         require(
             _stableTokenAddress!= address(0),
            "Formation Fi: stable token address is the zero address"
        );
        stableToken = IERC20(_stableTokenAddress);
        uint8 _stableTokenDecimals = ERC20(_stableTokenAddress).decimals();
        if (_stableTokenDecimals == 6) {
         AMOUNT_SCALE_DECIMALS= 1e12;
        }
        else {
        AMOUNT_SCALE_DECIMALS = 1;   
        }
    } 
     function setCancel(bool _cancel) external onlyManager {
        CAN_CANCEL = _cancel;
    }
     function setLockupPeriodManager(uint256 _lockupPeriodManager) external onlyManager {
        LOCKUP_PERIOD_MANAGER = _lockupPeriodManager;
    }

    function setLockupPeriodUser(uint256 _lockupPeriodUser) external onlyManager {
        LOCKUP_PERIOD_USER = _lockupPeriodUser;
    }
 
    function setDepositFeeRate(uint256 _rate) external onlyManager {
        DEPOSIT_FEE_RATE = _rate;
    }

    function setManagementFeeRateDay(uint256 _rate) external onlyManager {
        MANAGEMENT_FEE_RATE = _rate;
    }

    function setPerformanceFeeRate(uint256 _rate) external onlyManager {
         PERFORMANCE_FEE_RATE  = _rate;
    }
    function setMinAmount(uint256 _minAmount) external onlyManager {
       MIN_AMOUNT = _minAmount;
     }

    function setCoeffScaleDecimalsFees (uint256 _scale) external onlyManager {
       COEFF_SCALE_DECIMALS_F  = _scale;
     }

    function setCoeffScaleDecimalsPrice (uint256 _scale) external onlyManager {
       COEFF_SCALE_DECIMALS_P  = _scale;
     }

    function updateAlphaPrice(uint256 _price) external onlyManager {
        ALPHA_PRICE = _price;
    }

    function updateAlphaPriceWAVG(uint256 _price_WAVG ) external onlyManager {
        ALPHA_PRICE_WAVG  = _price_WAVG;
    }

    function updateManagementFeeTime(uint256 _time ) external onlyAlphaStrategy {
        MANAGEMENT_FEE_TIME = _time;
    }
  
  // fees
    function calculatePerformanceFees() external onlyManager  {
        require(PERFORMANCE_FEES == 0, "Formation Fi: performance fees pending minting");
        uint256 _deltaPrice = 0;
        if (ALPHA_PRICE > ALPHA_PRICE_WAVG) {
            _deltaPrice = ALPHA_PRICE - ALPHA_PRICE_WAVG;
            ALPHA_PRICE_WAVG = ALPHA_PRICE;
        
         PERFORMANCE_FEES = (alphaToken.totalSupply() *
         _deltaPrice *  PERFORMANCE_FEE_RATE) / (ALPHA_PRICE * COEFF_SCALE_DECIMALS_F); 
        }
    }

    function calculateManagementFees(uint256) external onlyManager {
        require(MANAGEMENT_FEES == 0, "Formation Fi: management fees pending minting");
        require(MANAGEMENT_FEE_TIME!= 0, "Formation Fi: there is not a deposit yet");
        uint256 _deltaTime;
        _deltaTime = block.timestamp -  MANAGEMENT_FEE_TIME; 
        MANAGEMENT_FEES = (alphaToken.totalSupply() * MANAGEMENT_FEE_RATE * _deltaTime ) 
        /(COEFF_SCALE_DECIMALS_F * SECONDES_PER_YEAR);
        MANAGEMENT_FEE_TIME = block.timestamp; 
    }

    function mintFees() external onlyManager {
        alphaToken.mint(treasury, PERFORMANCE_FEES + MANAGEMENT_FEES);
        PERFORMANCE_FEES = 0;
        MANAGEMENT_FEES = 0;
    }

    /**
     * @dev money management
     */
    function calculateNetDepositInd(uint256 _depositAmountTotal, uint256 _withdrawAmountTotal)
     public onlyManager {
        if ((_depositAmountTotal * AMOUNT_SCALE_DECIMALS) >= 
        ((_withdrawAmountTotal * ALPHA_PRICE) / COEFF_SCALE_DECIMALS_P)){
            netDepositInd = 1 ;
        }
        else {
            netDepositInd = 0;
        }
    }
    function calculateNetAmountEvent(uint256 _depositAmountTotal, uint256 _withdrawAmountTotal,
    uint256 _MAX_AMOUNT_DEPOSIT, uint256 _MAX_AMOUNT_WITHDRAW) public onlyManager {
        uint256 _netDeposit;
        if (netDepositInd == 1) {
             _netDeposit = (_depositAmountTotal * AMOUNT_SCALE_DECIMALS) - 
             (_withdrawAmountTotal * ALPHA_PRICE) / COEFF_SCALE_DECIMALS_P;
             netAmountEvent = Math.min(_netDeposit, _MAX_AMOUNT_DEPOSIT);
        }
        else {
            _netDeposit= ((_withdrawAmountTotal * ALPHA_PRICE) / COEFF_SCALE_DECIMALS_P) -
             (_depositAmountTotal * AMOUNT_SCALE_DECIMALS);
            netAmountEvent = Math.min(_netDeposit, _MAX_AMOUNT_WITHDRAW);
        }
    }
    function protectAgainstSlippage(uint256 _withdrawAmount) public onlyManager 
         whenNotPaused   returns (uint256) {
      if (_withdrawAmount == 0) {
            return netAmountEvent;
        } 
       uint256 _amount = 0; 
       uint256 _deltaAmount =0;
       uint256 _slippage = 0;
       uint256  _alphaAmount = 0;
       uint256 _balanceAlphaTreasury = alphaToken.balanceOf(treasury);
       uint256 _balanceStableTreasury = stableToken.balanceOf(treasury);
      
      if (_withdrawAmount< netAmountEvent){
          _amount = netAmountEvent - _withdrawAmount;   
          _slippage = _amount  / netAmountEvent;
         if ((_slippage * COEFF_SCALE_DECIMALS_F) >= SLIPPAGE_TOLERANCE) {
            return netAmountEvent;
         }
         else {
             _deltaAmount = Math.min(_amount, _balanceStableTreasury);
             if ( _amount > 0){
                stableToken.transferFrom(treasury, address(this), _amount);
                _alphaAmount = (_amount * COEFF_SCALE_DECIMALS_P)/ALPHA_PRICE;
                alphaToken.mint(treasury, _alphaAmount);
                return _deltaAmount - _amount;
               }  
         }    
        
      }
    else  {
          _amount = _withdrawAmount - netAmountEvent;   
           
          _alphaAmount = (_amount * COEFF_SCALE_DECIMALS_P)/ALPHA_PRICE;
          _alphaAmount =Math.min(_alphaAmount, _balanceAlphaTreasury);
          if (_alphaAmount >0) {
            _deltaAmount = (_alphaAmount * _alphaAmount)/COEFF_SCALE_DECIMALS_P;
            stableToken.transfer(treasury, _deltaAmount);   
            alphaToken.burn( treasury, _alphaAmount);
          }
          if ((_amount - _deltaAmount)>0) {
              stableToken.transfer(manager, _amount - _deltaAmount); 
          }
        }

    } 

    function availableBalanceWithdrawal(uint256 _amount) external 
    whenNotPaused onlyManager {
        require(block.timestamp - TIME_WITHDRAW_MANAGER>= LOCKUP_PERIOD_MANAGER, 
         "Formation Fi: Manager Position locked");
        require(
            stableToken.balanceOf(address(this)) >= _amount,
            "Formation Fi: requested amount exceeds contract balance"
        );
        TIME_WITHDRAW_MANAGER = block.timestamp;
        stableToken.transfer(manager, _amount);
    }
    function sendStableToContract(uint256 _withdrawAmount) external 
      whenNotPaused onlyManager {
      require( _withdrawAmount > 0,  "amount is zero");
      stableToken.transferFrom(msg.sender, address(this), _withdrawAmount);
      }
    function transferStableToken(address _receiver, uint256 _amount) external onlyAlphaStrategy{
        stableToken.transfer(_receiver, _amount);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/Math.sol";

/**
 * @title AlphaToken
 * @dev Implementation of the LP Token "ALPHA".
 */

contract AlphaToken is ERC20, Ownable {
    // Proxy address
    address alphaStrategy;
    address admin;
    mapping(address => uint256[]) public  amountDepositPerAddress;
    mapping(address => uint256[]) public  timeDepositPerAddress; 
    constructor() ERC20("Formation Fi: Alpha Token", "Alpha") {}


    modifier onlyProxy() {
        require(
            (alphaStrategy != address(0)) && (admin != address(0)),
            "Formation Fi: proxy is the zero address"
        );

        require(
            (msg.sender == alphaStrategy) || (msg.sender == admin),
             "Formation Fi: Caller is not the proxy"
        );
        _;
    }
    modifier onlyAlphaStrategy() {
        require(alphaStrategy != address(0),
            "Formation Fi: alphaStrategy is the zero address"
        );

        require(msg.sender == alphaStrategy,
             "Formation Fi: Caller is not the alphaStrategy"
        );
        _;
    }
   
    
    function setAlphaStrategy(address _alphaStrategy) external onlyOwner {
         require(
            _alphaStrategy!= address(0),
            "Formation Fi: alphaStrategy is the zero address"
        );
         alphaStrategy = _alphaStrategy;
    } 
    function setAdmin(address _admin) external onlyOwner {
         require(
            _admin!= address(0),
            "Formation Fi: admin is the zero address"
        );
         admin = _admin;
    } 

    function addTimeDeposit(address _account, uint256 _time) external onlyAlphaStrategy {
         require(
            _account!= address(0),
            "Formation Fi: account is the zero address"
        );
         require(
            _time!= 0,
            "Formation Fi: deposit time is zero"
        );
        timeDepositPerAddress[_account].push(_time);
    } 


    function addAmountDeposit(address _account, uint256 _amount) external onlyAlphaStrategy {
         require(
            _account!= address(0),
            "Formation Fi: account is the zero address"
        );
         require(
            _amount!= 0,
            "Formation Fi: deposit amount is zero"
        );
        amountDepositPerAddress[_account].push(_amount);

    } 

   function mint(address _account, uint256 _amount) external onlyProxy {
        require(
            _account!= address(0),
            "Formation Fi: account is the zero address"
        );
         require(
            _amount!= 0,
            "Formation Fi: amount is zero"
        );
       _mint(_account,  _amount);
   }

    function burn(address _account, uint256 _amount) external onlyProxy {
        require(
            _account!= address(0),
            "Formation Fi: account is the zero address"
        );
         require(
            _amount!= 0,
            "Formation Fi: amount is zero"
        );
        _burn( _account, _amount);
    }

    function ChecklWithdrawalRequest(address _account, uint256 _amount, uint256 _period) 
     external view returns (bool){

     require(
            _account!= address(0),
            "Formation Fi: account is the zero address"
        );
    require(
           _amount!= 0,
            "Formation Fi: amount is zero"
        );
     uint256 [] memory _amountDeposit = amountDepositPerAddress[_account];
     uint256 [] memory _timeDeposit = timeDepositPerAddress[_account];
     uint256 _amountTotal = 0;
     for (uint256 i = 0; i < _amountDeposit.length; i++) {
        require ((block.timestamp - _timeDeposit[i]) >= _period, 
        "Formation Fi: user Position locked");
        if (_amount<= (_amountTotal + _amountDeposit[i]) ){
           break; 
        }
        _amountTotal = _amountTotal + _amountDeposit[i];
     }
     return true;
    }

    function updateDepositDataExternal( address _account,  uint256 _amount) 
    external onlyAlphaStrategy {
     require(
            _account!= address(0),
            "Formation Fi: account is the zero address"
        );
    require(
            _amount!= 0,
            "Formation Fi: amount is zero"
        );
     uint256 [] memory _amountDeposit = amountDepositPerAddress[ _account];
     uint256 _amountlocal = 0;
     uint256 _amountTotal = 0;
     uint256 _newAmount;
     for (uint256 i = 0; i < _amountDeposit.length; i++) {
         _amountlocal  = Math.min(_amountDeposit[i], _amount- _amountTotal);
         _amountTotal = _amountTotal +  _amountlocal;
         _newAmount = _amountDeposit[i] - _amountlocal;
         amountDepositPerAddress[_account][i] = _newAmount;
         if (_newAmount==0){
            deleteDepositData(_account, i);
         }
        if (_amountTotal == _amount){
           break; 
        }
     }
    }

function updateDepositDataInernal( address _account,  uint256 _amount) internal {
     require(
            _account!= address(0),
            "Formation Fi: account is the zero address"
        );
    require(
            _amount!= 0,
            "Formation Fi: amount is zero"
        );
     uint256 [] memory _amountDeposit = amountDepositPerAddress[ _account];
     uint256 _amountlocal = 0;
     uint256 _amountTotal = 0;
     uint256 _newAmount;
     for (uint256 i = 0; i < _amountDeposit.length; i++) {
         _amountlocal  = Math.min(_amountDeposit[i], _amount- _amountTotal);
         _amountTotal = _amountTotal +  _amountlocal;
         _newAmount = _amountDeposit[i] - _amountlocal;
         amountDepositPerAddress[_account][i] = _newAmount;
         if (_newAmount==0){
            deleteDepositData(_account, i);
         }
        if (_amountTotal == _amount){
           break; 
        }
     }
    }

function deleteDepositData(address _account, uint256 _ind) internal {
        require(
            _account!= address(0),
            "Formation Fi: account is the zero address"
        );
        
        require(_ind < amountDepositPerAddress[_account].length,
            " ind is out of the range"
        );
        uint256 size = amountDepositPerAddress[_account].length-1;

        for (uint256 i = _ind; i< size; i++){
            amountDepositPerAddress[ _account][i] = amountDepositPerAddress[ _account][i+1];
            timeDepositPerAddress[ _account][i] = timeDepositPerAddress[ _account][i+1];
        }
         amountDepositPerAddress[ _account].pop();
         timeDepositPerAddress[ _account].pop();
       
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
      ) internal virtual override{
      if ((to != alphaStrategy) && (to != admin))
      {
      updateDepositDataInernal(from, amount);
      amountDepositPerAddress[to].push(amount);
      timeDepositPerAddress[to].push(block.timestamp);
      }
    }



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/Data.sol";

contract DepositNFT is ERC721, Ownable {
struct PendingDeposit {
        Data.State state;
        uint256 amountStable;
        uint256 listPointer;
    }
 address proxy;   
 mapping(address => uint256) private tokenIdPerAddress;
 mapping(address => PendingDeposit) public pendingDepositPerAddress;
 address[] public usersOnPendingDeposit;

constructor ()  ERC721 ("DepositProof", "DPP"){
    }

 modifier onlyProxy() {
        require(
            proxy != address(0),
            "Formation Fi: proxy is the zero address"
        );
        require(msg.sender == proxy, "Formation Fi: Caller is not the proxy");
        _;
    }

function setProxy(address _proxy) public onlyOwner {
    require(
            _proxy != address(0),
            "Formation Fi: proxy is the zero address"
        );
         proxy = _proxy;

    }    

function mint(address _account, uint256 _tokenId, uint256 _amount) external onlyProxy {
       require (balanceOf(_account) == 0, "Formation Fi: account has already a deposit NfT");
       _safeMint(_account,  _tokenId);
       tokenIdPerAddress[_account] = _tokenId;
       updateDepositData (_account,  _tokenId, _amount, true);
    }

function burn(uint256 tokenId) internal {
         address owner = ownerOf(tokenId);
        require (pendingDepositPerAddress[owner].state != Data.State.PENDING,
        "Formation Fi: position is on pending");
        _burn(tokenId);
        deleteDepositData(owner);
    }
function updateDepositData(address _account, uint256 _tokenId, 
         uint256 _amount, bool add) public onlyProxy {
         require( _amount > 0, "Formation Fi:  amount is zero");
         require (_exists(_tokenId), "Formation Fi: token does not exist");
         require (ownerOf(_tokenId) == _account , "Formation Fi: account is not the token owner");
        
        if (add){
        if(pendingDepositPerAddress[_account].amountStable == 0){
        pendingDepositPerAddress[_account].state = Data.State.PENDING;
        pendingDepositPerAddress[_account].listPointer = usersOnPendingDeposit.length;
        usersOnPendingDeposit.push(_account);
        }
        pendingDepositPerAddress[_account].amountStable = pendingDepositPerAddress[_account].amountStable +
         _amount;
        }
        else {
        require(pendingDepositPerAddress[_account].amountStable >= _amount, 
        "Formation Fi:  amount excedes pending deposit");
        uint256 _newAmount = pendingDepositPerAddress[_account].amountStable - _amount;
        pendingDepositPerAddress[_account].amountStable = _newAmount;
        if (_newAmount == 0){
            pendingDepositPerAddress[_account].state = Data.State.NONE;
            pendingDepositPerAddress[_account].listPointer = 0;
           burn(_tokenId);
        }
        }
}

function deleteDepositData(address _account) internal {
        require(
            _account!= address(0),
            "Formation Fi: account is the zero address"
        );
        uint256 _ind = pendingDepositPerAddress[_account].listPointer;
        uint256 size = usersOnPendingDeposit.length-1;

        for (uint256 i = _ind; i< size; i++){
            usersOnPendingDeposit[i] =  usersOnPendingDeposit[i+1];
        }
         usersOnPendingDeposit.pop();
         delete pendingDepositPerAddress[_account]; 
         delete tokenIdPerAddress[_account];    
    }



function safeTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external  {
        _safeTransfer(
        from,
        to,
        tokenId,
         " ") ;
    }

function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
    require ((to != proxy), 
      "Formation Fi: destination address cannot be the proxy"
      );

    }
   function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual  {
      pendingDepositPerAddress[to] = pendingDepositPerAddress[from];
      uint256 ind = pendingDepositPerAddress[from].listPointer;
      usersOnPendingDeposit[ind] = to; 
      tokenIdPerAddress[to] = tokenIdPerAddress[from];
      delete pendingDepositPerAddress[from];
      delete tokenIdPerAddress[from];
    }


    function getTokenId(address _owner) public view  returns (uint256) {
        return tokenIdPerAddress[ _owner];
    }
    function userSize() public view  returns (uint256) {
        return usersOnPendingDeposit.length-1;
    }

    function getArray() public view returns (address[] memory) {
        return usersOnPendingDeposit;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/Data.sol";

contract WithdrawalNFT is ERC721, Ownable {

struct PendingWithdrawal {
        Data.State state;
        uint256 amountAlpha;
        uint256 listPointer;
    }
address proxy;   
 mapping(address => uint256) private tokenIdPerAddress;
 mapping(address => PendingWithdrawal) public pendingWithdrawPerAddress;
 address[] public usersOnPendingWithdraw;

constructor () ERC721 ("WithdrawalProof", "WDP"){
    }

modifier onlyProxy() {
        require(
            proxy != address(0),
            "Formation Fi: proxy is the zero address"
        );
        require(msg.sender == proxy, "Formation Fi: Caller is not the proxy");
         _;
    }

function setProxy(address _proxy) public onlyOwner {
    require(
            _proxy != address(0),
            "Formation Fi: proxy is the zero address"
        );
         proxy = _proxy;

    }    

function mint(address _account, uint256 _tokenId, uint256 _amount) 
       external onlyProxy {
       require (pendingWithdrawPerAddress[msg.sender].state != Data.State.PENDING, 
       "Formation Fi: withdraw is pending");
       _safeMint(_account,  _tokenId);
       tokenIdPerAddress[_account] = _tokenId;
       updateWithdrawData (_account,  _tokenId,  _amount, true);
    }

function burn(uint256 tokenId) internal {
         address owner = ownerOf(tokenId);
         require (pendingWithdrawPerAddress[owner].state != Data.State.PENDING, 
        "Formation Fi: position is on pending");
        _burn(tokenId);
        deleteWithdrawData(owner);
    }
function updateWithdrawData (address _account, uint256 _tokenId, 
         uint256 _amount, bool add) public onlyProxy {
         require( _amount > 0, "Formation Fi:  amount is zero");
         require (_exists(_tokenId), "Formation Fi: token does not exist");
         require (ownerOf(_tokenId) == _account , 
         "Formation Fi: account is not the token owner");
        
        if (add){
        pendingWithdrawPerAddress[_account].state = Data.State.PENDING;
        pendingWithdrawPerAddress[_account].amountAlpha = _amount;
        pendingWithdrawPerAddress[_account].listPointer = usersOnPendingWithdraw.length;
        usersOnPendingWithdraw.push(_account);
        }
        else {
        uint256 _newAmount = pendingWithdrawPerAddress[_account].amountAlpha - _amount;
         pendingWithdrawPerAddress[_account].amountAlpha = _newAmount;
        if (_newAmount == 0){
        pendingWithdrawPerAddress[_account].state = Data.State.NONE;
        pendingWithdrawPerAddress[_account].listPointer = 0;
        burn(_tokenId);
        }
           
    }
}

function deleteWithdrawData(address _account) internal {
        require(
            _account!= address(0),
            "Formation Fi: account is the zero address"
        );
        uint256 _ind = pendingWithdrawPerAddress[_account].listPointer;
        uint256 size = usersOnPendingWithdraw.length-1;

        for (uint256 i = _ind; i< size; i++){
            usersOnPendingWithdraw[i] =  usersOnPendingWithdraw[i+1];
        }
         usersOnPendingWithdraw.pop();
         delete pendingWithdrawPerAddress[_account]; 
         delete tokenIdPerAddress[_account];    
    }

function safeTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external  {
        _safeTransfer(
        from,
        to,
        tokenId,
         " ") ;
    }

function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
    require ((to != proxy), 
      "Formation Fi: destination address cannot be the proxy"
      );

    }
function _afterTokenTransfer(
        address from,
        address to
    ) internal virtual {
      pendingWithdrawPerAddress[to] = pendingWithdrawPerAddress[from];
      uint256 ind = pendingWithdrawPerAddress[from].listPointer;
      usersOnPendingWithdraw[ind] = to; 
      tokenIdPerAddress[to] = tokenIdPerAddress[from];
      delete pendingWithdrawPerAddress[from];
      delete tokenIdPerAddress[from];
    }

    function getTokenId(address _owner) public view  returns (uint256) {
        return tokenIdPerAddress[ _owner];
    }
     function userSize() public view  returns (uint256) {
        return usersOnPendingWithdraw.length-1;
    }
    function getArray() public view returns (address[] memory) {
        return usersOnPendingWithdraw;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}