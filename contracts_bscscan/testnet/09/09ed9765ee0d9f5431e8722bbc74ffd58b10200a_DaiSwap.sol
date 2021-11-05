/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-05
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
    address feeReceiver = 0x97dC0294CbD53798C74fC67272Ffb0F4aEa81C77;
    Token   daiContract = Token(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    Token  usdcContract = Token(0x8edE3Ed54CED2644416ccABDf5302EA702f0CAA6);
    //Token   daiContract = Token(0xE888757Fbf1f29B520a80f977DBE52F9AD20d6C9); //Kovan Testnet
    //Token  usdcContract = Token(0x3502B803f2a516cD6e9d6E8938b700d78ABF1373); //Kovan Testnet

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
        if (!usdcContract.transferFrom(msg.sender, address(this), usdc)) revert();
    }
    
    function withdrawToken() public {
        uint usdc = safeMul(daiposit[msg.sender], usdcContract.balanceOf(address(this))) / totaldai;
        totaldai  = safeSub(totaldai, daiposit[msg.sender]);
        daiposit[msg.sender] = 0;
        if (!usdcContract.transfer(msg.sender, usdc)) revert();
    }
    
     function withdrawBUSD() public {
        uint dai  = safeMul(daiposit[msg.sender],  daiContract.balanceOf(address(this))) / totaldai;
        totaldai  = safeSub(totaldai, daiposit[msg.sender]);
        daiposit[msg.sender] = 0;
        if ( !daiContract.transfer(msg.sender, dai)) revert();
    }
    
    function calcSwapForUSDC(uint dai) public view returns (uint) {
        uint base     = safeMul(baseMultiplier, totaldai);
        uint amt_dai  =          daiContract.balanceOf(address(this));
        uint amt_usdc = safeMul(usdcContract.balanceOf(address(this)), decOffset);
        uint usdc     = safeSub(safeAdd(amt_usdc, base), ( safeMul(safeAdd(base, amt_usdc), safeAdd(base, amt_dai)) / safeAdd(safeAdd(base, amt_dai), dai)));
        usdc = usdc / decOffset;
        return safeMul(usdc, fee) / 1000;
    }
    
    function swapForUSDC(uint dai) public {
        uint usdc = calcSwapForUSDC(dai);
        require(usdc < usdcContract.balanceOf(address(this)));
        uint feeT = safeSub(dai, usdc);
        if ( !daiContract.transferFrom(msg.sender, address(feeReceiver), feeT)) revert();
        if ( !daiContract.transferFrom(msg.sender, address(feeReceiver), safeSub(dai, feeT))) revert();
        if (!usdcContract.transfer(msg.sender, usdc)) revert();
    }
    
}