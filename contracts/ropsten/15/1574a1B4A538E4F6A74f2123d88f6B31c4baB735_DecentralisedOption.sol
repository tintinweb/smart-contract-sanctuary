/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

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
    
    mapping (address => uint) private balances;

    // Mapping containing the numbers of options written by each address
    mapping(address => uint256) private writers;

    //Options stored in arrays of structs
    struct option {
        address underlyingToken;
        uint256 strike; 
        uint256 premium; //Fee in contract token that option writer charges
        uint256 expiry; //Unix timestamp of expiration time
        uint256 totalWritten; // Total number of options written
        uint256 totalExercised; // Total number of options exercised
        uint256 totalWithdrawn; // Total number of options withdrawn after expiration
        uint256 totalActiveOptions;
        uint256 totalUnderlyingToken; // Total number of options outstanding
        uint256 totalBaseToken; // Total amount of baseToken collected on option exercise and held by this contract
    }

    option private tokenOpt;

    constructor(address _underlyingTokenAddress, uint _strike, uint _premium, uint _expiry) {
        contractAddr = payable(address(this));
        tokenOpt = option(_underlyingTokenAddress, _strike, _premium, _expiry, 0, 0, 0, 0, 0, 0);
    }
  
    //Purchase a call option, needs desired token, ID of option and payment
    function buyOption(address writer) public payable {
        // Transfer premium payment from buyer to writer
        // Need to authorize the contract to transfer funds on your behalf
        require(msg.value == tokenOpt.premium, "Incorrect amount of ETH sent for premium");
        payable(writer).transfer(tokenOpt.premium);

        require(ERC20(tokenOpt.underlyingToken).transferFrom(writer, contractAddr, 1), "Incorrect amount of TOKEN supplied");
        
        // Increment balances
        balances[msg.sender] += 1;
        writers[writer] += 1;

        // Increment totals
        tokenOpt.totalUnderlyingToken += 1;
        tokenOpt.totalActiveOptions += 1;
        tokenOpt.totalWritten += 1;
    }
    
    // Exercise your call option, needs desired token, ID of option and payment
    function exercise() public payable {
        // If not expired and not already exercised, allow option owner to exercise
        // To exercise, the strike value*amount equivalent paid to writer (from buyer) and amount of tokens in the contract paid to buyer
        require(tokenOpt.expiry >= block.timestamp, "Option is expired");
        
        // require that buyer has at least one option address
        require(balances[msg.sender] >= 1);

        uint256 exerciseVal = tokenOpt.strike;
        require(msg.value == exerciseVal, "Incorrect ETH amount sent to exercise");
        
        // Pay buyer contract amount of TOKEN
        require(ERC20(tokenOpt.underlyingToken).transfer(msg.sender, 1), "Error: buyer was not paid");
    
        // Deduct balance
        balances[msg.sender] -= 1;
        
        // Update totals
        tokenOpt.totalExercised += 1;
        tokenOpt.totalActiveOptions -= 1;
        tokenOpt.totalUnderlyingToken -= 1;
        tokenOpt.totalBaseToken += exerciseVal;
    }
            
    //Allows writer to retrieve funds from an expired, non-exercised, non-canceled option
    function retrieveExpiredFunds(address writer) public {
        uint256 balance = writers[writer];
        require(block.timestamp > tokenOpt.expiry, "The option has not expired");
        require(balance > 0);

        // Zero the writer's written balance
        writers[writer] = 0;

        // TODO: Rounding error in the division
        uint underlyingTokenAmount = tokenOpt.totalActiveOptions * balance / tokenOpt.totalWritten;
        uint baseTokenAmount = tokenOpt.totalBaseToken * balance / tokenOpt.totalWritten;

        if (underlyingTokenAmount > 0) {
            require(ERC20(tokenOpt.underlyingToken).transfer(writer, underlyingTokenAmount));
        }

        if (baseTokenAmount > 0) {
            payable(writer).transfer(baseTokenAmount);
        }
        
        tokenOpt.totalWithdrawn += balance;
    }

    function writtenBy(address who) view public returns (uint256) {
        return writers[who];
    }

    function balanceOf(address who) view public returns (uint256) {
        return balances[who];
    }

    function getOptionProperties() public view returns (option memory) {
        return tokenOpt;
    }

    function getActiveUnderlyingTokenBalance() public view returns (uint256) {
        return tokenOpt.totalActiveOptions;
    }

    function getActiveBaseTokenBalance() public view returns (uint256) {
        return address(this).balance;
    }
}