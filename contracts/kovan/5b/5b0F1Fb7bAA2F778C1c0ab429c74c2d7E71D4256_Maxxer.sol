// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.3;

/**
* @author Maxxer.
*/

/**
* @title ERC223ReceivingContract
* @dev ContractReceiver abstract class that define by erc223, the method tokenFallback must by receiver contract if it want 
*      to accept erc223 tokens.
*      ERC223 Receiving Contract interface
*/
contract ERC223ReceivingContract {
    function tokenFallback(address from, uint value, bytes memory _data) public;
}

/**
* @title ERC223Interface
* @dev ERC223 Contract Interface
*/
contract ERC223Interface {
    function balanceOf(address who)public view returns (uint);
    function transfer(address to, uint value)public returns (bool success);
    function transfer(address to, uint value, bytes memory data)public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
* @title UpgradedStandardToken
* @dev Contract Upgraded Interface
*/
contract UpgradedStandardToken{
    function transferByHolder(address to, uint tokens) external;
}

/**
* @title Authenticity
* @dev Address Authenticity Interface
*/
contract Authenticity{
    function getAddress(address contratAddress) public view returns (bool);
}

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library safeMath {
    
    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    
    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
*      functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
    address public owner;

    constructor() internal{
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

/**
* @title BlackList
* @dev The BlackList contract has an BlackList address, and provides basic authorization control
*      functions, this simplifies the implementation of "user address authorization".
*/
contract BlackList is Ownable{

    mapping (address => bool) internal isBlackListed;

    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);

    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    /**
    * @param _evilUser address of user the owner want to add in BlackList 
    */
    function addBlackList (address _evilUser) public onlyOwner {
        require(!isBlackListed[_evilUser]);
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    /**
    * @param _clearedUser address of user the owner want to remove BlackList 
    */
    function removeBlackList (address _clearedUser) public onlyOwner {
        require(isBlackListed[_clearedUser]);
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }
}

/**
* @title BasicERC223
* @dev standard ERC223 contract
*/
contract BasicERC223 is BlackList,ERC223Interface {
    
    using safeMath for uint;
    uint8 public basisPointsRate;
    uint public minimumFee;
    uint public maximumFee;
    address[] holders;
    
    mapping(address => uint) internal balances;
    
    event Transfer(address from, address to, uint256 value, bytes data, uint256 fee);
    
    /**
    * @dev Function that is called when a user or another contract wants to transfer funds.
    * @param _address address of contract.
    * @return true is _address was contract address.
    */
    function isContract(address _address) internal view returns (bool is_contract) {
        uint length;
        require(_address != address(0));
        assembly {
            length := extcodesize(_address)
        }
        return (length > 0);
    }
    
    /**
    * @dev function that is called by transfer method to calculate Fee.
    * @param _amount Amount of tokens.
    * @return fee calculate from _amount.
    */
    function calculateFee(uint _amount) internal view returns(uint fee){
        fee = (_amount.mul(basisPointsRate)).div(1000);
        if (fee > maximumFee) fee = maximumFee;
        if (fee < minimumFee) fee = minimumFee;
    }
    
    /**
    * @dev function that is called when transaction target is a contract.
    * @return true if transferToContract execute successfully.
    */
    function transferToContract(address _to, uint _value, bytes memory _data) internal returns (bool success) {
        require(_value > 0 && balances[msg.sender]>=_value);
        require(_to != msg.sender && _to != address(0));
        uint fee = calculateFee(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value.sub(fee));
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
        }
        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value,  _data, fee);
        holderIsExist(_to);
        return true;
    }
    
    /**
    * @dev function that is called when transaction target is a external Address.
    * @return true if transferToAddress execute successfully.
    */
    function transferToAddress(address _to, uint _value, bytes memory _data) internal returns (bool success) {
        require(_value > 0 && balances[msg.sender]>=_value);
        require(_to != msg.sender && _to != address(0));
        uint fee = calculateFee(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value.sub(fee));
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
        }
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value,  _data, fee);
        holderIsExist(_to);
        return true;
    }
    
    /**
    * @dev Check for existing holder address if not then add it .
    * @param _holder The address to check it already exist or not.
    * @return true if holderIsExist execute successfully.
    */
    function holderIsExist(address _holder) internal returns (bool success){
        for(uint i=0;i<holders.length;i++)
            if(_holder==holders[i])
                success=true;
        if(!success) holders.push(_holder);
    }
    
    /**
    * @dev Get all holders of Contract.
    * @return array of holder address.
    */
    function holder() public onlyOwner view returns(address[] memory){
        return holders;
    }
}

