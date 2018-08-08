pragma solidity 0.4.18;

/**
 * @title Math
 * @dev Assorted math operations
 */

library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}




/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}


/**
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="eb998e868884abd9">[email&#160;protected]</span>π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}


/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="74061119171b3446">[email&#160;protected]</span>π.com>
 * @dev This blocks incoming ERC23 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is CanReclaimToken {

 /**
  * @dev Reject all ERC23 compatible tokens
  * @param from_ address The address that is transferring the tokens
  * @param value_ uint256 the amount of the specified token
  * @param data_ Bytes The data passed from the caller.
  */
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}





/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}



contract VITToken is Claimable, HasNoTokens, MintableToken {
    // solhint-disable const-name-snakecase
    string public constant name = "Vice";
    string public constant symbol = "VIT";
    uint8 public constant decimals = 18;
    // solhint-enable const-name-snakecase

    modifier cannotMint() {
        require(mintingFinished);
        _;
    }

    function VITToken() public {

    }

    /// @dev Same ERC20 behavior, but reverts if still minting.
    /// @param _to address The address to transfer to.
    /// @param _value uint256 The amount to be transferred.
    function transfer(address _to, uint256 _value) public cannotMint returns (bool) {
        return super.transfer(_to, _value);
    }

    /// @dev Same ERC20 behavior, but reverts if still minting.
    /// @param _from address The address which you want to send tokens from.
    /// @param _to address The address which you want to transfer to.
    /// @param _value uint256 the amount of tokens to be transferred.
    function transferFrom(address _from, address _to, uint256 _value) public cannotMint returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}




