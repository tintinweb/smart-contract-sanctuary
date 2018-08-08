pragma solidity ^0.4.21;

/***********************/
/* Trustedhealth Token */
/***********************/

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

contract owned {

    address public owner;

    function owned() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

/************************/
/* STANDARD ERC20 TOKEN */
/************************/

contract ERC20Token {

    /** Functions needed to be implemented by ERC20 standard **/
    function totalSupply() public constant returns (uint256 _totalSupply);
    function balanceOf(address _owner) public constant returns (uint256 _balance);
    function transfer(address _to, uint256 _amount) public returns (bool _success);
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool _success);
    function approve(address _spender, uint256 _amount) public returns (bool _success);
    function allowance(address _owner, address _spender) public constant returns (uint256 _remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
}


/**************************************/
/* TRUSTEDHEALTH TOKEN IMPLEMENTATION */
/**************************************/

contract TrustedhealthToken is ERC20Token, owned {
    using SafeMath for uint256;

    /* Public variables */
    string public name = "Trustedhealth";
    string public symbol = "TDH";
    uint8 public decimals = 18;
    bool public tokenFrozen;

    /* Private variables */
    uint256 supply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;
    mapping (address => bool) allowedToMint;

    /* Events */
    event TokenFrozen(bool _frozen, string _reason);
    event Mint(address indexed _to, uint256 _value);

    /**
    * Constructor function
    *
    * Initializes contract.
    **/
    function TrustedhealthToken() public {
        tokenFrozen = false;
    }

    /**
    * Internal transfer function.
    **/
    function _transfer(address _from, address _to, uint256 _amount) private {
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _amount);
        balances[_to] = balances[_to].add(_amount);
        balances[_from] = balances[_from].sub(_amount);
        emit Transfer(_from, _to, _amount);
    }

    /**
    * Transfer token
    *
    * Send &#39;_amount&#39; tokens to &#39;_to&#39; from your address.
    *
    * @param _to Address of recipient.
    * @param _amount Amount to send.
    * @return Whether the transfer was successful or not.
    **/
    function transfer(address _to, uint256 _amount) public returns (bool _success) {
        require(!tokenFrozen);
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    /**
    * Set allowance
    *
    * Allows &#39;_spender&#39; to spend &#39;_amount&#39; tokens from your address
    *
    * @param _spender Address of spender.
    * @param _amount Max amount allowed to spend.
    * @return Whether the approve was successful or not.
    **/
    function approve(address _spender, uint256 _amount) public returns (bool _success) {
        allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
    *Transfer token from
    *
    * Send &#39;_amount&#39; token from address &#39;_from&#39; to address &#39;_to&#39;
    *
    * @param _from Address of sender.
    * @param _to Address of recipient.
    * @param _amount Amount of token to send.
    * @return Whether the transfer was successful or not.
    **/
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool _success) {
        require(_amount <= allowances[_from][msg.sender]);
        require(!tokenFrozen);
        _transfer(_from, _to, _amount);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_amount);
        return true;
    }

    /**
    * Mint Tokens
    *
    * Adds _amount of tokens to _atAddress
    *
    * @param _atAddress Adds tokens to address
    * @param _amount Amount of tokens to add
    **/
    function mintTokens(address _atAddress, uint256 _amount) public {
        require(allowedToMint[msg.sender]);
        require(balances[_atAddress].add(_amount) > balances[_atAddress]);
        require((supply.add(_amount)) <= 201225419354262000000000000);
        supply = supply.add(_amount);
        balances[_atAddress] = balances[_atAddress].add(_amount);
        emit Mint(_atAddress, _amount);
        emit Transfer(0x0, _atAddress, _amount);
    }

    /**
    * Change freeze
    *
    * Changes status of frozen because of &#39;_reason&#39;
    *
    * @param _reason Reason for freezing or unfreezing token
    **/
    function changeFreezeTransaction(string _reason) public onlyOwner {
        tokenFrozen = !tokenFrozen;
        emit TokenFrozen(tokenFrozen, _reason);
    }

    /**
    * Change mint address
    *
    *  Changes the address to mint
    *
    * @param _addressToMint Address of new minter
    **/
    function changeAllowanceToMint(address _addressToMint) public onlyOwner {
        allowedToMint[_addressToMint] = !allowedToMint[_addressToMint];
    }

    /**
    * Get allowance
    *
    * @return Return amount allowed to spend from &#39;_owner&#39; by &#39;_spender&#39;
    **/
    function allowance(address _owner, address _spender) public constant returns (uint256 _remaining) {
        return allowances[_owner][_spender];
    }

    /**
    * Total amount of token
    *
    * @return Total amount of token
    **/
    function totalSupply() public constant returns (uint256 _totalSupply) {
        return supply;
    }

    /**
    * Balance of address
    *
    * Check balance of &#39;_owner&#39;
    *
    * @param _owner Address
    * @return Amount of token in possession
    **/
    function balanceOf(address _owner) public constant returns (uint256 _balance) {
        return balances[_owner];
    }

    /**
    * Address allowed to mint
    *
    * Checks if &#39;_address&#39; is allowed to mint
    *
    * @param _address Address
    * @return Allowance to mint
    **/
    function isAllowedToMint(address _address) public constant returns (bool _allowed) {
        return allowedToMint[_address];
    }

    /** Revert if someone sends ether to this contract **/
    function () public {
        revert();
    }

    /**
    * This part is here only for testing and will not be included into final version
    **/
    /**
    function killContract() onlyOwner{
    selfdestruct(msg.sender);
    }
    **/
}