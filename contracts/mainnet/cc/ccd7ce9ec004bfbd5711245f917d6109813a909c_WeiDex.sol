pragma solidity 0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor()
        public
    {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner()
    {
        require(
            msg.sender == owner,
            "Only the owner of that contract can execute this method"
        );
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        require(
            newOwner != address(0x0),
            "Invalid address"
        );

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}
// Inspired by https://github.com/AdExNetwork/adex-protocol-eth/blob/master/contracts/libs/SafeERC20.sol
// The old ERC20 token standard defines transfer and transferFrom without return value.
// So the current ERC20 token standard is incompatible with this one.
interface IOldERC20 {
	function transfer(address to, uint256 value)
        external;

	function transferFrom(address from, address to, uint256 value)
        external;

	function approve(address spender, uint256 value)
        external;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeOldERC20 {
	// definitely not a pure fn but the compiler complains otherwise
    function checkSuccess()
        private
        pure
		returns (bool)
	{
        uint256 returnValue = 0;

        assembly {
			// check number of bytes returned from last function call
			switch returndatasize

			// no bytes returned: assume success
			case 0x0 {
				returnValue := 1
			}

			// 32 bytes returned: check if non-zero
			case 0x20 {
				// copy 32 bytes into scratch space
				returndatacopy(0x0, 0x0, 0x20)

				// load those bytes into returnValue
				returnValue := mload(0x0)
			}

			// not sure what was returned: don&#39;t mark as success
			default { }
        }

        return returnValue != 0;
    }

    function transfer(address token, address to, uint256 amount) internal {
        IOldERC20(token).transfer(to, amount);
        require(checkSuccess(), "Transfer failed");
    }

    function transferFrom(address token, address from, address to, uint256 amount) internal {
        IOldERC20(token).transferFrom(from, to, amount);
        require(checkSuccess(), "Transfer From failed");
    }
}

library CrowdsaleLib {

    struct Crowdsale {
        uint256 startTime;
        uint256 endTime;
        uint256 capacity;
        uint256 leftAmount;
        uint256 tokenRatio;
        uint256 minContribution;
        uint256 maxContribution;
        uint256 weiRaised;
        address wallet;
    }

    function isValid(Crowdsale storage _self)
        internal
        view
        returns (bool)
    {
        return (
            (_self.startTime >= now) &&
            (_self.endTime >= _self.startTime) &&
            (_self.tokenRatio > 0) &&
            (_self.wallet != address(0))
        );
    }

    function isOpened(Crowdsale storage _self)
        internal
        view
        returns (bool)
    {
        return (now >= _self.startTime && now <= _self.endTime);
    }

    function createCrowdsale(
        address _wallet,
        uint256[8] _values
    )
        internal
        pure
        returns (Crowdsale memory)
    {
        return Crowdsale({
            startTime: _values[0],
            endTime: _values[1],
            capacity: _values[2],
            leftAmount: _values[3],
            tokenRatio: _values[4],
            minContribution: _values[5],
            maxContribution: _values[6],
            weiRaised: _values[7],
            wallet: _wallet
        });
    }
}

contract IUpgradableExchange {

    uint8 public VERSION;

    event FundsMigrated(address indexed user, address indexed exchangeAddress);

    function allowOrRestrictMigrations() external;

    function migrateFunds(address[] _tokens) external;

    function migrateEthers() private;

    function migrateTokens(address[] _tokens) private;

    function importEthers(address _user) external payable;

    function importTokens(address _tokenAddress, uint256 _tokenAmount, address _user) external;

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
        external returns (bool);

    function transferFrom(address from, address to, uint256 value)
        external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library OrderLib {

    struct Order {
        uint256 makerSellAmount;
        uint256 makerBuyAmount;
        uint256 nonce;
        address maker;
        address makerSellToken;
        address makerBuyToken;
    }

    /**
    * @dev Hashes the order.
    * @param order Order to be hashed.
    * @return hash result
    */
    function createHash(Order memory order)
        internal
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                order.maker,
                order.makerSellToken,
                order.makerSellAmount,
                order.makerBuyToken,
                order.makerBuyAmount,
                order.nonce,
                this
            )
        );
    }

    /**
    * @dev Creates order struct from value arrays.
    * @param addresses Array of trade&#39;s maker, makerToken and takerToken.
    * @param values Array of trade&#39;s makerTokenAmount, takerTokenAmount, expires and nonce.
    * @return Order struct
    */
    function createOrder(
        address[3] addresses,
        uint256[3] values
    )
        internal
        pure
        returns (Order memory)
    {
        return Order({
            maker: addresses[0],
            makerSellToken: addresses[1],
            makerSellAmount: values[0],
            makerBuyToken: addresses[2],
            makerBuyAmount: values[1],
            nonce: values[2]
        });
    }

}

/**
 * @title Math
 * @dev Math operations with safety checks that throw on error
 */
