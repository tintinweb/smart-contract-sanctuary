pragma solidity ^0.4.21;


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
    uint256 internal mGranularity = 18;
    uint256 internal mTotalSupply = 1000000;

    mapping(address => uint) internal mBalances;
    mapping(address => mapping(address => bool)) internal mAuthorized;

    address[] internal mDefaultOperators;
    mapping(address => bool) internal mIsDefaultOperator;
    mapping(address => mapping(address => bool)) internal mRevokedDefaultOperator;
    
    function ERC777DemoToken(string name, string symbol, uint256 granularity, uint256 totalSupply) {
        mName = name;
        mSymbol = symbol;
        mGranularity = granularity;
        mTotalSupply = totalSupply;
        
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
        //doSend(msg.sender, msg.sender, _to, _amount, _userData, "", true);
    }

    /// @notice Send `_amount` of tokens on behalf of the address `from` to the address `to`.
    /// @param _from The address holding the tokens being sent
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be sent
    /// @param _userData Data generated by the user to be sent to the recipient
    /// @param _operatorData Data generated by the operator to be sent to the recipient
    function operatorSend(address _from, address _to, uint256 _amount, bytes _userData, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _from));
        //doSend(msg.sender, _from, _to, _amount, _userData, _operatorData, true);
    }

    function burn(uint256 _amount, bytes _holderData) public {
        //doBurn(msg.sender, msg.sender, _amount, _holderData, "");
    }

    function operatorBurn(address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _tokenHolder));
        //doBurn(msg.sender, _tokenHolder, _amount, _holderData, _operatorData);
    }


}