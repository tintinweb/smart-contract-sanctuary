/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// File: contracts/exchange.sol


pragma solidity 0.8.7;

contract TokenExchange {
    // Hashmap of all tokens to their prices
    mapping(address => uint256) private tokenPrices;

    // Retrieves the current price of the baseToken
    function getBaseTokenPrice(address baseTokenAddress) public view returns (uint256)
    {
        return tokenPrices[baseTokenAddress];
    }
    
    //This is a helper function to help the user see what the cost to exercise an option is currently before they do so
    //Updates lastestCost member of option which is publicly viewable
    function setBaseTokenPrice(address baseTokenAddress, uint256 baseTokenPrice) public {
        tokenPrices[baseTokenAddress] = baseTokenPrice;
    }
}
// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: contracts/ERC20_own.sol


pragma solidity 0.8.7;

contract ERC20 {
    // MAXSUPPLY, supply, fee and minter
    // We use uint256 because it’s most efficient data type in solidity
    // The EVM works with 256bit and if data is smaller
    // further operations are needed to downscale it from 256bit.
    // The variables are private by convention and getters/setters can
    // be used to retrieve or amend them.
    uint256 constant private fee = 0;
    uint256 constant private MAXSUPPLY = 1000000;
    uint256 private supply = 50000;
    address private minter;

    // Event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Event to be emitted on mintership transfer
    event MintershipTransfer(address indexed previousMinter, address indexed newMinter);

    // Mapping for balances
    mapping (address => uint) public balances;

    // Mapping for allowances
    mapping (address => mapping(address => uint)) public allowances;

    constructor() {
        // Sender's balance gets set to total supply and sender gets assigned as minter
        balances[msg.sender] = supply;
        minter = msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        // Returns total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // Returns the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // Mint tokens by updating receiver's balance and total supply
        // Total supply must not exceed MAXSUPPLY
        // The sender needs to be the current minter to mint more tokens
        require(msg.sender == minter, "Sender is not the current minter");
        require(totalSupply() + amount <= MAXSUPPLY, "The added supply will exceed the max supply");
        supply += amount;
        balances[receiver] += amount;
        emit Transfer(address(0), receiver, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // Burn tokens by sending tokens to address(0)
        // Must have enough balance to burn
        require(balances[msg.sender] >= amount, "Insufficient balance to burn");
        supply -= amount;
        balances[address(0)] += amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // Transfer mintership to newminter
        // Only incumbent minter can transfer mintership
        // Should emit MintershipTransfer event
        require(msg.sender == minter, "Sender is not the current minter");
        minter = newMinter;
        emit MintershipTransfer(minter, newMinter);
        return true;
    }

    function doTransfer(address _from, address _to, uint256 _value) private returns (bool) {
        // Private method to avoid code duplication between transfer and transferFrom
        // Transfer `_value` tokens from _from to _to
        // _from needs to have enough tokens
        // Transfer value needs to be sufficient to cover fee
        // Emit events for sending to _to and to minter
        require(balances[_from] >= _value, "Insufficient balance");
        require(fee < _value, "Cover fee exceeds the transfer value");
        balances[_from] -= _value;
        balances[_to] += _value - fee;
        balances[minter] += fee;
        emit Transfer(_from, _to, _value - fee);
        emit Transfer(_from, minter, fee);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // Transfer `_value` tokens from sender to `_to`
        return doTransfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // Transfer `_value` tokens from `_from` to `_to`
        // `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        require(allowances[_from][msg.sender] >= _value, "Insufficient allowance");
        bool response = doTransfer(_from, _to, _value);
        allowances[_from][msg.sender] -= _value;
        return response;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // Allow `_spender` to spend `_value` on sender's behalf
        // If an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        // Return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowances[_owner][_spender];
    }
}
// File: contracts/options.sol


pragma solidity 0.8.7;



contract DecentralisedOption {    
    address payable contractAddr;

    address private underlyingTokenAddress;
    address private tokenExchange;

    uint private strike;
    uint private premium;
    uint private expiry;
    
    uint256 constant private MAXSUPPLY = 1000;

    mapping (address => uint) public balances;

    // Mapping containing the numbers of options written by each address
    mapping(address => uint256) public writers;

        // Total number of options outstanding
    uint256 public totalOptions = 0;

    // Total amount of baseToken collected on option exercise and held by this contract
    uint256 public totalBaseToken = 0;

    // Total number of options written
    uint256 public totalWritten = 0;

    // Total number of options withdrawn after expiration
    uint256 public totalWithdrawn = 0;

    // Total number of options exercised
    uint256 public totalExercised = 0;

    //Kovan feeds: https://docs.chain.link/docs/reference-contracts
    constructor(address _underlyingTokenAddress, uint _strike, uint _premium, uint _expiry, address _tokenExchange) {
        contractAddr = payable(address(this));
        underlyingTokenAddress = _underlyingTokenAddress;
        strike = _strike;
        premium = _premium;
        expiry = _expiry;
        tokenExchange = _tokenExchange;
    }
  
    //Purchase a call option, needs desired token, ID of option and payment
    function buyOption(address writer) public payable {
        // Transfer premium payment from buyer to writer
        // Need to authorize the contract to transfer funds on your behalf
        require(msg.value == premium, "Incorrect amount of ETH sent for premium");
        payable(writer).transfer(premium);

        require(ERC20(underlyingTokenAddress).transferFrom(writer, contractAddr, 1), "Incorrect amount of TOKEN supplied");
        
        // Increment balances
        balances[msg.sender] += 1;
        writers[writer] += 1;

        // Increment totals
        totalOptions += 1;
        totalWritten += 1;
    }
    
    // Exercise your call option, needs desired token, ID of option and payment
    function exercise() public payable {
        // If not expired and not already exercised, allow option owner to exercise
        // To exercise, the strike value*amount equivalent paid to writer (from buyer) and amount of tokens in the contract paid to buyer
        require(expiry >= block.timestamp, "Option is expired");
        
        // require that buyer has at least one option address
        require(balances[msg.sender] >= 1);

        uint256 exerciseVal = strike;
        require(msg.value == exerciseVal, "Incorrect ETH amount sent to exercise");

        // Buyer exercises option, exercise cost paid to writer
        contractAddr.transfer(exerciseVal);
        
        // Pay buyer contract amount of TOKEN
        require(ERC20(underlyingTokenAddress).transfer(msg.sender, 1), "Error: buyer was not paid");
    
        // Deduct balance
        balances[msg.sender] -= 1;
        
        // Update totals
        totalExercised -= 1;
        totalOptions -= 1;
        totalBaseToken -= 1;
    }
            
    //Allows writer to retrieve funds from an expired, non-exercised, non-canceled option
    function retrieveExpiredFunds(address writer) public {
        uint256 balance = writers[writer];
        require(block.timestamp > expiry);
        require(balance > 0);

        // Zero the writer's written balance
        writers[writer] = 0;

        uint underlyingTokenAmount = totalOptions * balance / totalWritten;

        uint baseTokenAmount = totalBaseToken * balance / totalWritten;

        if (underlyingTokenAmount > 0) {
            require(ERC20(underlyingTokenAddress).transfer(writer, underlyingTokenAmount));
        }

        if (baseTokenAmount > 0) {
            payable(writer).transfer(baseTokenAmount);
        }
        
        totalWithdrawn += balance;
    }

    // ---------------------
    // ------- ERC20 -------
    // ---------------------

    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address to, uint value ) public returns (bool) {
        if (balances[msg.sender] >= value) {
            balances[msg.sender] -= value;
            balances[to] += value;
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint value) public returns (bool) {
        if (balances[from] >= value && allowed[from][msg.sender] >= value) {
            balances[to] += value;
            balances[from] -= value;
            allowed[from][msg.sender] -= value;
            return true;
        } else {
            return false;
        }
    }

    function approve(address spender, uint value) public returns (bool) {
      allowed[msg.sender][spender] = value;
      return true;
    }

    function totalSupply() view public returns (uint) {
        return totalOptions;
    }

    function balanceOf(address who) view public returns (uint) {
        return balances[who];
    }

    function allowance(address owner, address spender) view public returns (uint) {
        return allowed[owner][spender];
    }

    function name() view public returns (string memory) {
        return string(abi.encodePacked("UCL Option", "\nUnderlying: ", underlyingTokenAddress, "\nStrike: ", Strings.toString(strike), "\nPremium: ", Strings.toString(premium)));
    }

    function mint() private returns (bool) {
        // Mint tokens by updating receiver's balance and total supply
        // Total supply must not exceed MAXSUPPLY
        // The sender needs to be the current minter to mint more tokens
        //require(msg.sender == minter, "Sender is not the current minter");
        require(totalSupply() + 1 <= MAXSUPPLY, "The added supply will exceed the max supply");
        totalOptions += 1;
        balances[msg.sender] += 1;
        return true;
    }

    function burn() private returns (bool) {
        // Burn tokens by sending tokens to address(0)
        // Must have enough balance to burn
        require(balances[msg.sender] >= 1, "Insufficient balance to burn");
        totalOptions -= 1;
        balances[address(0)] += 1;
        balances[msg.sender] -= 1;
        return true;
    }
}

// why the writer didn't receive the exercised price?
// how to do a put option?

// create the options with constructor specifying premium, price, etc
// so that we can trade them to people and they can see that they own them
// they will be traded like any other erc20 token with fixed premium, etc.
// create a contract to create such options



// File: contracts/creator.sol


pragma solidity 0.8.7;



contract DerivativeCreator {

    address private tokenExchange;

    // Mapping storing all token options in existence
    mapping(bytes32 => address) tokenOpts;

    constructor() {
        tokenExchange = address(new TokenExchange());
    }

    /**
     * Create a new type of covered option
     * Will create a new CoveredOption smart contract and return its address
     *
     * @param  underlyingToken            The address of the underlying token used in the option
     * @param  expirationTimestamp        A timestamp indicating the expiration date of the option
     * @param  underlyingTokenStrikePrice  The underlyingToken half of the exchange rate for
     *                                    the strike price of the option. Exchange rate
     *                                    must be specified in simplest form
     * @return _option                    The address of the new option contract
     */
    function createCoveredOption(
        address underlyingToken,
        uint256 underlyingTokenStrikePrice,
        uint256 premium,
        uint256 expirationTimestamp
    ) public returns (address _option) {
        bytes32 optionHash = keccak256(abi.encodePacked(
            underlyingToken,
            underlyingTokenStrikePrice,
            premium,
            expirationTimestamp,
            tokenExchange
        ));

        require(tokenOpts[optionHash] == address(0));

        address option = address(new DecentralisedOption(
            underlyingToken,
            underlyingTokenStrikePrice,
            premium,
            expirationTimestamp,
            tokenExchange
        ));

        tokenOpts[optionHash] = option;

        return option;
    }

    // -------------------------------------
    // ----- Public Constant Functions -----
    // -------------------------------------

    /**
     * Get the address of a covered option contract. Will return the 0 address if none exists
     *
     * @param  underlyingToken            The address of the underlying token used in the option
     * @param  expirationTimestamp        A timestamp indicating the expiration date of the option
     * @param  underlyingTokenStrikePrice  The underlyingToken half of the exchange rate for
     *                                    the strike price of the option. Exchange rate
     *                                    must be specified in simplest form
     * @return _option                    The address of the option contract
     */
    function getCoveredOption(
        address underlyingToken,
        uint256 underlyingTokenStrikePrice,
        uint256 premium,
        uint256 expirationTimestamp
        
    ) view public returns(
        address _option
    ) {
        bytes32 optionHash = keccak256(abi.encodePacked(
            underlyingToken,
            underlyingTokenStrikePrice,
            premium,
            expirationTimestamp,
            tokenExchange
        ));

        return tokenOpts[optionHash];
    }

    function getTokenExchange() view public returns(address) {
        return tokenExchange;
    }
}