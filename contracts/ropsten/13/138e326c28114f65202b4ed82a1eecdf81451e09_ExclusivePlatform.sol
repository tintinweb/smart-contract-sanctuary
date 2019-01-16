pragma solidity ^0.5.1;

/**
 * @title SafeMath
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
   function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
}



contract ForeignToken {
    function balanceOf(address _owner) view public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract ExclusivePlatform is ERC20Interface, Owned {
    
    using SafeMath for uint256;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public blacklist;

    string public name = "Exclusive Platform";
    string public symbol = "XPL";
    uint256 public decimals = 8;
    uint256 public _totalSupply;
    
    uint256 public XPLPerEther = 8333334e8;
    uint256 public amountClaimable = 14999e8;
    uint256 public minimumBuy = 1 ether / 10;
    uint256 public maximumBuy = 30 ether;
    uint256 public claimed = 0;
    bool public airdropIsOn = false;
    bool public crowdsaleIsOn = false;
    
    //mitigates the ERC20 short address attack
    //suggested by izqui9 @ http://bit.ly/2NMMCNv
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    modifier onlyWhitelist() {
        require(blacklist[msg.sender] == false);
        _;
    }
    
    constructor () public {
        _totalSupply = 10000000000e8;
        /**
         * give the original `owner` of the contract
         * the totalSupply
         */
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
    //get the total totalSupply
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function updateXPLPerEther(uint _XPLPerEther) public onlyOwner {        
        emit NewPrice(owner, XPLPerEther, _XPLPerEther);
        XPLPerEther = _XPLPerEther;
    }
    //toggle airdrop
    function switchAirdrop() public onlyOwner {
        airdropIsOn = !(airdropIsOn);
    }
    //toggle crowdsale
    function switchCrowdsale() public onlyOwner {
        crowdsaleIsOn = !(crowdsaleIsOn);
    }
    //give bonus for buy of 10 ether and above
    function bonus(uint256 _amount) internal view returns (uint256){
        if(_amount >= XPLPerEther.mul(10)) return ((10*_amount).div(100)).add(_amount);
        return _amount;
    }
    
    function airdrop() payable onlyWhitelist public{
        address investor = msg.sender;
        require(claimed <= 9999 && airdropIsOn);
        blacklist[investor] = true;
        claimed = claimed.add(1);
        doTransfer(owner, investor, amountClaimable);
    }
    
    function getXPL() payable public {
        if(msg.value >= minimumBuy){
            require(msg.value <= maximumBuy && crowdsaleIsOn);
            address investor = msg.sender;
            uint256 totalBuy =  (XPLPerEther.mul(msg.value)).div(1 ether);
            totalBuy = bonus(totalBuy);
            doTransfer(owner, investor, totalBuy);
        }else{
            airdrop();
        }
    }
    
    function () payable external {
        getXPL();
    }
    
    function distribute(address[] calldata _addresses, uint256 _amount) external {        
        for (uint i = 0; i < _addresses.length; i++) {transfer(_addresses[i], _amount);}
    }
    
    function distributeWithAmount(address[] calldata _addresses, uint256[] calldata _amounts) external {
        require(_addresses.length == _amounts.length);
        for (uint i = 0; i < _addresses.length; i++) {transfer(_addresses[i], _amounts[i]);}
    }
    
    /// @dev This is the actual transfer function in the token contract, it can
    ///  only be called by other functions in this contract.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function doTransfer(address _from, address _to, uint _amount) internal {
        // Do not allow transfer to 0x0 or the token contract itself
        require((_to != address(0)));
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }
    
    function balanceOf(address _owner) view public returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        doTransfer(msg.sender, _to, _amount);
        return true;
    }
    /// @return The balance of `_owner`
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {
        require(allowed[_from][msg.sender] >= _amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        doTransfer(_from, _to, _amount);
        return true;
    }
    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        ApproveAndCallFallBack spender = ApproveAndCallFallBack(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function transferEther(address payable _receiver, uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance);
        emit TransferEther(address(this), _receiver, _amount);
        _receiver.transfer(_amount);
    }
    
    function withdrawFund() onlyOwner public {
        uint256 balance = address(this).balance;
        owner.transfer(balance);
    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
    
    function getForeignTokenBalance(address tokenAddress, address who) view public returns (uint){
        ForeignToken t = ForeignToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
    
     function whitelistAddresses(address[] memory _addresses) onlyOwner public {
        for (uint i = 0; i < _addresses.length; i++) {
            blacklist[_addresses[i]] = false;
        }
    }

    function blacklistAddresses(address[] memory _addresses) onlyOwner public {
        for (uint i = 0; i < _addresses.length; i++) {
            blacklist[_addresses[i]] = true;
        }
    }
    
    event TransferEther(address indexed _from, address indexed _to, uint256 _value);
    event NewPrice(address indexed _changer, uint256 _lastPrice, uint256 _newPrice);
    event Burn(address indexed _burner, uint256 value);

}