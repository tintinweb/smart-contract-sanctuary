/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

/**
 *Submitted for verification at polygonscan.com on 2021-09-01
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
 * @title TupaAsset is a template for Asset token
 * */
contract TupaAsset {
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