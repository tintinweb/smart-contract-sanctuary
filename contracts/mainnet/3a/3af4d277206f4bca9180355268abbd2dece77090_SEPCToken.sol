pragma solidity ^0.4.21;
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract SEPCToken is ERC20Interface, Ownable{
    using SafeMath for uint;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;

    // ERC20 token max reward amount
    uint public angelMaxAmount;
    uint public firstMaxAmount;
    uint public secondMaxAmount;
    uint public thirdMaxAmount;

    // ERC20 token current reward amount
    uint public angelCurrentAmount = 0;
    uint public firstCurrentAmount = 0;
    uint public secondCurrentAmount = 0;
    uint public thirdCurrentAmount = 0;

    // ERC20 token reward rate
    uint public angelRate = 40000;
    uint public firstRate = 13333;
    uint public secondRate = 10000;
    uint public thirdRate = 6153;

    //Team hold amount
    uint public teamHoldAmount = 700000000;

    //every stage start time and end time
    uint public angelStartTime = 1528905600;  // Bei jing time 2018/06/14 00:00:00
    uint public firstStartTime = 1530201600;  // Beijing time 2018/06/29 00:00:00
    uint public secondStartTime = 1531929600; // Beijing time 2018/07/19 00:00:00
    uint public thirdStartTime = 1534521600;  // Beijing time 2018/08/18 00:00:00
    uint public endTime = 1550419200; // Beijing time 2019/02/18 00:00:00

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function SEPCToken() public {
        symbol = "SEPC";
        name = "SEPC";
        decimals = 18;
        angelMaxAmount = 54000000 * 10**uint(decimals);
        firstMaxAmount = 56000000 * 10**uint(decimals);
        secondMaxAmount= 90000000 * 10**uint(decimals);
        thirdMaxAmount = 100000000 * 10**uint(decimals);
        _totalSupply = 1000000000 * 10**uint(decimals);
        balances[msg.sender] = teamHoldAmount * 10**uint(decimals);
        emit Transfer(address(0), msg.sender, teamHoldAmount * 10**uint(decimals));
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // send ERC20 Token to multi address
    // ------------------------------------------------------------------------
    function multiTransfer(address[] _addresses, uint256[] amounts) public returns (bool success){
        for (uint256 i = 0; i < _addresses.length; i++) {
            transfer(_addresses[i], amounts[i]);
        }
        return true;
    }

    // ------------------------------------------------------------------------
    // send ERC20 Token to multi address with decimals
    // ------------------------------------------------------------------------
    function multiTransferDecimals(address[] _addresses, uint256[] amounts) public returns (bool success){
        for (uint256 i = 0; i < _addresses.length; i++) {
            transfer(_addresses[i], amounts[i] * 10**uint(decimals));
        }
        return true;
    }

    // ------------------------------------------------------------------------
    // Crowd-funding
    // ------------------------------------------------------------------------
    function () payable public {
          require(now < endTime && now >= angelStartTime);
          require(angelCurrentAmount <= angelMaxAmount && firstCurrentAmount <= firstMaxAmount && secondCurrentAmount <= secondMaxAmount && thirdCurrentAmount <= thirdMaxAmount);
          uint weiAmount = msg.value;
          uint rewardAmount;
          if(now >= angelStartTime && now < firstStartTime){
            rewardAmount = weiAmount.mul(angelRate);
            balances[msg.sender] = balances[msg.sender].add(rewardAmount);
            angelCurrentAmount = angelCurrentAmount.add(rewardAmount);
            require(angelCurrentAmount <= angelMaxAmount);
          }else if (now >= firstStartTime && now < secondStartTime){
            rewardAmount = weiAmount.mul(firstRate);
            balances[msg.sender] = balances[msg.sender].add(rewardAmount);
            firstCurrentAmount = firstCurrentAmount.add(rewardAmount);
            require(firstCurrentAmount <= firstMaxAmount);
          }else if(now >= secondStartTime && now < thirdStartTime){
            rewardAmount = weiAmount.mul(secondRate);
            balances[msg.sender] = balances[msg.sender].add(rewardAmount);
            secondCurrentAmount = secondCurrentAmount.add(rewardAmount);
            require(secondCurrentAmount <= secondMaxAmount);
          }else if(now >= thirdStartTime && now < endTime){
            rewardAmount = weiAmount.mul(thirdRate);
            balances[msg.sender] = balances[msg.sender].add(rewardAmount);
            thirdCurrentAmount = thirdCurrentAmount.add(rewardAmount);
            require(thirdCurrentAmount <= thirdMaxAmount);
          }
          owner.transfer(msg.value);
    }

    // ------------------------------------------------------------------------
    // After-Crowd-funding
    // ------------------------------------------------------------------------
    function collectToken()  public onlyOwner {
        require( now > endTime);
        balances[owner] = balances[owner].add(angelMaxAmount + firstMaxAmount + secondMaxAmount + thirdMaxAmount -angelCurrentAmount - firstCurrentAmount - secondCurrentAmount - thirdCurrentAmount);
    }
}