pragma solidity ^0.4.21;



/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract ERC777Token {
    // 获取Token的名称
    function name() public view returns (string);
    // 获取Token的符号，例如HIX
    function symbol() public view returns (string);
    // 获取代币总的支持量
    function totalSupply() public view returns (uint256);
    // 获取最小的交易单位
    function granularity() public view returns (uint256);
    
    // 获取默认允许操作的地址
    function defaultOperators() public view returns (address[]);
    // 查询某个合约地址是否被授予某个合约操作权限
    function isOperatorFor(address operator, address tokenHolder) public view returns (bool);
    // 批准指定的地址对Token的操作权限
    function authorizeOperator(address operator) public;
    // 撤销指定地址对Token的操作权限
    function revokeOperator(address operator) public;

    // 发送交易，区别于ERC20的transfer，但是功能一样，增加了允许加入用户自定义数据
    function send(address to, uint256 amount, bytes holderData) public;
    function operatorSend(address from, address to, uint256 amount, bytes holderData, bytes operatorData) public;

    function burn(uint256 amount, bytes holderData) public;
    function operatorBurn(address from, uint256 amount, bytes holderData, bytes operatorData) public;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes holderData,
        bytes operatorData
    ); // solhint-disable-next-line separate-by-one-line-in-contract
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes holderData, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

