// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract TriangleCoin {
    //                          PYRAMID.
    //                    The Pyramid Network
    //                Welcome to the pyramid network!
    //          This network rewards you for inviting others.
    //    Help grow the network, and build your triangle collection!
    
    string public constant name = "Triangle Coin";
    string public constant symbol = "TRI";
    uint8 public constant decimals = 18;

    address public _owner;
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    event walletRefered(address _referer, address _referee);
    event walletAccepted(address _referee, address _referer, bool _accepted);

    mapping(address => address) private __referredBy;
    mapping(address => uint) private __level;
    mapping(address => bool) private __acceptedReferral;
    
    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;

    using SafeMath for uint256;
    
    constructor() public {
      _owner = msg.sender;
      __level[_owner] = 0;
      __acceptedReferral[_owner] = true;
      totalSupply_ = 100000000000000000000;
      emit Transfer(0x0000000000000000000000000000000000000000, _owner, 100000000000000000000);
	    balances[msg.sender] = totalSupply_;
    }
    
    function totalSupply() public view returns (uint256) {
	    return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
      return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint numTokens) public returns (bool) {
      require(numTokens <= balances[msg.sender], "Not enough coins on behalf of the sender");
      balances[msg.sender] = balances[msg.sender].sub(numTokens);
      balances[receiver] = balances[receiver].add(numTokens);
      emit Transfer(msg.sender, receiver, numTokens);
      return true;
    }
    
    function approve(address delegate, uint numTokens) public returns (bool) {
      allowed[msg.sender][delegate] = numTokens;
      emit Approval(msg.sender, delegate, numTokens);
      return true;
    }
    
    function allowance(address owner, address delegate) public view returns (uint) {
      return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
      require(numTokens <= balances[owner], "Not enough coins on behalf of the sender");    
      require(numTokens <= allowed[owner][msg.sender], "Not enough coins on behalf of the delegate");
  
      balances[owner] = balances[owner].sub(numTokens);
      allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
      balances[buyer] = balances[buyer].add(numTokens);
      emit Transfer(owner, buyer, numTokens);
      return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        require(account == _owner, "Account not the owner");

        totalSupply_ += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function acceptReferral(address referer) public returns (bool success) {
        // Require that the person was refered and that the value is not the default value, address(0)
        require(__referredBy[msg.sender] == referer);
        require(__acceptedReferral[msg.sender] != true);

        __acceptedReferral[msg.sender] = true;

        emit walletAccepted(msg.sender, referer, __acceptedReferral[msg.sender]);

        // Set level of referee to 1 further down than the referer
        __level[msg.sender] = __level[__referredBy[msg.sender]] + 1;

        // Give joiner some triangles
        balances[msg.sender] += 5000000000000000000;
        totalSupply_ += 5000000000000000000;

        emit Transfer(0x0000000000000000000000000000000000000000, msg.sender, 5000000000000000000);

        address wallet = msg.sender;
        
        // Payout levels starting from bottom up to top working through who refered who
        for (uint i = 0; i < 17; i++) {
            if (__level[wallet] == 0 || i == 16) {
                return true;
            }
            else {
                balances[__referredBy[wallet]] += 5000000000000000000;
                totalSupply_ += 5000000000000000000;
                emit Transfer(0x0000000000000000000000000000000000000000, __referredBy[wallet], 5000000000000000000);
                wallet = __referredBy[wallet];
            }
        }
    }

    function extendReferral(address _to) public returns (bool success) {
        // Require that the sender cannot refer themselves
        require(_to != msg.sender);

        emit walletRefered(msg.sender, _to);

        // Extend referral
        __referredBy[_to] = msg.sender;
        return true;
    }

    function referedBy(address addr) public view returns (address referer) {
        return __referredBy[addr];
    }

    function isUser(address addr) public view returns (bool success) {
        return __acceptedReferral[addr];
    }

    function levelOf(address addr) public view returns (uint256 level) {
        return __level[addr];
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(account == msg.sender);

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balances[account] = accountBalance - amount;
        totalSupply_ -= amount;

        emit Transfer(account, address(0), amount);
    }
}

library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}