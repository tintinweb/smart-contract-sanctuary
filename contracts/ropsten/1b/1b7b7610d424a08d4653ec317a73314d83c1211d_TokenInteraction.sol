pragma solidity ^0.5.0;

import "./MyErc20Token.sol";


contract TokenInteraction {

    address public tokenAddress;

    constructor(address _tokenAdd) public {
        tokenAddress = _tokenAdd;
    }

    function transferToken(address to) public {
        ERC20Interface myToken = ERC20Interface(tokenAddress);
        myToken.transfer(to, 10);
    }

}