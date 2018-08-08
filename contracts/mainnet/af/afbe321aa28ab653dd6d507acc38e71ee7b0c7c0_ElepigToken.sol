pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
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
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
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
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
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
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
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
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    *
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    *
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
    * @dev Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_who] = balances[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
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
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is BurnableToken, Ownable  {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;
    


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    
}

contract ElepigToken is MintableToken {
    string public name = "Elepig";
    string public symbol = "EPG";
    uint8 public decimals = 18;    

   // unlock times for Team Wallets
    uint constant unlockY1Time = 1546300800; //  Tuesday, January 1, 2019 12:00:00 AM
    uint constant unlockY2Time = 1577836800; //  Wednesday, January 1, 2020 12:00:00 AM
    uint constant unlockY3Time = 1609459200; //  Friday, January 1, 2021 12:00:00 AM
    uint constant unlockY4Time = 1640995200; //  Saturday, January 1, 2022 12:00:00 AM
         
    mapping (address => uint256) public freezeOf;
    
    address affiliate;
    address contingency;
    address advisor;  

    // team vesting plan wallets
    address team; 
    address teamY1; 
    address teamY2; 
    address teamY3; 
    address teamY4; 
    bool public mintedWallets = false;
    
    // tokens to be minted straight away
    //=============================    
    // 50% of tokens will be minted during presale & ico, 50% now

    uint256 constant affiliateTokens = 7500000000000000000000000;      // 2.5% 
    uint256 constant contingencyTokens = 52500000000000000000000000;   // 17.5%
    uint256 constant advisorTokens = 30000000000000000000000000;       // 10%   
    uint256 constant teamTokensPerWallet = 12000000000000000000000000;  // 20% of 60MM EPG team fund - vesting program 

    
   
    event Unfreeze(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event WalletsMinted();


    // constructor - null 
    function ElepigToken() public {
        
    }
    
    // mints ElePig wallets
    function mintWallets(                
        address _affiliateAddress, 
        address _contingencyAddress, 
        address _advisorAddress,         
        address _teamAddress, 
        address _teamY1Address, 
        address _teamY2Address, 
        address _teamY3Address, 
        address _teamY4Address
        ) public  onlyOwner {  
        require(_affiliateAddress != address(0));
        require(_contingencyAddress != address(0));
        require(_advisorAddress != address(0));
        require(_teamAddress != address(0));
        require(_teamY1Address != address(0));
        require(_teamY2Address != address(0));
        require(_teamY3Address != address(0));
        require(_teamY4Address != address(0)); 
        require(mintedWallets == false); // can only call function once
        
            
        affiliate = _affiliateAddress;
        contingency = _contingencyAddress;
        advisor = _advisorAddress;

        // team vesting plan wallets each year 20%
        team = _teamAddress;
        teamY1 = _teamY1Address;
        teamY2 = _teamY2Address;
        teamY3 = _teamY3Address;
        teamY4 = _teamY4Address;
        
        // mint coins immediately that aren&#39;t for crowdsale
        mint(affiliate, affiliateTokens);
        mint(contingency, contingencyTokens);
        mint(advisor, advisorTokens);
        mint(team, teamTokensPerWallet);
        mint(teamY1, teamTokensPerWallet); // These will be locked for transfer until 01/01/2019 00:00:00
        mint(teamY2, teamTokensPerWallet); // These will be locked for transfer until 01/01/2020 00:00:00
        mint(teamY3, teamTokensPerWallet); // These will be locked for transfer until 01/01/2021 00:00:00
        mint(teamY4, teamTokensPerWallet); // These will be locked for transfer until 01/01/2022 00:00:00

        mintedWallets = true;
        emit WalletsMinted();
    }

    function checkPermissions(address _from) internal view returns (bool) {        
        // team vesting, a wallet gets unlocked each year.
        if (_from == teamY1 && now < unlockY1Time) {
            return false;
        } else if (_from == teamY2 && now < unlockY2Time) {
            return false;
        } else if (_from == teamY3 && now < unlockY3Time) {
            return false;
        } else if (_from == teamY4 && now < unlockY4Time) {
            return false;
        } else {
        //all other addresses are not locked
            return true;
        } 
    }

    // check Permissions before transfer
    function transfer(address _to, uint256 _value) public returns (bool) {

        require(checkPermissions(msg.sender));
        super.transfer(_to, _value);
    }

    // check Permissions before transfer
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(checkPermissions(_from));
        super.transferFrom(_from, _to, _value);
    }

    function () public payable {
        revert();
    }
}