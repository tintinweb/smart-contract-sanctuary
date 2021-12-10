/**
 *Submitted for verification at FtmScan.com on 2021-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IOwnable {
    function policy() external view returns (address);

    function renounceManagement() external;

    function pushManagement( address newOwner_ ) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyPolicy() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyPolicy() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}

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
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ITreasury {
    function valueOf( address _token, uint _amount ) external view returns ( uint value_ );
}

contract TreasuryBalance is Ownable {
    using SafeMath for uint;

    address[] public reserveTokens;
    address public treasury;

    function treasuryValue() external view returns ( uint ) {
        uint value = 0;
        for( uint i = 0; i < reserveTokens.length; i++ ) {
            if ( reserveTokens[i] != address(0) ) {
                uint balance = IERC20(reserveTokens[i]).balanceOf(treasury);
                value += ITreasury(treasury).valueOf(reserveTokens[i], balance);
            }
        }
        return value;
    }

    function treasuryValueAdj() external view returns ( uint ) {
        uint value = 0;
        for( uint i = 0; i < reserveTokens.length; i++ ) {
            if ( reserveTokens[i] != address(0) ) {
                uint balance = IERC20(reserveTokens[i]).balanceOf(treasury);
                value += ITreasury(treasury).valueOf(reserveTokens[i], balance);
            }
        }
        return value / 1e18;
    }

    function setTreasuryAddress( address _treasury ) external onlyPolicy() {
        treasury = _treasury;
    }

    function addReserveContract( address _token ) external onlyPolicy() {
        require( _token != address(0) );
        reserveTokens.push( _token );
    }

    function removeReserveContract( uint _index ) external onlyPolicy() {
        reserveTokens[ _index ] = address(0);
    }
}