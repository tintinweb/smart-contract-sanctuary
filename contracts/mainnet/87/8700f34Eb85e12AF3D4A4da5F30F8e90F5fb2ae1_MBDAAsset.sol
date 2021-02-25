/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

pragma solidity 0.6.6;
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


/**
 * @title MBDAAsset is a template for MB Digital Asset token
 * */
contract MBDAAsset {
    using SafeMath for uint256;

    //
    // events
    //
    // ERC20 events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // mint/burn events
    event Mint(address indexed _to, uint256 _amount, uint256 _newTotalSupply);
    event Burn(address indexed _from, uint256 _amount, uint256 _newTotalSupply);

    // admin events
    event BlockLockSet(uint256 _value);
    event NewAdmin(address _newAdmin);
    event NewManager(address _newManager);
    event NewInvestor(address _newInvestor);
    event RemovedInvestor(address _investor);
    event FundAssetsChanged(
        string indexed tokenSymbol,
        string assetInfo,
        uint8 amount,
        uint256 totalAssetAmount
    );

    modifier onlyAdmin {
        require(msg.sender == admin, "Only admin can perform this operation");
        _;
    }

    modifier managerOrAdmin {
        require(
            msg.sender == manager || msg.sender == admin,
            "Only manager or admin can perform this operation"
        );
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

    struct Asset {
        string assetTicker;
        string assetInfo;
        uint8 assetPercentageParticipation;
    }

    struct Investor {
        string info;
        bool exists;
    }

    uint256 public totalSupply;
    string public name;
    uint8 public decimals;
    string public symbol;
    address public admin;
    address public board;
    address public manager;
    uint256 public lockedUntilBlock;
    bool public canChangeAssets;
    bool public mintable;
    bool public hasWhiteList;
    bool public isSyndicate;
    string public urlFinancialDetailsDocument;
    bytes32 public financialDetailsHash;
    string[] public tradingPlatforms;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => Investor) public clearedInvestors;
    Asset[] public assets;

    /**
     * @dev Constructor
     * @param _fundAdmin - Fund admin
     * @param _fundBoard - Board
     * @param _tokenName - Detailed ERC20 token name
     * @param _decimalUnits - Detailed ERC20 decimal units
     * @param _tokenSymbol - Detailed ERC20 token symbol
     * @param _lockedUntilBlock - Block lock
     * @param _newTotalSupply - Total Supply owned by the contract itself, only Manager can move
     * @param _canChangeAssets - True allows the Manager to change assets in the portfolio
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
        bool _canChangeAssets,
        bool _mintable,
        bool _hasWhiteList,
        bool _isSyndicate
    ) public {
        name = _tokenName;
        require(_decimalUnits <= 18, "Decimal units should be 18 or lower");
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
        lockedUntilBlock = _lockedUntilBlock;
        admin = _fundAdmin;
        board = _fundBoard;
        totalSupply = _newTotalSupply;
        canChangeAssets = _canChangeAssets;
        mintable = _mintable;
        hasWhiteList = _hasWhiteList;
        isSyndicate = _isSyndicate;
        balances[address(this)] = totalSupply;
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
     * @dev Add trading platform
     * @param _details - Details of the trading platform
     * @return True if success
     */
    function addTradingPlatform(string memory _details)
        public
        onlyAdmin
        returns (bool)
    {
        tradingPlatforms.push(_details);
        return true;
    }

    /**
     * @dev Remove trading platform
     * @param _index - Index of the trading platform to be removed
     * @return True if success
     */
    function removeTradingPlatform(uint256 _index)
        public
        onlyAdmin
        returns (bool)
    {
        require(_index < tradingPlatforms.length, "Invalid platform index");
        tradingPlatforms[_index] = tradingPlatforms[tradingPlatforms.length -
            1];
        tradingPlatforms.pop();
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
     * @dev Add new asset to Portfolio
     * @param _assetTicker - Ticker
     * @param _assetInfo - Info
     * @param _assetPercentageParticipation - % of portfolio taken by the asset
     * @return success
     */
    function addNewAsset(
        string memory _assetTicker,
        string memory _assetInfo,
        uint8 _assetPercentageParticipation
    ) public onlyAdmin returns (bool success) {
        uint256 totalPercentageAssets = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            require(
                keccak256(bytes(_assetTicker)) !=
                    keccak256(bytes(assets[i].assetTicker)),
                "An asset cannot be assigned twice"
            );
            totalPercentageAssets = SafeMath.add(
                assets[i].assetPercentageParticipation,
                totalPercentageAssets
            );
        }
        totalPercentageAssets = SafeMath.add(
            totalPercentageAssets,
            _assetPercentageParticipation
        );
        require(
            totalPercentageAssets <= 100,
            "Total assets number cannot be higher than 100"
        );
        emit FundAssetsChanged(
            _assetTicker,
            _assetInfo,
            _assetPercentageParticipation,
            totalPercentageAssets
        );
        Asset memory newAsset = Asset(
            _assetTicker,
            _assetInfo,
            _assetPercentageParticipation
        );
        assets.push(newAsset);
        success = true;
        return success;
    }

    /**
     * @dev Remove asset from Portfolio
     * @param _assetIndex - Asset
     * @return True if success
     */
    function removeAnAsset(uint8 _assetIndex) public onlyAdmin returns (bool) {
        require(canChangeAssets, "Cannot change asset portfolio");
        require(
            _assetIndex < assets.length,
            "Invalid asset index number. Greater than total assets"
        );
        string memory assetTicker = assets[_assetIndex].assetTicker;
        assets[_assetIndex] = assets[assets.length - 1];
        delete assets[assets.length - 1];
        assets.pop();
        emit FundAssetsChanged(assetTicker, "", 0, 0);
        return true;
    }

    /**
     * @dev Updates an asset
     * @param _assetTicker - Ticker
     * @param _assetInfo - Info to update
     * @param _newAmount - % of portfolio taken by the asset
     * @return True if success
     */
    function updateAnAssetQuantity(
        string memory _assetTicker,
        string memory _assetInfo,
        uint8 _newAmount
    ) public onlyAdmin returns (bool) {
        require(canChangeAssets, "Cannot change asset amount");
        require(_newAmount > 0, "Cannot set zero asset amount");
        uint256 totalAssets = 0;
        uint256 assetIndex = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            if (
                keccak256(bytes(_assetTicker)) ==
                keccak256(bytes(assets[i].assetTicker))
            ) {
                assetIndex = i;
                totalAssets = SafeMath.add(totalAssets, _newAmount);
            } else {
                totalAssets = SafeMath.add(
                    totalAssets,
                    assets[i].assetPercentageParticipation
                );
            }
        }
        emit FundAssetsChanged(
            _assetTicker,
            _assetInfo,
            _newAmount,
            totalAssets
        );
        require(
            totalAssets <= 100,
            "Fund assets total percentage must be less than 100"
        );
        assets[assetIndex].assetPercentageParticipation = _newAmount;
        assets[assetIndex].assetInfo = _assetInfo;
        return true;
    }

    /**
     * @return Number of assets in Portfolio
     */
    function totalAssetsArray() public view returns (uint256) {
        return assets.length;
    }

    /**
     * @dev ERC20 Transfer
     * @param _to - destination address
     * @param _value - value to transfer
     * @return True if success
     */
    function transfer(address _to, uint256 _value)
        public
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
        managerOrAdmin
        blockLock(msg.sender)
        returns (bool)
    {
        balances[_to] = balances[_to].add(_value);
        totalSupply = totalSupply.add(_value);

        emit Mint(_to, _value, totalSupply);
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
        managerOrAdmin
        returns (bool)
    {
        require(_account != address(0), "ERC20: burn from the zero address");

        totalSupply = totalSupply.sub(_value);
        balances[_account] = balances[_account].sub(_value);
        emit Transfer(_account, address(0), _value);
        emit Burn(_account, _value, totalSupply);
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
     * @dev Set an account can perform some operations
     * @param _newManager Manager address
     * @return True if success
     */
    function setManager(address _newManager) public onlyAdmin returns (bool) {
        manager = _newManager;
        emit NewManager(_newManager);
        return true;
    }

    /**
     * @dev ERC20 balanceOf
     * @param _owner Owner address
     * @return True if success
     */
    function balanceOf(address _owner) public view returns (uint256) {
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
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
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


contract MBDAWallet {
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
    constructor(address _controller, string memory recipientExternalID) public {
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
        MBDAAsset mbda2 = MBDAAsset(_assetAddress);
        return mbda2.balanceOf(address(this));
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
        MBDAAsset mbda = MBDAAsset(_assetAddress);
        require(
            mbda.balanceOf(address(this)) >= _amount,
            "Insufficient balance"
        );
        return mbda.transfer(_recipient, _amount);
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
contract MBDAWalletFactory {
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

        MBDAWallet newWallet = new MBDAWallet(
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
 * @title MBDAManager is a contract that generates tokens that represents a investment fund units and manages them
 */
contract MBDAManager {
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
     * @dev Creates a new fund token
     * @param _fundManager - Manager
     * @param _fundChairman - Chairman
     * @param _tokenName - Detailed ERC20 token name
     * @param _decimalUnits - Detailed ERC20 decimal units
     * @param _tokenSymbol - Detailed ERC20 token symbol
     * @param _lockedUntilBlock - Block lock
     * @param _newTotalSupply - Total Supply owned by the contract itself, only Manager can move
     * @param _canChangeAssets - True allows the Manager to change assets in the portfolio
     * @param _mintable - True allows Manager to min new tokens
     * @param _hasWhiteList - Allows transfering only between whitelisted addresses
     * @param _isSyndicate - Allows secondary market
     * @return newFundTokenAddress the address of the newly created token
     */
    function newFund(
        address _fundManager,
        address _fundChairman,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol,
        uint256 _lockedUntilBlock,
        uint256 _newTotalSupply,
        bool _canChangeAssets,    //  ---> Deixar tudo _canChangeAssets
        bool _mintable, //  ---> Usar aqui _canMintNewTokens
        bool _hasWhiteList,
        bool _isSyndicate
    ) public returns (address newFundTokenAddress) {
        MBDAAsset ft = new MBDAAsset(
            _fundManager,
            _fundChairman,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _lockedUntilBlock,
            _newTotalSupply,
            _canChangeAssets,
            _mintable,
            _hasWhiteList,
            _isSyndicate
        );
        newFundTokenAddress = address(ft);
        FundTokenContract memory ftc = FundTokenContract(
            _fundManager,
            newFundTokenAddress,
            _tokenSymbol,
            true
        );
        contracts.push(ftc);
        contractsMap[ftc.fundContractAddress] = ftc;
        emit NewFundCreated(_fundManager, newFundTokenAddress, _tokenSymbol);
        return newFundTokenAddress;
    }

    /**
     * @return Total number of funds created
     */
    function totalContractsGenerated() public view returns (uint256) {
        return contracts.length;
    }
}


/**
 * @title MbdaBoard is the smart contract that will control all funds
 * */
contract MbdaBoard {
    uint256 public minVotes; //minimum number of votes to execute a proposal

    mapping(address => bool) public boardMembers; //board members
    address[] public boardMembersList; // array with member addresses

    /// @dev types of proposal allowed they are Solidity function signatures (bytes4) default ones are added on deploy later more can be added through a proposal
    mapping(string => bytes4) public proposalTypes;
    uint256 public totalProposals;

    /// @notice proposal Struct
    struct Proposal {
        string proposalType;
        address payable destination;
        uint256 value;
        uint8 votes;
        bool executed;
        bool exists;
        bytes proposal; /// @dev ABI encoded parameters for the function of the proposal type
        bool success;
        bytes returnData;
        mapping(address => bool) voters;
    }

    mapping(uint256 => Proposal) public proposals;

    /// @dev restricts calls to board members
    modifier onlyBoardMember() {
        require(boardMembers[msg.sender], "Sender must be a Board Member");
        _;
    }

    /// @dev restricts calls to the board itself (these can only be called from a voted proposal)
    modifier onlyBoard() {
        require(msg.sender == address(this), "Sender must the Board");
        _;
    }

    /// @dev Events
    event NewProposal(
        uint256 proposalID,
        string indexed proposalType,
        bytes proposalPayload
    );
    event Voted(address boardMember, uint256 proposalId);
    event ProposalApprovedAndEnforced(
        uint256 proposalID,
        bytes payload,
        bool success,
        bytes returnData
    );
    event Deposit(uint256 value);

    /**
     * @dev Constructor
     * @param _initialMembers - Initial board's members
     * @param _minVotes - minimum votes to approve a proposal
     * @param _proposalTypes - Proposal types to add upon deployment
     * @param _ProposalTypeDescriptions - Description of the proposal types
     */
    constructor(
        address[] memory _initialMembers,
        uint256 _minVotes,
        bytes4[] memory _proposalTypes,
        string[] memory _ProposalTypeDescriptions
    ) public {
        require(_minVotes > 0, "Should require at least 1 vote");
        require(
            _initialMembers.length >= _minVotes,
            "Member list length must be equal or higher than minVotes"
        );
        for (uint256 i = 0; i < _initialMembers.length; i++) {
            require(
                !boardMembers[_initialMembers[i]],
                "Duplicate Board Member sent"
            );
            boardMembersList.push(_initialMembers[i]);
            boardMembers[_initialMembers[i]] = true;
        }
        minVotes = _minVotes;

        // setting up default proposalTypes (board management txs)
        proposalTypes["addProposalType"] = 0xeaa0dff1;
        proposalTypes["removeProposalType"] = 0x746d26b5;
        proposalTypes["changeMinVotes"] = 0x9bad192a;
        proposalTypes["addBoardMember"] = 0x1eac03ae;
        proposalTypes["removeBoardMember"] = 0x39a169f9;
        proposalTypes["replaceBoardMember"] = 0xbec44b4f;

        // setting up user provided approved proposalTypes
        if (_proposalTypes.length > 0) {
            require(
                _proposalTypes.length == _ProposalTypeDescriptions.length,
                "Proposal types and descriptions do not match"
            );
            for (uint256 i = 0; i < _proposalTypes.length; i++)
                proposalTypes[_ProposalTypeDescriptions[i]] = _proposalTypes[i];
        }
    }

    /**
     * @dev Adds a proposal and vote on it (onlyMember)
     * @notice every proposal is a transaction to be executed by the board transaction type of proposal have to be previously approved (function sig)
     * @param _type - proposal type
     * @param _data - proposal data (ABI encoded)
     * @param _destination - address to send the transaction to
     * @param _value - value of the transaction
     * @return proposalID The ID of the proposal
     */
    function addProposal(
        string memory _type,
        bytes memory _data,
        address payable _destination,
        uint256 _value
    ) public onlyBoardMember returns (uint256 proposalID) {
        require(proposalTypes[_type] != bytes4(0x0), "Invalid proposal type");
        totalProposals++;
        proposalID = totalProposals;

        Proposal memory prop = Proposal(
            _type,
            _destination,
            _value,
            0,
            false,
            true,
            _data,
            false,
            bytes("")
        );
        proposals[proposalID] = prop;
        emit NewProposal(proposalID, _type, _data);

        // proposer automatically votes
        require(vote(proposalID), "Voting on the new proposal failed");
        return proposalID;
    }

    /**
     * @dev Vote on a given proposal (onlyMember)
     * @param _proposalID - Proposal ID
     * @return True if success
     */
    function vote(uint256 _proposalID) public onlyBoardMember returns (bool) {
        require(proposals[_proposalID].exists, "The proposal is not found");
        require(
            !proposals[_proposalID].voters[msg.sender],
            "This board member has voted already"
        );
        require(
            !proposals[_proposalID].executed,
            "This proposal has been approved and enforced"
        );

        proposals[_proposalID].votes++;
        proposals[_proposalID].voters[msg.sender] = true;
        emit Voted(msg.sender, _proposalID);

        if (proposals[_proposalID].votes >= minVotes)
            executeProposal(_proposalID);

        return true;
    }

    /**
     * @dev Executes a proposal (internal)
     * @param _proposalID - Proposal ID
     */
    function executeProposal(uint256 _proposalID) internal {
        Proposal memory prop = proposals[_proposalID];
        bytes memory payload = abi.encodePacked(
            proposalTypes[prop.proposalType],
            prop.proposal
        );
        proposals[_proposalID].executed = true;
        (bool success, bytes memory returnData) = prop.destination.call{value: prop.value}(payload);
        proposals[_proposalID].success = success;
        proposals[_proposalID].returnData = returnData;
        emit ProposalApprovedAndEnforced(
            _proposalID,
            payload,
            success,
            returnData
        );
    }

    /**
     * @dev Adds a proposal type (onlyBoard)
     * @param _id - The name of the proposal Type
     * @param _signature - 4 byte signature of the function to be called
     * @return True if success
     */
    function addProposalType(string memory _id, bytes4 _signature)
        public
        onlyBoard
        returns (bool)
    {
        proposalTypes[_id] = _signature;
        return true;
    }

    /**
     * @dev Removes a proposal type (onlyBoard)
     * @param _id - The name of the proposal Type
     * @return True if success
     */
    function removeProposalType(string memory _id)
        public
        onlyBoard
        returns (bool)
    {
        proposalTypes[_id] = bytes4("");
        return true;
    }

    /**
     * @dev Changes the amount of votes needed to approve a proposal (onlyBoard)
     * @param _minVotes - New minimum quorum to approve proposals
     * @return True if success
     */
    function changeMinVotes(uint256 _minVotes) public onlyBoard returns (bool) {
        require(_minVotes > 0, "MinVotes cannot be less than 0");
        require(
            _minVotes <= boardMembersList.length,
            "MinVotes lower than number of members"
        );
        minVotes = _minVotes;
        return true;
    }

    /**
     * @dev Adds a board member (onlyBoard)
     * @param _newMember - New member to be added
     * @return True if success
     */
    function addBoardMember(address _newMember)
        public
        onlyBoard
        returns (bool)
    {
        require(!boardMembers[_newMember], "Duplicate Board Member sent");
        boardMembersList.push(_newMember);
        boardMembers[_newMember] = true;
        if (boardMembersList.length > 1 && minVotes == 0) {
            minVotes = 1;
        }
        return true;
    }

    /**
     * @dev Removes a board member (onlyBoard)
     * @param _member - Member to be added
     * @return True if success
     */
    function removeBoardMember(address _member)
        public
        onlyBoard
        returns (bool)
    {
        boardMembers[_member] = false;
        for (uint256 i = 0; i < boardMembersList.length; i++) {
            if (boardMembersList[i] == _member) {
                boardMembersList[i] = boardMembersList[boardMembersList.length -
                    1];
                boardMembersList.pop();
            }
        }
        if (boardMembersList.length < minVotes) {
            minVotes = boardMembersList.length;
        }
        return true;
    }

    /**
     * @dev Replaces a board member (onlyBoard)
     * @param _oldMember - Old member to be replaced
     * @param _newMember - New member to be added
     * @return True if success
     */
    function replaceBoardMember(address _oldMember, address _newMember)
        public
        onlyBoard
        returns (bool)
    {
        require(removeBoardMember(_oldMember), "Failed to remove old member");
        return addBoardMember(_newMember);
    }

    /**
     * @dev Receive
     */
    receive() external payable {
        emit Deposit(msg.value);
    }
}