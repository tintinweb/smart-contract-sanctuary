/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

contract ERC20Interface {
    function balanceOf(address whom) view public returns (uint);
}

contract Example {

    function queryERC20Balance(address _tokenAddress, address _addressToQuery) view public returns (uint) {
        return ERC20Interface(_tokenAddress).balanceOf(_addressToQuery);
    }

}