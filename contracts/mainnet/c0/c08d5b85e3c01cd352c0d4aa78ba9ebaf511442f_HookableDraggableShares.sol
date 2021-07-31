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

import "./ERC20Hookable.sol";
import "./ERC20Recoverable.sol";
import "./ERC20Draggable.sol";
import "./ERC20Named.sol";

/**
 * @author Luzius Meisser, [email protected]
 */
contract HookableDraggableShares is ERC20Draggable, ERC20Recoverable, ERC20Hookable, ERC20Named {

    string public terms;

    constructor(address admin, string memory name_, string memory symbol_, string memory _terms, address wrappedToken, uint256 quorumBps, uint256 votePeriodSeconds) 
        ERC20Draggable(wrappedToken, quorumBps, votePeriodSeconds) ERC20Named(admin, name_, symbol_, 0) {
        terms = _terms;
    }

    function transfer(address to, uint256 value) virtual override(ERC20Recoverable, ERC20) public returns (bool) {
        return super.transfer(to, value);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) virtual override(ERC20Draggable, ERC20Hookable, ERC20) internal {
        super._beforeTokenTransfer(from, to, amount);
    }

    function getClaimDeleter() public override view returns (address) {
        return this.owner();
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
}

abstract contract IRecoverable {
    function getCollateralRate(address) public virtual view returns (uint256);
    function getClaimDeleter() public virtual view returns (address);
}