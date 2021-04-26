/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

// SPDX-License-Identifier: AGPL-3.0-or-later\
pragma solidity 0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface IOwnable {
  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}

contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}

interface IPool {
    function distributeRewards( uint rewards ) external returns ( bool );
}

interface IStaking {
    function distributeValue( uint value ) external returns ( bool );
    function distributeClout( uint clout ) external returns ( bool );
}

contract DefaultNetwork is Ownable {
    
    using SafeMath for uint256;
    
    address public Pool;
    address public Staking;

    uint public currentEpoch;
    uint public epochIssuance;
    uint[] public rewardDistributions;
    mapping( address => uint ) public memberships;

    constructor( address pool_, address staking_, uint epochIssuance_, uint[] memory distributions_ ) {
        Pool = pool_;
        Staking = staking_;
        epochIssuance = epochIssuance_;
        rewardDistributions = distributions_;
        currentEpoch = 1;
    }

    function registerMember() external returns ( bool ) {
        require( memberships[ msg.sender ] == 0, "Already a member" );
        memberships[ msg.sender ] = currentEpoch;
        return true;
    }

    function incrementEpoch() external onlyOwner() returns ( bool ) {
        currentEpoch++;
        //IPool( Pool ).distributeRewards( epochIssuance.mul( rewardDistributions[0].div( 1000 ) ) );
        //IStaking( Staking ).distributeValue( epochIssuance.mul( rewardDistributions[1].div( 1000 ) ) );
        //IStaking (Staking ).distributeClout( epochIssuance.mul( rewardDistributions[2].div( 1000 ) ) );
        return true;
    }

    function setRewardDistributions( uint[] memory distributions_ ) external onlyOwner() returns ( bool ) {
        rewardDistributions = distributions_;
        return true;
    }
}