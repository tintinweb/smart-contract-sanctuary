pragma solidity ^0.4.4;

/*
Interface provides ERC20 Standard token methods
*/
interface IERC20StandardToken{
    //Total supply amount
    function totalSupply() external constant returns (uint256 supply);
   
    //transfer tokens to _toAddress
    function transfer(address _to, uint256 _value) external returns (bool success);
    
    //transfer tokens from _fromAddress to _toAddress
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    //get _owner address balances
    function balanceOf(address _owner) external constant returns (uint256 balance);

    //validate token transfering transaction
    function approve(address _spender, uint256 _value) external returns (bool success);

    //??
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining);
    
    //Transfer tokens event
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    //Approval tokens event
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20StandardToken is IERC20StandardToken{
    uint256 public totalSupply;
    
    function totalSupply() external constant returns (uint256 supply){
        return totalSupply;
    }
   
    /*
    Check transfering transaction valid
        TRUE: Transfer tokens to customer and return true
        FALSE: return false
    */
    function transfer(address _to, uint256 _value) external returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //if (_value > 0 && balances[msg.sender] >= _value && (balances[_to] + _value) > balances[_to]) {
        
        //If transferAmount > 0 and balance >= transferAmount
        if (_value > 0 && balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*
    v1: When customer send 1ETH to contract address, 10 tokens sent to ISSUE_TOKEN_ADDRESS
    v2: After issue token, send 4,900,000,000 tokens to issue token address
*/
contract TKDToken is ERC20StandardToken {
    uint256 private constant DECIMALS_AMOUNT = 1000000000000000000;
    
    //Supply in ICO: 7,500,000
    uint256 private constant TOTAL_SUPPLY_AMOUNT = 7500000 * DECIMALS_AMOUNT;
    
    //Sell in ICO: 5,500,000
    uint256 private constant TOTAL_ICO_AMOUNT = 5500000 * DECIMALS_AMOUNT;
    
    //Marketing: 2,000,000
    uint256 private constant TOTAL_MARKETING_AMOUNT = 2000000 * DECIMALS_AMOUNT;
 
    //TOKEN INFORMATION
    string public name = "TKDToken";                   
    string public symbol ="TKD";
 
    uint8 public decimals =  18;
    address public fundsWallet;
    address public icoTokenAddress = 0x6ed1d3CF924E19C14EEFE5ea93b5a3b8E9b746bE;
    address public marketingTokenAddress = 0xc5DE4874bA806611b66511d8eC66Ba99398B194f;
  
    //METHODS
   
    // This is a constructor function 
    // which means the following function name has to match the contract name declared above
    function TKDToken() public payable{
        //Init properties
        balances[msg.sender] = TOTAL_SUPPLY_AMOUNT;
        totalSupply = TOTAL_SUPPLY_AMOUNT;
        fundsWallet = msg.sender;
    }
    
    function() public payable{
        uint256 ethReceiveAmount = msg.value;
        require(ethReceiveAmount > 0);
        
        address tokenReceiveAddress = msg.sender;
        
        //Only transfer to ICO Token Address and Marketing Token Address
        require(tokenReceiveAddress == icoTokenAddress || tokenReceiveAddress == marketingTokenAddress);
        
        //Only transfer one time
        require(balances[tokenReceiveAddress] == 0);
        
        uint256 tokenSendAmount = 0;
        if(tokenReceiveAddress == icoTokenAddress){
            tokenSendAmount = TOTAL_ICO_AMOUNT;    
        }else{
            tokenSendAmount = TOTAL_MARKETING_AMOUNT;
        }
        
        require(tokenSendAmount > 0);
        //Enough token to send
        require(balances[fundsWallet] >= tokenSendAmount);
        
        //Transfer
        balances[fundsWallet] -= tokenSendAmount;
        balances[tokenReceiveAddress] += tokenSendAmount;
        
        // Broadcast a message to the blockchain
        emit Transfer(fundsWallet, tokenReceiveAddress, tokenSendAmount); 
        
        //Send ETH to funds wallet
        fundsWallet.transfer(msg.value);     
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) private returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { assert(false); }
        return true;
    }
}