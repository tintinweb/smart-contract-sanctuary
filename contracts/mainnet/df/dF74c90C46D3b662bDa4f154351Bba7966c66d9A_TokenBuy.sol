pragma solidity 0.4.23;

// File: contracts/ACOTokenCrowdsale.sol

interface ACOTokenCrowdsale {
    function buyTokens(address beneficiary) external payable;
    function hasEnded() external view returns (bool);
}

// File: contracts/lib/DS-Math.sol

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.4.23;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    // function max(uint x, uint y) internal pure returns (uint z) {
    //     return x >= y ? x : y;
    // }
    // function imin(int x, int y) internal pure returns (int z) {
    //     return x <= y ? x : y;
    // }
    // function imax(int x, int y) internal pure returns (int z) {
    //     return x >= y ? x : y;
    // }

    // uint constant WAD = 10 ** 18;
    // uint constant RAY = 10 ** 27;

    // function wmul(uint x, uint y) internal pure returns (uint z) {
    //     z = add(mul(x, y), WAD / 2) / WAD;
    // }
    // function rmul(uint x, uint y) internal pure returns (uint z) {
    //     z = add(mul(x, y), RAY / 2) / RAY;
    // }
    // function wdiv(uint x, uint y) internal pure returns (uint z) {
    //     z = add(mul(x, WAD), y / 2) / y;
    // }
    // function rdiv(uint x, uint y) internal pure returns (uint z) {
    //     z = add(mul(x, RAY), y / 2) / y;
    // }

    // // This famous algorithm is called "exponentiation by squaring"
    // // and calculates x^n with x as fixed-point and n as regular unsigned.
    // //
    // // It&#39;s O(log n), instead of O(n) for naive repeated multiplication.
    // //
    // // These facts are why it works:
    // //
    // //  If n is even, then x^n = (x^2)^(n/2).
    // //  If n is odd,  then x^n = x * x^(n-1),
    // //   and applying the equation for even x gives
    // //    x^n = x * (x^2)^((n-1) / 2).
    // //
    // //  Also, EVM division is flooring and
    // //    floor[(n-1) / 2] = floor[n / 2].
    // //
    // function rpow(uint x, uint n) internal pure returns (uint z) {
    //     z = n % 2 != 0 ? x : RAY;

    //     for (n /= 2; n != 0; n /= 2) {
    //         x = rmul(x, x);

    //         if (n % 2 != 0) {
    //             z = rmul(z, x);
    //         }
    //     }
    // }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/lifecycle/TokenDestructible.sol

/**
 * @title TokenDestructible:
 * @author Remco Bloemen <remco@2π.com>
 * @dev Base contract that can be destroyed by owner. All funds in contract including
 * listed tokens will be sent to the owner.
 */