library Math {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns(uint256 c)
    {
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
    function div(uint256 a, uint256 b)
        internal
        pure
        returns(uint256)
    {
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns(uint256)
    {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns(uint256 c)
    {
        c = a + b;
        assert(c >= a);
        return c;
    }

    /**
    * @dev Calculate the ration between two assets. For example ETH/WDX
    * @param _numerator uint256 base currency
    * @param _denominator uint256 quote currency
    */
    function calculateRate(
        uint256 _numerator,
        uint256 _denominator
    )
        internal
        pure
        returns(uint256)
    {
        return div(mul(_numerator, 1e18), _denominator);
    }

    /**
    * @dev Calculate the fee in WDX
    * @param _fee uint256 full fee
    * @param _referralFeeRate uint256 referral fee rate
    */
    function calculateReferralFee(uint256 _fee, uint256 _referralFeeRate) internal pure returns (uint256) {
        return div(_fee, _referralFeeRate);
    }

    /**
    * @dev Calculate the fee in WDX
    * @param _etherAmount uint256 amount in Ethers
    * @param _tokenRatio uint256 the rate between ETH/WDX
    * @param _feeRate uint256 the fee rate
    */
    function calculateWdxFee(uint256 _etherAmount, uint256 _tokenRatio, uint256 _feeRate) internal pure returns (uint256) {
        return div(div(mul(_etherAmount, 1e18), _tokenRatio), mul(_feeRate, 2));
    }
}

/**
 * @title Token contract
 * @dev extending ERC20 to support ExchangeOffering functionality.
 */
contract Token is IERC20 {
    function getBonusFactor(uint256 _startTime, uint256 _endTime, uint256 _weiAmount)
        public view returns (uint256);

    function isUserWhitelisted(address _user)
        public view returns (bool);
}

contract Exchange is Ownable {

    using Math for uint256;

    using OrderLib for OrderLib.Order;

    uint256 public feeRate;

    mapping(address => mapping(address => uint256)) public balances;

    mapping(bytes32 => uint256) public filledAmounts;

    address constant public ETH = address(0x0);

    address public feeAccount;

    constructor(
        address _feeAccount,
        uint256 _feeRate
    )
        public
    {
        feeAccount = _feeAccount;
        feeRate = _feeRate;
    }

    enum ErrorCode {
        INSUFFICIENT_MAKER_BALANCE,
        INSUFFICIENT_TAKER_BALANCE,
        INSUFFICIENT_ORDER_AMOUNT
    }

    event Deposit(
        address indexed tokenAddress,
        address indexed user,
        uint256 amount,
        uint256 balance
    );

    event Withdraw(
        address indexed tokenAddress,
        address indexed user,
        uint256 amount,
        uint256 balance
    );

    event CancelOrder(
        address indexed makerBuyToken,
        address indexed makerSellToken,
        address indexed maker,
        bytes32 orderHash,
        uint256 nonce
    );

    event TakeOrder(
        address indexed maker,
        address taker,
        address indexed makerBuyToken,
        address indexed makerSellToken,
        uint256 takerGivenAmount,
        uint256 takerReceivedAmount,
        bytes32 orderHash,
        uint256 nonce
    );

    event Error(
        uint8 eventId,
        bytes32 orderHash
    );

    /**
    * @dev Owner can set the exchange fee
    * @param _feeRate uint256 new fee rate
    */
    function setFee(uint256 _feeRate)
        external
        onlyOwner
    {
        feeRate = _feeRate;
    }

    /**
    * @dev Owner can set the new fee account
    * @param _feeAccount address
    */
    function setFeeAccount(address _feeAccount)
        external
        onlyOwner
    {
        feeAccount = _feeAccount;
    }

    /**
    * @dev Allows user to deposit Ethers in the exchange contract.
    * Only the respected user can withdraw these Ethers.
    */
    function depositEthers() external payable
    {
        address user = msg.sender;
        _depositEthers(user);
        emit Deposit(ETH, user, msg.value, balances[ETH][user]);
    }

    /**
    * @dev Allows user to deposit Ethers for beneficiary in the exchange contract.
    * @param _beneficiary address
    * Only the beneficiary can withdraw these Ethers.
    */
    function depositEthersFor(
        address
        _beneficiary
    )
        external
        payable
    {
        _depositEthers(_beneficiary);
        emit Deposit(ETH, _beneficiary, msg.value, balances[ETH][_beneficiary]);
    }

    /**
    * @dev Allows user to deposit Tokens in the exchange contract.
    * Only the respected user can withdraw these tokens.
    * @param _tokenAddress address representing the token contract address.
    * @param _amount uint256 representing the token amount to be deposited.
    */
    function depositTokens(
        address _tokenAddress,
        uint256 _amount
    )
        external
    {
        address user = msg.sender;
        _depositTokens(_tokenAddress, _amount, user);
        emit Deposit(_tokenAddress, user, _amount, balances[_tokenAddress][user]);
    }

        /**
    * @dev Allows user to deposit Tokens for beneficiary in the exchange contract.
    * Only the beneficiary can withdraw these tokens.
    * @param _tokenAddress address representing the token contract address.
    * @param _amount uint256 representing the token amount to be deposited.
    * @param _beneficiary address representing the token amount to be deposited.
    */
    function depositTokensFor(
        address _tokenAddress,
        uint256 _amount,
        address _beneficiary
    )
        external
    {
        _depositTokens(_tokenAddress, _amount, _beneficiary);
        emit Deposit(_tokenAddress, _beneficiary, _amount, balances[_tokenAddress][_beneficiary]);
    }

    /**
    * @dev Internal version of deposit Ethers.
    */
    function _depositEthers(
        address
        _beneficiary
    )
        internal
    {
        balances[ETH][_beneficiary] = balances[ETH][_beneficiary].add(msg.value);
    }

    /**
    * @dev Internal version of deposit Tokens.
    */
    function _depositTokens(
        address _tokenAddress,
        uint256 _amount,
        address _beneficiary
    )
        internal
    {
        balances[_tokenAddress][_beneficiary] = balances[_tokenAddress][_beneficiary].add(_amount);

        require(
            Token(_tokenAddress).transferFrom(msg.sender, this, _amount),
            "Token transfer is not successfull (maybe you haven&#39;t used approve first?)"
        );
    }

    /**
    * @dev Allows user to withdraw Ethers from the exchange contract.
    * Throws if the user balance is lower than the requested amount.
    * @param _amount uint256 representing the amount to be withdrawn.
    */
    function withdrawEthers(uint256 _amount) external
    {
        address user = msg.sender;

        require(
            balances[ETH][user] >= _amount,
            "Not enough funds to withdraw."
        );

        balances[ETH][user] = balances[ETH][user].sub(_amount);

        user.transfer(_amount);

        emit Withdraw(ETH, user, _amount, balances[ETH][user]);
    }

    /**
    * @dev Allows user to withdraw specific Token from the exchange contract.
    * Throws if the user balance is lower than the requested amount.
    * @param _tokenAddress address representing the token contract address.
    * @param _amount uint256 representing the amount to be withdrawn.
    */
    function withdrawTokens(
        address _tokenAddress,
        uint256 _amount
    )
        external
    {
        address user = msg.sender;

        require(
            balances[_tokenAddress][user] >= _amount,
            "Not enough funds to withdraw."
        );

        balances[_tokenAddress][user] = balances[_tokenAddress][user].sub(_amount);

        require(
            Token(_tokenAddress).transfer(user, _amount),
            "Token transfer is not successfull."
        );

        emit Withdraw(_tokenAddress, user, _amount, balances[_tokenAddress][user]);
    }

    /**
    * @dev Allows user to transfer specific Token inside the exchange.
    * @param _tokenAddress address representing the token address.
    * @param _to address representing the beneficier.
    * @param _amount uint256 representing the amount to be transferred.
    */
    function transfer(
        address _tokenAddress,
        address _to,
        uint256 _amount
    )
        external
    {
        address user = msg.sender;

        require(
            balances[_tokenAddress][user] >= _amount,
            "Not enough funds to transfer."
        );

        balances[_tokenAddress][user] = balances[_tokenAddress][user].sub(_amount);

        balances[_tokenAddress][_to] = balances[_tokenAddress][_to].add(_amount);
    }

    /**
    * @dev Common take order implementation
    * @param _order OrderLib.Order memory - order info
    * @param _takerSellAmount uint256 - amount being given by the taker
    * @param _v uint8 part of the signature
    * @param _r bytes32 part of the signature (from 0 to 32 bytes)
    * @param _s bytes32 part of the signature (from 32 to 64 bytes)
    */
    function takeOrder(
        OrderLib.Order memory _order,
        uint256 _takerSellAmount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        internal
        returns (uint256)
    {
        bytes32 orderHash = _order.createHash();

        require(
            ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash)), _v, _r, _s) == _order.maker,
            "Order maker is invalid."
        );

        if(balances[_order.makerBuyToken][msg.sender] < _takerSellAmount) {
            emit Error(uint8(ErrorCode.INSUFFICIENT_TAKER_BALANCE), orderHash);
            return 0;
        }

        uint256 receivedAmount = (_order.makerSellAmount.mul(_takerSellAmount)).div(_order.makerBuyAmount);

        if(balances[_order.makerSellToken][_order.maker] < receivedAmount) {
            emit Error(uint8(ErrorCode.INSUFFICIENT_MAKER_BALANCE), orderHash);
            return 0;
        }

        if(filledAmounts[orderHash].add(_takerSellAmount) > _order.makerBuyAmount) {
            emit Error(uint8(ErrorCode.INSUFFICIENT_ORDER_AMOUNT), orderHash);
            return 0;
        }

        filledAmounts[orderHash] = filledAmounts[orderHash].add(_takerSellAmount);

        balances[_order.makerBuyToken][msg.sender] = balances[_order.makerBuyToken][msg.sender].sub(_takerSellAmount);
        balances[_order.makerBuyToken][_order.maker] = balances[_order.makerBuyToken][_order.maker].add(_takerSellAmount);

        balances[_order.makerSellToken][msg.sender] = balances[_order.makerSellToken][msg.sender].add(receivedAmount);
        balances[_order.makerSellToken][_order.maker] = balances[_order.makerSellToken][_order.maker].sub(receivedAmount);

        emit TakeOrder(
            _order.maker,
            msg.sender,
            _order.makerBuyToken,
            _order.makerSellToken,
            _takerSellAmount,
            receivedAmount,
            orderHash,
            _order.nonce
        );

        return receivedAmount;
    }

    /**
    * @dev Order maker can call this function in order to cancel it.
    * What actually happens is that the order become
    * fulfilled in the "filledAmounts" mapping. Thus we avoid someone calling
    * "takeOrder" directly from the contract if the order hash is available to him.
    * @param _orderAddresses address[3]
    * @param _orderValues uint256[3]
    * @param _v uint8 parameter parsed from the signature recovery
    * @param _r bytes32 parameter parsed from the signature (from 0 to 32 bytes)
    * @param _s bytes32 parameter parsed from the signature (from 32 to 64 bytes)
    */
    function cancelOrder(
        address[3] _orderAddresses,
        uint256[3] _orderValues,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
    {
        OrderLib.Order memory order = OrderLib.createOrder(_orderAddresses, _orderValues);
        bytes32 orderHash = order.createHash();

        require(
            ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash)), _v, _r, _s) == msg.sender,
            "Only order maker can cancel it."
        );

        filledAmounts[orderHash] = filledAmounts[orderHash].add(order.makerBuyAmount);

        emit CancelOrder(
            order.makerBuyToken,
            order.makerSellToken,
            msg.sender,
            orderHash,
            order.nonce
        );
    }

    /**
    * @dev Cancel multiple orders in a single transaction.
    * @param _orderAddresses address[3][]
    * @param _orderValues uint256[3][]
    * @param _v uint8[] parameter parsed from the signature recovery
    * @param _r bytes32[] parameter parsed from the signature (from 0 to 32 bytes)
    * @param _s bytes32[] parameter parsed from the signature (from 32 to 64 bytes)
    */
    function cancelMultipleOrders(
        address[3][] _orderAddresses,
        uint256[3][] _orderValues,
        uint8[] _v,
        bytes32[] _r,
        bytes32[] _s
    )
        external
    {
        for (uint256 index = 0; index < _orderAddresses.length; index++) {
            cancelOrder(
                _orderAddresses[index],
                _orderValues[index],
                _v[index],
                _r[index],
                _s[index]
            );
        }
    }
}

