pragma solidity ^0.4.15;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract DYLC_ERC20Token {

    address public owner;
    string public name = "YLCHINA";
    string public symbol = "DYLC";
    uint8 public decimals = 18;

    uint256 public totalSupply = 5000000000 * (10**18);
    uint256 public currentSupply = 0;

    uint256 public angelTime = 1522395000;
    uint256 public privateTime = 1523777400;
    uint256 public firstTime = 1525073400;
    uint256 public secondTime = 1526369400;
    uint256 public thirdTime = 1527665400;
    uint256 public endTime = 1529047800;

    uint256 public constant earlyExchangeRate = 83054;  
    uint256 public constant baseExchangeRate = 55369; 
    
    uint8 public constant rewardAngel = 20;
    uint8 public constant rewardPrivate = 20;
    uint8 public constant rewardOne = 15;
    uint8 public constant rewardTwo = 10;
    uint8 public constant rewardThree = 5;

    uint256 public constant CROWD_SUPPLY = 550000000 * (10**18);
    uint256 public constant DEVELOPER_RESERVED = 4450000000 * (10**18);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    //event Approval(address indexed owner, address indexed spender, uint256 value);

    event Burn(address indexed from, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }

    function DYLC_ERC20Token() public {
        owner = 0xA9802C071dD0D9fC470A06a487a2DB3D938a7b02;
        balanceOf[owner] = DEVELOPER_RESERVED;
    }

    function transferOwnership(address newOwner) onlyOwner public {
      require(newOwner != address(0));
      OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        //Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                      
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);    
        balanceOf[_from] -= _value;                         
        allowance[_from][msg.sender] -= _value;             
        totalSupply -= _value;                              
        Burn(_from, _value);
        return true;
    }
    
    function () payable public{
          buyTokens(msg.sender);
    }
    
    function buyTokens(address beneficiary) public payable {
      require(beneficiary != 0x0);
      require(validPurchase());

      uint256 rRate = rewardRate();

      uint256 weiAmount = msg.value;
      balanceOf[beneficiary] += weiAmount * rRate;
      currentSupply += balanceOf[beneficiary];
      forwardFunds();           
    }

    function rewardRate() internal constant returns (uint256) {
            require(validPurchase());
            uint256 rate;
            if (now >= angelTime && now < privateTime){
              rate = earlyExchangeRate + earlyExchangeRate * rewardAngel / 100;
            }else if(now >= privateTime && now < firstTime){
              rate = baseExchangeRate + baseExchangeRate * rewardPrivate / 100;
            }else if(now >= firstTime && now < secondTime){
              rate = baseExchangeRate + baseExchangeRate * rewardOne / 100;
            }else if(now >= secondTime && now < thirdTime){
              rate = baseExchangeRate + baseExchangeRate * rewardTwo / 100;
            }else if(now >= thirdTime && now < endTime){
              rate = baseExchangeRate + baseExchangeRate * rewardThree / 100;
            }
            return rate;
      }

      function forwardFunds() internal {
            owner.transfer(msg.value);
      }

      function validPurchase() internal constant returns (bool) {
            bool nonZeroPurchase = msg.value != 0;
            bool noEnd = !hasEnded();
            bool noSoleout = !isSoleout();
            return  nonZeroPurchase && noEnd && noSoleout;
      }

      function afterCrowdSale() public onlyOwner {
        require( hasEnded() && !isSoleout());
        balanceOf[owner] = balanceOf[owner] + CROWD_SUPPLY - currentSupply;
        currentSupply = CROWD_SUPPLY;
      }


      function hasEnded() public constant returns (bool) {
            return (now > endTime); 
      }

      function isSoleout() public constant returns (bool) {
        return (currentSupply >= CROWD_SUPPLY);
      }
}