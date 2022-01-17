// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

abstract contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract PrismPresale is Owned {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    // unix timestamp datas
    bool public openPresale;
    uint public closingTime; // time once the presale will close
    uint public claimStartTime; // time once the claim Prism started

    // buyers infos
    struct preBuy {
        uint mimAmount;
        uint aPrismAmount;
        uint claimedPercent;
    }
    mapping(address => preBuy) public preBuys;
    mapping(address => bool) public whiteListed;

    // Prism address
    address public Prism;
    // address where funds are collected
    address public PrismWallet;
    // address of mim token
    address public immutable MIMToken;
    // address of ccc token
    address public immutable CCCToken;

    // buy rate
    uint public boughtaPrism;
    uint public constant rate = 10;
    uint public constant secInDay = 86400;
    uint public constant maxaPrismAmount = 3 * 1e14;

    uint public constant MimAmount1 = 500;
    uint public constant MimAmount2 = 1000;
    uint public constant MimAmount3 = 1500;
    uint public constant MinCCC1 = 16 * 1e6;
    uint public constant MinCCC2 = 50 * 1e6;
    uint public constant MinCCC3 = 75 * 1e6;

    enum BuyType { LV1, LV2, LV3 }

    event TokenPurchase(address indexed purchaser, uint MimAmount, uint aPrismAmount);
    event ClaimPrism(address indexed claimer, uint prismAmount);

    constructor(
        address _mim,
        address _ccc
    ) {
        require(_mim != address(0));
        require(_ccc != address(0));

        MIMToken = _mim;
        CCCToken = _ccc;
    }

    function setPrism(address _prism) external onlyOwner {
        require(_prism != address(0));
        Prism = _prism;
    }

    function setWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0));
        PrismWallet = _wallet;
    }

    function startPresale() external onlyOwner {
        require(closingTime == 0, "Presale is open");
        
        closingTime = block.timestamp.add(secInDay.mul(2));
        openPresale = true;
    }

    function stopPresale() external onlyOwner {
        require(isPresale(), "Presale is not open");

        openPresale = false;
    }

    function startClaim() external onlyOwner {
        // check presale completed
        require(closingTime > 0 && block.timestamp > closingTime);

        claimStartTime = block.timestamp;
    }

    function setWhitelist(address[] memory addresses, bool value) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            whiteListed[addresses[i]] = value;
        }
    }

    function isPresale() public view returns(bool) {
        return block.timestamp <= closingTime && openPresale;
    }

    function presaleTime() public view returns(uint _remain) {
        _remain = isPresale() ? closingTime - block.timestamp : 0;
    }

    function getCCCMin(BuyType _type) public view returns(uint) {
        uint cccMin = _type == BuyType.LV1 ? MinCCC1 : (_type == BuyType.LV2 ? MinCCC2 : MinCCC3);
        return cccMin.mul(1e9);
    }

    function getMimAmount(BuyType _type) public view returns(uint) {
        uint _minAmount = _type == BuyType.LV1 ? MimAmount1 : (_type == BuyType.LV2 ? MimAmount2 : MimAmount3);
        return _minAmount.mul(1e18);
    }

    // allows buyers to put their mim to get some aPrism once the presale will closes
    function buy(BuyType _type) public {
        require(isPresale(), "Presale is not open");
        require(whiteListed[msg.sender], "You are not whitelisted");
        
        require(IERC20( CCCToken ).balanceOf(msg.sender) >= getCCCMin(_type), "You don't have enought CCC balance");

        preBuy memory selBuyer = preBuys[msg.sender];
        require(selBuyer.mimAmount == 0, "You bought aPrism already");

        uint mimAmount = getMimAmount(_type);
        require(mimAmount > 0);

        // calculate aPrism amount to be created
        uint aPrismAmount = mimAmount.mul(rate).div(1e11);
        require(maxaPrismAmount.sub(boughtaPrism) >= aPrismAmount, "there aren't enough fund to buy more aPrism");

        // safe transferFrom of the payout amount
        IERC20( MIMToken ).safeTransferFrom(msg.sender, address(this), mimAmount);
        
        selBuyer.mimAmount = mimAmount;
        selBuyer.aPrismAmount = aPrismAmount;
        preBuys[msg.sender] = selBuyer;

        boughtaPrism = boughtaPrism.add(aPrismAmount);

        emit TokenPurchase(
            msg.sender,
            mimAmount,
            aPrismAmount
        );
    }

    function getDay() public view returns(uint) {
        return block.timestamp.sub(claimStartTime).div(secInDay);
    }

    function getPercent() public view returns (uint _percent) {
        if(claimStartTime > 0 && block.timestamp >= claimStartTime) {
            uint dayPassed = getDay();
            if(dayPassed > 8) {
                dayPassed = 8;
            }

            uint totalPercent = dayPassed.mul(10).add(20);

            preBuy memory info = preBuys[msg.sender];
            _percent = totalPercent.sub(info.claimedPercent);
        }
    }

    function claimPrism() public {
        preBuy memory info = preBuys[msg.sender];
        require(info.aPrismAmount > 0, "Insufficient aPrism");

        uint percent = getPercent();
        require(percent > 0, "You can not claim more");
        
        uint newPercent = info.claimedPercent.add(percent);
        require(newPercent <= 100);

        preBuys[msg.sender].claimedPercent = newPercent;

        uint amount = info.aPrismAmount.mul(percent).div(100);
        IERC20( Prism ).safeTransfer(msg.sender, amount);

        emit ClaimPrism(msg.sender, amount);
    }

    // allows operator wallet to get the mim deposited in the contract
    function retrieveMim() public onlyOwner {
        require(!isPresale() && closingTime > 0, "Presale is not over yet");

        IERC20( MIMToken ).safeTransfer(PrismWallet, IERC20( MIMToken ).balanceOf(address(this)));
    }

    // allows operator wallet to get the unsold prism in the contract
    function retrievePrism() public onlyOwner {
        require(claimStartTime > 0 && getDay() > 8);

        IERC20( Prism ).safeTransfer(PrismWallet, IERC20( Prism ).balanceOf(address(this)));
    }

    function withdrawFunds() public onlyOwner {
        payable( PrismWallet ).transfer(address(this).balance);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);
  
  /**
   * @dev Returns the decimals of tokens in existence.
   */
  function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

// TODO(zx): Replace all instances of SafeMath with OZ implementation
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
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "./SafeMath.sol";
import "./Address.sol";

import "../interfaces/IERC20.sol";

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

// SPDX-License-Identifier: AGPL-3.0-or-later
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