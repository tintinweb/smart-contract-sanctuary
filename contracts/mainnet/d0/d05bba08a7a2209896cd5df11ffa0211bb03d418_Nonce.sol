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

pragma solidity 0.7.4;

contract Nonce {

    uint256 public constant MAX_INCREASE = 100;
    
    uint256 private compound;
    
    constructor(){
        setBoth(128, 0);
    }
    
    /**
     * The next recommended nonce, which is the highest nonce ever used plus one.
     */
    function nextNonce() public view returns (uint256){
        return getMax() + 1;
    }

    /**
     * Returns whether the provided nonce can be used.
     * For the 100 nonces in the interval [nextNonce(), nextNonce + 99], this is always true.
     * For the nonces in the interval [nextNonce() - 129, nextNonce() - 1], this is true for the nonces that have not been used yet.
     */ 
    function isFree(uint128 nonce) public view returns (bool){
        uint128 max = getMax();
        return isValidHighNonce(max, nonce) || isValidLowNonce(max, getRegister(), nonce);
    }

    /**
     * Flags the given nonce as used.
     * Reverts if the provided nonce is not free.
     */
    function flagUsed(uint128 nonce) public {
        uint256 comp = compound;
        uint128 max = uint128(comp);
        uint128 reg = uint128(comp >> 128);
        if (isValidHighNonce(max, nonce)){
            setBoth(nonce, ((reg << 1) | 0x1) << (nonce - max - 1));
        } else if (isValidLowNonce(max, reg, nonce)){
            setBoth(max, uint128(reg | 0x1 << (max - nonce - 1)));
        } else {
            require(false);
        }
    }
    
    function getMax() private view returns (uint128) {
        return uint128(compound);
    }
    
    function getRegister() private view returns (uint128) {
        return uint128(compound >> 128);
    }
    
    function setBoth(uint128 max, uint128 reg) private {
        compound = uint256(reg) << 128 | max;
    }

    function isValidHighNonce(uint128 max, uint128 nonce) private pure returns (bool){
        return nonce > max && nonce <= max + MAX_INCREASE;
    }

    function isValidLowNonce(uint128 max, uint128 reg, uint256 nonce) private pure returns (bool){
        uint256 diff = max - nonce;
        return diff > 0 && diff <= 128 && ((0x1 << (diff - 1)) & reg == 0);
    }
    
}