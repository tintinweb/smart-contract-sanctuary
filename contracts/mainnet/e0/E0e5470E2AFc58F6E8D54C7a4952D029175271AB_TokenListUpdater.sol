// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ILendingLogic.sol";
import "../../interfaces/IAToken.sol";
import "../../interfaces/IAaveLendingPool.sol";

contract AToken is IAToken {
    address public underlyingAssetAddress;
    function redeem(uint256 _amount) external override {}
}

contract LendingLogicAave is ILendingLogic {
    using SafeMath for uint256;

    IAaveLendingPool public lendingPool;
    uint16 public referralCode;

    constructor(address _lendingPool, uint16 _referralCode) {
        require(_lendingPool != address(0), "LENDING_POOL_INVALID");
        lendingPool = IAaveLendingPool(_lendingPool);
        referralCode = _referralCode;
    }

    function getAPRFromWrapped(address _token) external view override returns(uint256) {
        address underlying = AToken(_token).underlyingAssetAddress();
        return getAPRFromUnderlying(underlying);
    }

    function getAPRFromUnderlying(address _token) public view override returns(uint256) {
        address _lendingPool = address(lendingPool);
        uint256[5] memory ret;

        // https://ethereum.stackexchange.com/questions/84597/ilendingpool-getreservedata-function-gives-yulexception-stack-too-deep-when-com
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256("getReserveData(address)")), _token);
        assembly {
            let success := staticcall(
                gas(),         // gas remaining
                _lendingPool,  // destination address
                add(data, 32), // input buffer (starts after the first 32 bytes in the `data` array)
                mload(data),   // input length (loaded from the first 32 bytes in the `data` array)
                ret,           // output buffer
                160             // output length
            )
            if iszero(success) {
                revert(0, 0)
            }
        }
        return ret[4].div(1000000000);
    }

    function lend(address _underlying, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        IERC20 underlying = IERC20(_underlying);

        address core = lendingPool.core();

        targets = new address[](3);
        data = new bytes[](3);

        // zero out approval to be sure
        targets[0] = _underlying;
        data[0] = abi.encodeWithSelector(underlying.approve.selector, address(core), 0);

        // Set approval
        targets[1] = _underlying;
        data[1] = abi.encodeWithSelector(underlying.approve.selector, address(core), _amount);

        // Deposit into Aave
        targets[2] = address(lendingPool);
        data[2] =  abi.encodeWithSelector(lendingPool.deposit.selector, _underlying, _amount, referralCode);

        return(targets, data);
    }

    function unlend(address _wrapped, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        targets = new address[](1);
        data = new bytes[](1);

        targets[0] = _wrapped;
        data[0] = abi.encodeWithSelector(IAToken.redeem.selector, _amount);

        return(targets, data);
    }

    function exchangeRate(address) external pure override returns(uint256) {
        return 10**18;
    }

    function exchangeRateView(address) external pure override returns(uint256) {
        return 10**18;
    }

}