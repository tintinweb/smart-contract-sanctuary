/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity >=0.8;

import "./recovery/ERC20Recoverable.sol";
import "./sha/ERC20Draggable.sol";

/**
 * @title Draggable CompanyName AG Shares
 * @author Luzius Meisser, [email protected]
 *
 * This is an ERC-20 token representing shares of CompanyName AG that are bound to
 * a shareholder agreement that can be found at the URL defined in the constant 'terms'.
 * The shareholder agreement is partially enforced through this smart contract. The agreement
 * is designed to facilitate a complete acquisition of the firm even if a minority of shareholders
 * disagree with the acquisition, to protect the interest of the minority shareholders by requiring
 * the acquirer to offer the same conditions to everyone when acquiring the company, and to
 * facilitate an update of the shareholder agreement even if a minority of the shareholders that
 * are bound to this agreement disagree. The name "draggable" stems from the convention of calling
 * the right to drag a minority along with a sale of the company "drag-along" rights. The name is
 * chosen to ensure that token holders are aware that they are bound to such an agreement.
 *
 * The percentage of token holders that must agree with an update of the terms is defined by the
 * constant UPDATE_QUORUM. The percentage of yes-votes that is needed to successfully complete an
 * acquisition is defined in the constant ACQUISITION_QUORUM. Note that the update quorum is based
 * on the total number of tokens in circulation. In contrast, the acquisition quorum is based on the
 * number of votes cast during the voting period, not taking into account those who did not bother
 * to vote.
 */

