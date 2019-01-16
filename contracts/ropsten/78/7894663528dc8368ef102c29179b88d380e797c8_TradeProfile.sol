pragma solidity ^0.4.13;

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract Margin {
    using SafeMath for uint256;

    address public tokenAddress;
    mapping(address => uint256) marginBalances;
    event DepositWithToken(address indexed from, uint256 amount);
    event WithdrawMargin(address indexed from, uint256 amount);

    /**
    * @dev Gets the margin balance of the specified address.
    * @param _investor The address to query the the margin balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function marginBalanceOf(address _investor) public view returns (uint256) {
        return marginBalances[_investor];
    }

    /**
    * @notice Submit a presigned transfer which transfer tokens to this contract
    * @param _signature bytes The signature, issued by the owner.
    * @param _value uint256 The amount of tokens to be transferred.
    * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
    * @param _nonce uint256 Presigned transaction number.
    * @param _validUntil uint256 Block number until which the presigned transaction is still valid.
    */
    function depositWithToken(
        bytes _signature,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint256 _validUntil
    )
        public
        returns (bool)
    {
        require(block.number <= _validUntil);
        BCNTToken tokenContract = BCNTToken(tokenAddress);

        bytes32 hashedTx = ECRecovery.toEthSignedMessageHash(
          tokenContract.transferPreSignedHashing(tokenAddress, address(this), _value, _fee, _nonce, _validUntil)
        );
        address from = ECRecovery.recover(hashedTx, _signature);

        uint256 prevBalance = tokenContract.balanceOf(address(this));
        require(tokenContract.transferPreSigned(_signature, address(this), _value, _fee, _nonce, _validUntil));
        require(tokenContract.transfer(msg.sender, _fee));
        uint256 curBalance = tokenContract.balanceOf(address(this));
        require(curBalance == prevBalance + _value);

        marginBalances[from] = marginBalances[from].add(_value);

        emit DepositWithToken(from, _value);
        return true;
    }

    /**
    * @notice Withdraw specified amount of margin
    * @param _value uint256 The amount of margin to be withdrawn.
    */
    function withdrawMargin(
        uint256 _value
    )
        public
        returns (bool)
    {
        BCNTToken tokenContract = BCNTToken(tokenAddress);

        marginBalances[msg.sender] = marginBalances[msg.sender].sub(_value);
        require(tokenContract.transfer(msg.sender, _value));

        emit WithdrawMargin(msg.sender, _value);
        return true;
    }
}

contract MarginWithPresignedWithdraw is Margin{
    using SafeMath for uint256;

    event WithdrawMarginPreSigned(address indexed from, address indexed delegate, uint256 amount, uint256 fee);

    /**
    * @notice Submit a presigned withdraw to withdraw specified amount of margin
    * @param _signature bytes The signature, issued by the owner.
    * @param _from address The address which request to withdraw.
    * @param _value uint256 The amount of margin to be withdraw.
    * @param _fee uint256 The amount of tokens paid to msg.sender, by the requester.
    * @param _nonce uint256 Presigned transaction number.
    * @param _validUntil uint256 Block number until which the presigned transaction is still valid.
    */
    function withdrawMarginPreSigned(
        bytes _signature,
        address _from,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint256 _validUntil
    )
        public
        returns (bool)
    {
        require(block.number <= _validUntil);

        bytes32 hashedTx = ECRecovery.toEthSignedMessageHash(withdrawMarginPreSignedHashing(
            address(this),
            _from,
            _value,
            _fee,
            _nonce,
            _validUntil
        ));
        address from = ECRecovery.recover(hashedTx, _signature);
        require(_from == from);

        BCNTToken tokenContract = BCNTToken(tokenAddress);

        marginBalances[_from] = marginBalances[_from].sub(_value).sub(_fee);
        require(tokenContract.transfer(_from, _value));
        require(tokenContract.transfer(msg.sender, _fee));

        emit WithdrawMargin(_from, _value);
        emit WithdrawMarginPreSigned(_from, msg.sender, _value, _fee);
        return true;
    }

    /**
    * @notice Hash (keccak256) of the payload used by withdrawMarginPreSigned
    * @param _investContract address The address of the InvestContract.
    * @param _from address The address which request to withdraw.
    * @param _value uint256 The amount of margin to be withdraw.
    * @param _fee uint256 The amount of tokens paid to msg.sender, by the requester.
    * @param _nonce uint256 Presigned transaction number.
    * @param _validUntil uint256 Block number until which the presigned transaction is still valid.
    */
    function withdrawMarginPreSignedHashing(
        address _investContract,
        address _from,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint256 _validUntil
    )
        public
        pure
        returns (bytes32)
    {
        /* "ffffffff": withdrawMarginPreSignedHashing(address,address,address,uint256,uint256,uint256,uint256) */
        return keccak256(
            abi.encodePacked(
                bytes4(0xffffffff),
                _investContract,
                _from,
                _value,
                _fee,
                _nonce,
                _validUntil
            )
        );
    }
}

