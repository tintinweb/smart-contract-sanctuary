/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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


// File @openzeppelin/contracts/access/[email protected]

//

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

//

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

//

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

//

pragma solidity ^0.8.0;



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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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


// File contracts/utils/Power.sol

//

/* Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/
TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION
1. Definitions.
"License" shall mean the terms and conditions for use, reproduction,
and distribution as defined by Sections 1 through 9 of this document.
"Licensor" shall mean the copyright owner or entity authorized by
the copyright owner that is granting the License.
"Legal Entity" shall mean the union of the acting entity and all
other entities that control, are controlled by, or are under common
control with that entity. For the purposes of this definition,
"control" means (i) the power, direct or indirect, to cause the
direction or management of such entity, whether by contract or
otherwise, or (ii) ownership of fifty percent (50%) or more of the
outstanding shares, or (iii) beneficial ownership of such entity.
"You" (or "Your") shall mean an individual or Legal Entity
exercising permissions granted by this License.
"Source" form shall mean the preferred form for making modifications,
including but not limited to software source code, documentation
source, and configuration files.
"Object" form shall mean any form resulting from mechanical
transformation or translation of a Source form, including but
not limited to compiled object code, generated documentation,
and conversions to other media types.
"Work" shall mean the work of authorship, whether in Source or
Object form, made available under the License, as indicated by a
copyright notice that is included in or attached to the work
(an example is provided in the Appendix below).
"Derivative Works" shall mean any work, whether in Source or Object
form, that is based on (or derived from) the Work and for which the
editorial revisions, annotations, elaborations, or other modifications
represent, as a whole, an original work of authorship. For the purposes
of this License, Derivative Works shall not include works that remain
separable from, or merely link (or bind by name) to the interfaces of,
the Work and Derivative Works thereof.
"Contribution" shall mean any work of authorship, including
the original version of the Work and any modifications or additions
to that Work or Derivative Works thereof, that is intentionally
submitted to Licensor for inclusion in the Work by the copyright owner
or by an individual or Legal Entity authorized to submit on behalf of
the copyright owner. For the purposes of this definition, "submitted"
means any form of electronic, verbal, or written communication sent
to the Licensor or its representatives, including but not limited to
communication on electronic mailing lists, source code control systems,
and issue tracking systems that are managed by, or on behalf of, the
Licensor for the purpose of discussing and improving the Work, but
excluding communication that is conspicuously marked or otherwise
designated in writing by the copyright owner as "Not a Contribution."
"Contributor" shall mean Licensor and any individual or Legal Entity
on behalf of whom a Contribution has been received by Licensor and
subsequently incorporated within the Work.
2. Grant of Copyright License. Subject to the terms and conditions of
this License, each Contributor hereby grants to You a perpetual,
worldwide, non-exclusive, no-charge, royalty-free, irrevocable
copyright license to reproduce, prepare Derivative Works of,
publicly display, publicly perform, sublicense, and distribute the
Work and such Derivative Works in Source or Object form.
3. Grant of Patent License. Subject to the terms and conditions of
this License, each Contributor hereby grants to You a perpetual,
worldwide, non-exclusive, no-charge, royalty-free, irrevocable
(except as stated in this section) patent license to make, have made,
use, offer to sell, sell, import, and otherwise transfer the Work,
where such license applies only to those patent claims licensable
by such Contributor that are necessarily infringed by their
Contribution(s) alone or by combination of their Contribution(s)
with the Work to which such Contribution(s) was submitted. If You
institute patent litigation against any entity (including a
cross-claim or counterclaim in a lawsuit) alleging that the Work
or a Contribution incorporated within the Work constitutes direct
or contributory patent infringement, then any patent licenses
granted to You under this License for that Work shall terminate
as of the date such litigation is filed.
4. Redistribution. You may reproduce and distribute copies of the
Work or Derivative Works thereof in any medium, with or without
modifications, and in Source or Object form, provided that You
meet the following conditions:
(a) You must give any other recipients of the Work or
Derivative Works a copy of this License; and
(b) You must cause any modified files to carry prominent notices
stating that You changed the files; and
(c) You must retain, in the Source form of any Derivative Works
that You distribute, all copyright, patent, trademark, and
attribution notices from the Source form of the Work,
excluding those notices that do not pertain to any part of
the Derivative Works; and
(d) If the Work includes a "NOTICE" text file as part of its
distribution, then any Derivative Works that You distribute must
include a readable copy of the attribution notices contained
within such NOTICE file, excluding those notices that do not
pertain to any part of the Derivative Works, in at least one
of the following places: within a NOTICE text file distributed
as part of the Derivative Works; within the Source form or
documentation, if provided along with the Derivative Works; or,
within a display generated by the Derivative Works, if and
wherever such third-party notices normally appear. The contents
of the NOTICE file are for informational purposes only and
do not modify the License. You may add Your own attribution
notices within Derivative Works that You distribute, alongside
or as an addendum to the NOTICE text from the Work, provided
that such additional attribution notices cannot be construed
as modifying the License.
You may add Your own copyright statement to Your modifications and
may provide additional or different license terms and conditions
for use, reproduction, or distribution of Your modifications, or
for any such Derivative Works as a whole, provided Your use,
reproduction, and distribution of the Work otherwise complies with
the conditions stated in this License.
5. Submission of Contributions. Unless You explicitly state otherwise,
any Contribution intentionally submitted for inclusion in the Work
by You to the Licensor shall be under the terms and conditions of
this License, without any additional terms or conditions.
Notwithstanding the above, nothing herein shall supersede or modify
the terms of any separate license agreement you may have executed
with Licensor regarding such Contributions.
6. Trademarks. This License does not grant permission to use the trade
names, trademarks, service marks, or product names of the Licensor,
except as required for reasonable and customary use in describing the
origin of the Work and reproducing the content of the NOTICE file.
7. Disclaimer of Warranty. Unless required by applicable law or
agreed to in writing, Licensor provides the Work (and each
Contributor provides its Contributions) on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied, including, without limitation, any warranties or conditions
of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
PARTICULAR PURPOSE. You are solely responsible for determining the
appropriateness of using or redistributing the Work and assume any
risks associated with Your exercise of permissions under this License.
8. Limitation of Liability. In no event and under no legal theory,
whether in tort (including negligence), contract, or otherwise,
unless required by applicable law (such as deliberate and grossly
negligent acts) or agreed to in writing, shall any Contributor be
liable to You for damages, including any direct, indirect, special,
incidental, or consequential damages of any character arising as a
result of this License or out of the use or inability to use the
Work (including but not limited to damages for loss of goodwill,
work stoppage, computer failure or malfunction, or any and all
other commercial damages or losses), even if such Contributor
has been advised of the possibility of such damages.
9. Accepting Warranty or Additional Liability. While redistributing
the Work or Derivative Works thereof, You may choose to offer,
and charge a fee for, acceptance of support, warranty, indemnity,
or other liability obligations and/or rights consistent with this
License. However, in accepting such obligations, You may act only
on Your own behalf and on Your sole responsibility, not on behalf
of any other Contributor, and only if You agree to indemnify,
defend, and hold each Contributor harmless for any liability
incurred by, or claims asserted against, such Contributor by reason
of your accepting any such warranty or additional liability.
END OF TERMS AND CONDITIONS
APPENDIX: How to apply the Apache License to your work.
To apply the Apache License to your work, attach the following
boilerplate notice, with the fields enclosed by brackets "{}"
replaced with your own identifying information. (Don't include
the brackets!)  The text should be enclosed in the appropriate
comment syntax for the file format. We also recommend that a
file or class name and description of purpose be included on the
same "printed page" as the copyright notice for easier
identification within third-party archives.
Copyright 2017 Bprotocol Foundation
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

pragma solidity 0.8.9;

/**
* @title Power function by Bancor
* @dev https://github.com/bancorprotocol/contracts
*
* Modified from the original by Slava Balasanov & Tarrence van As
*
* Split Power.sol out from BancorFormula.sol
*/
contract Power {

    uint256 private constant ONE = 1;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

    /**
      The values below depend on MAX_PRECISION. If you choose to change it:
      Apply the same change in file 'PrintIntScalingFactors.py', run it and paste the results below.
    */
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

    /**
        Auto-generated via 'PrintLn2ScalingFactors.py'
    */
    uint256 private constant LN2_NUMERATOR   = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    /**
        Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'
    */
    uint256 private constant OPT_LOG_MAX_VAL =
    0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL =
    0x800000000000000000000000000000000;

    /**
      The values below depend on MIN_PRECISION and MAX_PRECISION. If you choose to change either one of them:
      Apply the same change in file 'PrintFunctionBancorFormula.py', run it and paste the results below.
    */
    uint256[128] private maxExpArray;
    constructor() {
        //  maxExpArray[0] = 0x6bffffffffffffffffffffffffffffffff;
        //  maxExpArray[1] = 0x67ffffffffffffffffffffffffffffffff;
        //  maxExpArray[2] = 0x637fffffffffffffffffffffffffffffff;
        //  maxExpArray[3] = 0x5f6fffffffffffffffffffffffffffffff;
        //  maxExpArray[4] = 0x5b77ffffffffffffffffffffffffffffff;
        //  maxExpArray[5] = 0x57b3ffffffffffffffffffffffffffffff;
        //  maxExpArray[6] = 0x5419ffffffffffffffffffffffffffffff;
        //  maxExpArray[7] = 0x50a2ffffffffffffffffffffffffffffff;
        //  maxExpArray[8] = 0x4d517fffffffffffffffffffffffffffff;
        //  maxExpArray[9] = 0x4a233fffffffffffffffffffffffffffff;
        //  maxExpArray[10] = 0x47165fffffffffffffffffffffffffffff;
        //  maxExpArray[11] = 0x4429afffffffffffffffffffffffffffff;
        //  maxExpArray[12] = 0x415bc7ffffffffffffffffffffffffffff;
        //  maxExpArray[13] = 0x3eab73ffffffffffffffffffffffffffff;
        //  maxExpArray[14] = 0x3c1771ffffffffffffffffffffffffffff;
        //  maxExpArray[15] = 0x399e96ffffffffffffffffffffffffffff;
        //  maxExpArray[16] = 0x373fc47fffffffffffffffffffffffffff;
        //  maxExpArray[17] = 0x34f9e8ffffffffffffffffffffffffffff;
        //  maxExpArray[18] = 0x32cbfd5fffffffffffffffffffffffffff;
        //  maxExpArray[19] = 0x30b5057fffffffffffffffffffffffffff;
        //  maxExpArray[20] = 0x2eb40f9fffffffffffffffffffffffffff;
        //  maxExpArray[21] = 0x2cc8340fffffffffffffffffffffffffff;
        //  maxExpArray[22] = 0x2af09481ffffffffffffffffffffffffff;
        //  maxExpArray[23] = 0x292c5bddffffffffffffffffffffffffff;
        //  maxExpArray[24] = 0x277abdcdffffffffffffffffffffffffff;
        //  maxExpArray[25] = 0x25daf6657fffffffffffffffffffffffff;
        //  maxExpArray[26] = 0x244c49c65fffffffffffffffffffffffff;
        //  maxExpArray[27] = 0x22ce03cd5fffffffffffffffffffffffff;
        //  maxExpArray[28] = 0x215f77c047ffffffffffffffffffffffff;
        //  maxExpArray[29] = 0x1fffffffffffffffffffffffffffffffff;
        //  maxExpArray[30] = 0x1eaefdbdabffffffffffffffffffffffff;
        //  maxExpArray[31] = 0x1d6bd8b2ebffffffffffffffffffffffff;
        maxExpArray[32] = 0x1c35fedd14ffffffffffffffffffffffff;
        maxExpArray[33] = 0x1b0ce43b323fffffffffffffffffffffff;
        maxExpArray[34] = 0x19f0028ec1ffffffffffffffffffffffff;
        maxExpArray[35] = 0x18ded91f0e7fffffffffffffffffffffff;
        maxExpArray[36] = 0x17d8ec7f0417ffffffffffffffffffffff;
        maxExpArray[37] = 0x16ddc6556cdbffffffffffffffffffffff;
        maxExpArray[38] = 0x15ecf52776a1ffffffffffffffffffffff;
        maxExpArray[39] = 0x15060c256cb2ffffffffffffffffffffff;
        maxExpArray[40] = 0x1428a2f98d72ffffffffffffffffffffff;
        maxExpArray[41] = 0x13545598e5c23fffffffffffffffffffff;
        maxExpArray[42] = 0x1288c4161ce1dfffffffffffffffffffff;
        maxExpArray[43] = 0x11c592761c666fffffffffffffffffffff;
        maxExpArray[44] = 0x110a688680a757ffffffffffffffffffff;
        maxExpArray[45] = 0x1056f1b5bedf77ffffffffffffffffffff;
        maxExpArray[46] = 0x0faadceceeff8bffffffffffffffffffff;
        maxExpArray[47] = 0x0f05dc6b27edadffffffffffffffffffff;
        maxExpArray[48] = 0x0e67a5a25da4107fffffffffffffffffff;
        maxExpArray[49] = 0x0dcff115b14eedffffffffffffffffffff;
        maxExpArray[50] = 0x0d3e7a392431239fffffffffffffffffff;
        maxExpArray[51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
        maxExpArray[52] = 0x0c2d415c3db974afffffffffffffffffff;
        maxExpArray[53] = 0x0bad03e7d883f69bffffffffffffffffff;
        maxExpArray[54] = 0x0b320d03b2c343d5ffffffffffffffffff;
        maxExpArray[55] = 0x0abc25204e02828dffffffffffffffffff;
        maxExpArray[56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
        maxExpArray[57] = 0x09deaf736ac1f569ffffffffffffffffff;
        maxExpArray[58] = 0x0976bd9952c7aa957fffffffffffffffff;
        maxExpArray[59] = 0x09131271922eaa606fffffffffffffffff;
        maxExpArray[60] = 0x08b380f3558668c46fffffffffffffffff;
        maxExpArray[61] = 0x0857ddf0117efa215bffffffffffffffff;
        maxExpArray[62] = 0x07ffffffffffffffffffffffffffffffff;
        maxExpArray[63] = 0x07abbf6f6abb9d087fffffffffffffffff;
        maxExpArray[64] = 0x075af62cbac95f7dfa7fffffffffffffff;
        maxExpArray[65] = 0x070d7fb7452e187ac13fffffffffffffff;
        maxExpArray[66] = 0x06c3390ecc8af379295fffffffffffffff;
        maxExpArray[67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
        maxExpArray[68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
        maxExpArray[69] = 0x05f63b1fc104dbd39587ffffffffffffff;
        maxExpArray[70] = 0x05b771955b36e12f7235ffffffffffffff;
        maxExpArray[71] = 0x057b3d49dda84556d6f6ffffffffffffff;
        maxExpArray[72] = 0x054183095b2c8ececf30ffffffffffffff;
        maxExpArray[73] = 0x050a28be635ca2b888f77fffffffffffff;
        maxExpArray[74] = 0x04d5156639708c9db33c3fffffffffffff;
        maxExpArray[75] = 0x04a23105873875bd52dfdfffffffffffff;
        maxExpArray[76] = 0x0471649d87199aa990756fffffffffffff;
        maxExpArray[77] = 0x04429a21a029d4c1457cfbffffffffffff;
        maxExpArray[78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
        maxExpArray[79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
        maxExpArray[80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
        maxExpArray[81] = 0x0399e96897690418f785257fffffffffff;
        maxExpArray[82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
        maxExpArray[83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
        maxExpArray[84] = 0x032cbfd4a7adc790560b3337ffffffffff;
        maxExpArray[85] = 0x030b50570f6e5d2acca94613ffffffffff;
        maxExpArray[86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
        maxExpArray[87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
        maxExpArray[88] = 0x02af09481380a0a35cf1ba02ffffffffff;
        maxExpArray[89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
        maxExpArray[90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
        maxExpArray[91] = 0x025daf6654b1eaa55fd64df5efffffffff;
        maxExpArray[92] = 0x0244c49c648baa98192dce88b7ffffffff;
        maxExpArray[93] = 0x022ce03cd5619a311b2471268bffffffff;
        maxExpArray[94] = 0x0215f77c045fbe885654a44a0fffffffff;
        maxExpArray[95] = 0x01ffffffffffffffffffffffffffffffff;
        maxExpArray[96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
        maxExpArray[97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
        maxExpArray[98] = 0x01c35fedd14b861eb0443f7f133fffffff;
        maxExpArray[99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
        maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
        maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
        maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
        maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
        maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
        maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
        maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
        maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
        maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
        maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
        maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
        maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
        maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
        maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
        maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
        maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
        maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
        maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
        maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
        maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
        maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
        maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
        maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
        maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
        maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
        maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
        maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
        maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
    }

    /**
      General Description:
          Determine a value of precision.
          Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
          Return the result along with the precision used.
       Detailed Description:
          Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
          The value of "log(base)" is represented with an integer slightly smaller than "log(base) * 2 ^ precision".
          The larger "precision" is, the more accurately this value represents the real value.
          However, the larger "precision" is, the more bits are required in order to store this value.
          And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
          This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
          Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
          This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
          This functions assumes that "_expN < 2 ^ 256 / log(MAX_NUM - 1)", otherwise the multiplication should be replaced with a "safeMul".
    */
    function power(
        uint256 _baseN,
        uint256 _baseD,
        uint32 _expN,
        uint32 _expD
    ) internal view returns (uint256, uint8)
    {
        assert(_baseN < MAX_NUM);
        require(_baseN >= _baseD, "Bases < 1 are not supported.");

        uint256 baseLog;
        uint256 base = _baseN * FIXED_1 / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        } else {
            baseLog = generalLog(base);
        }

        uint256 baseLogTimesExp = baseLog * _expN / _expD;
        if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
            return (optimalExp(baseLogTimesExp), MAX_PRECISION);
        } else {
            uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
            return (generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision), precision);
        }
    }

    /**
        Compute log(x / FIXED_1) * FIXED_1.
        This functions assumes that "x >= FIXED_1", because the output would be negative otherwise.
    */
    function generalLog(uint256 _x) internal pure returns (uint256) {
        uint256 res = 0;
        uint256 x = _x;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += ONE << (i - 1);
                }
            }
        }

        return res * LN2_NUMERATOR / LN2_DENOMINATOR;
    }

    /**
      Compute the largest integer smaller than or equal to the binary logarithm of the input.
    */
    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;
        uint256 n = _n;

        if (n < 256) {
            // At most 8 iterations
            while (n > 1) {
                n >>= 1;
                res += 1;
            }
        } else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (n >= (ONE << s)) {
                    n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    /**
        The global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
        - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
        - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
    */
    function findPositionInMaxExpArray(uint256 _x)
    internal view returns (uint8)
    {
        uint8 lo = MIN_PRECISION;
        uint8 hi = MAX_PRECISION;

        while (lo + 1 < hi) {
            uint8 mid = (lo + hi) / 2;
            if (maxExpArray[mid] >= _x)
                lo = mid;
            else
                hi = mid;
        }

        if (maxExpArray[hi] >= _x)
            return hi;
        if (maxExpArray[lo] >= _x)
            return lo;

        assert(false);
        return 0;
    }

    /* solium-disable */
    /**
         This function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
         It approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
         It returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
         The global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
         The maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     */
    function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision; res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
        xi = (xi * _x) >> _precision; res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
        xi = (xi * _x) >> _precision; res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
        xi = (xi * _x) >> _precision; res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
        xi = (xi * _x) >> _precision; res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
        xi = (xi * _x) >> _precision; res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
        xi = (xi * _x) >> _precision; res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
        xi = (xi * _x) >> _precision; res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

        return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }

    /**
        Return log(x / FIXED_1) * FIXED_1
        Input range: FIXED_1 <= x <= LOG_EXP_MAX_VAL - 1
        Auto-generated via 'PrintFunctionOptimalLog.py'
    */
    function optimalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {res += 0x40000000000000000000000000000000; x = x * FIXED_1 / 0xd3094c70f034de4b96ff7d5b6f99fcd8;}
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {res += 0x20000000000000000000000000000000; x = x * FIXED_1 / 0xa45af1e1f40c333b3de1db4dd55f29a7;}
        if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {res += 0x10000000000000000000000000000000; x = x * FIXED_1 / 0x910b022db7ae67ce76b441c27035c6a1;}
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {res += 0x08000000000000000000000000000000; x = x * FIXED_1 / 0x88415abbe9a76bead8d00cf112e4d4a8;}
        if (x >= 0x84102b00893f64c705e841d5d4064bd3) {res += 0x04000000000000000000000000000000; x = x * FIXED_1 / 0x84102b00893f64c705e841d5d4064bd3;}
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {res += 0x02000000000000000000000000000000; x = x * FIXED_1 / 0x8204055aaef1c8bd5c3259f4822735a2;}
        if (x >= 0x810100ab00222d861931c15e39b44e99) {res += 0x01000000000000000000000000000000; x = x * FIXED_1 / 0x810100ab00222d861931c15e39b44e99;}
        if (x >= 0x808040155aabbbe9451521693554f733) {res += 0x00800000000000000000000000000000; x = x * FIXED_1 / 0x808040155aabbbe9451521693554f733;}

        z = y = x - FIXED_1;
        w = y * y / FIXED_1;
        res += z * (0x100000000000000000000000000000000 - y) / 0x100000000000000000000000000000000; z = z * w / FIXED_1;
        res += z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y) / 0x200000000000000000000000000000000; z = z * w / FIXED_1;
        res += z * (0x099999999999999999999999999999999 - y) / 0x300000000000000000000000000000000; z = z * w / FIXED_1;
        res += z * (0x092492492492492492492492492492492 - y) / 0x400000000000000000000000000000000; z = z * w / FIXED_1;
        res += z * (0x08e38e38e38e38e38e38e38e38e38e38e - y) / 0x500000000000000000000000000000000; z = z * w / FIXED_1;
        res += z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y) / 0x600000000000000000000000000000000; z = z * w / FIXED_1;
        res += z * (0x089d89d89d89d89d89d89d89d89d89d89 - y) / 0x700000000000000000000000000000000; z = z * w / FIXED_1;
        res += z * (0x088888888888888888888888888888888 - y) / 0x800000000000000000000000000000000;

        return res;
    }

    /**
        Return e ^ (x / FIXED_1) * FIXED_1
        Input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
        Auto-generated via 'PrintFunctionOptimalExp.py'
    */
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000;
        z = z * y / FIXED_1; res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = z * y / FIXED_1; res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = z * y / FIXED_1; res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = z * y / FIXED_1; res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = z * y / FIXED_1; res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = z * y / FIXED_1; res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = z * y / FIXED_1; res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = z * y / FIXED_1; res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = z * y / FIXED_1; res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = z * y / FIXED_1; res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = z * y / FIXED_1; res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = z * y / FIXED_1; res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = z * y / FIXED_1; res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = z * y / FIXED_1; res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = z * y / FIXED_1; res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = z * y / FIXED_1; res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = z * y / FIXED_1; res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = z * y / FIXED_1; res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = z * y / FIXED_1; res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0) res = res * 0x1c3d6a24ed82218787d624d3e5eba95f9 / 0x18ebef9eac820ae8682b9793ac6d1e776;
        if ((x & 0x020000000000000000000000000000000) != 0) res = res * 0x18ebef9eac820ae8682b9793ac6d1e778 / 0x1368b2fc6f9609fe7aceb46aa619baed4;
        if ((x & 0x040000000000000000000000000000000) != 0) res = res * 0x1368b2fc6f9609fe7aceb46aa619baed5 / 0x0bc5ab1b16779be3575bd8f0520a9f21f;
        if ((x & 0x080000000000000000000000000000000) != 0) res = res * 0x0bc5ab1b16779be3575bd8f0520a9f21e / 0x0454aaa8efe072e7f6ddbab84b40a55c9;
        if ((x & 0x100000000000000000000000000000000) != 0) res = res * 0x0454aaa8efe072e7f6ddbab84b40a55c5 / 0x00960aadc109e7a3bf4578099615711ea;
        if ((x & 0x200000000000000000000000000000000) != 0) res = res * 0x00960aadc109e7a3bf4578099615711d7 / 0x0002bf84208204f5977f9a8cf01fdce3d;
        if ((x & 0x400000000000000000000000000000000) != 0) res = res * 0x0002bf84208204f5977f9a8cf01fdc307 / 0x0000003c6ab775dd0b95b4cbee7e65d11;

        return res;
    }
    /* solium-enable */
}


// File contracts/utils/BancorFormula.sol

//

pragma solidity 0.8.9;

/**
* @title Bancor formula by Bancor
* @dev Modified from the original by Slava Balasanov
* https://github.com/bancorprotocol/contracts
* Split Power.sol out from BancorFormula.sol and replace SafeMath formulas with zeppelin's SafeMath
* Licensed to the Apache Software Foundation (ASF) under one or more contributor license agreements;
* and to You under the Apache License, Version 2.0. "
*/
contract BancorFormula is Power {
    string public version = "0.3";
    uint32 private constant MAX_WEIGHT = 1000000;

    /**
    * @dev given a token supply, connector balance, weight and a deposit amount (in the connector token),
    * calculates the return for a given conversion (in the main token)
    *
    * Formula:
    * Return = _supply * ((1 + _depositAmount / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)
    *
    * @param _supply              token total supply
    * @param _connectorBalance    total connector balance
    * @param _connectorWeight     connector weight, represented in ppm, 1-1000000
    * @param _depositAmount       deposit amount, in connector token
    *
    *  @return purchase return amount
    */
    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _connectorBalance,
        uint32 _connectorWeight,
        uint256 _depositAmount) public view returns (uint256)
    {
        // validate input
        require(_supply > 0, "BancorFormula: Supply not > 0.");
        require(_connectorBalance > 0, "BancorFormula: ConnectorBalance not > 0");
        require(_connectorWeight > 0, "BancorFormula: Connector Weight not > 0");
        require(_connectorWeight <= MAX_WEIGHT, "BancorFormula: Connector Weight not <= MAX_WEIGHT");

        // special case for 0 deposit amount
        if (_depositAmount == 0) {
            return 0;
        }
        // special case if the weight = 100%
        if (_connectorWeight == MAX_WEIGHT) {
            return _supply * _depositAmount / _connectorBalance;
        }
        uint256 result;
        uint8 precision;
        uint256 baseN = _depositAmount + _connectorBalance;
        (result, precision) = power(
            baseN, _connectorBalance, _connectorWeight, MAX_WEIGHT
        );
        uint256 newTokenSupply = _supply * result >> precision;
        return newTokenSupply - _supply;
    }

    /**
    * @dev given a token supply, connector balance, weight and a sell amount (in the main token),
    * calculates the return for a given conversion (in the connector token)
    *
    * Formula:
    * Return = _connectorBalance * (1 - (1 - _sellAmount / _supply) ^ (1 / (_connectorWeight / 1000000)))
    *
    * @param _supply              token total supply
    * @param _connectorBalance    total connector
    * @param _connectorWeight     constant connector Weight, represented in ppm, 1-1000000
    * @param _sellAmount          sell amount, in the token itself
    *
    * @return sale return amount
    */
    function calculateSaleReturn(
        uint256 _supply,
        uint256 _connectorBalance,
        uint32 _connectorWeight,
        uint256 _sellAmount) public view returns (uint256)
    {
        // validate input
        require(_supply > 0, "BancorFormula: Supply not > 0.");
        require(_connectorBalance > 0, "BancorFormula: ConnectorBalance not > 0");
        require(_connectorWeight > 0, "BancorFormula: Connector Weight not > 0");
        require(_connectorWeight <= MAX_WEIGHT, "BancorFormula: Connector Weight not <= MAX_WEIGHT");
        require(_sellAmount <= _supply, "BancorFormula: Sell Amount not <= Supply");

        // special case for 0 sell amount
        if (_sellAmount == 0) {
            return 0;
        }
        // special case for selling the entire supply
        if (_sellAmount == _supply) {
            return _connectorBalance;
        }
        // special case if the weight = 100%
        if (_connectorWeight == MAX_WEIGHT) {
            return _connectorBalance * _sellAmount / _supply;
        }
        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _sellAmount;
        (result, precision) = power(
            _supply, baseD, MAX_WEIGHT, _connectorWeight
        );
        uint256 oldBalance = _connectorBalance * result;
        uint256 newBalance = _connectorBalance << precision;
        return (oldBalance - newBalance) / result;
    }
}


// File contracts/utils/BondingCurveToken.sol

//

pragma solidity 0.8.9;


/**
 * @title Bonding Curve
 * @dev Bonding curve contract based on Bacor formula
 * inspired by bancor protocol and simondlr
 * https://github.com/bancorprotocol/contracts
 * https://github.com/ConsenSys/curationmarkets/blob/master/CurationMarkets.sol
 */
abstract contract BondingCurveToken is ERC20, BancorFormula {
    /*
      reserve ratio, represented in ppm, 1-1000000
      1/3 corresponds to y= multiple * x^2
      1/2 corresponds to y= multiple * x
      2/3 corresponds to y= multiple * x^1/2
      multiple will depends on contract initialization,
      specificallytotalAmount and poolBalance parameters
      we might want to add an 'initialize' function that will allow
      the owner to send ether to the contract and mint a given amount of tokens
    */
    uint32 public reserveRatio;

    /*
      - Front-running attacks are currently mitigated by the following mechanisms:
      TODO - minimum return argument for each conversion
      provides a way to define a minimum/maximum price for the transaction
      - gas price limit prevents users from having control over the order of execution
    */
    uint256 public gasPrice; // maximum gas price for bancor transactions

    event CurvedMint(address sender, uint256 amount, uint256 deposit);
    event CurvedBurn(address sender, uint256 amount, uint256 reimbursement);

    constructor(uint32 _reserveRatio, uint256 _gasPrice) {
        reserveRatio = _reserveRatio;
        gasPrice = _gasPrice;
    }

    function calculateCurvedMintReturn(uint256 amount) public view returns (uint256) {
        return calculatePurchaseReturn(totalSupply(), poolBalance(), reserveRatio, amount);
    }

    function calculateCurvedBurnReturn(uint256 amount) public view returns (uint256) {
        return calculateSaleReturn(totalSupply(), poolBalance(), reserveRatio, amount);
    }

    /**
     * @dev Mint tokens
     */
    function _curvedMint(uint256 deposit) internal returns (uint256) {
        return _curvedMintFor(msg.sender, deposit);
    }

    function _curvedMintFor(address user, uint256 deposit)
    validGasPrice
    validMint(deposit)
    internal
    returns (uint256)
    {
        uint256 amount = calculateCurvedMintReturn(deposit);
        _mint(user, amount);
        emit CurvedMint(user, amount, deposit);
        return amount;
    }

    /**
     * @dev Burn tokens
     * @param amount Amount of tokens to withdraw
     */
    function _curvedBurn(uint256 amount) internal returns (uint256) {
        return _curvedBurnFor(msg.sender, amount);
    }

    function _curvedBurnFor(address user, uint256 amount) validGasPrice validBurn(amount) internal returns (uint256) {
        uint256 reimbursement = calculateCurvedBurnReturn(amount);
        _burn(user, amount);
        emit CurvedBurn(user, amount, reimbursement);
        return reimbursement;
    }

    /**
      @dev Allows the owner to update the gas price limit
      @param _gasPrice The new gas price limit
    */
    function _setGasPrice(uint256 _gasPrice) internal {
        require(_gasPrice > 0);
        gasPrice = _gasPrice;
    }

    /**
     * @dev Abstract method that returns pool balance
     */
    function poolBalance() public virtual view returns (uint256);

    // verifies that the gas price is lower than the universal limit
    modifier validGasPrice() {
        assert(tx.gasprice <= gasPrice);
        _;
    }

    modifier validBurn(uint256 amount) {
        require(amount > 0 && balanceOf(msg.sender) >= amount);
        _;
    }

    modifier validMint(uint256 amount) {
        require(amount > 0);
        _;
    }
}


// File contracts/utils/ERC1404.sol

//

pragma solidity 0.8.9;

abstract contract ERC1404 is ERC20 {
    /// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    /// @dev Overwrite with your custom transfer restriction logic
    function detectTransferRestriction (address from, address to, uint256 value) public virtual view returns (uint8);

    /// @notice Returns a human-readable message for a given restriction code
    /// @param restrictionCode Identifier for looking up a message
    /// @return Text showing the restriction's reasoning
    /// @dev Overwrite with your custom message and restrictionCode handling
    function messageForTransferRestriction (uint8 restrictionCode) public virtual view returns (string memory);
}


// File contracts/SecurityToken.sol

//

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;


/// @title Contract that implements the Security Token to manage the Bonding Curve
/// @dev This Token is being bonded in the Bonding Curve to gain Coordination Token
///      which is being used in the games. Security Token is strictly managed and
///      only whitelisted stakeholders are allowed to own it.
///      Reference implementation of ERC1404 can be found here:
///      https://github.com/simple-restricted-token/reference-implementation/blob/master/contracts/token/ERC1404/ERC1404ReferenceImpl.sol
///      https://github.com/simple-restricted-token/simple-restricted-token/blob/master/contracts/token/ERC1404/SimpleRestrictedToken.sol
contract SecurityToken is ERC1404, Ownable {

    uint8 constant private SUCCESS_CODE = 0;
    uint8 constant private ERR_RECIPIENT_CODE = 1;
    uint8 constant private ERR_BONDING_CURVE_CODE = 2;
    uint8 constant private ERR_NOT_WHITELISTED_CODE = 3;
    string constant private SUCCESS_MESSAGE = "SecurityToken: SUCCESS";
    string constant private ERR_RECIPIENT_MESSAGE = "SecurityToken: RECIPIENT SHOULD BE IN THE WHITELIST";
    string constant private ERR_BONDING_CURVE_MESSAGE = "SecurityToken: CAN TRANSFER ONLY TO BONDING CURVE";
    string constant private ERR_NOT_WHITELISTED_MESSAGE = "SecurityToken: ONLY WHITELISTED USERS CAN TRANSFER TOKEN";


    struct Role {
        bool awo;
        bool sco;
    }

    mapping(address => Role) public operators;
    mapping(address => bool) public whitelist;
    address public bondingCurve;


    event NewStakeholder(address stakeholer);
    event RemovedStakeholder(address stakeholer);
    event NewSCO(address operator);
    event RemovedSCO(address operator);
    event NewAWO(address operator);
    event RemovedAWO(address operator);

    /// @dev Reverts if the caller is not a Securities Control Operator or an owner
    modifier onlySCOperator() {
        require(owner() == msg.sender || operators[msg.sender].sco == true,
            "SecurityToken: Only SC operators are allowed to mint/burn token");
        _;
    }

    /// @dev Reverts if the caller is not an Accreditation Whitelist Operator or an owner
    modifier onlyAWOperator() {
        require(owner() == msg.sender || operators[msg.sender].awo == true,
            "SecurityToken: Only AW operators are allowed to change whitelist");
        _;
    }

    /// @dev Checks if transfer of 'value' amount of tokens from 'from' to 'to' is allowed
    /// @param from address of token sender
    /// @param to address of token receiver
    /// @param value amount of tokens to transfer
    modifier notRestricted (address from, address to, uint256 value) {
        uint8 restrictionCode = detectTransferRestriction(from, to, value);
        require(restrictionCode == SUCCESS_CODE, messageForTransferRestriction(restrictionCode));
        _;
    }

    /// @notice Constructor function of the token
    /// @param name Name of the token as it will be in the ledger
    /// @param symbol Symbol that will represent the token
    constructor(string memory name, string memory symbol)  ERC20(name, symbol) {}

    /// @notice Function to add AWO
    /// @dev Only owner can add AWO
    /// @param operator Address of the AWO
    function addAWOperator(address operator) external onlyOwner{
        require(operators[operator].awo == false,
            "SecurityToken.addAWOperator: There already exists such operator");
        operators[operator].awo = true;
        emit NewAWO(operator);
    }

    /// @notice Function to add SCO
    /// @dev Only owner can add SCO
    /// @param operator Address of the SCO
    function addSCOperator(address operator) external onlyOwner{
        require(operators[operator].sco == false,
            "SecurityToken.addSCOperator: There already exists such operator");
        operators[operator].sco = true;
        emit NewSCO(operator);
    }

    /// @notice Function to remove AWO
    /// @dev Only owner can remove AWO
    /// @param operator Address of the AWO
    function removeAWOperator(address operator) external onlyOwner{
        require(operators[operator].awo == true,
            "SecurityToken.removeAWOperator: There is no such operator");
        operators[operator].awo = false;
        emit RemovedAWO(operator);
    }

    /// @notice Function to remove SCO
    /// @dev Only owner can remove SCO
    /// @param operator Address of the SCO
    function removeSCOperator(address operator) external onlyOwner{
        require(operators[operator].sco == true,
            "SecurityToken.removeSCOperator: There is no such operator");
        operators[operator].sco = false;
        emit RemovedSCO(operator);
    }

    /// @notice Function to mint SecurityToken
    /// @dev Only SCO can mint tokens to the whitelisted addresses
    /// @param account Address of the token receiver
    /// @param amount Amount of minted tokens
    function mint(address account, uint256 amount) external onlySCOperator{
        require(whitelist[account] == true,
            "SecurityToken.mint: Only whitelisted users can own tokens");
        _mint(account, amount);
    }

    /// @notice Function to burn SecurityToken
    /// @dev Only SCO can burn tokens from addresses
    /// @param account Address from which tokens will be burned
    /// @param amount Amount of burned tokens
    function burn(address account, uint256 amount) external onlySCOperator{
        _burn(account, amount);
    }

    /// @notice Function to add address to Whitelist
    /// @dev Only AWO can add address to Whitelist
    /// @param account Address to add to the Whitelist
    function addToWhitelist(address account) public onlyAWOperator{
        whitelist[account] = true;
        emit NewStakeholder(account);
    }

    /// @notice Function to remove address from Whitelist
    /// @dev Only AWO can remove address from Whitelist on removal from the list user loses all of the tokens
    /// @param account Address to remove from the Whitelist
    function removeFromWhitelist(address account) external onlyAWOperator{
        require(whitelist[account] == true,
            "SecurityToken.removeFromWhitelist: User is not on the Whitelist");
        require(account != bondingCurve,
            "SecurityToken.removeFromWhitelist: Can't remove bondingCurve");
        whitelist[account] = false;
        emit RemovedStakeholder(account);
    }

    /// @notice Function to check the restriction for token transfer
    /// @param from address of sender
    /// @param to address of receiver
    /// @param value amount of tokens to transfer
    /// @return restrictionCode code of restriction for specific transfer
    function detectTransferRestriction (address from, address to, uint256 value)
        public
        view
        override
        returns (uint8 restrictionCode)
    {
        require(value > 0, "SecurityToken: need to transfer more then 0.");
        if(from == bondingCurve){
            if(whitelist[to] == true){
                restrictionCode = SUCCESS_CODE;
            } else {
                restrictionCode = ERR_RECIPIENT_CODE;
            }
        } else if (whitelist[from]){
            if(to == bondingCurve){
                restrictionCode = SUCCESS_CODE;
            } else {
                restrictionCode = ERR_BONDING_CURVE_CODE;
            }
        } else{
            restrictionCode = ERR_NOT_WHITELISTED_CODE;
        }
    }


    /// @notice Function to return restriction message based on the code
    /// @param restrictionCode code of restriction
    /// @return message message of restriction for specific code
    function messageForTransferRestriction (uint8 restrictionCode)
        public
        pure
        override
        returns (string memory message)
    {
        if (restrictionCode == SUCCESS_CODE) {
            message = SUCCESS_MESSAGE;
        } else if (restrictionCode == ERR_RECIPIENT_CODE) {
            message = ERR_RECIPIENT_MESSAGE;
        } else if (restrictionCode == ERR_BONDING_CURVE_CODE) {
            message = ERR_BONDING_CURVE_MESSAGE;
        } else {
            message = ERR_NOT_WHITELISTED_MESSAGE;
        }
    }


    /// @notice Function to transfer tokens between whitelisted users
    /// @param to Address to which tokens are sent
    /// @param value Amount of tokens to send
    function transfer(address to, uint256 value)
        public
        override
        notRestricted(msg.sender, to, value)
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    /// @notice Function to transfer tokens from some another address(used after approve)
    /// @dev Only Whitelisted addresses that have the approval can send or receive tokens
    /// @param sender Address that will be used to send tokens from
    /// @param recipient Address that will receive tokens
    /// @param amount Amount of tokens that may be sent
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        override
        notRestricted(sender, recipient, amount)
        returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, msg.sender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    /// @notice Function to set BondingCurve address for the contract
    /// @param curve address of the BondingCurve
    function setupBondingCurve(address curve) external onlyOwner {
        whitelist[bondingCurve] = false;
        bondingCurve = curve;
        whitelist[bondingCurve] = true;
    }


    /// @notice Function to check if user is in a whitelist
    /// @param user Address to check
    /// @return If address is in a whitelist
    function isInWhitelist(address user) external view returns (bool) {
        return whitelist[user];
    }
}


// File contracts/CoordinationToken.sol

//

pragma solidity 0.8.9;



contract CoordinationToken is Ownable, BondingCurveToken {


    uint32 private constant MAX_RESERVE_RATIO = 1000000;
    uint256 private constant HUNDRED_PERCENT = 1e18;
    uint256 private constant COEFFICIENT = 1e9;
    uint256 private immutable phi; // 1e18 = 100%, 1e16 = 1%, 0 = 0%
    SecurityToken public immutable securityToken;
    uint256 internal _poolBalance;

    event BondedToMint(address indexed receiver, uint256 bonded, uint256 received);
    event BurnedToWithdraw(address indexed receiver, uint256 burned, uint256 received);

    /// @notice Constructor that defines BondingTokenCurve and ERC20 parameters
    /// @param token Address of Security token to bond
    /// @param fee fee percentage to pay
    /// @param gasPrice gasPrice limitation to prevent front running
    /// @notice BondingCurveToken is created with _reserveRatio 500000 to set:
    /// CoordinationTokenSupply ^ 2 = SecurityTokenSupply
    constructor(SecurityToken token, uint256 fee, uint256 gasPrice) BondingCurveToken(500000, gasPrice) ERC20("Coordination","CRD") {
        securityToken = token;
        require(fee<HUNDRED_PERCENT,
            "CoordinationToken: Fee needs to be lower then 100%");
        phi = fee;
    }

    /// @notice Function that bonds SecurityTokens to receive CoordinationTokens
    /// @param amountToBond Amount of Security token to bond
    /// @param minimalAmountToReceive Minimal amount of Security tokens to receive
    function bondToMint(uint256 amountToBond, uint256 minimalAmountToReceive) external {
        uint256 minted;
        if(totalSupply() == 0){
            minted = amountToBond;
            _mint(msg.sender, amountToBond);
            emit BondedToMint(msg.sender, amountToBond, amountToBond);
        } else {
            minted = _curvedMint(amountToBond);
            emit BondedToMint(msg.sender, amountToBond, minted);
        }
        require(minted >= minimalAmountToReceive,
            "CoordinationToken.bondToMint: Mints less tokens then expected");
        _poolBalance += amountToBond;
        require(securityToken.transferFrom(msg.sender, address(this), amountToBond),
            "CoordinationToken.bondToMint: Impossible to bond so much tokens");
    }

    /// @notice Function that withdraws SecurityTokens by burning CoordinationTokens
    /// @param amountToWithdraw Amount of Coordination tokens to withdraw
    /// @param minimalAmountToReceive Minimal amount of Security tokens to receive
    function burnToWithdraw(uint256 amountToWithdraw, uint256 minimalAmountToReceive) external {
        require(balanceOf(msg.sender) >= amountToWithdraw,
            "CoordinationToken.burnToWithdraw: Not enough funds to withdraw");
        uint256 currentFee = (amountToWithdraw * phi) / HUNDRED_PERCENT;
        _transfer(msg.sender, address(this), currentFee);
        uint256 burned = _curvedBurn(amountToWithdraw - currentFee);
        _poolBalance = _poolBalance - burned;
        require(burned >= minimalAmountToReceive,
            "CordinationToken.burnToWithdraw: Send less tokens then expected");
        require(securityToken.transfer(msg.sender, burned),
            "Failed to transfer SecurityTokens");
        emit BurnedToWithdraw(msg.sender, amountToWithdraw, burned);
    }

    /// @notice Function that returns the overall amount of bonded SecurityTokens
    /// @return Balance of SecurityTokens of the contract
    function poolBalance() public override view returns (uint256) {
        return _poolBalance;
    }

    function setGasPrice(uint256 gasPrice) public onlyOwner{
        _setGasPrice(gasPrice);
    }
}