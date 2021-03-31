/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

//
//        __  __    __  ________  _______    ______   ________ 
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/ 
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__    
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |   
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/    
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____ 
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/ 
//
// dHEDGE DAO - https://dhedge.org
//
// MIT License
// ===========
//
// Copyright (c) 2020 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//


// File: contracts/ISynthetix.sol

pragma solidity ^0.6.2;

interface ISynthetix {
    function exchange(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint256 amountReceived);

    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external returns (uint256 amountReceived);

    function synths(bytes32 key)
        external
        view
        returns (address synthTokenAddress);

    function settle(bytes32 currencyKey)
        external
        returns (
            uint256 reclaimed,
            uint256 refunded,
            uint256 numEntriesSettled
        );
}

// File: contracts/IExchangeRates.sol

pragma solidity ^0.6.2;

interface IExchangeRates {
    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256);

    function rateForCurrency(bytes32 currencyKey)
        external
        view
        returns (uint256);
}

// File: contracts/IAddressResolver.sol

pragma solidity ^0.6.2;

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);
}

// File: contracts/IExchanger.sol

pragma solidity ^0.6.2;

interface IExchanger {

    function settle(address from, bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) external view returns (uint);

    function settlementOwing(address account, bytes32 currencyKey)
        external
        view
        returns (
            uint reclaimAmount,
            uint rebateAmount,
            uint numEntries
        );

}

// File: contracts/ISynth.sol

pragma solidity ^0.6.2;

interface ISynth {
    function proxy() external view returns (address);

    // Mutative functions
    function transferAndSettle(address to, uint256 value)
        external
        returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// File: contracts/ISystemStatus.sol

pragma solidity ^0.6.2;

interface ISystemStatus {
    struct Status {
        bool canSuspend;
        bool canResume;
    }

    struct Suspension {
        bool suspended;
        // reason is an integer code,
        // 0 => no reason, 1 => upgrading, 2+ => defined by system usage
        uint248 reason;
    }

    // Views
//    function getSynthExchangeSuspensions(bytes32[] calldata synths)
//        external
//        view
//        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function synthExchangeSuspension(bytes32 currencyKey)
        external
        view
        returns (bool suspended, uint248 reason);

}

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/Managed.sol

//
//        __  __    __  ________  _______    ______   ________ 
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/ 
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__    
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |   
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/    
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____ 
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/ 
//
// dHEDGE DAO - https://dhedge.org
//
// MIT License
// ===========
//
// Copyright (c) 2020 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//

pragma solidity ^0.6.0;




contract Managed is Initializable {
    using SafeMath for uint256;

    event ManagerUpdated(address newManager, string newManagerName);

    address private _manager;
    string private _managerName;

    address[] private _memberList;
    mapping(address => uint256) private _memberPosition;

    address private _trader;

    function initialize(address manager, string memory managerName)
        internal
        initializer
    {
        _manager = manager;
        _managerName = managerName;
    }

    modifier onlyManager() {
        require(msg.sender == _manager, "only manager");
        _;
    }

    modifier onlyManagerOrTrader() {
        require(msg.sender == _manager || msg.sender == _trader, "only manager or trader");
        _;
    }

    function managerName() public view returns (string memory) {
        return _managerName;
    }

    function manager() public view returns (address) {
        return _manager;
    }

    function isMemberAllowed(address member) public view returns (bool) {
        return _memberPosition[member] != 0;
    }

    function getMembers() public view returns (address[] memory) {
        return _memberList;
    }

    function changeManager(address newManager, string memory newManagerName)
        public
        onlyManager
    {
        _manager = newManager;
        _managerName = newManagerName;
        emit ManagerUpdated(newManager, newManagerName);
    }

    function addMembers(address[] memory members) public onlyManager {
        for (uint256 i = 0; i < members.length; i++) {
            if (isMemberAllowed(members[i]))
                continue;

            _addMember(members[i]);
        }
    }

    function removeMembers(address[] memory members) public onlyManager {
        for (uint256 i = 0; i < members.length; i++) {
            if (!isMemberAllowed(members[i]))
                continue;

            _removeMember(members[i]);
        }
    }

    function addMember(address member) public onlyManager {
        if (isMemberAllowed(member))
            return;

        _addMember(member);
    }

    function removeMember(address member) public onlyManager {
        if (!isMemberAllowed(member))
            return;

        _removeMember(member);
    }

    function trader() public view returns (address) {
        return _trader;
    }

    function setTrader(address newTrader) public onlyManager {
        _trader = newTrader;
    }

    function removeTrader() public onlyManager {
        _trader = address(0);
    }

    function numberOfMembers() public view returns (uint256) {
        return _memberList.length;
    }

    function _addMember(address member) internal {
        _memberList.push(member);
        _memberPosition[member] = _memberList.length;
    }

    function _removeMember(address member) internal {
        uint256 length = _memberList.length;
        uint256 index = _memberPosition[member].sub(1);

        address lastMember = _memberList[length.sub(1)];

        _memberList[index] = lastMember;
        _memberPosition[lastMember] = index.add(1);
        _memberPosition[member] = 0;

        _memberList.pop();
    }

    uint256[49] private __gap;
}

// File: contracts/IHasDaoInfo.sol

//
//        __  __    __  ________  _______    ______   ________ 
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/ 
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__    
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |   
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/    
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____ 
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/ 
//
// dHEDGE DAO - https://dhedge.org
//
// MIT License
// ===========
//
// Copyright (c) 2020 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//


pragma solidity ^0.6.2;

interface IHasDaoInfo {
    function getDaoFee() external view returns (uint256, uint256);

    function getDaoAddress() external view returns (address);

