/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

/* ERC20 Token Interface */
interface Token {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*  ERC20 token Implementation */
abstract contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public override returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success)  {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract LifeCoin2 is StandardToken, SafeMath {

    fallback() external {
      require(false, "Function does not exist");
    }

    // metadata
    string public constant name = "LifeCoin";
    string public constant symbol = "LFE";
    uint256 public constant decimals = 2;
	  uint256 private immutable _totalSupply;
    string public version = "1.0";

    // contracts
    address public ethFundDeposit;        // deposit address for ETH for YawLife Pty. Ltd.
    address public yawLifeFundDeposit;   // deposit address for LifeCoin for YawLife Pty. Ltd.

    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public constant yawLifeFund = 2.2 * (10**9) * 10**decimals;             // 2.2 Billion LifeCoin reserved for YawLife Pty. Ltd. (some to be re-allocated (e.g. to mining) later)
    uint256 public constant totalLifeCoins =  10 * (10**9) * 10**decimals;          // 7.8 Billion LifeCoins will be created.
    uint256 public baseLifeCoinExchangeRate;

    // Bonus parameters.
    // Assuming an average blocktime of 19s. 1 Week is 31831 blocks.
    uint256 public blocksPerWeek;

    mapping (address => uint256[7]) public icoEthBalances;   // Keeps track of amount of eth deposited during each week of the ICO;

    uint256[7] public icoEthPerWeek;  // Keeps track of amount of eth deposited during each week of the ICO;
    // Stores the relative percentages participants gain during the weeks.
    // uint32[7] public bonusesPerWeek;

    // events
    event CreateLifeCoin(address indexed _to, uint256 _value);
    event DepositETH(address indexed _from, uint256 _value, uint256 _bonusPeriod); //The naming is similar to contract function. However it looks nicer in public facing results.

    // constructor
    constructor(
        address _ethFundDeposit,
        address _yawLifeFundDeposit,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock,
        uint256 _blocksPerWeek
      )
    {
      require(_fundingEndBlock > (_fundingStartBlock + _blocksPerWeek), "_fundingEndBlock > _fundingStartBlock");
      isFinalized = false;                   //controls pre through crowdsale state
      ethFundDeposit = _ethFundDeposit;
      yawLifeFundDeposit = _yawLifeFundDeposit;
      blocksPerWeek = _blocksPerWeek;
      fundingStartBlock = _fundingStartBlock;
      fundingEndBlock = _fundingEndBlock;
      _totalSupply = totalLifeCoins;
    }

	function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /// Accepts ether and creates new LifeCoin tokens.
    function depositETH() external payable {
	  require(!isFinalized, "Already finalized");
	  require(block.timestamp >= fundingStartBlock, "Current block-number should not be less than fundingStartBlock");
	  require(block.timestamp <= fundingEndBlock, "Current block-number should not be greater than fundingEndBlock");
	  require(msg.value > 0, "Ether not sent");

      uint256 weekIndex = (block.timestamp - fundingStartBlock) / blocksPerWeek;  // Calculate the array index to credit account
      uint256 currentBalance = icoEthBalances[msg.sender][weekIndex];
      icoEthBalances[msg.sender][weekIndex] = safeAdd(currentBalance, msg.value); //Credit the senders account for the bonus period.

      // Store the totals for each week
      uint256 currentETHWeek = icoEthPerWeek[weekIndex];
      icoEthPerWeek[weekIndex] = safeAdd(currentETHWeek, msg.value); //Credit the senders account for the bonus period.
      emit DepositETH(msg.sender, msg.value, weekIndex);                                          // Log the deposit.
    }

    /// Ends the funding period and sends the ETH to the ethFundDeposit.
    function finalize() external {
      assert(address(this).balance > 0);
	  require(!isFinalized, "Already finalized");
      require(msg.sender == ethFundDeposit, "Sender should be ethFundDeposit"); // locks finalize to the ultimate ETH owner
	  require(block.timestamp > fundingEndBlock, "Current block-number is not greater than fundingEndBlock");
      //Calculate the base exchange rate

      uint256 totalEffectiveWei = 0;
      for(uint32 i =0; i < 7; i++){
        totalEffectiveWei = safeAdd(totalEffectiveWei, icoEthPerWeek[i]);
      }

      //Convert to wei
      baseLifeCoinExchangeRate = ((totalLifeCoins - yawLifeFund)*1e29) / totalEffectiveWei; //((totalLifeCoins - yawLifeFund)*1e29) / totalEffectiveWei
      // switch to operational
      isFinalized = true;
      balances[yawLifeFundDeposit] += yawLifeFund;       // Credit YawLife Pty. Ltd. After the ICO Finishes.
      emit CreateLifeCoin(yawLifeFundDeposit, yawLifeFund);  // Log the creation of the first new LifeCoin Tokens.
	  payable(ethFundDeposit).transfer(address(this).balance);   // send the eth to YawLife Pty. Ltd.
    }

    /// After the ICO - Allow participants to withdraw their tokens at the price dictated by amount of ETH raised.
    function withdraw() external {
      assert(isFinalized == true);            // Wait until YawLife has checked and confirmed the details of the ICO before withdrawing tokens.
      //VERIFY THIS
      // Check balance. Only permit if balance is non Zero
      uint256 balance =0;
      for(uint256 k=0; k < 7; k++){
        balance = safeAdd(balance, icoEthBalances[msg.sender][k]);
      }
      assert(balance > 0);  // TODO: CHECK THIS

      uint256 lifeCoinsOwed=0;
      uint256 effectiveWeiInvestment =0;
      for(uint32 i =0; i < 7; i++ ) {
          effectiveWeiInvestment = icoEthBalances[msg.sender][i];
          // Convert exchange rate to Wei after multiplying.
          lifeCoinsOwed = safeAdd(lifeCoinsOwed, baseLifeCoinExchangeRate*effectiveWeiInvestment/1e29); //baseLifeCoinExchangeRate*effectiveWeiInvestment/1e29
          icoEthBalances[msg.sender][i] = 0;
      }
      balances[msg.sender] = lifeCoinsOwed; // Credit the participants account with LifeCoins.
      emit CreateLifeCoin(msg.sender, lifeCoinsOwed); // Log the creation of new coins.
    }

}