contract DailyVolumeUpdater is Ownable {

    using Math for uint256;

    uint256 public dailyVolume;

    uint256 public dailyVolumeCap;

    uint256 private lastDay;

    constructor()
        public
    {
        dailyVolume = 0;
        dailyVolumeCap = 1000 ether;
        lastDay = today();
    }

    /**
    * @dev Allows the owner to change the daily volume capacity.
    * @param _dailyVolumeCap uint256 representing the daily volume capacity
    */
    function setDailyVolumeCap(uint256 _dailyVolumeCap)
        public
        onlyOwner
    {
        dailyVolumeCap = _dailyVolumeCap;
    }

    /**
    * @dev Internal function that increments the daily volume.
    * @param _volume uint256 representing the amount of volume increasement.
    */
    function updateVolume(uint256 _volume)
        internal
    {
        if(today() > lastDay) {
            dailyVolume = _volume;
            lastDay = today();
        } else {
            dailyVolume = dailyVolume.add(_volume);
        }
    }

    /**
    * @dev Internal function to check if the volume capacity is reached.
    * @return Whether the volume is reached or not.
    */
    function isVolumeReached()
        internal
        view
        returns(bool)
    {
        return dailyVolume >= dailyVolumeCap;
    }

    /**
    * @dev Private function to determine today&#39;s index
    * @return uint256 of today&#39;s index.
    */
    function today()
        private
        view
        returns(uint256)
    {
        return block.timestamp.div(1 days);
    }
}

