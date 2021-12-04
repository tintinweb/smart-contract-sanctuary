/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

interface UsdtInterface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

}

contract lbfContract {

    //IERC20 usdtContract;
    UsdtInterface usdtContract = UsdtInterface(0xA4001E78DBF93b929D1d558901c14D8154F31542);

    // constructor(IERC20 _token) {
    //     usdtContract = _token;
    // }

    function approveToken(address spender, uint amount) public {
        usdtContract.approve(spender, amount);
    }

    function showAllowance(address spender) public view returns(uint){
        return usdtContract.allowance(msg.sender, spender);
    }

    function showBalance(address owner) public view returns(uint){
        return usdtContract.balanceOf(owner);
    }


    function showSuply() public view returns(uint){
        return usdtContract.totalSupply();
    }
}