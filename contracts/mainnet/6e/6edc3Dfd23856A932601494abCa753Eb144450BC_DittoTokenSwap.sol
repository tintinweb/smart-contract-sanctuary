/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

// SPDX-License-Identifier: MIT

/*
MIT License

Copyright (c) 2020 DITTO Money

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

pragma solidity 0.6.12;

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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
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
  constructor() public {
    _owner = msg.sender;
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
}


/**
 * @title Ditto Swap Contract
 */
contract DittoTokenSwap is Ownable {
    using SafeMath for uint256;

    uint256 constant DITTO_DECIMALS = 9;
    uint256 public dittoUSDRate = 1000; // DITTO price in USD (4 decimals, e.g. 981 = $0.981)

    struct InputToken {
      string ticker;
      uint256 decimals;
      uint256 usdRate; // Token price in USD (4 decimals, e.g. 981 = $0.981)
    }

    mapping(address => InputToken) public inputs;
    
    address[] public inputAddresses;

    struct Swap {
      uint256 userCap;
      uint256 totalCap;
      uint256 bonusMultiplier;
      uint256 totalClaimed;
    }

    mapping(uint256 => Swap) swaps;
    
    // Mapping for recording claims for each swap
    
    mapping(uint256 => mapping (address => uint256)) public claims;
    
    uint256 private activeSwapIndex = 0;

    event SwapDeposit(address depositor, address input, uint256 inputAmount, uint256 outputAmount);

    function activeSwapInfo() internal view returns (uint256, uint256, uint256, uint256) {
        return swapInfo(activeSwapIndex);
    }
    
    function isSwapActive() public view returns (bool) {
      Swap storage activeSwap = swaps[activeSwapIndex];

      return activeSwap.totalCap > 0 ? true : false;
    }
    
    modifier hasActiveSwap {
        require(isSwapActive(), "Currently no ongoing swap.");
        _;
    }

    function remainingTokensInActiveSwap() external view hasActiveSwap returns (uint256) {
        Swap storage activeSwap = swaps[activeSwapIndex];
        
        return activeSwap.totalCap.sub(activeSwap.totalClaimed);
    }
    
    function remainingTokensForUser(address _addr) external view hasActiveSwap returns (uint256) {
        Swap storage activeSwap = swaps[activeSwapIndex];
        
        return activeSwap.userCap.sub(claims[activeSwapIndex][msg.sender]);
        
    }

    /**
     * @dev Return information about the swap at swapIndex.
     * @param swapIndex Index of swap to be retrieve info for.
     * @return Total swap cap.
     * @return Per-user cap.
     * @return Bonus multiplier.
     * @return Number of tokens alreaduy claimed.
     */
    function swapInfo(uint256 swapIndex) internal view returns (uint256, uint256, uint256, uint256) {
      Swap storage activeSwap = swaps[swapIndex];

      require(activeSwap.totalCap > 0, "No swap exists at this index.");

      return(
        activeSwap.totalCap,
        activeSwap.userCap,
        activeSwap.bonusMultiplier,
        activeSwap.totalClaimed
      );
    }

    /**
     * @dev Calculate the amount of DITTO to return for *amount* input tokens
     * @param amount Input amount.
     * @param inputAddress Address of the input token.
     * @return DITTO output amount.
     */
    function getDittoOutputAmount(uint256 amount, address inputAddress) public view hasActiveSwap returns (uint256) {
        uint256 usdRate = inputs[inputAddress].usdRate;
        uint256 decimals = inputs[inputAddress].decimals;
        
        uint256 multiplier = swaps[activeSwapIndex].bonusMultiplier;
        
        require(usdRate != 0, "Input token not supported or rate not set");

        uint256 outputAmount = amount.mul(usdRate).mul(10 ** DITTO_DECIMALS).div(dittoUSDRate).div(10 ** decimals);
        
        return outputAmount.mul(multiplier).div(100);

    }

    /**
     * @dev Allows the user to deposit some amount of input tokens. Records user/swap data and emits a SwapDeposit event.
     * @param inputTokenAddress Address of the token to be swapped.
     * @param amount Amount of input tokens to be swapped.
     */
    function swap(address inputTokenAddress, uint256 amount) external hasActiveSwap {
        
        require(amount > 0, "Input amount must be positive.");
        
        Swap storage activeSwap = swaps[activeSwapIndex];

        uint256 outputAmount = getDittoOutputAmount(amount, inputTokenAddress);
        
        require(outputAmount > 0, "Amount too small.");
        
        activeSwap.totalClaimed = activeSwap.totalClaimed.add(outputAmount);
        
        require(activeSwap.totalClaimed <= activeSwap.totalCap, "Swap too large: Total cap exceeded.");
        require(IERC20(inputTokenAddress).transferFrom(msg.sender, address(this), amount), "Transferring input tokens from user failed");

        claims[activeSwapIndex][msg.sender] = claims[activeSwapIndex][msg.sender].add(outputAmount);
        
        require(claims[activeSwapIndex][msg.sender] <= activeSwap.userCap, "Per-address cap exceeded for sender.");
        
        emit SwapDeposit(msg.sender, inputTokenAddress, amount, outputAmount);
        
    }
    
    /**
     * @dev Starts a new token swap.
     * @param _userCap Maximum amount of claimable tokens per address.
     * @param _totalCap Total amount of tokens available for the swap.
     * @param _bonusMultiplier Multiplier percentage, e.g. 110 = 110% = 10% bonus. Set to 100 for no multiplier.
     */
    function startSwap(uint256 _userCap, uint256 _totalCap, uint256 _bonusMultiplier) external onlyOwner {

      require(!isSwapActive(), "Swap is already active.");
      
      require(_userCap > 0, "User cap can't be zero.");
      require(_totalCap > 0, "Swap max cap can't be zero.");
      require(_bonusMultiplier >= 100, "Bonus multiplier must be set to >= 100%.");

      swaps[activeSwapIndex] = Swap(
        {
              userCap: _userCap,
              totalCap: _totalCap,
              bonusMultiplier: _bonusMultiplier,
              totalClaimed: 0
        }
      );
    }

    /**
     * @dev Ends the active swap.
     */
    function endSwap() external onlyOwner {
      activeSwapIndex++;
    }    
    
    /**
     * @dev Add a new input token.
     * @param _addr Address of the token to be added.
     * @param _rate USD price of the token (4 decimals - e.g. $1 = 1000, $0.95 = 950)
     */
    function addInputToken(address _addr, uint256 _rate) external onlyOwner {
        require(inputs[_addr].usdRate == 0, "Input token already set.");
        require(_addr != address(0), "Cannot add input token with zero address.");
        require(_rate > 0, "Cannot add input token with zero rate.");
        
        IERC20 token = IERC20(_addr);
        
        uint8 decimals = token.decimals();
        string memory symbol = token.symbol();

        inputs[_addr] = InputToken(
            {
                ticker: symbol,
                decimals: decimals,
                usdRate: _rate
            }
        );
        inputAddresses.push(_addr);
    }

    /**
     * @dev Lets the owner set the DITTO price in USD.
     * @param _rate Price of 1 DITTO in USD (4 decimals)
     */
    function updateDittoRate(uint256 _rate) external onlyOwner {
        require(_rate > 0, "Can't set zero rate");
        
        dittoUSDRate = _rate;
    }

    /**
     * @dev Lets the owner update the USD price of an input token.
     * @param _addr Address of the input token to be updated.
     * @param _rate Token price in USD (4 decimals)
     */
    function updateRateForInputToken(address _addr, uint256 _rate) external onlyOwner {
        require(inputs[_addr].usdRate > 0, "No input configured at address.");
        
        inputs[_addr].usdRate = _rate;
    }

    function numberOfInputs() external view returns (uint256) {
        return inputAddresses.length;
    }
    
    function removeAddressFromInputsList(address _addr) internal {
        // Each address can exist in the list exactly once.
        
        uint i = 0;
        
        while(inputAddresses[i] != _addr) {
            i++;
        }
        
        while(i < inputAddresses.length - 1) {
            inputAddresses[i] = inputAddresses[i+1];
            i++;
        }
        
        inputAddresses.pop();
    }

    /*
     * @dev Lets the owner remove an input token.
     * @param _addr Address of the token to be removed.
     */
    function removeInputToken(address _addr) external onlyOwner {
        require(inputs[_addr].usdRate > 0, "No input configured at address.");
        
        delete inputs[_addr];
        removeAddressFromInputsList(_addr);
    }

    /**
     * @dev Lets the owner withdraw tokens deposited to the contract account.
     * @param token Address of the token to be withdrawn.
     * @param to Address to which the tokens are to be sent.
     * @param amount Amount of tokens to be withdrawn.
     */
    function withdrawTokens(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

  
}