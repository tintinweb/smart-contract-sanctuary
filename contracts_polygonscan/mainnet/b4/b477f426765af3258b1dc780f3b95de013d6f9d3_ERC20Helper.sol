/**
 *Submitted for verification at polygonscan.com on 2021-07-29
*/

pragma solidity 0.8.6;

interface IERC20Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC20TotalSupply {
    function totalSupply() external view returns (uint256);
}

interface IERC20BalanceOf {
    function balanceOf(address) external view returns (uint256);
}

interface IERC20Allowance {
    function allowance(address, address) external view returns (uint256);
}

/// @author 0age
contract ERC20Helper {
    function metadataSafe(IERC20Metadata token) external view returns (bool tokenExists, bool nameOK, string memory name, bool symbolOK, string memory symbol, bool decimalsOK, uint8 decimals) {
        tokenExists = _hasCode(address(token));
        if (tokenExists) {
            bytes memory returnData;
            (nameOK, returnData) = address(token).staticcall{gas: gasleft() / 2}(abi.encodeWithSelector(token.name.selector));
            if (nameOK && returnData.length >= 64) {
                name = abi.decode(returnData, (string));
            } else {
                nameOK = false;
            }
            
            (symbolOK, returnData) = address(token).staticcall{gas: gasleft() / 2}(abi.encodeWithSelector(token.symbol.selector));
            if (symbolOK && returnData.length >= 64) {
                symbol = abi.decode(returnData, (string));
            } else {
                symbolOK = false;
            }
    
            (decimalsOK, returnData) = address(token).staticcall{gas: gasleft() / 2}(abi.encodeWithSelector(token.decimals.selector));
            if (decimalsOK && returnData.length >= 32) {
                decimals = abi.decode(returnData, (uint8));
            } else {
                decimalsOK = false;
            }
        }
    }

    function totalSupplySafe(IERC20TotalSupply token) external view returns (bool tokenExists, bool ok, uint256 totalSupply) {
        tokenExists = _hasCode(address(token));
        if (tokenExists) {
            bytes memory returnData;
            (ok, returnData) = address(token).staticcall{gas: gasleft() / 2}(abi.encodeWithSelector(token.totalSupply.selector));
            if (ok && returnData.length >= 32) {
                totalSupply = abi.decode(returnData, (uint256));
            } else {
                ok = false;
            }
        }
    }

    function balanceOfSafe(IERC20BalanceOf token, address account) external view returns (bool tokenExists, bool ok, uint256 balance) {
        tokenExists = _hasCode(address(token));
        if (tokenExists) {
            bytes memory returnData;
            (ok, returnData) = address(token).staticcall{gas: gasleft() / 2}(abi.encodeWithSelector(token.balanceOf.selector, account));
            if (ok && returnData.length >= 32) {
                balance = abi.decode(returnData, (uint256));
            } else {
                ok = false;
            }
        }
    }
    
    function allowanceSafe(IERC20Allowance token, address owner, address spender) external view returns (bool tokenExists, bool ok, uint256 allowance) {
        tokenExists = _hasCode(address(token));
        if (tokenExists) {
            bytes memory returnData;
            (ok, returnData) = address(token).staticcall{gas: gasleft() / 2}(abi.encodeWithSelector(token.allowance.selector, owner, spender));
            if (ok && returnData.length >= 32) {
                allowance = abi.decode(returnData, (uint256));
            } else {
                ok = false;
            }
        }
    }
    
	function _hasCode(address addr) internal view returns (bool) {
      uint256 size;
      assembly { size := extcodesize(addr) }
      return size > 0;
	}
}