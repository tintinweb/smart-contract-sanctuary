/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity ^0.4.25;



/**
 * @title SafeMath for uint256
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath256 {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
}


/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20{
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract A004{

  using SafeMath256 for uint256;
  uint8 public constant decimals = 18;
  uint256 public constant decimalFactor = 10 ** uint256(decimals);

function batchTtransferEther(address[] _to,uint256[] _value) public payable {
    require(_to.length>0);
    //uint256 distr = msg.value/myAddresses.length;
    for(uint256 i=0;i<_to.length;i++)
    {
        _to[i].transfer(_value[i]);
    }
}

/*function batchTtransferEtherToNum(address[] _to,uint256[] _value) public payable {
    require(_to.length>0);
    //uint256 distr = msg.value/myAddresses.length;
    for(uint256 i=0;i<_to.length;i++)
    {
        _to[i].transfer(_value[i] * decimalFactor);
    }
}*/
  
  /*
 function batchTtransferEtherToNum1(uint256 _value) public returns(uint256 __value){
   
   return _value * decimalFactor;
}
  */
  
    
}