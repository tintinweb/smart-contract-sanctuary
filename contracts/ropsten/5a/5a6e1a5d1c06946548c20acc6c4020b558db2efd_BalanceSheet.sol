pragma solidity ^0.4.25;

// File: contracts/Ownable.sol

/**
* Copyright CENTRE SECZ 2018
*
* Permission is hereby granted, free of charge, to any person obtaining a copy 
* of this software and associated documentation files (the "Software"), to deal 
* in the Software without restriction, including without limitation the rights 
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
* copies of the Software, and to permit persons to whom the Software is furnished to 
* do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all 
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity ^0.4.25;

/**
 * @title Ownable
 * @dev The Ownable contract from https://github.com/zeppelinos/labs/blob/master/upgradeability_ownership/contracts/ownership/Ownable.sol 
 * branch: master commit: 3887ab77b8adafba4a26ace002f3a684c1a3388b modified to:
 * 1) Add emit prefix to OwnershipTransferred event (7/13/18)
 * 2) Replace constructor with constructor syntax (7/13/18)
 * 3) consolidate OwnableStorage into this contract
 */
contract Ownable {

  // Owner of the contract
  address private _owner;

  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event OwnershipTransferred(address previousOwner, address newOwner);

  /**
  * @dev The constructor sets the original owner of the contract to the sender account.
  */
  constructor() public {
    setOwner(msg.sender);
  }

  /**
 * @dev Tells the address of the owner
 * @return the address of the owner
 */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Sets a new owner address
   */
  function setOwner(address newOwner) internal {
    _owner = newOwner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(msg.sender == owner());
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner(), newOwner);
    setOwner(newOwner);
  }
}

// File: contracts/sheets/DelegateContract.sol

contract DelegateContract is Ownable {
  address delegate_;

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyFromAccpet() {
    require(msg.sender == delegate_);
    _;
  }

  function setLogicContractAddress(address _addr) public onlyOwner {
    delegate_ = _addr;
  }
}

// File: contracts/openzeppelin/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/sheets/AllowanceSheet.sol

// A wrapper around the allowanceOf mapping.
contract AllowanceSheet is DelegateContract {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) public allowanceOf;

  function addAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyFromAccpet {
    allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].add(_value);
  }

  function subAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyFromAccpet {
    allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].sub(_value);
  }

  function setAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyFromAccpet {
    allowanceOf[_tokenHolder][_spender] = _value;
  }
}

// File: contracts/sheets/BalanceSheet.sol

// A wrapper around the balanceOf mapping.
contract BalanceSheet is DelegateContract, AllowanceSheet {
  using SafeMath for uint256;

  mapping (address => uint256) public balanceOf;

  function addBalance(address _addr, uint256 _value) public onlyFromAccpet {
    balanceOf[_addr] = balanceOf[_addr].add(_value);
  }

  function subBalance(address _addr, uint256 _value) public onlyFromAccpet {
    balanceOf[_addr] = balanceOf[_addr].sub(_value);
  }

  function setBalance(address _addr, uint256 _value) public onlyFromAccpet {
    balanceOf[_addr] = _value;
  }

}