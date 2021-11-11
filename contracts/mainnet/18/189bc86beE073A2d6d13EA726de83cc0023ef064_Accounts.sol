/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.5.14;


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

// This is for per user
library AccountTokenLib {
    using SafeMath for uint256;
    struct TokenInfo {
        // Deposit info
        uint256 depositPrincipal;   // total deposit principal of ther user
        uint256 depositInterest;    // total deposit interest of the user
        uint256 lastDepositBlock;   // the block number of user's last deposit
        // Borrow info
        uint256 borrowPrincipal;    // total borrow principal of ther user
        uint256 borrowInterest;     // total borrow interest of ther user
        uint256 lastBorrowBlock;    // the block number of user's last borrow
    }

    uint256 constant BASE = 10**18;

    // returns the principal
    function getDepositPrincipal(TokenInfo storage self) public view returns(uint256) {
        return self.depositPrincipal;
    }

    function getBorrowPrincipal(TokenInfo storage self) public view returns(uint256) {
        return self.borrowPrincipal;
    }

    function getDepositBalance(TokenInfo storage self, uint accruedRate) public view returns(uint256) {
        return self.depositPrincipal.add(calculateDepositInterest(self, accruedRate));
    }

    function getBorrowBalance(TokenInfo storage self, uint accruedRate) public view returns(uint256) {
        return self.borrowPrincipal.add(calculateBorrowInterest(self, accruedRate));
    }

    function getLastDepositBlock(TokenInfo storage self) public view returns(uint256) {
        return self.lastDepositBlock;
    }

    function getLastBorrowBlock(TokenInfo storage self) public view returns(uint256) {
        return self.lastBorrowBlock;
    }

    function getDepositInterest(TokenInfo storage self) public view returns(uint256) {
        return self.depositInterest;
    }

    function getBorrowInterest(TokenInfo storage self) public view returns(uint256) {
        return self.borrowInterest;
    }

    function borrow(TokenInfo storage self, uint256 amount, uint256 accruedRate, uint256 _block) public {
        newBorrowCheckpoint(self, accruedRate, _block);
        self.borrowPrincipal = self.borrowPrincipal.add(amount);
    }

    /**
     * Update token info for withdraw. The interest will be withdrawn with higher priority.
     */
    function withdraw(TokenInfo storage self, uint256 amount, uint256 accruedRate, uint256 _block) public {
        newDepositCheckpoint(self, accruedRate, _block);
        if (self.depositInterest >= amount) {
            self.depositInterest = self.depositInterest.sub(amount);
        } else if (self.depositPrincipal.add(self.depositInterest) >= amount) {
            self.depositPrincipal = self.depositPrincipal.sub(amount.sub(self.depositInterest));
            self.depositInterest = 0;
        } else {
            self.depositPrincipal = 0;
            self.depositInterest = 0;
        }
    }

    /**
     * Update token info for deposit
     */
    function deposit(TokenInfo storage self, uint256 amount, uint accruedRate, uint256 _block) public {
        newDepositCheckpoint(self, accruedRate, _block);
        self.depositPrincipal = self.depositPrincipal.add(amount);
    }

    function repay(TokenInfo storage self, uint256 amount, uint accruedRate, uint256 _block) public {
        // updated rate (new index rate), applying the rate from startBlock(checkpoint) to currBlock
        newBorrowCheckpoint(self, accruedRate, _block);
        // user owes money, then he tries to repays
        if (self.borrowInterest > amount) {
            self.borrowInterest = self.borrowInterest.sub(amount);
        } else if (self.borrowPrincipal.add(self.borrowInterest) > amount) {
            self.borrowPrincipal = self.borrowPrincipal.sub(amount.sub(self.borrowInterest));
            self.borrowInterest = 0;
        } else {
            self.borrowPrincipal = 0;
            self.borrowInterest = 0;
        }
    }

    function newDepositCheckpoint(TokenInfo storage self, uint accruedRate, uint256 _block) public {
        self.depositInterest = calculateDepositInterest(self, accruedRate);
        self.lastDepositBlock = _block;
    }

    function newBorrowCheckpoint(TokenInfo storage self, uint accruedRate, uint256 _block) public {
        self.borrowInterest = calculateBorrowInterest(self, accruedRate);
        self.lastBorrowBlock = _block;
    }

    // Calculating interest according to the new rate
    // calculated starting from last deposit checkpoint
    function calculateDepositInterest(TokenInfo storage self, uint accruedRate) public view returns(uint256) {
        return self.depositPrincipal.add(self.depositInterest).mul(accruedRate).sub(self.depositPrincipal.mul(BASE)).div(BASE);
    }

    function calculateBorrowInterest(TokenInfo storage self, uint accruedRate) public view returns(uint256) {
        uint256 _balance = self.borrowPrincipal;
        if(accruedRate == 0 || _balance == 0 || BASE >= accruedRate) {
            return self.borrowInterest;
        } else {
            return _balance.add(self.borrowInterest).mul(accruedRate).sub(_balance.mul(BASE)).div(BASE);
        }
    }
}


/**
 * @notice Bitmap library to set or unset bits on bitmap value
 */
