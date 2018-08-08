pragma solidity ^0.4.18;

    /**
    * Math operations with safety checks
    */
    library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    }


    contract Owned {

        /// @dev `owner` is the only address that can call a function with this
        /// modifier
        modifier onlyOwner() {
            require(msg.sender == owner);
            _;
        }

        address public owner;
        /// @notice The Constructor assigns the message sender to be `owner`
        function Owned() public {
            owner = msg.sender;
        }

        address public newOwner;

        /// @notice `owner` can step down and assign some other address to this role
        /// @param _newOwner The address of the new owner. 0x0 can be used to create
        ///  an unowned neutral vault, however that cannot be undone
        function changeOwner(address _newOwner) onlyOwner public {
            newOwner = _newOwner;
        }


        function acceptOwnership() public {
            if (msg.sender == newOwner) {
                owner = newOwner;
            }
        }
    }


    contract ERC20Protocol {
        /* This is a slight change to the ERC20 base standard.
        function totalSupply() constant returns (uint supply);
        is replaced with:
        uint public totalSupply;
        This automatically creates a getter function for the totalSupply.
        This is moved to the base contract since public getter functions are not
        currently recognised as an implementation of the matching abstract
        function by the compiler.
        */
        /// total amount of tokens
        uint public totalSupply;

        /// @param _owner The address from which the balance will be retrieved
        /// @return The balance
        function balanceOf(address _owner) constant public returns (uint balance);

        /// @notice send `_value` token to `_to` from `msg.sender`
        /// @param _to The address of the recipient
        /// @param _value The amount of token to be transferred
        /// @return Whether the transfer was successful or not
        function transfer(address _to, uint _value) public returns (bool success);

        /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
        /// @param _from The address of the sender
        /// @param _to The address of the recipient
        /// @param _value The amount of token to be transferred
        /// @return Whether the transfer was successful or not
        function transferFrom(address _from, address _to, uint _value) public returns (bool success);

        /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
        /// @param _spender The address of the account able to transfer the tokens
        /// @param _value The amount of tokens to be approved for transfer
        /// @return Whether the approval was successful or not
        function approve(address _spender, uint _value) public returns (bool success);

        /// @param _owner The address of the account owning tokens
        /// @param _spender The address of the account able to transfer the tokens
        /// @return Amount of remaining tokens allowed to spent
        function allowance(address _owner, address _spender) constant public returns (uint remaining);

        event Transfer(address indexed _from, address indexed _to, uint _value);
        event Approval(address indexed _owner, address indexed _spender, uint _value);
    }

    contract StandardToken is ERC20Protocol {
        using SafeMath for uint;

        /**
        * @dev Fix for the ERC20 short address attack.
        */
        modifier onlyPayloadSize(uint size) {
            require(msg.data.length >= size + 4);
            _;
        }

        function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) public returns (bool success) {
            //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
            //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
            //Replace the if with this one instead.
            //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            if (balances[msg.sender] >= _value) {
                balances[msg.sender] -= _value;
                balances[_to] += _value;
                Transfer(msg.sender, _to, _value);
                return true;
            } else { return false; }
        }

        function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) public returns (bool success) {
            //same as above. Replace this line with the following if you want to protect against wrapping uints.
            //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
                balances[_to] += _value;
                balances[_from] -= _value;
                allowed[_from][msg.sender] -= _value;
                Transfer(_from, _to, _value);
                return true;
            } else { return false; }
        }

        function balanceOf(address _owner) constant public returns (uint balance) {
            return balances[_owner];
        }

        function approve(address _spender, uint _value) onlyPayloadSize(2 * 32) public returns (bool success) {
            // To change the approve amount you first have to reduce the addresses`
            //  allowance to zero by calling `approve(_spender, 0)` if it is not
            //  already 0 to mitigate the race condition described here:
            //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
            assert((_value == 0) || (allowed[msg.sender][_spender] == 0));

            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        }

        function allowance(address _owner, address _spender) constant public returns (uint remaining) {
        return allowed[_owner][_spender];
        }

        mapping (address => uint) balances;
        mapping (address => mapping (address => uint)) allowed;
    }

    contract SharesChainToken is StandardToken {
        /// Constant token specific fields
        string public constant name = "SharesChainToken";
        string public constant symbol = "SCTK";
        uint public constant decimals = 18;

        /// SharesChain total tokens supply
        uint public constant MAX_TOTAL_TOKEN_AMOUNT = 20000000000 ether;

        /// Fields that are only changed in constructor
        /// SharesChain contribution contract
        address public minter;

        /*
        * MODIFIERS
        */

        modifier onlyMinter {
            assert(msg.sender == minter);
            _;
        }

        modifier maxTokenAmountNotReached (uint amount){
            assert(totalSupply.add(amount) <= MAX_TOTAL_TOKEN_AMOUNT);
            _;
        }

        /**
        * CONSTRUCTOR
        *
        * @dev Initialize the SharesChain Token
        * @param _minter The SharesChain Crowd Funding Contract
        */
        function SharesChainToken(address _minter) public {
            minter = _minter;
        }


        /**
        * EXTERNAL FUNCTION
        *
        * @dev Contribution contract instance mint token
        * @param recipient The destination account owned mint tokens
        * be sent to this address.
        */
        function mintToken(address recipient, uint _amount)
            public
            onlyMinter
            maxTokenAmountNotReached(_amount)
            returns (bool)
        {
            totalSupply = totalSupply.add(_amount);
            balances[recipient] = balances[recipient].add(_amount);
            return true;
        }
    }