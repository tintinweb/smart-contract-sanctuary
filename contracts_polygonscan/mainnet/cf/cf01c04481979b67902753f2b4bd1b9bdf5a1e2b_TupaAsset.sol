/**
 *Submitted for verification at polygonscan.com on 2021-09-05
*/

//SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;


/**
 * SafeMath from OpenZeppelin - commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/5dfe7215a9156465d550030eadc08770503b2b2f
 *
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC20/IERC20.sol
//Commit: https://github.com/OpenZeppelin/openzeppelin-contracts/commit/b0cf6fbb7a70f31527f36579ad644e1cf12fdf4e
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



/**
 * @title TupaAsset is a template for Asset token
 * */
contract TupaAsset is IERC20 {
    using SafeMath for uint256;

    // mint/burn events
    event Mint(address indexed _to, uint256 _amount, uint256 _newTotalSupply);
    event Burn(address indexed _from, uint256 _amount, uint256 _newTotalSupply);

    // admin events
    event BlockLockSet(uint256 _value);
    event NewAdmin(address _newAdmin);
    event NewInvestor(address _newInvestor);
    event RemovedInvestor(address _investor);
    event CoinReceived(address sender, uint256 amount);

    modifier onlyAdmin {
        require(msg.sender == admin, "Only admin can perform this operation");
        _;
    }

    modifier boardOrAdmin {
        require(
            msg.sender == board || msg.sender == admin,
            "Only admin or board can perform this operation"
        );
        _;
    }

    modifier blockLock(address _sender) {
        require(
            !isLocked() || _sender == admin,
            "Contract is locked except for the admin"
        );
        _;
    }

    modifier onlyIfMintable() {
      require(mintable, "Token minting is disabled");
      _;
    }

    struct Investor {
        string info;
        bool exists;
    }

    uint256 public _totalSupply;
    string public name;
    uint8 public decimals;
    string public symbol;
    address public admin;
    address public board;
    uint256 public lockedUntilBlock;
    bool public mintable;
    bool public hasWhiteList;
    bool public isSyndicate;
    string public urlFinancialDetailsDocument;
    bytes32 public financialDetailsHash;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => Investor) public clearedInvestors;

    /**
     * @dev Constructor
     * @param _fundAdmin - Fund admin
     * @param _fundBoard - Board
     * @param _tokenName - Detailed ERC20 token name
     * @param _decimalUnits - Detailed ERC20 decimal units
     * @param _tokenSymbol - Detailed ERC20 token symbol
     * @param _lockedUntilBlock - Block lock
     * @param _newTotalSupply - Total Supply owned by the contract itself, only Manager can move
     * @param _mintable - True allows Manager to rebalance the portfolio
     * @param _hasWhiteList - Allows transfering only between whitelisted addresses
     * @param _isSyndicate - Allows secondary market
     */
    constructor(
        address _fundAdmin,
        address _fundBoard,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol,
        uint256 _lockedUntilBlock,
        uint256 _newTotalSupply,
        bool _mintable,
        bool _hasWhiteList,
        bool _isSyndicate
    )  {
        name = _tokenName;
        require(_decimalUnits <= 18, "Decimal units should be 18 or lower");
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
        lockedUntilBlock = _lockedUntilBlock;
        admin = _fundAdmin;
        board = _fundBoard;
        _totalSupply = _newTotalSupply;
        mintable = _mintable;
        hasWhiteList = _hasWhiteList;
        isSyndicate = _isSyndicate;
        balances[address(this)] = _totalSupply;
        Investor memory tmp = Investor("Contract", true);
        clearedInvestors[address(this)] = tmp;
        emit NewInvestor(address(this));
    }

    /**
     * @dev Set financial details url
     * @param _url - URL
     * @return True if success
     */
    function setFinancialDetails(string memory _url)
        public
        onlyAdmin
        returns (bool)
    {
        urlFinancialDetailsDocument = _url;
        return true;
    }

    /**
     * @dev Set financial details IPFS hash
     * @param _hash - URL
     * @return True if success
     */
    function setFinancialDetailsHash(bytes32 _hash)
        public
        onlyAdmin
        returns (bool)
    {
        financialDetailsHash = _hash;
        return true;
    }

    /**
     * @dev Whitelists an Investor
     * @param _investor - Address of the investor
     * @param _investorInfo - Info
     * @return True if success
     */
    function addNewInvestor(address _investor, string memory _investorInfo)
        public
        onlyAdmin
        returns (bool)
    {
        require(_investor != address(0), "Invalid investor address");
        Investor memory tmp = Investor(_investorInfo, true);
        clearedInvestors[_investor] = tmp;
        emit NewInvestor(_investor);
        return true;
    }

    /**
     * @dev Removes an Investor from whitelist
     * @param _investor - Address of the investor
     * @return True if success
     */
    function removeInvestor(address _investor) public onlyAdmin returns (bool) {
        require(_investor != address(0), "Invalid investor address");
        delete (clearedInvestors[_investor]);
        emit RemovedInvestor(_investor);
        return true;
    }
    
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev ERC20 Transfer
     * @param _to - destination address
     * @param _value - value to transfer
     * @return True if success
     */
    function transfer(address _to, uint256 _value)
        public
        override
        blockLock(msg.sender)
        returns (bool)
    {
        address from = (admin == msg.sender) ? address(this) : msg.sender;
        require(
            isTransferValid(from, _to, _value),
            "Invalid Transfer Operation"
        );
        balances[from] = balances[from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(from, _to, _value);
        return true;
    }

    /**
     * @dev ERC20 Approve
     * @param _spender - destination address
     * @param _value - value to be approved
     * @return True if success
     */
    function approve(address _spender, uint256 _value)
        public
        override
        blockLock(msg.sender)
        returns (bool)
    {
        require(_spender != address(0), "ERC20: approve to the zero address");

        address from = (admin == msg.sender) ? address(this) : msg.sender;
        allowed[from][_spender] = _value;
        emit Approval(from, _spender, _value);
        return true;
    }

    /**
     * @dev ERC20 TransferFrom
     * @param _from - source address
     * @param _to - destination address
     * @param _value - value
     * @return True if success
     */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        override
        blockLock(_from)
        returns (bool)
    {
        // check sufficient allowance
        require(
            _value <= allowed[_from][msg.sender],
            "Value informed is invalid"
        );
        require(
            isTransferValid(_from, _to, _value),
            "Invalid Transfer Operation"
        );
        // transfer tokens
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(
            _value,
            "Value lower than approval"
        );

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Mint new tokens. Can only be called by minter or owner
     * @param _to - destination address
     * @param _value - value
     * @return True if success
     */
    function mint(address _to, uint256 _value)
        public
        onlyIfMintable
        onlyAdmin
        blockLock(msg.sender)
        returns (bool)
    {
        balances[_to] = balances[_to].add(_value);
        _totalSupply = _totalSupply.add(_value);

        emit Mint(_to, _value, _totalSupply);
        emit Transfer(address(0), _to, _value);

        return true;
    }

    /**
     * @dev Burn tokens
     * @param _account - address
     * @param _value - value
     * @return True if success
     */
    function burn(address payable _account, uint256 _value)
        public
        payable
        blockLock(msg.sender)
        onlyAdmin
        returns (bool)
    {
        require(_account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(_value);
        balances[_account] = balances[_account].sub(_value);
        emit Transfer(_account, address(0), _value);
        emit Burn(_account, _value, _totalSupply);
        if (msg.value > 0) {
            (bool success, ) = _account.call{value: msg.value}("");
            require(success, "Ether transfer failed.");
        }
        return true;
    }

    /**
     * @dev Set block lock. Until that block (exclusive) transfers are disallowed
     * @param _lockedUntilBlock - Block Number
     * @return True if success
     */
    function setBlockLock(uint256 _lockedUntilBlock)
        public
        boardOrAdmin
        returns (bool)
    {
        lockedUntilBlock = _lockedUntilBlock;
        emit BlockLockSet(_lockedUntilBlock);
        return true;
    }

    /**
     * @dev Replace current admin with new one
     * @param _newAdmin New token admin
     * @return True if success
     */
    function replaceAdmin(address _newAdmin)
        public
        boardOrAdmin
        returns (bool)
    {
        require(_newAdmin != address(0x0), "Null address");
        admin = _newAdmin;
        emit NewAdmin(_newAdmin);
        return true;
    }

    
    /**
     * @dev ERC20 balanceOf
     * @param _owner Owner address
     * @return True if success
     */
    function balanceOf(address _owner) public override view returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev ERC20 allowance
     * @param _owner Owner address
     * @param _spender Address allowed to spend from Owner's balance
     * @return uint256 allowance
     */
    function allowance(address _owner, address _spender)
        public
        override
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }
    
    /**
     * @dev Getter for the wallet balance for a given asset
     * @param _assetAddress - Asset to check balance
     * @return Balance
     */
    function getAssetBalance(address _assetAddress) public view returns (uint256) {
        IERC20 erc20 = IERC20(_assetAddress);
        return erc20.balanceOf(address(this));
    }

    /**
     * @dev Transfer ERC20 asset
     * @param _assetAddress - Asset
     * @param _recipient - Recipient
     * @param _amount - Amount to be transferred
     * @notice USE NATIVE TOKEN DECIMAL PLACES
     * @return True if success
     */
    function transferAsset(
        address _assetAddress,
        address _recipient,
        uint256 _amount
    ) public onlyAdmin returns (bool) {
        require(_recipient != address(0), "Invalid address");
        IERC20 tupa = IERC20(_assetAddress);
        require(
            tupa.balanceOf(address(this)) >= _amount,
            "Insufficient balance"
        );
        return tupa.transfer(_recipient, _amount);
    }
    
    /**
     * @dev Approve ERC20 asset
     * @param _assetAddress - Asset
     * @param _spender - External spender
     * @param _amount - Amount to be transferred
     * @notice USE NATIVE TOKEN DECIMAL PLACES
     * @return True if success
     */
    function approveAsset(
        address _assetAddress,
        address _spender,
        uint256 _amount
    ) public onlyAdmin returns (bool) {
        require(_spender != address(0), "Invalid address");
        IERC20 tupa = IERC20(_assetAddress);
        require(
            tupa.balanceOf(address(this)) >= 0,
            "Insufficient balance"
        );
        require(tupa.approve(_spender, 0), "could not adjust spender to zero");
        return tupa.approve(_spender, _amount);
    }
    
    /**
     * @dev Withdraw Coin from the contract
     * @param _beneficiary - Destination
     * @param _amount - Amount
     * @return True if success
     */
    function withdrawCoin(address payable _beneficiary, uint256 _amount)
        public
        onlyAdmin
        returns (bool)
    {
        require(
            address(this).balance >= _amount,
            "There is not enough balance"
        );
        (bool success, ) = _beneficiary.call{value: _amount}("");
        require(success, "Transfer failed.");
        return success;
    }
    
    /**
     * @dev Receive
     * Emits an event on blockchain coin received
     */
    receive() external payable {
        emit CoinReceived(msg.sender, msg.value);
    }

    /**
     * @dev Are transfers currently disallowed
     * @return True if disallowed
     */
    function isLocked() public view returns (bool) {
        return lockedUntilBlock > block.number;
    }

    /**
     * @dev Checks if transfer parameters are valid
     * @param _from Source address
     * @param _to Destination address
     * @param _amount Amount to check
     * @return True if valid
     */
    function isTransferValid(address _from, address _to, uint256 _amount)
        public
        view
        returns (bool)
    {
        if (_from == address(0)) {
            return false;
        }

        if (_to == address(0)) {
            return false;
        }

        if (!hasWhiteList) {
            return balances[_from] >= _amount; // sufficient balance
        }

        bool fromOK = clearedInvestors[_from].exists;

        if (!isSyndicate) {
            return
                balances[_from] >= _amount && // sufficient balance
                fromOK; // a seller holder within the whitelist
        }

        bool toOK = clearedInvestors[_to].exists;

        return
            balances[_from] >= _amount && // sufficient balance
            fromOK && // a seller holder within the whitelist
            toOK; // a buyer holder within the whitelist
    }
}


contract TupaWallet {
    mapping(address => bool) public controllers;
    address[] public controllerList;
    bytes32 public recipientID;
    string public recipient;

    modifier onlyController() {
        require(controllers[msg.sender], "Sender must be a Controller Member");
        _;
    }

    event EtherReceived(address sender, uint256 amount);

    /**
     * @dev Constructor
     * @param _controller - Controller of the new wallet
     * @param recipientExternalID - The Recipient ID (managed externally)
     */
    constructor(address _controller, string memory recipientExternalID)  {
        require(_controller != address(0), "Invalid address of controller 1");
        controllers[_controller] = true;
        controllerList.push(_controller);
        recipientID = keccak256(abi.encodePacked(recipientExternalID));
        recipient = recipientExternalID;
    }

    /**
     * @dev Getter for the total number of controllers
     * @return Total number of controllers
     */
    function getTotalControllers() public view returns (uint256) {
        return controllerList.length;
    }

    /**
     * @dev Adds a new Controller
     * @param _controller - Controller to be added
     * @return True if success
     */
    function newController(address _controller)
        public
        onlyController
        returns (bool)
    {
        require(!controllers[_controller], "Already a controller");
        require(_controller != address(0), "Invalid Controller address");
        require(
            msg.sender != _controller,
            "The sender cannot vote to include himself"
        );
        controllers[_controller] = true;
        controllerList.push(_controller);
        return true;
    }

    /**
     * @dev Deletes a Controller
     * @param _controller - Controller to be deleted
     * @return True if success
     */
    function deleteController(address _controller)
        public
        onlyController
        returns (bool)
    {
        require(_controller != address(0), "Invalid Controller address");
        require(
            controllerList.length > 1,
            "Cannot leave the wallet without a controller"
        );
        delete (controllers[_controller]);
        for (uint256 i = 0; i < controllerList.length; i++) {
            if (controllerList[i] == _controller) {
                controllerList[i] = controllerList[controllerList.length - 1];
                delete controllerList[controllerList.length - 1];
                controllerList.pop();
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Getter for the wallet balance for a given asset
     * @param _assetAddress - Asset to check balance
     * @return Balance
     */
    function getBalance(address _assetAddress) public view returns (uint256) {
        IERC20 tupa2 = IERC20(_assetAddress);
        return tupa2.balanceOf(address(this));
    }

    /**
     * @dev Transfer and ERC20 asset
     * @param _assetAddress - Asset
     * @param _recipient - Recipient
     * @param _amount - Amount to be transferred
     * @notice USE NATIVE TOKEN DECIMAL PLACES
     * @return True if success
     */
    function transfer(
        address _assetAddress,
        address _recipient,
        uint256 _amount
    ) public onlyController returns (bool) {
        require(_recipient != address(0), "Invalid address");
        IERC20 tupa = IERC20(_assetAddress);
        require(
            tupa.balanceOf(address(this)) >= _amount,
            "Insufficient balance"
        );
        return tupa.transfer(_recipient, _amount);
    }

    /**
     * @dev Getter for the Recipient
     * @return Recipient (string converted)
     */
    function getRecipient() public view returns (string memory) {
        return recipient;
    }

    /**
     * @dev Getter for the Recipient ID
     * @return Recipient (bytes32)
     */
    function getRecipientID() external view returns (bytes32) {
        return recipientID;
    }

    /**
     * @dev Change the recipient of the wallet
     * @param recipientExternalID - Recipient ID
     * @return True if success
     */
    function changeRecipient(string memory recipientExternalID)
        public
        onlyController
        returns (bool)
    {
        recipientID = keccak256(abi.encodePacked(recipientExternalID));
        recipient = recipientExternalID;
        return true;
    }

    /**
     * @dev Receive
     * Emits an event on ether received
     */
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /**
     * @dev Withdraw Ether from the contract
     * @param _beneficiary - Destination
     * @param _amount - Amount
     * @return True if success
     */
    function withdrawEther(address payable _beneficiary, uint256 _amount)
        public
        onlyController
        returns (bool)
    {
        require(
            address(this).balance >= _amount,
            "There is not enough balance"
        );
        (bool success, ) = _beneficiary.call{value: _amount}("");
        require(success, "Transfer failed.");
        return success;
    }

    function isController(address _checkAddress) external view returns (bool) {
        return controllers[_checkAddress];
    }
}


/**
 * @dev Wallet Factory
 */
contract TupaWalletFactory {
    struct Wallet {
        string recipientID;
        address walletAddress;
        address controller;
    }

    Wallet[] public wallets;
    mapping(string => Wallet) public walletsIDMap;

    event NewWalletCreated(
        address walletAddress,
        address indexed controller,
        string recipientExternalID
    );

    /**
     * @dev Creates a new wallet
     * @param _controller - Controller of the new wallet
     * @param recipientExternalID - The Recipient ID (managed externally)
     * @return true if success
     */
    function CreateWallet(
        address _controller,
        string memory recipientExternalID
    ) public returns (bool) {
        Wallet storage wallet = walletsIDMap[recipientExternalID];
        require(wallet.walletAddress == address(0x0), "WalletFactory: cannot associate same recipientExternalID twice.");

        TupaWallet newWallet = new TupaWallet(
            _controller,
            recipientExternalID
        );

        wallet.walletAddress = address(newWallet);
        wallet.controller = _controller;
        wallet.recipientID = recipientExternalID;

        wallets.push(wallet);
        walletsIDMap[recipientExternalID] = wallet;

        emit NewWalletCreated(
            address(newWallet),
            _controller,
            recipientExternalID
        );

        return true;
    }

    /**
     * @dev Total Wallets ever created
     * @return the total wallets ever created
     */
    function getTotalWalletsCreated() public view returns (uint256) {
        return wallets.length;
    }

    /**
     * @dev Wallet getter
     * @param recipientID recipient ID
     * @return Wallet (for frontend use)
     */
    function getWallet(string calldata recipientID)
        external
        view
        returns (Wallet memory)
    {
        require(
            walletsIDMap[recipientID].walletAddress != address(0x0),
            "invalid wallet"
        );
        return walletsIDMap[recipientID];
    }
}


/**
 * @title TupaActions is a contract that generates tokens that represents a investment fund
 */
contract TupaActions {
    struct FundTokenContract {
        address fundManager;
        address fundContractAddress;
        string fundTokenSymbol;
        bool exists;
    }

    FundTokenContract[] public contracts;
    mapping(address => FundTokenContract) public contractsMap;

    event NewFundCreated(
        address indexed fundManager,
        address indexed tokenAddress,
        string indexed tokenSymbol
    );

    /**
     * @dev Creates a new token
     * @param _fundAdmin - Admin
     * @param _fundBoard - Board
     * @param _tokenName - Detailed ERC20 token name
     * @param _decimalUnits - Detailed ERC20 decimal units
     * @param _tokenSymbol - Detailed ERC20 token symbol
     * @param _lockedUntilBlock - Block lock
     * @param _newTotalSupply - Total Supply owned by the contract itself, only Manager can move
     * @param _mintable - True allows Manager to min new tokens
     * @param _hasWhiteList - Allows transfering only between whitelisted addresses
     * @param _isSyndicate - Allows secondary market
     * @return newFundTokenAddress the address of the newly created token
     */
    function newElement(
        address _fundAdmin,
        address _fundBoard,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol,
        uint256 _lockedUntilBlock,
        uint256 _newTotalSupply,
        bool _mintable, //  ---> Usar aqui _canMintNewTokens
        bool _hasWhiteList,
        bool _isSyndicate
    ) public returns (address newFundTokenAddress) {
        TupaAsset ft = new TupaAsset(
            _fundAdmin,
            _fundBoard,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _lockedUntilBlock,
            _newTotalSupply,
            _mintable,
            _hasWhiteList,
            _isSyndicate
        );
        newFundTokenAddress = address(ft);
        FundTokenContract memory ftc = FundTokenContract(
            _fundAdmin,
            newFundTokenAddress,
            _tokenSymbol,
            true
        );
        contracts.push(ftc);
        contractsMap[ftc.fundContractAddress] = ftc;
        emit NewFundCreated(_fundAdmin, newFundTokenAddress, _tokenSymbol);
        return newFundTokenAddress;
    }

    /**
     * @return Total number of funds created
     */
    function totalContractsGenerated() public view returns (uint256) {
        return contracts.length;
    }
}