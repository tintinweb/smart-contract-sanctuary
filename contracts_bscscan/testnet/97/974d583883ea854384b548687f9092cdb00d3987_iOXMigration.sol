/**
 *Submitted for verification at BscScan.com on 2021-12-14
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
// --- Interface IOwnable
// ----------------------------------------------------------------------------

interface IOwnable {

  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}

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
// --- Library SafeMath
// ----------------------------------------------------------------------------

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

    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

    function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
      return mul( multiplier_, supply_ );
  }
}

// ----------------------------------------------------------------------------
// --- Contract Ownable
// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------
// --- Contract iOXMigration
// ----------------------------------------------------------------------------

contract iOXMigration is Ownable {
    using SafeMath for uint256;

    uint256 swapEndBlock;

    IERC20 public OX;
    IERC20 public iOX;
    
    bool public isInitialized;

    mapping(address => uint256) public senderInfo;
    
    modifier onlyInitialized() {
        require(isInitialized, "not initialized");
        _;
    }
    
    modifier notInitialized() {
        require( !isInitialized, "already initialized" );
        _;
    }

    function initialize (
        address _OX,
        address _iOX,
        uint256 _swapDuration
    ) public onlyOwner() notInitialized() {
        OX = IERC20(_OX);
        iOX = IERC20(_iOX);
        swapEndBlock = block.number.add(_swapDuration);
        isInitialized = true;
    }

    function migrate(uint256 amount) external onlyInitialized() {
        require(
            iOX.balanceOf(msg.sender) >= amount,
            "amount above user balance"
        );
        require(block.number < swapEndBlock, "swapping of iOX has ended");

        iOX.transferFrom(msg.sender, address(this), amount);
        senderInfo[msg.sender] = senderInfo[msg.sender].add(amount);
        OX.transfer(msg.sender, amount);
    }

    function reclaim() external {
        require(senderInfo[msg.sender] > 0, "user has no iOX to withdraw");
        require(
            block.number > swapEndBlock,
            "iOX swap is still ongoing"
        );

        uint256 amount = senderInfo[msg.sender];
        senderInfo[msg.sender] = 0;
        iOX.transfer(msg.sender, amount);
    }

    function withdraw() external onlyOwner() {
        require(block.number > swapEndBlock, "swapping of iOX has not ended");
        uint256 amount = OX.balanceOf(address(this));

        OX.transfer(msg.sender, amount);
    }
}