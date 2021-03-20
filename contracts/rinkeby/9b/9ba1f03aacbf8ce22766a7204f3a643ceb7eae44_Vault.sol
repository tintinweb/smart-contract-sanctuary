/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IBondingCalculator {
  function calcDebtRatio( uint pendingDebtDue_, uint managedTokenTotalSupply_ ) external returns ( uint debtRatio_ );
  function calcBondPremium( uint debtRatio_, uint bondConstantValue_ ) external returns ( uint premium_ );
  function calcPrincipleValuation( uint k_, uint amountDeposited_, uint totalSupplyOfTokenDeposited_ ) external pure returns ( uint principleValuation_ );


    function principleValuation( address principleTokenAddress_, uint amountDeposited_ ) external returns ( uint principleValuation_ );
    function calculateBondInterest( address treasury_, address reserveToken_, address principleTokenAddress_, uint amountDeposited_, uint bondConstantValue_ ) external returns ( uint interestDue_ );
}

interface IPrincipleDepository {

  function getDepositorInfo( address depositorAddress_, address principleToken_, address debtToken_ ) external returns ( uint principleAmount_, uint interestDue_, uint bondMaturationBlock_, uint bondScalingFactor );

  function addReserveToken( address newReserveToken_, bool isERC1612_ ) external returns ( bool );

  function addPrincipleToken( address newPrincipleToken_, bool isERC1612_ ) external returns ( bool );
  
  function removePrincipleToken( address oldPrincipleToken_ ) external returns ( bool );

  function addBondTerm(address reserveToken_, address bondPrincipleToken_, uint256 bondSaclingFactor_, uint256 bondingPeriodInBlocks_ ) external returns ( bool );

  function removeBondTerm( address reserveToken_, address bondPrincipleToRemove_) external returns ( bool );

  function removeBondingCalculatorForPrincipleToken( address reserveToken_, address principleToken_ ) external  returns ( bool );

}

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
    }
}

interface ISaleEpochCalculator {
    function updateSaleConfigEpoch( address _userProvidedToken, address _platformProvidedToken) external returns ( bool );
}

interface IERC20Burnable {

  function burn(uint256 amount) external;

  function burnFrom( address account_, uint256 ammount_ ) external;
}

interface IERC2612Permit {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
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

interface ITWAPOracle {

  function uniV2CompPairAddressForLastEpochUpdateBlockTimstamp( address ) external returns ( uint32 );

  function priceTokenAddressForPricingTokenAddressForLastEpochUpdateBlockTimstamp( address tokenToPrice_, address tokenForPriceComparison_, uint epochPeriod_ ) external returns ( uint32 );

  function pricedTokenForPricingTokenForEpochPeriodForPrice( address, address, uint ) external returns ( uint );

  function pricedTokenForPricingTokenForEpochPeriodForLastEpochPrice( address, address, uint ) external returns ( uint );