contract DiscountTokenExchange is Exchange, DailyVolumeUpdater {

    uint256 internal discountTokenRatio;

    uint256 private minimumTokenAmountForUpdate;

    address public discountTokenAddress;

    bool internal initialized = false;

    constructor(
        address _discountTokenAddress,
        uint256 _discountTokenRatio
    )
        public
    {
        discountTokenAddress = _discountTokenAddress;
        discountTokenRatio = _discountTokenRatio;
    }

    modifier onlyOnce() {
        require(
            initialized == false,
            "Exchange is already initialized"
        );
        _;
    }

    /**
    * @dev Update the token discount contract.
    * @param _discountTokenAddress address of the token used for fee discount
    * @param _discountTokenRatio uint256 initial rate of the token discount contract
    */
    function setDiscountToken(
        address _discountTokenAddress,
        uint256 _discountTokenRatio,
        uint256 _minimumTokenAmountForUpdate
    )
        public
        onlyOwner
        onlyOnce
    {
        discountTokenAddress = _discountTokenAddress;
        discountTokenRatio = _discountTokenRatio;
        minimumTokenAmountForUpdate = _minimumTokenAmountForUpdate;
        initialized = true;
    }

    /**
    * @dev Update the token ratio.
    * Add a minimum requirement for the amount of tokens being traded
    * to avoid possible intentional manipulation
    * @param _etherAmount uint256 amount in Ethers (wei)
    * @param _tokenAmount uint256 amount in Tokens
    */
    function updateTokenRatio(
        uint256 _etherAmount,
        uint256 _tokenAmount
    )
        internal
    {
        if(_tokenAmount >= minimumTokenAmountForUpdate) {
            discountTokenRatio = _etherAmount.calculateRate(_tokenAmount);
        }
    }

    /**
    * @dev Set the minimum requirement for updating the price.
    * This should be called whenever the rate of the token
    * has changed massively.
    * In order to avoid token price manipulation (that will reduce the fee)
    * The minimum amount requirement take place.
    * For example: Someone buys or sells 0.0000000001 Tokens with
    * high rate against ETH and after that execute a trade,
    * reducing his fees to approximately zero.
    * Having the mimimum amount requirement for updating
    * the price will protect us from such cases because
    * it will not be worth to do it.
    * @param _minimumTokenAmountForUpdate - the new mimimum amount of
    * tokens for updating the ratio (price)
    */
    function setMinimumTokenAmountForUpdate(
        uint256 _minimumTokenAmountForUpdate
    )
        external
        onlyOwner
    {
        minimumTokenAmountForUpdate = _minimumTokenAmountForUpdate;
    }

    /**
    * @dev Execute WeiDexToken Sale Order based on the order input parameters
    * and the signature from the maker&#39;s signing.
    * @param _orderAddresses address[3] representing
    * [0] address of the order maker
    * [1] address of WeiDexToken
    * [2] address of Ether (0x0)
    * @param _orderValues uint256[4] representing
    * [0] amount in WDX
    * [1] amount in Ethers (wei)
    * [2] order nonce used for hash uniqueness
    * @param _takerSellAmount uint256 - amount being asked from the taker, should be in ethers
    * @param _v uint8 parameter parsed from the signature recovery
    * @param _r bytes32 parameter parsed from the signature (from 0 to 32 bytes)
    * @param _s bytes32 parameter parsed from the signature (from 32 to 64 bytes)
    */
    function takeSellTokenOrder(
        address[3] _orderAddresses,
        uint256[3] _orderValues,
        uint256 _takerSellAmount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        require(
            _orderAddresses[1] == discountTokenAddress,
            "Should sell WeiDex Tokens"
        );

        require(
            0 < takeOrder(OrderLib.createOrder(_orderAddresses, _orderValues), _takerSellAmount, _v, _r, _s),
            "Trade failure"
        );
        updateVolume(_takerSellAmount);
        updateTokenRatio(_orderValues[1], _orderValues[0]);
    }

    /**
    * @dev Execute WeiDexToken Buy Order based on the order input parameters
    * and the signature from the maker&#39;s signing.
    * @param _orderAddresses address[3] representing
    * [0] address of the order maker
    * [1] address of Ether (0x0)
    * [2] address of WeiDexToken
    * @param _orderValues uint256[4] representing
    * [0] amount in Ethers
    * [1] amount in WDX
    * [2] order nonce used for hash uniqueness
    * @param _takerSellAmount uint256 - amount being asked from the taker
    * @param _v uint8 parameter parsed from the signature recovery
    * @param _r bytes32 parameter parsed from the signature (from 0 to 32 bytes)
    * @param _s bytes32 parameter parsed from the signature (from 32 to 64 bytes)
    */
    function takeBuyTokenOrder(
        address[3] _orderAddresses,
        uint256[3] _orderValues,
        uint256 _takerSellAmount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        require(
            _orderAddresses[2] == discountTokenAddress,
            "Should buy WeiDex Tokens"
        );

        uint256 receivedAmount = takeOrder(OrderLib.createOrder(_orderAddresses, _orderValues), _takerSellAmount, _v, _r, _s);
        require(0 < receivedAmount, "Trade failure");
        updateVolume(receivedAmount);
        updateTokenRatio(_orderValues[0], _orderValues[1]);
    }
}

