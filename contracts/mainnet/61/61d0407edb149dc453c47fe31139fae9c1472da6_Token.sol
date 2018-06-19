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