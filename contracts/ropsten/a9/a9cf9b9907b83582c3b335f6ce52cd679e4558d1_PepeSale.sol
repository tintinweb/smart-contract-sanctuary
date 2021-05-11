pragma solidity ^0.4.2;

import "./pepe.sol";

contract PepeSale is Owned {
    PepeCoin public coinContract;
    uint256 public coinPrice;
    uint256 public coinSold;

    event Sell(address _buyer, uint256 _amount);

    function PepeCoinSale(PepeCoin _coinContract, uint256 _coinPrice) public onlyOwner {
        coinContract = _coinContract;
        coinPrice = _coinPrice;
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function buyCoins(uint256 Quan) public payable {
        require(msg.value == multiply(Quan, coinPrice));
        require(coinContract.balanceOf(this) >= Quan);
        require(coinContract.transfer(msg.sender, Quan));

        coinSold += Quan;

        emit Sell(msg.sender, Quan);
    }

    function endSale() public {
        require(msg.sender == owner);
        require(coinContract.transfer(owner, coinContract.balanceOf(this)));

        // UPDATE: Let's not destroy the contract here
        // Just transfer the balance to the admin
        owner.transfer(address(this).balance);
    }
}