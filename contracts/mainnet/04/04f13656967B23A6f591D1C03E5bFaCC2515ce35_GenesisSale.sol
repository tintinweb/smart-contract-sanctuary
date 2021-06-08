// SPDX-License-Identifier: NO-LICENSE

pragma solidity ^0.8.4;

import "./utils/Context.sol";
import "./security/ReentrancyGuard.sol";
import "./interfaces/IGenesisSale.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWhitelist.sol";
import "./interfaces/AggregatorV3Interface.sol";

/**
 * Implementation of the {IGenesisSale} Interface.
 *
 * Used for the sale of EDGEX tokens at a constant price
 * with a lock tenure of 365 days.
 *
 * 2 Level Governance Model with admin and governor previlages.
 *
 * Token Price is stored as 8 precision variables.
 */

contract GenesisSale is ReentrancyGuard, Context, IGenesisSale {
    mapping(address => uint256) public allocated;
    mapping(address => uint256) public purchases;
    mapping(address => mapping(uint256 => Purchase)) public purchase;
    mapping(uint8 => uint256) public poolCap;
    mapping(uint8 => uint256) public poolSold;
    mapping(uint8 => uint256) public poolLock;
    mapping(address => uint256) public balanceOf;

    address public organisation;
    address payable public ethWallet;
    address public governor;
    address public admin;

    address public edgexContract;
    address public ethPriceSource;
    address public whitelistOracle;

    uint256 public presalePrice;

    uint256 public maxCap;
    uint256 public minCap;

    /**
     * @dev stores the sale history as individual structs.
     *
     * Mapped to an account with individual identifier.
     */
    struct Purchase {
        uint256 time;
        uint256 amount;
        uint256 price;
        uint256 lock;
        uint8 method;
        bool isSettled;
    }

    /**
     * @dev Emitted when there is a purchase of EDGEX tokens.
     *
     * Can be used for storing off-chain history events.
     */
    event PurchaseEvent(address indexed to, uint256 amount);

    /**
     * @dev Emitted when the governor role state changes.
     *
     * Based on the event we can predict the role of governor.
     */
    event UpdateGovernor(address indexed _governor);

    /**
     * @dev Emittee when the ownership of the contract changes.
     */
    event RevokeOwnership(address indexed _newOwner);

    /**
     * @dev Emitted when the pool parameters changes.
     */
    event PoolCapChange(uint256 newCap, uint8 poolId);

    /**
     * @dev Emitted when the pool lock duration changes.
     */
    event PoolLockChange(uint256 lockTime, uint8 poolId);

    /**
     * @dev sets the initial params.
     *
     * {_ethWallet} - Address to which the funds are directed to.
     * {_organisation} - Address to which % of sale tokens are sent to.
     * {_governor} - Address to be configured in the server for off-chain settlement.
     * {_admin} - Owner of this contract.
     * {_ethSource} - Chainlink ETH/USD price source.
     * {_whitelistOracle} - Oracle to fetch whitelisting info from.
     * {_edgexContract} - Address of the EDGEX token.
     * {_presalePrice} - Price of Each EDGEX token (8 precision).
     */
    constructor(
        address _ethWallet,
        address _organisation,
        address _governor,
        address _admin,
        address _ethSource,
        address _whitelistOracle,
        address _edgexContract,
        uint256 _presalePrice
    ) {
        organisation = _organisation;
        ethWallet = payable(_ethWallet);
        governor = _governor;
        whitelistOracle = _whitelistOracle;
        admin = _admin;
        edgexContract = _edgexContract;
        ethPriceSource = _ethSource;
        presalePrice = _presalePrice;
    }

    /**
     * @dev sanity checks the caller.
     * If the caller is not admin, the transaction is reverted.
     *
     * keeps the security of the platform and prevents bad actors
     * from executing sensitive functions / state changes.
     */
    modifier onlyAdmin() {
        require(_msgSender() == admin, "Error: caller not admin");
        _;
    }

    /**
     * @dev sanity checks the caller.
     * If the caller is not governor, the transaction is reverted.
     *
     * keeps the security of the platform and prevents bad actors
     * from executing sensitive functions / state changes.
     */
    modifier onlyGovernor() {
        require(_msgSender() == governor, "Error: caller not Governor");
        _;
    }

    /**
     * @dev checks whether the address is a valid one.
     *
     * If it's a zero address returns an error.
     */
    modifier isZero(address _address) {
        require(_address != address(0), "Error: zero address");
        _;
    }

    /**
     * @dev checks whether the `_user` is whitelisted and verified his KYC.
     *
     * Requirements:
     * `_user` cannot be a zero address,
     *
     * Proxies calls to the whitelist contract address.
     */
    function isWhitelisted(address _user) public view virtual returns (bool) {
        require(_user != address(0), "Error: zero address cannot buy");
        return IWhiteList(whitelistOracle).whitelisted(_user);
    }

    /**
     * @dev sends in `eth` in the transaction as `value`
     *
     * The function calculates the price of the ETH send
     * in value to equivalent amount in USD using chainlink
     * oracle and transfer the equivalent amount of tokens back to the user.
     *
     * Requirements:
     * `_reciever` address has to be whitelisted.
     */
    function buyEdgex(address _reciever, uint8 poolId)
        public
        payable
        virtual
        override
        nonReentrant
        returns (bool)
    {
        uint256 tokens = calculate(msg.value);

        require(tokens >= minCap, "Error: amount less than minimum");
        require(tokens <= maxCap, "Error: amount greater than maximum");

        require(poolCap[poolId] >= poolSold[poolId] + tokens, "Error: pool cap reached");
        require(    
            isWhitelisted(_reciever),
            "Error: account not elligible to puchase"
        );

        purchases[_reciever] += 1;
        balanceOf[_reciever] += tokens;

        Purchase storage p = purchase[_reciever][purchases[_reciever]];
        p.time = block.timestamp;
        p.lock = poolLock[poolId];
        p.method = 1;
        p.price = presalePrice;
        p.amount = tokens;

        poolSold[poolId] += tokens;

        ethWallet.transfer(msg.value);
    
        emit PurchaseEvent(_reciever, tokens);
        return true;
    }

    /**
     * @dev returns the amount of EDGEX tokens
     * for the input eth value.
     *
     * EDGEX tokens are returned in 18-decimal precision.
     */

    function calculate(uint256 _amount) private view returns (uint256) {
        require(_amount > 0, "Error: amount should not be zero");
        uint256 value = uint256(fetchEthPrice());
        value = _amount * value;
        uint256 tokens = value / presalePrice;
        return tokens;
    }

    function allocate(
        uint256 _tokens,
        address _user,
        uint8 _method,
        uint8 _poolId
    ) public virtual override onlyGovernor nonReentrant returns (bool) {
        require(_tokens >= minCap, "Error: amount less than minimum");
        require(_tokens <= maxCap, "Error: amount greater than maximum");

        require(
            isWhitelisted(_user),
            "Error: account not elligible to puchase"
        );

        require(
            poolCap[_poolId] >= poolSold[_poolId] + _tokens, 
            "Error: pool cap reached"
        );

        purchases[_user] += 1;
        balanceOf[_user] += _tokens;

        Purchase storage p = purchase[_user][purchases[_user]];
        p.time = block.timestamp;
        p.lock = poolLock[_poolId];
        p.method = _method;
        p.price = presalePrice;
        p.amount = _tokens;

        poolSold[_poolId] += _tokens;

        emit PurchaseEvent(_user, _tokens);
        return true;
    }

    /**
     * @dev transfers the edgex tokens to the user's wallet after the
     * 365-day lock time.
     *
     * Requirements:
     * `caller` shoul have a valid token balance > 0;
     */
    function claim(uint256 _purchaseId)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        Purchase storage p = purchase[_msgSender()][_purchaseId];
        uint256 lockedTill = p.lock;
        uint256 orgAmount = p.amount / 100;
        balanceOf[_msgSender()] -= p.amount;

        require(!p.isSettled, "Error: amount already claimed");
        require(block.timestamp >= lockedTill, "Error: lock time till not yet reached");

        p.isSettled = true;
        bool status = IERC20(edgexContract).transfer(_msgSender(), p.amount);
        bool status2 = IERC20(edgexContract).transfer(organisation, orgAmount);

        return (status && status2);
    }

    /**
     * @dev transfer the control of genesis sale to another account.
     *
     * Onwers can add governors.
     *
     * Requirements:
     * `_newOwner` cannot be a zero address.
     *
     * CAUTION: EXECUTE THIS FUNCTION WITH CARE.
     */

    function revokeOwnership(address _newOwner)
        public
        virtual
        override
        onlyAdmin
        isZero(_newOwner)
        returns (bool)
    {
        admin = payable(_newOwner);
        emit RevokeOwnership(_newOwner);
        return true;
    }

    /**
     * @dev fetches the price of Ethereum from chainlink oracle
     *
     * Real-time onchain price is fetched.
     */

    function fetchEthPrice() public view virtual returns (int256) {
        (, int256 price, , , ) =
            AggregatorV3Interface(ethPriceSource).latestRoundData();
        return price;
    }

    /**
     * @dev can change the minimum and maximum purchase value of edgex tokens
     * per transaction.
     *
     * Requirements:
     * `_maxCap` can never be zero.
     *
     * `caller` should have governor role.
     */
    function updateCap(uint256 _minCap, uint256 _maxCap)
        public
        virtual
        override
        onlyGovernor
        returns (bool)
    {
        // solhint-ig
        require(_maxCap > 0, "Error: maximum amount cannot be zero");
        maxCap = _maxCap;
        minCap = _minCap;
        return false;
    }

    /**
     * @dev add an account with governor level previlages.
     *
     * Requirements:
     * `caller` should have admin role.
     * `_newGovernor` should not be a zero wallet.
     */
    function updateGovernor(address _newGovernor)
        public
        virtual
        override
        onlyGovernor
        isZero(_newGovernor)
        returns (bool)
    {
        governor = _newGovernor;

        emit UpdateGovernor(_newGovernor);
        return true;
    }

    /**
     * @dev can change the contract address of EDGEX tokens.
     *
     * Requirements:
     * `_contract` cannot be a zero address.
     */
    function updateContract(address _contract)
        public
        virtual
        override
        onlyAdmin
        isZero(_contract)
        returns (bool)
    {
        edgexContract = _contract;
        return true;
    }

    /**
     * @dev can change the Chainlink ETH Source.
     *
     * Requirements:
     * `_ethSource` cannot be a zero address.
     */
    function updateEthSource(address _ethSource)
        public
        virtual
        override
        onlyAdmin
        isZero(_ethSource)
        returns (bool)
    {
        ethPriceSource = _ethSource;
        return true;
    }

    /**
     * @dev can change the address to which all paybale ethers are sent to.
     *
     * Requirements:
     * `_caller` should be admin.
     * `_newEthSource` cannot be a zero address.
     */
    function updateEthWallet(address _newEthWallet)
        public
        virtual
        override
        onlyAdmin
        isZero(_newEthWallet)
        returns (bool)
    {
        ethWallet = payable(_newEthWallet);
        return true;
    }

    /**
     * @dev can change the address to which a part of sold tokens are paid to.
     *
     * Requirements:
     * `_caller` should be admin.
     * `_newOrgWallet` cannot be a zero address.
     */
    function updateOrgWallet(address _newOrgWallet)
        public
        virtual
        override
        onlyAdmin
        isZero(_newOrgWallet)
        returns (bool)
    {
        organisation = _newOrgWallet;
        return true;
    }

    /**
     * @dev can update the locktime for each poolId in number of days.
     *
     * Requirements:
     * `caller` should be admin.
     * `poolId` should be a valid one
     */
    function updatePoolLock(uint8 poolId, uint256 lockDays)
       public
       virtual
       override
       onlyAdmin
       returns (bool)
    {
       require(lockDays > 0, "Error: lock days cannot be zero");
       poolLock[poolId] = lockDays * 1 days;

       emit PoolLockChange(lockDays, poolId);
       return true;
    }

    /**
     * @dev can update the cap for each poolId in number of edgex tokens.
     *
     * Requirements:
     * `caller` should be admin.
     * `poolId` should be a valid one
     */
    function updatePoolCap(uint8 poolId, uint256 _poolCap)
        public 
        virtual 
        override
        onlyAdmin
        returns (bool) 
    {
        require(_poolCap > 0, "Error: cap cannot be zero");
        poolCap[poolId] = _poolCap;

        emit PoolCapChange(_poolCap, poolId);
        return true;
    }

    /**
     * @dev can allows admin to take out the unsold tokens from the smart contract.
     *
     * Requirements:
     * `_caller` should be admin.
     * `_to` cannot be a zero address.
     * `_amount` should be less than the current EDGEX token balance.
     *
     * Prevents the tokens from getting locked within the smart contract.
     */
    function drain(address _to, uint256 _amount)
        public
        virtual
        override
        onlyAdmin
        isZero(_to)
        returns (bool)
    {
        return IERC20(edgexContract).transfer(_to, _amount);
    }
}

