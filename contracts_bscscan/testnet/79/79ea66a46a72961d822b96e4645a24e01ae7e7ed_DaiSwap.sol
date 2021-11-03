/**
 *Submitted for verification at BscScan.com on 2021-11-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

pragma solidity ^0.5.10;

contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Token {
  /// @return total amount of tokens
  function totalSupply() public view returns (uint256 supply) {}

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) public view returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) public returns (bool success) {}

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}


contract DaiSwap is SafeMath {
    mapping (address => uint) public daiposit;
    uint public totaldai = 0;
    uint public baseMultiplier = 40;
    uint fee = 970; // 3.0%
    uint constant decOffset = 1e12;
    address busdReceiver = 0x97dC0294CbD53798C74fC67272Ffb0F4aEa81C77;
    Token   daiContract = Token(0x04B9c7Ad928f6868E3dd5D78703B4704ae364442);
    Token  usdcContract = Token(0xb05B1C0A69910113B19C97376b489811C73914f1);

    function sharesFromDai(uint dai) public view returns (uint) {
        if (totaldai == 0) return dai; // Initialisation 
        uint amt_dai  =  daiContract.balanceOf(address(this));
        return safeMul(dai, totaldai) / amt_dai;
    }

    function usdcAmountFromShares(uint shares) public view returns (uint) {
        if (totaldai == 0) return shares / decOffset; // Initialisation - 1 Dai = 1 Shares
        uint amt_usdc = safeMul(usdcContract.balanceOf(address(this)), decOffset);
        return (safeMul(shares, amt_usdc) / totaldai) / decOffset;
    }
    
    function usdcAmountFromDai(uint dai) public view returns (uint) {
        return usdcAmountFromShares(sharesFromDai(dai));
    }
    
    function deposit(uint dai) public {
        uint shares = sharesFromDai(dai);
        uint usdc = usdcAmountFromShares(shares);
        daiposit[msg.sender] = safeAdd(daiposit[msg.sender], shares);
        totaldai             = safeAdd(totaldai, shares);
        if ( !daiContract.transferFrom(msg.sender, address(this), dai)) revert();
        if (!usdcContract.transferFrom(msg.sender, address(this), usdc)) revert();
    }
    
    function withdraw() public {
        uint dai  = safeMul(daiposit[msg.sender],  daiContract.balanceOf(address(this))) / totaldai;
        uint usdc = safeMul(daiposit[msg.sender], usdcContract.balanceOf(address(this))) / totaldai;
        totaldai  = safeSub(totaldai, daiposit[msg.sender]);
        daiposit[msg.sender] = 0;
        if ( !daiContract.transfer(msg.sender, dai)) revert();
        if (!usdcContract.transfer(msg.sender, usdc)) revert();
    }
    
    
    function calcSwapForDai(uint usdc) public view returns (uint) {
        uint base     = safeMul(baseMultiplier, totaldai);
        uint amt_dai  =          daiContract.balanceOf(address(this));
        uint amt_usdc = safeMul(usdcContract.balanceOf(address(this)), decOffset);
        uint dai      = safeSub(safeAdd(amt_dai, base), ( safeMul(safeAdd(base, amt_usdc), safeAdd(base, amt_dai)) / safeAdd(safeAdd(base, amt_usdc), usdc)));
        dai = dai / decOffset;
        return safeMul(dai, fee) / 1000;
    }
    
    function swapForDai(uint usdc) public {
        uint dai = calcSwapForDai(usdc);
        require(dai < daiContract.balanceOf(address(this)));
        if (!usdcContract.transferFrom(msg.sender, address(busdReceiver), usdc)) revert();
        if ( !daiContract.transfer(msg.sender, dai)) revert();
    }
}