/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity 0.4.24;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed _to);

    constructor(address _owner) public {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
      require(!paused);
      _;
    }

    modifier whenPaused() {
      require(paused);
      _;
    }

    function pause() onlyOwner whenNotPaused public {
      paused = true;
      emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
      paused = false;
      emit Unpause();
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20 {
 // modifiers

 // mitigate short address attack
 // thanks to https://github.com/numerai/contract/blob/c182465f82e50ced8dacb3977ec374a892f5fa8c/contracts/Safe.sol#L30-L34.
 // TODO: doublecheck implication of >= compared to ==
    modifier onlyPayloadSize(uint numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }

    uint256 public totalSupply;
    /*
      *  Public functions
      */
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    /*
      *  Events
      */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event SaleContractActivation(address saleContract, uint256 tokensForSale);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {
    using SafeMath for uint256;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) balances;

  /// @dev Returns number of tokens owned by given address
  /// @param _owner Address of token owner
  /// @return Balance of owner

  // it is recommended to define functions which can read the state of blockchain but cannot write in it as view instead of constant

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

  /// @dev Transfers sender&#39;s tokens to a given address. Returns success
  /// @param _to Address of token receiver
  /// @param _value Number of tokens to transfer
  /// @return Was transfer successful?

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to].add(_value) > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value); // solhint-disable-line
            return true;
        } else {
            return false;
        }
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success
    /// @param _from Address from where tokens are withdrawn
    /// @param _to Address to where tokens are sent
    /// @param _value Number of tokens to transfer
    /// @return Was transfer successful?

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value); // solhint-disable-line
        return true;
    }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */


    function approve(address _spender, uint256 _value) public onlyPayloadSize(2) returns (bool) {
      // To change the approve amount you first have to reduce the addresses`
      //  allowance to zero by calling `approve(_spender, 0)` if it is not
      //  already 0 to mitigate the race condition described here:
      //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

        require(_value == 0 || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); // solhint-disable-line
        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) public onlyPayloadSize(3) returns (bool success) {
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        emit Approval(msg.sender, _spender, _newValue); // solhint-disable-line
        return true;
    }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

 /**
  * @dev Burns a specific amount of tokens.
  * @param _value The amount of token to be burned.
  */
    function burn(uint256 _value) public returns (bool burnSuccess) {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value); // solhint-disable-line
        return true;
    }
    
    

}

 /**
 * @title Synapse
 */