// SPDX-License-Identifier: NO-LICENSE

pragma solidity ^0.8.4;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// SPDX-License-Identifier: NO-LICENSE

pragma solidity ^0.8.4;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: NO-LICENSE

pragma solidity ^0.8.4;

/**
 * @dev Interface of the Genesis Sale Smart Contract.
 *
 * Selling EDGEX tokens at a fixed price
 * with a 365-day lock period.
 */

interface IGenesisSale {
    /**
     * @dev sends in `eth` in the transaction as `value`
     *
     * The function calculates the price of the ETH send
     * in value to equivalent amount in USD using chainlink
     * oracle and transfer the equivalent amount of tokens back to the user.
     *
     * Requirements:
     * `_reciever` address has to be whitelisted.
     */
    function buyEdgex(address _reciever, uint8 poolId) external payable returns (bool);

    /**
     * @dev allocate the amount of tokens (`EDGEX`) to a specific account.
     *
     * Requirements:
     * `caller` should have governor role previlages.
     * `_user` should've to be whitelisted.
     *
     * Used for off-chain purchases with on-chain settlements.
     */
    function allocate(
        uint256 _tokens,
        address _user,
        uint8 _method,
        uint8 poolId
    ) external returns (bool);

    /**
     * @dev transfer the control of genesis sale to another account.
     *
     * Onwers can add governors.
     *
     * Requirements:
     * `_newOwner` cannot be a zero address.
     *
     * CAUTION: EXECUTE THIS FUNCTION WITH CARE.
     */
    function revokeOwnership(address _newOwner) external returns (bool);