contract DraggableShares is ERC20Recoverable, ERC20Draggable {

    string public terms;

    constructor(
        string memory _terms,
        address _wrappedToken,
        uint256 _quorumBps,
        uint256 _votePeriodSeconds,
        address _recoveryHub,
        address _offerFactory,
        address _oracle
    )
        ERC20Draggable(_wrappedToken, _quorumBps, _votePeriodSeconds, _offerFactory, _oracle) ERC20Flaggable(0) ERC20Recoverable(_recoveryHub) 
    {
        terms = _terms; // to update the terms, migrate to a new contract. That way it is ensured that the terms can only be updated when the quorom agrees.
        IRecoveryHub(address(_recoveryHub)).setRecoverable(false);
    }

    function transfer(address to, uint256 value) virtual override(ERC20Recoverable, ERC20Flaggable) public returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * Let the oracle act as deleter of invalid claims. In earlier versions, this was referring to the claim deleter
     * of the wrapped token. But that stops working after a successful acquisition as the acquisition currency most
     * likely does not have a claim deleter.
     */
    function getClaimDeleter() public view override returns (address) {
        return getOracle();
    }

    function getCollateralRate(address collateralType) public view override returns (uint256) {
        uint256 rate = super.getCollateralRate(collateralType);
        if (rate > 0) {
            return rate;
        } else if (collateralType == address(wrapped)) {
            return unwrapConversionFactor;
        } else {
            // If the wrapped contract allows for a specific collateral, we should too.
            // If the wrapped contract is not IRecoverable, we will fail here, but would fail anyway.
            return IRecoverable(address(wrapped)).getCollateralRate(collateralType) * unwrapConversionFactor;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) virtual override(ERC20Draggable, ERC20Flaggable) internal {
        super._beforeTokenTransfer(from, to, amount);
    }

}

// SPDX-License-Identifier: MIT
// Copied and adjusted from OpenZeppelin
// Adjustments:
// - modifications to support ERC-677
// - removed unnecessary require statements
// - removed GSN Context
// - upgraded to 0.8 to drop SafeMath
// - let name() and symbol() be implemented by subclass
// - infinite allowance support, with 2^255 and above considered infinite
// - use upper 32 bits of balance for flags
// - add a global settings variable

pragma solidity >=0.8;

import "./IERC20.sol";
import "./IERC677Receiver.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */

abstract contract ERC20Flaggable is IERC20 {

    uint256 private constant FLAGGING_MASK = 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000;
    uint256 private constant BALANCES_MASK = 0x00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    // Documentation of flags used by subclasses:
    // NOTE: flags denote the bit number that is being used and must be smaller than 32
    // ERC20Draggable: uint8 private constant FLAG_INDEX_VOTED = 1;
    // ERC20Recoverable: uint8 private constant FLAG_INDEX_CLAIM_PRESENT = 10;
    // ERCAllowlistable: uint8 private constant FLAG_INDEX_ALLOWLIST = 20;
    // ERCAllowlistable: uint8 private constant FLAG_INDEX_FORBIDDEN = 21;
    // ERCAllowlistable: uint8 private constant FLAG_INDEX_POWERLIST = 22;

    mapping (address => uint256) private _balances; // lower 32 bits reserved for flags

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    uint8 public override decimals;

    constructor(uint8 _decimals) {
        decimals = _decimals;
    }

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account] & BALANCES_MASK;
    }

    function hasFlag(address account, uint8 number) public view returns (bool) {
        return hasFlagInternal(account, number);
    }

    function setFlag(address account, uint8 index, bool value) internal returns (bool) {
        if (hasFlagInternal(account, index) != value){
            toggleFlag(account, index);
            return true;
        } else {
            return false;
        }
    }

    function hasFlagInternal(address account, uint8 number) internal view returns (bool) {
        uint256 flag = 0x1 << (number + 224);
        return _balances[account] & flag == flag;
    }

    function toggleFlag(address account, uint8 number) internal {
        uint256 flag = 0x1 << (number + 224);
        _balances[account] ^= flag;
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance < (1 << 255)){
            // Only decrease the allowance if it was not set to 'infinite'
            // Documented in /doc/infiniteallowance.md
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] -= amount;
        increaseBalance(recipient, amount);
        emit Transfer(sender, recipient, amount);
    }

    // ERC-677 functionality, can be useful for swapping and wrapping tokens
    function transferAndCall(address recipient, uint amount, bytes calldata data) public returns (bool) {
        bool success = transfer(recipient, amount);
        if (success){
            success = IERC677Receiver(recipient).onTokenTransfer(msg.sender, amount, data);
        }
        return success;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address recipient, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), recipient, amount);
        _totalSupply += amount;
        increaseBalance(recipient, amount);
        emit Transfer(address(0), recipient, amount);
    }

    function increaseBalance(address recipient, uint256 amount) private {
        require(recipient != address(0x0)); // use burn instead
        uint256 oldBalance = _balances[recipient];
        uint256 oldSettings = oldBalance & FLAGGING_MASK;
        uint256 newBalance = oldBalance + amount;
        uint256 newSettings = newBalance & FLAGGING_MASK;
        require(newSettings == oldSettings, "overflow");
        _balances[recipient] = newBalance;
    }

     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(account, address(0), amount);

        _totalSupply -= amount;
        _balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) virtual internal {
    }
}

/**
* SPDX-License-Identifier: MIT
*
* Copyright (c) 2016-2019 zOS Global Limited
*
*/
pragma solidity >=0.8;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */

interface IERC20 {

    // Optional functions
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    event NameChanged(string name, string symbol);

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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

interface IERC677Receiver {
    
    function onTokenTransfer(address from, uint256 amount, bytes calldata data) external returns (bool);

}

// SPDX-License-Identifier: MIT
//
// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
//
// Modifications:
// - Replaced Context._msgSender() with msg.sender
// - Made leaner
// - Extracted interface

pragma solidity >=0.8;

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
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address initialOwner) {
        owner = initialOwner;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }
}

/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity ^0.8;

import "../recovery/ERC20Recoverable.sol";
import "./ERC20Allowlistable.sol";
import "../DraggableShares.sol";

