/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// File: contracts/v4/library/SafeMath.sol

pragma solidity 0.4.24;
    
    
    /**
     * @title SafeMath
     * @dev Math operations with safety checks that revert on error
     */
    library SafeMath {
    
      /**
      * @dev Multiplies two numbers, reverts on overflow.
      */
      function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
          return 0;
        }
    
        uint256 c = a * b;
        require(c / a == b);
    
        return c;
      }
    
      /**
      * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
      */
      function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    
        return c;
      }
    
      /**
      * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
      */
      function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
    
        return c;
      }
    
      /**
      * @dev Adds two numbers, reverts on overflow.
      */
      function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
    
        return c;
      }
    
      /**
      * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
      * reverts when dividing by zero.
      */
      function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
      }
    }

// File: contracts/v4/library/SafeMathInt.sol

pragma solidity 0.4.24;
    
    /*
    MIT License
    
    Copyright (c) 2018 requestnetwork
    Copyright (c) 2018 Omss, Inc.
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
    */
    /**
     * @title SafeMathInt
     * @dev Math operations for int256 with overflow safety checks.
     */
    library SafeMathInt {
        int256 private constant MIN_INT256 = int256(1) << 255;
        int256 private constant MAX_INT256 = ~(int256(1) << 255);
    
        /**
         * @dev Multiplies two int256 variables and fails on overflow.
         */
        function mul(int256 a, int256 b)
            internal
            pure
            returns (int256)
        {
            int256 c = a * b;
    
            // Detect overflow when multiplying MIN_INT256 with -1
            require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
            require((b == 0) || (c / b == a));
            return c;
        }
    
        /**
         * @dev Division of two int256 variables and fails on overflow.
         */
        function div(int256 a, int256 b)
            internal
            pure
            returns (int256)
        {
            // Prevent overflow when dividing MIN_INT256 by -1
            require(b != -1 || a != MIN_INT256);
    
            // Solidity already throws when dividing by 0.
            return a / b;
        }
    
        /**
         * @dev Subtracts two int256 variables and fails on overflow.
         */
        function sub(int256 a, int256 b)
            internal
            pure
            returns (int256)
        {
            int256 c = a - b;
            require((b >= 0 && c <= a) || (b < 0 && c > a));
            return c;
        }
    
        /**
         * @dev Adds two int256 variables and fails on overflow.
         */
        function add(int256 a, int256 b)
            internal
            pure
            returns (int256)
        {
            int256 c = a + b;
            require((b >= 0 && c >= a) || (b < 0 && c < a));
            return c;
        }
    
        /**
         * @dev Converts to absolute value, and fails on overflow.
         */
        function abs(int256 a)
            internal
            pure
            returns (int256)
        {
            require(a != MIN_INT256);
            return a < 0 ? -a : a;
        }
    }

// File: contracts/v4/interface/IERC20.sol

pragma solidity 0.4.24;
    
    /**
     * @title ERC20 interface
     * @dev see https://github.com/ethereum/EIPs/issues/20
     */
    interface IERC20 {
      function totalSupply() external view returns (uint256);
    
      function balanceOf(address who) external view returns (uint256);
    
      function allowance(address owner, address spender)
        external view returns (uint256);
    
      function transfer(address to, uint256 value) external returns (bool);
    
      function approve(address spender, uint256 value)
        external returns (bool);
    
      function transferFrom(address from, address to, uint256 value)
        external returns (bool);
    
      event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
      );
    
      event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
      );
    }

// File: contracts/v4/interface/UInt256Lib.sol

pragma solidity 0.4.24;


/**
 * @title Various utilities useful for uint256.
 */
library UInt256Lib {

    uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a)
        internal
        pure
        returns (int256)
    {
        require(a <= MAX_INT256);
        return int256(a);
    }
}

// File: contracts/v4/common/Initializable.sol

pragma solidity 0.4.24;
    
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
    
        bool wasInitializing = initializing;
        initializing = true;
        initialized = true;
    
        _;
    
        initializing = wasInitializing;
      }
    
      /// @dev Returns true if and only if the function is running in the constructor
      function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        assembly { cs := extcodesize(address) }
        return cs == 0;
      }
    
      // Reserved storage space to allow for layout changes in the future.
      uint256[50] private ______gap;
    }

// File: contracts/v4/common/Ownable.sol

