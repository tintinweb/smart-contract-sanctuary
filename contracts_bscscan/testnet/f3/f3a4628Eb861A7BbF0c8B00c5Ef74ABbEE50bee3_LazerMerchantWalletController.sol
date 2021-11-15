// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./interfaces/IERC20Wallet.sol";
import "./interfaces/ILazerStorage.sol";
import "./interfaces/ILazerStorageSchema.sol";
import "./ERC20Wallet.sol";
import "./libs/SafeMath.sol";
import "./libs/IERC20.sol";
import "./libs/Ownable.sol";
import "./interfaces/IDerivativeToken.sol";

/**
 * @dev Contract for lazer merchant wallet functionality
 */
contract LazerMerchantWalletController is Ownable, ILazerStorageSchema {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ILazerStorage public storageContract;
    uint256 public precision = 100;
    uint256 public percentValue = 100;

    event WalletCreationEvent(address wallet, uint256 merchantsID, uint256 createdAt);
    event WithdrawToken(uint256 amount, uint256 commissionFee, address recipient, address wallet, uint256 merchantsID);
    event UnderlyingAssetDeposited(address wallet, uint256 underlyingAmount, uint256 derivativeAmount, uint256 balance);

    event DerivativeAssetWithdrawn(address wallet, uint256 underlyingAmount, uint256 derivativeAmount, uint256 balance);

    constructor(
        address _walletAdmin,
        address payable _owner,
        address storageAddress
    ) public {
        owner = _owner;
        WalletAdmin = _walletAdmin;
        storageContract = ILazerStorage(storageAddress);
    }

    function setPrecision(uint256 _precision) public onlyOwner {
        precision = _precision;
    }

    function setPercentValue(uint256 _percentValue) public onlyOwner {
        percentValue = _percentValue.mul(100);
    }

    function _updateStakeRecord(
        uint256 merchantId,
        address walletId,
        uint256 amountStaked,
        uint256 derivativeBalance,
        uint256 derivativeTotalWithdrawn,
        uint256 derivativeDeposits,
        uint256 underlyingTotalWithdrawn,
        address stakeToken
    ) internal {
        storageContract.updateStakeRecord(
            merchantId,
            walletId,
            amountStaked,
            derivativeBalance,
            derivativeTotalWithdrawn,
            derivativeDeposits,
            underlyingTotalWithdrawn,
            stakeToken
        );
    }

    function getStakingRecordByWallet(address wallet) public view returns (StakingRecord memory) {
        (
            uint256 merchantId,
            uint256 amountStaked,
            uint256 derivativeBalance,
            uint256 derivativeTotalWithdrawn,
            uint256 derivativeDeposits,
            uint256 underlyingTotalWithdrawn,
            address stakeToken,
            address walletId,
            bool exists
        ) = storageContract.getStakingRecordByWalletAddress(wallet);
        return
            StakingRecord(
                merchantId,
                amountStaked,
                derivativeBalance,
                derivativeTotalWithdrawn,
                derivativeDeposits,
                underlyingTotalWithdrawn,
                stakeToken,
                walletId,
                exists
            );
    }

    function _validateUserBalanceIsSufficient(address wallet, uint256 derivativeAmount) internal view {
        StakingRecord memory stakeRecord = getStakingRecordByWallet(wallet);

        uint256 derivativeBalance = stakeRecord.derivativeBalance;

        require(derivativeBalance >= derivativeAmount, "Withdrawal cannot be processes, reason: Insufficient Balance");
    }

    function createMerchantsWallet(uint256 _merchantsID, uint256 createdAt) external returns (address) {
        // get wallet by merchants Id
        ERC20Wallet wallet = new ERC20Wallet(owner, address(this));
        storageContract.createWalletMapping(_merchantsID, address(wallet), createdAt);
        storageContract.createMerchantToWalletIdMapping(_merchantsID, address(wallet), createdAt);
        emit WalletCreationEvent(address(wallet), _merchantsID, createdAt);
        return address(wallet);
    }

    function withdrawFunds(
        address walletContractAddress,
        uint256 merchantsId,
        address tokenAddress,
        uint256 amount,
        address payable recipient
    ) external onlyOwner returns (bool) {
        require(merchantsId != 0, "MerchantWallet: Contract is not a merchant wallet contract ");

        //get wallet by id from storage contract
        Wallet memory _wallet = storageContract.getWalletById(walletContractAddress);

        require(_wallet.merchant == merchantsId, "LazerMerchantWallet: MerchantId does not have wallet");

        IERC20Wallet wallet = IERC20Wallet(walletContractAddress);

        require(wallet.tokenBalanceOf(tokenAddress, address(wallet)) > 0, "MerchantWallet: Wallet is empty");

        // get 1% of the amount with precision
        // get the commission fee percentvalue of the amount with precision
        uint256 commissionFee = amount.mul(percentValue).div(precision.mul(100));
        // get the amount minus commission fee
        uint256 amountToWithdraw = amount.sub(commissionFee);

        (commissionFee, amountToWithdraw, wallet, recipient, tokenAddress) = wallet.sweepTokens(
            commissionFee,
            amountToWithdraw,
            recipient,
            tokenAddress
        );

        emit WithdrawToken(amountToWithdraw, commissionFee, recipient, address(wallet), merchantsId);
        return true;
    }

    /// @notice This function deposits funds on venus protocol
    function stakeFundsToProtocol(
        uint256 amount,
        address token,
        address derivativeToken,
        uint256 merchantId,
        address walletId
    ) external onlyOwner returns (bool) {
        require(amount > 0, "LazerMerchantWallet: Amount is 0");

        Wallet memory _wallet = storageContract.getWalletById(walletId);
        require(_wallet.merchant == merchantId, "LazerMerchantWallet: MerchantId does not have wallet");
        IERC20Wallet wallet = IERC20Wallet(walletId);

        require(wallet.tokenBalanceOf(token, address(wallet)) >= amount, "LazerMerchantWallet: Wallet does not have the amount");

        wallet.approveAddress(token, amount, address(this));
        uint256 allowance = wallet.allowance(token, address(this));
        require(allowance >= amount, "LazerMerchantWallet: Wallet does not have enough allowance");

        wallet.transfer(token, address(this), amount);

        IDerivativeToken _derivativeToken = IDerivativeToken(derivativeToken);

        IERC20 _token = IERC20(token);

        _token.safeApprove(address(_derivativeToken), amount);

        //  Now our deriavtive contract has deposited our token and it is earning interest
        //and this gives us deriavative token in this Wallet contract
        //  and we will use the derivative token to redeem our token
        _derivativeToken.mint(amount);
        //  transfer the derivative shares to the merchants wallet
        _derivativeToken.transfer(address(wallet), _derivativeToken.balanceOf(address(this)));

        //wallet balance after stake
        uint256 walletBalance = wallet.tokenBalanceOf(token, address(wallet));

        //update the staking record
        StakingRecord memory stakeRecord = _updateStakeRecordAfterDeposit(
            walletId,
            derivativeToken,
            amount,
            _derivativeToken.balanceOf(address(wallet)),
            merchantId
        );

        bool exists = storageContract.doesStakeRecordExist(walletId);

        if (exists) _updateStakeRecord(stakeRecord);
        else {
            storageContract.createStakeRecord(
                stakeRecord.merchant,
                stakeRecord.walletId,
                stakeRecord.amountStaked,
                stakeRecord.derivativeBalance,
                stakeRecord.derivativeTotalWithdrawn,
                stakeRecord.derivativeDeposits,
                stakeRecord.underlyingTotalWithdrawn,
                stakeRecord.stakeToken
            );
        }
        emit UnderlyingAssetDeposited(address(wallet), amount, _derivativeToken.balanceOf(address(wallet)), walletBalance);
        return true;
    }

    function withdrawStakeFromProtocol(
        uint256 sharesAmount,
        address token,
        address derivativeToken,
        uint256 merchantId,
        address walletId
    ) external onlyOwner returns (bool) {
        require(sharesAmount > 0, "LazerMerchantWallet: Cannot withdraw");

        Wallet memory _wallet = storageContract.getWalletById(walletId);

        require(_wallet.merchant == merchantId, "LazerMerchantWallet: MerchantId does not have wallet");

        _validateUserBalanceIsSufficient(walletId, sharesAmount);

        IERC20Wallet wallet = IERC20Wallet(walletId);

        bool isApproveSuccessful = wallet.approveAddress(derivativeToken, sharesAmount, address(this));

        require(isApproveSuccessful, "LazerMerchantWallet: Wallet does not have enough allowance");

        wallet.transferFrom(derivativeToken, address(this), sharesAmount);

        IERC20 _token = IERC20(token);

        //  We now call the withdraw function to withdraw the total we have on venus.
        // This withdrawal is sent to this smart contract
        IDerivativeToken _derivativeToken = IDerivativeToken(derivativeToken);
        _derivativeToken.redeem(sharesAmount);

        uint256 amountWithdrawn = _token.balanceOf(address(this));
        _token.safeTransfer(address(wallet), amountWithdrawn);

        StakingRecord memory stakeRecord = _updateStakeRecordAfterWithdrawal(walletId, amountWithdrawn, sharesAmount);

        _updateStakeRecord(stakeRecord);
    }

    function _updateStakeRecordAfterWithdrawal(
        address wallet,
        uint256 underlyingAmountWithdrawn,
        uint256 sharesAmount
    ) internal view returns (StakingRecord memory) {
        StakingRecord memory stakingRecord = getStakingRecordByWallet(wallet);

        stakingRecord.derivativeTotalWithdrawn = stakingRecord.derivativeTotalWithdrawn.add(sharesAmount);

        stakingRecord.underlyingTotalWithdrawn = stakingRecord.underlyingTotalWithdrawn.add(underlyingAmountWithdrawn);

        stakingRecord.derivativeBalance = stakingRecord.derivativeBalance.sub(sharesAmount);
        return stakingRecord;
    }

    function _updateStakeRecordAfterDeposit(
        address wallet,
        address derivativeToken,
        uint256 amountStaked,
        uint256 sharesAmount,
        uint256 merchant
    ) internal view returns (StakingRecord memory) {
        bool exists = storageContract.doesStakeRecordExist(wallet);
        if (!exists) {
            StakingRecord memory stakingRecord = StakingRecord(
                merchant,
                amountStaked,
                sharesAmount,
                0,
                sharesAmount,
                0,
                derivativeToken,
                wallet,
                true
            );
            return stakingRecord;
        } else {
            StakingRecord memory stakingRecord = getStakingRecordByWallet(wallet);

            stakingRecord.amountStaked = stakingRecord.amountStaked.add(amountStaked);

            stakingRecord.derivativeDeposits = stakingRecord.derivativeDeposits.add(sharesAmount);

            stakingRecord.derivativeBalance = stakingRecord.derivativeBalance.add(sharesAmount);

            return stakingRecord;
        }
    }

    function _updateStakeRecord(StakingRecord memory stakeRecord) internal {
        storageContract.updateStakeRecord(
            stakeRecord.merchant,
            stakeRecord.walletId,
            stakeRecord.amountStaked,
            stakeRecord.derivativeBalance,
            stakeRecord.derivativeTotalWithdrawn,
            stakeRecord.derivativeDeposits,
            stakeRecord.underlyingTotalWithdrawn,
            stakeRecord.stakeToken
        );
    }

    function getPricePerFullShare(address derivativeToken) external view returns (uint256) {
        IDerivativeToken _derivativeToken = IDerivativeToken(derivativeToken);
        uint256 cash = _derivativeToken.getCash();

        uint256 totalBorrows = _derivativeToken.totalBorrows();

        uint256 totalReserves = _derivativeToken.totalReserves();

        uint256 totalSupply = _derivativeToken.totalSupply();

        uint256 pricePerFullShare = (cash.add(totalBorrows).sub(totalReserves)).div(totalSupply);
        return pricePerFullShare;
    }

    function getGrossRevenue(address account, address derivativeToken) public view returns (uint256) {
        IDerivativeToken _derivativeToken = IDerivativeToken(derivativeToken);
        //  Get the price per full share
        uint256 price = _derivativeToken.exchangeRateCurrent();

        //  Get the balance of yDai in this users address
        uint256 balanceShares = _derivativeToken.balanceOf(account);

        return balanceShares.mul(price);
    }
}

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20WALLET contract
 */
