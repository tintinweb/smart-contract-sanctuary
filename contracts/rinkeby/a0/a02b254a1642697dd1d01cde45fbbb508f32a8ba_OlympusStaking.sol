/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// File: contracts\dependencies\SafeMath.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;


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

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    /*
     * Expects percentage to be trailed by 00,
    */
    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    /*
     * Expects percentage to be trailed by 00,
    */
    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    /**
     * Taken from Hypersonic https://github.com/M2629/HyperSonic/blob/main/Math.sol
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

  function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
      return mul( multiplier_, supply_ );
  }
}

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    // function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    //     require(address(this).balance >= value, "Address: insufficient balance for call");
    //     return _functionCallWithValue(target, data, value, errorMessage);
    // }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}

interface IOwnable {

  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}

contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view override returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}

interface ITreasury {
  function getManagedPairForUserProvidedTokenForPlatformProvidedToken( address platformProvidedToken_, address userProvidedToken_ ) external returns ( address reserveToken_, address managedToken_ );

  function isManagedToken( address ) external returns ( bool );

  function setPrincipleDepository( address reserveToken_, address principleToken_, address principleDepository_ ) external returns ( bool );

    function isReserveToken(address reserveToken_) external view returns (bool);

    function isPrincipleToken(address principleToken_) external view returns (bool);

    function isTellerContract(address tellerContract_) external view returns (bool);

    function isPaymentContract(address paymentContract_) external view returns (bool);

    function getManagedTokenForReserveToken(address reserveToken_) external view returns (address);

    function getPaymentAddressForReserveTokenForManagedToken( address managedTOken_, address reserveToken_ ) external view returns (address);

    function getPrincipleDepositoryForPrincipleTokenForReserveToken(address reserveToken_, address principleToken_) external view returns (address);
    
    function getDebtAmountDueForPrincipleTokenForReserveToken(address reserveToken_, address principleToken_) external view returns (uint);

    function getPrincipleTokenBalanceForPrincipleTokenForReserveToken(address reserveToken_, address principleToken_) external view returns (uint);

    function getBondingCalculatorForPrincipleTokenForReserveToken(address reserveToken_, address principleToken_) external view returns (address);

    function getIntrinsicValueOfReserveToken(address reserveToken_) external view returns (uint);

    function setManagedTokenForReserveToken( address newManagedToken_, address reserveToken_ ) external returns ( bool );

    function addReserveToken( address newReserveToken_ ) external returns ( bool );

    function addPrincipleToken( address newLPToken_ ) external returns ( bool );

    function addTellerContract( address newTellerContract_ ) external returns ( bool );

    function addBondingDepositoryForPrincipleTokenForReserveToken( address newBondingDepository_, address PrincipleToken_, address reserveToken_ ) external returns ( bool );

    function setBondingCalculatorForPrincipleTokenForReserveToken( address resesrveToken_, address principleToken_, address newPrincipleTokenValueCalculator_ ) external returns ( bool );

  function addPaymentContract( address managedToken_, address reserveToken_, address newPaymentContract_ ) external returns ( bool );

    function payDebt( address depositor_, address principleTokenBeingCollected_, address reserveToken_ ) external returns ( bool );

    function incurDebt( address reserveToken_, address principleToken_, uint principieTokenAmountDeposited_ ) external returns ( bool );

  function epochPeriod() external view returns (uint256);
  function epochTWAPTimestamp() external view returns (uint32);
  function previousEpochTWAPTimestamp() external view returns (uint32);

  function getTWAPOracleForReserveToken( address ) external returns ( address );
  
  function lastEpochIntrinsicValue() external returns ( uint );
  function lastEpochManagedTokenTotalSupply() external returns ( uint );

  function setTWAPOracleForReserveToken( address newTWAPOracleForReserveToken_, address reserveToken_ ) external returns ( bool );

  function updateProfits( address reserveToken_, address managedToken_ ) external returns ( bool );

  function updateSaleEpoch( address userPorvidedToken_, address platformProvidedToken_ ) external returns ( bool );

  function setSaleEpochCalculatorForuserProvidedTokenForPlatformProvidedToken( address userPorvidedToken_, address platformProvidedToken_, address newSaleEpochCalculator_ ) external returns ( bool );

  function setSaleContractForuserProvidedTokenForPlatformProvidedToken( address userProvidedToken_, address platformProvidedToken_, address newSaleContract_ ) external returns ( bool ); 

  function setManagedPairForUserProvidedTokenForPlatformProvidedToken( address reserveToken_, address managedToken_ ) external returns ( bool );

  function getSaleEpochCalculatorForUserProvidedTokenForPlatformProvidedToken(address reserveToken_, address managedToken_ ) external view returns ( address );

  function getSaleContractForuserProvidedTokenForPlatformProvidedToken( address reserveToken_, address managedToken_ ) external returns ( address );

  function mintManagedToken( address reserveToken_, address managedToken_, uint amountToDeposit_ ) external returns ( bool );

  function depositProfit( address reserveToken_, uint depoistAmount_ ) external returns ( bool );
}

interface IStaking {

    function initialize(
        address olyTokenAddress_,
        address sOLY_,
        address dai_,
        address olympusTreasuryAddress_
    ) external;

    //function stakeOLY(uint amountToStake_) external {
    function stakeOLYWithPermit (
        uint256 amountToStake_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external;

    //function unstakeOLY( uint amountToWithdraw_) external {
    function unstakeOLYWithPermit (
        uint256 amountToWithdraw_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external;

    function stakeOLY( uint amountToStake_ ) external returns ( bool );

    function unstakeOLY( uint amountToWithdraw_ ) external returns ( bool );

    function distributeOLYProfits() external;
}

contract VaultOwned is Ownable {
    
  address internal _vault;

  function setVault( address vault_ ) external onlyOwner() returns ( bool ) {
    _vault = vault_;

    return true;
  }

  /**
   * @dev Returns the address of the current vault.
   */
  function vault() public view returns (address) {
    return _vault;
  }

  /**
   * @dev Throws if called by any account other than the vault.
   */
  modifier onlyVault() {
    require( _vault == msg.sender, "VaultOwned: caller is not the Vault" );
    _;
  }

}

