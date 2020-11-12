// Copyright (C) 2020 Easy Chain. <https://easychain.tech>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

interface ERC20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}




struct ProtocolBalance {
    ProtocolMetadata metadata;
    AdapterBalance[] adapterBalances;
}


struct ProtocolMetadata {
    string name;
    string description;
    string websiteURL;
    string iconURL;
    uint256 version;
}


struct AdapterBalance {
    AdapterMetadata metadata;
    FullTokenBalance[] balances;
}


struct AdapterMetadata {
    address adapterAddress;
    string adapterType; // "Asset", "Debt"
}


// token and its underlying tokens (if exist) balances
struct FullTokenBalance {
    TokenBalance base;
    TokenBalance[] underlying;
}


struct TokenBalance {
    TokenMetadata metadata;
    uint256 amount;
}


// ERC20-style token metadata
// 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE address is used for ETH
struct TokenMetadata {
    address token;
    string name;
    string symbol;
    uint8 decimals;
}


struct Component {
    address token;
    string tokenType;  // "ERC20" by default
    uint256 rate;  // price per full share (1e18)
}


interface IOneSplit {

    function getExpectedReturn(
        ERC20 fromToken,
        ERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        external
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );
}

interface AdapterRegistry {

    function getAdapterBalances(
        address account,
        address[] calldata adapters
    )
        external
        view
        returns (AdapterBalance[] memory);

    function getFullTokenBalance(
        string calldata tokenType,
        address token
    )
        external
        view
        returns (FullTokenBalance memory);
}

struct AdaptedBalance {
    address token;
    int256 amount; // can be negative, thus int
}

/**
 * @dev BerezkaPriceTracker contract.
 * This adapter provides on chain price tracking using 1inch exchange api
 * @author Vasin Denis <denis.vasin@easychain.tech>
 */
contract BerezkaPriceTracker {

    string BEREZKA = "Berezka DAO";

    ERC20 immutable USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ERC20 immutable DAI  = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ERC20 immutable USDT = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    IOneSplit       immutable iOneSplit       = IOneSplit(0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E);
    AdapterRegistry immutable adapterRegistry = AdapterRegistry(0x06FE76B2f432fdfEcAEf1a7d4f6C3d41B5861672);

    function getPrice(
        address _token
    ) 
        public
        view 
        returns (int256) 
    {
        AdaptedBalance[] memory nonEmptyBalances
            = getNonEmptyTokenBalances(_token);
        return _getTokenBalancePrice(nonEmptyBalances); 
    }


    // Internal functions

    function _getTokenBalancePrice(
        AdaptedBalance[] memory _balances
    )
        internal
        view
        returns (int256) 
    {
        int256 result = 0;
        uint256 length = _balances.length;
        for (uint256 i = 0; i < length; i++) {
            result += getTokenPrice(_balances[i].amount, _balances[i].token);
        }
        return result;
    }

    function getNonEmptyTokenBalances(
        address _token
    ) 
        public
        view 
        returns (AdaptedBalance[] memory) 
    {
        FullTokenBalance memory fullTokenBalance
            = adapterRegistry.getFullTokenBalance(BEREZKA, _token);
        TokenBalance[] memory tokenBalances = fullTokenBalance.underlying;
        uint256 count = 0;
        uint256 length = tokenBalances.length;
        for (uint256 i = 0; i < length; i++) {
            if (tokenBalances[i].amount > 0) {
                count++;
            }
        }
        AdaptedBalance[] memory result = new AdaptedBalance[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < length; i++) {
            if (tokenBalances[i].amount > 0) {
                result[index] = AdaptedBalance(
                    tokenBalances[i].metadata.token,
                    int256(tokenBalances[i].amount * 1e18) / 1e18
                );
                index++;
            }
        }
        return result;
    }

    function getTokenPrice(
        int256 _amount,
        address _token
    )
        public
        view
        returns (int256) 
    {
        int8     sign      = _amount < 0 ? -1 : int8(1);
        uint256  absAmount = _amount < 0 ? uint256(-_amount) : uint256(_amount); 
        ERC20    token     = ERC20(_token);
        uint8    count     = 0;
        
        uint256 priceUSDC = _getExpectedReturn(token, USDC, absAmount);
        if (priceUSDC > 0) {
            count++;
        }

        uint256 priceUSDT = _getExpectedReturn(token, USDT, absAmount);
        if (priceUSDT > 0) {
            count++;
        }

        uint256 priceDAIUSDC = 0;
        uint256 priceDAI = _getExpectedReturn(token, DAI, absAmount);
        if (priceDAI > 0) {
            priceDAIUSDC = _getExpectedReturn(DAI, USDC, priceDAI);
            if (priceDAIUSDC > 0) {
                count++;
            }
        }
        
        return sign * int256(((priceUSDC + priceDAIUSDC + priceUSDT) / count));
    }

    function getExpectedReturn(
        ERC20 _fromToken,
        ERC20 _destToken,
        uint256 _amount
    )
        public
        view
        returns (uint256) 
    {
        return _getExpectedReturn(_fromToken, _destToken, _amount);    
    }

    function _getExpectedReturn(
        ERC20 _fromToken,
        ERC20 _destToken,
        uint256 _amount
    )
        internal
        view
        returns (uint256)
    {
        try iOneSplit.getExpectedReturn(
            _fromToken,
            _destToken,
            _amount,
            1,
            0
        ) returns (uint256 returnAmount, uint256[] memory) {
            return returnAmount;
        } catch {
            return 0;
        }
    }
}