// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./AsToken.sol";
contract AsTokenSale{ 

    address public admin;

    AsToken public tokenContract;

    uint256 public tokenPrice;
    uint256 public tokensForSell;
    uint256 public tokensSold;


    uint256 public amountForWithdraw;

    event Sell(address _buyer,uint256 _amount);

    constructor(AsToken _tokenContract, uint256 _tokenPrice,uint256 _tokensForSell) public{
            admin = msg.sender;
            tokenContract = _tokenContract;
            tokensForSell = _tokensForSell;
            tokenPrice = _tokenPrice;
        }

    function buyTokens(uint256 _numberOfTokens) public payable{

        require(msg.value == _numberOfTokens*tokenPrice);
        require(tokenContract.balanceOf(address(this)) >= _numberOfTokens);
        require(tokenContract.transfer(msg.sender,_numberOfTokens));
        tokensSold += _numberOfTokens;
        amountForWithdraw += msg.value;
        emit Sell(msg.sender,_numberOfTokens);

    }

    modifier onlyAdmin{
          require(msg.sender == admin,'Only admin can withdraw  Funds');
          _;
    }

    function endSale() public onlyAdmin payable{
        require(tokenContract.transfer(admin,tokenContract.balanceOf(address(this))));
        // destroy contract
        // selfdestruct(msg.sender);
    }

    function withdraw(address payable _to) public onlyAdmin payable{
        _to.transfer(address(this).balance);
        amountForWithdraw = 0;
    }

}