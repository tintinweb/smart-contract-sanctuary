pragma solidity ^0.4.0;

import "./SafeMath.sol";
import "./IERC20.sol";

// Token w/ ownership
contract StandardToken is IERC20 {
    using SafeMath for uint256; // done

    uint256 public totalSupply;

    mapping (address => uint256) internal balances; // done
    mapping (address => mapping (address => uint256)) internal allowed; //done
    address public owner; // done


    event OwnershipIsTransferred(address indexed previousOwner, address indexed newOwner); // done
    event Burn(address indexed burner, uint256 value);
    
    constructor() public { // done
        owner = msg.sender;
    }
    
    modifier isOwner() { // done
        require(msg.sender == owner);
        _;
    }
    
    function transferToNewOwner(address newOwner) public isOwner { // done
        require(newOwner != address(0));
        emit OwnershipIsTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    //done
    function transfer(address _to, uint256 _value) public returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    //done
    function balanceOf (address _owner) public view returns (uint256 balance)
    {
        return balances[_owner];
    }

    // done
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    //done
    function approve(address _spender, uint256 _value) public returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // done
    function allowance(address _owner, address _spender) public  view returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    //done
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    // done
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue)
        {
            allowed[msg.sender][_spender] = 0;
        }
        else
        {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function burn(uint256 _value) external
    {
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }
}


contract ApGoldCoin is StandardToken {

    // all done
    string public name = 'ApGoldCoin';
    string public symbol = 'APG';
    uint public decimals = 18;
    bool public tradeable;

    constructor() public {
        totalSupply = 50000000000 * (10 ** uint(decimals));
        balances[msg.sender] = totalSupply;
        tradeable = false;
    }
    
    function setTradable(bool _tradeable) public isOwner {
        tradeable = _tradeable;
    }
    
    modifier ifTradingAllowed() {
        require(tradeable == true);
        _;
    }
    
    // The token can be moved around so call super functions on transfer
    // These are just wrapper around normal transfer, approve, increaseApproval, decreaseApproval functions
    // so as to handle the new settings of being a tradable and can only be executed by the owner.
    function transferForCrowdSale(address _to, uint256 _value) public isOwner returns (bool) {
        require( tradeable == false );
        return super.transfer(_to, _value);
    } 
    
    function transfer(address _to, uint256 _value) public ifTradingAllowed returns (bool) {
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public ifTradingAllowed returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) public ifTradingAllowed returns (bool) {
        return super.approve(_spender, _value);
    }
    
    function increaseApproval(address _spender, uint _addedValue) public ifTradingAllowed returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public ifTradingAllowed returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}


contract ApgCrowdSale {
    using SafeMath for uint256;
    
    
    // Handle ownership logic
    address public owner; // done


    event OwnershipIsTransferred(address indexed previousOwner, address indexed newOwner); // done
    event Burn(address indexed burner, uint256 value);
    
    constructor() public { // done
        owner = msg.sender;
        token = new ApGoldCoin();
        remAPG = token.totalSupply();
    }
    
    modifier isOwner() { // done
        require(msg.sender == owner);
        _;
    }
    
    function transferToNewOwner(address newOwner) public isOwner { // done
        require(newOwner != address(0));
        emit OwnershipIsTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    
    event StartCrowdsale();
    event EndCrowdSale();
    event TokenSoldToAccount(address recipient, uint eth_amount, uint apg_amount);
    
    uint256 constant presaleEthToAPG   = 3500; 
    uint256 constant crowdsaleEthToAPG =  1200;
    
    ApGoldCoin public token;
    
    uint256 public remAPG;
    
    address public vault;
    
    // crowdsale state
    enum CrowdsaleState { Idle, Running, Finished }
    CrowdsaleState public state = CrowdsaleState.Idle;
    uint256 public startTime;
    uint256 public endTime;
    
    // Buyers state
    struct Buyer {
        uint256 ethAllocatedForUser;
        bool    allowedToBuy;
    }
    mapping (address => Buyer) private listOfBuyers;

    function startCrowdsale(uint256 _startTime, uint256 _endTime, address _vault) public isOwner {
        require(state == CrowdsaleState.Idle);
        require(_startTime >= now);
        require(_endTime > _startTime);
        require(_vault != 0x0);
        
        startTime     = _startTime;
        endTime       = _endTime;
        vault     = _vault;
        _transferTokens(vault, 0, remAPG * 45 / 100);
        state     = CrowdsaleState.Running;
        emit StartCrowdsale();
    }
    
    function finalizeCrowdsale() public isOwner {
        require(state == CrowdsaleState.Running);
        require(endTime < now);
        
        _transferTokens( vault, 0, remAPG );
        
        state = CrowdsaleState.Finished;
        
        token.setTradable(true);
    
        emit EndCrowdSale();
    }
    
    function setEndDate(uint256 _endTime) public isOwner {
        require(state == CrowdsaleState.Running);
        require(_endTime > now);
        require(_endTime > startTime);
        require(_endTime > endTime);
        
        endTime = _endTime;
    }
    
    function setVault(address _vault) public isOwner {
        require(_vault != 0x0);
        
        vault = _vault;    
    }
    
    function whitelistAdd(address[] _addresses) public isOwner {
        for (uint i=0; i<_addresses.length; i++) {
            Buyer storage p = listOfBuyers[ _addresses[i] ];
            p.allowedToBuy = true;
            p.ethAllocatedForUser = 15 ether;
        }
    }
    
    
    function whitelistRemove(address[] _addresses) public isOwner {
        for (uint i=0; i<_addresses.length; i++) {
            delete listOfBuyers[ _addresses[i] ];
        }
    }
    
    function() external payable {
        buyTokens(msg.sender);
    }
    
    
    function _allocateTokens(uint256 eth) private view returns(uint256 tokens) {
        tokens = crowdsaleEthToAPG.mul(eth);
        require( remAPG >= tokens );
    }
    
    function _allocatePresaleTokens(uint256 eth) private view returns(uint256 tokens) {
        tokens = presaleEthToAPG.mul(eth);
        require( remAPG >= tokens );
    }
    
    function _transferTokens(address recipient, uint256 eth, uint256 apg) private {
        require( token.transferForCrowdSale( recipient, apg ) );
        remAPG = remAPG.sub( apg );
        emit TokenSoldToAccount(recipient, eth, apg);
    }
    
    function buyTokens(address recipient) public payable {
        require( (state == CrowdsaleState.Running) && (now >= startTime) && (now < endTime) );
        
        Buyer storage p = listOfBuyers[ recipient ];    
        require( p.allowedToBuy );
    
        uint256 tokens = _allocateTokens(msg.value);
        require( vault.send(msg.value) );
        _transferTokens( recipient, msg.value, tokens );
    }
    
    function grantTokens(address recipient, uint256 apg) public isOwner {
        require( (state == CrowdsaleState.Running) );
        require( remAPG >=  apg);
        _transferTokens( recipient, 0, apg );
    }
    
    function grantPresaleTokens(address[] recipients, uint256[] eths) public isOwner {
        require( (state == CrowdsaleState.Running) );
        require( recipients.length == eths.length );
        for (uint i=0; i<recipients.length; i++) {
            uint256 tokens = _allocatePresaleTokens(eths[i]);
            _transferTokens( recipients[i], eths[i], tokens );
        }
    }

}