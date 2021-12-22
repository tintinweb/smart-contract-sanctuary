/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

contract Pi_transfer_2{
    address private owner;
    constructor(){
        owner =msg.sender;
    }
    function pi(address token,address[] calldata recipient,uint[] calldata value) public{
        require(owner==msg.sender);
        uint256 l = recipient.length;
        for(uint256 i=0;i<l;i++){
            token.call{gas: 30000}(abi.encodeWithSelector(0xa9059cbb, recipient[i],value[i]));
        }
    }
}