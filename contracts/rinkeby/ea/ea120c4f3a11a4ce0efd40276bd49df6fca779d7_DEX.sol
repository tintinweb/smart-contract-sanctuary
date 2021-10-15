// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./CustomTokenSpec.sol";
contract DEX  {

    event Bought(uint256 amount);
    event Sold(uint256 amount);

    event Token(ERC20Basic token1,ERC20Basic token2);

    ERC20Basic public token1;
    ERC20Basic public token2;
     
    constructor() public {

        token1 = new ERC20Basic("ERC1");
        token2 = new ERC20Basic("ERC2");
        emit Token(token1,token2);
       
    }


    function buyTokens(IERC20 token) payable public {
        uint256 amountTobuy = msg.value *2;
        uint256 dexBalance = token.balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        token.transfer(msg.sender, amountTobuy);
        emit Bought(amountTobuy);
    }

    function sellTokens(IERC20 token,uint256 amount) public {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        payable(msg.sender).transfer(amount/2);
        emit Sold(amount);
    }

    function swap(uint _amount1,uint _amount2,IERC20 _token1,IERC20 _token2) public
    {
     require(_token1.allowance(msg.sender, address(this)) >= _amount1,"Token  allowance too low");
     _token1.transferFrom(msg.sender, address(this), _amount1);
     _token2.transfer(msg.sender, _amount2);
    }

}