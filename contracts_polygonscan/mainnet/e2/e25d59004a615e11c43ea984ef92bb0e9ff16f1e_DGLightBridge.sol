/**
 *Submitted for verification at polygonscan.com on 2021-11-15
*/

// SPDX-License-Identifier: ---DG----

pragma solidity ^0.8.9;

interface IERC20Token {

    function transfer(
        address _recipient, 
        uint256 _amount
    ) 
        external 
        returns (bool);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) 
        external 
        returns (bool);
}

contract DGLightBridge {

    IERC20Token immutable public lightDG;    
    IERC20Token immutable public classicDG;

    uint16 constant public RATIO = 1000;

    mapping(address => uint256) public sponsors;

    constructor(
        address _classicDG, // 0x2a93172c8DCCbfBC60a39d56183B7279a2F647b4
        address _lightDG // ??
    ) {
        classicDG = IERC20Token(
            _classicDG
        );

        lightDG = IERC20Token(
            _lightDG
        );        
    }
    
    function goLight( 
        uint256 _classicAmountToDeposit
    )
        external
    {
        classicDG.transferFrom(
            msg.sender, 
            address(this),
            _classicAmountToDeposit
        );

        lightDG.transfer(
            msg.sender,
            _classicAmountToDeposit * RATIO
        );
    }
    
    function goClassic(
        uint256 _classicAmountToReceive
    )
        external
    {
        lightDG.transferFrom(
            msg.sender, 
            address(this),
            _classicAmountToReceive * RATIO
        );
        
        classicDG.transfer(
            msg.sender, 
            _classicAmountToReceive
        );
    }

    function sponsorLight(
        uint256 _lightAmount 
    )
        external
    {
        lightDG.transferFrom(
            msg.sender, 
            address(this),
            _lightAmount
        );
        
        sponsors[msg.sender] = 
        sponsors[msg.sender] + _lightAmount;
    }

    function sponsorClassic(
        uint256 _classicAmount 
    )
        external
    {
        classicDG.transferFrom(
            msg.sender, 
            address(this),
            _classicAmount
        );
        
        sponsors[msg.sender] = 
        sponsors[msg.sender] + _classicAmount * RATIO;
    }

    function redeemLight(
        uint256 _lightAmount
    )
        external
    {
        sponsors[msg.sender] = 
        sponsors[msg.sender] - _lightAmount;                
        
        lightDG.transfer(
            msg.sender, 
            _lightAmount
        );        
    }

    function redeemClassic(
        uint256 _classicAmount 
    )
        external
    {
        sponsors[msg.sender] = 
        sponsors[msg.sender] - _classicAmount * RATIO;        

        classicDG.transfer(
            msg.sender, 
            _classicAmount
        );
    }  
}