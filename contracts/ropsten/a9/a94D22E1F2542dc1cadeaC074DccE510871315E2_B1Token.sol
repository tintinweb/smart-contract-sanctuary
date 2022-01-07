//SPDX-License-Identifier: Unlicense
//https://eips.ethereum.org/EIPS/eip-20

pragma solidity ^0.8.0;

//import "hardhat/console.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IRouter {
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

contract B1Token {
  //uint256 can over/underflow, so SafeMath prevents fuckups
  using SafeMath for uint256;
  uint256 unused = 0;

  //Public can be access from outside the contract
  //View is constant
  //Events can trigger external applications
  string public constant name = "B1 Token";
  string public constant symbol = "B1";
  address payable public deployerAddress;
  address public presaleAddress = address(0);
  address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public WNATIVE = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
  uint8 public constant decimals = 18;
  uint256 public burnPercentage = 5;
  uint256 public taxPercentage = 5;
  uint256 public sellThreshold = 5000 ether;
  uint256 public taxPool = 0;
  uint256 public cumulativeTaxPool = 0;
  uint256 public lastTax = 0;
  uint256 public lastBurn = 0;
  bool public open = false;

  //Define Approval event with owner address, delegate address and amount of tokens the delegate can spend
  event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

  //Define transfer event with from address, to address and amount of tokens
  event Transfer(address indexed from, address indexed to, uint256 tokens);

  //Define balances dict/hashmap/thing with address as the key and uint256 as a value
  mapping(address => uint256) balances;

  //Define allowed dict/hashmap/thing with address as the key and address:uint256 hashmap as a value
  mapping(address => mapping(address => uint256)) allowed;

  //Define array to contain list of addresses with >0 balances
  address[] PositiveBalances;
  mapping(address => uint256) PositiveBalancesHashmap;

  uint256 totalSupply_;

  address private pair;
  bool private inSwap = false;
  modifier lockTheSwap() {
    inSwap = true;
    _;
    inSwap = false;
  }

  constructor(uint256 total) {
    //Total being total number of tokens - is passed as parameter on deployment
    totalSupply_ = total;
    deployerAddress = payable(msg.sender);
    //msg.sender being the address of the wallet interacting with it
    //Gives all tokens to wallet that deploys contract

    // second param is wrapped ether, will need to change on different networks
    pair = pairFor(address(this), WNATIVE);
    balances[deployerAddress] = totalSupply_;
  }

  function setPresaleAddress(address presaleAddress_) public returns (bool) {
    require(msg.sender == deployerAddress, "Bad address");
    presaleAddress = presaleAddress_;
    return true;
  }

  function totalSupply() public view returns (uint256) {
    //Public function to return totalSupply_
    return totalSupply_;
  }

  function balanceOf(address tokenOwner) public view returns (uint256) {
    //Public function to return the amount of tokens a wallet has in balances dict
    return balances[tokenOwner];
  }

  function getOpen() public view returns (bool) {
    return open;
  }

  function setOpen(bool newValue) public returns (bool) {
    require(msg.sender == deployerAddress, "Bad address");
    open = newValue;
    return true;
  }

  function getBurn() public view returns (uint256) {
    return burnPercentage;
  }

  function setBurn(uint256 newValue) public returns (bool) {
    require(msg.sender == deployerAddress, "Bad address");
    burnPercentage = newValue;
    return true;
  }

  function getTax() public view returns (uint256) {
    return taxPercentage;
  }

  function setTax(uint256 newValue) public returns (bool) {
    require(msg.sender == deployerAddress, "Bad address");
    taxPercentage = newValue;
    return true;
  }

  function allowance(address owner, address delegate) public view returns (uint256) {
    //Returns value for how much a delegate can spend on behalf of an address
    return allowed[owner][delegate];
  }

  function approve(address delegate, uint256 numTokens) public returns (bool) {
    require(open == true || deployerAddress == msg.sender);
    //Delegate is a 3rd party allowed to spend tokens for a wallet

    //mapping(address => mapping(address => uint256))
    //[owner[delegate:spendable tokens]]
    allowed[msg.sender][delegate] = numTokens;

    //Emits an event for Approval with three params
    emit Approval(msg.sender, delegate, numTokens);
    return true;
  }

  function doTransaction(
    address sender,
    address receiver,
    uint256 numTokens
  ) private returns (bool) {
    //Acts as a break if wallet balance is less than numTokens - reverts previous logic if fails as well
    require(numTokens <= balances[sender], "Not enough tokens");
    require(open == true || deployerAddress == sender || presaleAddress == sender, "Token has not yet been opened");
    uint256 burned = 0;
    uint256 taxed = 0;

    if(open == true){
      if (burnPercentage > 0 && sender != deployerAddress && sender != address(this)) {
        burned = numTokens / (100 / burnPercentage);
      }
      if (taxPercentage > 0 && sender != deployerAddress && sender != address(this)) {
        taxed = numTokens / (100 / taxPercentage);
      }
    }
    
    //SafeMath uses .sub instead of subtraction operator because safer. Same for add.
    balances[sender] = balances[sender].sub(numTokens);
    numTokens = numTokens.sub(burned.add(taxed));
    balances[receiver] = balances[receiver].add(numTokens);
    emit Transfer(sender, receiver, numTokens);

    lastTax = taxed;
    lastBurn = burned;

    if (burned > 0) {
      balances[address(0)] = balances[address(0)].add(burned);
      emit Transfer(sender, address(0), burned);
    }

    if (taxed > 0) {
      taxPool = taxPool.add(taxed);
      cumulativeTaxPool = cumulativeTaxPool.add(taxed);

      balances[address(this)] = balances[address(this)].add(taxed);
      emit Transfer(sender, address(this), taxed);

      allowed[address(this)][routerAddress] = balanceOf(address(this));
      emit Approval(address(this), routerAddress, balanceOf(address(this)));

      if (taxPool >= sellThreshold && sender != pair && !inSwap) {
        swap(taxed);
      }
    }

    return true;
  }

  function swap(uint256 taxed) internal lockTheSwap {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = WNATIVE;

    balances[deployerAddress] = balances[deployerAddress].add(taxed);
    IRouter(routerAddress).swapExactTokensForETHSupportingFeeOnTransferTokens(
      balanceOf(address(this)),
      0,
      path,
      deployerAddress,
      block.timestamp + (60 * 10)
    );
    taxPool = 0 ether;
  }

  function transfer(address receiver, uint256 numTokens) public returns (bool) {
    doTransaction(msg.sender, receiver, numTokens);
    return true;
  }

  function releaseEther(uint256 amount) public returns (bool) {
    require(msg.sender == deployerAddress, "Address does not match deployer address");
    deployerAddress.transfer(amount);
    return true;
  }

  function transferFrom(
    address owner,
    address buyer,
    uint256 numTokens
  ) public returns (bool) {
    //Require token owner to have the amount of tokens needed
    //Require delegate for owner to be allowed to use the amount of tokens needed
    require(numTokens <= balances[owner], "Owner does not hold enough");
    require(numTokens <= allowed[owner][msg.sender], "Delegate does not have permission to spend more than allowance");

    allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
    doTransaction(owner, buyer, numTokens);
    return true;
  }

  function pairFor(address tokenA, address tokenB) public pure returns (address pair) {
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
              keccak256(abi.encodePacked(token0, token1)),
              hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
            )
          )
        )
      )
    );
  }

  //function rand(uint256 range) public view returns (uint256) {
  //  return uint256 (keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % range;
  //}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}