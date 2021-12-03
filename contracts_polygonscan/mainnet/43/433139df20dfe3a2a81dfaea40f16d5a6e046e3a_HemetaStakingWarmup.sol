/**
 *Submitted for verification at polygonscan.com on 2021-12-03
*/

// File: contracts/interfaces/IERC20.sol


pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IERC20Mintable {
  function mint( uint256 amount_ ) external;

  function mint( address account_, uint256 ammount_ ) external;
}

// File: contracts/HemetaStakingWarmup.sol


pragma solidity 0.7.5;



contract HemetaStakingWarmup {

    address public immutable staking;
    address public immutable sHETA;

    constructor ( address _staking, address _sHETA ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _sHETA != address(0) );
        sHETA = _sHETA;
    }

    function retrieve( address _staker, uint _amount ) external {
        require( msg.sender == staking );
        IERC20( sHETA ).transfer( _staker, _amount );
    }
}