library BitmapLib {

    /**
     * @dev Sets the given bit in the bitmap value
     * @param _bitmap Bitmap value to update the bit in
     * @param _index Index range from 0 to 127
     * @return Returns the updated bitmap value
     */
    function setBit(uint128 _bitmap, uint8 _index) internal pure returns (uint128) {
        // Suppose `_bitmap` is in bit value:
        // 0001 0100 = represents third(_index == 2) and fifth(_index == 4) bit is set

        // Bit not set, hence, set the bit
        if( ! isBitSet(_bitmap, _index)) {
            // Suppose `_index` is = 3 = 4th bit
            // mask = 0000 1000 = Left shift to create mask to find 4rd bit status
            uint128 mask = uint128(1) << _index;

            // Setting the corrospending bit in _bitmap
            // Performing OR (|) operation
            // 0001 0100 (_bitmap)
            // 0000 1000 (mask)
            // -------------------
            // 0001 1100 (result)
            return _bitmap | mask;
        }

        // Bit already set, just return without any change
        return _bitmap;
    }

    /**
     * @dev Unsets the bit in given bitmap
     * @param _bitmap Bitmap value to update the bit in
     * @param _index Index range from 0 to 127
     * @return Returns the updated bitmap value
     */
    function unsetBit(uint128 _bitmap, uint8 _index) internal pure returns (uint128) {
        // Suppose `_bitmap` is in bit value:
        // 0001 0100 = represents third(_index == 2) and fifth(_index == 4) bit is set

        // Bit is set, hence, unset the bit
        if(isBitSet(_bitmap, _index)) {
            // Suppose `_index` is = 2 = 3th bit
            // mask = 0000 0100 = Left shift to create mask to find 3rd bit status
            uint128 mask = uint128(1) << _index;

            // Performing Bitwise NOT(~) operation
            // 1111 1011 (mask)
            mask = ~mask;

            // Unsetting the corrospending bit in _bitmap
            // Performing AND (&) operation
            // 0001 0100 (_bitmap)
            // 1111 1011 (mask)
            // -------------------
            // 0001 0000 (result)
            return _bitmap & mask;
        }

        // Bit not set, just return without any change
        return _bitmap;
    }

    /**
     * @dev Returns true if the corrosponding bit set in the bitmap
     * @param _bitmap Bitmap value to check
     * @param _index Index to check. Index range from 0 to 127
     * @return Returns true if bit is set, false otherwise
     */
    function isBitSet(uint128 _bitmap, uint8 _index) internal pure returns (bool) {
        require(_index < 128, "Index out of range for bit operation");
        // Suppose `_bitmap` is in bit value:
        // 0001 0100 = represents third(_index == 2) and fifth(_index == 4) bit is set

        // Suppose `_index` is = 2 = 3th bit
        // 0000 0100 = Left shift to create mask to find 3rd bit status
        uint128 mask = uint128(1) << _index;

        // Example: When bit is set:
        // Performing AND (&) operation
        // 0001 0100 (_bitmap)
        // 0000 0100 (mask)
        // -------------------------
        // 0000 0100 (bitSet > 0)

        // Example: When bit is not set:
        // Performing AND (&) operation
        // 0001 0100 (_bitmap)
        // 0000 1000 (mask)
        // -------------------------
        // 0000 0000 (bitSet == 0)

        uint128 bitSet = _bitmap & mask;
        // Bit is set when greater than zero, else not set
        return bitSet > 0;
    }
}

contract Constant {
    enum ActionType { DepositAction, WithdrawAction, BorrowAction, RepayAction }
    address public constant ETH_ADDR = 0x000000000000000000000000000000000000000E;
    uint256 public constant INT_UNIT = 10 ** uint256(18);
    uint256 public constant ACCURACY = 10 ** 18;
    // OKExChain blocks per year as per 3 sec per block
    uint256 public constant BLOCKS_PER_YEAR = 2102400;
}



/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


interface IGlobalConfig {
    function savingAccount() external view returns (address);
    function tokenInfoRegistry() external view returns (ITokenRegistry);
    function bank() external view returns (IBank);
    function deFinerCommunityFund() external view returns (address);
    function deFinerRate() external view returns (uint256);
    function liquidationThreshold() external view returns (uint256);
    function liquidationDiscountRatio() external view returns (uint256);
}

interface ITokenRegistry {
    function getTokenDecimals(address) external view returns (uint8);
    function getCToken(address) external view returns (address);
    function depositeMiningSpeeds(address) external view returns (uint256);
    function borrowMiningSpeeds(address) external view returns (uint256);
    function isSupportedOnCompound(address) external view returns (bool);
    function getTokens() external view returns (address[] memory);
    function getTokenInfoFromAddress(address _token) external view returns (uint8, uint256, uint256, uint256);
    function getTokenInfoFromIndex(uint index) external view returns (address, uint256, uint256, uint256);
    function getTokenIndex(address _token) external view returns (uint8);
    function addressFromIndex(uint index) external view returns(address);
    function isTokenExist(address _token) external view returns (bool isExist);
    function isTokenEnabled(address _token) external view returns (bool);
}


interface IBank {
    function newRateIndexCheckpoint(address) external;
    function deposit(address _to, address _token, uint256 _amount) external;
    function withdraw(address _from, address _token, uint256 _amount) external returns(uint);
    function borrow(address _from, address _token, uint256 _amount) external;
    function repay(address _to, address _token, uint256 _amount) external returns(uint);
    function getDepositAccruedRate(address _token, uint _depositRateRecordStart) external view returns (uint256);
    function getBorrowAccruedRate(address _token, uint _borrowRateRecordStart) external view returns (uint256);
    function depositeRateIndex(address _token, uint _blockNum) external view returns (uint);
    function borrowRateIndex(address _token, uint _blockNum) external view returns (uint);
    function depositeRateIndexNow(address _token) external view returns(uint);
    function borrowRateIndexNow(address _token) external view returns(uint);
    function updateMining(address _token) external;
    function updateDepositFINIndex(address _token) external;
    function updateBorrowFINIndex(address _token) external;
    function depositFINRateIndex(address, uint) external view returns (uint);
    function borrowFINRateIndex(address, uint) external view returns (uint);
}

