/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

pragma solidity 0.5.14;


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
    uint256 public constant BLOCKS_PER_YEAR = 2102400;
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

contract Accounts is Constant, Initializable{
    using AccountTokenLib for AccountTokenLib.TokenInfo;
    using BitmapLib for uint128;
    using SafeMath for uint256;
    using Math for uint256;

    mapping(address => Account) public accounts;
    IGlobalConfig globalConfig;
    mapping(address => uint256) public FINAmount;

    modifier onlyAuthorized() {
        require(msg.sender == address(globalConfig.savingAccount()) || msg.sender == address(globalConfig.bank()),
            "Only authorized to call from DeFiner internal contracts.");
        _;
    }

    struct Account {
        // Note, it's best practice to use functions minusAmount, addAmount, totalAmount
        // to operate tokenInfos instead of changing it directly.
        mapping(address => AccountTokenLib.TokenInfo) tokenInfos;
        uint128 depositBitmap;
        uint128 borrowBitmap;
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
        if (tokenInfo.getLastDepositBlock() == 0)
            return 0;
        else {
            // As the last deposit block exists, the block is also a check point on index curve.
            uint256 accruedRate = IBank(globalConfig.bank()).getDepositAccruedRate(_token, tokenInfo.getLastDepositBlock());
            return tokenInfo.calculateDepositInterest(accruedRate);
        }
    }

    function getBorrowInterest(address _accountAddr, address _token) public view returns(uint256) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        // If the account has never borrowed the token, return 0
        if (tokenInfo.getLastBorrowBlock() == 0)
            return 0;
        else {
            // As the last borrow block exists, the block is also a check point on index curve.
            uint256 accruedRate = IBank(globalConfig.bank()).getBorrowAccruedRate(_token, tokenInfo.getLastBorrowBlock());
            return tokenInfo.calculateBorrowInterest(accruedRate);
        }
    }

    function borrow(address _accountAddr, address _token, uint256 _amount) external onlyAuthorized {
        require(_amount != 0, "Borrow zero amount of token is not allowed.");
        require(isUserHasAnyDeposits(_accountAddr), "The user doesn't have any deposits.");
        (uint8 tokenIndex, uint256 tokenDivisor, uint256 tokenPrice,) = ITokenRegistry(globalConfig.tokenInfoRegistry()).getTokenInfoFromAddress(_token);
        require(
            getBorrowETH(_accountAddr).add(_amount.mul(tokenPrice).div(tokenDivisor))
            <= getBorrowPower(_accountAddr), "Insufficient collateral when borrow."
        );

        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];

        if(tokenInfo.getLastBorrowBlock() == 0)
            tokenInfo.borrow(_amount, INT_UNIT, getBlockNumber());
        else {
            calculateBorrowFIN(tokenInfo.getLastBorrowBlock(), _token, _accountAddr, getBlockNumber());
            uint256 accruedRate = IBank(globalConfig.bank()).getBorrowAccruedRate(_token, tokenInfo.getLastBorrowBlock());
            // Update the token principla and interest
            tokenInfo.borrow(_amount, accruedRate, getBlockNumber());
        }

        // Since we have checked that borrow amount is larget than zero. We can set the borrow
        // map directly without checking the borrow balance.
        setInBorrowBitmap(_accountAddr, tokenIndex);
    }

    /**
     * Update token info for withdraw. The interest will be withdrawn with higher priority.
     */
    function withdraw(address _accountAddr, address _token, uint256 _amount) public onlyAuthorized returns (uint256) {
        (, uint256 tokenDivisor, uint256 tokenPrice, uint256 borrowLTV) = ITokenRegistry(globalConfig.tokenInfoRegistry()).getTokenInfoFromAddress(_token);

        uint256 withdrawETH = _amount.mul(tokenPrice).mul(borrowLTV).div(tokenDivisor).div(100);
        require(getBorrowETH(_accountAddr) <= getBorrowPower(_accountAddr).sub(withdrawETH), "Insufficient collateral when withdraw.");

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
        // Check if withdraw amount is less than user's balance
        require(_amount <= getDepositBalanceCurrent(_token, _accountAddr), "Insufficient balance.");

        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        uint256 lastBlock = tokenInfo.getLastDepositBlock();
        uint256 currentBlock = getBlockNumber();
        calculateDepositFIN(lastBlock, _token, _accountAddr, currentBlock);

        uint256 principalBeforeWithdraw = tokenInfo.getDepositPrincipal();

        if (tokenInfo.getLastDepositBlock() == 0)
            tokenInfo.withdraw(_amount, INT_UNIT, getBlockNumber());
        else {
            // As the last deposit block exists, the block is also a check point on index curve.
            uint256 accruedRate = IBank(globalConfig.bank()).getDepositAccruedRate(_token, tokenInfo.getLastDepositBlock());
            tokenInfo.withdraw(_amount, accruedRate, getBlockNumber());
        }

        uint256 principalAfterWithdraw = tokenInfo.getDepositPrincipal();
        if(tokenInfo.getDepositPrincipal() == 0) {
            uint8 tokenIndex = ITokenRegistry(globalConfig.tokenInfoRegistry()).getTokenIndex(_token);
            unsetFromDepositBitmap(_accountAddr, tokenIndex);
        }

        uint256 commission = 0;
        if (_isCommission && _accountAddr != globalConfig.deFinerCommunityFund()) {
            // DeFiner takes 10% commission on the interest a user earn
            commission = _amount.sub(principalBeforeWithdraw.sub(principalAfterWithdraw)).mul(globalConfig.deFinerRate()).div(100);
            deposit(globalConfig.deFinerCommunityFund(), _token, commission);
            _amount = _amount.sub(commission);
        }

        return (_amount, commission);
    }

    /**
     * Update token info for deposit
     */
    function deposit(address _accountAddr, address _token, uint256 _amount) public onlyAuthorized {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        if(tokenInfo.getDepositPrincipal() == 0) {
            uint8 tokenIndex = ITokenRegistry(globalConfig.tokenInfoRegistry()).getTokenIndex(_token);
            setInDepositBitmap(_accountAddr, tokenIndex);
        }

        if(tokenInfo.getLastDepositBlock() == 0)
            tokenInfo.deposit(_amount, INT_UNIT, getBlockNumber());
        else {
            calculateDepositFIN(tokenInfo.getLastDepositBlock(), _token, _accountAddr, getBlockNumber());
            uint256 accruedRate = IBank(globalConfig.bank()).getDepositAccruedRate(_token, tokenInfo.getLastDepositBlock());
            tokenInfo.deposit(_amount, accruedRate, getBlockNumber());
        }
    }

    function repay(address _accountAddr, address _token, uint256 _amount) public onlyAuthorized returns(uint256){
        // Update tokenInfo
        uint256 amountOwedWithInterest = getBorrowBalanceCurrent(_token, _accountAddr);
        uint256 amount = _amount > amountOwedWithInterest ? amountOwedWithInterest : _amount;
        uint256 remain =  _amount > amountOwedWithInterest ? _amount.sub(amountOwedWithInterest) : 0;
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        // Sanity check
        require(tokenInfo.getBorrowPrincipal() > 0, "Token BorrowPrincipal must be greater than 0. To deposit balance, please use deposit button.");
        if(tokenInfo.getLastBorrowBlock() == 0)
            tokenInfo.repay(amount, INT_UNIT, getBlockNumber());
        else {
            calculateBorrowFIN(tokenInfo.getLastBorrowBlock(), _token, _accountAddr, getBlockNumber());
            uint256 accruedRate = IBank(globalConfig.bank()).getBorrowAccruedRate(_token, tokenInfo.getLastBorrowBlock());
            tokenInfo.repay(amount, accruedRate, getBlockNumber());
        }

        if(tokenInfo.getBorrowPrincipal() == 0) {
            uint8 tokenIndex = ITokenRegistry(globalConfig.tokenInfoRegistry()).getTokenIndex(_token);
            unsetFromBorrowBitmap(_accountAddr, tokenIndex);
        }
        return remain;
    }

    function getDepositBalanceCurrent(
        address _token,
        address _accountAddr
    ) public view returns (uint256 depositBalance) {
        AccountTokenLib.TokenInfo storage tokenInfo = accounts[_accountAddr].tokenInfos[_token];
        IBank bank = IBank(globalConfig.bank());
        uint256 accruedRate;
        if(tokenInfo.getDepositPrincipal() == 0) {
            return 0;
        } else {
            if(bank.depositRateIndex(_token, tokenInfo.getLastDepositBlock()) == 0) {
                accruedRate = INT_UNIT;
            } else {
                accruedRate = bank.depositRateIndexNow(_token)
                .mul(INT_UNIT)
                .div(bank.depositRateIndex(_token, tokenInfo.getLastDepositBlock()));
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
        IBank bank = IBank(globalConfig.bank());
        uint256 accruedRate;
        if(tokenInfo.getBorrowPrincipal() == 0) {
            return 0;
        } else {
            if(bank.borrowRateIndex(_token, tokenInfo.getLastBorrowBlock()) == 0) {
                accruedRate = INT_UNIT;
            } else {
                accruedRate = bank.borrowRateIndexNow(_token)
                .mul(INT_UNIT)
                .div(bank.borrowRateIndex(_token, tokenInfo.getLastBorrowBlock()));
            }
            return tokenInfo.getBorrowBalance(accruedRate);
        }
    }

    /**
     * Calculate an account's borrow power based on token's LTV
     */
    function getBorrowPower(address _borrower) public view returns (uint256 power) {
        ITokenRegistry tokenRegistry = ITokenRegistry(globalConfig.tokenInfoRegistry());
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

    /**
     * Get current deposit balance of a token
     * @dev This is an estimation. Add a new checkpoint first, if you want to derive the exact balance.
     */
    function getDepositETH(
        address _accountAddr
    ) public view returns (uint256 depositETH) {
        ITokenRegistry tokenRegistry = ITokenRegistry(globalConfig.tokenInfoRegistry());
        uint256 tokenNum = tokenRegistry.getCoinLength();
        for(uint256 i = 0; i < tokenNum; i++) {
            if(isUserHasDeposits(_accountAddr, uint8(i))) {
                (address token, uint256 divisor, uint256 price, ) = tokenRegistry.getTokenInfoFromIndex(i);

                uint256 depositBalanceCurrent = getDepositBalanceCurrent(token, _accountAddr);
                depositETH = depositETH.add(depositBalanceCurrent.mul(price).div(divisor));
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
        ITokenRegistry tokenRegistry = ITokenRegistry(globalConfig.tokenInfoRegistry());
        uint256 tokenNum = tokenRegistry.getCoinLength();
        for(uint256 i = 0; i < tokenNum; i++) {
            if(isUserHasBorrows(_accountAddr, uint8(i))) {
                (address token, uint256 divisor, uint256 price, ) = tokenRegistry.getTokenInfoFromIndex(i);

                uint256 borrowBalanceCurrent = getBorrowBalanceCurrent(token, _accountAddr);
                borrowETH = borrowETH.add(borrowBalanceCurrent.mul(price).div(divisor));
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
        ITokenRegistry tokenRegistry = ITokenRegistry(globalConfig.tokenInfoRegistry());
        IBank bank = IBank(globalConfig.bank());

        // Add new rate check points for all the collateral tokens from borrower in order to
        // have accurate calculation of liquidation oppotunites.
        uint256 tokenNum = tokenRegistry.getCoinLength();
        for(uint8 i = 0; i < tokenNum; i++) {
            if (isUserHasDeposits(_borrower, i) || isUserHasBorrows(_borrower, i)) {
                address token = tokenRegistry.addressFromIndex(i);
                bank.newRateIndexCheckpoint(token);
            }
        }

        uint256 liquidationThreshold = globalConfig.liquidationThreshold();
        uint256 liquidationDiscountRatio = globalConfig.liquidationDiscountRatio();

        uint256 totalBorrow = getBorrowETH(_borrower);
        uint256 totalCollateral = getDepositETH(_borrower);

        // It is required that LTV is larger than LIQUIDATE_THREADHOLD for liquidation
        // return totalBorrow.mul(100) > totalCollateral.mul(liquidationThreshold);
        return totalBorrow.mul(100) > totalCollateral.mul(liquidationThreshold) && totalBorrow.mul(100) <= totalCollateral.mul(liquidationDiscountRatio);
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
        require(isAccountLiquidatable(_borrower), "The borrower is not liquidatable.");

        // It is required that the liquidator doesn't exceed it's borrow power.
        require(
            getBorrowETH(_liquidator) < getBorrowPower(_liquidator),
            "No extra funds are used for liquidation."
        );

        LiquidationVars memory vars;

        ITokenRegistry tokenRegistry = ITokenRegistry(globalConfig.tokenInfoRegistry());

        // _borrowedToken balance of the liquidator (deposit balance)
        vars.targetTokenBalance = getDepositBalanceCurrent(_borrowedToken, _liquidator);
        require(vars.targetTokenBalance > 0, "The account amount must be greater than zero.");

        // _borrowedToken balance of the borrower (borrow balance)
        vars.targetTokenBalanceBorrowed = getBorrowBalanceCurrent(_borrowedToken, _borrower);
        require(vars.targetTokenBalanceBorrowed > 0, "The borrower doesn't own any debt token specified by the liquidator.");

        // _borrowedToken available for liquidation
        uint256 borrowedTokenAmountForLiquidation = vars.targetTokenBalance.min(vars.targetTokenBalanceBorrowed);

        // _collateralToken balance of the borrower (deposit balance)
        vars.liquidateTokenBalance = getDepositBalanceCurrent(_collateralToken, _borrower);
        vars.liquidateTokenPrice = tokenRegistry.priceFromAddress(_collateralToken);

        uint256 divisor = 10 ** uint256(tokenRegistry.getTokenDecimals(_borrowedToken));
        uint256 liquidateTokendivisor = 10 ** uint256(tokenRegistry.getTokenDecimals(_collateralToken));

        // _collateralToken to purchase so that borrower's balance matches its borrow power
        vars.totalBorrow = getBorrowETH(_borrower);
        vars.borrowPower = getBorrowPower(_borrower);
        vars.liquidationDiscountRatio = globalConfig.liquidationDiscountRatio();
        vars.borrowTokenLTV = tokenRegistry.getBorrowLTV(_borrowedToken);
        vars.limitRepaymentValue = vars.totalBorrow.sub(vars.borrowPower).mul(100).div(vars.liquidationDiscountRatio.sub(vars.borrowTokenLTV));

        uint256 collateralTokenValueForLiquidation = vars.limitRepaymentValue.min(vars.liquidateTokenBalance.mul(vars.liquidateTokenPrice).div(liquidateTokendivisor));

        vars.targetTokenPrice = tokenRegistry.priceFromAddress(_borrowedToken);
        uint256 liquidationValue = collateralTokenValueForLiquidation.min(borrowedTokenAmountForLiquidation.mul(vars.targetTokenPrice).mul(100).div(divisor).div(vars.liquidationDiscountRatio));

        vars.repayAmount = liquidationValue.mul(vars.liquidationDiscountRatio).mul(divisor).div(100).div(vars.targetTokenPrice);
        vars.payAmount = vars.repayAmount.mul(liquidateTokendivisor).mul(100).mul(vars.targetTokenPrice);
        vars.payAmount = vars.payAmount.div(divisor).div(vars.liquidationDiscountRatio).div(vars.liquidateTokenPrice);

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
        ITokenRegistry tokenRegistry = ITokenRegistry(globalConfig.tokenInfoRegistry());
        IBank bank = IBank(globalConfig.bank());
        uint256 coinLength = tokenRegistry.getCoinLength();
        for(uint8 i = 0; i < coinLength; i++) {
            if (isUserHasDeposits(_account, i) || isUserHasBorrows(_account, i)) {
                address token = tokenRegistry.addressFromIndex(i);
                AccountTokenLib.TokenInfo storage tokenInfo = accounts[_account].tokenInfos[token];
                uint256 currentBlock = getBlockNumber();
                bank.updateMining(token);

                if (isUserHasDeposits(_account, i)) {
                    bank.updateDepositFINIndex(token);
                    uint256 accruedRate = bank.getDepositAccruedRate(token, tokenInfo.getLastDepositBlock());
                    calculateDepositFIN(tokenInfo.getLastDepositBlock(), token, _account, currentBlock);
                    tokenInfo.deposit(0, accruedRate, currentBlock);
                }

                if (isUserHasBorrows(_account, i)) {
                    bank.updateBorrowFINIndex(token);
                    uint256 accruedRate = bank.getBorrowAccruedRate(token, tokenInfo.getLastBorrowBlock());
                    calculateBorrowFIN(tokenInfo.getLastBorrowBlock(), token, _account, currentBlock);
                    tokenInfo.borrow(0, accruedRate, currentBlock);
                }
            }
        }
        uint256 _FINAmount = FINAmount[_account];
        FINAmount[_account] = 0;
        return _FINAmount;
    }

    /**
     * Accumulate the amount FIN mined by depositing between _lastBlock and _currentBlock
     */
    function calculateDepositFIN(uint256 _lastBlock, address _token, address _accountAddr, uint256 _currentBlock) internal {
        IBank bank = IBank(globalConfig.bank());

        uint256 indexDifference = bank.depositFINRateIndex(_token, _currentBlock)
                                .sub(bank.depositFINRateIndex(_token, _lastBlock));
        uint256 getFIN = getDepositBalanceCurrent(_token, _accountAddr)
                        .mul(indexDifference)
                        .div(bank.depositRateIndex(_token, _currentBlock));
        FINAmount[_accountAddr] = FINAmount[_accountAddr].add(getFIN);
    }

    /**
     * Accumulate the amount FIN mined by borrowing between _lastBlock and _currentBlock
     */
    function calculateBorrowFIN(uint256 _lastBlock, address _token, address _accountAddr, uint256 _currentBlock) internal {
        IBank bank = IBank(globalConfig.bank());

        uint256 indexDifference = bank.borrowFINRateIndex(_token, _currentBlock)
                                .sub(bank.borrowFINRateIndex(_token, _lastBlock));
        uint256 getFIN = getBorrowBalanceCurrent(_token, _accountAddr)
                        .mul(indexDifference)
                        .div(bank.borrowRateIndex(_token, _currentBlock));
        FINAmount[_accountAddr] = FINAmount[_accountAddr].add(getFIN);
    }
}

interface IGlobalConfig {
    function constants() external view returns (address);
    function tokenInfoRegistry() external view returns (address);
    function chainLink() external view returns (address);
    function bank() external view returns (address);
    function savingAccount() external view returns (address);
    function accounts() external view returns (address);
    function maxReserveRatio() external view returns (uint256);
    function midReserveRatio() external view returns (uint256);
    function minReserveRatio() external view returns (uint256);
    function rateCurveSlope() external view returns (uint256);
    function rateCurveConstant() external view returns (uint256);
    function compoundSupplyRateWeights() external view returns (uint256);
    function compoundBorrowRateWeights() external view returns (uint256);
    function deFinerCommunityFund() external view returns (address);
    function deFinerRate() external view returns (uint256);
    function liquidationThreshold() external view returns (uint256);
    function liquidationDiscountRatio() external view returns (uint256);
}

interface ITokenRegistry {
    function getTokenDecimals(address) external view returns (uint8);
    function getCToken(address) external view returns (address);
    function depositeMiningSpeeds(address) external view returns (uint);
    function borrowMiningSpeeds(address) external view returns (uint);
    function isSupportedOnCompound(address) external view returns (bool);
    function getTokenInfoFromIndex(uint) external view returns (address, uint, uint, uint);
    function getTokenInfoFromAddress(address) external view returns (uint8 ,uint ,uint ,uint);
    function getTokenIndex(address) external view returns (uint8);
    function getCoinLength() external view returns (uint);
    function priceFromAddress(address) external view returns(uint);
    function getBorrowLTV(address) external view returns (uint);
    function addressFromIndex(uint) external view returns (address);
}

interface IAccount {
    function deposit(address, address, uint256) external;
    function borrow(address, address, uint256) external;
    function getBorrowPrincipal(address, address) external view returns (uint256);
    function withdraw(address, address, uint256) external returns (uint256);
    function repay(address, address, uint256) external returns (uint256);
}

interface ISavingAccount {
    function toCompound(address, uint256) external;
    function fromCompound(address, uint256) external;
}

interface IBank {
    function depositRateIndex(address, uint) external view returns (uint);
    function borrowRateIndex(address, uint) external view returns (uint);

    function depositRateIndexNow(address) external view returns (uint);
    function borrowRateIndexNow(address) external view returns (uint);

    function newRateIndexCheckpoint(address) external;
    function updateMining(address) external;

    function updateDepositFINIndex(address) external;
    function updateBorrowFINIndex(address) external;

    function getDepositAccruedRate(address, uint) external view returns (uint);
    function getBorrowAccruedRate(address, uint) external view returns (uint);

    function depositFINRateIndex(address, uint) external view returns (uint);
    function borrowFINRateIndex(address, uint) external view returns (uint);
}