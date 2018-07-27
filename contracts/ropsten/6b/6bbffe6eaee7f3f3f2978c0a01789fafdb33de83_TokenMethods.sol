// @notice ERC20 function for balance of the token
// @dev any token implementing the ERC20 standard will be compatible
contract TokenBalance {
    function balanceOf(address) external returns (uint256) {}
}
// @title TokenMethods is a library of token related functions 
library TokenMethods {

    // @dev returns balance of the specified ERC20 token for this contract/address
    // @param _token address of the ERC20 token
    function balanceThis(address _token) public returns (uint256) {
        return TokenBalance(_token).balanceOf(address(this));
    }

    // @dev returns balance of the specified ERC20 token for this the function caller
    // @param _token address of the ERC20 token
    function balanceSender(address _token) public returns (uint256) {
        return balanceAddress(_token, msg.sender);
    }

    // @dev returns balance of the specified ERC20 token for the specified tokenHolder
    // @dev alternatively, the _token contract itself could be called to get this data
    // @param _token address of the ERC20 token
    // @param _tokenHolder address of the ERC20 tokenHolder
    function balanceAddress(address _token, address _tokenHolder) public returns (uint256) {
        return (TokenBalance(_token).balanceOf(_tokenHolder));
    }

}