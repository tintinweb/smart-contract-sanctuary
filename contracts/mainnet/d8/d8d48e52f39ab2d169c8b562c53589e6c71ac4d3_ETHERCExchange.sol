pragma solidity ^0.4.19;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


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
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


/**
 * ERC-20 Token Standard
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract Token {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/**
 * Interface for trading discounts and rebates for specific accounts
 */
contract FeeModifiersInterface {
    function accountFeeModifiers(address _user) public view returns (uint256 feeDiscount, uint256 feeRebate);
    function tradingFeeModifiers(address _maker, address _taker) public view returns (uint256 feeMakeDiscount, uint256 feeTakeDiscount, uint256 feeRebate);
}


/**
 * Interface for trade tracker to handle trade event
 */
contract TradeTrackerInterface {
    function tradeEventHandler(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, address _maker, address _user, bytes32 _orderHash, uint256 _gasLimit) public;
}


contract ETHERCExchange is Ownable {
    using SafeMath for uint256;

    // the trade tracker address
    address public tradeTracker;
    // the contract which stores fee discounts/rebates
    address public feeModifiers;
    // the account that will receive fees
    address public feeAccount;
    // maker fee percentage times (1 ether)
    uint256 public feeMake;
    // taker fee percentage times (1 ether) 
    uint256 public feeTake;

    // mapping of token addresses to mapping of account balances
    mapping (address => mapping (address => uint256)) public tokens;
    // mapping of order hash to status cancelled
    mapping (bytes32 => bool) public cancelledOrders;
    // mapping order hashes to uints (amount of order that has been filled)
    mapping (bytes32 => uint256) public orderFills;

    //Logging events
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);
    event Cancel(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, uint256 expires, uint256 nonce, address maker, uint8 v, bytes32 r, bytes32 s, bytes32 orderHash, uint256 amountFilled);
    event Trade(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, address maker, address taker, bytes32 orderHash);

    function ETHERCExchange() public {
        feeAccount = owner;
    }

    function() public {
        revert();
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Fee Discounts, Rebates
    ////////////////////////////////////////////////////////////////////////////////

    function getAccountFeeModifiers(address _user) public view returns(uint256 feeDiscount, uint256 feeRebate) {
        if (feeModifiers != address(0)) {
            (feeDiscount, feeRebate) = FeeModifiersInterface(feeModifiers).accountFeeModifiers(_user);
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Funds
    ////////////////////////////////////////////////////////////////////////////////

    function deposit() public payable {
        tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(msg.value);
        Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }

    function depositToken(address _token, uint256 _amount) public {
        require(_token != address(0));

        if (!Token(_token).transferFrom(msg.sender, this, _amount)) revert();
        tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);
        Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function withdraw(uint256 _amount) public {
        require(tokens[address(0)][msg.sender] >= _amount);

        tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].sub(_amount);
        msg.sender.transfer(_amount);
        Withdraw(address(0), msg.sender, _amount, tokens[address(0)][msg.sender]);
    }

    function withdrawToken(address _token, uint256 _amount) public {
        require(_token != address(0));
        require(tokens[_token][msg.sender] >= _amount);

        tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
        if (!Token(_token).transfer(msg.sender, _amount)) revert();
        Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function balanceOf(address _token, address _user) public view returns (uint256) {
        return tokens[_token][_user];
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Trading & Order
    ////////////////////////////////////////////////////////////////////////////////

    function trade(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _maker, uint8 _v, bytes32 _r, bytes32 _s, uint256 _amountTrade) public {
        uint256 executionGasLimit = msg.gas;
        bytes32 orderHash = getOrderHash(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _maker);

        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), _v, _r, _s) != _maker ||
            cancelledOrders[orderHash] ||
            block.number > _expires ||
            orderFills[orderHash].add(_amountTrade) > _amountGet
        ) revert();

        tradeBalances(_tokenGet, _amountGet, _tokenGive, _amountGive, _maker, _amountTrade);
        orderFills[orderHash] = orderFills[orderHash].add(_amountTrade);
        uint256 amountTradeGive = _amountGive.mul(_amountTrade) / _amountGet;
        if(tradeTracker != address(0)){
            TradeTrackerInterface(tradeTracker).tradeEventHandler(_tokenGet, _amountTrade, _tokenGive, amountTradeGive, _maker, msg.sender, orderHash, executionGasLimit);
        }
        Trade(_tokenGet, _amountTrade, _tokenGive, amountTradeGive, _maker, msg.sender, orderHash);
    }

    function tradeBalances(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, address _maker, uint256 _amountTrade) private {
        uint256 feeMakeValue = _amountTrade.mul(feeMake) / (1 ether);
        uint256 feeTakeValue = _amountTrade.mul(feeTake) / (1 ether);
        uint256 feeRebateValue = 0;

        if (feeModifiers != address(0)) {
            uint256 feeMakeDiscount; uint256 feeTakeDiscount; uint256 feeRebate;
            (feeMakeDiscount, feeTakeDiscount, feeRebate) = FeeModifiersInterface(feeModifiers).tradingFeeModifiers(_maker, msg.sender);
            if (feeMakeValue > 0 && feeMakeDiscount > 0 && feeMakeDiscount <= 100 ) feeMakeValue = feeMakeValue.mul(100 - feeMakeDiscount) / 100;
            if (feeTakeValue > 0 && feeTakeDiscount > 0 && feeTakeDiscount <= 100 ) feeTakeValue = feeTakeValue.mul(100 - feeTakeDiscount) / 100;
            if (feeTakeValue > 0 && feeRebate > 0 && feeRebate <= 100) feeRebateValue = feeTakeValue.mul(feeRebate) / 100;
        }

        tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender].sub(_amountTrade.add(feeTakeValue));
        tokens[_tokenGet][_maker] = tokens[_tokenGet][_maker].add(_amountTrade.sub(feeMakeValue).add(feeRebateValue));
        tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender].add(_amountGive.mul(_amountTrade) / _amountGet);
        tokens[_tokenGive][_maker] = tokens[_tokenGive][_maker].sub(_amountGive.mul(_amountTrade) / _amountGet);
        tokens[_tokenGet][feeAccount] = tokens[_tokenGet][feeAccount].add(feeMakeValue.add(feeTakeValue).sub(feeRebateValue));
    }

    function validateTrade(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _maker, uint8 _v, bytes32 _r, bytes32 _s, uint256 _amountTrade, address _taker) public view returns (uint8) {
        uint256 feeTakeValue = calculateTakerFee(_taker, _amountTrade);

        if (_amountTrade.add(feeTakeValue) > tokens[_tokenGet][_taker]) return 1;
        if (availableVolume(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _maker, _v, _r, _s) < _amountTrade) return 2;
        return 0;
    }

    function calculateTakerFee(address _taker, uint256 _amountTrade) public view returns (uint256) {
        uint256 feeTakeValue = _amountTrade.mul(feeTake) / (1 ether);

        uint256 feeDiscount; uint256 feeRebate;
        (feeDiscount, feeRebate) = getAccountFeeModifiers(_taker);
        if (feeTakeValue > 0 && feeDiscount > 0 && feeDiscount <= 100 ) feeTakeValue = feeTakeValue.mul(100 - feeDiscount) / 100;

        return feeTakeValue;
    }

    function getOrderHash(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _maker) public view returns (bytes32) {
        return keccak256(this, _tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _maker);
    }

    function availableVolume(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _maker, uint8 _v, bytes32 _r, bytes32 _s) public view returns (uint256) {
        bytes32 orderHash = getOrderHash(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _maker);

        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), _v, _r, _s) != _maker ||
            cancelledOrders[orderHash] ||
            block.number > _expires ||
            _amountGet <= orderFills[orderHash]
        ) return 0;

        uint256[2] memory available;
        available[0] = _amountGet.sub(orderFills[orderHash]);
        available[1] = tokens[_tokenGive][_maker].mul(_amountGet) / _amountGive;
        if (available[0] < available[1]) return available[0];
        return available[1];
    }

    function amountFilled(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, address _maker) public view returns (uint256) {
        bytes32 orderHash = getOrderHash(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _maker);
        return orderFills[orderHash];
    }

    function cancelOrder(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive, uint256 _expires, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s) public {
        bytes32 orderHash = getOrderHash(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, msg.sender);
        if (ecrecover(keccak256("\x19Ethereum Signed Message:\n32", orderHash), _v, _r, _s) != msg.sender) revert();

        cancelledOrders[orderHash] = true;
        Cancel(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, msg.sender, _v, _r, _s, orderHash, orderFills[orderHash]);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Setting
    ////////////////////////////////////////////////////////////////////////////////

    function changeFeeAccount(address _feeAccount) public onlyOwner {
        require(_feeAccount != address(0));
        feeAccount = _feeAccount;
    }

    function changeFeeMake(uint256 _feeMake) public onlyOwner {
        require(_feeMake != feeMake);
        feeMake = _feeMake;
    }

    function changeFeeTake(uint256 _feeTake) public onlyOwner {
        require(_feeTake != feeTake);
        feeTake = _feeTake;
    }

    function changeFeeModifiers(address _feeModifiers) public onlyOwner {
        require(feeModifiers != _feeModifiers);
        feeModifiers = _feeModifiers;
    }

    function changeTradeTracker(address _tradeTracker) public onlyOwner {
        require(tradeTracker != _tradeTracker);
        tradeTracker = _tradeTracker;
    }
}