    /**
     * @dev transfers the edgex tokens to the user's wallet after the
     * 365-day lock time.
     *
     * Requirements:
     * `caller` should have a valid token balance > 0;
     * `_purchaseId` should be valid.
     */
    function claim(uint256 _purchaseId) external returns (bool);

    /**
     * @dev can change the minimum and maximum purchase value of edgex tokens
     * per transaction.
     *
     * Requirements:
     *  `_maxCap` can never be zero.
     *
     * `caller` should have governor role.
     */
    function updateCap(uint256 _minCap, uint256 _maxCap)
        external
        returns (bool);

    /**
     * @dev add an account with governor level previlages.
     *
     * Requirements:
     * `caller` should have admin role.
     * `_newGovernor` should not be a zero wallet.
     */
    function updateGovernor(address _newGovernor) external returns (bool);

    /**
     * @dev can change the contract address of EDGEX tokens.
     *
     * Requirements:
     * `_contract` cannot be a zero address.
     */
    function updateContract(address _contract) external returns (bool);

    /**
     * @dev can change the Chainlink ETH Source.
     *
     * Requirements:
     * `_ethSource` cannot be a zero address.
     */
    function updateEthSource(address _ethSource) external returns (bool);

    /**
     * @dev can change the address to which all paybale ethers are sent to.
     *
     * Requirements:
     * `_caller` should be admin.
     * `_newEthSource` cannot be a zero address.
     */
    function updateEthWallet(address _newEthWallet) external returns (bool);

