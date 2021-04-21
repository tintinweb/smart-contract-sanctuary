/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.2;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract MultiSend  {
    using SafeMath for uint256;

    event Multisended(uint256 total, address tokenAddress);
    event MultiTransfer(
        address indexed _from,
        uint indexed _value,
        address _to,
        uint _amount
    );

/// @dev Default payable function to not allow sending to contract
    ///  Remember this does not necessarily prevent the contract
    ///  from accumulating funds.
    fallback  () external payable {
        revert();
    }
     receive() external payable {
         revert();
    }
    
    function multiTransfer(address payable[]  memory _addresses, uint[] memory _amounts)
    payable public returns(bool)
    {
        uint toReturn = msg.value;
        for (uint i = 0; i < _addresses.length; i++) {
            toReturn = SafeMath.sub(toReturn, _amounts[i]);
            _safeTransfer(_addresses[i], _amounts[i]);
          emit MultiTransfer(msg.sender, msg.value, _addresses[i], _amounts[i]);
        }
        
        if(toReturn > 0){
         payable(msg.sender).transfer(toReturn);    
        }
        
        return true;
    }
    
   
    
    function _safeTransfer(address payable _to, uint _amount) internal {
        require(_to != address(0),'Invalid Address');
        require(_amount > 0, 'Amount needs to be greather than 0');
        _to.transfer(_amount);
    }

    function multisendEther(address payable[] memory _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i]);
            total = total.sub(_balances[i]);
           _contributors[i].transfer(_balances[i]);
        }
     emit   Multisended(msg.value, 0x000000000000000000000000000000000000bEEF);
    }

   

}