    function getAddressResolver() external view returns (IAddressResolver);
}

// File: contracts/IHasProtocolDaoInfo.sol

//
//        __  __    __  ________  _______    ______   ________ 
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/ 
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__    
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |   
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/    
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____ 
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/ 
//
// dHEDGE DAO - https://dhedge.org
//
// MIT License
// ===========
//
// Copyright (c) 2020 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//


pragma solidity ^0.6.2;

interface IHasProtocolDaoInfo {
    function owner() external view returns (address);
}

// File: contracts/IHasFeeInfo.sol

//
//        __  __    __  ________  _______    ______   ________ 
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/ 
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__    
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |   
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/    
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____ 
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/ 
//
// dHEDGE DAO - https://dhedge.org
//
// MIT License
// ===========
//
// Copyright (c) 2020 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//

pragma solidity ^0.6.2;

interface IHasFeeInfo {
    // Manager fee
    function getPoolManagerFee(address pool) external view returns (uint256, uint256);
    function setPoolManagerFeeNumerator(address pool, uint256 numerator) external;

    function getMaximumManagerFeeNumeratorChange() external view returns (uint256);
    function getManagerFeeNumeratorChangeDelay() external view returns (uint256);
   
    // Exit fee
    function getExitFee() external view returns (uint256, uint256);
    function getExitFeeCooldown() external view returns (uint256);

    // Synthetix tracking
    function getTrackingCode() external view returns (bytes32);
}

// File: contracts/IHasAssetInfo.sol

//
//        __  __    __  ________  _______    ______   ________ 
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/ 
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__    
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |   
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/    
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____ 
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/ 
//
// dHEDGE DAO - https://dhedge.org
//
// MIT License
// ===========
//
// Copyright (c) 2020 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//

pragma solidity ^0.6.2;

interface IHasAssetInfo {
    function getMaximumSupportedAssetCount() external view returns (uint256);
}

// File: contracts/IReceivesUpgrade.sol

//
//        __  __    __  ________  _______    ______   ________ 
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/ 
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__    
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |   
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/    
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____ 
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/ 
//
// dHEDGE DAO - https://dhedge.org
//
// MIT License
// ===========
//
// Copyright (c) 2020 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//

pragma solidity ^0.6.2;

interface IReceivesUpgrade {
    function receiveUpgrade(uint256 targetVersion) external;
}

// File: contracts/IHasDhptSwapInfo.sol

//
//        __  __    __  ________  _______    ______   ________ 
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/ 
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__    
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |   
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/    
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____ 
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/ 
//
// dHEDGE DAO - https://dhedge.org
//
// MIT License
// ===========
//
// Copyright (c) 2020 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//

pragma solidity ^0.6.2;

interface IHasDhptSwapInfo {
    // DHPT Swap Address
    function getDhptSwapAddress() external view returns (address);
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.6.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.6.0;






/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