contract AllowlistDraggableShares is ERC20Allowlistable, ERC20Draggable, ERC20Recoverable {

  string public terms;

  constructor(
    string memory _terms,
    address _wrappedToken,
    uint256 _quorum,
    uint256 _votePeriod,
    address _recoveryHub,
    address _offerFactory,
    address _oracle,
    address _owner
  )
    ERC20Draggable(_wrappedToken, _quorum, _votePeriod, _offerFactory, _oracle) 
    ERC20Flaggable(0)
    ERC20Recoverable(_recoveryHub)
    Ownable(_owner)
  {
    terms = _terms; // to update the terms, migrate to a new contract. That way it is ensured that the terms can only be updated when the quorom agrees.
    IRecoveryHub(address(_recoveryHub)).setRecoverable(false); 
  }

  /**
  * Let the oracle act as deleter of invalid claims. In earlier versions, this was referring to the claim deleter
  * of the wrapped token. But that stops working after a successful acquisition as the acquisition currency most
  * likely does not have a claim deleter.
  */
  function getClaimDeleter() public view override returns (address) {
      return getOracle();
  }

  function transfer(address to, uint256 value) virtual override(ERC20Flaggable, ERC20Recoverable) public returns (bool) {
      return super.transfer(to, value);
  }
  function _beforeTokenTransfer(address from, address to, uint256 amount) virtual override(ERC20Allowlistable, ERC20Draggable, ERC20Flaggable) internal {
    super._beforeTokenTransfer(from, to, amount);
  }

}

/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity ^0.8;


import "../ERC20Flaggable.sol";
import "../Ownable.sol";

/**
 * 
 */
abstract contract ERC20Allowlistable is ERC20Flaggable, Ownable {

  uint8 private constant TYPE_DEFAULT = 0x0;
  uint8 private constant TYPE_ALLOWLISTED = 0x1;
  uint8 private constant TYPE_FORBIDDEN = 0x2;
  uint8 private constant TYPE_POWERLISTED = 0x4;

  uint8 private constant FLAG_INDEX_ALLOWLIST = 20;
  uint8 private constant FLAG_INDEX_FORBIDDEN = 21;
  uint8 private constant FLAG_INDEX_POWERLIST = 22;

  event AddressTypeUpdate(address indexed account, uint8 addressType);

  bool public restrictTransfers;

  constructor(){
    setApplicableInternal(true);
  }

  /**
   * Configures whether the allowlisting is applied.
   * Also sets the powerlist and allowlist flags on the null address accordingly.
   * It is recommended to also deactivate the powerlist flag on other addresses.
   */
  function setApplicable(bool transferRestrictionsApplicable) public onlyOwner {
    setApplicableInternal(transferRestrictionsApplicable);
  }

  function setApplicableInternal(bool transferRestrictionsApplicable) internal {
    restrictTransfers = true;
    // if transfer restrictions are applied, we guess that should also be the case for newly minted tokens
    // if the admin disagrees, it is still possible to change the type of the null address
    if (transferRestrictionsApplicable){
      setTypeInternal(address(0x0), TYPE_POWERLISTED);
    } else {
      setTypeInternal(address(0x0), TYPE_DEFAULT);
    }
  }

  function setType(address account, uint8 typeNumber) public onlyOwner {
    setTypeInternal(account, typeNumber);
  }

  function setTypeInternal(address account, uint8 typeNumber) internal {
    setFlag(account, FLAG_INDEX_ALLOWLIST, typeNumber == TYPE_ALLOWLISTED);
    setFlag(account, FLAG_INDEX_FORBIDDEN, typeNumber == TYPE_FORBIDDEN);
    setFlag(account, FLAG_INDEX_POWERLIST, typeNumber == TYPE_POWERLISTED);
    emit AddressTypeUpdate(account, typeNumber);
  }

  function setType(address[] calldata addressesToAdd, uint8 value) public onlyOwner {
    for (uint i=0; i<addressesToAdd.length; i++){
      setType(addressesToAdd, value);
    }
  }

  /**
   * If true, this address is allowlisted and can only transfer tokens to other allowlisted addresses.
   */
  function canReceiveFromAnyone(address account) public view returns (bool) {
    return hasFlagInternal(account, FLAG_INDEX_ALLOWLIST) || hasFlagInternal(account, FLAG_INDEX_POWERLIST);
  }

  /**
   * If true, this address can only transfer tokens to allowlisted addresses and not receive from anyone.
   */
  function isForbidden(address account) public view returns (bool){
    return hasFlagInternal(account, FLAG_INDEX_FORBIDDEN);
  }

  /**
   * If true, this address can automatically allowlist target addresses if necessary.
   */
  function isPowerlisted(address account) public view returns (bool) {
    return hasFlagInternal(account, FLAG_INDEX_POWERLIST);
  }

  /**
   * Cleans the allowlist and disallowlist flag under the assumption that the
   * allowlisting is not applicable any more.
   */
  function failOrCleanup(address account) internal {
    require(!restrictTransfers, "not allowed");
    setType(account, TYPE_DEFAULT);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) override virtual internal {
    super._beforeTokenTransfer(from, to, amount);
    if (canReceiveFromAnyone(to)){
      // ok, transfers to allowlisted addresses are always allowed
    } else if (isForbidden(to)){
      // Target is forbidden, but maybe restrictions have been removed and we can clean the flag
      failOrCleanup(to);
    } else {
      if (isPowerlisted(from)){
        // it is not allowlisted, but we can make it so
        setType(to, TYPE_ALLOWLISTED);
      }
      // if we made it to here, the target must be a free address and we are not powerlisted
      else if (hasFlagInternal(from, FLAG_INDEX_ALLOWLIST) || isForbidden(from)){
        // We cannot send to free addresses, but maybe the restrictions have been removed and we can clean the flag?
        failOrCleanup(from);
      }
    }
  }

}

