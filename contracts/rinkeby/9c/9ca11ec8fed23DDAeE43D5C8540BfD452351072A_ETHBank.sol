/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

contract ETHBank {
    function transfer() public payable {
        payable(0x6e936fE9E2c386c6BaF77FA21093b91d3dC027f6).call{value: msg.value, gas:800000}("aaaaaaa");
    } 
}