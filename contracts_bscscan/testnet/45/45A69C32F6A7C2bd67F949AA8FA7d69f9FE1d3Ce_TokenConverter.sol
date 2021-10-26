/**
 *Submitted for verification at BscScan.com on 2021-10-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IRouter {
    function WETH() external view returns (address);

    function factory() external view returns (address);
}

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPair {
    function token0() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

contract TokenConverter {
    mapping(address => mapping(address => address)) pairs;

    IRouter public DEFAULT_ROUTER;
    IFactory public DEFAULT_FACTORY;
    address public WETH;

    constructor(IRouter _defaultRouter) {
        // 0x10ED43C718714eb63d5aA57B78B54704E256024E PANCAKE V2
        // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D UNI V2
        DEFAULT_ROUTER = _defaultRouter; 
        DEFAULT_FACTORY = IFactory(DEFAULT_ROUTER.factory());
        WETH = DEFAULT_ROUTER.WETH();
    }

    function convertTwoByPair(
        address _tokenA,
        uint256 _amount,
        IPair _pair
    ) public view returns (uint256) {
        if (_amount == 0) return 0;
        address _t0 = _pair.token0();
        (uint112 _r0, uint112 _r1, ) = _pair.getReserves();
        if (_r0 == 0 || _r1 == 0) return 0;
        if (_t0 == _tokenA) return (_amount * _r1) / _r0;
        else return (_amount * _r0) / _r1;
    }

    // BY DEFAULT

    function convertTwo(
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) public view returns (uint256) {
        if (_tokenA == _tokenB) return _amount;
        return convertTwoByFactory(DEFAULT_FACTORY, _tokenA, _tokenB, _amount);
    }

    function convertTwoUniversal(
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) public view returns (uint256) {
        if (_tokenA == _tokenB) return _amount;
        return convertTwoUniversalByFactory(DEFAULT_FACTORY, _tokenA, _tokenB, _amount);
    }

    function convertViaWETH(
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) public view returns (uint256) {
        if (_tokenA == _tokenB) return _amount;
        return convertViaWETHByFactory(DEFAULT_FACTORY, _tokenA, _tokenB, _amount);
    }

    function convertChained(address[] memory _tokens, uint256 _amount) public view returns (uint256 amt) {
        return convertChainedByFactory(DEFAULT_FACTORY, _tokens, _amount);
    }

    function convertChainedUniversal(address[] memory _tokens, uint256 _amount) public view returns (uint256 amt) {
        return convertChainedUniversalByFactory(DEFAULT_FACTORY, _tokens, _amount);
    }

    function checkTokensDistance(address _tokenA, address _tokenB) public view returns (uint8) {
        return checkTokensDistanceByFactory(DEFAULT_FACTORY, _tokenA, _tokenB);
    }

    // BY FACTORY

    function convertTwoByFactory(
        IFactory _factory,
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) public view returns (uint256) {
        if (_tokenA == _tokenB) return _amount;
        IPair _pair = IPair(_factory.getPair(_tokenA, _tokenB));
        if (address(_pair) == address(0)) return 0;
        return convertTwoByPair(_tokenA, _amount, _pair);
    }

    function convertTwoUniversalByFactory(
        IFactory _factory,
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) public view returns (uint256) {
        if (_tokenA == _tokenB) return _amount;
        uint8 _distance = checkTokensDistanceByFactory(_factory, _tokenA, _tokenB);
        if (_distance == 0) return 0;
        if (_distance == 1) return convertTwoByFactory(_factory, _tokenA, _tokenB, _amount);
        else return convertViaWETHByFactory(_factory, _tokenA, _tokenB, _amount);
    }

    function convertViaWETHByFactory(
        IFactory _factory,
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) public view returns (uint256) {
        if (_tokenA == _tokenB) return _amount;
        uint256 _amount_WETH = convertTwoByFactory(_factory, _tokenA, WETH, _amount);
        return convertTwoByFactory(_factory, WETH, _tokenB, _amount_WETH);
    }

    function convertChainedByFactory(
        IFactory _factory,
        address[] memory _tokens,
        uint256 _amount
    ) public view returns (uint256 amt) {
        amt = _amount;
        if (_tokens.length < 2) return amt;
        for (uint256 i = 0; i < _tokens.length - 1; i++) amt = convertTwoByFactory(_factory, _tokens[i], _tokens[i + 1], amt);
    }

    function convertChainedUniversalByFactory(
        IFactory _factory,
        address[] memory _tokens,
        uint256 _amount
    ) public view returns (uint256 amt) {
        amt = _amount;
        if (_tokens.length < 2) return amt;
        for (uint256 i = 0; i < _tokens.length - 1; i++) amt = convertTwoUniversalByFactory(_factory, _tokens[i], _tokens[i + 1], amt);
    }

    function checkTokensDistanceByFactory(
        IFactory _factory,
        address _tokenA,
        address _tokenB
    ) public view returns (uint8) {
        if (_tokenA == _tokenB) return 0;
        address _pair = _factory.getPair(_tokenA, _tokenB);
        if (address(_pair) == address(0)) {
            address _pairWA = _factory.getPair(_tokenA, WETH);
            address _pairWB = _factory.getPair(WETH, _tokenB);
            if (_pairWA == address(0) || _pairWB == address(0)) return 0;
            else return 2;
        } else return 1;
    }

    // BY ROUTER

    function convertTwoByRouter(
        IRouter _router,
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) public view returns (uint256) {
        if (_tokenA == _tokenB) return _amount;
        IFactory _factory = IFactory(_router.factory());
        return convertTwoByFactory(_factory, _tokenA, _tokenB, _amount);
    }

    function convertTwoUniversalByRouter(
        IRouter _router,
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) public view returns (uint256) {
        if (_tokenA == _tokenB) return _amount;
        IFactory _factory = IFactory(_router.factory());
        return convertTwoUniversalByFactory(_factory, _tokenA, _tokenB, _amount);
    }

    function convertViaWETHByRouter(
        IRouter _router,
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) public view returns (uint256) {
        if (_tokenA == _tokenB) return _amount;
        IFactory _factory = IFactory(_router.factory());
        return convertViaWETHByFactory(_factory, _tokenA, _tokenB, _amount);
    }

    function convertChainedByRouter(
        IRouter _router,
        address[] memory _tokens,
        uint256 _amount
    ) public view returns (uint256 amt) {
        IFactory _factory = IFactory(_router.factory());
        return convertChainedByFactory(_factory, _tokens, _amount);
    }

    function convertChainedUniversalByRouter(
        IRouter _router,
        address[] memory _tokens,
        uint256 _amount
    ) public view returns (uint256 amt) {
        IFactory _factory = IFactory(_router.factory());
        return convertChainedUniversalByFactory(_factory, _tokens, _amount);
    }

    function checkTokensDistanceByRouter(
        IRouter _router,
        address _tokenA,
        address _tokenB
    ) public view returns (uint8) {
        if (_tokenA == _tokenB) return 0;
        IFactory _factory = IFactory(_router.factory());
        return checkTokensDistanceByFactory(_factory, _tokenA, _tokenB);
    }
}