        _name = name;
        _symbol = symbol;
        _decimals = 18;

    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    uint256[44] private __gap;
}

// File: contracts/DHedge.sol

//
//        __  __    __  ________  _______    ______   ________ 
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/ 
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__    
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |   
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/    
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____ 
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/ 
//
// dHEDGE DAO - https://dhedge.org
//
// MIT License
// ===========
//
// Copyright (c) 2020 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//

pragma solidity ^0.6.2;


















contract DHedge is Initializable, ERC20UpgradeSafe, Managed, IReceivesUpgrade {
    using SafeMath for uint256;

    bytes32 constant private _EXCHANGE_RATES_KEY = "ExchangeRates";
    bytes32 constant private _SYNTHETIX_KEY = "Synthetix";
    bytes32 constant private _EXCHANGER_KEY = "Exchanger";
    bytes32 constant private _SYSTEM_STATUS_KEY = "SystemStatus";
    bytes32 constant private _SUSD_KEY = "sUSD";

    event Deposit(
        address fundAddress,
        address investor,
        uint256 valueDeposited,
        uint256 fundTokensReceived,
        uint256 totalInvestorFundTokens,
        uint256 fundValue,
        uint256 totalSupply,
        uint256 time
    );
    event Withdrawal(
        address fundAddress,
        address investor,
        uint256 valueWithdrawn,
        uint256 fundTokensWithdrawn,
        uint256 totalInvestorFundTokens,
        uint256 fundValue,
        uint256 totalSupply,
        uint256 time
    );
    event Exchange(
        address fundAddress,
        address manager,
        bytes32 sourceKey,
        uint256 sourceAmount,
        bytes32 destinationKey,
        uint256 destinationAmount,
        uint256 time
    );
    event AssetAdded(address fundAddress, address manager, bytes32 assetKey);
    event AssetRemoved(address fundAddress, address manager, bytes32 assetKey);

    event PoolPrivacyUpdated(bool isPoolPrivate);

    event ManagerFeeMinted(
        address pool,
        address manager,
        uint256 available,
        uint256 daoFee,
        uint256 managerFee,
        uint256 tokenPriceAtLastFeeMint
    );

    event ManagerFeeSet(
        address fundAddress,
        address manager,
        uint256 numerator,
        uint256 denominator
    );

    event ManagerFeeIncreaseAnnounced(
        uint256 newNumerator,
        uint256 announcedFeeActivationTime);

    event ManagerFeeIncreaseRenounced();

    bool public privatePool;
    address public creator;

    uint256 public creationTime;

    IAddressResolver public addressResolver;

    address public factory;

    bytes32[] public supportedAssets;
    mapping(bytes32 => uint256) public assetPosition; // maps the asset to its 1-based position

    mapping(bytes32 => bool) public persistentAsset;

    // Manager fees
    uint256 public tokenPriceAtLastFeeMint;

    mapping(address => uint256) public lastDeposit;

    // Fee increase announcement
    uint256 public announcedFeeIncreaseNumerator;
    uint256 public announcedFeeIncreaseTimestamp;

    modifier onlyPrivate() {
        require(
            msg.sender == manager() ||
                !privatePool ||
                isMemberAllowed(msg.sender),
            "only members allowed"
        );
        _;
    }

    function initialize(
        address _factory,
        bool _privatePool,
        address _manager,
        string memory _managerName,
        string memory _fundName,
        string memory _fundSymbol,
        IAddressResolver _addressResolver,
        bytes32[] memory _supportedAssets
    ) public initializer {
        ERC20UpgradeSafe.__ERC20_init(_fundName, _fundSymbol);
        Managed.initialize(_manager, _managerName);

        factory = _factory;
        _setPoolPrivacy(_privatePool);
        creator = msg.sender;
        creationTime = block.timestamp;
        addressResolver = _addressResolver;

        _addToSupportedAssets(_SUSD_KEY);

        for(uint8 i = 0; i < _supportedAssets.length; i++) {
            _addToSupportedAssets(_supportedAssets[i]);
        }

        // Set persistent assets
        persistentAsset[_SUSD_KEY] = true;

        tokenPriceAtLastFeeMint = 10**18;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override
    {
        super._beforeTokenTransfer(from, to, amount);

        require(getExitFeeRemainingCooldown(from) == 0, "cooldown active");
    }

    function setPoolPrivate(bool _privatePool) public onlyManager {
        require(privatePool != _privatePool, "flag must be different");

        _setPoolPrivacy(_privatePool);
    }

    function _setPoolPrivacy(bool _privacy) internal {
        privatePool = _privacy;

        emit PoolPrivacyUpdated(_privacy);
    }

    function getAssetProxy(bytes32 key) public view returns (address) {
        address synth = ISynthetix(addressResolver.getAddress(_SYNTHETIX_KEY))
            .synths(key);
        require(synth != address(0), "invalid key");
        address proxy = ISynth(synth).proxy();
        require(proxy != address(0), "invalid proxy");
        return proxy;
    }

    function isAssetSupported(bytes32 key) public view returns (bool) {
        return assetPosition[key] != 0;
    }

    function validateAsset(bytes32 key) public view returns (bool) {
        address synth = ISynthetix(addressResolver.getAddress(_SYNTHETIX_KEY))
            .synths(key);

        if (synth == address(0))
            return false;

        address proxy = ISynth(synth).proxy();

        if (proxy == address(0))
            return false;

        return true;
    }

    function addToSupportedAssets(bytes32 key) public onlyManagerOrTrader {
        _addToSupportedAssets(key);
    }

    function removeFromSupportedAssets(bytes32 key) public {
        require(msg.sender == IHasProtocolDaoInfo(factory).owner() ||
            msg.sender == manager() ||
            msg.sender == trader(), "only manager, trader or Protocol DAO");

        require(isAssetSupported(key), "asset not supported");

        require(!persistentAsset[key], "persistent assets can't be removed");
        
        if (validateAsset(key) == true) { // allow removal of depreciated synths
            require(
                IERC20(getAssetProxy(key)).balanceOf(address(this)) == 0,
                "non-empty asset cannot be removed"
            );
        }
        

        _removeFromSupportedAssets(key);
    }

    function numberOfSupportedAssets() public view returns (uint256) {
        return supportedAssets.length;
    }

    // Unsafe internal method that assumes we are not adding a duplicate
    function _addToSupportedAssets(bytes32 key) internal {
        require(supportedAssets.length < IHasAssetInfo(factory).getMaximumSupportedAssetCount(), "maximum assets reached");
        require(!isAssetSupported(key), "asset already supported");
        require(validateAsset(key) == true, "not an asset");

        supportedAssets.push(key);
        assetPosition[key] = supportedAssets.length;

        emit AssetAdded(address(this), manager(), key);
    }

    // Unsafe internal method that assumes we are removing an element that exists
    function _removeFromSupportedAssets(bytes32 key) internal {
        uint256 length = supportedAssets.length;
        uint256 index = assetPosition[key].sub(1); // adjusting the index because the map stores 1-based

        bytes32 lastAsset = supportedAssets[length.sub(1)];

        // overwrite the asset to be removed with the last supported asset
        supportedAssets[index] = lastAsset;
        assetPosition[lastAsset] = index.add(1); // adjusting the index to be 1-based
        assetPosition[key] = 0; // update the map

        // delete the last supported asset and resize the array
        supportedAssets.pop();

        emit AssetRemoved(address(this), manager(), key);
    }

    function exchange(
        bytes32 sourceKey,
        uint256 sourceAmount,
        bytes32 destinationKey
    ) public onlyManagerOrTrader {
        require(isAssetSupported(sourceKey), "unsupported source currency");
        require(
            isAssetSupported(destinationKey),
            "unsupported destination currency"
        );

        ISynthetix sx = ISynthetix(addressResolver.getAddress(_SYNTHETIX_KEY));

        uint256 destinationAmount = sx.exchangeWithTracking(
            sourceKey,
            sourceAmount,
            destinationKey,
            IHasDaoInfo(factory).getDaoAddress(),
            IHasFeeInfo(factory).getTrackingCode()
        );

        emit Exchange(
            address(this),
            msg.sender,
            sourceKey,
            sourceAmount,
            destinationKey,
            destinationAmount,
            block.timestamp
        );
    }

    function totalFundValue() public virtual view returns (uint256) {
        uint256 total = 0;
        uint256 assetCount = supportedAssets.length;

        for (uint256 i = 0; i < assetCount; i++) {
            total = total.add(assetValue(supportedAssets[i]));
        }
        return total;
    }

    function assetValue(bytes32 key) public view returns (uint256) {
        return
            IExchangeRates(addressResolver.getAddress(_EXCHANGE_RATES_KEY))
                .effectiveValue(
                key,
                IERC20(getAssetProxy(key)).balanceOf(address(this)),
                _SUSD_KEY
            );
    }

    function deposit(uint256 _susdAmount) public onlyPrivate returns (uint256) {
        lastDeposit[msg.sender] = block.timestamp;

        //we need to settle all the assets before determining the total fund value for calculating manager fees
        //as an optimisation it also returns current fundValue
        uint256 fundValue = mintManagerFee(true);

        uint256 totalSupplyBefore = totalSupply();

        IExchanger sx = IExchanger(addressResolver.getAddress(_EXCHANGER_KEY));

        require(
            IERC20(getAssetProxy(_SUSD_KEY)).transferFrom(
                msg.sender,
                address(this),
                _susdAmount
            ),
            "token transfer failed"
        );

        uint256 liquidityMinted;
        if (totalSupplyBefore > 0) {
            //total balance converted to susd that this contract holds
            //need to calculate total value of synths in this contract
            liquidityMinted = _susdAmount.mul(totalSupplyBefore).div(fundValue);
        } else {
            liquidityMinted = _susdAmount;
        }

        _mint(msg.sender, liquidityMinted);

        emit Deposit(
            address(this),
            msg.sender,
            _susdAmount,
            liquidityMinted,
            balanceOf(msg.sender),
            fundValue.add(_susdAmount),
            totalSupplyBefore.add(liquidityMinted),
            block.timestamp
        );

        return liquidityMinted;
    }

    function _settleAll(bool failOnSuspended) internal {
        ISynthetix sx = ISynthetix(addressResolver.getAddress(_SYNTHETIX_KEY));
        ISystemStatus status = ISystemStatus(addressResolver.getAddress(_SYSTEM_STATUS_KEY));

        uint256 assetCount = supportedAssets.length;

        for (uint256 i = 0; i < assetCount; i++) {

            address proxy = getAssetProxy(supportedAssets[i]);
            uint256 totalAssetBalance = IERC20(proxy).balanceOf(address(this));

            if (totalAssetBalance > 0) {
                sx.settle(supportedAssets[i]);
                if (failOnSuspended) {
                    (bool suspended, ) = status.synthExchangeSuspension(supportedAssets[i]);
                    require(!suspended , "required asset is suspended");
                }
            }

        }
    }

    function withdraw(uint256 _fundTokenAmount) public virtual {
        require(
            balanceOf(msg.sender) >= _fundTokenAmount,
            "insufficient balance of fund tokens"
        );

        require(
            getExitFeeRemainingCooldown(msg.sender) == 0,
            "cooldown active"
        );

        uint256 fundValue = mintManagerFee(false);
        uint256 valueWithdrawn = _fundTokenAmount.mul(fundValue).div(totalSupply());

        //calculate the proportion
        uint256 portion = _fundTokenAmount.mul(10**18).div(totalSupply());

        //first return funded tokens
        _burn(msg.sender, _fundTokenAmount);

        uint256 assetCount = supportedAssets.length;

        for (uint256 i = 0; i < assetCount; i++) {
            address proxy = getAssetProxy(supportedAssets[i]);
            uint256 totalAssetBalance = IERC20(proxy).balanceOf(address(this));
            uint256 portionOfAssetBalance = totalAssetBalance.mul(portion).div(10**18);

            if (portionOfAssetBalance > 0) {
                IERC20(proxy).transfer(msg.sender, portionOfAssetBalance);
            }
        }

        emit Withdrawal(
            address(this),
            msg.sender,
            valueWithdrawn,
            _fundTokenAmount,
            balanceOf(msg.sender),
            fundValue.sub(valueWithdrawn),
            totalSupply(),
            block.timestamp
        );
    }

    function getFundSummary()
        public
        view
        returns (
            string memory,
            uint256,
            uint256,
            address,
            string memory,
            uint256,
            bool,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {

        uint256 managerFeeNumerator;
        uint256 managerFeeDenominator;
        (managerFeeNumerator, managerFeeDenominator) = IHasFeeInfo(factory).getPoolManagerFee(address(this));

        uint256 exitFeeNumerator = 0;
        uint256 exitFeeDenominator = 1;

        return (
            name(),
            totalSupply(),
            totalFundValue(),
            manager(),
            managerName(),
            creationTime,
            privatePool,
            managerFeeNumerator,
            managerFeeDenominator,
            exitFeeNumerator,
            exitFeeDenominator
        );
    }

    function getSupportedAssets() public view returns (bytes32[] memory) {
        return supportedAssets;
    }

    function getFundComposition()
        public
        view
        returns (
            bytes32[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 assetCount = supportedAssets.length;

        bytes32[] memory assets = new bytes32[](assetCount);
        uint256[] memory balances = new uint256[](assetCount);
        uint256[] memory rates = new uint256[](assetCount);

        IExchangeRates exchangeRates = IExchangeRates(
            addressResolver.getAddress(_EXCHANGE_RATES_KEY)
        );
        for (uint256 i = 0; i < assetCount; i++) {
            bytes32 asset = supportedAssets[i];
            balances[i] = IERC20(getAssetProxy(asset)).balanceOf(address(this));
            assets[i] = asset;
            rates[i] = exchangeRates.rateForCurrency(asset);
        }
        return (assets, balances, rates);
    }

    function getWaitingPeriods()
        public
        view
        returns (
            bytes32[] memory,
            uint256[] memory
        )
    {
        uint256 assetCount = supportedAssets.length;

        bytes32[] memory assets = new bytes32[](assetCount);
        uint256[] memory periods = new uint256[](assetCount);

        IExchanger exchanger = IExchanger(addressResolver.getAddress(_EXCHANGER_KEY));

        for (uint256 i = 0; i < assetCount; i++) {
            bytes32 asset = supportedAssets[i];
            assets[i] = asset;
            periods[i] = exchanger.maxSecsLeftInWaitingPeriod(address(this), asset);
        }

        return (assets, periods);
    }

    // MANAGER FEES

    function tokenPrice() public view returns (uint256) {
        uint256 fundValue = totalFundValue();
        uint256 tokenSupply = totalSupply();

        return _tokenPrice(fundValue, tokenSupply);
    }

    function _tokenPrice(uint256 _fundValue, uint256 _tokenSupply)
        internal
        pure
        returns (uint256)
    {
        if (_tokenSupply == 0 || _fundValue == 0) return 0;

        return _fundValue.mul(10**18).div(_tokenSupply);
    }

    function availableManagerFee() public view returns (uint256) {
        uint256 fundValue = totalFundValue();
        uint256 tokenSupply = totalSupply();

        uint256 managerFeeNumerator;
        uint256 managerFeeDenominator;
        (managerFeeNumerator, managerFeeDenominator) = IHasFeeInfo(factory).getPoolManagerFee(address(this));

        return
            _availableManagerFee(
                fundValue,
                tokenSupply,
                tokenPriceAtLastFeeMint,
                managerFeeNumerator,
                managerFeeDenominator
            );
    }

    function _availableManagerFee(
        uint256 _fundValue,
        uint256 _tokenSupply,
        uint256 _lastFeeMintPrice,
        uint256 _feeNumerator,
        uint256 _feeDenominator
    ) internal pure returns (uint256) {
        if (_tokenSupply == 0 || _fundValue == 0) return 0;

        uint256 currentTokenPrice = _fundValue.mul(10**18).div(_tokenSupply);

        if (currentTokenPrice <= _lastFeeMintPrice) return 0;

        uint256 available = currentTokenPrice
            .sub(_lastFeeMintPrice)
            .mul(_tokenSupply)
            .mul(_feeNumerator)
            .div(_feeDenominator)
            .div(currentTokenPrice);

        return available;
    }

    //returns uint256 fundValue as a gas optimisation
    function mintManagerFee(bool failOnSuspended) public returns (uint256) {
        //we need to settle all the assets before minting the manager fee
        _settleAll(failOnSuspended);

        uint256 fundValue = totalFundValue();
        uint256 tokenSupply = totalSupply();

        uint256 managerFeeNumerator;
        uint256 managerFeeDenominator;
        (managerFeeNumerator, managerFeeDenominator) = IHasFeeInfo(factory).getPoolManagerFee(address(this));

        uint256 available = _availableManagerFee(
            fundValue,
            tokenSupply,
            tokenPriceAtLastFeeMint,
            managerFeeNumerator,
            managerFeeDenominator
        );

        // Ignore dust when minting performance fees
        if (available < 100)
            return fundValue;

        address daoAddress = IHasDaoInfo(factory).getDaoAddress();
        uint256 daoFeeNumerator;
        uint256 daoFeeDenominator;

        (daoFeeNumerator, daoFeeDenominator) = IHasDaoInfo(factory).getDaoFee();

        uint256 daoFee = available.mul(daoFeeNumerator).div(daoFeeDenominator);
        uint256 managerFee = available.sub(daoFee);

        if (daoFee > 0) _mint(daoAddress, daoFee);

        if (managerFee > 0) _mint(manager(), managerFee);

        tokenPriceAtLastFeeMint = _tokenPrice(fundValue, tokenSupply);

        emit ManagerFeeMinted(
            address(this),
            manager(),
            available,
            daoFee,
            managerFee,
            tokenPriceAtLastFeeMint
        );

        return fundValue;
    }

    function getManagerFee() public view returns (uint256, uint256) {
        return IHasFeeInfo(factory).getPoolManagerFee(address(this));
    }

    function setManagerFeeNumerator(uint256 numerator) public onlyManager {
        uint256 managerFeeNumerator;
        uint256 managerFeeDenominator;
        (managerFeeNumerator, managerFeeDenominator) = IHasFeeInfo(factory).getPoolManagerFee(address(this));

        require(numerator < managerFeeNumerator, "manager fee too high");

        IHasFeeInfo(factory).setPoolManagerFeeNumerator(address(this), numerator);

        emit ManagerFeeSet(
            address(this),
            manager(),
            numerator,
            managerFeeDenominator
        );
    }

    function _setManagerFeeNumerator(uint256 numerator) internal {
        IHasFeeInfo(factory).setPoolManagerFeeNumerator(address(this), numerator);
        
        uint256 managerFeeNumerator;
        uint256 managerFeeDenominator;
        (managerFeeNumerator, managerFeeDenominator) = IHasFeeInfo(factory).getPoolManagerFee(address(this));

        emit ManagerFeeSet(
            address(this),
            manager(),
            managerFeeNumerator,
            managerFeeDenominator
        );
    }

    function announceManagerFeeIncrease(uint256 numerator) public onlyManager {
        uint256 maximumAllowedChange = IHasFeeInfo(factory).getMaximumManagerFeeNumeratorChange();

        uint256 currentFeeNumerator;
        (currentFeeNumerator, ) = getManagerFee();

        require (numerator <= currentFeeNumerator.add(maximumAllowedChange), "exceeded allowed increase");

        uint256 feeChangeDelay = IHasFeeInfo(factory).getManagerFeeNumeratorChangeDelay(); 

        announcedFeeIncreaseNumerator = numerator;
        announcedFeeIncreaseTimestamp = block.timestamp + feeChangeDelay;
        emit ManagerFeeIncreaseAnnounced(numerator, announcedFeeIncreaseTimestamp);
    }

    function renounceManagerFeeIncrease() public onlyManager {
        announcedFeeIncreaseNumerator = 0;
        announcedFeeIncreaseTimestamp = 0;
        emit ManagerFeeIncreaseRenounced();
    }

    function commitManagerFeeIncrease() public onlyManager {
        require(block.timestamp >= announcedFeeIncreaseTimestamp, "fee increase delay active");

        _setManagerFeeNumerator(announcedFeeIncreaseNumerator);

        announcedFeeIncreaseNumerator = 0;
        announcedFeeIncreaseTimestamp = 0;
    }

    function getManagerFeeIncreaseInfo() public view returns (uint256, uint256) {
        return (announcedFeeIncreaseNumerator, announcedFeeIncreaseTimestamp);
    }

    // Exit fees

    function getExitFee() external view returns (uint256, uint256) {
        return (0, 1);
    }

    function getExitFeeCooldown() external view returns (uint256) {
        return IHasFeeInfo(factory).getExitFeeCooldown();
    }

    function getExitFeeRemainingCooldown(address sender) public view returns (uint256) {
        uint256 cooldown = IHasFeeInfo(factory).getExitFeeCooldown();
        uint256 cooldownFinished = lastDeposit[sender].add(cooldown);

        if (cooldownFinished < block.timestamp)
            return 0;

        return cooldownFinished.sub(block.timestamp);
    }
    
    // Swap contract

    function setLastDeposit(address investor) public onlyDhptSwap {
        lastDeposit[investor] = block.timestamp;
    }

    modifier onlyDhptSwap() {
        address dhptSwapAddress = IHasDhptSwapInfo(factory)
            .getDhptSwapAddress();
        require(msg.sender == dhptSwapAddress, "only swap contract");
        _;
    }

    // Upgrade

    function receiveUpgrade(uint256 targetVersion) external override{
        require(msg.sender == factory, "no permission");

        if (targetVersion == 1) {
            addressResolver = IAddressResolver(0x4E3b31eB0E5CB73641EE1E65E7dCEFe520bA3ef2);
            return;
        }

        require(false, "upgrade handler not found");
    }

    uint256[50] private __gap;
}

// File: contracts/upgradability/Proxy.sol

pragma solidity ^0.6.2;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
    /**
     * @dev Fallback function.
     * Implemented entirely in `_fallback`.
     */
    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    /**
     * @return The Address of the implementation.
     */
    function _implementation() internal virtual view returns (address);

    /**
     * @dev Delegates execution to an implementation contract.
     * This is a low level function that doesn't return to its internal call site.
     * It will return to the external caller whatever the implementation returns.
     * @param implementation Address to delegate.
     */
    function _delegate(address implementation) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    /**
     * @dev Function that is run as the first thing in the fallback function.
     * Can be redefined in derived contracts to add functionality.
     * Redefinitions must call super._willFallback().
     */
    function _willFallback() internal virtual {}

    /**
     * @dev fallback implementation.
     * Extracted to enable manual triggering.
     */
    function _fallback() internal {
        _willFallback();
        _delegate(_implementation());
    }
}

// File: contracts/upgradability/Address.sol

pragma solidity ^0.6.2;

/**
 * Utility library of inline functions on addresses
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/utils/Address.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Address implementation from an openzeppelin version.
 */
library OpenZeppelinUpgradesAddress {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// File: contracts/upgradability/HasLogic.sol

//
//        __  __    __  ________  _______    ______   ________ 
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/ 
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__    
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |   
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/    
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____ 
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/ 
//
// dHEDGE DAO - https://dhedge.org
//
// MIT License
// ===========
//
// Copyright (c) 2020 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//

pragma solidity ^0.6.2;

interface HasLogic {
    function getLogic() external view returns (address);
}

// File: contracts/upgradability/BaseUpgradeabilityProxy.sol

pragma solidity ^0.6.2;




/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
    /**
     * @dev Emitted when the implementation is upgraded.
     * @param implementation Address of the new implementation.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32
        internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal override view returns (address) {
        address factory;
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            factory := sload(slot)
        }

        // Begin custom modification
        if (factory == address(0x0)) return address(0x0); // If factory not initialized return empty

        return HasLogic(factory).getLogic();
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     * @param newImplementation Address of the new implementation.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation address of the proxy.
     * @param newImplementation Address of the new implementation.
     */
    function _setImplementation(address newImplementation) internal {
        require(
            OpenZeppelinUpgradesAddress.isContract(newImplementation),
            "Cannot set a proxy implementation to a non-contract address"
        );

        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// File: contracts/upgradability/InitializableUpgradeabilityProxy.sol

pragma solidity ^0.6.2;


/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
     * @dev Contract initializer.
     * @param _factory Address of the factory containing the implementation.
     * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
     */
    function initialize(address _factory, bytes memory _data) public payable {
        require(_implementation() == address(0), "Impl not zero");
        assert(
            IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
        _setImplementation(_factory);
        if (_data.length > 0) {
            (bool success, ) = _implementation().delegatecall(_data);
            require(success);
        }
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

pragma solidity ^0.6.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// File: contracts/upgradability/ProxyFactory.sol

//
//        __  __    __  ________  _______    ______   ________ 
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/ 
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__    
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |   
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/    
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____ 
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/ 
//
// dHEDGE DAO - https://dhedge.org
//
// MIT License
// ===========
//
// Copyright (c) 2020 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//

pragma solidity ^0.6.2;




contract ProxyFactory is OwnableUpgradeSafe, HasLogic {
    event ProxyCreated(address proxy);

    address private _logic;

    function __ProxyFactory_init(address poolLogic) public initializer {
        OwnableUpgradeSafe.__Ownable_init();

        _logic = poolLogic;
    }

    function setLogic(address logic) public onlyOwner {
        _logic = logic;
    }

    function getLogic() public override view returns (address) {
        return _logic;
    }

    function deploy(bytes memory _data) public returns (address) {
        return _deployProxy(_data);
    }

    function _deployProxy(bytes memory _data) internal returns (address) {
        InitializableUpgradeabilityProxy proxy = _createProxy();
        emit ProxyCreated(address(proxy));
        proxy.initialize(address(this), _data);
        return address(proxy);
    }

    function _createProxy()
        internal
        returns (InitializableUpgradeabilityProxy)
    {
        address payable addr;
        bytes memory code = type(InitializableUpgradeabilityProxy).creationCode;

        assembly {
            addr := create(0, add(code, 0x20), mload(code))
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        return InitializableUpgradeabilityProxy(addr);
    }
    
    uint256[50] private __gap;
}

// File: contracts/DHedgeFactory.sol

//
//        __  __    __  ________  _______    ______   ________ 
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/ 
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__    
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |   
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/    
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____ 
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/ 
//
// dHEDGE DAO - https://dhedge.org
//
// MIT License
// ===========
//
// Copyright (c) 2020 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//

pragma solidity ^0.6.2;













contract DHedgeFactory is
    ProxyFactory,
    IHasDaoInfo,
    IHasFeeInfo,
    IHasAssetInfo,
    IHasDhptSwapInfo
{
    using SafeMath for uint256;

    event FundCreated(
        address fundAddress,
        bool isPoolPrivate,
        string fundName,
        string managerName,
        address manager,
        uint256 time,
        uint256 managerFeeNumerator,
        uint256 managerFeeDenominator
    );

    event DaoAddressSet(address dao);
    event DaoFeeSet(uint256 numerator, uint256 denominator);

    event ExitFeeSet(uint256 numerator, uint256 denominator);
    event ExitFeeCooldownSet(uint256 cooldown);

    event MaximumSupportedAssetCountSet(uint256 count);
    
    event DhptSwapAddressSet(address dhptSwap);

    IAddressResolver public addressResolver;

    address[] public deployedFunds;

    address internal _daoAddress;
    uint256 internal _daoFeeNumerator;
    uint256 internal _daoFeeDenominator;

    mapping (address => bool) public isPool;

    uint256 private _MAXIMUM_MANAGER_FEE_NUMERATOR;
    uint256 private _MANAGER_FEE_DENOMINATOR;
    mapping (address => uint256) public poolManagerFeeNumerator;
    mapping (address => uint256) public poolManagerFeeDenominator;

    uint256 internal _exitFeeNumerator;
    uint256 internal _exitFeeDenominator;
    uint256 internal _exitFeeCooldown;

    uint256 internal _maximumSupportedAssetCount;

    bytes32 internal _trackingCode;
    
    mapping (address => uint256) public poolVersion;
    uint256 public poolStorageVersion;

    address internal _dhptSwapAddress;

    uint256 public maximumManagerFeeNumeratorChange;
    uint256 public managerFeeNumeratorChangeDelay;

    function initialize(
        IAddressResolver _addressResolver,
        address _poolLogic,
        address daoAddress
    ) public initializer {

        ProxyFactory.__ProxyFactory_init(_poolLogic);

        addressResolver = _addressResolver;

        _setDaoAddress(daoAddress);

        _setMaximumManagerFee(5000, 10000);

        _setDaoFee(10, 100); // 10%
        _setExitFee(5, 1000); // 0.5%
        _setExitFeeCooldown(1 days);

        _setMaximumSupportedAssetCount(10);

        _setTrackingCode(
            0x4448454447450000000000000000000000000000000000000000000000000000
        );
    }

    function createFund(
        bool _privatePool,
        address _manager,
        string memory _managerName,
        string memory _fundName,
        string memory _fundSymbol,
        uint256 _managerFeeNumerator,
        bytes32[] memory _supportedAssets
    ) public returns (address) {
        bytes memory data = abi.encodeWithSignature(
            "initialize(address,bool,address,string,string,string,address,bytes32[])",
            address(this),
            _privatePool,
            _manager,
            _managerName,
            _fundName,
            _fundSymbol,
            addressResolver,
            _supportedAssets
        );

        address fund = deploy(data);

        deployedFunds.push(fund);
        isPool[fund] = true;

        poolVersion[fund] = poolStorageVersion;

        _setPoolManagerFee(fund, _managerFeeNumerator, _MANAGER_FEE_DENOMINATOR);

        emit FundCreated(
            fund,
            _privatePool,
            _fundName,
            _managerName,
            _manager,
            block.timestamp,
            _managerFeeNumerator,
            _MANAGER_FEE_DENOMINATOR
        );

        return fund;
    }

    function deployedFundsLength() external view returns (uint256) {
        return deployedFunds.length;
    }

    function setAddressResolver(address _addressResolver) public onlyOwner {
        addressResolver = IAddressResolver(_addressResolver);
    }

    function getAddressResolver() public override view returns (IAddressResolver) {
        return addressResolver;
    }

    // DAO info

    function getDaoAddress() public override view returns (address) {
        return _daoAddress;
    }

    function setDaoAddress(address daoAddress) public onlyOwner {
        _setDaoAddress(daoAddress);
    }

    function _setDaoAddress(address daoAddress) internal {
        _daoAddress = daoAddress;

        emit DaoAddressSet(daoAddress);
    }
    
    function setDaoFee(uint256 numerator, uint256 denominator) public onlyOwner {
        _setDaoFee(numerator, denominator);
    }

    function _setDaoFee(uint256 numerator, uint256 denominator) internal {
        require(numerator <= denominator, "invalid fraction");

        _daoFeeNumerator = numerator;
        _daoFeeDenominator = denominator;

        emit DaoFeeSet(numerator, denominator);
    }

    function getDaoFee() public override view returns (uint256, uint256) {
        return (_daoFeeNumerator, _daoFeeDenominator);
    }

    modifier onlyPool() {
        require(
            isPool[msg.sender] == true,
            "Only a pool contract can perform this action"
        );
        _;
    }

    // Manager fees

    function getPoolManagerFee(address pool) external override view returns (uint256, uint256) {
        require(isPool[pool] == true, "supplied address is not a pool");

        return (poolManagerFeeNumerator[pool], poolManagerFeeDenominator[pool]);
    }

    function setPoolManagerFeeNumerator(address pool, uint256 numerator) external override {
        require(pool == msg.sender && isPool[msg.sender] == true, "only a pool can change own fee");
        require(isPool[pool] == true, "supplied address is not a pool");
        require(numerator <= poolManagerFeeNumerator[pool].add(maximumManagerFeeNumeratorChange), "manager fee too high");

        _setPoolManagerFee(msg.sender, numerator, _MANAGER_FEE_DENOMINATOR);
    }

    function _setPoolManagerFee(address pool, uint256 numerator, uint256 denominator) internal {
        require(numerator <= denominator && numerator <= _MAXIMUM_MANAGER_FEE_NUMERATOR, "invalid fraction");

        poolManagerFeeNumerator[pool] = numerator;
        poolManagerFeeDenominator[pool] = denominator;
    }

    function getMaximumManagerFee() public view returns (uint256, uint256) {
        return (_MAXIMUM_MANAGER_FEE_NUMERATOR, _MANAGER_FEE_DENOMINATOR);
    }

    function _setMaximumManagerFee(uint256 numerator, uint256 denominator) internal {
        require(denominator > 0, "denominator must be positive");

        _MAXIMUM_MANAGER_FEE_NUMERATOR = numerator;
        _MANAGER_FEE_DENOMINATOR = denominator;
    }

    function setMaximumManagerFeeNumeratorChange(uint256 amount) public onlyOwner {
        maximumManagerFeeNumeratorChange = amount;
    }

    function getMaximumManagerFeeNumeratorChange() public override view returns (uint256) {
        return maximumManagerFeeNumeratorChange;
    }

    function setManagerFeeNumeratorChangeDelay(uint256 delay) public onlyOwner {
        managerFeeNumeratorChangeDelay = delay;
    }

    function getManagerFeeNumeratorChangeDelay() public override view returns (uint256) {
        return managerFeeNumeratorChangeDelay;
    }

    // Exit fees

    function setExitFee(uint256 numerator, uint256 denominator) public onlyOwner {
        _setExitFee(numerator, denominator);
    }

    function _setExitFee(uint256 numerator, uint256 denominator) internal {
        require(numerator <= denominator, "invalid fraction");

        _exitFeeNumerator = numerator;
        _exitFeeDenominator = denominator;

        emit ExitFeeSet(numerator, denominator);
    }

    function getExitFee() external override view returns (uint256, uint256) {
        return (_exitFeeNumerator, _exitFeeDenominator);
    }

    function setExitFeeCooldown(uint256 cooldown)
        external
        onlyOwner
    {
        _setExitFeeCooldown(cooldown);
    }

    function _setExitFeeCooldown(uint256 cooldown) internal {
        _exitFeeCooldown = cooldown;

        emit ExitFeeCooldownSet(cooldown);
    }

    function getExitFeeCooldown() public override view returns (uint256) {
        return _exitFeeCooldown;
    }

    // Asset Info

    function setMaximumSupportedAssetCount(uint256 count) external onlyOwner {
        _setMaximumSupportedAssetCount(count);
    }

    function _setMaximumSupportedAssetCount(uint256 count) internal {
        _maximumSupportedAssetCount = count;

        emit MaximumSupportedAssetCountSet(count);
    }

    function getMaximumSupportedAssetCount() external virtual view override returns (uint256) {
        return _maximumSupportedAssetCount;
    }

    // Synthetix tracking

    function setTrackingCode(bytes32 code) external onlyOwner {
        _setTrackingCode(code);
    }

    function _setTrackingCode(bytes32 code) internal {
        _trackingCode = code;
    }

    function getTrackingCode() public override view returns (bytes32) {
        return _trackingCode;
    }
    
    // DHPT Swap

    function getDhptSwapAddress() public override view returns (address) {
        return _dhptSwapAddress;
    }

    function setDhptSwapAddress(address dhptSwapAddress) public onlyOwner {
        _setDhptSwapAddress(dhptSwapAddress);
    }

    function _setDhptSwapAddress(address dhptSwapAddress) internal {
        _dhptSwapAddress = dhptSwapAddress;

        emit DhptSwapAddressSet(dhptSwapAddress);
    }

    // Upgrade

    function _upgradePool(address pool, uint256 targetVersion) internal {
        IReceivesUpgrade(pool).receiveUpgrade(targetVersion);

        poolVersion[pool] = targetVersion;
    }

    function upgradePoolBatch(uint256 startIndex, uint256 endIndex, uint256 sourceVersion, uint256 targetVersion) external onlyOwner {
        require(startIndex <= endIndex && startIndex < deployedFunds.length && endIndex < deployedFunds.length, "invalid bounds");

        for (uint256 i = startIndex; i <= endIndex; i++) {

            address pool = deployedFunds[i];

            if (poolVersion[pool] != sourceVersion)
                continue;

            _upgradePool(pool, targetVersion);

        }
    } 

    function setPoolStorageVersion(uint256 version) external onlyOwner {
        require(version > poolStorageVersion, "invalid version");

        poolStorageVersion = version;
    }

    uint256[48] private __gap;
}