  function updateTWAP( address uniV2CompatPairAddressToUpdate_, uint eopchPeriodToUpdate_ ) external returns ( bool );
}

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IERC20Mintable {

  function mint( uint256 amount_ ) external;

  function mint( address account_, uint256 ammount_ ) external;
}

contract Vault is ITreasury, Ownable {
  using SafeMath for uint;
  using SafeERC20 for IERC20;
  event EpochPeriodChanged( uint previousEpochPeriod, uint newEpochPeriod );
  event ReserveTokenAdded( address indexed newReserveCurrency );
  event ManagedTokenAdded( address indexed newManafedToken, address newRserveToken );
  event PrincipleTokenAdded( address indexed newPrincipleToken );

  struct ManagedPair {
    address reserveToken;
    address managedToken;
  }

  mapping( address => mapping( address => ManagedPair ) ) internal managedPairForUserProvidedTokenForPlatformProvidedToken;

  function getManagedPairForUserProvidedTokenForPlatformProvidedToken( address platformProvidedToken_, address userProvidedToken_ ) external override returns ( address reserveToken_, address managedToken_ ) {
     ManagedPair memory managedPairToView = managedPairForUserProvidedTokenForPlatformProvidedToken[platformProvidedToken_][userProvidedToken_];
     reserveToken_ = managedPairToView.reserveToken;
     managedToken_ = managedPairToView.managedToken;
  }

  /**
   * @dev Does not have a function to remove a reserve Token as this functionality is limited to migrating liquidity.
   */
  mapping( address => bool ) public override isReserveToken;

  mapping( address => bool ) public override isManagedToken;

  mapping( address => bool ) public override isPrincipleToken;

  mapping( address => bool ) public override isTellerContract;

  mapping( address => bool ) public override isPaymentContract;

  mapping( address => address ) public override getManagedTokenForReserveToken;

  mapping( address => mapping( address => address ) ) public override getPaymentAddressForReserveTokenForManagedToken;

  mapping( address => mapping( address => address ) ) public override getPrincipleDepositoryForPrincipleTokenForReserveToken;

  mapping( address => mapping( address => uint ) ) public override getDebtAmountDueForPrincipleTokenForReserveToken;

  mapping( address => mapping( address => uint ) ) public override getPrincipleTokenBalanceForPrincipleTokenForReserveToken;

  mapping( address => mapping( address => address ) ) public override getBondingCalculatorForPrincipleTokenForReserveToken;

  mapping( address => uint ) public override getIntrinsicValueOfReserveToken;

  modifier onlyManagedToken( address managedTokenChallenge_ ) {
    require( isManagedToken[managedTokenChallenge_] == true );
    _;
  }

  modifier onlyReserveToken( address reserveTokenChallenge_ ) {
    require( isReserveToken[reserveTokenChallenge_] == true, "Vault: reserveTokenChallenge_ is not a reserve Token." );
    _;
  }

  modifier onlyPrincipleToken( address PrincipleTokenChallenge_ ) {
    require( isPrincipleToken[PrincipleTokenChallenge_] == true, "Vault: PrincipleTokenChallenge_ is not a Principle token." );
    _;
  }

  modifier onlyTeller() {
    require( isTellerContract[msg.sender] == true, "Vault: msg.sender is not a teller." );
    _;
  }

  modifier onlyPayment() {
    require( isPaymentContract[msg.sender] == true, "Vault:: msg.sender is not a registered payment contract." );
    _;
  }

  // *** Functions that set for Principle Depository *** \\

  function setPrincipleDepository( address reserveToken_, address principleToken_, address principleDepository_ ) external override onlyOwner() returns ( bool ) {
    getPrincipleDepositoryForPrincipleTokenForReserveToken[reserveToken_][principleToken_] = principleDepository_;
    return true;
  }

  function setEpochPeriod( uint newEpochPeriod_ ) external onlyOwner() returns ( bool ) {
    emit EpochPeriodChanged( epochPeriod, newEpochPeriod_ );
    epochPeriod = newEpochPeriod_;
    return true;
  }

  function setManagedTokenForReserveToken( address newManagedToken_, address reserveToken_ ) external override onlyOwner() returns ( bool ) {
    emit ManagedTokenAdded( newManagedToken_, reserveToken_ );
    getManagedTokenForReserveToken[reserveToken_] = newManagedToken_;
    return true;
  }

  function addReserveToken( address newReserveToken_ ) external override onlyOwner() returns ( bool ) {
    emit ReserveTokenAdded( newReserveToken_);
    isReserveToken[newReserveToken_] = true;

    return true;
  }

  // TODO needs to check if the principle token contains a reserve token.
  function addPrincipleToken( address newPrincipleToken_ ) external override onlyOwner() returns ( bool ) {
    isPrincipleToken[newPrincipleToken_] = true;
    emit PrincipleTokenAdded( newPrincipleToken_ );
    return true;
  }

  function addTellerContract( address newTellerContract_ ) external override onlyOwner() returns ( bool ) {
    isTellerContract[newTellerContract_] = true;
    return true;
  }

  function addBondingDepositoryForPrincipleTokenForReserveToken( address newBondingDepository_, address PrincipleToken_, address reserveToken_ ) external override onlyOwner() onlyReserveToken( reserveToken_ ) onlyPrincipleToken( PrincipleToken_ ) returns ( bool ) {
    require( getPrincipleDepositoryForPrincipleTokenForReserveToken[reserveToken_][PrincipleToken_] == address(0) );
    getPrincipleDepositoryForPrincipleTokenForReserveToken[reserveToken_][PrincipleToken_] = newBondingDepository_;
    return true;
  }

  function setBondingCalculatorForPrincipleTokenForReserveToken( address resesrveToken_, address principleToken_, address newPrincipleTokenValueCalculator_ ) external override onlyOwner() returns ( bool ) {
    getBondingCalculatorForPrincipleTokenForReserveToken[resesrveToken_][principleToken_] = newPrincipleTokenValueCalculator_;
    return true;
  }

  function addPaymentContract( address managedToken_, address reserveToken_, address newPaymentContract_ ) external override onlyOwner() returns ( bool ) {
    isPaymentContract[newPaymentContract_] = true;
    getPaymentAddressForReserveTokenForManagedToken[managedToken_][reserveToken_] = newPaymentContract_;
    return true;
  }

  function ownerDepositReserveToken( address reserveToken_, uint amount_ ) external onlyOwner() onlyReserveToken( reserveToken_ ) returns ( bool ) {
    IERC20( reserveToken_ ).safeTransferFrom( msg.sender, address(this), amount_ ); 
    _updateIntrinsicValueFromReserveDeposit( reserveToken_, amount_);
    return true;
  } 
  
  function _updateIntrinsicValueFromReserveDeposit( address reserveToken_, uint amount_ ) internal {
    getIntrinsicValueOfReserveToken[reserveToken_] = getIntrinsicValueOfReserveToken[reserveToken_].add(amount_);
  }

  function _updateIntrinsicValueFromBonds( address principleTokenAddress_, address reserveTokenAddress_, uint amount_ ) internal {
    uint additionalIntrinsicValue_ = IBondingCalculator( getBondingCalculatorForPrincipleTokenForReserveToken[reserveTokenAddress_][principleTokenAddress_] ).principleValuation( principleTokenAddress_, amount_ );
  }

  function depositProfit( address reserveToken_, uint depoistAmount_ ) external override onlyOwner() onlyReserveToken( reserveToken_ ) returns ( bool ) {
    IERC20( reserveToken_ ).safeTransferFrom( msg.sender, address(this), depoistAmount_ );
    _updateIntrinsicValueFromReserveDeposit( reserveToken_, depoistAmount_ );
    return true;
  }

  function depositPrinciple( address principleTokenAddress_, address reserveTokenAddress_, uint depoistAmount_ ) external onlyOwner() onlyPrincipleToken( principleTokenAddress_ ) returns ( bool ) {
    IERC20( principleTokenAddress_ ).safeTransferFrom( msg.sender, address(this), depoistAmount_ );
    _updateIntrinsicValueFromBonds( principleTokenAddress_, reserveTokenAddress_, depoistAmount_ );
    return true;
  }

  function mintManagedToken( address reserveToken_, address managedToken_, uint amountToDeposit_ ) external override onlyOwner() onlyReserveToken( reserveToken_ ) onlyManagedToken( managedToken_ ) returns ( bool ) {
    IERC20( reserveToken_ ).safeTransferFrom( msg.sender, address( this ), amountToDeposit_ );
    IERC20Mintable( managedToken_ ).mint( msg.sender, amountToDeposit_ );
  }

  function payDebt( 
    address depositor_,
    address principleTokenBeingCollected_,
    address reserveToken_
  ) external override
    onlyReserveToken( reserveToken_ )
    onlyPrincipleToken( principleTokenBeingCollected_ )
    onlyTeller( )
    returns ( bool )
  {
    ( 
      uint principleAmount_, 
      uint interestDue_,
      uint bondMaturationBlock_,
      uint bondingScaleFactor_
    ) =
      IPrincipleDepository( getPrincipleDepositoryForPrincipleTokenForReserveToken[reserveToken_][principleTokenBeingCollected_] )
        .getDepositorInfo( depositor_, principleTokenBeingCollected_, reserveToken_ );

    require( block.timestamp >= bondMaturationBlock_, "Vault: Bond has not yet matured." );

    uint outstandingDebtAmount_ =  getDebtAmountDueForPrincipleTokenForReserveToken[reserveToken_][principleTokenBeingCollected_];

    require( outstandingDebtAmount_ >= interestDue_, "Vault: msg.sender is trying to collect more interest then there is outstanding debt." );

    getDebtAmountDueForPrincipleTokenForReserveToken[reserveToken_][principleTokenBeingCollected_] = outstandingDebtAmount_.sub( interestDue_ );

    IERC20(principleTokenBeingCollected_).safeTransferFrom(msg.sender, address(this), principleAmount_);

    uint currentBalanceOfReserveToken_ = IERC20(principleTokenBeingCollected_).balanceOf( address(this) );

    uint currentRegisteredBalanceOfReserveTokenPlusPrincipleAmount_ =  getPrincipleTokenBalanceForPrincipleTokenForReserveToken[reserveToken_][principleTokenBeingCollected_].add( principleAmount_ );
    
    require( currentBalanceOfReserveToken_ >= currentRegisteredBalanceOfReserveTokenPlusPrincipleAmount_, "Vault: Not enough debt tokens has been deposited." );

    getDebtAmountDueForPrincipleTokenForReserveToken[reserveToken_][principleTokenBeingCollected_] = currentRegisteredBalanceOfReserveTokenPlusPrincipleAmount_;

    IERC20Mintable( getManagedTokenForReserveToken[reserveToken_] ).mint( depositor_, interestDue_ );

    uint additionalIntrinsicValue_ = IBondingCalculator( getBondingCalculatorForPrincipleTokenForReserveToken[reserveToken_][principleTokenBeingCollected_] ).principleValuation( principleTokenBeingCollected_, principleAmount_ );
    
    getIntrinsicValueOfReserveToken[reserveToken_] = getIntrinsicValueOfReserveToken[reserveToken_].add( additionalIntrinsicValue_ );

    return true;
 }

  function incurDebt( address reserveToken_, address principleToken_, uint principieTokenAmountDeposited_ ) external override onlyPayment( ) onlyReserveToken( reserveToken_ ) onlyPrincipleToken( principleToken_ ) returns ( bool ) {
    getDebtAmountDueForPrincipleTokenForReserveToken[reserveToken_][principleToken_] = getDebtAmountDueForPrincipleTokenForReserveToken[reserveToken_][principleToken_].add(
        IBondingCalculator( getBondingCalculatorForPrincipleTokenForReserveToken[reserveToken_][principleToken_] )
          .principleValuation( principleToken_, principieTokenAmountDeposited_)
      );
    return true;
  }
  
  uint public override epochPeriod;
  uint32 public override epochTWAPTimestamp;
  uint32 public override previousEpochTWAPTimestamp;

  mapping( address => address ) public override getTWAPOracleForReserveToken;
  
  uint public override lastEpochIntrinsicValue;
  uint public override lastEpochManagedTokenTotalSupply;

  function setTWAPOracleForReserveToken( address newTWAPOracleForReserveToken_, address reserveToken_ ) external override onlyOwner() returns ( bool ) {
    getTWAPOracleForReserveToken[reserveToken_] = newTWAPOracleForReserveToken_;
    return true;
  }

  function _updateEpoch( address reserveToken_, address managedToken_ ) internal returns ( bool ) {
    if( epochPeriod >= _calculateElapsedTimeSinceLastUpdate( epochTWAPTimestamp, previousEpochTWAPTimestamp ) ) {
      previousEpochTWAPTimestamp = epochTWAPTimestamp;
      epochTWAPTimestamp = ITWAPOracle( getTWAPOracleForReserveToken[reserveToken_] )
        .priceTokenAddressForPricingTokenAddressForLastEpochUpdateBlockTimstamp( managedToken_, reserveToken_, epochPeriod );

      lastEpochIntrinsicValue = getIntrinsicValueOfReserveToken[reserveToken_];
      lastEpochManagedTokenTotalSupply = IERC20( managedToken_ ).totalSupply();

      uint amountToMint_ = _calculateProfits();
      IERC20Mintable( managedToken_ ).mint( getPaymentAddressForReserveTokenForManagedToken[managedToken_][reserveToken_], amountToMint_ );
      IStaking( getPaymentAddressForReserveTokenForManagedToken[managedToken_][reserveToken_] ).distributeOLYProfits();
    }
    return true;
  }

  function _calculateElapsedTimeSinceLastUpdate( uint32 epochTWAPTimestamp_, uint32 previousEpochTWAPTimestamp_ ) internal pure returns (uint32) {
    return epochTWAPTimestamp_ - previousEpochTWAPTimestamp_; // overflow is desired
  }

  function updateProfits( address reserveToken_, address managedToken_ ) external override onlyPayment() returns ( bool ) {
    _updateEpoch( reserveToken_, managedToken_ );
    return true;
  }

  function _calculateProfits() internal view returns ( uint ) {
    return lastEpochIntrinsicValue.sub( lastEpochManagedTokenTotalSupply );
  }

  mapping( address => mapping( address => address ) ) public override getSaleEpochCalculatorForUserProvidedTokenForPlatformProvidedToken;
  mapping( address => mapping( address => address ) ) public override getSaleContractForuserProvidedTokenForPlatformProvidedToken;

  function setSaleEpochCalculatorForuserProvidedTokenForPlatformProvidedToken( address userPorvidedToken_, address platformProvidedToken_, address newSaleEpochCalculator_ ) external onlyOwner() override returns ( bool ) {
    getSaleEpochCalculatorForUserProvidedTokenForPlatformProvidedToken[userPorvidedToken_][platformProvidedToken_] = newSaleEpochCalculator_;
    getSaleEpochCalculatorForUserProvidedTokenForPlatformProvidedToken[platformProvidedToken_][userPorvidedToken_] = newSaleEpochCalculator_;
    return true;
  }

  function setSaleContractForuserProvidedTokenForPlatformProvidedToken( address userProvidedToken_, address platformProvidedToken_, address newSaleContract_ ) external override onlyOwner() returns ( bool ) {
    getSaleContractForuserProvidedTokenForPlatformProvidedToken[userProvidedToken_][platformProvidedToken_] = newSaleContract_;
    getSaleContractForuserProvidedTokenForPlatformProvidedToken[platformProvidedToken_][userProvidedToken_] = newSaleContract_;
  }

  function setManagedPairForUserProvidedTokenForPlatformProvidedToken( address reserveToken_, address managedToken_ ) external override onlyOwner() returns ( bool ) {
    ManagedPair memory newManagedPair = ManagedPair(
      {
        reserveToken: reserveToken_,
        managedToken: managedToken_
      }
    );
    managedPairForUserProvidedTokenForPlatformProvidedToken[reserveToken_][managedToken_] = newManagedPair;
    managedPairForUserProvidedTokenForPlatformProvidedToken[managedToken_][reserveToken_] = newManagedPair;
  }

  function updateSaleEpoch( address userPorvidedToken_, address platformProvidedToken_ ) external override returns ( bool ) {
    if ( _isEpochPassed() ) {
      ISaleEpochCalculator( getSaleEpochCalculatorForUserProvidedTokenForPlatformProvidedToken[platformProvidedToken_][userPorvidedToken_] ).updateSaleConfigEpoch( userPorvidedToken_, platformProvidedToken_ );
    
      address saleContract_ = getSaleContractForuserProvidedTokenForPlatformProvidedToken[platformProvidedToken_][userPorvidedToken_];

      ManagedPair memory currentManagedPair_ = managedPairForUserProvidedTokenForPlatformProvidedToken[userPorvidedToken_][platformProvidedToken_];

      uint saleProceedsAmount_ = IERC20( currentManagedPair_.reserveToken ).balanceOf( saleContract_ );

      IERC20( currentManagedPair_.reserveToken ).safeTransferFrom( saleContract_, address(this), IERC20( userPorvidedToken_).balanceOf( saleContract_ ) );
      
      IERC20Burnable( currentManagedPair_.managedToken ).burnFrom( saleContract_, IERC20( currentManagedPair_.managedToken ).balanceOf( saleContract_ ) );

      _updateIntrinsicValueFromReserveDeposit( currentManagedPair_.reserveToken, saleProceedsAmount_ );
    }
  }

  function _isEpochPassed() internal returns ( bool ) {
    return epochPeriod >= _calculateElapsedTimeSinceLastUpdate( epochTWAPTimestamp, previousEpochTWAPTimestamp ) ? true : false;
  }

  function migrateReserveAndPrinciple( address tokenToMigrate_, address migrationExecutor_ ) external onlyOwner() returns ( bool saveGas_ ) {
    IERC20( tokenToMigrate_ ).safeTransfer( migrationExecutor_, IERC20( tokenToMigrate_ ).balanceOf( address( this ) ) );
  }

}