contract ReferralExchange is Exchange {

    uint256 public referralFeeRate;

    mapping(address => address) public referrals;

    constructor(
        uint256 _referralFeeRate
    )
        public
    {
        referralFeeRate = _referralFeeRate;
    }

    event ReferralBalanceUpdated(
        address refererAddress,
        address referralAddress,
        address tokenAddress,
        uint256 feeAmount,
        uint256 referralFeeAmount
    );

    event ReferralDeposit(
        address token,
        address indexed user,
        address indexed referrer,
        uint256 amount,
        uint256 balance
    );

    /**
    * @dev Deposit Ethers with a given referrer address
    * @param _referrer address of the referrer
    */
    function depositEthers(address _referrer)
        external
        payable
    {
        address user = msg.sender;

        require(
            0x0 == referrals[user],
            "This user already have a referrer."
        );

        super._depositEthers(user);
        referrals[user] = _referrer;
        emit ReferralDeposit(ETH, user, _referrer, msg.value, balances[ETH][user]);
    }

    /**
    * @dev Deposit Tokens with a given referrer address
    * @param _referrer address of the referrer
    */
    function depositTokens(
        address _tokenAddress,
        uint256 _amount,
        address _referrer
    )
        external
    {
        address user = msg.sender;

        require(
            0x0 == referrals[user],
            "This user already have a referrer."
        );

        super._depositTokens(_tokenAddress, _amount, user);
        referrals[user] = _referrer;
        emit ReferralDeposit(_tokenAddress, user, _referrer, _amount, balances[_tokenAddress][user]);
    }

    /**
    * @dev Update the referral fee rate,
    * i.e. the rate of the fee that will be accounted to the referrer
    * @param _referralFeeRate uint256 amount of fee going to the referrer
    */
    function setReferralFee(uint256 _referralFeeRate)
        external
        onlyOwner
    {
        referralFeeRate = _referralFeeRate;
    }

    /**
    * @dev Return the feeAccount address if user doesn&#39;t have referrer
    * @param _user address user whom referrer is being checked.
    * @return address of user&#39;s referrer.
    */
    function getReferrer(address _user)
        internal
        view
        returns(address referrer)
    {
        return referrals[_user] != address(0x0) ? referrals[_user] : feeAccount;
    }
}

contract UpgradableExchange is Exchange {

    uint8 constant public VERSION = 0;

    address public newExchangeAddress;

    bool public isMigrationAllowed;

    event FundsMigrated(address indexed user, address indexed exchangeAddress);

    /**
    * @dev Owner can set the address of the new version of the exchange contract.
    * @param _newExchangeAddress address representing the new exchange contract address
    */
    function setNewExchangeAddress(address _newExchangeAddress)
        external
        onlyOwner
    {
        newExchangeAddress = _newExchangeAddress;
    }

    /**
    * @dev Enables/Disables the migrations. Can be called only by the owner.
    */
    function allowOrRestrictMigrations()
        external
        onlyOwner
    {
        isMigrationAllowed = !isMigrationAllowed;
    }

    /**
    * @dev Set the address of the new version of the exchange contract. Should be called by the user.
    * @param _tokens address[] representing the token addresses which are going to be migrated.
    */
    function migrateFunds(address[] _tokens) external {

        require(
            false != isMigrationAllowed,
            "Fund migration is not allowed"
        );

        require(
            IUpgradableExchange(newExchangeAddress).VERSION() > VERSION,
            "New exchange version should be greater than the current version."
        );

        migrateEthers();

        migrateTokens(_tokens);

        emit FundsMigrated(msg.sender, newExchangeAddress);
    }

    /**
    * @dev Helper function to migrate user&#39;s Ethers. Should be called in migrateFunds() function.
    */
    function migrateEthers() private {

        uint256 etherAmount = balances[ETH][msg.sender];
        if (etherAmount > 0) {
            balances[ETH][msg.sender] = 0;

            IUpgradableExchange(newExchangeAddress).importEthers.value(etherAmount)(msg.sender);
        }
    }

    /**
    * @dev Helper function to migrate user&#39;s tokens. Should be called in migrateFunds() function.
    * @param _tokens address[] representing the token addresses which are going to be migrated.
    */
    function migrateTokens(address[] _tokens) private {

        for (uint256 index = 0; index < _tokens.length; index++) {

            address tokenAddress = _tokens[index];

            uint256 tokenAmount = balances[tokenAddress][msg.sender];

            if (0 == tokenAmount) {
                continue;
            }

            require(
                Token(tokenAddress).approve(newExchangeAddress, tokenAmount),
                "Approve failed"
            );

            balances[tokenAddress][msg.sender] = 0;

            IUpgradableExchange(newExchangeAddress).importTokens(tokenAddress, tokenAmount, msg.sender);
        }
    }
}