contract ERC777DemoToken is ERC777Token {
    string internal mName = "ERC777DemoToken";
    string internal mSymbol = "EDT1";
    uint8 public mDecimals = 18;
    uint256 internal mGranularity = 1;
    uint256 internal mTotalSupply = 1000000;

    mapping(address => uint) internal mBalances;
    mapping(address => mapping(address => bool)) internal mAuthorized;

    address[] internal mDefaultOperators;
    mapping(address => bool) internal mIsDefaultOperator;
    mapping(address => mapping(address => bool)) internal mRevokedDefaultOperator;
    
    function ERC777DemoToken(string name, string symbol, uint256 initialSupply) {
        mTotalSupply = initialSupply * 10 ** uint256(mDecimals); 
        
        mName = name;
        mSymbol = symbol;
        mBalances[msg.sender] = mTotalSupply;
    }
    
    /* -- ERC777 Interface Implementation -- */
    //
    /// @return the name of the token
    function name() public constant returns (string) { return mName; }

    /// @return the symbol of the token
    function symbol() public constant returns (string) { return mSymbol; }

    /// @return the granularity of the token
    function granularity() public constant returns (uint256) { return mGranularity; }

    /// @return the total supply of the token
    function totalSupply() public constant returns (uint256) { return mTotalSupply; }
    
    /// @notice Return the account balance of some account
    /// @param _tokenHolder Address for which the balance is returned
    /// @return the balance of `_tokenAddress`.
    function balanceOf(address _tokenHolder) public constant returns (uint256) { return mBalances[_tokenHolder]; }
    
    /// @notice Return the list of default operators
    /// @return the list of all the default operators
    function defaultOperators() public view returns (address[]) { return mDefaultOperators; }

    /// @notice Authorize a third party `_operator` to manage (send) `msg.sender`&#39;s tokens.
    /// @param _operator The operator that wants to be Authorized
    function authorizeOperator(address _operator) public {
        require(_operator != msg.sender);
        if (mIsDefaultOperator[_operator]) {
            mRevokedDefaultOperator[_operator][msg.sender] = false;
        } else {
            mAuthorized[_operator][msg.sender] = true;
        }
        //AuthorizedOperator(_operator, msg.sender);
    }

    /// @notice Revoke a third party `_operator`&#39;s rights to manage (send) `msg.sender`&#39;s tokens.
    /// @param _operator The operator that wants to be Revoked
    function revokeOperator(address _operator) public {
        require(_operator != msg.sender);
        if (mIsDefaultOperator[_operator]) {
            mRevokedDefaultOperator[_operator][msg.sender] = true;
        } else {
            mAuthorized[_operator][msg.sender] = false;
        }
        //RevokedOperator(_operator, msg.sender);
    }

    /// @notice Check whether the `_operator` address is allowed to manage the tokens held by `_tokenHolder` address.
    /// @param _operator address to check if it has the right to manage the tokens
    /// @param _tokenHolder address which holds the tokens to be managed
    /// @return `true` if `_operator` is authorized for `_tokenHolder`
    function isOperatorFor(address _operator, address _tokenHolder) public constant returns (bool) {
        return (_operator == _tokenHolder
            || mAuthorized[_operator][_tokenHolder]
            || (mIsDefaultOperator[_operator] && !mRevokedDefaultOperator[_operator][_tokenHolder]));
    }

    /// @notice Send `_amount` of tokens to address `_to` passing `_userData` to the recipient
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    function send(address _to, uint256 _amount, bytes _userData) public {
        doSend(msg.sender, msg.sender, _to, _amount, _userData, "", true);
    }

    /// @notice Send `_amount` of tokens on behalf of the address `from` to the address `to`.
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _userData Data generated by the user to be sent to the recipient
    /// @param _operatorData Data generated by the operator to be sent to the recipient
    function operatorSend(address _from, address _to, uint256 _amount, bytes _userData, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _from));
        doSend(msg.sender, _from, _to, _amount, _userData, _operatorData, true);
    }

    function burn(uint256 _amount, bytes _holderData) public {
        doBurn(msg.sender, msg.sender, _amount, _holderData, "");
    }

    function operatorBurn(address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _tokenHolder));
        doBurn(msg.sender, _tokenHolder, _amount, _holderData, _operatorData);
    }

    /// @notice Internal function that ensures `_amount` is multiple of the granularity
    /// @param _amount The quantity that want&#39;s to be checked
    function requireMultiple(uint256 _amount) internal view {
        require(_amount/mGranularity*mGranularity == _amount);
    }

    /// @notice Helper function that checks for ERC777TokensSender on the sender and calls it.
    ///  May throw according to `_preventLocking`
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be sent
    /// @param _userData Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    ///  implementing `ERC777TokensSender`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function callSender(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData
    )
        internal
    {
        return;
        // TODO: ImpleImplement it
        //address senderImplementation = interfaceAddr(_from, "ERC777TokensSender");
        //if (senderImplementation == 0) { return; }
        //ERC777TokensSender(senderImplementation).tokensToSend(_operator, _from, _to, _amount, _userData, _operatorData);
    }


    /// @notice Helper function that checks for ERC777TokensRecipient on the recipient and calls it.
    ///  May throw according to `_preventLocking`
    /// @param _operator The address performing the send or mint
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _userData Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    /// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
    ///  implementing `ERC777TokensRecipient`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function callRecipient(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    )
        internal
    {
        // TODO: Implement 
        //address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
        //if (recipientImplementation != 0) {
        //    ERC777TokensRecipient(recipientImplementation).tokensReceived(
        //        _operator, _from, _to, _amount, _userData, _operatorData);
        //} else if (_preventLocking) {
        //    require(isRegularAddress(_to));
        //}
    }
    

    /// @notice Helper function actually performing the sending of tokens.
    /// @param _operator The address performing the send
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _userData Data generated by the user to be passed to the recipient
    /// @param _operatorData Data generated by the operator to be passed to the recipient
    /// @param _preventLocking `true` if you want this function to throw when tokens are sent to a contract not
    ///  implementing `erc777_tokenHolder`.
    ///  ERC777 native Send functions MUST set this parameter to `true`, and backwards compatible ERC20 transfer
    ///  functions SHOULD set this parameter to `false`.
    function doSend(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    )
        internal
    {
        //requireMultiple(_amount);

        //callSender(_operator, _from, _to, _amount, _userData, _operatorData);

        require(_to != address(0));          // forbid sending to 0x0 (=burning)
        require(mBalances[_from] >= _amount); // ensure enough funds

        mBalances[_from] = mBalances[_from] - _amount;
        mBalances[_to] = mBalances[_to] + _amount;

        //callRecipient(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);

        Sent(_operator, _from, _to, _amount, _userData, _operatorData);
    }

    /// @notice Helper function actually performing the burning of tokens.
    /// @param _operator The address performing the burn
    /// @param _tokenHolder The address holding the tokens being burn
    /// @param _amount The number of tokens to be burnt
    /// @param _holderData Data generated by the token holder
    /// @param _operatorData Data generated by the operator
    function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData)
        internal
    {
        requireMultiple(_amount);
        require(balanceOf(_tokenHolder) >= _amount);

        mBalances[_tokenHolder] = mBalances[_tokenHolder] - _amount;
        mTotalSupply = mTotalSupply - _amount;

        callSender(_operator, _tokenHolder, 0x0, _amount, _holderData, _operatorData);
        Burned(_operator, _tokenHolder, _amount, _holderData, _operatorData);
    }
}