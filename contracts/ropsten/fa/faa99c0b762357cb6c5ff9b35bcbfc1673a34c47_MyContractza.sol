/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

pragma solidity ^0.8.7;

interface IERC20zaa{ // defining an interface of the (external) token contract that you're going to be interacting with
    function decimals() external view returns (uint8);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}

contract MyContractza {
    function buy(address _to, uint _value) external {
        IERC20zaa tokenContract = IERC20zaa(address(0x3Ac63D5f78b90CfDbd7135A9b4b1b5Fd4ce9e8ab)); // the token contract address

        // reverts if the transfer wasn't successful
        require(
            tokenContract.transferFrom(
                msg.sender, // from the user
                _to, // to this contract
                _value * (10 ** tokenContract.decimals()) // 50 tokens, incl. decimals of the token contract
            ) == true,
            'Could not transfer tokens from your address to this contract' // error message in case the transfer was not successful
        );
        
        // transfer was successful, rest of your code
    }
}