contract ExchangeOffering is Exchange {

    using CrowdsaleLib for CrowdsaleLib.Crowdsale;

    mapping(address => CrowdsaleLib.Crowdsale) public crowdsales;

    mapping(address => mapping(address => uint256)) public userContributionForProject;

    event TokenPurchase(
        address indexed project,
        address indexed contributor,
        uint256 tokens,
        uint256 weiAmount
    );

    function registerCrowdsale(
        address _project,
        address _projectWallet,
        uint256[8] _values
    )
        public
        onlyOwner
    {
        crowdsales[_project] = CrowdsaleLib.createCrowdsale(_projectWallet, _values);

        require(
            crowdsales[_project].isValid(),
            "Crowdsale is not active."
        );

        // project contract validation
        require(
            getBonusFactor(_project, crowdsales[_project].minContribution) >= 0,
            "The project should have *getBonusFactor* function implemented. The function should return the bonus percentage depending on the start/end date and contribution amount. Should return 0 if there is no bonus."
        );

        // project contract validation
        require(
            isUserWhitelisted(_project, this),
            "The project should have *isUserWhitelisted* function implemented. This contract address should be whitelisted"
        );
    }

    function buyTokens(address _project)
       public
       payable
    {
        uint256 weiAmount = msg.value;

        address contributor = msg.sender;

        address crowdsaleWallet = crowdsales[_project].wallet;

        require(
            isUserWhitelisted(_project, contributor), "User is not whitelisted"
        );

        require(
            validContribution(_project, contributor, weiAmount),
            "Contribution is not valid: Check minimum/maximum contribution amount or if crowdsale cap is reached"
        );

        uint256 tokens = weiAmount.mul(crowdsales[_project].tokenRatio);

        uint256 bonus = getBonusFactor(_project, weiAmount);

        uint256 bonusAmount = tokens.mul(bonus).div(100);

        uint256 totalPurchasedTokens = tokens.add(bonusAmount);

        crowdsales[_project].leftAmount = crowdsales[_project].leftAmount.sub(totalPurchasedTokens);

        require(Token(_project).transfer(contributor, totalPurchasedTokens), "Transfer failed");

        crowdsales[_project].weiRaised = crowdsales[_project].weiRaised.add(weiAmount);

        userContributionForProject[_project][contributor] = userContributionForProject[_project][contributor].add(weiAmount);

        balances[ETH][crowdsaleWallet] = balances[ETH][crowdsaleWallet].add(weiAmount);

        emit TokenPurchase(_project, contributor, totalPurchasedTokens, weiAmount);
    }

    function withdrawWhenFinished(address _project) public {

        address crowdsaleWallet = crowdsales[_project].wallet;

        require(
            msg.sender == crowdsaleWallet,
            "Only crowdsale owner can withdraw funds that are left."
        );

        require(
            !crowdsales[_project].isOpened(),
            "You can&#39;t withdraw funds yet. Crowdsale should end first."
        );

        uint256 leftAmount = crowdsales[_project].leftAmount;

        crowdsales[_project].leftAmount = 0;

        require(Token(_project).transfer(crowdsaleWallet, leftAmount), "Transfer failed");
    }

    function saleOpen(address _project)
        public
        view
        returns(bool)
    {
        return crowdsales[_project].isOpened();
    }

    function getBonusFactor(address _project, uint256 _weiAmount)
        public
        view
        returns(uint256)
    {
        return Token(_project).getBonusFactor(crowdsales[_project].startTime, crowdsales[_project].endTime, _weiAmount);
    }

    function isUserWhitelisted(address _project, address _user)
        public
        view
        returns(bool)
    {
        return Token(_project).isUserWhitelisted(_user);
    }

    function validContribution(
        address _project,
        address _user,
        uint256 _weiAmount
    )
        private
        view
        returns(bool)
    {
        if (saleOpen(_project)) {
            // minimum contribution check
            if (_weiAmount < crowdsales[_project].minContribution) {
                return false;
            }

            // maximum contribution check
            if (userContributionForProject[_project][_user].add(_weiAmount) > crowdsales[_project].maxContribution) {
                return false;
            }

            // token sale capacity check
            if (crowdsales[_project].capacity < crowdsales[_project].weiRaised.add(_weiAmount)) {
                return false;
            }
        } else {
            return false;
        }

        return msg.value != 0; // check for non zero contribution
    }
}