contract Synapse is StandardToken, Owned, Pausable {
    
    using SafeMath for uint256;
    string public symbol;
    string public name;
    uint8 public decimals;

    uint256 public tokensForSale = 495000000 * 1 ether;//50% total of Supply for crowdsale   
    uint256 public vestingTokens = 227700000 * 1 ether;//23% of total Supply will be freeze(10% team, 8% reserve and 5% others) 
    uint256 public managementTokens = 267300000 * 1 ether;//27% total Supply(12% Marketing, 9% Expansion, 3% Bounty, 3% Advisor)

    mapping(address => bool) public investorIsVested; 
    uint256 public vestingTime = 15552000;// 6 months  

    uint256 public bountyTokens = 29700000 * 1 ether;
    uint256 public marketingTokens = 118800000 * 1 ether;
    uint256 public expansionTokens = 89100000 * 1 ether;
    uint256 public advisorTokens = 29700000 * 1 ether;    

    uint256 public icoStartTime;
    uint256 public icoFinalizedTime;

    address public tokenOwner;
    address public crowdSaleOwner;
    address public vestingOwner;

    address public saleContract;
    address public vestingContract;
    bool public fundraising = true;

    mapping (address => bool) public frozenAccounts;
    event FrozenFund(address target, bool frozen);


    modifier onlyPayloadSize(uint numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }

    modifier manageTransfer() {
        if (msg.sender == owner) {
            _;
        } else {
            require(fundraising == false);
            _;
        }
    }
    
    /**
    * @dev constructor of a token contract
    * @param _tokenOwner address of the owner of contract.
    */
    constructor(address _tokenOwner,address _crowdSaleOwner, address _vestingOwner ) public Owned(_tokenOwner) {

        symbol ="SYP";
        name = "Synapsecoin";
        decimals = 18;
        tokenOwner = _tokenOwner; 
        crowdSaleOwner = _crowdSaleOwner;
        vestingOwner = _vestingOwner;
        totalSupply = 990000000 * 1 ether;
        balances[_tokenOwner] = balances[_tokenOwner].add(managementTokens);
        balances[_crowdSaleOwner] = balances[_crowdSaleOwner].add(tokensForSale);        
        balances[_vestingOwner] = balances[_vestingOwner].add(vestingTokens);
        emit Transfer(address(0), _tokenOwner, managementTokens);
        emit Transfer(address(0), _crowdSaleOwner, tokensForSale);    
        emit Transfer(address(0), _vestingOwner, vestingTokens);        
    }

    /**
    * @dev  Investor can Transfer token from this method
    * @param _to address of the reciever
    * @param _value amount of tokens to transfer
    */
    function transfer(address _to, uint256 _value) public manageTransfer whenNotPaused onlyPayloadSize(2) returns (bool success) {
        
        require(_value>0);
        require(_to != address(0));
        require(!frozenAccounts[msg.sender]);
        if(investorIsVested[msg.sender]==true )
        {
            require(now >= icoFinalizedTime.add(vestingTime)); 
            super.transfer(_to,_value);
            return true;

        }
        else {
            super.transfer(_to,_value);
            return true;
        }

    }
    
    /**
    * @dev  Transfer from allow to trasfer token 
    * @param _from address of sender 
    * @param _to address of the reciever
    * @param _value amount of tokens to transfer
    */
    function transferFrom(address _from, address _to, uint256 _value) public manageTransfer whenNotPaused onlyPayloadSize(3) returns (bool) {
        require(_value>0);
        require(_to != address(0));
        require(_from != address(0));
        require(!frozenAccounts[_from]);
        if(investorIsVested[_from]==true )
        {
            require(now >= icoFinalizedTime.add(vestingTime));//15552000
            super.transferFrom(_from,_to,_value);
            return true;

        }
        else {
            
           super.transferFrom(_from,_to,_value);
           return true;
        }    }
    

    /**
    * activates the sale contract (i.e. transfers saleable contracts)
    * @param _saleContract ,address of crowdsale contract
    */
    function activateSaleContract(address _saleContract) public whenNotPaused {
        require(msg.sender == crowdSaleOwner);
        require(_saleContract != address(0));
        require(saleContract == address(0));        
        saleContract = _saleContract;
        icoStartTime = now;

    }
     
    /**
    * activates the sale contract (i.e. transfers saleable contracts)
    * @param _vestingContract ,address of crowdsale contract
    */
    function activateVestingContract(address _vestingContract) public whenNotPaused  {
        require(msg.sender == vestingOwner);        
        require(_vestingContract != address(0));
        require(vestingContract == address(0));
        vestingContract = _vestingContract;
        
    }
    
    /**
    * @dev this function will send the bounty tokens to given address
    * @param _to ,address of the bounty receiver.
    * @param _value , number of tokens to be sent.
    */
    function sendBounty(address _to, uint256 _value) public whenNotPaused onlyOwner returns (bool) {

        require(_to != address(0));
        require(_value > 0 );        
        require(bountyTokens >= _value);
        bountyTokens = bountyTokens.sub(_value);
        return super.transfer(_to, _value);  
        }    

    /**
    * @dev this function will send the Marketing tokens to given address
    * @param _to ,address of the bounty receiver.
    * @param _value , number of tokens to be sent.
    */
    function sendMarketingTokens(address _to, uint256 _value) public whenNotPaused onlyOwner returns (bool) {

        require(_to != address(0));
        require(_value > 0 );        
        require(marketingTokens >= _value);
        marketingTokens = marketingTokens.sub(_value);
        return super.transfer(_to, _value);  
   }    

    /**
    * @dev this function will send the expansion tokens to given address
    * @param _to ,address of the bounty receiver.
    * @param _value , number of tokens to be sent.
    */
    function sendExpansionTokens(address _to, uint256 _value) public whenNotPaused onlyOwner returns (bool) {

        require(_to != address(0));
        require(_value > 0 );        
        require(expansionTokens >= _value);
        expansionTokens = expansionTokens.sub(_value);
        return super.transfer(_to, _value);  
   }    

    /**
    * @dev this function will send the expansion tokens to given address
    * @param _to ,address of the bounty receiver.
    * @param _value , number of tokens to be sent.
    */
    function sendAdvisorTokens(address _to, uint256 _value) public whenNotPaused onlyOwner returns (bool) {

        require(_to != address(0));
        require(_value > 0 );        
        require(advisorTokens >= _value);
        advisorTokens = advisorTokens.sub(_value);
        return super.transfer(_to, _value);  
   }    

    /**
    * @dev function to check whether passed address is a contract address
    */
    function isContract(address _address) private view returns (bool is_contract) {
        uint256 length;
        assembly {
        //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_address)
        }
        return (length > 0);
    }
    
    /**
    * @dev this function can only be called by crowdsale contract to transfer tokens to investor
    * @param _to address The address of the investor.
    * @param _value uint256 The amount of tokens to be send
    */
    function saleTransfer(address _to, uint256 _value) external whenNotPaused returns (bool) {
        require(saleContract != address(0),&#39;sale address is not activated&#39;);
        require(msg.sender == saleContract,&#39;caller is not crowdsale contract&#39;);
        require(!frozenAccounts[_to],&#39;account is freezed&#39;);
        return super.transferFrom(crowdSaleOwner,_to, _value);
            
    }

    /**
    * @dev this function can only be called by  contract to transfer tokens to vesting beneficiary
    * @param _to address The address of the beneficiary.
    * @param _value uint256 The amount of tokens to be send
    */
    function vestingTransfer(address _to, uint256 _value) external whenNotPaused returns (bool) {
        require(icoFinalizedTime == 0,&#39;ico is finalised&#39;);
        require(vestingContract != address(0));
        require(msg.sender == vestingContract,&#39;caller is not a vesting contract&#39;);
        investorIsVested[_to] = true;
        return super.transferFrom(vestingOwner,_to, _value);
    }

    /**
    * @dev this function will closes the sale ,after this anyone can transfer their tokens to others.
    */
    function finalize() external whenNotPaused returns(bool){
        require(fundraising != false); 
        require(msg.sender == saleContract);
        fundraising = false;
        icoFinalizedTime = now;
        return true;
    }

   /**
   * @dev this function will freeze the any account so that the frozen account will not able to participate in crowdsale.
   * @param target ,address of the target account 
   * @param freeze ,boolean value to freeze or unfreeze the account ,true to freeze and false to unfreeze
   */
   function freezeAccount (address target, bool freeze) public onlyOwner {
        require(target != 0x0);
        frozenAccounts[target] = freeze;
        emit FrozenFund(target, freeze); // solhint-disable-line
    }

    /**
    * @dev Function to transfer any ERC20 token  to owner address which gets accidentally transferred to this contract
    * @param tokenAddress The address of the ERC20 contract
    * @param tokens The amount of tokens to transfer.
    * @return A boolean that indicates if the operation was successful.
    */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public whenNotPaused onlyOwner returns (bool success) {
        require(tokenAddress != address(0));
        require(isContract(tokenAddress));
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
    
    function () external payable {
        revert();
    }
    
}