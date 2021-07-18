/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

//   send tokens to this address and see 







contract ERC20 {
    function transfer(address _recipient, uint256 amount) public;
}       
contract Testbro {
    function multiTransfer(ERC20 token, address[] _addresses, uint256 amount) public {
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transfer(_addresses[i], amount);
        }
    }
}