interface IERC20Wallet {
    /**
     * @dev Transfers tokens to merchan'ts external address;
     */
    function sweepTokens(
        uint256 commissionFee,
        uint256 amount,
        address payable recepient,
        address tokenAddress
    )
        external
        returns (
            uint256,
            uint256,
            IERC20Wallet,
            address payable,
            address
        );

    // /**
    //  * @dev Transfers all bnb to merchant's contract address;
    //  */
    // function sweepBNB() external returns(uint,address);

    /**
     * @dev Returns the token balance for this contract
     */
    function tokenBalanceOf(address tokenAddress, address walletAddress) external view returns (uint256);

    /**
     * @dev Returns the bnb balance for this contract
     */
    // function bnbBalanceOf() external view returns (uint256);

    function approveAddress(
        address tokenAddress,
        uint256 amount,
        address spender
    ) external returns (bool success);

    function transferFrom(
        address tokenAddress,
        address to,
        uint256 amount
    ) external returns (bool success);

    function allowance(address tokenAddress, address spender) external view returns (uint256 amount);

    function transfer(
        address tokenAddress,
        address to,
        uint256 amount
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

pragma experimental ABIEncoderV2;
import "./ILazerStorageSchema.sol";

/**
 * @dev Interface of the ERC20WALLET contract
 */
interface ILazerStorage is ILazerStorageSchema {
    function getWalletById(address walletId) external view returns (Wallet memory);

    function doesStakeRecordExist(address walletId) external view returns (bool);

    function getRecordIndex(address walletId) external view returns (uint256);

    function getLenghtOfStakeRecords() external view returns (uint256);

    function getStakingRecordByIndex(uint256 index)
        external
        view
        returns (
            uint256 merchantId,
            uint256 amountStaked,
            uint256 derivativeBalance,
            uint256 derivativeTotalWithdrawn,
            uint256 derivativeDeposits,
            uint256 underlyingTotalWithdrawn,
            address stakeToken,
            address walletId,
            bool exists
        );

    function getStakingRecordByWalletAddress(address wallet)
        external
        view
        returns (
            uint256 merchantId,
            uint256 amountStaked,
            uint256 derivativeBalance,
            uint256 derivativeTotalWithdrawn,
            uint256 derivativeDeposits,
            uint256 underlyingTotalWithdrawn,
            address stakeToken,
            address walletId,
            bool exists
        );

    function createStakeRecord(
        uint256 merchantId,
        address walletId,
        uint256 amountStaked,
        uint256 derivativeBalance,
        uint256 derivativeTotalWithdrawn,
        uint256 derivativeDeposits,
        uint256 underlyingTotalWithdrawn,
        address stakeToken
    ) external;

    function updateStakeRecord(
        uint256 merchantId,
        address walletId,
        uint256 amountStaked,
        uint256 derivativeBalance,
        uint256 derivativeTotalWithdrawn,
        uint256 derivativeDeposits,
        uint256 underlyingTotalWithdrawn,
        address stakeToken
    ) external;

    function createWalletMapping(
        uint256 merchant,
        address walletId,
        uint256 createdAt
    ) external;

    function createMerchantToWalletIdMapping(
        uint256 merchant,
        address walletId,
        uint256 createdAt
    ) external;

    function getWallets() external view returns (Wallet[] memory);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.7.0;
import "../libs/IERC20.sol";

interface ILazerStorageSchema {
    struct Wallet {
        address walletId;
        uint256 createdAt;
        uint256 merchant;
    }
    struct StakingRecord {
        uint256 merchant;
        uint256 amountStaked;
        uint256 derivativeBalance;
        uint256 derivativeTotalWithdrawn;
        uint256 derivativeDeposits;
        uint256 underlyingTotalWithdrawn;
        address stakeToken;
        address walletId;
        bool exists;
    }
    struct RecordIndex {
        bool exists;
        uint256 index;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
import "./libs/Ownable.sol";
import "./libs/IERC20.sol";
import "./libs/SafeERC20.sol";
import "./libs/SafeMath.sol";

/**
 * @dev Contract for extending the lazer merchant wallet functionality
 */
contract ERC20Wallet is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token;

    constructor(address payable _owner, address _walletadmin) public {
        owner = _owner;
        WalletAdmin = _walletadmin;
    }

    // @dev withdraw tokens from merchants wallets
    function sweepTokens(
        uint256 commissionFee,
        uint256 amount,
        address payable recepient,
        address tokenAddress
    )
        public
        onlyLazerWalletOrOwner
        returns (
            uint256,
            uint256,
            address,
            address,
            address
        )
    {
        token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance != 0, "ERC20Wallet: token balance cannot be zero");

        token.safeTransfer(WalletAdmin, commissionFee);
        // transfer amount to the recepient
        uint256 walletBalanceAfterCommissionFeeWithdrawal = token.balanceOf(address(this));
        require(walletBalanceAfterCommissionFeeWithdrawal >= amount, "ERC20Wallet: not enough funds");
        token.safeTransfer(recepient, amount);
        return (commissionFee, amount, address(this), recepient, tokenAddress);
    }

    /** Should we allow for the withdrawal of bnb? Just in case someone mistakenly sends bnb to the contract? */

    // function withdrawBNB(uint256 commissionFee, address recepient) public returns (uint256,address){
    //    uint256 BNBBalance =  address(this).balance;
    //    require(BNBBalance != 0, "ERC20Wallet: BNB balance cannot be zero");
    //    owner.transfer(BNBBalance);
    //    return (BNBBalance,owner);
    // }

    function tokenBalanceOf(address tokenAddress, address walletAddress) public view returns (uint256 amount) {
        IERC20 tokenContract = IERC20(tokenAddress);
        return tokenContract.balanceOf(walletAddress);
    }

    function approveAddress(
        address tokenAddress,
        uint256 amount,
        address spender
    ) public returns (bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        return tokenContract.approve(spender, amount);
    }

    function allowance(address tokenAddress, address spender) public view returns (uint256 amount) {
        IERC20 tokenContract = IERC20(tokenAddress);
        return tokenContract.allowance(address(this), spender);
    }

    function transferFrom(
        address tokenAddress,
        address to,
        uint256 amount
    ) public returns (bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        return tokenContract.transferFrom(address(this), to, amount);
    }

    function transfer(
        address tokenAddress,
        address to,
        uint256 amount
    ) public returns (bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        return tokenContract.transfer(to, amount);
    }

    // function bnbBalanceOf() public view returns (uint256 amount) {
    //     return address(this).balance;
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

import "./Context.sol";

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
    address payable public owner;
    address public WalletAdmin;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address payable msgSender = _msgSender();
        owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    modifier onlyLazerWalletOrOwner() {
        require(msg.sender == owner || msg.sender == WalletAdmin, "Controller: caller must be wallet admin");
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
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public virtual onlyLazerWalletOrOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

pragma solidity 0.7.0;

import "../libs/IERC20.sol";

/*
    This interface is for the interest-bearing DUSD contract
*/

interface IDerivativeToken is IERC20 {
    function redeem(uint256 _shares) external returns (uint256);

    function mint(uint256 _amount) external returns (uint256);

    //function balance() external view returns (uint256);
    function exchangeRateCurrent() external view returns (uint256);

    function getCash() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalReserves() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    // solhint-disable-next-line max-line-length
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(
      value,
      "SafeERC20: decreased allowance below zero"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // solhint-disable-next-line no-inline-assembly
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
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

