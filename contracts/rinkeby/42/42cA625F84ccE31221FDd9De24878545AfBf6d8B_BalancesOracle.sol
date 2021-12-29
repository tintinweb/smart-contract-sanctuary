// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import "./IERC20.sol";

contract Balance {
    function balanceOf(address contractAddr, address identity) external view returns (uint256){
        return IERC20(contractAddr).balanceOf(identity);
    }
    function symbol(address contractAddr) external view returns (string memory){
        return IERC20(contractAddr).symbol();
    }
    function decimals(address contractAddr) external view returns (uint8){
        return IERC20(contractAddr).decimals();
    }
}

contract BalancesOracle {
    struct Token {
        string symbol;
        uint256 amount;
        uint8 decimals;
    }
    
    Balance balance = new Balance();

    function balanceOf(address contractAddr, address identity) internal view returns (uint256){
        try balance.balanceOf(contractAddr, identity) returns (uint256 result) {
            return result;
        } catch Error(string memory /*reason*/) {
            return (0);
        } catch (bytes memory) {
            return (0);
        }
    }

    function symbol(address contractAddr) internal view returns (string memory){
        try balance.symbol(contractAddr) returns (string memory result) {
            return result;
        } catch Error(string memory /*reason*/) {
            return "";
        } catch (bytes memory) {
            return "";
        }
    }

    function decimals(address contractAddr) internal view returns (uint8){
        try balance.decimals(contractAddr) returns (uint8 result) {
            return result;
        } catch Error(string memory /*reason*/) {
            return (0);
        } catch (bytes memory) {
            return (0);
        }
    }

	function getBalances(
		address identity,
		address[] calldata tokenAddrs
	) external view returns (Token[] memory) {
		uint len = tokenAddrs.length;
		Token[] memory results = new Token[](len);
		for (uint256 i = 0; i < len; i++) {
			if (tokenAddrs[i] == address(0)) {
                results[i] = Token("ETH", address(identity).balance, 18);
            } else {
                results[i] = Token(symbol(tokenAddrs[i]), balanceOf(tokenAddrs[i], identity), decimals(tokenAddrs[i]));
            }
        }
        return results;
	}
}