/// @title VITToken sale contract.
contract VITTokenSale is Claimable {
    using Math for uint256;
    using SafeMath for uint256;

    // VIT token contract.
    VITToken public vitToken;

    // Received funds are forwarded to this address.
    address public fundingRecipient;

    // VIT token unit.
    uint256 public constant TOKEN_UNIT = 10 ** 18;

    // Maximum tokens offered in the sale: 2B.
    uint256 public constant MAX_TOKENS_SOLD = 2 * 10 ** 9 * TOKEN_UNIT;

    // VIT to 1 wei ratio.
    uint256 public vitPerWei;

    // Sale start and end timestamps.
    uint256 public constant RESTRICTED_PERIOD_DURATION = 1 days;
    uint256 public startTime;
    uint256 public endTime;

    // Refund data and state.
    uint256 public refundEndTime;
    mapping (address => uint256) public refundableEther;
    mapping (address => uint256) public claimableTokens;
    uint256 public totalClaimableTokens = 0;
    bool public finalizedRefund = false;

    // Amount of tokens sold until now in the sale.
    uint256 public tokensSold = 0;

    // Accumulated amount each participant has contributed so far.
    mapping (address => uint256) public participationHistory;

    // Maximum amount that each participant is allowed to contribute (in WEI), during the restricted period.
    mapping (address => uint256) public participationCaps;

    // Initial allocations.
    address[20] public strategicPartnersPools;
    uint256 public constant STRATEGIC_PARTNERS_POOL_ALLOCATION = 100 * 10 ** 6 * TOKEN_UNIT; // 100M

    event TokensIssued(address indexed to, uint256 tokens);
    event EtherRefunded(address indexed from, uint256 weiAmount);
    event TokensClaimed(address indexed from, uint256 tokens);
    event Finalized();
    event FinalizedRefunds();

    /// @dev Reverts if called when not during sale.
    modifier onlyDuringSale() {
        require(!saleEnded() && now >= startTime);

        _;
    }

    /// @dev Reverts if called before the sale ends.
    modifier onlyAfterSale() {
        require(saleEnded());

        _;
    }

    /// @dev Reverts if called not doing the refund period.
    modifier onlyDuringRefund() {
        require(saleDuringRefundPeriod());

        _;
    }

    modifier onlyAfterRefund() {
        require(saleAfterRefundPeriod());

        _;
    }

    /// @dev Constructor that initializes the sale conditions.
    /// @param _fundingRecipient address The address of the funding recipient.
    /// @param _startTime uint256 The start time of the token sale.
    /// @param _endTime uint256 The end time of the token sale.
    /// @param _refundEndTime uint256 The end time of the refunding period.
    /// @param _vitPerWei uint256 The exchange rate of VIT for one ETH.
    /// @param _strategicPartnersPools address[20] The addresses of the 20 strategic partners pools.
    function VITTokenSale(address _fundingRecipient, uint256 _startTime, uint256 _endTime, uint256 _refundEndTime,
        uint256 _vitPerWei, address[20] _strategicPartnersPools) public {
        require(_fundingRecipient != address(0));
        require(_startTime > now && _startTime < _endTime && _endTime < _refundEndTime);
        require(_startTime.add(RESTRICTED_PERIOD_DURATION) < _endTime);
        require(_vitPerWei > 0);

        for (uint i = 0; i < _strategicPartnersPools.length; ++i) {
            require(_strategicPartnersPools[i] != address(0));
        }

        fundingRecipient = _fundingRecipient;
        startTime = _startTime;
        endTime = _endTime;
        refundEndTime = _refundEndTime;
        vitPerWei = _vitPerWei;
        strategicPartnersPools = _strategicPartnersPools;

        // Deploy new VITToken contract.
        vitToken = new VITToken();

        // Grant initial token allocations.
        grantInitialAllocations();
    }

    /// @dev Fallback function that will delegate the request to create().
    function () external payable onlyDuringSale {
        address recipient = msg.sender;

        uint256 cappedWeiReceived = msg.value;
        uint256 weiAlreadyParticipated = participationHistory[recipient];

        // If we&#39;re during the restricted period, then only the white-listed participants are allowed to participate,
        if (saleDuringRestrictedPeriod()) {
            uint256 participationCap = participationCaps[recipient];
            cappedWeiReceived = Math.min256(cappedWeiReceived, participationCap.sub(weiAlreadyParticipated));
        }

        require(cappedWeiReceived > 0);

        // Calculate how much tokens can be sold to this participant.
        uint256 tokensLeftInSale = MAX_TOKENS_SOLD.sub(tokensSold);
        uint256 weiLeftInSale = tokensLeftInSale.div(vitPerWei);
        uint256 weiToParticipate = Math.min256(cappedWeiReceived, weiLeftInSale);
        participationHistory[recipient] = weiAlreadyParticipated.add(weiToParticipate);

        // Issue tokens and transfer to recipient.
        uint256 tokensToIssue = weiToParticipate.mul(vitPerWei);
        if (tokensLeftInSale.sub(tokensToIssue) < vitPerWei) {
            // If purchase would cause less than vitPerWei tokens left then nobody could ever buy them, so we&#39;ll gift
            // them to the last buyer.
            tokensToIssue = tokensLeftInSale;
        }

        // Record the both the participate ETH and tokens for future refunds.
        refundableEther[recipient] = refundableEther[recipient].add(weiToParticipate);
        claimableTokens[recipient] = claimableTokens[recipient].add(tokensToIssue);

        // Update token counters.
        totalClaimableTokens = totalClaimableTokens.add(tokensToIssue);
        tokensSold = tokensSold.add(tokensToIssue);

        // Issue the tokens to the token sale smart contract itself, which will hold them for future refunds.
        issueTokens(address(this), tokensToIssue);

        // Partial refund if full participation not possible, e.g. due to cap being reached.
        uint256 refund = msg.value.sub(weiToParticipate);
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
    }

    /// @dev Set restricted period participation caps for a list of addresses.
    /// @param _participants address[] The list of participant addresses.
    /// @param _cap uint256 The cap amount (in ETH).
    function setRestrictedParticipationCap(address[] _participants, uint256 _cap) external onlyOwner {
        for (uint i = 0; i < _participants.length; ++i) {
            participationCaps[_participants[i]] = _cap;
        }
    }

    /// @dev Finalizes the token sale event, by stopping token minting.
    function finalize() external onlyAfterSale {
        // Issue any unsold tokens back to the company.
        if (tokensSold < MAX_TOKENS_SOLD) {
            issueTokens(fundingRecipient, MAX_TOKENS_SOLD.sub(tokensSold));
        }

        // Finish minting. Please note, that if minting was already finished - this call will revert().
        vitToken.finishMinting();

        Finalized();
    }

    function finalizeRefunds() external onlyAfterRefund {
        require(!finalizedRefund);

        finalizedRefund = true;

        // Transfer all the Ether to the beneficiary of the funding.
        fundingRecipient.transfer(this.balance);

        FinalizedRefunds();
    }

    /// @dev Reclaim all ERC20 compatible tokens, but not more than the VIT tokens which were reserved for refunds.
    /// @param token ERC20Basic The address of the token contract.
    function reclaimToken(ERC20Basic token) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        if (token == vitToken) {
            balance = balance.sub(totalClaimableTokens);
        }

        assert(token.transfer(owner, balance));
    }

    /// @dev Allows participants to claim their tokens, which also transfers the Ether to the funding recipient.
    /// @param _tokensToClaim uint256 The amount of tokens to claim.
    function claimTokens(uint256 _tokensToClaim) public onlyAfterSale {
        require(_tokensToClaim != 0);

        address participant = msg.sender;
        require(claimableTokens[participant] > 0);

        uint256 claimableTokensAmount = claimableTokens[participant];
        require(_tokensToClaim <= claimableTokensAmount);

        uint256 refundableEtherAmount = refundableEther[participant];
        uint256 etherToClaim = _tokensToClaim.mul(refundableEtherAmount).div(claimableTokensAmount);
        assert(etherToClaim > 0);

        refundableEther[participant] = refundableEtherAmount.sub(etherToClaim);
        claimableTokens[participant] = claimableTokensAmount.sub(_tokensToClaim);
        totalClaimableTokens = totalClaimableTokens.sub(_tokensToClaim);

        // Transfer the tokens from the token sale smart contract to the participant.
        assert(vitToken.transfer(participant, _tokensToClaim));

        // Transfer the Ether to the beneficiary of the funding (as long as the refund hasn&#39;t finalized yet).
        if (!finalizedRefund) {
            fundingRecipient.transfer(etherToClaim);
        }

        TokensClaimed(participant, _tokensToClaim);
    }

    /// @dev Allows participants to claim all their tokens.
    function claimAllTokens() public onlyAfterSale {
        uint256 claimableTokensAmount = claimableTokens[msg.sender];
        claimTokens(claimableTokensAmount);
    }

    /// @dev Allows participants to claim refund for their purchased tokens.
    /// @param _etherToClaim uint256 The amount of Ether to claim.
    function refundEther(uint256 _etherToClaim) public onlyDuringRefund {
        require(_etherToClaim != 0);

        address participant = msg.sender;

        uint256 refundableEtherAmount = refundableEther[participant];
        require(_etherToClaim <= refundableEtherAmount);

        uint256 claimableTokensAmount = claimableTokens[participant];
        uint256 tokensToClaim = _etherToClaim.mul(claimableTokensAmount).div(refundableEtherAmount);
        assert(tokensToClaim > 0);

        refundableEther[participant] = refundableEtherAmount.sub(_etherToClaim);
        claimableTokens[participant] = claimableTokensAmount.sub(tokensToClaim);
        totalClaimableTokens = totalClaimableTokens.sub(tokensToClaim);

        // Transfer the tokens to the beneficiary of the funding.
        assert(vitToken.transfer(fundingRecipient, tokensToClaim));

        // Transfer the Ether to the participant.
        participant.transfer(_etherToClaim);

        EtherRefunded(participant, _etherToClaim);
    }

    /// @dev Allows participants to claim refund for all their purchased tokens.
    function refundAllEther() public onlyDuringRefund {
        uint256 refundableEtherAmount = refundableEther[msg.sender];
        refundEther(refundableEtherAmount);
    }

    /// @dev Initialize token grants.
    function grantInitialAllocations() private onlyOwner {
        for (uint i = 0; i < strategicPartnersPools.length; ++i) {
            issueTokens(strategicPartnersPools[i], STRATEGIC_PARTNERS_POOL_ALLOCATION);
        }
    }

    /// @dev Issues tokens for the recipient.
    /// @param _recipient address The address of the recipient.
    /// @param _tokens uint256 The amount of tokens to issue.
    function issueTokens(address _recipient, uint256 _tokens) private {
        // Request VIT token contract to mint the requested tokens for the buyer.
        assert(vitToken.mint(_recipient, _tokens));

        TokensIssued(_recipient, _tokens);
    }

    /// @dev Returns whether the sale has ended.
    /// @return bool Whether the sale has ended or not.
    function saleEnded() private view returns (bool) {
        return tokensSold >= MAX_TOKENS_SOLD || now >= endTime;
    }

    /// @dev Returns whether the sale is during its restricted period, where only white-listed participants are allowed
    /// to participate.
    /// @return bool Whether the sale is during its restricted period, where only white-listed participants are allowed
    /// to participate.
    function saleDuringRestrictedPeriod() private view returns (bool) {
        return now <= startTime.add(RESTRICTED_PERIOD_DURATION);
    }

    /// @dev Returns whether the sale is during its refund period.
    /// @return bool whether the sale is during its refund period.
    function saleDuringRefundPeriod() private view returns (bool) {
        return saleEnded() && now <= refundEndTime;
    }

    /// @dev Returns whether the sale is during its refund period.
    /// @return bool whether the sale is during its refund period.
    function saleAfterRefundPeriod() private view returns (bool) {
        return saleEnded() && now > refundEndTime;
    }
}