contract OldERC20ExchangeSupport is Exchange, ReferralExchange {

    /**
    * @dev Allows user to deposit Tokens in the exchange contract.
    * Only the respected user can withdraw these tokens.
    * @param _tokenAddress address representing the token contract address.
    * @param _amount uint256 representing the token amount to be deposited.
    */
    function depositOldTokens(
        address _tokenAddress,
        uint256 _amount
    )
        external
    {
        address user = msg.sender;
        _depositOldTokens(_tokenAddress, _amount, user);
        emit Deposit(_tokenAddress, user, _amount, balances[_tokenAddress][user]);
    }

    /**
    * @dev Deposit Tokens with a given referrer address
    * @param _referrer address of the referrer
    */
    function depositOldTokens(
        address _tokenAddress,
        uint256 _amount,
        address _referrer
    )
        external
    {
        address user = msg.sender;

        require(
            0x0 == referrals[user],
            "This user already have a referrer."
        );

        _depositOldTokens(_tokenAddress, _amount, user);
        referrals[user] = _referrer;
        emit ReferralDeposit(_tokenAddress, user, _referrer, _amount, balances[_tokenAddress][user]);
    }

        /**
    * @dev Allows user to deposit Tokens for beneficiary in the exchange contract.
    * Only the beneficiary can withdraw these tokens.
    * @param _tokenAddress address representing the token contract address.
    * @param _amount uint256 representing the token amount to be deposited.
    * @param _beneficiary address representing the token amount to be deposited.
    */
    function depositOldTokensFor(
        address _tokenAddress,
        uint256 _amount,
        address _beneficiary
    )
        external
    {
        _depositOldTokens(_tokenAddress, _amount, _beneficiary);
        emit Deposit(_tokenAddress, _beneficiary, _amount, balances[_tokenAddress][_beneficiary]);
    }

    /**
    * @dev Allows user to withdraw specific Token from the exchange contract.
    * Throws if the user balance is lower than the requested amount.
    * @param _tokenAddress address representing the token contract address.
    * @param _amount uint256 representing the amount to be withdrawn.
    */
    function withdrawOldTokens(
        address _tokenAddress,
        uint256 _amount
    )
        external
    {
        address user = msg.sender;

        require(
            balances[_tokenAddress][user] >= _amount,
            "Not enough funds to withdraw."
        );

        balances[_tokenAddress][user] = balances[_tokenAddress][user].sub(_amount);

        SafeOldERC20.transfer(_tokenAddress, user, _amount);

        emit Withdraw(_tokenAddress, user, _amount, balances[_tokenAddress][user]);
    }

    /**
    * @dev Internal version of deposit Tokens.
    */
    function _depositOldTokens(
        address _tokenAddress,
        uint256 _amount,
        address _beneficiary
    )
        internal
    {
        balances[_tokenAddress][_beneficiary] = balances[_tokenAddress][_beneficiary].add(_amount);

        SafeOldERC20.transferFrom(_tokenAddress, msg.sender, this, _amount);
    }
}