/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity >=0.8;

import "../ERC20Flaggable.sol";
import "./IRecoveryHub.sol";
import "./IRecoverable.sol";

/**
 * @title Recoverable
 * In case of tokens that represent real-world assets such as shares of a company, one needs a way
 * to handle lost private keys. With physical certificates, courts can declare share certificates as
 * invalid so the company can issue replacements. Here, we want a solution that does not depend on
 * third parties to resolve such cases. Instead, when someone has lost a private key, he can use the
 * declareLost function to post a deposit and claim that the shares assigned to a specific address are
 * lost. To prevent front running, a commit reveal scheme is used. If he actually is the owner of the shares,
 * he needs to wait for a certain period and can then reclaim the lost shares as well as the deposit.
 * If he is an attacker trying to claim shares belonging to someone else, he risks losing the deposit
 * as it can be claimed at anytime by the rightful owner.
 * Furthermore, if "getClaimDeleter" is defined in the subclass, the returned address is allowed to
 * delete claims, returning the collateral. This can help to prevent obvious cases of abuse of the claim
 * function.
 */

abstract contract ERC20Recoverable is ERC20Flaggable, IRecoverable {

    uint8 private constant FLAG_CLAIM_PRESENT = 10;

    // ERC-20 token that can be used as collateral or 0x0 if disabled
    address public customCollateralAddress;
    uint256 public customCollateralRate;

    IRecoveryHub public immutable recovery;

    constructor(address recoveryHub){
        recovery = IRecoveryHub(recoveryHub);
    }

    /**
     * Returns the collateral rate for the given collateral type and 0 if that type
     * of collateral is not accepted. By default, only the token itself is accepted at
     * a rate of 1:1.
     *
     * Subclasses should override this method if they want to add additional types of
     * collateral.
     */
    function getCollateralRate(address collateralType) public override virtual view returns (uint256) {
        if (collateralType == address(this)) {
            return 1;
        } else if (collateralType == customCollateralAddress) {
            return customCollateralRate;
        } else {
            return 0;
        }
    }

    function claimPeriod() public pure override returns (uint256){
        return 180 days;
    }

    /**
     * Allows subclasses to set a custom collateral besides the token itself.
     * The collateral must be an ERC-20 token that returns true on successful transfers and
     * throws an exception or returns false on failure.
     * Also, do not forget to multiply the rate in accordance with the number of decimals of the collateral.
     * For example, rate should be 7*10**18 for 7 units of a collateral with 18 decimals.
     */
    function _setCustomClaimCollateral(address collateral, uint256 rate) internal {
        customCollateralAddress = collateral;
        if (customCollateralAddress == address(0)) {
            customCollateralRate = 0; // disabled
        } else {
            require(rate > 0, "zero");
            customCollateralRate = rate;
        }
    }

    function getClaimDeleter() virtual public view returns (address);

    function transfer(address recipient, uint256 amount) override virtual public returns (bool) {
        require(super.transfer(recipient, amount));
        if (hasFlagInternal(msg.sender, FLAG_CLAIM_PRESENT)){
            recovery.clearClaimFromToken(msg.sender);
        }
        return true;
    }

    function notifyClaimMade(address target) public override {
        require(msg.sender == address(recovery));
        setFlag(target, FLAG_CLAIM_PRESENT, true);
    }

    function notifyClaimDeleted(address target) public override {
        require(msg.sender == address(recovery));
        setFlag(target, FLAG_CLAIM_PRESENT, false);
    }

    function deleteClaim(address lostAddress) public {
        require(msg.sender == getClaimDeleter(), "no access");
        recovery.deleteClaim(lostAddress);
    }

    function recover(address oldAddress, address newAddress) public override {
        require(msg.sender == address(recovery));
        _transfer(oldAddress, newAddress, balanceOf(oldAddress));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

abstract contract IRecoverable {

    function claimPeriod() public view virtual returns (uint256);
    
    function notifyClaimMade(address target) public virtual;

    function notifyClaimDeleted(address target) public virtual;

    function getCollateralRate(address collateral) public view virtual returns(uint256);

    function recover(address oldAddress, address newAddress) public virtual;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

abstract contract IRecoveryHub {

    function setRecoverable(bool flag) public virtual;
    
    function deleteClaim(address target) public virtual;

    function clearClaimFromToken(address holder) public virtual;

}

/**
 * SPDX-License-Identifier: LicenseRef-Aktionariat
 *
 * MIT License with Automated License Fee Payments
 *
 * Copyright (c) 2020 Aktionariat AG (aktionariat.com)
 *
 * Permission is hereby granted to any person obtaining a copy of this software
 * and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies of the
 * Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * - The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * - All automated license fee payments integrated into this and related Software
 *   are preserved.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
pragma solidity >=0.8;

/**
 * @title CompanyName Shareholder Agreement
 * @author Luzius Meisser, [email protected]
 * @dev These tokens are based on the ERC20 standard and the open-zeppelin library.
 *
 * This is an ERC-20 token representing shares of CompanyName AG that are bound to
 * a shareholder agreement that can be found at the URL defined in the constant 'terms'
 * of the 'DraggableCompanyNameShares' contract. The agreement is partially enforced
 * through the Swiss legal system, and partially enforced through this smart contract.
 * In particular, this smart contract implements a drag-along clause which allows the
 * majority of token holders to force the minority sell their shares along with them in
 * case of an acquisition. That's why the tokens are called "Draggable CompanyName AG Shares."
 */

import "./IDraggable.sol";
import "../ERC20Flaggable.sol";
import "../IERC20.sol";
import "../IERC677Receiver.sol";

abstract contract ERC20Draggable is ERC20Flaggable, IERC677Receiver, IDraggable {
    
	uint8 private constant FLAG_VOTED = 1;

	IERC20 public wrapped; // The wrapped contract
	IOfferFactory public immutable factory;

	// If the wrapped tokens got replaced in an acquisition, unwrapping might yield many currency tokens
	uint256 public unwrapConversionFactor = 0;

	// The current acquisition attempt, if any. See initiateAcquisition to see the requirements to make a public offer.
	IOffer public offer;

	uint256 public immutable quorum; // BPS (out of 10'000)
	uint256 public immutable votePeriod; // Seconds

	address private oracle;

	event MigrationSucceeded(
		address newContractAddress,
		uint256 yesVotes,
		uint256 oracleVotes,
		uint256 totalVotingPower
	);

	constructor(
		address _wrappedToken,
		uint256 _quorum,
		uint256 _votePeriod,
		address _offerFactory,
		address _oracle
	) {
		wrapped = IERC20(_wrappedToken);
		quorum = _quorum;
		votePeriod = _votePeriod;
		factory = IOfferFactory(_offerFactory);
		oracle = _oracle;
	}

	function onTokenTransfer(
		address from,
		uint256 amount,
		bytes calldata
	) public override returns (bool) {
		require(msg.sender == address(wrapped));
		_mint(from, amount);
		return true;
	}

	/** Increases the number of drag-along tokens. Requires minter to deposit an equal amount of share tokens */
	function wrap(address shareholder, uint256 amount) public {
		require(wrapped.transferFrom(msg.sender, address(this), amount));
		_mint(shareholder, amount);
	}

	/**
	 * Indicates that the token holders are bound to the token terms and that:
	 * - Conversions back to the wrapped token (unwrap) are not allowed
	 * - The drag-along can be performed by making an according offer
	 * - They can be migrated to a new version of this contract in accordance with the terms
	 */
	function isBinding() public view returns (bool) {
		return unwrapConversionFactor == 0;
	}

	function name() public view override returns (string memory) {
		if (isBinding()) {
			return string(abi.encodePacked(wrapped.name(), " SHA"));
		} else {
			return string(abi.encodePacked(wrapped.name(), " (Wrapped)"));
		}
	}

	function symbol() public view override returns (string memory) {
		// ticker should be less dynamic than name
		return string(abi.encodePacked(wrapped.symbol(), "S"));
	}

	/**
	 * Deactivates the drag-along mechanism and enables the unwrap function.
	 */
	function deactivate(uint256 factor) internal {
		require(factor >= 1, "factor");
		unwrapConversionFactor = factor;
		emit NameChanged(name(), symbol());
	}

	/** Decrease the number of drag-along tokens. The user gets back their shares in return */
	function unwrap(uint256 amount) public {
		require(!isBinding());
		unwrap(msg.sender, amount, unwrapConversionFactor);
	}

	function unwrap(
		address owner,
		uint256 amount,
		uint256 factor
	) internal {
		_burn(owner, amount);
		require(wrapped.transfer(owner, amount * factor));
	}

	/**
	 * Burns both the token itself as well as the wrapped token!
	 * If you want to get out of the shareholder agreement, use unwrap after it has been
	 * deactivated by a majority vote or acquisition.
	 *
	 * Burning only works if wrapped token supports burning. Also, the exact meaning of this
	 * operation might depend on the circumstances. Burning and reussing the wrapped token
	 * does not free the sender from the legal obligations of the shareholder agreement.
	 */
	function burn(uint256 amount) public {
		_burn(msg.sender, amount);
		uint256 factor = isBinding() ? 1 : unwrapConversionFactor;
		IShares(address(wrapped)).burn(amount * factor);
	}

	function makeAcquisitionOffer(
		bytes32 salt,
		uint256 pricePerShare,
		address currency
	) public payable {
		require(isBinding());
		address newOffer = factory.create{value: msg.value}(
			salt,
			msg.sender,
			pricePerShare,
			currency,
			quorum,
			votePeriod
		);

		if (offerExists()) {
			offer.makeCompetingOffer(newOffer);
		}
		offer = IOffer(newOffer);
	}

	function drag(address buyer, address currency) public override {
		require(msg.sender == address(offer));
		unwrap(buyer, balanceOf(buyer), 1);
		replaceWrapped(currency, buyer);
	}

	function notifyOfferEnded() public override {
		if (msg.sender == address(offer)) {
			offer = IOffer(address(0));
		}
	}

	function replaceWrapped(address newWrapped, address oldWrappedDestination) internal {
		require(isBinding());
		// Free all old wrapped tokens we have
		require(wrapped.transfer(oldWrappedDestination, wrapped.balanceOf(address(this))));
		// Count the new wrapped tokens
		wrapped = IERC20(newWrapped);
		deactivate(wrapped.balanceOf(address(this)) / totalSupply());
	}

	function getOracle() public view override returns (address) {
		return oracle;
	}

	function setOracle(address newOracle) public {
		require(msg.sender == oracle, "not oracle");
		oracle = newOracle;
	}

	function migrateWithExternalApproval(address target, uint256 externalSupportingVotes) public {
		require(msg.sender == oracle);
		// Additional votes cannot be higher than the votes not represented by these tokens.
		// The assumption here is that more shareholders are bound to the shareholder agreement
		// that this contract helps enforce and a vote among all parties is necessary to change
		// it, with an oracle counting and reporting the votes of the others.
		require(totalSupply() + externalSupportingVotes <= totalVotingTokens());
		migrate(target, externalSupportingVotes);
	}

	function migrate() public {
		migrate(msg.sender, 0);
	}

	function migrate(address successor, uint256 additionalVotes) internal {
		uint256 yesVotes = additionalVotes + balanceOf(successor);
		uint256 totalVotes = totalVotingTokens();
		require(yesVotes < totalVotes);
		require(!offerExists()); // if you have the quorum, you can cancel the offer first if necessary
		require(yesVotes * 10000 >= totalVotes * quorum, "quorum");
		replaceWrapped(successor, successor);
		emit MigrationSucceeded(successor, yesVotes, additionalVotes, totalVotes);
	}

	function votingPower(address voter) public view override returns (uint256) {
		return balanceOf(voter);
	}

	function totalVotingTokens() public view override returns (uint256) {
		return IShares(address(wrapped)).totalShares();
	}

	function hasVoted(address voter) internal view returns (bool) {
		return hasFlagInternal(voter, FLAG_VOTED);
	}

	function notifyVoted(address voter) public override {
		setFlag(voter, FLAG_VOTED, true);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual override {
		if (hasVoted(from) || hasVoted(to)) {
			if (offerExists()) {
				offer.notifyMoved(from, to, amount);
			} else {
				setFlag(from, FLAG_VOTED, false);
				setFlag(to, FLAG_VOTED, false);
			}
		}
		super._beforeTokenTransfer(from, to, amount);
	}

	function offerExists() internal view returns (bool) {
		return address(offer) != address(0);
	}
}

abstract contract IShares {
	function burn(uint256) public virtual;

	function totalShares() public view virtual returns (uint256);
}

abstract contract IOffer {
	function makeCompetingOffer(address newOffer) public virtual;

	function notifyMoved(
		address from,
		address to,
		uint256 value
	) public virtual;
}

abstract contract IOfferFactory {
	function create(
		bytes32 salt,
		address buyer,
		uint256 pricePerShare,
		address currency,
		uint256 quorum,
		uint256 votePeriod
	) public payable virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

abstract contract IDraggable {
    
    function getOracle() public virtual returns (address);
    function drag(address buyer, address currency) public virtual;
    function notifyOfferEnded() public virtual;
    function votingPower(address voter) public virtual returns (uint256);
    function totalVotingTokens() public virtual view returns (uint256);
    function notifyVoted(address voter) public virtual;

}