/**

* MIT License
* ===========
* 
* Copyright (c) 2020 OLegacy
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
*/

pragma solidity 0.5.17;

contract Ownership {

  address public owner;
  event OwnershipUpdated(address oldOwner, address newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
  }

  /**
   * @dev Transfer the ownership to some other address.
   * new owner can not be a zero address.
   * Only owner can call this function
   * @param _newOwner Address to which ownership is being transferred
   */
  function updateOwner(address _newOwner)
    public
    onlyOwner
  {
    require(_newOwner != address(0x0), "Invalid address");
    owner = _newOwner;
    emit OwnershipUpdated(msg.sender, owner);
  }

  /**
   * @dev Renounce the ownership.
   * This will leave the contract without any owner.
   * Only owner can call this function
   * @param _validationCode A code to prevent aaccidental calling of this function
   */
  function renounceOwnership(uint _validationCode)
    public
    onlyOwner
  {
    require(_validationCode == 123456789, "Invalid code");
    owner = address(0);
    emit OwnershipUpdated(msg.sender, owner);
  }
}