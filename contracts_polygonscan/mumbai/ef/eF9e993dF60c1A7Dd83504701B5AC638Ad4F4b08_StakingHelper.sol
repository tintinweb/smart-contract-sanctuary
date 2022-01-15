// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "IStaking.sol";
import "IERC20.sol";

contract StakingHelper {

    event LogStake(address indexed recipient, uint amount);

    IStaking public immutable staking;
    IERC20 public immutable Time;

    constructor ( address _staking, address _Time ) {
        require( _staking != address(0) );
        staking = IStaking(_staking);
        require( _Time != address(0) );
        Time = IERC20(_Time);
    }

    function stake( uint _amount, address recipient ) external {
        Time.transferFrom( msg.sender, address(this), _amount );
        Time.approve( address(staking), _amount );
        staking.stake( _amount, recipient );
        staking.claim( recipient );
        emit LogStake(recipient, _amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
pragma abicoder v2;


interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim( address _recipient ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
pragma abicoder v2;


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