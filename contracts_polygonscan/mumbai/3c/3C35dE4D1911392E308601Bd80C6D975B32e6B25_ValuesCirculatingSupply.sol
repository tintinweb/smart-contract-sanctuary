// SPDX-License-Identifier: AGPL-3.0-or-later\
pragma solidity 0.7.5;

import '../interfaces/IERC20.sol';

import '../libraries/SafeMath.sol';

contract ValuesCirculatingSupply {
    using SafeMath for uint256;

    bool public isInitialized;

    address public VALUES;
    address public owner;
    address[] public nonCirculatingVALUESAddresses;

    constructor(address _owner) {
        owner = _owner;
    }

    function initialize(address _values) external returns (bool) {
        require(msg.sender == owner, 'caller is not owner');
        require(isInitialized == false);

        VALUES = _values;

        isInitialized = true;

        return true;
    }

    function VALUESCirculatingSupply() external view returns (uint256) {
        uint256 _totalSupply = IERC20(VALUES).totalSupply();

        uint256 _circulatingSupply = _totalSupply.sub(
            getNonCirculatingVALUES()
        );

        return _circulatingSupply;
    }

    function getNonCirculatingVALUES() public view returns (uint256) {
        uint256 _nonCirculatingVALUES;

        for (
            uint256 i = 0;
            i < nonCirculatingVALUESAddresses.length;
            i = i.add(1)
        ) {
            _nonCirculatingVALUES = _nonCirculatingVALUES.add(
                IERC20(VALUES).balanceOf(nonCirculatingVALUESAddresses[i])
            );
        }

        return _nonCirculatingVALUES;
    }

    function setNonCirculatingVALUESAddresses(
        address[] calldata _nonCirculatingAddresses
    ) external returns (bool) {
        require(msg.sender == owner, 'Sender is not owner');
        nonCirculatingVALUESAddresses = _nonCirculatingAddresses;

        return true;
    }

    function transferOwnership(address _owner) external returns (bool) {
        require(msg.sender == owner, 'Sender is not owner');

        owner = _owner;

        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
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

// SPDX-License-Identifier: AGPL-3.0-or-later
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