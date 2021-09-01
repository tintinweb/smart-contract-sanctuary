/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-08-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.8.0;

contract Context {
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor ()  {
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
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    function burn(uint256 _value) external returns (bool success);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    bool private _notEntered;

    constructor ()  {
        
        _notEntered = true;
    }

    
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        
        _notEntered = true;
    }
}

contract crowdsale is Context, Ownable, ReentrancyGuard{
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    uint256 public rate;
    uint256 private _weiRaised;
    uint256 public bnbRaised;
    uint256 public totalSold;
    IERC20 public tokenAddress;
    uint256 private cap = 875000 *10**18;
    
    
    uint256 public minimumBuyAmount = 5 * 10 ** 16;
    uint256 public maximumBuyAmount = 4*10**18;
    address payable public walletAddress;
    event TokensPurchased(address indexed to, uint256 amount);
    
    constructor () {
        
        rate = uint256(1000);
        walletAddress = 0xEB0e7f3d7b8c50623a595CE962f1aB451eB177b6; // TEAM
        tokenAddress = IERC20(0x6C64CD343262929a16A218A4BE657D092c0C899b); // RFX //0x6C64CD343262929a16A218A4BE657D092c0C899b
    }
    
    receive () external payable {
        buy();
    }
    
    function changeWallet (address payable _walletAddress) public {
        require(msg.sender == owner(), "!governance");
        walletAddress = _walletAddress;
    }
    
    /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address) {
    return owner();
  }
  
  function changeRate (uint256 _rate) public {
        require(msg.sender == owner(), "!governance");
        rate = _rate;
    }
    
    function setToken(IERC20 _tokenAddress) public {
        require(msg.sender == owner(), "!governance");
        tokenAddress = _tokenAddress;
    }
    
    function buy() public payable nonReentrant {
        uint256 weiValue = msg.value;
        IERC20 token = IERC20(tokenAddress);
        uint256 senderBal = token.balanceOf(msg.sender);
        uint256 amount = weiValue.mul(rate);
        uint256 sb = senderBal.add(amount);
        require((sb < maximumBuyAmount.mul(rate)), "You can only buy maximum of 4 BNB worth of tokens");
        require((weiValue >= minimumBuyAmount) &&(weiValue<= maximumBuyAmount), "Minimum amount is 0.05 BNB and Maximum amount is 4 BNB");
        require(totalSold <= cap);                
        //uint256 amount = weiValue.mul(rate);
        _weiRaised = _weiRaised.add(weiValue);
        bnbRaised = bnbRaised.add(_weiRaised.div(10**18));   
        token.safeTransfer(msg.sender, amount);
        walletAddress.transfer(weiValue);
        totalSold += amount;
        emit TokensPurchased(msg.sender, amount);
    }
    
    function burnUnsold() public {
        require(msg.sender == owner(), "!governance");
        IERC20 token = IERC20(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        token.burn(amount);
    }
    
}