contract WeiDex is DiscountTokenExchange, ReferralExchange, UpgradableExchange, ExchangeOffering, OldERC20ExchangeSupport  {

    mapping(bytes4 => bool) private allowedMethods;

    function () public payable {
        revert("Cannot send Ethers to the contract, use depositEthers");
    }

    constructor(
        address _feeAccount,
        uint256 _feeRate,
        uint256 _referralFeeRate,
        address _discountTokenAddress,
        uint256 _discountTokenRatio
    )
        public
        Exchange(_feeAccount, _feeRate)
        ReferralExchange(_referralFeeRate)
        DiscountTokenExchange(_discountTokenAddress, _discountTokenRatio)
    {
        // empty constructor
    }

    /**
    * @dev Allows or restricts methods from being executed in takeAllPossible and takeAllOrRevert
    * @param _methodId bytes4 method id that will be allowed/forbidded from execution
    * @param _allowed bool
    */
    function allowOrRestrictMethod(
        bytes4 _methodId,
        bool _allowed
    )
        external
        onlyOwner
    {
        allowedMethods[_methodId] = _allowed;
    }

    /**
    * @dev Execute multiple order by given method id
    * @param _orderAddresses address[3][] representing
    * @param _orderValues uint256[4][] representing
    * @param _takerSellAmount uint256[] - amounts being asked from the taker, should be in tokens
    * @param _v uint8[] parameter parsed from the signature recovery
    * @param _r bytes32[] parameter parsed from the signature (from 0 to 32 bytes)
    * @param _s bytes32[] parameter parsed from the signature (from 32 to 64 bytes)
    */
    function takeAllOrRevert(
        address[3][] _orderAddresses,
        uint256[3][] _orderValues,
        uint256[] _takerSellAmount,
        uint8[] _v,
        bytes32[] _r,
        bytes32[] _s,
        bytes4 _methodId
    )
        external
    {
        require(
            allowedMethods[_methodId],
            "Can&#39;t call this method"
        );

        for (uint256 index = 0; index < _orderAddresses.length; index++) {
            require(
                address(this).delegatecall(
                _methodId,
                _orderAddresses[index],
                _orderValues[index],
                _takerSellAmount[index],
                _v[index],
                _r[index],
                _s[index]
                ),
                "Method call failed"
            );
        }
    }

    /**
    * @dev Execute multiple order by given method id
    * @param _orderAddresses address[3][]
    * @param _orderValues uint256[4][]
    * @param _takerSellAmount uint256[] - amounts being asked from the taker, should be in tokens
    * @param _v uint8[] parameter parsed from the signature recovery
    * @param _r bytes32[] parameter parsed from the signature (from 0 to 32 bytes)
    * @param _s bytes32[] parameter parsed from the signature (from 32 to 64 bytes)
    */
    function takeAllPossible(
        address[3][] _orderAddresses,
        uint256[3][] _orderValues,
        uint256[] _takerSellAmount,
        uint8[] _v,
        bytes32[] _r,
        bytes32[] _s,
        bytes4 _methodId
    )
        external
    {
        require(
            allowedMethods[_methodId],
            "Can&#39;t call this method"
        );

        for (uint256 index = 0; index < _orderAddresses.length; index++) {
            address(this).delegatecall(
            _methodId,
            _orderAddresses[index],
            _orderValues[index],
            _takerSellAmount[index],
            _v[index],
            _r[index],
            _s[index]
            );
        }
    }

    /**
    * @dev Execute buy order based on the order input parameters
    * and the signature from the maker&#39;s signing
    * @param _orderAddresses address[3] representing
    * [0] address of the order maker
    * [1] address of ether (0x0)
    * [2] address of token being bought
    * @param _orderValues uint256[4] representing
    * [0] amount in Ethers (wei)
    * [1] amount in tokens
    * [2] order nonce used for hash uniqueness
    * @param _takerSellAmount uint256 - amount being asked from the taker, should be in tokens
    * @param _v uint8 parameter parsed from the signature recovery
    * @param _r bytes32 parameter parsed from the signature (from 0 to 32 bytes)
    * @param _s bytes32 parameter parsed from the signature (from 32 to 64 bytes)
    */
    function takeBuyOrder(
        address[3] _orderAddresses,
        uint256[3] _orderValues,
        uint256 _takerSellAmount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        require(
            _orderAddresses[1] == ETH,
            "Base currency must be ether&#39;s (0x0)"
        );

        OrderLib.Order memory order = OrderLib.createOrder(_orderAddresses, _orderValues);
        uint256 receivedAmount = takeOrder(order, _takerSellAmount, _v, _r, _s);

        require(0 < receivedAmount, "Trade failure");

        updateVolume(receivedAmount);

        if (!isVolumeReached()) {
            takeFee(order.maker, msg.sender, order.makerBuyToken, _takerSellAmount, receivedAmount);
        }
    }

    /**
    * @dev Execute sell order based on the order input parameters
    * and the signature from the maker&#39;s signing
    * @param _orderAddresses address[3] representing
    * [0] address of the order maker
    * [1] address of token being sold
    * [2] address of ether (0x0)
    * @param _orderValues uint256[4] representing
    * [0] amount in tokens
    * [1] amount in Ethers (wei)
    * [2] order nonce used for hash uniqueness
    * @param _takerSellAmount uint256 - amount being asked from the taker, should be in ethers
    * @param _v uint8 parameter parsed from the signature recovery
    * @param _r bytes32 parameter parsed from the signature (from 0 to 32 bytes)
    * @param _s bytes32 parameter parsed from the signature (from 32 to 64 bytes)
    */
    function takeSellOrder(
        address[3] _orderAddresses,
        uint256[3] _orderValues,
        uint256 _takerSellAmount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
    {
        require(
            _orderAddresses[2] == ETH,
            "Base currency must be ether&#39;s (0x0)"
        );

        OrderLib.Order memory order = OrderLib.createOrder(_orderAddresses, _orderValues);

        uint256 receivedAmount = takeOrder(order, _takerSellAmount, _v, _r, _s);

        require(0 < receivedAmount, "Trade failure");

        updateVolume(_takerSellAmount);

        if (!isVolumeReached()) {
            takeFee(order.maker, msg.sender, order.makerSellToken, receivedAmount, _takerSellAmount);
        }
    }

    /**
    * @dev Takes fee for making/taking the order
    * @param _maker address
    * @param _taker address
    * @param _tokenAddress address
    * @param _tokenFulfilledAmount uint256 fulfilled amount in tokens
    * @param _etherFulfilledAmount uint256 fulfilled amount in ethers
    */
    function takeFee(
        address _maker,
        address _taker,
        address _tokenAddress,
        uint256 _tokenFulfilledAmount,
        uint256 _etherFulfilledAmount
    )
        private
    {
        uint256 _feeRate = feeRate; // gas optimization
        uint256 feeInWdx = _etherFulfilledAmount.calculateWdxFee(discountTokenRatio, feeRate);

        takeFee(_maker, ETH, _etherFulfilledAmount.div(_feeRate), feeInWdx);
        takeFee(_taker, _tokenAddress, _tokenFulfilledAmount.div(_feeRate), feeInWdx);
    }

    /**
    * @dev Takes fee in WDX or the given token address
    * @param _user address taker or maker
    * @param _tokenAddress address of the token
    * @param _tokenFeeAmount uint256 amount in given token address
    * @param _wdxFeeAmount uint256 amount in WDX tokens
    */
    function takeFee(
        address _user,
        address _tokenAddress,
        uint256 _tokenFeeAmount,
        uint256 _wdxFeeAmount
        )
        private
    {
        if(balances[discountTokenAddress][_user] >= _wdxFeeAmount) {
            takeFee(_user, discountTokenAddress, _wdxFeeAmount);
        } else {
            takeFee(_user, _tokenAddress, _tokenFeeAmount);
        }
    }

    /**
    * @dev Takes fee in WDX or the given token address
    * @param _user address taker or maker
    * @param _tokenAddress address
    * @param _fullFee uint256 fee taken from a given token address
    */
    function takeFee(
        address _user,
        address _tokenAddress,
        uint256 _fullFee
        )
        private
    {
        address _feeAccount = feeAccount; // gas optimization
        address referrer = getReferrer(_user);
        uint256 referralFee = _fullFee.calculateReferralFee(referralFeeRate);

        balances[_tokenAddress][_user] = balances[_tokenAddress][_user].sub(_fullFee);

        if(referrer == _feeAccount) {
            balances[_tokenAddress][_feeAccount] = balances[_tokenAddress][_feeAccount].add(_fullFee);
        } else {
            balances[_tokenAddress][_feeAccount] = balances[_tokenAddress][_feeAccount].add(_fullFee.sub(referralFee));
            balances[_tokenAddress][referrer] = balances[_tokenAddress][referrer].add(referralFee);
        }
        emit ReferralBalanceUpdated(referrer, _user, _tokenAddress, _fullFee, referralFee);
    }
}