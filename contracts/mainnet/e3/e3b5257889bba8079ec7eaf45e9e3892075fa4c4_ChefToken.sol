/*
Besides the standard ERC20 token functions, ChefToken smart contract has the following functions implemented:
- servicePaymentWithCharityPercentage:
    After the client and service provider agree on a service and it&#39;s price, the agreed amount is transfered to the CookUp smart contract address
    to ensure that the service provider will be paid. Once the service has been completed, the CookUp application calls this function, 
    which then calculates the appropriate percentages of the price for each involved party: the service provider, CookUp and the charity organization.
    CookUp&#39;s percentage is determined by the variable cookUpFee, while the charity&#39;s percentage is determined by the variable charityDonation.
    These two fees are substracted from the total service price, and the remaining amount is sent to the service provider.
    The funds that will be sent to charity organization are first stored at a temporary address.
- releaseAdvisorsTeamTokens:
    This function is used to transfer CHEF tokens reserved for CookUp partners and advisors to a temporary address every month, 
    for twelve months. It can only be called by the owner and has a built in condition which prevents the funds from being released 
    earlier than intended.
- burn:
    This function will be used only to burn unsold tokens during ICO.
*/

pragma solidity 0.4.23;
  library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
  
contract Ownable{
   address public chefOwner; 
   
   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
   function Ownable() public {
        chefOwner = msg.sender;
    }
   
    modifier onlyOwner() {
        require(msg.sender == chefOwner);
        _;
    }
      
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(chefOwner, newOwner);
        chefOwner = newOwner;
    }
}  


contract ChefTokenInterface {
    
    function totalSupply() public view returns (uint256 supply);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 value) public returns (bool success);
    function servicePaymentWithCharityPercentage(address to, uint256 value) public returns  (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approveAndCall(address spender, uint256 value, bytes extraData) public returns (bool success);
    function burn(uint256 value) public returns (bool success);
    function setCharityDonation(uint256 donation) public returns (bool success);
    function setCookUpFee(uint256 fee) public returns (bool success);
    function setCharityAddress(address tempAddress) public returns (bool success);
    function setAdvisorsTeamAddress(address tempAddress) public returns (bool success);
    function releaseAdvisorsTeamTokens () public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event PaymentWithCharityPercentage (address indexed from, address indexed to, address indexed charity, uint256 value, uint256 charityValue);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
}

interface tokenRecipient { 
    function receiveApproval(address from, uint256 value, address token, bytes extraData) external; 
}


contract ChefToken is Ownable, ChefTokenInterface {
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public cookUpFee;
    uint256 public charityDonation;
    address public tempCharity;
    address public tempAdvisorsTeam;
    uint256 public tokensReleasedAdvisorsTeam;
    uint256 initialReleaseDate; 
    uint256 releaseSum; 
    mapping (address => uint256) public balanceOf; 
    mapping (address => mapping (address => uint256)) public allowance;
    
    
    function ChefToken () public {
        totalSupply = 630*(10**6)*(10**18);   
        balanceOf[msg.sender] = totalSupply;  
        name = "CHEF";                  
        symbol = "CHEF";
    
        tempCharity = address(0);
        tempAdvisorsTeam = address(0);
        tokensReleasedAdvisorsTeam = 0;
        initialReleaseDate = 1530396000;
        releaseSum = 1575*(10**5)*(10**18);
        cookUpFee = 7;
        charityDonation=3;
    }


    function totalSupply() public view returns (uint256 supply) {
        return totalSupply;
    }
	

    function balanceOf(address _tokenOwner) public view returns (uint256 balance) {
        return balanceOf[_tokenOwner];
    }
	

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value); 
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]); 
        balanceOf[_from] = balanceOf[_from].sub(_value); 
        balanceOf[_to] = balanceOf[_to].add(_value); 
        emit Transfer(_from, _to, _value); 
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances); 
    }
	

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
	

    function servicePaymentWithCharityPercentage(address _to, uint256 _value)  public onlyOwner returns  (bool success) {
        uint256 servicePercentage = 100 - cookUpFee - charityDonation;
        _transfer(msg.sender, _to, _value.mul(servicePercentage).div(100));
        _transfer(msg.sender, tempCharity, _value.mul(charityDonation).div(100));
        emit PaymentWithCharityPercentage (msg.sender, _to, tempCharity, _value.mul(servicePercentage).div(100), _value.mul(charityDonation).div(100));
        return true;
    }
		

    function allowance(address _tokenOwner, address _spender) public view returns (uint256 remaining) {
        return allowance[_tokenOwner][_spender];
    }
    

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
	

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);   
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
	

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= _value);  
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);  
        totalSupply = totalSupply.sub(_value);  
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function setCharityAddress(address _tempAddress) public onlyOwner returns (bool success) {
        tempCharity = _tempAddress;
        return true;    
    }
    
    function setCookUpFee(uint256 _fee) public onlyOwner returns (bool success) {
        cookUpFee = _fee;
        return true;    
    }
    
    
     function setCharityDonation(uint256 _donation) public onlyOwner returns (bool success) {
        charityDonation = _donation;
        return true;    
    }
    
    
    function setAdvisorsTeamAddress(address _tempAddress) public onlyOwner returns (bool success) {
        tempAdvisorsTeam = _tempAddress;
        return true;    
    }


    function releaseAdvisorsTeamTokens () public onlyOwner returns (bool success) {
        uint256 releaseAmount = releaseSum.div(12);
        if((releaseSum >= (tokensReleasedAdvisorsTeam.add(releaseAmount))) && (initialReleaseDate+(tokensReleasedAdvisorsTeam.mul(30 days).mul(12).div(releaseSum)) <= now)) {
            tokensReleasedAdvisorsTeam=tokensReleasedAdvisorsTeam.add(releaseAmount);
            _transfer(chefOwner,tempAdvisorsTeam,releaseAmount);
            return true;
        }
        else {
            return false;
        }
    }    
}