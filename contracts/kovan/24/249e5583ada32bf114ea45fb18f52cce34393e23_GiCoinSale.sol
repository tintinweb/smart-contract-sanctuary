pragma solidity >=0.4.22 <0.7.0;

import "./GiCoin.sol";

contract GiCoinSale {
    address admin;
    GiCoin public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    event Sell(address _buyer, uint256 _amount);

    constructor(GiCoin _tokenContract, uint256 _tokenPrice) public {
        admin = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function buyTokens(uint256 _numberOfTokens) public payable {

        require(msg.value == multiply(_numberOfTokens, tokenPrice));

        uint256 bal=tokenContract.balanceOf(address(this));
      
        require(tokenContract.transfer(msg.sender, _numberOfTokens));

        tokensSold += _numberOfTokens;

        emit Sell(msg.sender, _numberOfTokens);
    }

    function endSale() public {
        require(msg.sender == admin);
        require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));
        //selfdestruct(admin);
        // UPDATE: Let's not destroy the contract here
        // Just transfer the balance to the admin

        address payable wallet = address(uint160(admin));

        wallet.transfer( address(this).balance);
    }
}