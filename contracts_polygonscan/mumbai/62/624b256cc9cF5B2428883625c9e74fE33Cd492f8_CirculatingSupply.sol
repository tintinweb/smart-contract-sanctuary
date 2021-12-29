// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

import "./interfaces/IERC20.sol";

import "./libraries/SafeMath.sol";

contract CirculatingSupply {
    using SafeMath for uint;

    bool public isInitialized;

    address public BRAVO;
    address public owner;
    address[] public nonCirculatingBRAVOAddresses;

    constructor( address _owner ) {
        owner = _owner;
    }

    function initialize( address _BRAVO ) external returns ( bool ) {
        require( msg.sender == owner, "caller is not owner" );
        require( isInitialized == false );

        BRAVO = _BRAVO;

        isInitialized = true;

        return true;
    }

    function BRAVOCirculatingSupply() external view returns ( uint ) {
        uint _totalSupply = IERC20( BRAVO ).totalSupply();

        uint _circulatingSupply = _totalSupply.sub( getNonCirculatingBRAVO() );

        return _circulatingSupply;
    }

    function getNonCirculatingBRAVO() public view returns ( uint ) {
        uint _nonCirculatingBRAVO;

        for( uint i=0; i < nonCirculatingBRAVOAddresses.length; i = i.add( 1 ) ) {
            _nonCirculatingBRAVO = _nonCirculatingBRAVO.add( IERC20( BRAVO ).balanceOf( nonCirculatingBRAVOAddresses[i] ) );
        }

        return _nonCirculatingBRAVO;
    }

    function setNonCirculatingBRAVOAddresses( address[] calldata _nonCirculatingAddresses ) external returns ( bool ) {
        require( msg.sender == owner, "Sender is not owner" );
        nonCirculatingBRAVOAddresses = _nonCirculatingAddresses;

        return true;
    }

    function transferOwnership( address _owner ) external returns ( bool ) {
        require( msg.sender == owner, "Sender is not owner" );

        owner = _owner;

        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0
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

// SPDX-License-Identifier: AGPL-3.0
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