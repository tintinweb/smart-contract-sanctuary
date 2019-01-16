pragma solidity ^0.4.24;


/**
 * @title Safe math
 * @dev Math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        /* Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
         * benefit is lost if &#39;b&#39; is also tested.
         * See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
         */
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;

        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0.

        uint256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);

        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo), reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);

        return a % b;
    }
}

/**
 * @title ERC-20 token interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

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

/**
 * @title Standard ERC20 token.
 * @dev Implementation of the basic standard token.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @return Total number of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the given address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Transfers tokens for the specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);

        return true;
    }

    /**
     * @dev Transfers tokens from one address to another.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= _allowed[from][msg.sender]);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);

        return true;
    }

    /**
     * @dev Approves the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    /**
     * @dev Checks the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return An uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Increases the amount of tokens that an owner allowed to a spender.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

        return true;
    }

    /**
     * @dev Decreases the amount of tokens that an owner allowed to a spender.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

        return true;
    }

    /**
     * @dev Transfers tokens for a specified address.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(from, to, value);
    }

    /**
     * @dev Mints an amount of the token and assigns it to an account.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != 0);

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);

        emit Transfer(address(0), account, value);
    }
}

/**
 * @title ERC-20 extension for multiple recipients
 * @dev Extends the functionality of the ERC-20 standard token with the ability to transfer tokens
 * to multiple recipients in a single transaction.
 */
contract ERC20MultiRecipient is ERC20 {
    function transferMulti(address[] recipients, uint256[] values) public returns (bool) {
        require(recipients.length > 0);
        require(recipients.length == values.length);

        uint256 i;
        uint256 total;

        for (i = 0; i < values.length; i++) {
            total = total.add(values[i]);
        }

        require(total <= _balances[msg.sender]);

        _balances[msg.sender] = _balances[msg.sender].sub(total);

        for (i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0));

            _balances[recipients[i]] = _balances[recipients[i]].add(values[i]);

            emit Transfer(msg.sender, recipients[i], values[i]);
        }

        return true;
    }
}

interface IChannelManager {
    event ChannelOpened(
        address node,
        address from,
        uint256 deposit,
        uint64 timestamp
    );

    event ChannelClosed(
        address node,
        address from
    );
}

/**
 * @title Channel manager contract with support for one-to-many payments.
 */
contract ChannelManager is IChannelManager {
    using SafeMath for uint256;

    // Structs benefit from using smaller variables as they are stored packed.
    struct Channel {
        address node;
        uint192 deposit;
        uint64 timestamp;
    }

    uint64 private _channelTimeout;

    ERC20MultiRecipient private _token;

    mapping (bytes32 => Channel) private _channels;

    /**
     * @param token Address of the ERC-20 compatible token contract.
     * @param channelTimeout Channel timeout in seconds.
     */
    constructor(address token, uint64 channelTimeout) public {
        _channelTimeout = channelTimeout;
        _token = ERC20MultiRecipient(token);
    }

    /**
     * @dev Opens a channel between a client and a manager node.
     * @param node Address of the manager node.
     * @param deposit Amount to deposit.
     */
    function openChannel(address node, uint256 deposit) public returns (bool) {
        require(node != address(0));
        require(node != msg.sender);
        require(deposit > 0);

        bytes32 key = _channelKey(msg.sender, node);

        if (_channels[key].timestamp == 0) {
            uint64 timestamp = uint64(block.timestamp);
            _channels[key] = Channel(node, uint192(deposit), timestamp);

            emit ChannelOpened(node, msg.sender, deposit, timestamp);

            _token.transferFrom(msg.sender, address(this), deposit);
        }

        return true;
    }

    /**
     * @dev Returns the deposit amount left for the caller&#39;s channel.
     * @param node Address of the manager node.
     * @return Creation timestamp and deposit of the channel.
     */
    function getChannel(address node) public view returns (uint64, uint256) {
        require(node != address(0));

        bytes32 key = _channelKey(msg.sender, node);
        return (_channels[key].timestamp, uint256(_channels[key].deposit));
    }

    /**
     * @dev Settles the channel provided the caller has a valid signature from channel&#39;s node.
     */
    function settleChannel(address node, address[] recipients, uint256[] values, bytes nodesig) public returns (bool) {
        require(node != address(0));
        require(recipients.length > 0);
        require(recipients.length == values.length);

        bytes32 key = _channelKey(msg.sender, node);

        require(_channels[key].timestamp > 0);
        require(_channels[key].node == node);

        address signer = _recoverAddress(recipients, values, nodesig);
        require(node == signer);

        _settleChannel(msg.sender, node, key, recipients, values);

        return true;
    }

    /**
     * @dev Closes the channel after the channel timed out provided the node has a valid signature from the client.
     */
    function closeChannel(address from, address[] recipients, uint256[] values, bytes clientsig) public returns (bool) {
        require(from != address(0));
        require(recipients.length > 0);
        require(recipients.length == values.length);

        bytes32 key = _channelKey(from, msg.sender);

        require(_channels[key].timestamp > 0);
        require(_channels[key].node == msg.sender);

        uint256 channelOpenTimestamp = block.timestamp.sub(_channels[key].timestamp);

        require(_channelTimeout < channelOpenTimestamp);

        address signer = _recoverAddress(recipients, values, clientsig);
        require(from == signer);

        _settleChannel(from, msg.sender, key, recipients, values);

        return true;
    }

    function _settleChannel(address from, address node, bytes32 key, address[] recipients, uint256[] values) private {
        uint256 total;

        for (uint256 i = 0; i < values.length; i++) {
            total = total.add(values[i]);
        }

        require(total <= _channels[key].deposit);

        uint256 refund = uint256(_channels[key].deposit).sub(total);

        delete _channels[key];
        emit ChannelClosed(node, from);

        _token.transferMulti(recipients, values);
        _token.transfer(from, refund);
    }

    function _channelKey(address from, address node) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(from, node));
    }

    function _recoverAddress(address[] recipients, uint256[] values, bytes signature) private pure returns (address) {
        require(signature.length == 0x41); // 0x20 + 0x20 + 0x01

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // First 32 bytes contain array length.
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))

            // Convert classic ECDSA recovery identifier to yellow paper variant.
            if lt(v, 0x1b) {
                v := add(v, 0x1b)
            }
        }

        require(v == 0x1b || v == 0x1c);

        bytes32 message = keccak256(abi.encodePacked(recipients, values));
        return ecrecover(message, v, r, s);
    }
}