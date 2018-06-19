pragma solidity ^ 0.4.15;

/**
*library name : SafeMath
*purpose : be the library for the smart contract for the swap between the godz and ether
*goal : to achieve the secure basic math operations
*/
library SafeMath {

  /*function name : mul*/
  /*purpose : be the funcion for safe multiplicate*/
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    /*assert(a == 0 || c / a == b);*/
    return c;
  }

  /*function name : div*/
  /*purpose : be the funcion for safe division*/
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  /*function name : sub*/
  /*purpose : be the funcion for safe substract*/
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    /*assert(b <= a);*/
    return a - b;
  }

  /*function name : add*/
  /*purpose : be the funcion for safe sum*/
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    /*assert(c >= a);*/
    return c;
  }
}

/**
*contract name : ReentryProtected
*/
contract ReentryProtected{
    /*The reentry protection state mutex.*/
    bool __reMutex;

    /**
    *This modifier can be used on functions with external calls to
    *prevent reentry attacks.
    *Constraints:
    *Protected functions must have only one point of exit.
    *Protected functions cannot use the `return` keyword
    *Protected functions return values must be through return parameters.
    */
    modifier preventReentry() {
        require(!__reMutex);
        __reMutex = true;
        _;
        delete __reMutex;
        return;
    }

    /**
    *This modifier can be applied to public access state mutation functions
    *to protect against reentry if a `preventReentry` function has already
    *set the mutex. This prevents the contract from being reenter under a
    *different memory context which can break state variable integrity.
    */
    modifier noReentry() {
        require(!__reMutex);
        _;
    }
}

/**
*contract name : GodzSwapGodzEtherCompliance
*purpose : be the smart contract for compliance of the greater than usd5000
*/
contract GodzSwapGodzEtherCompliance{
    //address of the owner of the contract
    address public owner;
    
    /*structure for store the sale*/
    struct GodzBuyAccounts
    {
        uint256 amount;/*amount sent*/
        address account;/*account that sent*/
        uint sendGodz;/*if send the godz back*/
    }

    /*mapping of the acounts that send more than usd5000*/
    mapping(uint=>GodzBuyAccounts) public accountsHolding;
    
    /*index of the account information*/
    uint public indexAccount = 0;

    /*account information*/
    address public swapContract;/*address of the swap contract*/


    /*function name : GodzSwapGodzEtherCompliance*/
    /*purpose : be the constructor and the setter of the owner*/
    /*goal : to set the owner of the contract*/    
    function GodzSwapGodzEtherCompliance()
    {
        /*sets the owner of the contract than compliance with the greater than usd5000 maximiun*/
        owner = msg.sender;
    }

    /*function name : setHolderInformation*/
    /*purpose : be the setter of the swap contract and wallet holder*/
    /*goal : to set de swap contract address and the wallet holder address*/    
    function setHolderInformation(address _swapContract)
    {    
        /*if the owner is setting the information of the holder and the swap*/
        if (msg.sender==owner)
        {
            /*address of the swap contract*/
            swapContract = _swapContract;
        }
    }

    /*function name : SaveAccountBuyingGodz*/
    /*purpose : be the safe function that map the account that send it*/
    /*goal : to store the account information*/
    function SaveAccountBuyingGodz(address account, uint256 amount) public returns (bool success) 
    {
        /*if the sender is the swapContract*/
        if (msg.sender==swapContract)
        {
            /*increment the index*/
            indexAccount += 1;
            /*store the account informacion*/
            accountsHolding[indexAccount].account = account;
            accountsHolding[indexAccount].amount = amount;
            accountsHolding[indexAccount].sendGodz = 0;
            /*transfer the ether to the wallet holder*/
            /*account save was completed*/
            return true;
        }
        else
        {
            return false;
        }
    }

    /*function name : setSendGodz*/
    /*purpose : be the flag update for the compliance account*/
    /*goal : to get the flag on the account*/
    function setSendGodz(uint index) public 
    {
        if (owner == msg.sender)
        {
            accountsHolding[index].sendGodz = 1;
        }
    }

    /*function name : getAccountInformation*/
    /*purpose : be the getter of the information of the account*/
    /*goal : to get the amount and the acount of a compliance account*/
    function getAccountInformation(uint index) public returns (address account, uint256 amount, uint sendGodz)
    {
        /*return the account of a compliance*/
        return (accountsHolding[index].account, accountsHolding[index].amount, accountsHolding[index].sendGodz);
    }
}