contract Invest is MarginWithPresignedWithdraw{
    using SafeMath for uint256;

    address public bincentive;
    mapping(address => mapping(bytes32 => address)) traderProfile;
    mapping(bytes => bool) internal registerSignatures;
    mapping(bytes => bool) internal transferSignatures;
    mapping(bytes => bool) internal followTraderSignatures;
    event RegisterTradeProfile(address indexed trader, address indexed profileAddr);
    event CloseTradeProfile(address indexed trader, address indexed profileAddr);
    event FollowTrader(address indexed follower, address indexed trader, uint256 marginAmount);
    event ClearTrade(address indexed follower, address indexed trader, uint256 investedAmount, int256 profitAmount, string causeToClear);

    // Group the local variables together to prevent
    // Compiler error: Stack too deep, try removing local variables.
    struct LocalVariableGrouping {
        bytes32 hashedTx;
        address from;
        BCNTToken tokenContract;
        TradeProfile profile;
    }

    /**
    * @dev Gets the trade profile address of the specified trader address.
    * @param _trader The address to query the profile of.
    * @param _strategyID The strategy ID of the profile
    * @return The trader&#39;s profile address.
    */
    function profileOf(address _trader, bytes32 _strategyID) public view returns (address) {
        return traderProfile[_trader][_strategyID];
    }

    /**
    * @notice Register a trade profile
    * @param _registerSignature bytes The signature for register trade profile, issued by the trader.
    * @param _strategyID bytes32 The strategy ID of the trade profile.
    * @param _registerFee uint256 Fee paid for the registration by trader
    * @param _periodLength uint256 Period length of a follow trade.
    * @param _maxMarginDeposit uint256 The maximum amount to join the follow trade.
    * @param _minMarginDeposit uint256 The minimum amount to join the follow trade.
    * @param _rewardPercentage uint256 The ratio of the profit paid to the trader.
    * @param _nonce uint256 Presigned transaction number.
    * @param _transferSignature bytes The signature for transfer register fee, issued by the trader.
    *        _transferSignature is the signature on (_registerFee, 0, _nonce, _validUntil)
    * @param _validUntil uint256 Block number until which the presigned transaction is still valid.
    */
    function registerTradeProfile(
        bytes _registerSignature,
        bytes32 _strategyID,
        uint256 _registerFee,
        uint256 _periodLength,
        uint256 _maxMarginDeposit,
        uint256 _minMarginDeposit,
        uint256 _rewardPercentage,
        uint256 _nonce,
        bytes _transferSignature,
        uint256 _validUntil
    )
        public
        returns (bool)
    {
        require(msg.sender == bincentive);
        require(registerSignatures[_registerSignature] == false);
        require(transferSignatures[_transferSignature] == false);

        LocalVariableGrouping memory localVariables;

        localVariables.hashedTx = ECRecovery.toEthSignedMessageHash(registerPreSignedHashing(
            address(this),
            _strategyID,
            _registerFee,
            _periodLength,
            _maxMarginDeposit,
            _minMarginDeposit,
            _rewardPercentage,
            _nonce
        ));
        localVariables.from = ECRecovery.recover(localVariables.hashedTx, _registerSignature);
        require(traderProfile[localVariables.from][_strategyID] == address(0));

        if(_registerFee > 0) {
            localVariables.tokenContract = BCNTToken(tokenAddress);
        
            localVariables.hashedTx = ECRecovery.toEthSignedMessageHash(
                localVariables.tokenContract.transferPreSignedHashing(tokenAddress, address(this), _registerFee, 0, _nonce, _validUntil)
            );
            require(ECRecovery.recover(localVariables.hashedTx, _transferSignature) == localVariables.from);

            require(localVariables.tokenContract.transferPreSigned(_transferSignature, address(this), _registerFee, 0, _nonce, _validUntil));
        }

        localVariables.profile = new TradeProfile(localVariables.from, _periodLength, _maxMarginDeposit, _minMarginDeposit, _rewardPercentage);
        traderProfile[localVariables.from][_strategyID] = localVariables.profile;
        registerSignatures[_registerSignature] = true;
        transferSignatures[_transferSignature] = true;

        emit RegisterTradeProfile(localVariables.from, localVariables.profile);
        return true;
    }

    /**
    * @notice Hash (keccak256) of the payload used by registerTradeProfile
    * @param _investContract address The address of the Invest Contract.
    * @param _strategyID bytes32 The strategy ID of the trade profile.
    * @param _registerFee uint256 Fee paid for the registration by trader
    * @param _periodLength uint256 Period length of a follow trade.
    * @param _maxMarginDeposit uint256 The maximum amount to join the follow trade.
    * @param _minMarginDeposit uint256 The minimum amount to join the follow trade.
    * @param _rewardPercentage uint256 The ratio of the profit paid to the trader.
    * @param _nonce uint256 Presigned transaction number.
    */
    function registerPreSignedHashing(
        address _investContract,
        bytes32 _strategyID,
        uint256 _registerFee,
        uint256 _periodLength,
        uint256 _maxMarginDeposit,
        uint256 _minMarginDeposit,
        uint256 _rewardPercentage,
        uint256 _nonce
    )
        public
        pure
        returns (bytes32)
    {
        /* "ffffffff": registerPreSignedHashing(...) */
        return keccak256(
            abi.encodePacked(
                bytes4(0xffffffff),
                _investContract,
                _strategyID,
                _registerFee,
                _periodLength,
                _maxMarginDeposit,
                _minMarginDeposit,
                _rewardPercentage,
                _nonce
            )
        );
    }

    /**
    * @notice Follow a trader
    * @param _signature bytes The signature, issued by the follower.
    * @param _trader address Address of the trader to follow.
    * @param _strategyID bytes32 The strategy ID of the trade profile.
    * @param _marginAmount uint256 The amount of this follow trade.
    * @param _oracle address The oracle of this follow trade that will report result when clearing.
    * @param _validUntil uint256 Block number until which the presigned transaction is still valid.
    */
    function followTrader(
        bytes _signature,
        address _trader,
        bytes32 _strategyID,
        uint256 _marginAmount,
        address _oracle,
        uint256 _validUntil
    )
        public
        returns (bool)
    {
        require(block.number <= _validUntil);
        require(followTraderSignatures[_signature] == false);

        require(traderProfile[_trader][_strategyID] != address(0));
        TradeProfile profile = TradeProfile(traderProfile[_trader][_strategyID]);

        bytes32 hashedTx = ECRecovery.toEthSignedMessageHash(followTraderPreSignedHashing(
            address(this),
            _trader,
            _strategyID,
            _marginAmount,
            _oracle,
            _validUntil
        ));
        address from = ECRecovery.recover(hashedTx, _signature);

        marginBalances[from] = marginBalances[from].sub(_marginAmount);
        require(profile.follow(from, _marginAmount, _oracle));

        followTraderSignatures[_signature] = true;

        emit FollowTrader(from, _trader, _marginAmount);
        return true;
    }

    /**
    * @notice Hash (keccak256) of the payload used by followTrader
    * @param _investContract address The address of the Invest Contract.
    * @param _trader address Address of the trader to follow.
    * @param _strategyID bytes32 The strategy ID of the trade profile.
    * @param _marginAmount uint256 The amount of this follow trade.
    * @param _oracle address The oracle of this follow trade that will report result when clearing.
    * @param _validUntil uint256 Block number until which the presigned transaction is still valid.
    */
    function followTraderPreSignedHashing(
        address _investContract,
        address _trader,
        bytes32 _strategyID,
        uint256 _marginAmount,
        address _oracle,
        uint256 _validUntil
    )
        public
        pure
        returns (bytes32)
    {
        /* "ffffffff": followTraderPreSignedHashing(...) */
        return keccak256(
            abi.encodePacked(
                bytes4(0xffffffff),
                _investContract,
                _trader,
                _strategyID,
                _marginAmount,
                _oracle,
                _validUntil
            )
        );
    }

    /**
    * @notice Clear a following trade
    * @param _signature bytes The signature, issued by the oracle.
    * @param _trader address Address of the trader to follow.
    * @param _strategyID bytes32 The strategy ID of the trade profile.
    * @param _follower address The follower of this trader.
    * @param _investedAmount uint256 The total amount the follower invest in this follow trade.
    * @param _profitAmount int256 The profit made in this follow trade, could be negative.
    * @param _causeToClear string The cause to clear this follow trade.
    */
    function clearTrade(
        bytes _signature,
        address _trader,
        bytes32 _strategyID,
        address _follower,
        uint256 _investedAmount,
        int256 _profitAmount,
        string _causeToClear
    )
        public
        returns (bool)
    {
        require(traderProfile[_trader][_strategyID] != address(0));
        TradeProfile profile = TradeProfile(traderProfile[_trader][_strategyID]);

        if(msg.sender != bincentive) {
            require(profile.startTimeOf(_follower) + profile.periodLength() <= now);
        }

        bytes32 hashedTx = ECRecovery.toEthSignedMessageHash(clearTradePreSignedHashing(
            address(this),
            _trader,
            _strategyID,
            _follower,
            _investedAmount,
            _profitAmount,
            _causeToClear
        ));
        address from = ECRecovery.recover(hashedTx, _signature);

        uint256 amountToTrader;
        uint256 amountToFollower;
        (amountToTrader, amountToFollower) = profile.clear(_follower, from, _profitAmount);
        marginBalances[_trader] = marginBalances[_trader].add(amountToTrader);
        marginBalances[_follower] = marginBalances[_follower].add(amountToFollower);

        emit ClearTrade(_follower, _trader, _investedAmount, _profitAmount, _causeToClear);
        return true;
    }


    /**
    * @notice Hash (keccak256) of the payload used by clearTrade
    * @param _investContract address The address of the Invest Contract.
    * @param _trader address Address of the trader to follow.
    * @param _strategyID bytes32 The strategy ID of the trade profile.
    * @param _follower address The follower of this trader.
    * @param _investedAmount uint256 The total amount the follower invest in this follow trade.
    * @param _profitAmount int256 The profit made in this follow trade, could be negative.
    * @param _causeToClear string The cause to clear this follow trade.
    */
    function clearTradePreSignedHashing(
        address _investContract,
        address _trader,
        bytes32 _strategyID,
        address _follower,
        uint256 _investedAmount,
        int256 _profitAmount,
        string _causeToClear
    )
        public
        pure
        returns (bytes32)
    {
        /* "ffffffff": clearTradePreSignedHashing(...) */
        return keccak256(
            abi.encodePacked(
                bytes4(0xffffffff),
                _investContract,
                _trader,
                _strategyID,
                _follower,
                _investedAmount,
                _profitAmount,
                _causeToClear
            )
        );
    }

    /**
    * @notice Close a trade profile
    * @param _signature bytes The signature for closing trade profile, issued by the trader.
    * @param _strategyID bytes32 The strategy ID of the trade profile.
    */
    function closeTradeProfile(bytes _signature, bytes32 _strategyID) public returns (bool) {
        require(msg.sender == bincentive);

        bytes32 hashedTx = ECRecovery.toEthSignedMessageHash(closePreSignedHashing(
            address(this),
            _strategyID
        ));
        address from = ECRecovery.recover(hashedTx, _signature);
        require(traderProfile[from][_strategyID] != address(0));

        TradeProfile profile = TradeProfile(traderProfile[from][_strategyID]);
        require(profile.close());

        emit CloseTradeProfile(from, profile);
        return true;
    }

    /**
    * @notice Hash (keccak256) of the payload used by closeTradeProfile
    * @param _investContract address The address of the Invest contract.
    * @param _strategyID bytes32 The strategy ID of the trade profile.
    */
    function closePreSignedHashing(
        address _investContract,
        bytes32 _strategyID
    )
        public
        pure
        returns (bytes32)
    {
        /* "ffffffff": registerPreSignedHashing(...) */
        return keccak256(
            abi.encodePacked(bytes4(0xffffffff), _investContract, _strategyID)
        );
    }

    constructor(address _tokenAddress) public {
        bincentive = msg.sender;
        tokenAddress = _tokenAddress;
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract StandardToken is ERC20, BasicToken {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) internal allowed;

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract DepositFromPrivateToken is StandardToken {
   using SafeMath for uint256;

   PrivateToken public privateToken;

   modifier onlyPrivateToken() {
     require(msg.sender == address(privateToken));
     _;
   }

   /**
   * @dev Deposit is the function should only be called from PrivateToken
   * When the user wants to deposit their private Token to Origin Token. They should
   * let the Private Token invoke this function.
   * @param _depositor address. The person who wants to deposit.
   */

   function deposit(address _depositor, uint256 _value) public onlyPrivateToken returns(bool){
     require(_value != 0);
     balances[_depositor] = balances[_depositor].add(_value);
     emit Transfer(privateToken, _depositor, _value);
     return true;
   }
 }

contract BCNTToken is DepositFromPrivateToken{
    using SafeMath for uint256;

    string public constant name = "Bincentive Token"; // solium-disable-line uppercase
    string public constant symbol = "BCNT"; // solium-disable-line uppercase
    uint8 public constant decimals = 18; // solium-disable-line uppercase
    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));
    mapping(bytes => bool) internal signatures;
    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);

    /**
    * @notice Submit a presigned transfer
    * @param _signature bytes The signature, issued by the owner.
    * @param _to address The address which you want to transfer to.
    * @param _value uint256 The amount of tokens to be transferred.
    * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
    * @param _nonce uint256 Presigned transaction number.
    * @param _validUntil uint256 Block number until which the presigned transaction is still valid.
    */
    function transferPreSigned(
        bytes _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint256 _validUntil
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(signatures[_signature] == false);
        require(block.number <= _validUntil);

        bytes32 hashedTx = ECRecovery.toEthSignedMessageHash(
          transferPreSignedHashing(address(this), _to, _value, _fee, _nonce, _validUntil)
        );

        address from = ECRecovery.recover(hashedTx, _signature);

        balances[from] = balances[from].sub(_value).sub(_fee);
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].add(_fee);
        signatures[_signature] = true;

        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }

    /**
    * @notice Hash (keccak256) of the payload used by transferPreSigned
    * @param _token address The address of the token.
    * @param _to address The address which you want to transfer to.
    * @param _value uint256 The amount of tokens to be transferred.
    * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
    * @param _nonce uint256 Presigned transaction number.
    * @param _validUntil uint256 Block number until which the presigned transaction is still valid.
    */
    function transferPreSignedHashing(
        address _token,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint256 _validUntil
    )
        public
        pure
        returns (bytes32)
    {
        /* "0d2d1bf5": transferPreSigned(address,address,uint256,uint256,uint256,uint256) */
        return keccak256(
            abi.encodePacked(
                bytes4(0x0a0fb66b),
                _token,
                _to,
                _value,
                _fee,
                _nonce,
                _validUntil
            )
        );
    }

    /**
    * @dev Constructor that gives _owner all of existing tokens.
    */
    constructor(address _admin) public {
        totalSupply_ = INITIAL_SUPPLY;
        privateToken = new PrivateToken(
          _admin, "Bincentive Private Token", "BCNP", decimals, INITIAL_SUPPLY
       );
    }
}

