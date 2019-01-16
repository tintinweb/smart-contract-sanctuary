pragma solidity ^0.5.1;

contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes memory _data)public;
}


contract ERC223Interface {
    function balanceOf(address who)public view returns (uint);
    function transfer(address to, uint value)public returns (bool success);
    function transfer(address to, uint value, bytes memory data)public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}


/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library safeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract Ownable {
    address payable public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
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


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address payable newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    /**
    * @dev Fix for the ERC short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

}
contract BlackList is Ownable{
    
    mapping (address => bool) public isBlackListed;
    
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
    /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether) ///////
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }
    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

}

contract ERC223 is BlackList,ERC223Interface{
    
    using safeMath for uint256;
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    uint public basisPointsRate = 0;
    uint public minimumFee = 0;
    uint public maximumFee = 0;
    
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    
    constructor(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply) public {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply.mul(10**uint(_decimals));
        balances[msg.sender] = _totalSupply;
    }
    
    /*ERC20 Events*/
    //event Transfer(address indexed from,address indexed to,uint256 value);
    //event Approval(address indexed _owner,address indexed _spender,uint256 _value);
    
    /*ERC621 Events*/
    event IncreaseSupply(uint amount);
    event DecreaseSupply(uint amount);
    
    /*ERC223 Events*/
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    
    /*other Events*/
    event Params(uint feeBasisPoints,uint maximumFee,uint minimumFee);
    event DestroyedBlackFunds(address _blackListedUser,uint _balance);
    
    event Deposit(address sender,address from,uint val,bytes timestamp);
    /* Returns the balance of a particular account */
    function balanceOf(address _address)public view returns(uint256 balance) {
        return balances[_address];
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
  
    
    function transfer(address _to, uint256  _value)onlyPayloadSize(2 * 32) public returns (bool success){
        bytes memory empty;
        require(!isBlackListed[msg.sender] && !isBlackListed[_to]);
    
        return transfer(_to,_value,empty);
    }
    
    function transfer(address _to, uint _value, bytes memory _data)onlyPayloadSize(2 * 32) public returns (bool success){
        
        require(!isBlackListed[msg.sender] && !isBlackListed[_to]);
         //Calculate Fees from basis point rate
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }
        uint fee = calculateFee(_value);
        // Prevent transfer to 0x0 address.
        require (_to != msg.sender);
        //check receiver is not owner
        require(_to != address(0));
        //Check transfer value is > 0;
        require (_value > 0);
        // Check if the sender has enough
        require (balances[msg.sender] >= _value);
        // Check for overflows
        require (balances[_to].add(_value) >= balances[_to]);
        //sendAmount to receiver after deducted fee
        uint sendAmount = _value.sub(fee);
        // Subtract from the sender
        balances[msg.sender] = balances[msg.sender].sub(_value);
        // Add the same to the recipient
        balances[_to] = balances[_to].add(sendAmount);
        //Add fee to owner Account
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(msg.sender, owner, fee,_data);
        }
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    
    /* ERC223 // Infers if whether _address is a contract based on the presence of bytecode */
    function calculateFee(uint _amount) internal view returns(uint){
        uint fee = (_amount.mul(basisPointsRate)).div(1000);
        if (fee > maximumFee) {
                fee = maximumFee;
        }
        if (fee < minimumFee) {
            fee = minimumFee;
        }
        return fee;
    }
    
    
    /* ERC621 Standard
    Issue a new amount of tokens
    these tokens are deposited into the owner address
    @param _amount Number of tokens to be issued
    */
    function increaseSupply(uint amount) public onlyOwner {
        require(amount <= 10000000);
        amount = amount.mul(10**uint(_decimals));
        require(_totalSupply.add(amount) > _totalSupply);
        require(balances[owner].add(amount) > balances[owner]);
        balances[owner] = balances[owner].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit IncreaseSupply(amount);
    }
    
    /* ERC621 Standard
    Redeem tokens.
    These tokens are withdrawn from the owner address
    if the balance must be enough to cover the redeem
    or the call will fail.
    @param _amount Number of tokens to be issued
    */
    function decreaseSupply(uint amount) public onlyOwner {
        require(amount <= 10000000);
        amount = amount.mul(10**uint(_decimals));
        require(_totalSupply >= amount);
        require(balances[owner] >= amount);
        _totalSupply = _totalSupply.sub(amount);
        balances[owner] = balances[owner].sub(amount);
        emit DecreaseSupply(amount);
    }
    
     /*
        @dev Function to set the basis point rate .
        @param newBasisPoints uint which is <= 2.
    */
    function setParams(uint newBasisPoints,uint newMaxFee,uint newMinFee) public onlyOwner {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(newBasisPoints <= 9);
        require(newMaxFee <= 100);
        require(newMinFee <= 5);
        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**uint(_decimals));
        minimumFee = newMinFee.mul(10**uint(_decimals));
        emit Params(basisPointsRate, maximumFee, minimumFee);
    }
    
    
    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balances[_blackListedUser];
        balances[_blackListedUser] = 0;
        _totalSupply = _totalSupply.sub(dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ERC223Interface token = ERC223Interface(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    /*onlyOwner is custom modifier
    owner can kill this contract owners address*/
    function destroy(address payable _owner) public onlyOwner{
        require(_owner == owner);
        selfdestruct(_owner);
    }
}