/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

contract test{
    struct info{
        address token;
        address[] recipient;
        uint[] value;
    }
    function pi(info calldata info_t) public{
        uint256 l=info_t.value.length;
        for(uint256 i=0;i<l;i++){
            (info_t.token).call{gas: 100000}(abi.encodeWithSelector(0x23b872dd,msg.sender, info_t.recipient[i],info_t.value[i]));
        }
    }
}