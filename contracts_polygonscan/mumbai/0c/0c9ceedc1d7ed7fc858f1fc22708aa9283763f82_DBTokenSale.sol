/**
 *Submitted for verification at polygonscan.com on 2021-08-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract DBToken is IERC20, Context {
    address public _owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    string private _eventCode;
    string private _teamName;

    /**
     * @dev Next to the regular name and symbol params, constructor takes an event code and team which represent the team 
     * the token is representing
     * @param name_ Name of the token. Generally "DBToken"
     * @param symbol_ Symbol of the toke. Generally "DBT"
     * @param eventCode_ Event code of the token. Later could be used in the DBTokenSale contract to end the tokens under given event
     * @param teamName_ Name of the team the token is representing
     * @param totalSupply_ Initialy total supply of the tokens
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory eventCode_,
        string memory teamName_,
        uint256 totalSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _eventCode = eventCode_;
        _teamName = teamName_;
        _totalSupply = totalSupply_;
        _owner = _msgSender();
        _balances[_owner] = totalSupply_;
    }


    modifier ownerOnly() {
        require(_msgSender() == _owner, "DBToken: function can only be called by the owner");
        _;
    }



    function getName() external view returns (string memory) {
        return _name;
    }

    function getSymbol() external view returns (string memory) {
        return _symbol;
    }

    function getEventCode() external view returns (string memory) {
        return _eventCode;
    }

    function getTeamName() external view returns (string memory) {
        return _teamName;
    }

    function decimal() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(
            _allowances[sender][_msgSender()] >= amount,
            "DBToken: transfer amount exceeds allowance"
        );
        _transfer(sender, recipient, amount);

        unchecked {
            _approve(
                sender,
                _msgSender(),
                _allowances[sender][_msgSender()] - amount
            );
        }

        return true;
    }

    function _mint(address account, uint256 amount) external returns (bool) {
        require(account != address(0), "DBToken: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(
            sender != address(0),
            "DBToken: transfer from the zero address"
        );
        require(
            recipient != address(0),
            "DBToken: transfer to the zero address"
        );

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "DBToken: transfer amount exceeds balance"
        );

        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "DBToken: approve from the zero address");
        require(spender != address(0), "DBToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}
interface StandardToken {


    function transferFrom(address _from, address _to, uint _value) external;

    function transfer(address _to, uint256 _value) external;

    function approve(address _spender, uint _value) external;

    function allowance(address _owner, address _spender) external view returns (uint256);

    function balanceOf(address _owner) external returns (uint256);
}

contract DBTokenSale is Context {
    address private _owner;
    address private _withrawable;

    StandardToken public _standardToken;
    mapping(bytes32 => DBToken) public _dbtokens;

    uint256 private _saleStart;
    uint256 private _saleEnd;


    /**
     * @param standardToken_ Standard token is the USDT contract from which the sale contract will allow income of funds from. The contract should extend the StandardToken interface
     * @param withrawable Address where the funds can be withdrawn to
     */
    constructor(StandardToken standardToken_, address withrawable) {
        _standardToken = standardToken_;
        _owner = _msgSender();
        _withrawable = withrawable;
    }

    modifier ownerOnly() {
        require(
            _msgSender() == _owner,
            "DBTokenSale: function can only be called by the owner"
        );
        _;
    }

    modifier duringSale() {
        require(
            (time() >= _saleStart) && (time() < _saleEnd),
            "DBTokenSale: function can only be called during sale"
        );
        _;
    }

    modifier outsideOfSale() {
        require(
            (time() < _saleStart) || (time() >= _saleEnd),
            "DBTokenSale: function can only be called outside of sale"
        );
        _;
    }

    /**
     * @dev This function adds DBToken references to the _dbtokens mapping. The function expects event code and team name to be supplied. 
     * This is only added for additional security to check if the owner is adding the correct address.
     * @param _token Address of the DBToken you are adding
     * @param _eventCode Event code of the DBToken reference. Has to match the event code the token has been initialized with.
     * @param _teamName Same as event code. Has to match the team name the token has been initialized with
     */
    function addDBTokenReference(
        DBToken _token,
        string memory _eventCode,
        string memory _teamName
    ) public ownerOnly returns (bool) {
        bytes32 tokenEventCode = keccak256(bytes(_token.getEventCode()));
        bytes32 tokenTeamName = keccak256(bytes(_token.getTeamName()));
        bytes32 givenEventCode = keccak256(bytes(_eventCode));
        bytes32 givenTeamName = keccak256(bytes(_teamName));

        require(
            tokenEventCode == givenEventCode,
            "DBTokenSale: given event code doesn't match reference event code"
        );
        require(
            tokenTeamName == givenTeamName,
            "DBTokenSale: given team name doesn't match reference team name"
        );

        bytes32 tokenHash = getTokenHash(_eventCode, _teamName);

        _dbtokens[tokenHash] = _token;
        return true;
    }


    // Return current timestamp
    function time() private view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Function to set the start and end time of the next sale. 
     * Can only be called if there is currently no active sale and needs to be called by the owner of the contract.
     * @param start Unix time stamp of the start of sale. Needs to be a timestamp in the future. If the start is 0, the sale will start immediately.
     * @param end Unix time stamp of the end of sale. Needs to be a timestamp after the start
     */
    function setSaleStartEnd(uint256 start, uint256 end)
        public
        ownerOnly
        outsideOfSale
        returns (bool)
    {
        if (start != 0) {
            require(start > time(), "DBTokenSale: given past sale start time");
        } else {
            start = time();
        }
        require(
            end > start,
            "DBTokenSale: sale end time needs to be greater than start time"
        );

        _saleStart = start;
        _saleEnd = end;

        return true;
    }


    // Function can be called by the owner during a sale to end it prematurely
    function endSaleNow() public ownerOnly duringSale returns (bool) {
        _saleEnd = time();
        return true;
    }


    /**
     * @dev Public function which provides info if there is currently any active sale and when the sale status will update.
     * There are 3 possible return patterns:
     * 1) Sale isn't active and sale start time is in the future => saleActive: false, saleUpdateTime: _saleStart
     * 2) Sale is active => saleActive: true, saleUpdateTime: _saleEnd
     * 3) Sale isn't active and _saleStart isn't a timestamp in the future => saleActive: false, saleUpdateTime: 0
     */
    function isSaleOn()
        public
        view
        returns (bool saleActive, uint256 saleUpdateTime)
    {
        if (_saleStart > time()) {
            return (false, _saleStart);
        } else if (_saleEnd > time()) {
            return (true, _saleEnd);
        } else {
            return (false, 0);
        }
    }

    // Used for testing to lookup names
    function getNameOfToken(string memory _eventCode, string memory _teamName)
        public
        view
        returns (string memory)
    {
        bytes32 tokenHash = getTokenHash(_eventCode, _teamName);
        return _dbtokens[tokenHash].getTeamName();
    }


    /**
     * @dev Public function from which users can buy token from. A requirement for this purchase is that the user has approved 
     * at least the given amount of standardToken funds for transfer to contract address. The user has to input the event code 
     * and the team name of the token they are looking to purchase and the amount of tokens they are looking to purchase.
     * @param _eventCode Event code of the DBToken
     * @param _teamName Team name of the DBToken
     * @param amount Amount of tokens the user wants to purchase. Has to have pre-approved amount of USDT tokens for transfer.
     */
    function buyTokens(
        string memory _eventCode,
        string memory _teamName,
        uint256 amount
    ) public duringSale returns (bool) {
        bytes32 tokenHash = getTokenHash(_eventCode, _teamName);
        require(
            address(_dbtokens[tokenHash]) != address(0),
            "DBTokenSale: non-existing token selected"
        );
        require(
            _dbtokens[tokenHash].balanceOf(address(this)) >= amount,
            "DBTokenSale: insufficient tokens in contract account"
        );

        uint256 senderAllowance = _standardToken.allowance(
            _msgSender(),
            address(this)
        );
        require(
            senderAllowance >= amount,
            "DBTokenSale: insufficient allowance for standard token transaction"
        );

        uint256 dbtokenAmount = amount * rate();
        _standardToken.transferFrom(_msgSender(), address(this), amount);
        _dbtokens[tokenHash].transfer(_msgSender(), dbtokenAmount);

        return true;
    }


    /**
     * @dev Allows the owner of the contract to withdraw the funds from to contract to the address in the variable withdrawable
     * @param amount Amount of tokens standardTokens the owner wants to withdraw. If the amount is more than the current balance, all tokens are withdrawn.
     */
    function withdraw(uint256 amount) public ownerOnly returns (bool) {
        require(
            _withrawable != address(0),
            "DBTokenSale: withdrawable address is zero address"
        );
        uint256 tokenBalance = _standardToken.balanceOf(address(this));
        if (amount > tokenBalance) {
            amount = tokenBalance;
        }

        _standardToken.transfer(_withrawable, amount);
        return true;
    }

    function getTokenHash(string memory _eventCode, string memory _teamName)
        private
        pure
        returns (bytes32)
    {
        return keccak256(bytes(abi.encodePacked(_eventCode, _teamName)));
    }

    // Rate represents how many DBTokens can be purchased with 1 USDT
    function rate() public pure returns (uint256) {
        return 1;
    }
}