contract PrivateToken is StandardToken {
    using SafeMath for uint256;

    string public name; // solium-disable-line uppercase
    string public symbol; // solium-disable-line uppercase
    uint8 public decimals; // solium-disable-line uppercase

    address public admin;
    bool public isPublic;
    uint256 public unLockTime;
    DepositFromPrivateToken originToken;

    event StartPublicSale(uint256 unlockTime);
    event Deposit(address indexed from, uint256 value);
    /**
    *  @dev check if msg.sender is allowed to deposit Origin token.
    */
    function isDepositAllowed() internal view{
      // If the tokens isn&#39;t public yet all transfering are limited to origin tokens
      require(isPublic);
      require(msg.sender == admin || block.timestamp > unLockTime);
    }

    /**
    * @dev Deposit msg.sender&#39;s origin token to real token
    */
    function deposit(address _depositor) public returns (bool){
      isDepositAllowed();
      uint256 _value;
      _value = balances[_depositor];
      require(_value > 0);
      balances[_depositor] = 0;
      require(originToken.deposit(_depositor, _value));
      emit Deposit(_depositor, _value);

      // This event is for those apps calculate balance from events rather than balanceOf
      emit Transfer(_depositor, address(0), _value);
    }

    /**
    *  @dev Start Public sale and allow admin to deposit the token.
    *  normal users could deposit their tokens after the tokens unlocked
    */
    function startPublicSale(uint256 _unLockTime) public onlyAdmin {
      require(!isPublic);
      isPublic = true;
      unLockTime = _unLockTime;
      emit StartPublicSale(_unLockTime);
    }

    /**
    *  @dev unLock the origin token and start the public sale.
    */
    function unLock() public onlyAdmin{
      require(isPublic);
      unLockTime = block.timestamp;
    }

    modifier onlyAdmin() {
      require(msg.sender == admin);
      _;
    }

    constructor(address _admin, string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public{
      originToken = DepositFromPrivateToken(msg.sender);
      admin = _admin;
      name = _name;
      symbol = _symbol;
      decimals = _decimals;
      totalSupply_ = _totalSupply;
      balances[admin] = _totalSupply;
      emit Transfer(address(0), admin, _totalSupply);
    }
}

contract TradeProfile{
    using SafeMath for uint256;

    address public InvestContractAddress;
    address public owner;
    bool public isActive;
    uint256 public periodLength;
    uint256 public maxMarginDeposit;
    uint256 public minMarginDeposit;
    uint256 public rewardPercentage;
    mapping(address => uint256) investBalances;
    mapping(address => uint256) startTime;
    mapping(address => address) oracle;

    /**
    * @dev Gets the invest balance of the specified follower.
    * @param _follower address The follower to query the the invest balance of.
    * @return uint256 representing the amount invested by the passed follower.
    */
    function investBalanceOf(address _follower) public view returns (uint256) {
        return investBalances[_follower];
    }

    /**
    * @dev Gets the start time of the specified follower.
    * @param _follower address The follower to query the the start time of.
    * @return uint256 representing the start time of the follow trade.
    */
    function startTimeOf(address _follower) public view returns (uint256) {
        return startTime[_follower];
    }

    /**
    * @dev Gets the oracle of the specified follower.
    * @param _follower address The follower to query the the oracle of.
    * @return address representing the oracle of the follow trade.
    */
    function oracleOf(address _follower) public view returns (address) {
        return oracle[_follower];
    }

    /**
    * @dev Increase the invest balance of the specified follower.
    * @param _follower address The follower.
    * @param _amount uint256 The amount of margin to put into this follow trade.
    * @param _oracle address The oracle which has the authority to report the outcome of the follow trade.
    */
    function follow(address _follower, uint256 _amount, address _oracle) public returns (bool) {
        require(isActive);
        require(msg.sender == InvestContractAddress);

        investBalances[_follower] = investBalances[_follower].add(_amount);
        require(minMarginDeposit <= investBalances[_follower] && investBalances[_follower] <= maxMarginDeposit);

        if(startTime[_follower] == 0) {
            startTime[_follower] = now;
            oracle[_follower] = _oracle;
        }
    
        return true;
    }

    /**
    * @notice Clear a following trade
    * @param _follower address The follower of this trader.
    * @param _oracle address The oracle which has the authority to report the outcome of the follow trade.
    * @param _profitAmount int256 The profit made in this follow trade.
    */
    function clear(
        address _follower,
        address _oracle,
        int256 _profitAmount
    )
        public
        returns (uint256 amountToTrader, uint256 amountToFollower)
    {
        require(msg.sender == InvestContractAddress);
        require(_oracle == oracle[_follower]);

        uint256 balance = investBalances[_follower];

        delete investBalances[_follower];
        delete startTime[_follower];
        delete oracle[_follower];

        if(_profitAmount <= 0) {
            amountToTrader = 0;
        }
        else {
            amountToTrader = uint256(_profitAmount) * rewardPercentage / 100;
            if(amountToTrader > balance) {
                amountToTrader = balance;
            }
        }
        amountToFollower = balance - amountToTrader;
    }

    function close() public returns (bool) {
        require(isActive);
        require(msg.sender == InvestContractAddress);
        isActive = false;
        return true;
    }

    constructor(address _owner, uint256 _periodLength, uint256 _maxMarginDeposit, uint256 _minMarginDeposit, uint256 _rewardPercentage) public {
        InvestContractAddress = msg.sender;
        owner = _owner;
        periodLength = _periodLength;
        maxMarginDeposit = _maxMarginDeposit;
        minMarginDeposit = _minMarginDeposit;
        rewardPercentage = _rewardPercentage;
        isActive = true;
    }
}