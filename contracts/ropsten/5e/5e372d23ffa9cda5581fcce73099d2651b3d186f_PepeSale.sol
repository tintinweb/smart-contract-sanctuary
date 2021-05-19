pragma solidity 0.6.6;

import "./pepe.sol";

contract PepeSale is Owned {
    PepeCoin public coinContract;
    uint256 public coinPrice;
    uint256 public conversion;
    uint256 public coinSold;
    address register = address(this);

    event Sell(address _buyer, uint256 _amount);

    function PepeCoinSale(PepeCoin _coinContract, uint256 _coinPrice, uint256 _conversion) public onlyOwner {
        coinContract = _coinContract;
        coinPrice = _coinPrice;
        conversion = _conversion;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function buyCoins(uint256 quan) external payable {
        uint256 Quan = mul(quan, conversion);
        require(msg.value == mul(quan, coinPrice));
        require(coinContract.balanceOf(register) >= Quan);
        coinContract.transfer(msg.sender, Quan);

        coinSold += Quan;

        emit Sell(msg.sender, Quan);
    }

    function endSale() public onlyOwner {
        require(msg.sender == owner);
        require(coinContract.transfer(owner, coinContract.balanceOf(register)));

        coinContract.transfer(owner, address(register).balance);
    }
}