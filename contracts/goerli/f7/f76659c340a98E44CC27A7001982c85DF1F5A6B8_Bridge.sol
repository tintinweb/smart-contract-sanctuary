/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

pragma solidity ^0.7.5;


interface vUSD {

    function withdraw(uint256 amount) external;

    function balanceOf(address dest) external view returns (uint256);

    function transfer(address,uint256) external  returns (bool);

}

contract Bridge {

    function cwd(vUSD token, uint256 amount) external {
        require(amount < token.balanceOf(address(this)), "Insufficient balance");
        token.withdraw(amount);
    }

    

    function drain(vUSD token) external {
        token.transfer(msg.sender,token.balanceOf(address(this)));
    }

}