/**
* @title Maxxer.
* @dev Maxxer that implements BasicERC223.
*/
contract Maxxer is BasicERC223{
    string public  name;
    string public symbol;
    uint8 public decimals;
    uint256 internal _totalSupply;
    bool public Auth;
    bool public deprecated;
    bytes empty;
   
    /** @dev fee Events */
    event Params(uint8 feeBasisPoints,uint maximumFee,uint minimumFee);
    
    /** @dev IsAutheticate is modifier use to check contract is verifyed or not. */
    modifier IsAuthenticate(){
        require(Auth);
        _;
    }
    
    constructor(string memory _name, string memory _symbol, uint256 totalSupply) public {
        name = _name;                                      // Name of token
        symbol = _symbol;                                  // Symbol of token
        decimals = 18;                                      // Decimal unit of token
        _totalSupply = totalSupply * 10**uint(decimals);   // Initial supply of token
        balances[msg.sender] = _totalSupply;                // Token owner will credited defined token supply
        holders.push(msg.sender);
        emit Transfer(address(this),msg.sender,_totalSupply);
    }
    
    /**
    * @dev Get totalSupply of tokens.
    */
    function totalSupply() IsAuthenticate public view returns (uint256) {
        return _totalSupply;
    }
    
    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) IsAuthenticate public view returns (uint balance) {
        return balances[_owner];
    }
    
    /**
    * @dev Transfer the specified amount of tokens to the specified address.
    *      This function works the same with the previous one
    *      but doesn't contain `_data` param.
    *      Added due to backwards compatibility reasons.
    * @param to    Receiver address.
    * @param value Amount of tokens that will be transferred.
    * @return true if transfer execute successfully.
    */
    function transfer(address to, uint value) public IsAuthenticate returns (bool success) {
        require(!deprecated);
        require(!isBlackListed[msg.sender] && !isBlackListed[to]);
        if(isContract(to)) return transferToContract(to, value, empty);
        else return transferToAddress(to, value, empty);
    }
    
    /**
    * @dev Transfer the specified amount of tokens to the specified address.
    *      Invokes the `tokenFallback` function if the recipient is a contract.
    *      The token transfer fails if the recipient is a contract
    *      but does not implement the `tokenFallback` function
    *      or the fallback function to receive funds.
    * @param to    Receiver address.
    * @param value Amount of tokens that will be transferred.
    * @param data  Transaction metadata.
    * @return true if transfer execute successfully.
    */
    function transfer(address to, uint value, bytes memory data) public IsAuthenticate returns (bool success) {
        require(!deprecated);
        require(!isBlackListed[msg.sender] && !isBlackListed[to]);
        if(isContract(to)) return transferToContract(to, value, data);
        else return transferToAddress(to, value, data);
    }
    
    /**
    * @dev authenticate the address is valid or not 
    * @param _authenticate The address is authenticate or not.
    * @return true if address is valid.
    */
    function authenticate(address _authenticate) onlyOwner public returns(bool){
        return Auth = Authenticity(_authenticate).getAddress(address(this));
    }
    
    /**
    * @dev withdraw the token on our contract to owner 
    * @param _tokenContract address of contract to withdraw token.
    * @return true if transfer success.
    */
    function withdrawForeignTokens(address _tokenContract) onlyOwner IsAuthenticate public returns (bool) {
        ERC223Interface token = ERC223Interface(_tokenContract);
        uint tokenBalance = token.balanceOf(address(this));
        return token.transfer(owner,tokenBalance);
    }
    
    /**
    * @dev Issue a new amount of tokens
    *      these tokens are deposited into the owner address
    * @param amount Number of tokens to be increase
    */
    function increaseSupply(uint amount) public onlyOwner IsAuthenticate{
        require(amount <= 10000000);
        amount = amount.mul(10**uint(decimals));
        balances[owner] = balances[owner].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), owner, amount);
    }
    
    /**
    * @dev Redeem tokens.These tokens are withdrawn from the owner address
    *      if the balance must be enough to cover the redeem
    *      or the call will fail.
    * @param amount Number of tokens to be issued
    */
    function decreaseSupply(uint amount) public onlyOwner IsAuthenticate {
        require(amount <= 10000000);
        amount = amount.mul(10**uint(decimals));
        require(_totalSupply >= amount && balances[owner] >= amount);
        _totalSupply = _totalSupply.sub(amount);
        balances[owner] = balances[owner].sub(amount);
        emit Transfer(owner, address(0), amount);
    }
    
    /**
    * @dev Function to set the basis point rate.
    * @param newBasisPoints uint which is <= 9.
    * @param newMaxFee uint which is <= 100 and >= 5.
    * @param newMinFee uint which is <= 5.
    */
    function setParams(uint8 newBasisPoints, uint newMaxFee, uint newMinFee) public onlyOwner IsAuthenticate{
        require(newBasisPoints <= 9);
        require(newMaxFee >= 5 && newMaxFee <= 100);
        require(newMinFee <= 5);
        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**uint(decimals));
        minimumFee = newMinFee.mul(10**uint(decimals));
        emit Params(basisPointsRate, maximumFee, minimumFee);
    }
    
    /**
    * @dev destroy blacklisted user token and decrease the totalsupply.
    * @param _blackListedUser destroy token of blacklisted user.
    */
    function destroyBlackFunds(address _blackListedUser) public onlyOwner IsAuthenticate{
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balances[_blackListedUser];
        balances[_blackListedUser] = 0;
        _totalSupply = _totalSupply.sub(dirtyFunds);
        emit Transfer(_blackListedUser, address(0), dirtyFunds);
    }
    
    /**
    * @dev deprecate current contract in favour of a new one.
    * @param _upgradedAddress contract address of upgradable contract.
    * @return true if deprecate execute successfully.
    */
    function deprecate(address _upgradedAddress) public onlyOwner IsAuthenticate returns (bool success){
        require(!deprecated);
        deprecated = true;
        UpgradedStandardToken upd = UpgradedStandardToken(_upgradedAddress);
        for(uint i=0; i<holders.length;i++){
            if(balances[holders[i]] > 0 && !isBlackListed[holders[i]]){
                upd.transferByHolder(holders[i],balances[holders[i]]);
                balances[holders[i]] = 0;
            }
        }
        return true;
    }
    
    /**
    * @dev Destroy the contract.
    */
    function destroyContract(address payable _owner) public onlyOwner IsAuthenticate{
        require(_owner == owner);
        selfdestruct(_owner);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}