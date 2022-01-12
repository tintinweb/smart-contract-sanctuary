// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './interfaces/IERC20.sol';
import './interfaces/IValuesStaking.sol';
import './libraries/SafeMath.sol';

contract ValuesStakingHelper {
    using SafeMath for uint256;

    address public immutable staking;
    address public immutable VALUES;

    constructor(address _staking, address _VALUES) {
        require(_staking != address(0));
        staking = _staking;
        require(_VALUES != address(0));
        VALUES = _VALUES;
    }

    function stake(uint256 _amount, address _recipient) external {
        IERC20(VALUES).transferFrom(msg.sender, address(this), _amount);
        IERC20(VALUES).approve(staking, _amount);
        IValuesStaking(staking).stake(_amount, _recipient);
        IValuesStaking(staking).claim(_recipient);
    }

    function stakeToMany(
        uint256 _amount,
        address[] memory _recipients,
        uint256[] memory _shares
    ) external {
        require(
            _shares.length > 0 && _recipients.length > 0,
            'Must be at least one recipient and one share'
        );
        require(
            _shares.length == _recipients.length,
            'Recipients and shares length must be equal'
        );
        uint256 totalShare = 0;
        for (uint256 i; i < _shares.length; i++) {
            totalShare = totalShare + _shares[i];
        }
        require(
            totalShare == uint256(100000),
            'Total shares must equal 100000'
        );
        IERC20(VALUES).transferFrom(msg.sender, address(this), _amount);
        IERC20(VALUES).approve(staking, _amount);
        for (uint256 i; i < _recipients.length; i++) {
            uint256 _recipientAmount = _calculateShareAmount(
                _shares[i],
                _amount
            );
            IValuesStaking(staking).stake(_recipientAmount, _recipients[i]);
            IValuesStaking(staking).claim(_recipients[i]);
        }
    }

    function _calculateShareAmount(uint256 share, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return amount.mul(share).div(uint256(100000));
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

interface IValuesStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;
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