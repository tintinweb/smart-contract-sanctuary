// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.5;

import './IBEP20.sol';
import './IERC20.sol';
import '../Libraries/SafeBEP20.sol';
import '../Libraries/SafeMath.sol';
import '../Modifiers/ReentrancyGuard.sol';
import '../Modifiers/Ownable.sol';
import "../BondDepositoryGlb.sol";
import "../BondDepositoryGlbBusdLP.sol";
import "../BondDepositoryGlbBnbLP.sol";

/**
 * @dev BojiSwap: Initial Panther Offering
 */
contract IPO is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 depositedInvestmentTokens;   // How many tokens the user has provided.
        uint256 refundedInvestmentTokens;   // How many tokens the user has been refunded.

        uint256 claimableProjectTokens;

        uint256 depositedWGLBD;
        uint256 remainingWGLBD;
        bool migrateGLB;  // default false
        bool depositWGLBD;  // default false
        bool whitelisted;  // default false
    }

    // The raising token
    address public wGLBD;
    // The raising token
    address public investmentToken;
    // The offering token
    address public projectToken;
    // The block number when IPO starts
    uint256 public startPresale;
    // The block number when IPO ends
    uint256 public endPresale;
    // The block number when IPO ends
    uint256 public startClaim;
    // total amount of wGLBD needed to be deposited
    uint256 public requiredGLB;
    // total amount of wGLBD needed to be deposited
    uint256 public requiredWGLBD;
    // max amount of investment tokens that can invest any user
    uint256 public maxInvestment;
    // total amount of investment tokens need to be raised
    uint256 public raisingAmount;
    // total amount of investment tokens that have already raised
    uint256 public totalAmountInvested;
    // address => amount
    mapping (address => UserInfo) public userInfo;
    // participators
    address[] public addressList;
    address[] public bondGLBList;
    address[] public bondGLBBUSDList;
    address[] public bondGLBBNBList;
    mapping (address => bool) private whitelist;
    mapping (address => bool) private blacklist;

      event Invest(address indexed user, uint256 amount);
      event Claim(address indexed user, uint256 amount);

  constructor(
      address _wGLBD,
      address _investmentToken,
      address _projectToken,
      uint256 _startPresale,
      uint256 _endPresale,
      uint256 _startClaim,
      uint256 _requiredWGLBD,
      uint256 _requiredGLB,
      uint256 _maxInvestment,
      uint256 _raisingAmount
  ) {
      wGLBD = _wGLBD;
      investmentToken = _investmentToken;
      projectToken = _projectToken;
      startPresale = _startPresale;
      endPresale = _endPresale;
      startClaim = _startClaim;
      requiredWGLBD = _requiredWGLBD;
      requiredGLB = _requiredGLB;
      maxInvestment = _maxInvestment;
      raisingAmount= _raisingAmount;
      totalAmountInvested = 0;
  }

    function isWhitelist(address _address) public view returns(bool) {
        return whitelist[_address];
    }

    function setWhitelist(address _address, bool _on) external onlyOwner {
        whitelist[_address] = _on;
    }

    function isBlacklist(address _address) public view returns(bool) {
        return blacklist[_address];
    }

    function setBlacklist(address _address, bool _on) external onlyOwner {
        blacklist[_address] = _on;
    }

    function setStartPresale(uint256 _startPresale) public onlyOwner {
        startPresale = _startPresale;
    }

    function setEndPresale(uint256 _endPresale) public onlyOwner {
        endPresale = _endPresale;
    }

    function setStartClaim(uint256 _startClaim) public onlyOwner {
        startClaim = _startClaim;
    }

    function setRequiredWGLBD(uint256 _requiredWGLBD) public onlyOwner {
        requiredWGLBD = _requiredWGLBD;
    }

    function setRequiredGLB(uint256 _requiredGLB) public onlyOwner {
        requiredGLB = _requiredGLB;
    }

    function setMaxInvestment(uint256 _maxInvestment) public onlyOwner {
        maxInvestment = _maxInvestment;
    }

    function setRaisingAmount(uint256 _raisingAmount) public onlyOwner {
        raisingAmount = _raisingAmount;
    }

    function addBond(uint _typeBond, address _bond) public onlyOwner {
        if(_typeBond==1)
        {
            bondGLBList.push(_bond);
        }
        else if(_typeBond==2)
        {
            bondGLBBUSDList.push(_bond);
        }
        else if(_typeBond==3)
        {
            bondGLBBNBList.push(_bond);
        }
    }

    function deleteBond(uint _typeBond, address _bond) public onlyOwner {
        if(_typeBond==1)
        {
            for (uint8 i = 0; i < bondGLBList.length; i++) {
                if (bondGLBList[i] == _bond) {
                    for (uint j = i; j<bondGLBList.length-1; j++)
                    {
                        bondGLBList[j] = bondGLBList[j+1];
                    }
                    bondGLBList.pop();
                }
            }
        }
        else if(_typeBond==2)
        {
            for (uint8 i = 0; i < bondGLBBUSDList.length; i++) {
                if (bondGLBBUSDList[i] == _bond) {
                    for (uint j = i; j<bondGLBBUSDList.length-1; j++)
                    {
                        bondGLBBUSDList[j] = bondGLBBUSDList[j+1];
                    }
                    bondGLBBUSDList.pop();
                }
            }
        }
        else if(_typeBond==3)
        {
            for (uint8 i = 0; i < bondGLBBNBList.length; i++) {
                if (bondGLBBNBList[i] == _bond) {
                    for (uint j = i; j<bondGLBBNBList.length-1; j++)
                    {
                        bondGLBBNBList[j] = bondGLBBNBList[j+1];
                    }
                    bondGLBBNBList.pop();
                }
            }
        }
    }

    function canInvest(address _user) public view returns (bool)
    {
        if(isWhitelist(_user))
        {
            return true;
        }
        else
        {
            uint amountMigrating = 0;
            uint newAmount = 0;
            for (uint8 i = 0; i < bondGLBList.length; i++) {
                (newAmount,,,,,,) = BondDepositoryGlb(bondGLBList[i]).bondInfo(_user);
                amountMigrating = amountMigrating.add(newAmount);
            }
            for (uint8 i = 0; i < bondGLBBUSDList.length; i++) {
                (newAmount,,,,,,,) = BondDepositoryGlbBusdLP(bondGLBBUSDList[i]).bondInfo(_user);
                amountMigrating = amountMigrating.add(newAmount.mul(2));
            }
            for (uint8 i = 0; i < bondGLBBNBList.length; i++) {
                (newAmount,,,,,,,) = BondDepositoryGlbBnbLP(bondGLBBNBList[i]).bondInfo(_user);
                amountMigrating = amountMigrating.add(newAmount.mul(2));
            }

            return amountMigrating>=requiredGLB;
        }
    }

    function invest(uint256 _amount) public
    {
        require (block.number > startPresale && block.timestamp < endPresale, 'not presale time');
        require (canInvest(msg.sender) || IERC20(wGLBD).balanceOf(msg.sender)>=requiredWGLBD, 'you cannot invest'); //
        require (_amount > 0, 'need _amount > 0');
        require (userInfo[msg.sender].depositedInvestmentTokens.add(_amount) > maxInvestment, 'you cannot invest more');

        if(!canInvest(msg.sender))
        {
            IERC20(wGLBD).safeTransferFrom(address(msg.sender), address(this), requiredWGLBD);
            userInfo[msg.sender].depositedWGLBD = requiredWGLBD;
            userInfo[msg.sender].remainingWGLBD = requiredWGLBD;
        }

        IBEP20(investmentToken).safeTransferFrom(address(msg.sender), address(this), _amount);
        if (userInfo[msg.sender].depositedInvestmentTokens == 0) {
          addressList.push(address(msg.sender));
        }
        userInfo[msg.sender].depositedInvestmentTokens = userInfo[msg.sender].depositedInvestmentTokens.add(_amount);
        totalAmountInvested = totalAmountInvested.add(_amount);

        emit Invest(msg.sender, _amount);
    }

    // get the amount of investment tokens you will be refunded
    function getExcessInvestmentTokens(address _user) public view returns(uint256) {
        if (totalAmountInvested <= raisingAmount) {
            return 0;
        }
        uint256 allocation = getUserAllocation(_user);
        uint256 payAmount = raisingAmount.mul(allocation).div(1e6);
        return userInfo[_user].depositedInvestmentTokens.sub(payAmount).sub(userInfo[_user].refundedInvestmentTokens);
    }

    function refundExcessInvestmentTokens(address _user) public nonReentrant {
        uint256 refundingTokenAmount = getExcessInvestmentTokens(_user);
        if (refundingTokenAmount > 0) {
            IBEP20(investmentToken).safeTransfer(_user, refundingTokenAmount);
            userInfo[_user].refundedInvestmentTokens = userInfo[_user].refundedInvestmentTokens.add(refundingTokenAmount);
        }
    }

    function recoverWGLBD(address _depositor) external returns ( uint ) {
        uint transferAmount = availableToRecoverWGLBD(_depositor);

        IERC20(wGLBD).safeTransferFrom(address(this),_depositor, transferAmount);

        userInfo[_depositor].remainingWGLBD = userInfo[_depositor].remainingWGLBD.sub(transferAmount);

        return transferAmount;
    }

    function availableToInvest(address _depositor) public view returns ( uint ) {
        return maxInvestment.sub(userInfo[ _depositor ].depositedInvestmentTokens);
    }

    function availableToRecoverWGLBD(address _depositor) public view returns ( uint ) {
        UserInfo memory user = userInfo[ _depositor ];

        uint harvestingAmount = 0;
        if(endPresale>block.timestamp)
        {
            harvestingAmount = user.remainingWGLBD;
        }
        else if(startClaim>block.timestamp)
        {
            harvestingAmount = user.depositedWGLBD.mul(startClaim.sub(block.timestamp)).div(startClaim.sub(endPresale));
        }

        return user.remainingWGLBD.sub(harvestingAmount);
    }

  // allocation 100000 means 0.1(10%), 1 meanss 0.000001(0.0001%), 1000000 means 1(100%)
  function getUserAllocation(address _user) public view returns(uint256) {
    return userInfo[_user].depositedInvestmentTokens.mul(1e12).div(totalAmountInvested).div(1e6);
  }

  // get the amount of IPO token you will get
  function getOfferingAmount(address _user, uint _amount) public view returns(uint256) {
      uint256 allocation = getUserAllocation(_user);
      return _amount.mul(allocation).div(1e6);
  }

    function distributeProjectTokens(uint _amount, uint256 start, uint256 end) public onlyOwner {

        for (uint256 i = start; i < end; i++)
        {
            userInfo[addressList[i]].claimableProjectTokens = getOfferingAmount(addressList[i],_amount);
        }
    }

    function distributeProjectTokens(uint _amount) public onlyOwner {
        distributeProjectTokens(_amount,0,addressList.length);
    }

    function claimProjectTokens(address _user) public nonReentrant {
        uint256 claimAmount = userInfo[_user].claimableProjectTokens;

        if (claimAmount > 0) {
            IBEP20(projectToken).safeTransfer(_user, claimAmount);
            userInfo[_user].claimableProjectTokens = 0;
            emit Claim(msg.sender, claimAmount);
        }
    }

  function getAddressListLength() external view returns(uint256) {
    return addressList.length;
  }

    function withdrawInvestmentToken(uint256 _amount) public onlyOwner {
        uint256 amountBlocked = totalAmountInvested > raisingAmount ? totalAmountInvested - raisingAmount : 0;
        require (_amount <= IBEP20(investmentToken).balanceOf(address(this)).sub(amountBlocked), 'not enough investment tokens');
        IBEP20(investmentToken).safeTransfer(address(msg.sender), _amount);
    }

    function withdrawInvestmentToken() public onlyOwner {
        uint256 amountBlocked = totalAmountInvested > raisingAmount ? totalAmountInvested - raisingAmount : 0;
        IBEP20(investmentToken).safeTransfer(address(msg.sender), IBEP20(investmentToken).balanceOf(address(this)).sub(amountBlocked));
    }

    function withdrawProjectToken(uint256 _amount) public onlyOwner {
        require (_amount <= IBEP20(projectToken).balanceOf(address(this)), 'not enough project token');
        IBEP20(projectToken).safeTransfer(address(msg.sender), _amount);
    }

    function withdrawProjectToken() public onlyOwner {
        IBEP20(projectToken).safeTransfer(address(msg.sender), IBEP20(projectToken).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.5;

interface IBEP20 {

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity 0.7.5;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Returns the decimals of token.
     */
    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.5;

import './SafeMath.sol';
import './Address.sol';
import '../Tokens/IBEP20.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

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
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.5;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./IOwnable.sol";

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyOwner() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import './Modifiers/IOwnable.sol';
import './Modifiers/Ownable.sol';
import './Libraries/SafeMath.sol';
import './Libraries/SafeERC20.sol';
import './Libraries/Address.sol';
import './Tokens/IERC20.sol';
import './Tokens/IBEP20.sol';
import './IStaking.sol';
import './StakingHelper.sol';

contract BondDepositoryGlb is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public glbd;
    address public glb;
    address public stakingHelper;

    uint public bondHarvestTime;
    uint public bondRatio;
    uint public bondMaxDeposit;
    uint public totalDebt;

    mapping( address => Bond ) public bondInfo; // stores bond information for depositors

    // Info for bond holder
    struct Bond {
        uint deposited; // GLBs deposited
        uint payout; // Total GLBD to be paid
        uint payoutRemaining; // GLBD remaining to be paid
        uint depositTime; // Timestamp on deposit
        uint harvestTime; // HarvestTime on deposit
        uint ratio; // For front end viewing
        uint maxDeposit; // For front end viewing
    }

    event BondCreated(address indexed _depositor, uint deposited, uint totalDeposited, uint payout, uint totalPayout, uint harvestTime, uint ratioLP);
    event BondRedeemed( address indexed _depositor, uint amountTransfered, uint remaining, uint payout );

    constructor(
        address _glbd,
        address _glb,
        address _stakingHelper,
        uint _bondHarvestTime,
        uint _bondRatio,
        uint _bondMaxDeposit
    ) {
        glbd = _glbd;
        glb = _glb;
        stakingHelper = _stakingHelper;
        bondHarvestTime = _bondHarvestTime;
        bondRatio = _bondRatio;
        bondMaxDeposit = _bondMaxDeposit;
        totalDebt = 0;

        IERC20( glbd ).approve(_stakingHelper, uint(0));
        IERC20( glbd ).approve(_stakingHelper, uint(~0));
    }

    function setBondHarvestTime( uint _bondHarvestTime ) external onlyOwner {
        bondHarvestTime = _bondHarvestTime;
    }

    function setBondRatio( uint _bondRatio ) external onlyOwner {
        require( _bondRatio > 0, "Invalid parameter" );
        bondRatio = _bondRatio;
    }

    function setBondMaxDeposit( uint _bondMaxDeposit ) external onlyOwner {
        bondMaxDeposit = _bondMaxDeposit;
    }

    function deposit(
        uint _amount,
        address _depositor
    ) external returns ( uint ) {
        require(  bondInfo[ _depositor ].deposited < bondMaxDeposit, "You cannot deposit more tokens" );
        require( _depositor != address(0), "Invalid address" );

        uint amount = bondMaxDeposit.sub(bondInfo[ _depositor ].deposited)>_amount ? _amount : bondMaxDeposit.sub(bondInfo[ _depositor ].deposited);

        IBEP20(glb).transferFrom( msg.sender, address(this), amount );

        uint actualPayout = amount.div(bondRatio);
        actualPayout = actualPayout.mul( 10 ** IERC20( glbd ).decimals() ).div( 10 ** IBEP20( glb ).decimals());

        require( actualPayout <= excessReserves(), "Not enough GLBDs available" );

        bondInfo[ _depositor ] = Bond({
            deposited: bondInfo[ _depositor ].deposited.add(amount),
            payout: bondInfo[ _depositor ].payoutRemaining.add( actualPayout ),
            payoutRemaining: bondInfo[ _depositor ].payoutRemaining.add( actualPayout ),
            depositTime: block.timestamp,
            harvestTime: bondHarvestTime,
            maxDeposit: bondMaxDeposit,
            ratio: bondRatio
        });

        // total debt is increased
        totalDebt = totalDebt.add( actualPayout );

        // indexed events are emitted
        emit BondCreated( _depositor, amount, bondInfo[ _depositor ].deposited , actualPayout,  bondInfo[ _depositor ].payout, bondHarvestTime, bondRatio );

        return actualPayout;
    }

    function redeem(
        address _depositor
    ) external returns ( uint ) {
        uint transferAmount = availableToRedeem(_depositor);
        require(transferAmount>0,"[There's no more GLBD to be claimed]");

        StakingHelper(stakingHelper).stake(transferAmount, _depositor);

        uint newPayoutRemaining = bondInfo[ _depositor ].payoutRemaining.sub(transferAmount);
        if(newPayoutRemaining==0)
        {
            delete bondInfo[ _depositor ];
        }
        else
        {
            bondInfo[ _depositor ].payoutRemaining = newPayoutRemaining;
        }

        // total debt is decreased
        totalDebt = totalDebt.sub( transferAmount );

        // indexed events are emitted
        emit BondRedeemed( _depositor, transferAmount, bondInfo[ _depositor ].payoutRemaining, bondInfo[ _depositor ].payout);

        return transferAmount;
    }

    function recoverRewardTokens(uint _amount) external onlyOwner {
        require(IERC20(glbd).balanceOf(address(this)).sub(totalDebt)>=_amount, "Not enough GLBDs available");
        IERC20(glbd).transfer(address(msg.sender), _amount);
    }

    function recoverRewardTokens() external onlyOwner {
        IERC20(glbd).transfer(address(msg.sender), IERC20(glbd).balanceOf(address(this)).sub(totalDebt));
    }

    function recoverReserveToken(uint _amount) external onlyOwner {
        IBEP20(glb).transfer(address(msg.sender), _amount);
    }

    function recoverReserveToken() external onlyOwner {
        IBEP20 token = IBEP20(glb);
        token.transfer(address(msg.sender), token.balanceOf(address(this)));
    }

    function recoverWrontToken(address _token) external onlyOwner {
        IBEP20 token = IBEP20(_token);
        token.transfer(address(msg.sender), token.balanceOf(address(this)));
    }

    function excessReserves() public view returns ( uint ) {
        return IERC20(glbd).balanceOf(address(this)).sub( totalDebt );
    }

    function availableToDeposit(address _depositor) public view returns ( uint ) {
        return bondMaxDeposit.sub(bondInfo[ _depositor ].deposited);
    }

    function availableToRedeem(address _depositor) public view returns ( uint ) {
        Bond memory depositoryBond = bondInfo[ _depositor ];

        uint harvestingAmount = 0;
        if(depositoryBond.depositTime.add(depositoryBond.harvestTime)>block.timestamp && depositoryBond.harvestTime>0)
        {
            harvestingAmount = depositoryBond.payout.mul(depositoryBond.depositTime.add(depositoryBond.harvestTime).sub(block.timestamp)).div(depositoryBond.harvestTime);
        }

        return depositoryBond.payoutRemaining.sub(harvestingAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;


import './Modifiers/IOwnable.sol';
import './Modifiers/Ownable.sol';
import './Libraries/SafeERC20.sol';
import './Libraries/SafeMath.sol';
import './Libraries/Address.sol';
import './Tokens/IERC20.sol';
import './Tokens/IPancakeERC20.sol';
import './Tokens/IBEP20.sol';
import './Tokens/IPair.sol';
import './Helpers/IRouterV1.sol';
import './IStaking.sol';
import './StakingHelper.sol';

// Contract for partners of BeGlobal only.
contract BondDepositoryGlbBusdLP is Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public glbd;
    address public busd;
    address public pair;
    address public router;
    address public stakingHelper;

    uint public bondHarvestTime;
    uint public bondRatioLP;
    uint public bondMaxDeposit;
    uint public totalDebt;

    // Info for bond holder
    struct Bond {
        uint deposited; // LPs deposited
        uint depositedGLB; // GLBs deposited
        uint payout; // Total GLBD to be paid
        uint payoutRemaining; // GLBD remaining to be paid
        uint depositTime; // Timestamp on deposit
        uint harvestTime; // HarvestTime on deposit
        uint ratioLP; // For front end viewing
        uint maxDeposit; // For front end viewing
    }

    mapping( address => Bond ) public bondInfo; // stores bond information for depositors

    event BondCreated(address indexed _depositor, uint deposited, uint totalDeposited, uint payout, uint totalPayout, uint harvestTime, uint ratioLP);
    event BondRedeemed( address indexed _depositor, uint amountTransfered, uint remaining, uint payout );

    constructor(
        address _glbd,
        address _busd,
        address _pair,
        address _router,
        address _stakingHelper,
        uint _bondHarvestTime,
        uint _bondRatioLP,
        uint _bondMaxDeposit
    ) {
        glbd = _glbd;
        busd = _busd;
        pair = _pair;
        router = _router;
        stakingHelper = _stakingHelper;
        bondHarvestTime = _bondHarvestTime;
        bondRatioLP = _bondRatioLP;
        bondMaxDeposit = _bondMaxDeposit;
        totalDebt = 0;

        IPair( pair ).approve(_router, uint(0));
        IPair( pair ).approve(_router, uint(~0));

        IERC20( glbd ).approve(_stakingHelper, uint(0));
        IERC20( glbd ).approve(_stakingHelper, uint(~0));
    }

    function setBondHarvestTime( uint _bondHarvestTime ) external onlyOwner {
        bondHarvestTime = _bondHarvestTime;
    }

    function setBondRatioLP( uint _bondRatioLP ) external onlyOwner {
        require( _bondRatioLP > 0, "Invalid parameter" );
        bondRatioLP = _bondRatioLP;
    }

    function setBondMaxDeposit( uint _bondMaxDeposit ) external onlyOwner {
        bondMaxDeposit = _bondMaxDeposit;
    }

    function deposit(
        uint _amount,
        address _depositor
    ) external returns ( uint ) {
        require(  bondInfo[ _depositor ].deposited < bondMaxDeposit, "You cannot deposit more tokens" );
        require( _depositor != address(0), "Invalid address" );

        uint amount = bondMaxDeposit.sub(bondInfo[ _depositor ].deposited)>_amount ? _amount : bondMaxDeposit.sub(bondInfo[ _depositor ].deposited);

        IPair(pair).transferFrom( msg.sender, address(this), amount );

        ( uint reserve0, uint reserve1) = IRouterV1(router).removeLiquidity(
            IPair(pair).token0(),
            IPair(pair).token1(),
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );

        uint reserve;

        if ( IPair(pair).token0() == busd ) {
            reserve = reserve1;
        } else {
            reserve = reserve0;
        }

        uint actualPayout = reserve.div(bondRatioLP);
        actualPayout = actualPayout.mul( 10 ** IERC20( glbd ).decimals() ).div( 10 ** IERC20( pair ).decimals());

        require( actualPayout <= excessReserves(), "Not enough GLBDs available" );

        bondInfo[ _depositor ] = Bond({
            deposited: bondInfo[ _depositor ].deposited.add(amount),
            depositedGLB: bondInfo[ _depositor ].depositedGLB.add(reserve),
            payout: bondInfo[ _depositor ].payoutRemaining.add( actualPayout ),
            payoutRemaining: bondInfo[ _depositor ].payoutRemaining.add( actualPayout ),
            depositTime: block.timestamp,
            harvestTime: bondHarvestTime,
            maxDeposit: bondMaxDeposit,
            ratioLP: bondRatioLP
        });

        // total debt is increased
        totalDebt = totalDebt.add( actualPayout );

        // indexed events are emitted
        emit BondCreated( _depositor, amount, bondInfo[ _depositor ].deposited , actualPayout,  bondInfo[ _depositor ].payout, bondHarvestTime, bondRatioLP );

        return actualPayout;
    }

    function redeem(
        address _depositor
    ) external returns ( uint ) {
        uint transferAmount = availableToRedeem(_depositor);
        require(transferAmount>0,"[There's no more GLBD to be claimed]");

        StakingHelper(stakingHelper).stake(transferAmount, _depositor);

        uint newPayoutRemaining = bondInfo[ _depositor ].payoutRemaining.sub(transferAmount);
        if(newPayoutRemaining==0)
        {
            delete bondInfo[ _depositor ];
        }
        else
        {
            bondInfo[ _depositor ].payoutRemaining = newPayoutRemaining;
        }

        // total debt is decreased
        totalDebt = totalDebt.sub( transferAmount );

        // indexed events are emitted
        emit BondRedeemed( _depositor, transferAmount, bondInfo[ _depositor ].payoutRemaining, bondInfo[ _depositor ].payout);

        return transferAmount;
    }

    function recoverRewardTokens(uint _amount) external onlyOwner {
        require(IERC20(glbd).balanceOf(address(this)).sub(totalDebt)>=_amount, "Not enough GLBDs available");
        IERC20(glbd).transfer(address(msg.sender), _amount);
    }

    function recoverRewardTokens() external onlyOwner {
        IERC20(glbd).transfer(address(msg.sender), IERC20(glbd).balanceOf(address(this)).sub(totalDebt));
    }

    function recoverLiquidityToken(address _token, uint _amount) external onlyOwner {
        IERC20(_token).transfer(address(msg.sender), _amount);
    }

    function recoverLiquidityToken(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(address(msg.sender), token.balanceOf(address(this)));
    }

    function excessReserves() public view returns ( uint ) {
        return IERC20(glbd).balanceOf(address(this)).sub( totalDebt );
    }

    function availableToDeposit(address _depositor) public view returns ( uint ) {
        return bondMaxDeposit.sub(bondInfo[ _depositor ].deposited);
    }

    function availableToRedeem(address _depositor) public view returns ( uint ) {
        Bond memory depositoryBond = bondInfo[ _depositor ];

        uint harvestingAmount = 0;
        if(depositoryBond.depositTime.add(depositoryBond.harvestTime)>block.timestamp && depositoryBond.harvestTime>0)
        {
            harvestingAmount = depositoryBond.payout.mul(depositoryBond.depositTime.add(depositoryBond.harvestTime).sub(block.timestamp)).div(depositoryBond.harvestTime);
        }

        return depositoryBond.payoutRemaining.sub(harvestingAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import './Modifiers/IOwnable.sol';
import './Modifiers/Ownable.sol';
import './Libraries/SafeERC20.sol';
import './Libraries/SafeMath.sol';
import './Libraries/Address.sol';
import './Tokens/IERC20.sol';
import './Tokens/IPancakeERC20.sol';
import './Tokens/IBEP20.sol';
import './Tokens/IPair.sol';
import './Helpers/IRouterV1.sol';
import './IStaking.sol';
import './StakingHelper.sol';

// Contract for partners of BeGlobal only.
contract BondDepositoryGlbBnbLP is Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public glbd;
    address public bnb;
    address public pair;
    address public router;
    address public stakingHelper;

    uint public bondHarvestTime;
    uint public bondRatioLP;
    uint public bondMaxDeposit;
    uint public totalDebt;

    // Info for bond holder
    struct Bond {
        uint deposited; // LPs deposited
        uint depositedGLB; // GLBs deposited
        uint payout; // Total GLBD to be paid
        uint payoutRemaining; // GLBD remaining to be paid
        uint depositTime; // Timestamp on deposit
        uint harvestTime; // HarvestTime on deposit
        uint ratioLP; // For front end viewing
        uint maxDeposit; // For front end viewing
    }

    mapping( address => Bond ) public bondInfo; // stores bond information for depositors

    event BondCreated(address indexed _depositor, uint deposited, uint totalDeposited, uint payout, uint totalPayout, uint harvestTime, uint ratioLP);
    event BondRedeemed( address indexed _depositor, uint amountTransfered, uint remaining, uint payout );

    constructor(
        address _glbd,
        address _bnb,
        address _pair,
        address _router,
        address _stakingHelper,
        uint _bondHarvestTime,
        uint _bondRatioLP,
        uint _bondMaxDeposit
    ) {
        glbd = _glbd;
        bnb = _bnb;
        pair = _pair;
        router = _router;
        stakingHelper = _stakingHelper;
        bondHarvestTime = _bondHarvestTime;
        bondRatioLP = _bondRatioLP;
        bondMaxDeposit = _bondMaxDeposit;
        totalDebt = 0;

        IPair( pair ).approve(_router, uint(0));
        IPair( pair ).approve(_router, uint(~0));

        IERC20( glbd ).approve(_stakingHelper, uint(0));
        IERC20( glbd ).approve(_stakingHelper, uint(~0));
    }

    function setBondHarvestTime( uint _bondHarvestTime ) external onlyOwner {
        bondHarvestTime = _bondHarvestTime;
    }

    function setBondRatioLP( uint _bondRatioLP ) external onlyOwner {
        require( _bondRatioLP > 0, "Invalid parameter" );
        bondRatioLP = _bondRatioLP;
    }

    function setBondMaxDeposit( uint _bondMaxDeposit ) external onlyOwner {
        bondMaxDeposit = _bondMaxDeposit;
    }

    function deposit(
        uint _amount,
        address _depositor
    ) external returns ( uint ) {
        require(  bondInfo[ _depositor ].deposited < bondMaxDeposit, "You cannot deposit more tokens" );
        require( _depositor != address(0), "Invalid address" );

        uint amount = bondMaxDeposit.sub(bondInfo[ _depositor ].deposited)>_amount ? _amount : bondMaxDeposit.sub(bondInfo[ _depositor ].deposited);

        IPair(pair).transferFrom( msg.sender, address(this), amount );

        ( uint reserve0, uint reserve1) = IRouterV1(router).removeLiquidity(
            IPair(pair).token0(),
            IPair(pair).token1(),
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );

        uint reserve;

        if ( IPair(pair).token0() == bnb ) {
            reserve = reserve1;
        } else {
            reserve = reserve0;
        }

        uint actualPayout = reserve.div(bondRatioLP);
        actualPayout = actualPayout.mul( 10 ** IERC20( glbd ).decimals() ).div( 10 ** IERC20( pair ).decimals());

        require( actualPayout <= excessReserves(), "Not enough GLBDs available" );

        bondInfo[ _depositor ] = Bond({
            deposited: bondInfo[ _depositor ].deposited.add(amount),
            depositedGLB: bondInfo[ _depositor ].depositedGLB.add(reserve),
            payout: bondInfo[ _depositor ].payoutRemaining.add( actualPayout ),
            payoutRemaining: bondInfo[ _depositor ].payoutRemaining.add( actualPayout ),
            depositTime: block.timestamp,
            harvestTime: bondHarvestTime,
            maxDeposit: bondMaxDeposit,
            ratioLP: bondRatioLP
        });

        // total debt is increased
        totalDebt = totalDebt.add( actualPayout );

        // indexed events are emitted
        emit BondCreated( _depositor, amount, bondInfo[ _depositor ].deposited , actualPayout,  bondInfo[ _depositor ].payout, bondHarvestTime, bondRatioLP );

        return actualPayout;
    }

    function redeem(
        address _depositor
    ) external returns ( uint ) {
        uint transferAmount = availableToRedeem(_depositor);
        require(transferAmount>0,"[There's no more GLBD to be claimed]");

        StakingHelper(stakingHelper).stake(transferAmount, _depositor);

        uint newPayoutRemaining = bondInfo[ _depositor ].payoutRemaining.sub(transferAmount);
        if(newPayoutRemaining==0)
        {
            delete bondInfo[ _depositor ];
        }
        else
        {
            bondInfo[ _depositor ].payoutRemaining = newPayoutRemaining;
        }

        // total debt is decreased
        totalDebt = totalDebt.sub( transferAmount );

        // indexed events are emitted
        emit BondRedeemed( _depositor, transferAmount, bondInfo[ _depositor ].payoutRemaining, bondInfo[ _depositor ].payout);

        return transferAmount;
    }

    function recoverRewardTokens(uint _amount) external onlyOwner {
        require(IERC20(glbd).balanceOf(address(this)).sub(totalDebt)>=_amount, "Not enough GLBDs available");
        IERC20(glbd).transfer(address(msg.sender), _amount);
    }

    function recoverRewardTokens() external onlyOwner {
        IERC20(glbd).transfer(address(msg.sender), IERC20(glbd).balanceOf(address(this)).sub(totalDebt));
    }

    function recoverLiquidityToken(address _token, uint _amount) external onlyOwner {
        IERC20(_token).transfer(address(msg.sender), _amount);
    }

    function recoverLiquidityToken(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(address(msg.sender), token.balanceOf(address(this)));
    }

    function excessReserves() public view returns ( uint ) {
        return IERC20(glbd).balanceOf(address(this)).sub( totalDebt );
    }

    function availableToDeposit(address _depositor) public view returns ( uint ) {
        return bondMaxDeposit.sub(bondInfo[ _depositor ].deposited);
    }

    function availableToRedeem(address _depositor) public view returns ( uint ) {
        Bond memory depositoryBond = bondInfo[ _depositor ];

        uint harvestingAmount = 0;
        if(depositoryBond.depositTime.add(depositoryBond.harvestTime)>block.timestamp && depositoryBond.harvestTime>0)
        {
            harvestingAmount = depositoryBond.payout.mul(depositoryBond.depositTime.add(depositoryBond.harvestTime).sub(block.timestamp)).div(depositoryBond.harvestTime);
        }

        return depositoryBond.payoutRemaining.sub(harvestingAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

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
            if (returndata.length > 0) {

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IOwnable {
    function owner() external view returns (address);

    function renounceManagement() external;

    function pushManagement( address newOwner_ ) external;

    function pullManagement() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import '../Libraries/SafeMath.sol';
import '../Libraries/Address.sol';
import '../Tokens/IERC20.sol';

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim( address _recipient ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./Tokens/IERC20.sol";
import "./IStaking.sol";

contract StakingHelper {

    address public immutable staking;
    address public immutable GLBD;

    constructor ( address _staking, address _GLBD ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _GLBD != address(0) );
        GLBD = _GLBD;
    }

    function stake( uint _amount, address _recipient ) external {
        IERC20( GLBD ).transferFrom( msg.sender, address(this), _amount );
        IERC20( GLBD ).approve( staking, _amount );
        IStaking( staking ).stake( _amount, _recipient );
        IStaking( staking ).claim( _recipient );
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >= 0.6.12;

interface IPancakeERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.6;

import "./IPancakeERC20.sol";

interface IPair is IPancakeERC20 {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function swapFee() external view returns (uint32);
    function devFee() external view returns (uint32);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    function setSwapFee(uint32) external;
    function setDevFee(uint32) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.5;

interface IRouterV1 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapFeeReward() external pure returns (address);

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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}