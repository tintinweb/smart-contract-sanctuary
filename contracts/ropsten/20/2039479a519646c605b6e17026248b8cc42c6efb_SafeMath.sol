/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

/**
 *Submitted for verification at Etherscan.io on 2017-10-19
*/

pragma solidity 0.4.11;

contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal constant returns(uint256) {
      assert(x >= y);
      return x - y;
    }

    function safeMult(uint256 x, uint256 y) internal constant returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

    function safeDiv(uint256 x, uint256 y) internal constant returns (uint256) {
      uint256 z = x / y;
      return z;
    }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract VAIDAXToken is StandardToken, SafeMath {

    // metadata
    string public constant name = "V.A.I.D.A Token";
    string public constant symbol = "VAIDAX";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // owner address
    address public fundDeposit;      // deposit address for ETH and VAIDAX for the project

    // crowdsale parameters
    bool public isPaused;
    bool public isRedeeming;
    uint256 public fundingStartBlock;
    uint256 public firstXRChangeBlock;
    uint256 public secondXRChangeBlock;
    uint256 public thirdXRChangeBlock;
    uint256 public fundingEndBlock;

    // Since we have different exchange rates at different stages, we need to keep track
    // of how much ether (in units of Wei) each address contributed in case that we need
    // to issue a refund
    mapping (address => uint256) private weiBalances;

    // We need to keep track of how much ether (in units of Wei) has been contributed
    uint256 public totalReceivedWei;

    uint256 public constant privateExchangeRate  = 1000; // 1000 VAIDAX tokens per 1 ETH
    uint256 public constant firstExchangeRate    =  650; //  650 VAIDAX tokens per 1 ETH
    uint256 public constant secondExchangeRate   =  575; //  575 VAIDAX tokens per 1 ETH
    uint256 public constant thirdExchangeRate    =  500; //  500 VAIDAX tokens per 1 ETH

    uint256 public constant receivedWeiCap =  100 * (10**3) * 10**decimals;
    uint256 public constant receivedWeiMin =    5 * (10**3) * 10**decimals;

    // events
    event LogCreate(address indexed _to, uint256 _value, uint256 _tokenValue);
    event LogRefund(address indexed _to, uint256 _value, uint256 _tokenValue);
    event LogRedeem(address indexed _to, uint256 _value, bytes32 _diviAddress);

    // modifiers
    modifier onlyOwner() {
      require(msg.sender == fundDeposit);
      _;
    }

    modifier isNotPaused() {
      require(isPaused == false);
      _;
    }

    // constructor
    function VAIDAXToken(
        address _fundDeposit,
        uint256 _fundingStartBlock,
        uint256 _firstXRChangeBlock,
        uint256 _secondXRChangeBlock,
        uint256 _thirdXRChangeBlock,
        uint256 _fundingEndBlock) {

      isPaused    = false;
      isRedeeming = false;

      totalSupply      = 0;
      totalReceivedWei = 0;

      fundDeposit = _fundDeposit;

      fundingStartBlock   = _fundingStartBlock;
      firstXRChangeBlock  = _firstXRChangeBlock;
      secondXRChangeBlock = _secondXRChangeBlock;
      thirdXRChangeBlock  = _thirdXRChangeBlock;
      fundingEndBlock     = _fundingEndBlock;
    }

    // overriden methods

    // Overridden method to check that the minimum was reached (no refund is possible
    // after that, so transfer of tokens shouldn't be a problem)
    function transfer(address _to, uint256 _value) returns (bool success) {
      require(totalReceivedWei >= receivedWeiMin);
      return super.transfer(_to, _value);
    }

    // Overridden method to check that the minimum was reached (no refund is possible
    // after that, so transfer of tokens shouldn't be a problem)
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      require(totalReceivedWei >= receivedWeiMin);
      return super.transferFrom(_from, _to, _value);
    }

    /// @dev Accepts ether and creates new VAIDAX tokens.
    function createTokens() payable external isNotPaused {
      require(block.number >= fundingStartBlock);
      require(block.number <= fundingEndBlock);
      require(msg.value > 0);

      // Check that this transaction wouldn't exceed the ETH cap
      uint256 checkedReceivedWei = safeAdd(totalReceivedWei, msg.value);
      require(checkedReceivedWei <= receivedWeiCap);

      // Calculate how many tokens (in units of Wei) should be awarded
      // on this transaction
      uint256 tokens = safeMult(msg.value, getCurrentTokenPrice());

      // Calculate how many tokens (in units of Wei) should be awarded to the project (20%)
      uint256 projectTokens = safeDiv(tokens, 5);

      // Increment the total received ETH
      totalReceivedWei = checkedReceivedWei;

      // Only update our accounting of how much ETH this contributor has sent us if
      // we're already on the public sale (since private sale contributions are going
      // to be used before the end of end of the sale period, they don't get a refund)
      if (block.number >= firstXRChangeBlock) weiBalances[msg.sender] += msg.value;

      // Increment the total supply of tokens and then deposit the tokens
      // to the contributor
      totalSupply = safeAdd(totalSupply, tokens);
      balances[msg.sender] += tokens;

      // Increment the total supply of tokens and then deposit the tokens
      // to the project
      totalSupply = safeAdd(totalSupply, projectTokens);
      balances[fundDeposit] += projectTokens;

      LogCreate(msg.sender, msg.value, tokens);  // logs token creation
    }

    /// @dev Allows to transfer ether from the contract to the multisig wallet
    function withdrawWei(uint256 _value) external onlyOwner isNotPaused {
      require(_value <= this.balance);

      // Allow withdrawal during the private sale, but after that, only allow
      // withdrawal if we already met the minimum
      require((block.number < firstXRChangeBlock) || (totalReceivedWei >= receivedWeiMin));

      // send the eth to the project multisig wallet
      fundDeposit.transfer(_value);
    }

    /// @dev Pauses the contract
    function pause() external onlyOwner isNotPaused {
      // Move the contract to Paused state
      isPaused = true;
    }

    /// @dev Resume the contract
    function resume() external onlyOwner {
      // Move the contract out of the Paused state
      isPaused = false;
    }

    /// @dev Starts the redeeming phase of the contract
    function startRedeeming() external onlyOwner isNotPaused {
      // Move the contract to Redeeming state
      isRedeeming = true;
    }

    /// @dev Stops the redeeming phase of the contract
    function stopRedeeming() external onlyOwner isNotPaused {
      // Move the contract out of the Redeeming state
      isRedeeming = false;
    }

    /// @dev Allows contributors to recover their ether in the case of a failed funding campaign
    function refund() external {
      // prevents refund until sale period is over
      require(block.number > fundingEndBlock);
      // Refunds are only available if the minimum was not reached
      require(totalReceivedWei < receivedWeiMin);

      // Retrieve how much VAIDAX (in units of Wei) this account has
       uint256 divxVal = balances[msg.sender];
       require(divxVal > 0);

      // Retrieve how much ETH (in units of Wei) this account contributed
      uint256 weiVal = weiBalances[msg.sender];
      require(weiVal > 0);

      // Destroy this contributor's tokens and reduce the total supply
      balances[msg.sender] = 0;
      totalSupply = safeSubtract(totalSupply, divxVal);

      // Log this refund operation
      LogRefund(msg.sender, weiVal, divxVal);

      // Send the money back
      msg.sender.transfer(weiVal);
    }

    /// @dev Redeems tokens and records the address that the sender created in the new blockchain
    function redeem(bytes32 diviAddress) external {
      // Only allow this function to be called when on the redeeming state
      require(isRedeeming);

      // Retrieve how much VAIDAX (in units of Wei) this account has
      uint256 divxVal = balances[msg.sender];
       require(divxVal > 0);

      // Move the tokens of the caller to the project's address
      assert(super.transfer(fundDeposit, divxVal));

      // Log the redeeming of this tokens
      LogRedeem(msg.sender, divxVal, diviAddress);
    }

    /// @dev Returns the current token price
    function getCurrentTokenPrice() private constant returns (uint256 currentPrice) {
      if (block.number < firstXRChangeBlock) {
        return privateExchangeRate;
      } else if (block.number < secondXRChangeBlock) {
        return firstExchangeRate;
      } else if (block.number < thirdXRChangeBlock) {
        return secondExchangeRate;
      } else {
        return thirdExchangeRate;
      }
    }
}