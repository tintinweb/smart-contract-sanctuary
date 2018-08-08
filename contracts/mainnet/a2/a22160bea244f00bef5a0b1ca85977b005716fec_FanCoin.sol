pragma solidity ^0.4.21;

// File: deploy/contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error.
 * Note, the div and mul methods were removed as they are not currently needed
 */
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: deploy/contracts/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: deploy/contracts/Stampable.sol

contract Stampable is ERC20 {
    using SafeMath for uint256;

    // A struct that represents a particular token balance
    struct TokenBalance {
        uint256 amount;
        uint index;
    }

    // A struct that represents a particular address balance
    struct AddressBalance {
        mapping (uint256 => TokenBalance) tokens;
        uint256[] tokenIndex;
    }

    // A mapping of address to balances
    mapping (address => AddressBalance) balances;

    // The total number of tokens owned per address
    mapping (address => uint256) ownershipCount;

    // Whitelist for addresses allowed to stamp tokens
    mapping (address => bool) public stampingWhitelist;

    /**
    * Modifier for only whitelisted addresses
    */
    modifier onlyStampingWhitelisted() {
        require(stampingWhitelist[msg.sender]);
        _;
    }

    // Event for token stamping
    event TokenStamp (address indexed from, uint256 tokenStamped, uint256 stamp, uint256 amt);

    /**
    * @dev Function to stamp a token in the msg.sender&#39;s wallet
    * @param _tokenToStamp uint256 The tokenId of theirs to stamp (0 for unstamped tokens)
    * @param _stamp uint256 The new stamp to apply
    * @param _amt uint256 The quantity of tokens to stamp
    */
    function stampToken (uint256 _tokenToStamp, uint256 _stamp, uint256 _amt)
        onlyStampingWhitelisted
        public returns (bool) {
        require(_amt <= balances[msg.sender].tokens[_tokenToStamp].amount);

        // Subtract balance of 0th token ID _amt value.
        removeToken(msg.sender, _tokenToStamp, _amt);

        // "Stamp" the token
        addToken(msg.sender, _stamp, _amt);

        // Emit the stamping event
        emit TokenStamp(msg.sender, _tokenToStamp, _stamp, _amt);

        return true;
    }

    function addToken(address _owner, uint256 _token, uint256 _amount) internal {
        // If they don&#39;t yet have any, assign this token an index
        if (balances[_owner].tokens[_token].amount == 0) {
            balances[_owner].tokens[_token].index = balances[_owner].tokenIndex.push(_token) - 1;
        }

        // Increase their balance of said token
        balances[_owner].tokens[_token].amount = balances[_owner].tokens[_token].amount.add(_amount);

        // Increase their ownership count
        ownershipCount[_owner] = ownershipCount[_owner].add(_amount);
    }

    function removeToken(address _owner, uint256 _token, uint256 _amount) internal {
        // Decrease their ownership count
        ownershipCount[_owner] = ownershipCount[_owner].sub(_amount);

        // Decrease their balance of the token
        balances[_owner].tokens[_token].amount = balances[_owner].tokens[_token].amount.sub(_amount);

        // If they don&#39;t have any left, remove it
        if (balances[_owner].tokens[_token].amount == 0) {
            uint index = balances[_owner].tokens[_token].index;
            uint256 lastCoin = balances[_owner].tokenIndex[balances[_owner].tokenIndex.length - 1];
            balances[_owner].tokenIndex[index] = lastCoin;
            balances[_owner].tokens[lastCoin].index = index;
            balances[_owner].tokenIndex.length--;
            // Make sure the user&#39;s token is removed
            delete balances[_owner].tokens[_token];
        }
    }
}

// File: deploy/contracts/FanCoin.sol

