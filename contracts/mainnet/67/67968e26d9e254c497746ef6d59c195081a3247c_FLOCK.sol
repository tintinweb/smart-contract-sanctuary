pragma solidity ^0.4.21;

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


interface Token {
    function totalSupply() external view returns (uint _supply);
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function decimals() external view returns (uint8 _decimals);
    function balanceOf(address _owner) external view returns (uint _balance);
    function transfer(address _to, uint _tokens) external returns (bool _success);
    function transferFrom(address _from, address _to, uint _tokens) external returns (bool _success);

    function allowance(address _owner, address _spender) external view returns (uint _remaining);
    function approve(address _spender, uint _tokens) external returns (bool _success);

    event Transfer(address indexed _from, address indexed _to, uint _tokens, bytes indexed _data);
    event Approval(address indexed _owner, address indexed _spender, uint _tokens);
}

contract StandardToken is Token {
    using SafeMath for uint;

    function processTransfer(address _from, address _to, uint256 _value, bytes _data) internal returns (bool success) {
        if (balances[_from] >= _value && _value > 0) {
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);

            // ERC223 - ensure if we get told to transfer to a contract address
            // it must support tokenFallback method and approve the transfer.
            if (isContract(_to)) {
                iReceiver receiver = iReceiver(_to);
                receiver.tokenFallback(_from, _value, _data);
            }

            emit Transfer(_from, _to, _value, _data);
            return true;
        }
        return false;
    }

    /// @notice send `_value` token to `_to` from `msg.sender` with `_data`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @param _data Data to be logged and sent
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value, bytes _data) external returns (bool success) {
        return processTransfer(msg.sender, _to, _value, _data);
    }

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success) {
        bytes memory empty;
        return processTransfer(msg.sender, _to, _value, empty);
    }
    
    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        if (allowed[_from][msg.sender] >= _value) {
            bytes memory empty;
            return processTransfer(_from, _to, _value, empty);
        }
        return false;
    }

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    string public name;                   
    uint8 public decimals;                 
    string public symbol;                  
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    
    function totalSupply() external view returns (uint _supply) {
        return totalSupply;
    }
    
    function name() external view returns (string _name) {
        return name;
    }
    
    function symbol() external view returns (string _symbol) {
        return symbol;
    }
    
    function decimals() external view returns (uint8 _decimals) {
        return decimals;
    }

    function isContract(address _addr) internal view returns (bool _is_contract) {
        uint length;
        assembly {
            length := extcodesize(_addr)
        }
        return (length>0);
    }
}

contract FLOCK is StandardToken { // CHANGE THIS. Update the contract name.
    using SafeMath for uint;

    /* Public variables of the token */

    /*
        NOTE:
        The following variables are OPTIONAL vanities. One does not have to include them.
        They allow one to customise the token contract & in no way influences the core functionality.
        Some wallets/interfaces might not even bother to look at this information.
    */
    string public version = "H1.0"; 
    uint256 public totalEthInWei;         // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC). We&#39;ll store the total ETH raised via our ICO here.  
    address public fundsWallet;           // Where should the raised ETH go?

    Round[] rounds;
    struct Round {
        uint start;
        uint end;
        uint price;
    }

    // This is a constructor function 
    // which means the following function name has to match the contract name declared above
    function FLOCK() public {
        totalSupply = 10000000000;          // Update total supply
        balances[msg.sender] = totalSupply; // Give the creator all initial tokens.
        name = "FLOCK";                     // Set the name for display purposes
        decimals = 0;                       // Amount of decimals for display purposes
        symbol = "FLK";                     // Set the symbol for display purposes
        fundsWallet = msg.sender;           // The owner of the contract gets ETH

        uint ts = 1523764800;
        rounds.push(Round(ts, ts += 5 days, 500000)); // Round 1
        rounds.push(Round(ts, ts += 5 days, 500000)); // Round 2
        rounds.push(Round(ts, ts += 2 days, 250000)); // Round 3
        rounds.push(Round(ts, ts += 2 days, 166667)); // Round 4
        rounds.push(Round(ts, ts += 2 days, 125000)); // Round 5
        rounds.push(Round(ts, ts += 2 days, 100000)); // Round 6
        rounds.push(Round(ts, ts += 2 days, 83333)); // Round 7
        rounds.push(Round(ts, ts += 2 days, 71429)); // Round 8
        rounds.push(Round(ts, ts += 2 days, 62500)); // Round 9
        rounds.push(Round(ts, ts += 2 days, 55556)); // Round 10
        rounds.push(Round(ts, ts += 2 days, 50000)); // Round 11
    }

    /// @notice Gets the conversion rate for ETH purchases.
    /// @return Amount of tokens per ETH paid.
    function unitsOneEthCanBuy() public view returns (uint _units) {
        for (uint i = 0; i < rounds.length; i++) {
            Round memory round = rounds[i];
            if (block.timestamp >= round.start && block.timestamp < round.end) {
                return round.price;
            }
        }
        return 0;
    }

    /// @notice Accepts payment of eth in exchange for a variable amount of tokens, depending
    /// upon the conversion rate of the current sale round.
    function() external payable {
        uint ethInWei = msg.value;
        totalEthInWei = totalEthInWei + ethInWei;
        uint perEth = unitsOneEthCanBuy();
        
        // The following division is necessary to convert the number of decimal places in
        // eth(wei=`18`) and our number of `decimal` places, since we have `unitsPerEth`:
        uint256 amount = ethInWei.mul(perEth).div(10**uint(18 - decimals));

        require(amount > 0);
        require(balances[fundsWallet] >= amount);

        //Transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);                               

        bytes memory empty;
        processTransfer(fundsWallet, msg.sender, amount, empty);
    }

    /// @notice Approves and then calls the receiving contract
    function approveAndCall(address _spender, uint256 _value, bytes _data) external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        // Call the receiveApproval function on the contract you want to be notified.
        iApprover(_spender).receiveApproval(msg.sender, _value, address(this), _data);
        return true;
    }

    /// @notice Safety function so any accidentally sent ERC20 compliant tokens can be recovered.
    function reclaimERC20(address _token, uint _tokens) external returns (bool _success) {
        require(msg.sender == fundsWallet);
        return Token(_token).transfer(msg.sender, _tokens);
    }
}

interface iReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) external;
}

interface iApprover {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _data) external;
}