interface IsOLYandOLY {
    function rebase(uint256 olyProfit)
        external
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract OlympusStaking is IStaking, VaultOwned {
    using SafeMath for uint256;
    using Address for address;

    bool isInitialized;

    address public oly;
    address public sOLY;
    address public dai;
    address public olympusTreasuryAddress;

    uint256 public olyToDistributeNextEpoch;

    modifier notInitialized() {
        require(!isInitialized);
        _;
    }

    function initialize(
        address olyTokenAddress_,
        address sOLY_,
        address dai_,
        address olympusTreasuryAddress_
    ) external override onlyOwner() notInitialized() {
        oly = olyTokenAddress_;
        sOLY = sOLY_;
        dai = dai_;
        olympusTreasuryAddress = olympusTreasuryAddress_;

        isInitialized = true;
    }

    function stakeOLYWithPermit (
        uint256 amountToStake_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external override {

        IsOLYandOLY(oly).permit(
            msg.sender,
            address(this),
            amountToStake_,
            deadline_,
            v_,
            r_,
            s_
        );
        
        updateProfits();

        _stakeOLY( amountToStake_ );

    }

    function unstakeOLYWithPermit (
        uint256 amountToWithdraw_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external override {
        
        IsOLYandOLY(sOLY).permit(
            msg.sender,
            address(this),
            amountToWithdraw_,
            deadline_,
            v_,
            r_,
            s_
        );

        ITreasury(olympusTreasuryAddress).updateProfits( dai, oly );

        _unstakeOLY( amountToWithdraw_ );

    }

    function stakeOLY( uint amountToStake_ ) external override returns ( bool ) {

        _stakeOLY( amountToStake_ );

        return true;

    }

    function unstakeOLY( uint amountToWithdraw_ ) external override returns ( bool ) {

        _unstakeOLY( amountToWithdraw_ );

        return true;

    }

    function _stakeOLY( uint256 amountToStake_ ) internal {
        
        require(
            IsOLYandOLY(oly).transferFrom(
                msg.sender,
                address(this),
                amountToStake_
            )
        );

        require( IsOLYandOLY(sOLY).transfer(msg.sender, amountToStake_));

    }

    function _unstakeOLY( uint256 amountToUnstake_ ) internal {

        require(IsOLYandOLY(sOLY).transferFrom(
            msg.sender,
            address(this),
            amountToUnstake_
        ), "Not enough stake");

        require(
            IsOLYandOLY(oly).transfer(msg.sender, amountToUnstake_),
            "Claim Failed"
        );

    }

    function distributeOLYProfits() external override onlyVault() {

        IsOLYandOLY(sOLY).rebase(olyToDistributeNextEpoch);

        uint256 _olyBalance = IsOLYandOLY(oly).balanceOf(address(this));
        uint256 _solySupply = IsOLYandOLY(sOLY).circulatingSupply();

        olyToDistributeNextEpoch = _olyBalance.sub(_solySupply);
    }

    function updateProfits() public returns ( bool ) {
        ITreasury( olympusTreasuryAddress ).updateProfits( dai, oly );
        return true;
    }


}