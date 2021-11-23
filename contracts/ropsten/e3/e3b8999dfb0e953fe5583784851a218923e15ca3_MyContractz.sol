/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

pragma solidity ^0.8.7;

interface IERC20za { // defining an interface of the (external) token contract that you're going to be interacting with
    function decimals() external view returns (uint8);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}

contract MyContractz {
    function buy() external {
        IERC20za tokenContract = IERC20za(address(0x277f833FfE4bd2c4765d4479AFBf3054A53AbA88)); // the token contract address

        // reverts if the transfer wasn't successful
        require(
            tokenContract.transferFrom(
                msg.sender, // from the user
                address(this), // to this contract
                50 * (10 ** tokenContract.decimals()) // 50 tokens, incl. decimals of the token contract
            ) == true,
            'Could not transfer tokens from your address to this contract' // error message in case the transfer was not successful
        );
        
        // transfer was successful, rest of your code
    }
}