// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


contract TellorPlayground {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TipAdded(address indexed _sender, bytes32 indexed _requestId, uint256 _tip);
    event NewValue(bytes32 _requestId, uint256 _time, bytes _value);
    
    mapping(bytes32 => mapping(uint256 => bytes)) public values; //requestId -> timestamp -> value
    mapping(bytes32=> mapping(uint256 => bool)) public isDisputed; //requestId -> timestamp -> value
    mapping(bytes32 => uint256[]) public timestamps;
    mapping(address => uint) public balances;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory _iName, string memory _iSymbol) {
        _name = _iName;
        _symbol = _iSymbol;
        _decimals = 18;
    }

    /**
     * @dev Public function to mint tokens for the passed address
     * @param _user The address which will own the tokens
     *
     */
    function faucet(address _user) external {
        _mint(_user, 1000 ether);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the balance of a given user.
     */
    function balanceOf(address _account) public view returns (uint256) {
        return _balances[_account];
    }

    /**
     * @dev Transfer tokens from user to another
     * @param _recipient The destination address
     * @param _amount The amount of tokens, including decimals, to transfer
     * @return bool If the transfer succeeded
     *
     */
    function transfer(address _recipient, uint256 _amount) public virtual returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }


     /**
     * @dev Retruns the amount that an address is alowed to spend of behalf of other
     * @param _owner The address which owns the tokens
     * @param _spender The address that will use the tokens
     * @return uint256 Indicating the amount of allowed tokens
     *
     */
    function allowance(address _owner, address _spender) public view virtual returns (uint256) {
        return _allowances[_owner][_spender];
    }


     /**
     * @dev Approves  amount that an address is alowed to spend of behalf of other
     * @param _spender The address which user the tokens
     * @param _amount The amount that msg.sender is allowing spender to use
     * @return bool If the transaction succeeded
     *
     */
    function approve(address _spender, uint256 _amount) public virtual returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

     /**
     * @dev Transfer tokens from user to another
     * @param _sender The address which owns the tokens
     * @param _recipient The destination address
     * @param _amount The amount of tokens, including decimals, to transfer
     * @return bool If the transfer succeeded
     *
     */
    function transferFrom(address _sender, address _recipient, uint256 _amount) public virtual returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, _allowances[_sender][msg.sender] -_amount);
        return true;
    }

    /**
     * @dev Internal function to perform token transfer
     */
    function _transfer(address _sender, address _recipient, uint256 _amount) internal virtual {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        _balances[_sender] -=  _amount;
        _balances[_recipient] += _amount;
        emit Transfer(_sender, _recipient, _amount);
    }

    /**
     * @dev Internal function to create new tokens for the user
     */
    function _mint(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "ERC20: mint to the zero address");
        _totalSupply += _amount;
        _balances[_account] += _amount;
        emit Transfer(address(0), _account, _amount);
    }

    /**
     * @dev Internal function to burn tokens for the user
     */
    function _burn(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "ERC20: burn from the zero address");
        _balances[_account] -= _amount;
        _totalSupply -= _amount;
        emit Transfer(_account, address(0), _amount);
    }

    /**
     * @dev Internal function to approve tokens for the user
     */
    function _approve(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
    
    /**
    * @dev A mock function to submit a value to be read withoun miners needed
    * @param _requestId The tellorId to associate the value to
    * @param _value the value for the requestId
    */
    function submitValue(bytes32 _requestId, bytes calldata _value, uint256 _nonce) external {
        require(_nonce ==  timestamps[_requestId].length, "nonce should be correct");
        values[_requestId][block.timestamp] = _value;
        timestamps[_requestId].push(block.timestamp);
        emit NewValue(_requestId, block.timestamp, _value);
    }

    /**
    * @dev A mock function to create a dispute
    * @param _requestId The tellorId to be disputed
    * @param _timestamp the timestamp that indentifies for the value
    */
    function disputeValue(bytes32 _requestId, uint256 _timestamp) external {
        values[_requestId][_timestamp] = bytes("");
        isDisputed[_requestId][_timestamp] = true;
    }
    
    /**
    * @dev Retreive value from oracle based on requestId/timestamp
    * @param _requestId being requested
    * @param _timestamp to retreive data/value from
    * @return bytes value for requestId/timestamp submitted
    */
    function retrieveData(bytes32 _requestId, uint256 _timestamp) public view returns(bytes memory) {
        return values[_requestId][_timestamp];
    }

    /**
    * @dev Gets if the mined value for the specified requestId/_timestamp is currently under dispute
    * @param _requestId to looku p
    * @param _timestamp is the timestamp to look up miners for
    * @return bool true if requestId/timestamp is under dispute
    */
    function isInDispute(bytes32 _requestId, uint256 _timestamp) public view returns(bool){
        return isDisputed[_requestId][_timestamp];
    }

    /**
    * @dev Counts the number of values that have been submited for the request
    * @param _requestId the requestId to look up
    * @return uint count of the number of values received for the requestId
    */
    function getNewValueCountbyRequestId(bytes32 _requestId) public view returns(uint) {
        return timestamps[_requestId].length;
    }

    /**
    * @dev Gets the timestamp for the value based on their index
    * @param _requestId is the requestId to look up
    * @param _index is the value index to look up
    * @return uint timestamp
    */
    function getTimestampbyRequestIDandIndex(bytes32 _requestId, uint256 _index) public view returns(uint256) {
        uint256 len = timestamps[_requestId].length;
        if(len == 0 || len <= _index) return 0; 
        return timestamps[_requestId][_index];
    }

    /**
    * @dev Adds a tip to a given request Id.
    * @param _requestId is the requestId to look up
    * @param _amount is the amount of tips
    */
    function addTip(bytes32 _requestId, uint256 _amount) external {
        _transfer(msg.sender, address(this), _amount);
        emit TipAdded(msg.sender, _requestId, _amount);
    }
}

