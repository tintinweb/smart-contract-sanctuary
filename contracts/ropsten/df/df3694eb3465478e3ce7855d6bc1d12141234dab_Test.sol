pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // solidity auto throw when divide by 0
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnerShip(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Test is Ownable {
  using SafeMath for uint256;

  address public wallet;
  Token public token;
  mapping(address=>string) public emails;
  mapping(string=>uint256[]) bundleExpriredTimeOfEmail;

  uint256[] public bundles;
  uint256[] public bundlesExpiredTime;

  constructor(Token _token, address _wallet) public
  {
    wallet = _wallet;
    token = _token;
    // bundles hardcode
    bundles.push(1000000000000000000);
    bundlesExpiredTime.push(10000);
    bundles.push(2000000000000000000);
    bundlesExpiredTime.push(20000);
  }

  function registerEmail(string email) internal
  {
    // must be unregistered
    require(bundleExpriredTimeOfEmail[email].length == 0);
    bundleExpriredTimeOfEmail[email].push(0);
  }

  function purchaseBundle(uint8 bundleNumber, string email) public
  {
    require(bundleNumber < 2);
    if (bundleExpriredTimeOfEmail[email].length == 0) {
      registerEmail(email);
    }
    assert(token.transferFrom(msg.sender, this, bundles[bundleNumber]));
    if (bundleExpriredTimeOfEmail[email][bundleNumber] < now) {
      bundleExpriredTimeOfEmail[email][bundleNumber] =
        now.add(bundlesExpiredTime[bundleNumber]);
    } else {
      bundleExpriredTimeOfEmail[email][bundleNumber] =
        bundleExpriredTimeOfEmail[email][bundleNumber].add(bundlesExpiredTime[bundleNumber]);
    }
  }

  function withdraw() public
  onlyOwner
  {
    token.transfer(wallet, token.balanceOf(this));
  }
}