/**
*contract name : GodzSwapGodzEther
*purpose : be the smart contract for the swap between the godz and ether
*goal : to achieve the swap transfers
*/
contract GodzSwapGodzEther  is ReentryProtected{
    address public seller;/*address of the owner of the contract creation*/
    address public tokenContract;/*address of the erc20 token smart contract for the swap*/
    address public complianceContract;/*compliance contract*/
    address public complianceWallet;/*compliance wallet address*/
    uint256 public sellPrice;/*value price of the swap*/
    uint256 public sellQuantity;/*quantity value of the swap*/

    /*function name : GodzSwapGodzEther*/
    /*purpose : be the constructor of the swap smart contract*/
    /*goal : register the basic information of the swap smart contract*/
    function GodzSwapGodzEther(
    address token,
    address complianceC,
    address complianceW
    ){
        tokenContract = token;
        /*owner of the quantity of supply of the erc20 token*/
        seller = msg.sender;
        /*swap price of the token supply*/
        sellPrice = 0.00625 * 1 ether;
        /*total quantity to swap*/
        sellQuantity = SafeMath.mul(210000000, 1 ether);
        /*compliance contract store accounts*/
        complianceContract = complianceC;
        /*compliance wallet holder*/
        complianceWallet = complianceW;
    }

    /*function name : () payable*/
    /*purpose : be the swap executor*/
    /*goal : to transfer the godz to the investor and the ether to the owner of the godz*/
    function() payable preventReentry
    {
        /*address of the buyer*/
        address buyer = msg.sender;

        /*value paid and receive on the swap call*/
        uint256 valuePaid = msg.value;

        /*set the quantity of godz on behalf of the ether that is send to this function*/
  		  uint256 buyQuantity = SafeMath.mul((SafeMath.div(valuePaid, sellPrice)), 1 ether);

        /*gets the balance of the owner of the godz*/
        uint256 balanceSeller = Token(tokenContract).balanceOf(seller);

        /*get the allowance of the owner of the godz*/
  		uint256 balanceAllowed = Token(tokenContract).allowance(seller,this);

        if (seller!=buyer) /*if the seller of godz on swap is different than the investor buying*/
        {
            /*if the balance and the allowance match a valid quantity swap*/
      		if ((balanceAllowed >= buyQuantity) && (balanceSeller >= buyQuantity))
            {
                /*if the msg.value(ether sent) is greater than compliance, store it and sent to the wallet holder*/
                if (valuePaid>(20 * 1 ether))
                {
                    /*transfer the value(ether) to the compliance holder wallet*/
                    complianceWallet.transfer(valuePaid);
                    /*save the account information*/
                    require(GodzSwapGodzEtherCompliance(complianceContract).SaveAccountBuyingGodz(buyer, valuePaid));
                }
                else
                {
                    /*transfer the ether inside to the seller of the godz*/
                    seller.transfer(valuePaid);
                    /*call the transferfrom function of the erc20 token smart contract*/
                    require(Token(tokenContract).transferFrom(seller, buyer, buyQuantity));
                }
            }
            else/*if not a valid match between allowance and balance of the owner of godz, return the ether*/
            {
                /*send back the ether received*/
                buyer.transfer(valuePaid);
            }
        }
    }

    /*function name : safeWithdrawal*/
    /*purpose : be the safe withrow function in case of the contract keep ether inside*/
    /*goal : to transfer the ether to the owner of the swap contract*/
    function safeWithdrawal()
    {
        /*requires that the contract call is the owner of the swap contract*/
        /*require(seller == msg.sender);*/
        /*if the seller of the godz is the call contract address*/
        if (seller == msg.sender)
        {
            /*transfer the ether inside to the seller of the godz*/
            seller.transfer(this.balance);
        }
    }
}

/**
*contract name : tokenRecipient
*/
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

/**
*contract name : Token
*/
contract Token {
    /*using the secure math library for basic math operations*/
    using SafeMath for uint256;

    /* Public variables of the token */
    string public standard = &#39;DSCS.GODZ.TOKEN&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function Token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;                  /* Give the creator all initial tokens*/
        totalSupply = initialSupply;                            /* Update total supply*/
        name = tokenName;                                       /* Set the name for display purposes*/
        symbol = tokenSymbol;                                   /* Set the symbol for display purposes*/
        decimals = decimalUnits;                                /* Amount of decimals for display purposes*/
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) revert();                               /* Prevent transfer to 0x0 address. Use burn() instead*/
        if (balanceOf[msg.sender] < _value) revert();           /* Check if the sender has enough*/
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); /* Check for overflows*/
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                        /* Subtract from the sender*/
        balanceOf[_to] = balanceOf[_to].add(_value);                               /* Add the same to the recipient*/
        Transfer(msg.sender, _to, _value);                      /* Notify anyone listening that this transfer took place*/
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* A contract attempts to get the coins but transfer from the origin*/
    function transferFromOrigin(address _to, uint256 _value)  returns (bool success) {
        address origin = tx.origin;
        if (origin == 0x0) revert();
        if (_to == 0x0) revert();                                /* Prevent transfer to 0x0 address.*/
        if (balanceOf[origin] < _value) revert();                /* Check if the sender has enough*/
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  /* Check for overflows*/
        balanceOf[origin] = balanceOf[origin].sub(_value);       /* Subtract from the sender*/
        balanceOf[_to] = balanceOf[_to].add(_value);             /* Add the same to the recipient*/
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) revert();                                /* Prevent transfer to 0x0 address.*/
        if (balanceOf[_from] < _value) revert();                 /* Check if the sender has enough*/
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  /* Check for overflows*/
        if (_value > allowance[_from][msg.sender]) revert();     /* Check allowance*/
        balanceOf[_from] = balanceOf[_from].sub(_value);                              /* Subtract from the sender*/
        balanceOf[_to] = balanceOf[_to].add(_value);                                /* Add the same to the recipient*/
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

}