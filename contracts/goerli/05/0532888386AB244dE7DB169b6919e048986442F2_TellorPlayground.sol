// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract TellorPlayground {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event TipAdded(
        address indexed _sender,
        uint256 indexed _requestId,
        uint256 _tip
    );
    event NewValue(uint256 _requestId, uint256 _time, uint256 _value);
    event NewBytesValue(uint256 _requestId, uint256 _time, bytes _value);

    mapping(uint256 => mapping(uint256 => uint256)) public values; //requestId -> timestamp -> value
    mapping(uint256 => mapping(uint256 => bytes)) public bytesValues; //requestId -> timestamp -> value
    mapping(uint256 => mapping(uint256 => bool)) public isDisputed; //requestId -> timestamp -> value
    mapping(uint256 => uint256[]) public timestamps;
    mapping(address => uint256) public balances;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Public function to mint tokens for the passed address
     * @param user The address which will own the tokens
     *
     */
    function faucet(address user) external {
        _mint(user, 1000 ether);
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
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Transfer tokens from user to another
     * @param recipient The destination address
     * @param amount The amount of tokens, including decimals, to transfer
     * @return bool If the transfer succeeded
     *
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Retruns the amount that an address is alowed to spend of behalf of other
     * @param owner The address which owns the tokens
     * @param spender The address that will use the tokens
     * @return uint256 Indicating the amount of allowed tokens
     *
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev Approves  amount that an address is alowed to spend of behalf of other
     * @param spender The address which user the tokens
     * @param amount The amount that msg.sender is allowing spender to use
     * @return bool If the transaction succeeded
     *
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Transfer tokens from user to another
     * @param sender The address which owns the tokens
     * @param recipient The destination address
     * @param amount The amount of tokens, including decimals, to transfer
     * @return bool If the transfer succeeded
     *
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Helper function to increase the allowance
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Helper function to increase the allowance
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Internal function to perform token transfer
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Internal function to create new tokens for the user
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Internal function to burn tokens for the user
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Internal function to approve tokens for the user
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev A mock function to submit a value to be read withoun miners needed
     * @param _requestId The tellorId to associate the value to
     * @param _value the value for the requestId
     */
    function submitValue(uint256 _requestId, uint256 _value) external {
        values[_requestId][block.timestamp] = _value;
        timestamps[_requestId].push(block.timestamp);
        emit NewValue(_requestId, block.timestamp, _value);
    }

    function submitMiningSolution(
        string calldata _nonce,
        uint256[5] calldata _requestIds,
        uint256[5] calldata _values
    ) external view {}

    function getNewCurrentVariables()
        external
        view
        returns (
            bytes32 _challenge,
            uint256[5] memory _requestIds,
            uint256 _diff,
            uint256 _tip
        )
    {
        bytes32 ch = "HelloStackOverFlow";
        uint256[5] memory chall =
            [uint256(1), uint256(2), uint256(3), uint256(4), uint256(5)];
        return (ch, chall, 1, 1);
    }

    /**
     * @dev A mock function to submit a value to be read withoun miners needed
     * @param _requestId The tellorId to associate the value to
     * @param _value the value for the requestId
     */
    function submitBytesValue(uint256 _requestId, bytes memory _value)
        external
    {
        bytesValues[_requestId][block.timestamp] = _value;
        timestamps[_requestId].push(block.timestamp);
        emit NewBytesValue(_requestId, block.timestamp, _value);
    }

    /**
     * @dev A mock function to create a dispute
     * @param _requestId The tellorId to be disputed
     * @param _timestamp the timestamp that indentifies for the value
     */
    function disputeValue(uint256 _requestId, uint256 _timestamp) external {
        values[_requestId][_timestamp] = 0;
        isDisputed[_requestId][_timestamp] = true;
    }

    /**
     * @dev A mock function to create a dispute
     * @param _requestId The tellorId to be disputed
     * @param _timestamp the timestamp that indentifies for the value
     */
    function disputeBytesValue(uint256 _requestId, uint256 _timestamp)
        external
    {
        bytesValues[_requestId][_timestamp] = "";
        isDisputed[_requestId][_timestamp] = true;
    }

    /**
     * @dev Retreive value from oracle based on requestId/timestamp
     * @param _requestId being requested
     * @param _timestamp to retreive data/value from
     * @return uint256 value for requestId/timestamp submitted
     */
    function retrieveData(uint256 _requestId, uint256 _timestamp)
        public
        view
        returns (uint256)
    {
        return values[_requestId][_timestamp];
    }

    /**
     * @dev Retreive value from oracle based on requestId/timestamp
     * @param _requestId being requested
     * @param _timestamp to retreive data/value from
     * @return bytes value for requestId/timestamp submitted
     */
    function retrieveBytesData(uint256 _requestId, uint256 _timestamp)
        public
        view
        returns (bytes memory)
    {
        return bytesValues[_requestId][_timestamp];
    }

    /**
     * @dev Gets if the mined value for the specified requestId/_timestamp is currently under dispute
     * @param _requestId to looku p
     * @param _timestamp is the timestamp to look up miners for
     * @return bool true if requestId/timestamp is under dispute
     */
    function isInDispute(uint256 _requestId, uint256 _timestamp)
        public
        view
        returns (bool)
    {
        return isDisputed[_requestId][_timestamp];
    }

    /**
     * @dev Counts the number of values that have been submited for the request
     * @param _requestId the requestId to look up
     * @return uint count of the number of values received for the requestId
     */
    function getNewValueCountbyRequestId(uint256 _requestId)
        public
        view
        returns (uint256)
    {
        return timestamps[_requestId].length;
    }

    /**
     * @dev Gets the timestamp for the value based on their index
     * @param _requestId is the requestId to look up
     * @param index is the value index to look up
     * @return uint timestamp
     */
    function getTimestampbyRequestIDandIndex(uint256 _requestId, uint256 index)
        public
        view
        returns (uint256)
    {
        uint256 len = timestamps[_requestId].length;
        if (len == 0 || len <= index) return 0;
        return timestamps[_requestId][index];
    }

    /**
     * @dev Adds a tip to a given request Id.
     * @param _requestId is the requestId to look up
     * @param _amount is the amount of tips
     */
    function addTip(uint256 _requestId, uint256 _amount) external {
        _transfer(msg.sender, address(this), _amount);
        emit TipAdded(msg.sender, _requestId, _amount);
    }
}