    /**
     * @dev can change the address to which a part of sold tokens are paid to.
     *
     * Requirements:
     * `_caller` should be admin.
     * `_newOrgWallet` cannot be a zero address.
     */
    function updateOrgWallet(address _newOrgWallet) external returns (bool);

    /**
     * @dev can update the locktime for each poolId in number of days.
     *
     * Requirements:
     * `caller` should be admin.
     * `poolId` should be a valid one
     */
    function updatePoolLock(uint8 poolId, uint256 lockDays) external returns (bool);

    /**
     * @dev can update the cap for each poolId in number of edgex tokens.
     *
     * Requirements:
     * `caller` should be admin.
     * `poolId` should be a valid one
     */
    function updatePoolCap(uint8 poolId, uint256 poolCap) external returns (bool);

    /**
     * @dev can allows admin to take out the unsold tokens from the smart contract.
     *
     * Requirements:
     * `_caller` should be admin.
     * `_to` cannot be a zero address.
     * `_amount` should be less than the current EDGEX token balance.
     *
     * Prevents the tokens from getting locked within the smart contract.
     */
    function drain(address _to, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: NO-LICENSE

pragma solidity ^0.8.4;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/**
 * @dev interface of Whitelist Contract.
 */

interface IWhiteList {
    /**
     * @dev whitelist the `_user` for purchase.
     *
     * Requirements:
     * `_user` should not be a zero address.
     * `_user` should not be already whitelisted.
     *
     * returns a bool to represent the status of the transaction.
     */
    function whitelist(address _user) external returns (bool);

    /**
     * @dev blacklists the `user` from sale.
     *
     * Requirements:
     * `_user` should be whitelisted before.
     * `_user` cannot be a zero address.
     *
     * returns a bool to represent the status of the transaction.
     */
    function blacklist(address _user) external returns (bool);

    /**
     * @dev transfers the control of whitelisting to another wallet.
     *
     * Requirements:
     * `_newGovernor` should not be a zero address.
     * `caller` should be the current governor.
     *
     * returns a bool to represent the status of the transaction.
     */
    function transferGovernor(address _newGovernor) external returns (bool);

    /**
     * @dev returns a bool to represent the whitelisting status of a wallet.
     *
     * true - address is whitelisted and can purchase tokens.
     * false - prevented from sale.
     */
    function whitelisted(address _user) external view returns (bool);
}

// SPDX-License-Identifier: NO-LICENSE

pragma solidity ^0.8.4;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}