contract Accounts is Constant, Initializable{
    using AccountTokenLib for AccountTokenLib.TokenInfo;
    using BitmapLib for uint128;
    using SafeMath for uint256;
    using Math for uint256;

    mapping(address => Account) public accounts;
    IGlobalConfig globalConfig;
    mapping(address => uint256) public FINAmount;

    modifier onlyAuthorized() {
        _isAuthorized();
        _;
    }

    struct Account {
        // Note, it's best practice to use functions minusAmount, addAmount, totalAmount
        // to operate tokenInfos instead of changing it directly.
        mapping(address => AccountTokenLib.TokenInfo) tokenInfos;
        uint128 depositBitmap;
        uint128 borrowBitmap;
        uint128 collateralBitmap;
        bool isCollInit;
    }

    event CollateralFlagChanged(address indexed _account, uint8 _index, bool _enabled);

    function _isAuthorized() internal view {
        require(
            msg.sender == address(globalConfig.savingAccount()) || msg.sender == address(globalConfig.bank()),
            "not authorized"
        );
    }

    /**
     * Initialize the Accounts
     * @param _globalConfig the global configuration contract
     */
    function initialize(
        IGlobalConfig _globalConfig
    ) public initializer {
        globalConfig = _globalConfig;
    }

    /**
     * @dev Initialize the Collateral flag Bitmap for given account
     * @notice This function is required for the contract upgrade, as previous users didn't
     *         have this collateral feature. So need to init the collateralBitmap for each user.
     * @param _account User account address
    */
    function initCollateralFlag(address _account) public {
        Account storage account = accounts[_account];

        // For all users by default `isCollInit` will be `false`
        if(account.isCollInit == false) {
            // Two conditions:
            // 1) An account has some position previous to this upgrade
            //    THEN: copy `depositBitmap` to `collateralBitmap`
            // 2) A new account is setup after this upgrade
            //    THEN: `depositBitmap` will be zero for that user, so don't copy

            // all deposited tokens be treated as collateral
            if(account.depositBitmap > 0) account.collateralBitmap = account.depositBitmap;
            account.isCollInit = true;
        }

        // when isCollInit == true, function will just return after if condition check
    }

    /**
     * @dev Enable/Disable collateral for a given token
     * @param _tokenIndex Index of the token
     * @param _enable `true` to enable the collateral, `false` to disable
     */
    function setCollateral(uint8 _tokenIndex, bool _enable) public {
        address accountAddr = msg.sender;
        initCollateralFlag(accountAddr);
        Account storage account = accounts[accountAddr];

        if(_enable) {
            account.collateralBitmap = account.collateralBitmap.setBit(_tokenIndex);
            // when set new collateral, no need to evaluate borrow power
        } else {
            account.collateralBitmap = account.collateralBitmap.unsetBit(_tokenIndex);
            // when unset collateral, evaluate borrow power, only when user borrowed already
            if(account.borrowBitmap > 0) {
                require(getBorrowETH(accountAddr) <= getBorrowPower(accountAddr), "Insufficient collateral");
            }
        }

        emit CollateralFlagChanged(msg.sender, _tokenIndex, _enable);
    }

    function setCollateral(uint8[] calldata _tokenIndexArr, bool[] calldata _enableArr) external {
        require(_tokenIndexArr.length == _enableArr.length, "array length does not match");
        for(uint i = 0; i < _tokenIndexArr.length; i++) {
            setCollateral(_tokenIndexArr[i], _enableArr[i]);
        }
    }

    function getCollateralStatus(address _account)
        external
        view
        returns (address[] memory tokens, bool[] memory status)
    {
        Account memory account = accounts[_account];
        ITokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        tokens = tokenRegistry.getTokens();
        uint256 tokensCount = tokens.length;
        status = new bool[](tokensCount);
        uint128 collBitmap = account.collateralBitmap;
        for(uint i = 0; i < tokensCount; i++) {
            // Example: 0001 << 1 => 0010 (mask for 2nd position)
            uint128 mask = uint128(1) << uint128(i);
            bool isEnabled = (collBitmap & mask) > 0;
            if(isEnabled) status[i] = true;
        }
    }

    /**
     * Check if the user has deposit for any tokens
     * @param _account address of the user
     * @return true if the user has positive deposit balance
     */
    function isUserHasAnyDeposits(address _account) public view returns (bool) {
        Account storage account = accounts[_account];
        return account.depositBitmap > 0;
    }

    /**
     * Check if the user has deposit for a token
     * @param _account address of the user
     * @param _index index of the token
     * @return true if the user has positive deposit balance for the token
     */
    function isUserHasDeposits(address _account, uint8 _index) public view returns (bool) {
        Account storage account = accounts[_account];
        return account.depositBitmap.isBitSet(_index);
    }

    /**
     * Check if the user has borrowed a token
     * @param _account address of the user
     * @param _index index of the token
     * @return true if the user has borrowed the token
     */
    function isUserHasBorrows(address _account, uint8 _index) public view returns (bool) {
        Account storage account = accounts[_account];
        return account.borrowBitmap.isBitSet(_index);
    }

    /**
     * Check if the user has collateral flag set
     * @param _account address of the user
     * @param _index index of the token
     * @return true if the user has collateral flag set for the given index
     */
    function isUserHasCollateral(address _account, uint8 _index) public view returns(bool) {
        Account storage account = accounts[_account];
        return account.collateralBitmap.isBitSet(_index);
    }

    /**
     * Set the deposit bitmap for a token.
     * @param _account address of the user
     * @param _index index of the token
     */
    function setInDepositBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.depositBitmap = account.depositBitmap.setBit(_index);
    }

    /**
     * Unset the deposit bitmap for a token
     * @param _account address of the user
     * @param _index index of the token
     */
    function unsetFromDepositBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.depositBitmap = account.depositBitmap.unsetBit(_index);
    }

    /**
     * Set the borrow bitmap for a token.
     * @param _account address of the user
     * @param _index index of the token
     */
    function setInBorrowBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.borrowBitmap = account.borrowBitmap.setBit(_index);
    }

    /**
     * Unset the borrow bitmap for a token
     * @param _account address of the user
     * @param _index index of the token
     */
    function unsetFromBorrowBitmap(address _account, uint8 _index) internal {
        Account storage account = accounts[_account];
        account.borrowBitmap = account.borrowBitmap.unsetBit(_index);
    }

    function getDepositPrincipal(address _accountAddr, address _token) public view returns(uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getDepositPrincipal();
    }

    function getBorrowPrincipal(address _accountAddr, address _token) public view returns(uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getBorrowPrincipal();
    }

    function getLastDepositBlock(address _accountAddr, address _token) public view returns(uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getLastDepositBlock();
    }

    function getLastBorrowBlock(address _accountAddr, address _token) public view returns(uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        return tokenInfo.getLastBorrowBlock();
    }

    /**
     * Get deposit interest of an account for a specific token
     * @param _account account address
     * @param _token token address
     * @dev The deposit interest may not have been updated in AccountTokenLib, so we need to explicited calcuate it.
     */
    function getDepositInterest(address _account, address _token) public view returns(uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_account].tokenInfos[_token];
        // If the account has never deposited the token, return 0.
        uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
        if (lastDepositBlock == 0)
            return 0;
        else {
            // As the last deposit block exists, the block is also a check point on index curve.
            uint256 accruedRate = globalConfig.bank().getDepositAccruedRate(_token, lastDepositBlock);
            return tokenInfo.calculateDepositInterest(accruedRate);
        }
    }

    function getBorrowInterest(address _accountAddr, address _token) public view returns(uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        // If the account has never borrowed the token, return 0
        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
        if (lastBorrowBlock == 0)
            return 0;
        else {
            // As the last borrow block exists, the block is also a check point on index curve.
            uint256 accruedRate = globalConfig.bank().getBorrowAccruedRate(_token, lastBorrowBlock);
            return tokenInfo.calculateBorrowInterest(accruedRate);
        }
    }

    function borrow(address _accountAddr, address _token, uint256 _amount) external onlyAuthorized {
        initCollateralFlag(_accountAddr);
        require(_amount != 0, "borrow amount is 0");
        require(isUserHasAnyDeposits(_accountAddr), "no user deposits");
        (uint8 tokenIndex, uint256 tokenDivisor, uint256 tokenPrice,) = globalConfig.tokenInfoRegistry().getTokenInfoFromAddress(_token);
        require(
            getBorrowETH(_accountAddr).add(_amount.mul(tokenPrice).div(tokenDivisor)) <=
            getBorrowPower(_accountAddr), "Insufficient collateral when borrow"
        );

        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        uint256 blockNumber = getBlockNumber();
        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();

        if(lastBorrowBlock == 0)
            tokenInfo.borrow(_amount, INT_UNIT, blockNumber);
        else {
            calculateBorrowFIN(lastBorrowBlock, _token, _accountAddr, blockNumber);
            uint256 accruedRate = globalConfig.bank().getBorrowAccruedRate(_token, lastBorrowBlock);
            // Update the token principla and interest
            tokenInfo.borrow(_amount, accruedRate, blockNumber);
        }

        // Since we have checked that borrow amount is larget than zero. We can set the borrow
        // map directly without checking the borrow balance.
        setInBorrowBitmap(_accountAddr, tokenIndex);
    }

    /**
     * Update token info for withdraw. The interest will be withdrawn with higher priority.
     */
    function withdraw(address _accountAddr, address _token, uint256 _amount) public onlyAuthorized returns (uint256) {
        initCollateralFlag(_accountAddr);
        (, uint256 tokenDivisor, uint256 tokenPrice, uint256 borrowLTV) = globalConfig.tokenInfoRegistry().getTokenInfoFromAddress(_token);

        // if user borrowed before then only check for under liquidation
        Account memory account = accounts[_accountAddr];
        if(account.borrowBitmap > 0) {
            uint256 withdrawETH = _amount.mul(tokenPrice).mul(borrowLTV).div(tokenDivisor).div(100);
            require(getBorrowETH(_accountAddr) <= getBorrowPower(_accountAddr).sub(withdrawETH), "Insufficient collateral");
        }

        (uint256 amountAfterCommission, ) = _withdraw(_accountAddr, _token, _amount, true);

        return amountAfterCommission;
    }

    /**
     * This function is called in liquidation function. There two difference between this function and
     * the Account.withdraw function: 1) It doesn't check the user's borrow power, because the user
     * is already borrowed more than it's borrowing power. 2) It doesn't take commissions.
     */
    function withdraw_liquidate(address _accountAddr, address _token, uint256 _amount) internal {
        _withdraw(_accountAddr, _token, _amount, false);
    }

    function _withdraw(address _accountAddr, address _token, uint256 _amount, bool _isCommission) internal returns (uint256, uint256) {
        uint256 calcAmount = _amount;
        // Check if withdraw amount is less than user's balance
        require(calcAmount <= getDepositBalanceCurrent(_token, _accountAddr), "Insufficient balance");

        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        uint256 lastBlock = tokenInfo.getLastDepositBlock();
        uint256 blockNumber = getBlockNumber();
        calculateDepositFIN(lastBlock, _token, _accountAddr, blockNumber);

        uint256 principalBeforeWithdraw = tokenInfo.getDepositPrincipal();

        if (lastBlock == 0)
            tokenInfo.withdraw(calcAmount, INT_UNIT, blockNumber);
        else {
            // As the last deposit block exists, the block is also a check point on index curve.
            uint256 accruedRate = globalConfig.bank().getDepositAccruedRate(_token, lastBlock);
            tokenInfo.withdraw(calcAmount, accruedRate, blockNumber);
        }

        uint256 principalAfterWithdraw = tokenInfo.getDepositPrincipal();
        if(principalAfterWithdraw == 0) {
            uint8 tokenIndex = globalConfig.tokenInfoRegistry().getTokenIndex(_token);
            unsetFromDepositBitmap(_accountAddr, tokenIndex);
        }

        uint256 commission = 0;
        if (_isCommission && _accountAddr != globalConfig.deFinerCommunityFund()) {
            // DeFiner takes 10% commission on the interest a user earn
            commission = calcAmount.sub(principalBeforeWithdraw.sub(principalAfterWithdraw)).mul(globalConfig.deFinerRate()).div(100);
            deposit(globalConfig.deFinerCommunityFund(), _token, commission);
            calcAmount = calcAmount.sub(commission);
        }

        return (calcAmount, commission);
    }

    /**
     * Update token info for deposit
     */
    function deposit(address _accountAddr, address _token, uint256 _amount) public onlyAuthorized {
        initCollateralFlag(_accountAddr);
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        if(tokenInfo.getDepositPrincipal() == 0) {
            uint8 tokenIndex = globalConfig.tokenInfoRegistry().getTokenIndex(_token);
            setInDepositBitmap(_accountAddr, tokenIndex);
        }

        uint256 blockNumber = getBlockNumber();
        uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
        if(lastDepositBlock == 0)
            tokenInfo.deposit(_amount, INT_UNIT, blockNumber);
        else {
            calculateDepositFIN(lastDepositBlock, _token, _accountAddr, blockNumber);
            uint256 accruedRate = globalConfig.bank().getDepositAccruedRate(_token, lastDepositBlock);
            tokenInfo.deposit(_amount, accruedRate, blockNumber);
        }
    }

    function repay(address _accountAddr, address _token, uint256 _amount) public onlyAuthorized returns(uint256){
        initCollateralFlag(_accountAddr);
        // Update tokenInfo
        uint256 amountOwedWithInterest = getBorrowBalanceCurrent(_token, _accountAddr);
        uint256 amount = _amount > amountOwedWithInterest ? amountOwedWithInterest : _amount;
        uint256 remain = _amount > amountOwedWithInterest ? _amount.sub(amountOwedWithInterest) : 0;
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        // Sanity check
        uint256 borrowPrincipal = tokenInfo.getBorrowPrincipal();
        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
        require(borrowPrincipal > 0, "BorrowPrincipal not gt 0");
        if(lastBorrowBlock == 0)
            tokenInfo.repay(amount, INT_UNIT, getBlockNumber());
        else {
            calculateBorrowFIN(lastBorrowBlock, _token, _accountAddr, getBlockNumber());
            uint256 accruedRate = globalConfig.bank().getBorrowAccruedRate(_token, lastBorrowBlock);
            tokenInfo.repay(amount, accruedRate, getBlockNumber());
        }

        if(borrowPrincipal == 0) {
            uint8 tokenIndex = globalConfig.tokenInfoRegistry().getTokenIndex(_token);
            unsetFromBorrowBitmap(_accountAddr, tokenIndex);
        }
        return remain;
    }

    function getDepositBalanceCurrent(
        address _token,
        address _accountAddr
    ) public view returns (uint256 depositBalance) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        IBank bank = globalConfig.bank();
        uint256 accruedRate;
        uint256 depositRateIndex = bank.depositeRateIndex(_token, tokenInfo.getLastDepositBlock());
        if(tokenInfo.getDepositPrincipal() == 0) {
            return 0;
        } else {
            if(depositRateIndex == 0) {
                accruedRate = INT_UNIT;
            } else {
                accruedRate = bank.depositeRateIndexNow(_token)
                .mul(INT_UNIT)
                .div(depositRateIndex);
            }
            return tokenInfo.getDepositBalance(accruedRate);
        }
    }

    /**
     * Get current borrow balance of a token
     * @param _token token address
     * @dev This is an estimation. Add a new checkpoint first, if you want to derive the exact balance.
     */
    function getBorrowBalanceCurrent(
        address _token,
        address _accountAddr
    ) public view returns (uint256 borrowBalance) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        IBank bank = globalConfig.bank();
        uint256 accruedRate;
        uint256 borrowRateIndex = bank.borrowRateIndex(_token, tokenInfo.getLastBorrowBlock());
        if(tokenInfo.getBorrowPrincipal() == 0) {
            return 0;
        } else {
            if(borrowRateIndex == 0) {
                accruedRate = INT_UNIT;
            } else {
                accruedRate = bank.borrowRateIndexNow(_token)
                .mul(INT_UNIT)
                .div(borrowRateIndex);
            }
            return tokenInfo.getBorrowBalance(accruedRate);
        }
    }

    /**
     * Calculate an account's borrow power based on token's LTV
     */
     /*
    function getBorrowPower(address _borrower) public view returns (uint256 power) {
        TokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        uint256 tokenNum = tokenRegistry.getCoinLength();
        for(uint256 i = 0; i < tokenNum; i++) {
            if (isUserHasDeposits(_borrower, uint8(i))) {
                (address token, uint256 divisor, uint256 price, uint256 borrowLTV) = tokenRegistry.getTokenInfoFromIndex(i);

                uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _borrower);
                power = power.add(depositBalanceCurrent.mul(price).mul(borrowLTV).div(100).div(divisor));
            }
        }
        return power;
    }
    */

    function getBorrowPower(address _borrower) public view returns (uint256 power) {
        Account storage account = accounts[_borrower];

        // if a user have deposits in some tokens and collateral enabled for some
        // then we need to iterate over his deposits for which collateral is also enabled.
        // Hence, we can derive this information by perorming AND bitmap operation
        // hasCollnDepositBitmap = collateralEnabled & hasDeposit
        // Example:
        // collateralBitmap         = 0101
        // depositBitmap            = 0110
        // ================================== OP AND
        // hasCollnDepositBitmap    = 0100 (user can only use his 3rd token as borrow power)
        uint128 hasCollnDepositBitmap = account.collateralBitmap & account.depositBitmap;

        // When no-collateral enabled and no-deposits just return '0' power
        if(hasCollnDepositBitmap == 0) return power;

        ITokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();

        // This loop has max "O(n)" complexity where "n = TokensLength", but the loop
        // calculates borrow power only for the `hasCollnDepositBitmap` bit, hence the loop
        // iterates only till the highest bit set. Example 00000100, the loop will iterate
        // only for 4 times, and only 1 time to calculate borrow the power.
        // NOTE: When transaction gas-cost goes above the block gas limit, a user can
        //      disable some of his collaterals so that he can perform the borrow.
        //      Earlier loop implementation was iterating over all tokens, hence the platform
        //      were not able to add new tokens
        for(uint i = 0; i < 128; i++) {
            // if hasCollnDepositBitmap = 0000 then break the loop
            if(hasCollnDepositBitmap > 0) {
                // hasCollnDepositBitmap = 0100
                // mask                  = 0001
                // =============================== OP AND
                // result                = 0000
                bool isEnabled = (hasCollnDepositBitmap & uint128(1)) > 0;
                // Is i(th) token enabled?
                if(isEnabled) {
                    // continue calculating borrow power for i(th) token
                    (address token, uint256 divisor, uint256 price, uint256 borrowLTV) = tokenRegistry.getTokenInfoFromIndex(i);

                    // avoid some gas consumption when borrowLTV == 0
                    if(borrowLTV != 0) {
                        uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _borrower);
                        power = power.add(depositBalanceCurrent.mul(price).mul(borrowLTV).div(100).div(divisor));
                    }
                }

                // right shift by 1
                // hasCollnDepositBitmap = 0100
                // BITWISE RIGHTSHIFT 1 on hasCollnDepositBitmap = 0010
                hasCollnDepositBitmap = hasCollnDepositBitmap >> 1;
                // continue loop and repeat the steps until `hasCollnDepositBitmap == 0`
            } else {
                break;
            }
        }

        return power;
    }

    function getCollateralETH(address _account) public view returns (uint256 collETH) {
        ITokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        Account memory account = accounts[_account];
        uint128 hasDeposits = account.depositBitmap;
        for(uint8 i = 0; i < 128; i++) {
            if(hasDeposits > 0) {
                bool isEnabled = (hasDeposits & uint128(1)) > 0;
                if(isEnabled) {
                    (address token,
                    uint256 divisor,
                    uint256 price,
                    uint256 borrowLTV) = tokenRegistry.getTokenInfoFromIndex(i);
                    if(borrowLTV != 0) {
                        uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _account);
                        collETH = collETH.add(depositBalanceCurrent.mul(price).div(divisor));
                    }
                }
                hasDeposits = hasDeposits >> 1;
            } else {
                break;
            }
        }

        return collETH;
    }

    /**
     * Get current deposit balance of a token
     * @dev This is an estimation. Add a new checkpoint first, if you want to derive the exact balance.
     */
    function getDepositETH(
        address _accountAddr
    ) public view returns (uint256 depositETH) {
        ITokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        Account memory account = accounts[_accountAddr];
        uint128 hasDeposits = account.depositBitmap;
        for(uint8 i = 0; i < 128; i++) {
            if(hasDeposits > 0) {
                bool isEnabled = (hasDeposits & uint128(1)) > 0;
                if(isEnabled) {
                    (address token, uint256 divisor, uint256 price, ) = tokenRegistry.getTokenInfoFromIndex(i);

                    uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _accountAddr);
                    depositETH = depositETH.add(depositBalanceCurrent.mul(price).div(divisor));
                }
                hasDeposits = hasDeposits >> 1;
            } else {
                break;
            }
        }

        return depositETH;
    }
    /**
     * Get borrowed balance of a token in the uint256 of Wei
     */
    function getBorrowETH(
        address _accountAddr
    ) public view returns (uint256 borrowETH) {
        ITokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        Account memory account = accounts[_accountAddr];
        uint128 hasBorrows = account.borrowBitmap;
        for(uint8 i = 0; i < 128; i++) {
            if(hasBorrows > 0) {
                bool isEnabled = (hasBorrows & uint128(1)) > 0;
                if(isEnabled) {
                    (address token, uint256 divisor, uint256 price, ) = tokenRegistry.getTokenInfoFromIndex(i);

                    uint256 borrowBalanceCurrent = getBorrowBalanceCurrent(token, _accountAddr);
                    borrowETH = borrowETH.add(borrowBalanceCurrent.mul(price).div(divisor));
                }
                hasBorrows = hasBorrows >> 1;
            } else {
                break;
            }
        }

        return borrowETH;
    }

    /**
     * Check if the account is liquidatable
     * @param _borrower borrower's account
     * @return true if the account is liquidatable
     */
    function isAccountLiquidatable(address _borrower) public returns (bool) {
        ITokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        IBank bank = globalConfig.bank();

        // Add new rate check points for all the collateral tokens from borrower in order to
        // have accurate calculation of liquidation oppotunites.
        Account memory account = accounts[_borrower];
        uint128 hasBorrowsOrDeposits = account.borrowBitmap | account.depositBitmap;
        for(uint8 i = 0; i < 128; i++) {
            if(hasBorrowsOrDeposits > 0) {
                bool isEnabled = (hasBorrowsOrDeposits & uint128(1)) > 0;
                if(isEnabled) {
                    address token = tokenRegistry.addressFromIndex(i);
                    bank.newRateIndexCheckpoint(token);
                }
                hasBorrowsOrDeposits = hasBorrowsOrDeposits >> 1;
            } else {
                break;
            }
        }

        uint256 liquidationThreshold = globalConfig.liquidationThreshold();

        uint256 totalBorrow = getBorrowETH(_borrower);
        uint256 totalCollateral = getCollateralETH(_borrower);

        // It is required that LTV is larger than LIQUIDATE_THREADHOLD for liquidation
        // return totalBorrow.mul(100) > totalCollateral.mul(liquidationThreshold);
        return totalBorrow.mul(100) > totalCollateral.mul(liquidationThreshold);
    }

    struct LiquidationVars {
        uint256 borrowerCollateralValue;
        uint256 targetTokenBalance;
        uint256 targetTokenBalanceBorrowed;
        uint256 targetTokenPrice;
        uint256 liquidationDiscountRatio;
        uint256 totalBorrow;
        uint256 borrowPower;
        uint256 liquidateTokenBalance;
        uint256 liquidateTokenPrice;
        uint256 limitRepaymentValue;
        uint256 borrowTokenLTV;
        uint256 repayAmount;
        uint256 payAmount;
    }

    function liquidate(
        address _liquidator,
        address _borrower,
        address _borrowedToken,
        address _collateralToken
    )
        external
        onlyAuthorized
        returns (
            uint256,
            uint256
        )
    {
        initCollateralFlag(_liquidator);
        initCollateralFlag(_borrower);
        require(isAccountLiquidatable(_borrower), "borrower is not liquidatable");

        // It is required that the liquidator doesn't exceed it's borrow power.
        // if liquidator has any borrows, then only check for borrowPower condition
        Account memory liquidateAcc = accounts[_liquidator];
        if(liquidateAcc.borrowBitmap > 0) {
            require(
                getBorrowETH(_liquidator) < getBorrowPower(_liquidator),
                "No extra funds used for liquidation"
            );
        }

        LiquidationVars memory vars;

        ITokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();

        // _borrowedToken balance of the liquidator (deposit balance)
        vars.targetTokenBalance = getDepositBalanceCurrent(_borrowedToken, _liquidator);
        require(vars.targetTokenBalance > 0, "amount must be > 0");

        // _borrowedToken balance of the borrower (borrow balance)
        vars.targetTokenBalanceBorrowed = getBorrowBalanceCurrent(_borrowedToken, _borrower);
        require(vars.targetTokenBalanceBorrowed > 0, "borrower not own any debt token");

        // _borrowedToken available for liquidation
        uint256 borrowedTokenAmountForLiquidation = vars.targetTokenBalance.min(vars.targetTokenBalanceBorrowed);

        // _collateralToken balance of the borrower (deposit balance)
        vars.liquidateTokenBalance = getDepositBalanceCurrent(_collateralToken, _borrower);

        uint256 targetTokenDivisor;
        (
            ,
            targetTokenDivisor,
            vars.targetTokenPrice,
            vars.borrowTokenLTV
        ) = tokenRegistry.getTokenInfoFromAddress(_borrowedToken);

        uint256 liquidateTokendivisor;
        uint256 collateralLTV;
        (
            ,
            liquidateTokendivisor,
            vars.liquidateTokenPrice,
            collateralLTV
        ) = tokenRegistry.getTokenInfoFromAddress(_collateralToken);

        // _collateralToken to purchase so that borrower's balance matches its borrow power
        vars.totalBorrow = getBorrowETH(_borrower);
        vars.borrowPower = getBorrowPower(_borrower);
        vars.liquidationDiscountRatio = globalConfig.liquidationDiscountRatio();
        vars.limitRepaymentValue = vars.totalBorrow.sub(vars.borrowPower)
            .mul(100)
            .div(vars.liquidationDiscountRatio.sub(collateralLTV));

        uint256 collateralTokenValueForLiquidation = vars.limitRepaymentValue.min(
            vars.liquidateTokenBalance
            .mul(vars.liquidateTokenPrice)
            .div(liquidateTokendivisor)
        );

        uint256 liquidationValue = collateralTokenValueForLiquidation.min(
            borrowedTokenAmountForLiquidation
            .mul(vars.targetTokenPrice)
            .mul(100)
            .div(targetTokenDivisor)
            .div(vars.liquidationDiscountRatio)
        );

        vars.repayAmount = liquidationValue.mul(vars.liquidationDiscountRatio)
            .mul(targetTokenDivisor)
            .div(100)
            .div(vars.targetTokenPrice);
        vars.payAmount = vars.repayAmount.mul(liquidateTokendivisor)
            .mul(100)
            .mul(vars.targetTokenPrice);
        vars.payAmount = vars.payAmount.div(targetTokenDivisor)
            .div(vars.liquidationDiscountRatio)
            .div(vars.liquidateTokenPrice);

        deposit(_liquidator, _collateralToken, vars.payAmount);
        withdraw_liquidate(_liquidator, _borrowedToken, vars.repayAmount);
        withdraw_liquidate(_borrower, _collateralToken, vars.payAmount);
        repay(_borrower, _borrowedToken, vars.repayAmount);

        return (vars.repayAmount, vars.payAmount);
    }


    /**
     * Get current block number
     * @return the current block number
     */
    function getBlockNumber() private view returns (uint256) {
        return block.number;
    }

    /**
     * An account claim all mined FIN token.
     * @dev If the FIN mining index point doesn't exist, we have to calculate the FIN amount
     * accurately. So the user can withdraw all available FIN tokens.
     */
    function claim(address _account) public onlyAuthorized returns(uint256){
        ITokenRegistry tokenRegistry = globalConfig.tokenInfoRegistry();
        IBank bank = globalConfig.bank();

        uint256 currentBlock = getBlockNumber();

        Account memory account = accounts[_account];
        uint128 depositBitmap = account.depositBitmap;
        uint128 borrowBitmap = account.borrowBitmap;
        uint128 hasDepositOrBorrow = depositBitmap | borrowBitmap;

        for(uint8 i = 0; i < 128; i++) {
            if(hasDepositOrBorrow > 0) {
                if((hasDepositOrBorrow & uint128(1)) > 0) {
                    address token = tokenRegistry.addressFromIndex(i);
                    AccountTokenLib.TokenInfo storage tokenInfo = accounts[_account].tokenInfos[token];
                    bank.updateMining(token);
                    if (depositBitmap.isBitSet(i)) {
                        bank.updateDepositFINIndex(token);
                        uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
                        calculateDepositFIN(lastDepositBlock, token, _account, currentBlock);
                        tokenInfo.deposit(0, bank.getDepositAccruedRate(token, lastDepositBlock), currentBlock);
                    }

                    if (borrowBitmap.isBitSet(i)) {
                        bank.updateBorrowFINIndex(token);
                        uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
                        calculateBorrowFIN(lastBorrowBlock, token, _account, currentBlock);
                        tokenInfo.borrow(0, bank.getBorrowAccruedRate(token, lastBorrowBlock), currentBlock);
                    }
                }
                hasDepositOrBorrow = hasDepositOrBorrow >> 1;
            } else {
                break;
            }
        }

        uint256 _FINAmount = FINAmount[_account];
        FINAmount[_account] = 0;
        return _FINAmount;
    }

    function claimForToken(address _account, address _token) public onlyAuthorized returns(uint256) {
        Account memory account = accounts[_account];
        uint8 index = globalConfig.tokenInfoRegistry().getTokenIndex(_token);
        bool isDeposit = account.depositBitmap.isBitSet(index);
        bool isBorrow = account.borrowBitmap.isBitSet(index);
        if(! (isDeposit || isBorrow)) return 0;

        IBank bank = globalConfig.bank();
        uint256 currentBlock = getBlockNumber();

        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_account].tokenInfos[_token];
        bank.updateMining(_token);

        if (isDeposit) {
            bank.updateDepositFINIndex(_token);
            uint256 lastDepositBlock = tokenInfo.getLastDepositBlock();
            calculateDepositFIN(lastDepositBlock, _token, _account, currentBlock);
            tokenInfo.deposit(0, bank.getDepositAccruedRate(_token, lastDepositBlock), currentBlock);
        }
        if (isBorrow) {
            bank.updateBorrowFINIndex(_token);
            uint256 lastBorrowBlock = tokenInfo.getLastBorrowBlock();
            calculateBorrowFIN(lastBorrowBlock, _token, _account, currentBlock);
            tokenInfo.borrow(0, bank.getBorrowAccruedRate(_token, lastBorrowBlock), currentBlock);
        }

        uint256 _FINAmount = FINAmount[_account];
        FINAmount[_account] = 0;
        return _FINAmount;
    }

    /**
     * Accumulate the amount FIN mined by depositing between _lastBlock and _currentBlock
     */
    function calculateDepositFIN(uint256 _lastBlock, address _token, address _accountAddr, uint256 _currentBlock) internal {
        IBank bank = globalConfig.bank();

        uint256 indexDifference = bank.depositFINRateIndex(_token, _currentBlock)
            .sub(bank.depositFINRateIndex(_token, _lastBlock));
        uint256 getFIN = getDepositBalanceCurrent(_token, _accountAddr)
            .mul(indexDifference)
            .div(bank.depositeRateIndex(_token, _currentBlock));
        FINAmount[_accountAddr] = FINAmount[_accountAddr].add(getFIN);
    }

    /**
     * Accumulate the amount FIN mined by borrowing between _lastBlock and _currentBlock
     */
    function calculateBorrowFIN(uint256 _lastBlock, address _token, address _accountAddr, uint256 _currentBlock) internal {
        IBank bank = globalConfig.bank();

        uint256 indexDifference = bank.borrowFINRateIndex(_token, _currentBlock)
            .sub(bank.borrowFINRateIndex(_token, _lastBlock));
        uint256 getFIN = getBorrowBalanceCurrent(_token, _accountAddr)
            .mul(indexDifference)
            .div(bank.borrowRateIndex(_token, _currentBlock));
        FINAmount[_accountAddr] = FINAmount[_accountAddr].add(getFIN);
    }

    function version() public pure returns(string memory) {
        return "v1.2.0";
    }
}