pragma solidity 0.4.24;

    
    /**
     * @title Ownable
     * @dev The Ownable contract has an owner address, and provides basic authorization control
     * functions, this simplifies the implementation of "user permissions".
     */
    contract Ownable is Initializable {
      address private _owner;
    
    
      event OwnershipRenounced(address indexed previousOwner);
      event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
      );
    
    
      /**
       * @dev The Ownable constructor sets the original `owner` of the contract to the sender
       * account.
       */
      function initialize(address sender) public initializer {
        _owner = sender;
      }
    
      /**
       * @return the address of the owner.
       */
      function owner() public view returns(address) {
        return _owner;
      }
    
      /**
       * @dev Throws if called by any account other than the owner.
       */
      modifier onlyOwner() {
        require(isOwner());
        _;
      }
    
      /**
       * @return true if `msg.sender` is the owner of the contract.
       */
      function isOwner() public view returns(bool) {
        return msg.sender == _owner;
      }
    
      /**
       * @dev Allows the current owner to relinquish control of the contract.
       * @notice Renouncing to ownership will leave the contract without an owner.
       * It will not be possible to call the functions with the `onlyOwner`
       * modifier anymore.
       */
      function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
      }
    
      /**
       * @dev Allows the current owner to transfer control of the contract to a newOwner.
       * @param newOwner The address to transfer ownership to.
       */
      function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
      }
    
      /**
       * @dev Transfers control of the contract to a newOwner.
       * @param newOwner The address to transfer ownership to.
       */
      function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
      }
    
      uint256[50] private ______gap;
    }

// File: contracts/v4/Console.sol

pragma solidity 0.4.24;







contract Console is Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;

    event LogRebase(string message, uint256 epoch, uint256 timestampSec);

    // uint256 public rebaseLag;
    // uint256 public minRebaseTimeIntervalSec;
    // uint256 public lastRebaseTimestampSec;
    // uint256 public rebaseWindowOffsetSec;
    // uint256 public rebaseWindowLengthSec;
    uint256 public epoch;

    function rebase() external {
        // require(inRebaseWindow(), 'Must be in the rebase window');

        // // This comparison also ensures there is no reentrancy.
        // require(lastRebaseTimestampSec.add(minRebaseTimeIntervalSec) < now, 'Not allowed to rebase so soon since the last rebase');

        // // Snap the rebase time to the start of this window.
        // lastRebaseTimestampSec = now.sub(
        //     now.mod(minRebaseTimeIntervalSec)).add(rebaseWindowOffsetSec);

        epoch = epoch.add(1);

        emit LogRebase("Rebasing", epoch, now);
    }

    // function setRebaseLag(uint256 rebaseLag_)
    //     external
    //     onlyOwner
    // {
    //     require(rebaseLag_ > 0, 'Rebase lag must be greater than 0');
    //     rebaseLag = rebaseLag_;
    // }

    // function setRebaseTimingParameters(
    //     uint256 minRebaseTimeIntervalSec_,
    //     uint256 rebaseWindowOffsetSec_,
    //     uint256 rebaseWindowLengthSec_)
    //     external
    //     onlyOwner
    // {
    //     require(minRebaseTimeIntervalSec_ > 0, 'Min rebase time interval must be greater than 0');
    //     require(rebaseWindowOffsetSec_ < minRebaseTimeIntervalSec_, 'Rebase window offset must be less than min rebase time interval');

    //     minRebaseTimeIntervalSec = minRebaseTimeIntervalSec_;
    //     rebaseWindowOffsetSec = rebaseWindowOffsetSec_;
    //     rebaseWindowLengthSec = rebaseWindowLengthSec_;
    // }

    // function initialize(address owner_)
    //     public
    //     initializer
    // {
    //     require(owner_ != address(0), 'The address can not be a zero-address');
    //     Ownable.initialize(owner_);

    //     // rebaseLag = 30;
    //     rebaseLag = 10;
    //     minRebaseTimeIntervalSec = 1 days;
    //     rebaseWindowOffsetSec = 46800;  // 3PM UTC
    //     rebaseWindowLengthSec = 30 minutes;
    // }

    // function inRebaseWindow() public view returns (bool) {
    //     return (
    //         now.mod(minRebaseTimeIntervalSec) >= rebaseWindowOffsetSec &&
    //         now.mod(minRebaseTimeIntervalSec) < (rebaseWindowOffsetSec.add(rebaseWindowLengthSec))
    //     );
    // }
}