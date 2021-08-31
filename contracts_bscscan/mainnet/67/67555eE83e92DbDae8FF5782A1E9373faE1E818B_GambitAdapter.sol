/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// File: contracts/SmartRoute/intf/IGambit.sol

pragma solidity 0.6.9;


interface IGambit {
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);

}

// File: contracts/SmartRoute/intf/IDODOAdapter.sol



interface IDODOAdapter {
    
    function sellBase(address to, address pool, bytes memory data) external;

    function sellQuote(address to, address pool, bytes memory data) external;
}

// File: contracts/SmartRoute/adapter/GambitAdapter.sol




contract GambitAdapter is IDODOAdapter {

    function _gambitSwap(address to, address pool, bytes memory moreInfo) internal {
        (address tokenIn, address tokenOut) = abi.decode(moreInfo, (address, address));

        IGambit(pool).swap(tokenIn, tokenOut, to);
    }

    function sellBase(address to, address pool, bytes memory moreInfo) external override {
        _gambitSwap(to, pool, moreInfo);
    }

    function sellQuote(address to, address pool, bytes memory moreInfo) external override {
        _gambitSwap(to, pool, moreInfo);
    }
}