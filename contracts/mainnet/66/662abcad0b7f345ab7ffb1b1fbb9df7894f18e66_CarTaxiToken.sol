pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {

    uint constant DAY_IN_SECONDS = 86400;
    uint constant BASE = 1000000000000000000;
    uint constant preIcoPrice = 4101;
    uint constant icoPrice = 2255;

    function mul(uint256 a, uint256 b) constant internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) constant internal returns (uint256) {
        assert(b != 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) constant internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) constant internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mulByFraction(uint256 number, uint256 numerator, uint256 denominator) internal returns (uint256) {
        return div(mul(number, numerator), denominator);
    }

    // presale volume bonus calculation 
    function presaleVolumeBonus(uint256 price) internal returns (uint256) {

        // preCTX > ETH
        uint256 val = div(price, preIcoPrice);

        if(val >= 100 * BASE) return add(price, price * 1/20); // 5%
        if(val >= 50 * BASE) return add(price, price * 3/100); // 3%
        if(val >= 20 * BASE) return add(price, price * 1/50);  // 2%

        return price;
    }

	// ICO volume bonus calculation 
    function volumeBonus(uint256 etherValue) internal returns (uint256) {
		
        if(etherValue >= 1000000000000000000000) return 15;// +15% tokens
        if(etherValue >=  500000000000000000000) return 10; // +10% tokens
        if(etherValue >=  300000000000000000000) return 7;  // +7% tokens
        if(etherValue >=  100000000000000000000) return 5;  // +5% tokens
        if(etherValue >=   50000000000000000000) return 3;   // +3% tokens
        if(etherValue >=   20000000000000000000) return 2;   // +2% tokens

        return 0;
    }

	// ICO date bonus calculation 
    function dateBonus(uint startIco) internal returns (uint256) {

        // day from ICO start
        uint daysFromStart = (now - startIco) / DAY_IN_SECONDS + 1;

        if(daysFromStart == 1) return 15; // +15% tokens
        if(daysFromStart == 2) return 10; // +10% tokens
        if(daysFromStart == 3) return 10; // +10% tokens
        if(daysFromStart == 4) return 5;  // +5% tokens
        if(daysFromStart == 5) return 5;  // +5% tokens
        if(daysFromStart == 6) return 5;  // +5% tokens

		// no discount
        return 0;
    }

}


/// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
/// @title Abstract token contract - Functions to be implemented by token contracts.

contract AbstractToken {
    // This is not an abstract function, because solc won&#39;t recognize generated getter functions for public variables as functions
    function totalSupply() constant returns (uint256) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}

contract StandardToken is AbstractToken {
    /*
     *  Data structures
     */
    mapping (address => uint256) balances;
    mapping (address => bool) ownerAppended;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    address[] public owners;

    /*
     *  Read and write storage functions
     */
    /// @dev Transfers sender&#39;s tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            if(!ownerAppended[_to]) {
                ownerAppended[_to] = true;
                owners.push(_to);
            }
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            if(!ownerAppended[_to]) {
                ownerAppended[_to] = true;
                owners.push(_to);
            }
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
     * Read storage functions
     */
    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}


contract CarTaxiToken is StandardToken, SafeMath {
    /*
     * Token meta data
     */
    string public constant name = "CarTaxi";
    string public constant symbol = "CTX";
    uint public constant decimals = 18;

    // tottal supply

    address public icoContract = 0x0;
    /*
     * Modifiers
     */

    modifier onlyIcoContract() {
        // only ICO contract is allowed to proceed
        require(msg.sender == icoContract);
        _;
    }

    /*
     * Contract functions
     */

    /// @dev Contract is needed in icoContract address
    /// @param _icoContract Address of account which will be mint tokens
    function CarTaxiToken(address _icoContract) {
        assert(_icoContract != 0x0);
        icoContract = _icoContract;
    }

    /// @dev Burns tokens from address. It&#39;s can be applied by account with address this.icoContract
    /// @param _from Address of account, from which will be burned tokens
    /// @param _value Amount of tokens, that will be burned
    function burnTokens(address _from, uint _value) onlyIcoContract {
        assert(_from != 0x0);
        require(_value > 0);

        balances[_from] = sub(balances[_from], _value);
    }

    /// @dev Adds tokens to address. It&#39;s can be applied by account with address this.icoContract
    /// @param _to Address of account to which the tokens will pass
    /// @param _value Amount of tokens
    function emitTokens(address _to, uint _value) onlyIcoContract {
        assert(_to != 0x0);
        require(_value > 0);

        balances[_to] = add(balances[_to], _value);

        if(!ownerAppended[_to]) {
            ownerAppended[_to] = true;
            owners.push(_to);
        }

    }

    function getOwner(uint index) constant returns (address, uint256) {
        return (owners[index], balances[owners[index]]);
    }

    function getOwnerCount() constant returns (uint) {
        return owners.length;
    }

}