contract FanCoin is Stampable {
    using SafeMath for uint256;

    // The owner of this token
    address public owner;

    // Keeps track of allowances for particular address. - ERC20 Method
    mapping (address => mapping (address => uint256)) public allowed;

    event TokenTransfer (address indexed from, address indexed to, uint256 tokenId, uint256 value);
    event MintTransfer  (address indexed from, address indexed to, uint256 originalTokenId, uint256 tokenId, uint256 value);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
    * The constructor for the FanCoin token
    */
    function FanCoin() public {
        owner = 0x7DDf115B8eEf3058944A3373025FB507efFAD012;
        name = "FanChain";
        symbol = "FANZ";
        decimals = 4;

        // Total supply is one billion tokens
        totalSupply = 6e8 * uint256(10) ** decimals;

        // Add the owner to the stamping whitelist
        stampingWhitelist[owner] = true;

        // Initially give all of the tokens to the owner
        addToken(owner, 0, totalSupply);
    }

    /** ERC 20
    * @dev Retrieves the balance of a specified address
    * @param _owner address The address to query the balance of.
    * @return A uint256 representing the amount owned by the _owner
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipCount[_owner];
    }

    /**
    * @dev Retrieves the balance of a specified address for a specific token
    * @param _owner address The address to query the balance of
    * @param _tokenId uint256 The token being queried
    * @return A uint256 representing the amount owned by the _owner
    */
    function balanceOfToken(address _owner, uint256 _tokenId) public view returns (uint256 balance) {
        return balances[_owner].tokens[_tokenId].amount;
    }

    /**
    * @dev Returns all of the tokens owned by a particular address
    * @param _owner address The address to query
    * @return A uint256 array representing the tokens owned
    */
    function tokensOwned(address _owner) public view returns (uint256[] tokens) {
        return balances[_owner].tokenIndex;
    }

    /** ERC 20
    * @dev Transfers tokens to a specific address
    * @param _to address The address to transfer tokens to
    * @param _value unit256 The amount to be transferred
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= totalSupply);
        require(_value <= ownershipCount[msg.sender]);

        // Cast the value as the ERC20 standard uses uint256
        uint256 _tokensToTransfer = uint256(_value);

        // Do the transfer
        require(transferAny(msg.sender, _to, _tokensToTransfer));

        // Notify that a transfer has occurred
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
    * @dev Transfer a specific kind of token to another address
    * @param _to address The address to transfer to
    * @param _tokenId address The type of token to transfer
    * @param _value uint256 The number of tokens to transfer
    */
    function transferToken(address _to, uint256 _tokenId, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender].tokens[_tokenId].amount);

        // Do the transfer
        internalTransfer(msg.sender, _to, _tokenId, _value);

        // Notify that a transfer happened
        emit TokenTransfer(msg.sender, _to, _tokenId, _value);
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
    * @dev Transfer a list of token kinds and values to another address
    * @param _to address The address to transfer to
    * @param _tokenIds uint256[] The list of tokens to transfer
    * @param _values uint256[] The list of amounts to transfer
    */
    function transferTokens(address _to, uint256[] _tokenIds, uint256[] _values) public returns (bool) {
        require(_to != address(0));
        require(_tokenIds.length == _values.length);
        require(_tokenIds.length < 100); // Arbitrary limit

        // Do verification first
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(_values[i] > 0);
            require(_values[i] <= balances[msg.sender].tokens[_tokenIds[i]].amount);
        }

        // Transfer every type of token specified
        for (i = 0; i < _tokenIds.length; i++) {
            require(internalTransfer(msg.sender, _to, _tokenIds[i], _values[i]));
            emit TokenTransfer(msg.sender, _to, _tokenIds[i], _values[i]);
            emit Transfer(msg.sender, _to, _values[i]);
        }

        return true;
    }

    /**
    * @dev Transfers the given number of tokens regardless of how they are stamped
    * @param _from address The address to transfer from
    * @param _to address The address to transfer to
    * @param _value uint256 The number of tokens to send
    */
    function transferAny(address _from, address _to, uint256 _value) private returns (bool) {
        // Iterate through all of the tokens owned, and transfer either the
        // current balance of that token, or the remaining total amount to be
        // transferred (`_value`), whichever is smaller. Because tokens are completely removed
        // as their balances reach 0, we just run the loop until we have transferred all
        // of the tokens we need to
        uint256 _tokensToTransfer = _value;
        while (_tokensToTransfer > 0) {
            uint256 tokenId = balances[_from].tokenIndex[0];
            uint256 tokenBalance = balances[_from].tokens[tokenId].amount;

            if (tokenBalance >= _tokensToTransfer) {
                require(internalTransfer(_from, _to, tokenId, _tokensToTransfer));
                _tokensToTransfer = 0;
            } else {
                _tokensToTransfer = _tokensToTransfer - tokenBalance;
                require(internalTransfer(_from, _to, tokenId, tokenBalance));
            }
        }

        return true;
    }

    /**
    * Internal function for transferring a specific type of token
    */
    function internalTransfer(address _from, address _to, uint256 _tokenId, uint256 _value) private returns (bool) {
        // Decrease the amount being sent first
        removeToken(_from, _tokenId, _value);

        // Increase receivers token balances
        addToken(_to, _tokenId, _value);

        return true;
    }

    /** ERC 20
    * @dev Transfer on behalf of another address
    * @param _from address The address to send tokens from
    * @param _to address The address to send tokens to
    * @param _value uint256 The amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= ownershipCount[_from]);
        require(_value <= allowed[_from][msg.sender]);

        // Get the uint256 version of value
        uint256 _castValue = uint256(_value);

        // Decrease the spending limit
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        // Actually perform the transfer
        require(transferAny(_from, _to, _castValue));

        // Notify that a transfer has occurred
        emit Transfer(_from, _to, _value);

        return true;
    }

    /**
    * @dev Transfer and stamp tokens from a mint in one step
    * @param _to address To send the tokens to
    * @param _tokenToStamp uint256 The token to stamp (0 is unstamped tokens)
    * @param _stamp uint256 The new stamp to apply
    * @param _amount uint256 The number of tokens to stamp and transfer
    */
    function mintTransfer(address _to, uint256 _tokenToStamp, uint256 _stamp, uint256 _amount) public
        onlyStampingWhitelisted returns (bool) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender].tokens[_tokenToStamp].amount);

        // Decrease the amount being sent first
        removeToken(msg.sender, _tokenToStamp, _amount);

        // Increase receivers token balances
        addToken(_to, _stamp, _amount);

        emit MintTransfer(msg.sender, _to, _tokenToStamp, _stamp, _amount);
        emit Transfer(msg.sender, _to, _amount);

        return true;
    }

    /**
     * @dev Add an address to the whitelist
     * @param _addr address The address to add
     */
    function addToWhitelist(address _addr) public
        onlyOwner {
        stampingWhitelist[_addr] = true;
    }

    /**
     * @dev Remove an address from the whitelist
     * @param _addr address The address to remove
     */
    function removeFromWhitelist(address _addr) public
        onlyOwner {
        stampingWhitelist[_addr] = false;
    }

    /** ERC 20
    * @dev Approve sent address to spend the specified amount of tokens on
    * behalf of msg.sender
    *
    * See https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * for any potential security concerns
    *
    * @param _spender address The address that will spend funds
    * @param _value uint256 The number of tokens they are allowed to spend
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /** ERC 20
    * @dev Returns the amount a spender is allowed to spend for a particular
    * address
    * @param _owner address The address which owns the funds
    * @param _spender address The address which will spend the funds.
    * @return uint256 The number of tokens still available for the spender
    */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /** ERC 20
    * @dev Increases the number of tokens a spender is allowed to spend for
    * `msg.sender`
    * @param _spender address The address of the spender
    * @param _addedValue uint256 The amount to increase the spenders approval by
    */
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /** ERC 20
    * @dev Decreases the number of tokens a spender is allowed to spend for
    * `msg.sender`
    * @param _spender address The address of the spender
    * @param _subtractedValue uint256 The amount to decrease the spenders approval by
    */
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint _value = allowed[msg.sender][_spender];
        if (_subtractedValue > _value) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = _value.sub(_subtractedValue);
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}