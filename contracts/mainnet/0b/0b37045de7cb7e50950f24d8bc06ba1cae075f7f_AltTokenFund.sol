pragma solidity 0.4.25;

contract StandardToken {

    /* Data structures */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    /* Events */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /* Read and write storage functions */

    // Transfers sender&#39;s tokens to a given address. Returns success.
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    // Allows allowed third party to transfer tokens from one address to another. Returns success. _value Number of tokens to transfer.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    // Returns number of tokens owned by given address.
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // Sets approved amount of tokens for spender. Returns success. _value Number of approved tokens.
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /* Read storage functions */

    //Returns number of allowed tokens for given address. _owner Address of token owner. _spender Address of token spender.
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}

contract AltTokenFund is StandardToken {

    /* External contracts */

    address public emissionContractAddress = 0x0;

    //Token meta data
    string constant public name = "Alt Token Fund";
    string constant public symbol = "ATF";
    uint8 constant public decimals = 8;

    /* Storage */
    address public owner = 0x0;
    bool public emissionEnabled = true;
    bool transfersEnabled = true;

    /* Modifiers */

    modifier isCrowdfundingContract() {
        // Only emission address to do this action
        if (msg.sender != emissionContractAddress) {
            revert();
        }
        _;
    }

    modifier onlyOwner() {
        // Only owner is allowed to do this action.
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    /* Contract functions */

    // TokenFund emission function. _for is Address of receiver, tokenCount is Number of tokens to issue.
    function issueTokens(address _for, uint tokenCount)
        external
        isCrowdfundingContract
        returns (bool)
    {
        if (emissionEnabled == false) {
            revert();
        }

        balances[_for] += tokenCount;
        totalSupply += tokenCount;
        return true;
    }

    // Withdraws tokens for msg.sender.
    function withdrawTokens(uint tokenCount)
        public
        returns (bool)
    {
        uint balance = balances[msg.sender];
        if (balance < tokenCount) {
            return false;
        }
        balances[msg.sender] -= tokenCount;
        totalSupply -= tokenCount;
        return true;
    }

    // Function to change address that is allowed to do emission.
    function changeEmissionContractAddress(address newAddress)
        external
        onlyOwner
        returns (bool)
    {
        emissionContractAddress = newAddress;
    }

    // Function that enables/disables transfers of token, value is true/false
    function enableTransfers(bool value)
        external
        onlyOwner
    {
        transfersEnabled = value;
    }

    // Function that enables/disables token emission.
    function enableEmission(bool value)
        external
        onlyOwner
    {
        emissionEnabled = value;
    }

    /* Overriding ERC20 standard token functions to support transfer lock */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (transfersEnabled == true) {
            return super.transfer(_to, _value);
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (transfersEnabled == true) {
            return super.transferFrom(_from, _to, _value);
        }
        return false;
    }


    // Contract constructor function sets initial token balances. _owner Address of the owner of AltTokenFund.
    constructor (address _owner) public
    {
        totalSupply = 0;
        owner = _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}