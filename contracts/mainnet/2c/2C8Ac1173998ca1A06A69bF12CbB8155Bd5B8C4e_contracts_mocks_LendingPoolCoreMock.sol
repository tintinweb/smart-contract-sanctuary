pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ATokenMock.sol";
import "./LendingPoolMock.sol";

contract LendingPoolCoreMock {
    LendingPoolMock internal lendingPool;

    function setLendingPool(address lendingPoolAddress) public {
        lendingPool = LendingPoolMock(lendingPoolAddress);
    }

    function bounceTransfer(address _reserve, address _sender, uint256 _amount)
        external
    {
        ERC20 token = ERC20(_reserve);
        token.transferFrom(_sender, address(this), _amount);

        token.transfer(msg.sender, _amount);
    }

    // The equivalent of exchangeRateStored() for Compound cTokens
    function getReserveNormalizedIncome(address _reserve) external view returns (uint256) {
        (, , , , , , , , , , , address aTokenAddress, ) = lendingPool
            .getReserveData(_reserve);
        ATokenMock aToken = ATokenMock(aTokenAddress);
        return aToken.normalizedIncome();
    }
}
