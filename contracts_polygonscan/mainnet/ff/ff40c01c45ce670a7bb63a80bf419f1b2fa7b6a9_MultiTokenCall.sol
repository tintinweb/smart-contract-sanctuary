// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IERC20.sol";

contract MultiTokenCall {
    
    function multiBalance(address[] memory addrs, address owner) external view returns (uint256[] memory){
        uint256[] memory amounts = new uint256[](addrs.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            amounts[i] = IERC20(addrs[i]).balanceOf(owner);
        }
        return amounts;
    }

    function multiDecimals(address[] memory addrs) external view returns (uint256[] memory){
        uint256[] memory amounts = new uint256[](addrs.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            amounts[i] = IERC20(addrs[i]).decimals();
        }
        return amounts;
    }

    function multiName(address[] memory addrs) external view returns (string[] memory){
        string[] memory strs = new string[](addrs.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            strs[i] = IERC20(addrs[i]).name();
        }
        return strs;
    }

    function multiAllowance(address[] memory addrs, address _owner, address _spender) external view returns (uint256[] memory){
        uint256[] memory amounts = new uint256[](addrs.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            amounts[i] = IERC20(addrs[i]).allowance(_owner, _spender);
        }
        return amounts;
    }

    function multiSymbol(address[] memory addrs) external view returns (string[] memory){
        string[] memory strs = new string[](addrs.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            strs[i] = IERC20(addrs[i]).symbol();
        }
        return strs;
    }

    function multiTotalSupply(address[] memory addrs) external view returns (uint256[] memory){
        uint256[] memory amounts = new uint256[](addrs.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            amounts[i] = IERC20(addrs[i]).totalSupply();
        }
        return amounts;
    }

    function multiGetOwner(address[] memory addrs) external view returns (address[] memory){
        address[] memory owners = new address[](addrs.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            owners[i] = IERC20(addrs[i]).getOwner();
        }
        return owners;
    }
    
}