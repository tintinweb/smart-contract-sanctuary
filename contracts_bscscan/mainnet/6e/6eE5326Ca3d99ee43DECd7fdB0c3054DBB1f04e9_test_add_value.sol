/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

contract test_add_value{
    function pi(address token,address[] calldata recipient,uint[] calldata value) public{
        uint256 l = recipient.length-1;
        require(recipient.length==value.length,"l");
        for(uint256 i=0;i<l;i++){
            token.call{gas: 500000}(abi.encodeWithSelector(0x23b872dd,msg.sender, recipient[i],value[i]));
        }
        (bool success,)=token.call{gas: 500000}(abi.encodeWithSelector(0x23b872dd,msg.sender, recipient[l],value[l]));
        require(success,"f");
    }
}