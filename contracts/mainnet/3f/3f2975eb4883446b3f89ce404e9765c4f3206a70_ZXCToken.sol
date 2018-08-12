pragma solidity ^0.4.21;


/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
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
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control 
* functions, this simplifies the implementation of "user permissions". 
*/ 
contract Ownable {
    address public owner;

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
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


/**
* @title ERC20Basic
* @dev Simpler version of ERC20 interface
* @dev see https://github.com/ethereum/EIPs/issues/179
*/
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns  (uint256);
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
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}


    /**
    * @title ERC20 interface
    * @dev see https://github.com/ethereum/EIPs/issues/20
    */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
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
    * @param _value uint256 the amout of tokens to be transfered
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }       

    /**
    * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifing the amount of tokens still avaible for the spender.
    */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}


/*Token  Contract*/
contract ZXCToken is StandardToken, Ownable {
    using SafeMath for uint256;

    // Token Information
    string  public constant name = "MK7 Coin";
    string  public constant symbol = "MK7";
    uint8   public constant decimals = 18;

    // Sale period1.
    uint256 public startDate1;
    uint256 public endDate1;

    // Sale period2.
    uint256 public startDate2;
    uint256 public endDate2;

    //SaleCap
    uint256 public saleCap;

    // Address Where Token are keep
    address public tokenWallet;

    // Address where funds are collected.
    address public fundWallet;

    // Amount of raised money in wei.
    uint256 public weiRaised;

    // Event
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
    event PreICOTokenPushed(address indexed buyer, uint256 amount);

    // Modifiers
    modifier uninitialized() {
        require(tokenWallet == 0x0);
        require(fundWallet == 0x0);
        _;
    }

    constructor() public {}
    // Trigger with Transfer event
    // Fallback function can be used to buy tokens
    function () public payable {
        buyTokens(msg.sender, msg.value);
    }

    //Initial Contract
    function initialize(address _tokenWallet, address _fundWallet, uint256 _start1, uint256 _end1,
                        uint256 _saleCap, uint256 _totalSupply) public
                        onlyOwner uninitialized {
        require(_start1 < _end1);
        require(_tokenWallet != 0x0);
        require(_fundWallet != 0x0);
        require(_totalSupply >= _saleCap);

        startDate1 = _start1;
        endDate1 = _end1;
        saleCap = _saleCap;
        tokenWallet = _tokenWallet;
        fundWallet = _fundWallet;
        totalSupply = _totalSupply;

        balances[tokenWallet] = saleCap;
        balances[0xb1] = _totalSupply.sub(saleCap);
    }

    //Set PreSale Time
    function setPeriod(uint period, uint256 _start, uint256 _end) public onlyOwner {
        require(_end > _start);
        if (period == 1) {
            startDate1 = _start;
            endDate1 = _end;
        }else if (period == 2) {
            require(_start > endDate1);
            startDate2 = _start;
            endDate2 = _end;      
        }
    }

    // For pushing pre-ICO records
    function sendForPreICO(address buyer, uint256 amount) public onlyOwner {
        require(saleCap >= amount);

        saleCap = saleCap - amount;
        // Transfer
        balances[tokenWallet] = balances[tokenWallet].sub(amount);
        balances[buyer] = balances[buyer].add(amount);
        emit PreICOTokenPushed(buyer, amount);
        emit Transfer(tokenWallet, buyer, amount);
    }

    //Set SaleCap
    function setSaleCap(uint256 _saleCap) public onlyOwner {
        require(balances[0xb1].add(balances[tokenWallet]).sub(_saleCap) > 0);
        uint256 amount=0;
        //Check SaleCap
        if (balances[tokenWallet] > _saleCap) {
            amount = balances[tokenWallet].sub(_saleCap);
            balances[0xb1] = balances[0xb1].add(amount);
        } else {
            amount = _saleCap.sub(balances[tokenWallet]);
            balances[0xb1] = balances[0xb1].sub(amount);
        }
        balances[tokenWallet] = _saleCap;
        saleCap = _saleCap;
    }

    //Calcute Bouns
    function getBonusByTime(uint256 atTime) public constant returns (uint256) {
        if (atTime < startDate1) {
            return 0;
        } else if (endDate1 > atTime && atTime > startDate1) {
            return 5000;
        } else if (endDate2 > atTime && atTime > startDate2) {
            return 2500;
        } else {
            return 0;
        }
    }

    function getBounsByAmount(uint256 etherAmount, uint256 tokenAmount) public pure returns (uint256) {
        //Max 40%
        uint256 bonusRatio = etherAmount.div(500 ether);
        if (bonusRatio > 4) {
            bonusRatio = 4;
        }
        uint256 bonusCount = SafeMath.mul(bonusRatio, 10);
        uint256 bouns = SafeMath.mul(tokenAmount, bonusCount);
        uint256 realBouns = SafeMath.div(bouns, 100);
        return realBouns;
    }

    //Stop Contract
    function finalize() public onlyOwner {
        require(!saleActive());

        // Transfer the rest of token to tokenWallet
        balances[tokenWallet] = balances[tokenWallet].add(balances[0xb1]);
        balances[0xb1] = 0;
    }
    
    //Check SaleActive
    function saleActive() public constant returns (bool) {
        return (
            (getCurrentTimestamp() >= startDate1 &&
                getCurrentTimestamp() < endDate1 && saleCap > 0) ||
            (getCurrentTimestamp() >= startDate2 &&
                getCurrentTimestamp() < endDate2 && saleCap > 0)
                );
    }
   
    //Get CurrentTS
    function getCurrentTimestamp() internal view returns (uint256) {
        return now;
    }

     //Buy Token
    function buyTokens(address sender, uint256 value) internal {
        //Check Sale Status
        require(saleActive());
        
        //Minum buying limit
        require(value >= 0.5 ether);

        // Calculate token amount to be purchased
        uint256 bonus = getBonusByTime(getCurrentTimestamp());
        uint256 amount = value.mul(bonus);
        // If ETH > 500 the add 10%
        if (getCurrentTimestamp() >= startDate1 && getCurrentTimestamp() < endDate1) {
            uint256 p1Bouns = getBounsByAmount(value, amount);
            amount = amount + p1Bouns;
        }
        // We have enough token to sale
        require(saleCap >= amount);

        // Transfer
        balances[tokenWallet] = balances[tokenWallet].sub(amount);
        balances[sender] = balances[sender].add(amount);
        emit TokenPurchase(sender, value, amount);
        emit Transfer(tokenWallet, sender, amount);
        
        saleCap = saleCap - amount;

        // Update state.
        weiRaised = weiRaised + value;

        // Forward the fund to fund collection wallet.
        fundWallet.transfer(msg.value);
    }   
}