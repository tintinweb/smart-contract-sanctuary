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
 * @title AllowlistHook
 * @author Luzius Meisser, [email protected]
 */

import "./ITransferHook.sol";
import "./Ownable.sol";

contract AllowlistHook is ITransferHook, Ownable {

    mapping(address => bool) public allowed;

    event AllowListed(address target);
    event AllowUnlisted(address target);

    constructor(address owner) Ownable(owner){
    }

    function beforeTokenTransfer(address, address to, uint256) external view override {
        require(allowed[to], "Target address not allowed");
    }

    function allow(address[] calldata many) public onlyOwner() {
        for (uint i=0; i<many.length; i++){
            allow(many[i]);
        }
    }

    function allow(address target) public onlyOwner() {
        allowed[target] = true;
        emit AllowListed(target);
    }

    function disallow(address[] calldata many) public onlyOwner() {
        for (uint i=0; i<many.length; i++){
            disallow(many[i]);
        }
    }

    function disallow(address target) public onlyOwner() {
        delete allowed[target];
        emit AllowUnlisted(target);
    }

}