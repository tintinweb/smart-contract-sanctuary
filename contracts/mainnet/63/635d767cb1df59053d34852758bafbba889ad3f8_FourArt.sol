/**
 * 4art ERC20 StandardToken
 * Author: scalify.it
 * */

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event DelegatedTransfer(address indexed from, address indexed to, address indexed delegate, uint256 value, uint256 fee);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) public balances;

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

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
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Owned() public {
        owner = msg.sender;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract FourArt is StandardToken, Owned {
    string public constant name = "4ArtCoin";
    string public constant symbol = "4Art";
    uint8 public constant decimals = 18;
    uint256 public sellPrice = 0; // eth
    uint256 public buyPrice = 0; // eth
    mapping (address => bool) private SubFounders;       
    mapping (address => bool) private TeamAdviserPartner;
    
    //FounderAddress1 is main founder
    address private FounderAddress1;
    address private FounderAddress2;
    address private FounderAddress3;
    address private FounderAddress4;
    address private FounderAddress5;
    address private teamAddress;
    address private adviserAddress;
    address private partnershipAddress;
    address private bountyAddress;
    address private affiliateAddress;
    address private miscAddress;

    function FourArt(
        address _founderAddress1, 
        address _founderAddress2,
        address _founderAddress3, 
        address _founderAddress4, 
        address _founderAddress5, 
        address _teamAddress, 
        address _adviserAddress, 
        address _partnershipAddress, 
        address _bountyAddress, 
        address _affiliateAddress,
        address _miscAddress
        )  {
        totalSupply = 6500000000e18;
        //assign initial tokens for sale to contracter
        balances[msg.sender] = 4354000000e18;
        FounderAddress1 = _founderAddress1;
        FounderAddress2 = _founderAddress2;
        FounderAddress3 = _founderAddress3;
        FounderAddress4 = _founderAddress4;
        FounderAddress5 = _founderAddress5;
        teamAddress = _teamAddress;
        adviserAddress =  _adviserAddress;
        partnershipAddress = _partnershipAddress;
        bountyAddress = _bountyAddress;
        affiliateAddress = _affiliateAddress;
        miscAddress =  _miscAddress;
        
        //Assign tokens to the addresses at contract deployment
        balances[FounderAddress1] = 1390000000e18;
        balances[FounderAddress2] = 27500000e18;
        balances[FounderAddress3] = 27500000e18;
        balances[FounderAddress4] = 27500000e18;
        balances[FounderAddress5] = 27500000e18;
        balances[teamAddress] = 39000000e18;
        balances[adviserAddress] = 39000000e18;
        balances[partnershipAddress] = 39000000e18;
        balances[bountyAddress] = 65000000e18;
        balances[affiliateAddress] = 364000000e18;
        balances[miscAddress] = 100000000e18;

        //checks for tokens transfer        
        SubFounders[FounderAddress2] = true;        
        SubFounders[FounderAddress3] = true;        
        SubFounders[FounderAddress4] = true;        
        SubFounders[FounderAddress5] = true;        
        TeamAdviserPartner[teamAddress] = true;     
        TeamAdviserPartner[adviserAddress] = true;  
        TeamAdviserPartner[partnershipAddress] = true;
    }

    // Set buy and sell price of 1 token in eth.
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    // @notice Buy tokens from contract by sending ether
    function buy() payable public {
        require(now > 1543536000); // seconds since 01.01.1970 to 30.11.2018 (18:00:00 o&#39;clock GMT)
        uint amount = msg.value.div(buyPrice);       // calculates the amount
        _transfer(owner, msg.sender, amount);   // makes the transfers
    }

    // @notice Sell `amount` tokens to contract
    function sell(uint256 amount) public {
        require(now > 1543536000); // seconds since 01.01.1970 to 30.11.2018 (18:00:00 o&#39;clock GMT) 
        require(amount > 0);
        require(balances[msg.sender] >= amount);
        uint256 requiredBalance = amount.mul(sellPrice);
        require(this.balance >= requiredBalance);  // checks if the contract has enough ether to pay
        balances[msg.sender] -= amount;
        balances[owner] += amount;
        Transfer(msg.sender, owner, amount); 
        msg.sender.transfer(requiredBalance);    // sends ether to the seller.
    }

    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
        Transfer(_from, _to, _value);
    }

    // @dev if owner wants to transfer contract ether balance to own account.
    function transferBalanceToOwner(uint256 _value) public onlyOwner {
        require(_value <= this.balance);
        owner.transfer(_value);
    }
    
    // @dev if someone wants to transfer tokens to other account.
    function transferTokens(address _to, uint256 _tokens) lockTokenTransferBeforeStage4 TeamTransferConditions(_tokens, msg.sender)   public {
        _transfer(msg.sender, _to, _tokens);
    }
    
    // @dev Transfer tokens from one address to another
    function transferFrom(address _from, address _to, uint256 _value) lockTokenTransferBeforeStage4 TeamTransferConditions(_value, _from)  public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    modifier lockTokenTransferBeforeStage4{
        if(msg.sender != owner){
           require(now > 1533513600); // Locking till stage 4 starting date (ICO).
        }
        _;
    }
    
    modifier TeamTransferConditions(uint256 _tokens,  address _address) {
        if(SubFounders[_address]){
            require(now > 1543536000);
            if(now > 1543536000 && now < 1569628800){
                //90% lock of total 27500000e18
                isLocked(_tokens, 24750000e18, _address);
            } 
            if(now > 1569628800 && now < 1601251200){
               //50% lock of total 27500000e18
               isLocked(_tokens, 13750000e18, _address);
            }
        }
        
        if(TeamAdviserPartner[_address]){
            require(now > 1543536000);
            if(now > 1543536000 && now < 1569628800){
                //85% lock of total 39000000e18
                isLocked(_tokens, 33150000e18, _address);
            } 
            if(now > 1569628800 && now < 1601251200){
               //60% lock of total 39000000e18
               isLocked(_tokens, 23400000e18, _address);
            }
        }
        _;
    }

    // @dev if someone wants to transfer tokens to other account.    
    function isLocked(uint256 _value,uint256 remainingTokens, address _address)  internal returns (bool) {
            uint256 remainingBalance = balances[_address].sub(_value);
            require(remainingBalance >= remainingTokens);
            return true;
    }
}