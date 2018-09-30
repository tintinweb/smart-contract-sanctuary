pragma solidity 0.4.25;


/**
 * @title Safe maths
 * @author https://theethereum.wiki/w/index.php/ERC20_Token_Standard
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "Bad maths.");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "Bad maths.");
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b, "Bad maths.");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "Bad maths.");
        c = a / b;
    }
}


/**
 * @title ERC Token Standard #20 Interface
 * @author https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 * @notice This is the basic interface for ERC20 that ensures all required functions exist.
 * @dev https://theethereum.wiki/w/index.php/ERC20_Token_Standard
 */
contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


/**
 * @title Contract function to receive approval and execute function in one call
 * @author https://theethereum.wiki/w/index.php/ERC20_Token_Standard
 * @dev Borrowed from MiniMeToken
 */
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


/**
 * @title Owned Contract
 * @author https://theethereum.wiki/w/index.php/ERC20_Token_Standard
 * @notice Gives an inheriting contract the ability for certain functions to be
 *   called only by the owner of the system.
 */
contract Owned {
    address internal owner;
    address internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @notice Modifier indicates that the function can only be called by owner
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner may execute this function.");
        _;
    }

    /**
     * @notice Give the ownership to the address _newOwner. Change only takes
     *  place once the new owner accepts the ownership of this contract.
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    /**
     * @notice Delete owner information
     */
    function disown() public onlyOwner() {
        delete owner;
    }

    /**
     * @notice The new owner accepts responsibility of contract ownership
     *  by using this function.
     */
    function acceptOwnership() public {
        require(msg.sender == newOwner, "You have not been selected as the new owner.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}





/**
 * @title Snowden Token
 * @author David Edwards <Telecontrol Unterhaltungselektronik AG>
 * @notice This contract provides UltraUpload a token with which to
 *   trade and receive dividends.
 * @dev Heavily derivative of the ERC20 Token Standard
    https://theethereum.wiki/w/index.php/ERC20_Token_Standard
 */
contract SnowdenToken is ERC20Interface, Owned {
    using SafeMath for uint256;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 internal accountCount = 0;
    uint256 internal _totalSupply = 0;
    bool internal readOnly = false;
    uint256 internal constant MAX_256 = 2**256 - 1;
    mapping(address => bool) public ignoreDividend;

    event DividendGivenEvent(uint64 dividendPercentage);

    mapping(address => uint256) public freezeUntil;

    mapping(address => address) internal addressLinkedList;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    /**
     * @notice The token constructor. Creates the total supply.
     * @param supply The total number of coins to mint
     * @param addresses The addresses that will receive initial tokens
     * @param tokens The number of tokens that each address will receive
     * @param freezeList The unixepoch timestamp from which addresses are allowed to trade
     * @param ignoreList Addresses passed into this array will never receive dividends. The ignore list will always include this token contract.
     *
     * For example, if addresses is [ "0x1", "0x2" ], then tokens will need to have [ 1000, 8000 ] and freezeList will need to have [ 0, 0 ]. Numbers may change, but the values need to exist.
     */
    constructor(uint256 supply, address[] addresses, uint256[] tokens, uint256[] freezeList, address[] ignoreList) public {
        symbol = "SNOW";
        name = "Snowden";
        decimals = 0;
        _totalSupply = supply; // * 10**uint(decimals);
        balances[address(0)] = _totalSupply;

        uint256 totalAddresses = addresses.length;
        uint256 totalTokens = tokens.length;

        // Must have positive number of addresses and tokens
        require(totalAddresses > 0 && totalTokens > 0, "Must be a positive number of addresses and tokens.");

        // Require same number of addresses as tokens
        require(totalAddresses == totalTokens, "Must be tokens assigned to all addresses.");

        uint256 aggregateTokens = 0;

        for (uint256 i = 0; i < totalAddresses; i++) {
            // Do not allow empty tokens – although this would have no impact on
            // the mappings (a 0 count on the mapping will not result in a new entry).
            // It is better to break here to ensure that there was no input error.
            require(tokens[i] > 0, "No empty tokens allowed.");

            aggregateTokens = aggregateTokens + tokens[i];

            // Supply should always be more than the number of tokens given out!
            require(aggregateTokens <= supply, "Supply is not enough for demand.");

            giveReserveTo(addresses[i], tokens[i]);
            freezeUntil[addresses[i]] = freezeList[i];
        }

        ignoreDividend[address(this)] = true;
        ignoreDividend[msg.sender] = true;
        for (i = 0; i < ignoreList.length; i++) {
            ignoreDividend[ignoreList[i]] = true;
        }
    }

    /**
     * @notice Fallback function reverts all paid ether. Do not accept payments.
     */
    function () public payable {
        revert();
    }

    /**
     * @notice Total supply, including in reserve
     * @return The number of tokens in circulation
     */
    function totalSupply() public constant returns (uint256) {
        return _totalSupply; // (we use the local address to store the rest) - balances[address(0)];
    }

    /**
     * @notice Return a list of addresses and their tokens
     * @return Two arrays, the first a list of addresses, the second a list of
     *   token amounts. Each index matches the other.
     */
    function list() public view returns (address[], uint256[]) {
        address[] memory addrs = new address[](accountCount);
        uint256[] memory tokens = new uint256[](accountCount);

        uint256 i = 0;
        address current = addressLinkedList[0];
        while (current != 0) {
            addrs[i] = current;
            tokens[i] = balances[current];

            current = addressLinkedList[current];
            i++;
        }

        return (addrs, tokens);
    }

    /**
     * @notice Return the number of tokens not provisioned
     * @return The total number of tokens left in the reserve pool
     */
    function remainingTokens() public view returns(uint256) {
        return balances[address(0)];
    }

    /**
     * @return Is the contract set to readonly
     */
    function isReadOnly() public view returns(bool) {
        return readOnly;
    }

    /**
     * @notice Get the token balance for account `tokenOwner`
     * @param tokenOwner Address of the account to get the number of tokens for
     * @return The number of tokens the address has
     */
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }

    /**
     * @notice Ensure that account is allowed to trade
     * @param from Address of the account to send from
     * @return True if this trade is allowed
     */
    function requireTrade(address from) public view {
        require(!readOnly, "Read only mode engaged");

        uint256 i = 0;
        address current = addressLinkedList[0];
        while (current != 0) {
            if(current == from) {
                uint256 timestamp = freezeUntil[current];
                require(timestamp < block.timestamp, "Trades from your account are temporarily not possible. This is due to ICO rules.");

                break;
            }

            current = addressLinkedList[current];
            i++;
        }
    }

    /**
     * @notice Transfer the balance from token owner&#39;s account to `to` account
     *    - Owner&#39;s account must have sufficient balance to transfer
     *    - 0 value transfers are allowed
     * @param to Address to transfer tokens to
     * @param tokens Number of tokens to be transferred
     */
    function transfer(address to, uint256 tokens) public returns (bool success) {
        requireTrade(msg.sender);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);

        ensureInAccountList(to);

        return true;
    }

    /**
     * @notice Token owner can approve for `spender` to transferFrom(...) `tokens`
     *   from the token owner&#39;s account
     * @param spender address of the spender to approve
     * @param tokens Number of tokens to allow spender to spend
     * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
     *   recommends that there are no checks for the approval double-spend attack
     *   as this should be implemented in user interfaces
     */
    function approve(address spender, uint256 tokens) public returns (bool success) {
        requireTrade(msg.sender);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    /**
     * @notice Transfer `tokens` from the `from` account to the `to` account
     * @param from address to transfer tokens from
     * @param to address to transfer tokens to
     * @param tokens Number of tokens to transfer
     * @dev The calling account must already have sufficient tokens approve(...)-d
     *   for spending from the `from` account and
     *   - From account must have sufficient balance to transfer
     *   - Spender must have sufficient allowance to transfer
     *   - 0 value transfers are allowed
     */
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        requireTrade(from);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);

        ensureInAccountList(from);
        ensureInAccountList(to);

        return true;
    }

    /**
     * @notice Returns the amount of tokens approved by the owner that can be
     *   transferred to the spender&#39;s account
     * @param tokenOwner The address of the owner of the token
     * @param spender The address of the spender of the token
     * @return Number of tokens that are approved for spending from the tokenOwner
     */
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        requireTrade(tokenOwner);
        return allowed[tokenOwner][spender];
    }

    /**
     * @notice Token owner can approve for `spender` to transferFrom(...) `tokens`
     *   from the token owner&#39;s account. The `spender` contract function
     *   `receiveApproval(...)` is then executed
     * @param spender address with which to approve
     * @param tokens The number of tokens that this address is approved to take
     * @param data Pass data to receiveApproval
     */
    function approveAndCall(address spender, uint256 tokens, bytes data) public returns (bool success) {
        requireTrade(msg.sender);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    /**
     * @notice In the event of errors, allow the owner to move tokens from an account
     * @param addr address to take tokens from
     * @param tokens The number of tokens to take
     */
    function transferAnyERC20Token(address addr, uint256 tokens) public onlyOwner returns (bool success) {
        requireTrade(addr);
        return ERC20Interface(addr).transfer(owner, tokens);
    }

    /**
     * @notice Give tokens from the pool to account, creating the account if necessary
     * @param to The address to deliver the new tokens to
     * @param tokens The number of tokens to deliver
     */
    function giveReserveTo(address to, uint256 tokens) public onlyOwner {
        require(!readOnly, "Read only mode engaged");

        balances[address(0)] = balances[address(0)].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(address(0), to, tokens);

        ensureInAccountList(to);
    }

    /**
     * @notice Distribute dividends to all owners
     * @param percentage Given in the form 1% === 10000. This is not a number of
     *   tokens, more a form of percentage that does not require decimals. This
     *   supports 0.00001% (with 1 as the percentage value).
     * @dev Dividends are rounded down, if a user has too few tokens, they will not receive anything
     */
    function giveDividend(uint64 percentage) public onlyOwner {
        require(!readOnly, "Read only mode engaged");

        require(percentage > 0, "Percentage must be more than 0 (10000 = 1%)"); // At least 0.00001% dividends
        require(percentage <= 500000, "Percentage may not be larger than 500000 (50%)"); // No more than 50% dividends

        emit DividendGivenEvent(percentage);

        address current = addressLinkedList[0];
        while (current != 0) {
            bool found = ignoreDividend[current];
            if(!found) {
                uint256 extraTokens = (balances[current] * percentage) / 1000000;
                giveReserveTo(current, extraTokens);
            }
            current = addressLinkedList[current];
        }
    }

    /**
     * @notice Allow admins to (en|dis)able all write functionality for emergencies
     * @param enabled true to enable read only mode, false to allow writing
     */
    function setReadOnly(bool enabled) public onlyOwner {
        readOnly = enabled;
    }

    /**
     * @notice Add an account to a linked list
     * @param addr address of the account to add to the linked list
     * @dev This is necessary to iterate over for listing purposes
     */
    function addToAccountList(address addr) internal {
        require(!readOnly, "Read only mode engaged");

        addressLinkedList[addr] = addressLinkedList[0x0];
        addressLinkedList[0x0] = addr;
        accountCount++;
    }

    /**
     * @notice Remove an account from a linked list
     * @param addr address of the account to remove from the linked list
     * @dev This is necessary to iterate over for listing purposes
     */
    function removeFromAccountList(address addr) internal {
        require(!readOnly, "Read only mode engaged");

        uint16 i = 0;
        bool found = false;
        address parent;
        address current = addressLinkedList[0];
        while (true) {
            if (addressLinkedList[current] == addr) {
                parent = current;
                found = true;
                break;
            }
            current = addressLinkedList[current];

            if (i++ > accountCount) break;
        }

        require(found, "Account was not found to remove.");

        addressLinkedList[parent] = addressLinkedList[addressLinkedList[parent]];
        delete addressLinkedList[addr];

        if (balances[addr] > 0) {
            balances[address(0)] += balances[addr];
        }

        delete balances[addr];

        accountCount--;
    }

    /**
     * @notice Make sure that this address exists in our linked list
     * @param addr address of the account to test
     * @dev This is necessary to iterate over for listing purposes
     */
    function ensureInAccountList(address addr) internal {
        require(!readOnly, "Read only mode engaged");

        bool found = false;
        address current = addressLinkedList[0];
        while (current != 0) {
            if (current == addr) {
                found = true;
                break;
            }
            current = addressLinkedList[current];
        }
        if (!found) {
            addToAccountList(addr);
        }
    }
}