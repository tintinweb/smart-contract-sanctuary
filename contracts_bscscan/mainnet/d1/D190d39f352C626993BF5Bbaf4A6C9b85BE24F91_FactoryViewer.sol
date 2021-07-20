/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

pragma solidity 0.8.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

contract FactoryViewer {
    
    function getPairAddress(address factory, uint256 cursor, uint256 size) external view returns (address[] memory, uint256) {
        IPancakeFactory pcsFactory = IPancakeFactory(factory);
        uint256 maxLength = pcsFactory.allPairsLength()-1;
        uint256 length = size;
        if (length > maxLength - cursor) {
            length = maxLength - cursor;
        }

        address[] memory values = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            address tempAddr = address(pcsFactory.allPairs(cursor+i));
            values[i] = tempAddr;
        }

        return (values, cursor + length);
    }

}