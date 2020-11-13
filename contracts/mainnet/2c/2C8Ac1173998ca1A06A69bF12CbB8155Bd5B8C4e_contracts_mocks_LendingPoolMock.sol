pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ATokenMock.sol";
import "./LendingPoolCoreMock.sol";

contract LendingPoolMock {
    mapping(address => address) internal reserveAToken;
    LendingPoolCoreMock public core;

    constructor(address _core) public {
        core = LendingPoolCoreMock(_core);
    }

    function setReserveAToken(address _reserve, address _aTokenAddress) external {
        reserveAToken[_reserve] = _aTokenAddress;
    }

    function deposit(address _reserve, uint256 _amount, uint16)
        external
    {
        ERC20 token = ERC20(_reserve);
        core.bounceTransfer(_reserve, msg.sender, _amount);

        // Mint aTokens
        address aTokenAddress = reserveAToken[_reserve];
        ATokenMock aToken = ATokenMock(aTokenAddress);
        aToken.mint(msg.sender, _amount);
        token.transfer(aTokenAddress, _amount);
    }

    function getReserveData(address _reserve)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256 liquidityRate,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address aTokenAddress,
            uint40
        )
    {
        aTokenAddress = reserveAToken[_reserve];
        ATokenMock aToken = ATokenMock(aTokenAddress);
        liquidityRate = aToken.liquidityRate();
    }
}
