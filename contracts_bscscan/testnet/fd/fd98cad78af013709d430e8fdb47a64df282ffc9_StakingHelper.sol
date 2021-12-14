/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

pragma solidity ^0.8.10;

// ----------------------------------------------------------------------------
// --- Name   : AlphaDAO - [https://www.alphadao.financial/]
// --- Symbol : Format - {OX}
// --- Supply : Generated from DAO
// --- @title : the Beginning and the End 
// --- 01000110 01101111 01110010 00100000 01110100 01101000 01100101 00100000 01101100 
// --- 01101111 01110110 01100101 00100000 01101111 01100110 00100000 01101101 01111001 
// --- 00100000 01100011 01101000 01101001 01101100 01100100 01110010 01100101 01101110
// --- AlphaDAO.financial - EJS32 - 2021
// --- @dev pragma solidity version:0.8.10+commit.fc410830
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// --- Interface IERC20
// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------
// --- Interface IStaking
// ----------------------------------------------------------------------------

interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim( address _recipient ) external;
}

// ----------------------------------------------------------------------------
// --- Contract StakingHelper
// ----------------------------------------------------------------------------

contract StakingHelper {

    address public immutable staking;
    address public immutable OX;

    constructor ( address _staking, address _OX ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _OX != address(0) );
        OX = _OX;
    }

    function stake( uint _amount ) external {
        IERC20( OX ).transferFrom( msg.sender, address(this), _amount );
        IERC20( OX ).approve( staking, _amount );
        IStaking( staking ).stake( _amount, msg.sender );
        IStaking( staking ).claim( msg.sender );
    }
}