/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity ^0.4.21;
// compiles with v0.4.25

contract DiaOracle {
        address owner;

        struct CoinInfo {
                uint256 price;
                uint256 supply;
                uint256 lastUpdateTimestamp;
                string symbol;
        }

        mapping(string => CoinInfo) diaOracles;

        event newCoinInfo(
                string name,
                string symbol,
                uint256 price,
                uint256 supply,
                uint256 lastUpdateTimestamp
        );
    
        constructor() public {
                owner = msg.sender;
        }

        function changeOwner(address newOwner) public {
                require(msg.sender == owner);
                owner = newOwner;
        }
    
        function updateCoinInfo(string name, string symbol, uint256 newPrice, uint256 newSupply, uint256 newTimestamp) public {
                require(msg.sender == owner);
                diaOracles[name] = (CoinInfo(newPrice, newSupply, newTimestamp, symbol));
                emit newCoinInfo(name, symbol, newPrice, newSupply, newTimestamp);
        }
    
        function getCoinInfo(string name) public view returns (uint256, uint256, uint256, string) {
                return (
                        diaOracles[name].price,
                        diaOracles[name].supply,
                        diaOracles[name].lastUpdateTimestamp,
                        diaOracles[name].symbol
                );
        }
}