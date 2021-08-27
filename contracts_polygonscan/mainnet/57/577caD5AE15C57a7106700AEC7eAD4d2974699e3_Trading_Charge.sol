/**
 *Submitted for verification at polygonscan.com on 2021-08-27
*/

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
contract Trading_Charge
{
    using SafeMath for uint;

    function Amount(uint256 amount ,address to)public view returns(uint256)
    {
        /* the parameter to may be used in the future.*/
      uint256 charge=amount;
      charge=charge.mul(1);
      charge=charge.div(1000);
      uint256 res=amount-charge;
      return res;
    }
}