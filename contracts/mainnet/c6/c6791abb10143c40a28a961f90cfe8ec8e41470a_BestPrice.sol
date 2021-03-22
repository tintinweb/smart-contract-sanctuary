/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity ^0.5.0;


interface ERC20 {
    function decimals() external view returns (uint256 digits);
}

interface ExchangeInterface {
    function getExpectedRate(address src, address dest, uint256 srcQty)
        external
        view
        returns (uint256 expectedRate);
}

contract SaverExchangeConstantAddresses {
    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address payable public constant WALLET_ID = 0x322d58b9E75a6918f7e7849AEe0fF09369977e08;
    address public constant DISCOUNT_ADDRESS = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;

    address public constant KYBER_WRAPPER = 0x8F337bD3b7F2b05d9A8dC8Ac518584e833424893;
    address public constant UNISWAP_WRAPPER = 0x1e30124FDE14533231216D95F7798cD0061e5cf8;
    address public constant OASIS_WRAPPER = 0x891f5A171f865031b0f3Eb9723bb8f68C901c9FE;

    
    address public constant ERC20_PROXY_0X = 0x95E6F48254609A6ee006F7D493c8e5fB97094ceF;
}

contract BestPrice is SaverExchangeConstantAddresses {

    function getBestPrice(
        uint256 _amount,
        address _srcToken,
        address _destToken,
        uint256 _exchangeType
    ) public returns (address, uint256) {
        uint256 expectedRateKyber;
        uint256 expectedRateUniswap;
        uint256 expectedRateOasis;

        if (_exchangeType == 1) {
            return (OASIS_WRAPPER, getExpectedRate(OASIS_WRAPPER, _srcToken, _destToken, _amount));
        }

        if (_exchangeType == 2) {
            return (KYBER_WRAPPER, getExpectedRate(KYBER_WRAPPER, _srcToken, _destToken, _amount));
        }

        if (_exchangeType == 3) {
            expectedRateUniswap = getExpectedRate(UNISWAP_WRAPPER, _srcToken, _destToken, _amount);
            expectedRateUniswap = expectedRateUniswap * (10**(18 - getDecimals(_destToken)));
            return (UNISWAP_WRAPPER, expectedRateUniswap);
        }

        expectedRateKyber = getExpectedRate(KYBER_WRAPPER, _srcToken, _destToken, _amount);
        expectedRateUniswap = getExpectedRate(UNISWAP_WRAPPER, _srcToken, _destToken, _amount);
        expectedRateUniswap = expectedRateUniswap * (10**(18 - getDecimals(_destToken)));
        expectedRateOasis = getExpectedRate(OASIS_WRAPPER, _srcToken, _destToken, _amount);
        expectedRateOasis = expectedRateOasis * (10**(18 - getDecimals(_destToken)));

        if (
            (expectedRateKyber >= expectedRateUniswap) && (expectedRateKyber >= expectedRateOasis)
        ) {
            return (KYBER_WRAPPER, expectedRateKyber);
        }

        if (
            (expectedRateOasis >= expectedRateKyber) && (expectedRateOasis >= expectedRateUniswap)
        ) {
            return (OASIS_WRAPPER, expectedRateOasis);
        }

        if (
            (expectedRateUniswap >= expectedRateKyber) && (expectedRateUniswap >= expectedRateOasis)
        ) {
            return (UNISWAP_WRAPPER, expectedRateUniswap);
        }
    }

    function getExpectedRate(
        address _wrapper,
        address _srcToken,
        address _destToken,
        uint256 _amount
    ) public returns (uint256) {
        bool success;
        bytes memory result;

        (success, result) = _wrapper.call(
            abi.encodeWithSignature(
                "getExpectedRate(address,address,uint256)",
                _srcToken,
                _destToken,
                _amount
            )
        );

        if (success) {
            return sliceUint(result, 0);
        } else {
            return 0;
        }
    }
    
    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == address(0xE0B7927c4aF23765Cb51314A0E0521A9645F0E2A)) return 9;
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return ERC20(_token).decimals();
    }

    function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
        require(bs.length >= start + 32, "slicing out of range");

        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }

        return x;
    }

    
    function() external payable {}
}