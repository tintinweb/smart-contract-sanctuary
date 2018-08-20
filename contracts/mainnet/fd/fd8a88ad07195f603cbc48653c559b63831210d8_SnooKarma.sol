pragma solidity 0.4.24;


contract SnooKarma {
    
    //The oracle checks the authenticity of the Reddit accounts and their karma
    address public oracle;
    
    //The maintainer manages donations and a small Karma fee
    //The maintainer is in charge of keeping the oracle running
    address public maintainer;
    
    //The owner can replace the oracle or maintainer if they are compromised
    address public owner;
    
    //ERC20 code
    //See https://github.com/ethereum/EIPs/blob/e451b058521ba6ccd5d3205456f755b1d2d52bb8/EIPS/eip-20.md
    mapping(address => uint) public balanceOf;
    mapping(address => mapping (address => uint)) public allowance;
    string public constant symbol = "SNK";
    string public constant name = "SnooKarma";
    uint8 public constant decimals = 2;
    uint public totalSupply = 0;
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
   
    //The Redeem event is activated when a Reddit user redeems Karma Coins
    event Redeem(string indexed username, address indexed addr, uint karma);
    //END OF ERC20 code
 
    //Keep track of Reddit users and their redeemed karma amount
    mapping(string => uint) redeemedKarma;
    
    //Construct the contract
    constructor() public {
        owner = msg.sender;
        maintainer = msg.sender;
        oracle = msg.sender;
    }
    
    //ERC20 code
    //See https://github.com/ethereum/EIPs/blob/e451b058521ba6ccd5d3205456f755b1d2d52bb8/EIPS/eip-20.md
    function transfer(address destination, uint amount) public returns (bool success) {
        if (balanceOf[msg.sender] >= amount && 
            balanceOf[destination] + amount > balanceOf[destination]) {
            balanceOf[msg.sender] -= amount;
            balanceOf[destination] += amount;
            emit Transfer(msg.sender, destination, amount);
            return true;
        } else {
            return false;
        }
    }
 
    function transferFrom (
        address from,
        address to,
        uint amount
    ) public returns (bool success) {
        if (balanceOf[from] >= amount &&
            allowance[from][msg.sender] >= amount &&
            balanceOf[to] + amount > balanceOf[to]) 
        {
            balanceOf[from] -= amount;
            allowance[from][msg.sender] -= amount;
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        } else {
            return false;
        }
    }
 
    function approve(address spender, uint amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    //END OF ERC20 code
    
    //SafeAdd function from 
    //https://github.com/OpenZeppelin/zeppelin-solidity/blob/6ad275befb9b24177b2a6a72472673a28108937d/contracts/math/SafeMath.sol
    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
    
    //Used to enforce permissions
    modifier onlyBy(address account) {
        require(msg.sender == account);
        _;
    }
    
    //The owner can transfer ownership
    function transferOwnership(address newOwner) public onlyBy(owner) {
        require(newOwner != address(0));
        owner = newOwner;
    }
    
    //The owner can change the oracle
    //This works only if removeOracle() was never called
    function changeOracle(address newOracle) public onlyBy(owner) {
        require(oracle != address(0) && newOracle != address(0));
        oracle = newOracle;
    }

    //The owner can remove the oracle
    //This can not be reverted and stops the generation of new SnooKarma coins!
    function removeOracle() public onlyBy(owner) {
        oracle = address(0);
    }
    
    //The owner can change the maintainer
    function changeMaintainer(address newMaintainer) public onlyBy(owner) {
        maintainer = newMaintainer;
    }
    
    //Allows the user the redeem an amount of Karma verified by the oracle
    //This function also grants a small extra amount of Karma to the maintainer
    //The maintainer gets 1 extra karma for each 100 redeemed by a user
    function redeem(string username, uint karma, uint sigExp, uint8 sigV, bytes32 sigR, bytes32 sigS) public {
        //The identity of the oracle is checked
        require(
            ecrecover(
                keccak256(abi.encodePacked(this, username, karma, sigExp)),
                sigV, sigR, sigS
            ) == oracle
        );
        //The signature must not be expired
        require(block.timestamp < sigExp);
        //The amount of karma needs to be more than the previous redeemed amount
        require(karma > redeemedKarma[username]);
        //The new karma that is available to be redeemed
        uint newUserKarma = karma - redeemedKarma[username];
        //The user&#39;s karma balance is updated with the new karma
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], newUserKarma);
        //The maintainer&#39;s extra karma is computed (1 extra karma for each 100 redeemed by a user)
        uint newMaintainerKarma = newUserKarma / 100;
        //The balance of the maintainer is updated
        balanceOf[maintainer] = safeAdd(balanceOf[maintainer], newMaintainerKarma);
        //The total supply (ERC20) is updated
        totalSupply = safeAdd(totalSupply, safeAdd(newUserKarma, newMaintainerKarma));
        //The amount of karma redeemed by a user is updated
        redeemedKarma[username] = karma;
        //The Redeem event is triggered
        emit Redeem(username, msg.sender, newUserKarma);
        //Update token holder balance on chain explorers
        emit Transfer(0x0, msg.sender, newUserKarma);
    }
    
    //This function is a workaround because this.redeemedKarma cannot be public
    //This is the limitation of the current Solidity compiler
    function redeemedKarmaOf(string username) public view returns(uint) {
        return redeemedKarma[username];
    }
    
    //Receive donations
    function() public payable {  }
    
    //Transfer donations or accidentally received Ethereum
    function transferEthereum(uint amount, address destination) public onlyBy(maintainer) {
        require(destination != address(0));
        destination.transfer(amount);
    }

    //Transfer donations or accidentally received ERC20 tokens
    function transferTokens(address token, uint amount, address destination) public onlyBy(maintainer) {
        require(destination != address(0));
        SnooKarma tokenContract = SnooKarma(token);
        tokenContract.transfer(destination, amount);
    }
 
}