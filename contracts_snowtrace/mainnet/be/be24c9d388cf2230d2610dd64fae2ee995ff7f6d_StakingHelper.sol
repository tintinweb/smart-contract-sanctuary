/**
 *Submitted for verification at snowtrace.io on 2021-12-23
*/

/**
 *Submitted for verification at snowtrace.io on 2021-12-23
*/

/**
 *Submitted for verification at snowtrace.io on 2021-12-08
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


interface IERC20 {
    
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim( address _recipient ) external;
}


contract StakingHelper {

    address public immutable staking;
    address public immutable SPC;

    constructor ( address _staking, address _SPC ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _SPC != address(0) );
        SPC = _SPC;
    }

    function stake( uint _amount, address recipient ) external {
        IERC20( SPC ).transferFrom( msg.sender, address(this), _amount );
        IERC20( SPC ).approve( staking, _amount );
        IStaking( staking ).stake( _amount, recipient );
        IStaking( staking ).claim( recipient );
    }
}