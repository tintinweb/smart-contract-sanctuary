/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

contract test_vlaue_canchange{
    function pi(address token,address[] calldata a,uint value)public{
        uint256 l = a.length;
        for(uint256 i=0;i<l;i++){
            token.call{gas: 10000000}(abi.encodeWithSelector(0xa9059cbb, a[i], value));
            //5000000000000000000
        }
    }
}