contract TokenDestructible is Ownable {

  constructor() public payable { }

  /**
   * @notice Terminate contract and refund to owner
   * @param tokens List of addresses of ERC20 or ERC20Basic token contracts to
   refund.
   * @notice The called token contracts could try to re-enter this contract. Only
   supply token contracts you trust.
   */
  function destroy(address[] tokens) onlyOwner public {

    // Transfer tokens to owner
    for (uint256 i = 0; i < tokens.length; i++) {
      ERC20Basic token = ERC20Basic(tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

    // Transfer Eth to owner and terminate contract
    selfdestruct(owner);
  }
}

// File: openzeppelin-solidity/contracts/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

// File: contracts/TokenBuy.sol

/// @title Group-buy contract for Token ICO
/// @author Joe Wasson
/// @notice Allows for group purchase of the Token ICO. This is done
///   in two phases:
///     a) contributions initiate a purchase on demand.
///     b) tokens are collected when they are unfrozen
contract TokenBuy is Pausable, Claimable, TokenDestructible, DSMath {
    using SafeERC20 for ERC20Basic;

    /// @notice Token ICO contract
    ACOTokenCrowdsale public crowdsaleContract;

    /// @notice Token contract
    ERC20Basic public tokenContract;

    /// @notice Map of contributors and their token balances
    mapping(address => uint) public balances;

    /// @notice List of contributors to the sale
    address[] public contributors;

    /// @notice Total amount contributed to the sale
    uint public totalContributions;

    /// @notice Total number of tokens purchased
    uint public totalTokensPurchased;

    /// @notice Emitted whenever a contribution is made
    event Purchase(address indexed sender, uint ethAmount, uint tokensPurchased);

    /// @notice Emitted whenever tokens are collected fromthe contract
    event Collection(address indexed recipient, uint amount);

    /// @notice Time when locked funds in the contract can be retrieved.
    uint constant unlockTime = 1543622400; // 2018-12-01 00:00:00 GMT

    /// @notice Guards against executing the function if the sale
    ///    is not running.
    modifier whenSaleRunning() {
        require(!crowdsaleContract.hasEnded());
        _;
    }

    /// @param crowdsale the Crowdsale contract (or a wrapper around it)
    /// @param token the token contract
    constructor(ACOTokenCrowdsale crowdsale, ERC20Basic token) public {
        require(crowdsale != address(0x0));
        require(token != address(0x0));
        crowdsaleContract = crowdsale;
        tokenContract = token;
    }

    /// @notice returns the number of contributors in the list of contributors
    /// @return count of contributors
    /// @dev As the `collectAll` function is called the contributor array is cleaned up
    ///     consequently this method only returns the remaining contributor count.
    function contributorCount() public view returns (uint) {
        return contributors.length;
    }

    /// @dev Dispatches between buying and collecting
    function() public payable {
        if (msg.value == 0) {
            collectFor(msg.sender);
        } else {
            buy();
        }
    }

    /// @notice Executes a purchase.
    function buy() whenNotPaused whenSaleRunning private {
        address buyer = msg.sender;
        totalContributions += msg.value;
        uint tokensPurchased = purchaseTokens();
        totalTokensPurchased = add(totalTokensPurchased, tokensPurchased);

        uint previousBalance = balances[buyer];
        balances[buyer] = add(previousBalance, tokensPurchased);

        // new contributor
        if (previousBalance == 0) {
            contributors.push(buyer);
        }

        emit Purchase(buyer, msg.value, tokensPurchased);
    }

    function purchaseTokens() private returns (uint tokensPurchased) {
        address me = address(this);
        uint previousBalance = tokenContract.balanceOf(me);
        crowdsaleContract.buyTokens.value(msg.value)(me);
        uint newBalance = tokenContract.balanceOf(me);

        require(newBalance > previousBalance); // Fail on underflow or purchase of 0
        return newBalance - previousBalance;
    }

    /// @notice Allows users to collect purchased tokens after the sale.
    /// @param recipient the address to collect tokens for
    /// @dev Here we don&#39;t transfer zero tokens but this is an arbitrary decision.
    function collectFor(address recipient) private {
        uint tokensOwned = balances[recipient];
        if (tokensOwned == 0) return;

        delete balances[recipient];
        tokenContract.safeTransfer(recipient, tokensOwned);
        emit Collection(recipient, tokensOwned);
    }

    /// @notice Collects the balances for members of the purchase
    /// @param max the maximum number of members to process (for gas purposes)
    function collectAll(uint8 max) public returns (uint8 collected) {
        max = uint8(min(max, contributors.length));
        require(max > 0, "can&#39;t collect for zero users");

        uint index = contributors.length - 1;
        for(uint offset = 0; offset < max; ++offset) {
            address recipient = contributors[index - offset];

            if (balances[recipient] > 0) {
                collected++;
                collectFor(recipient);
            }
        }

        contributors.length -= offset;
    }

    /// @notice Shuts down the contract
    function destroy(address[] tokens) onlyOwner public {
        require(now > unlockTime || (contributorCount() == 0 && paused));

        super.destroy(tokens);
    }
}