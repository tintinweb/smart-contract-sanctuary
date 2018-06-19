pragma solidity ^0.4.13;

contract Calculator {
    function getAmount(uint value) constant returns (uint);
}

contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Sale is Ownable {

    //responsible for getting token amount
    Calculator calculator;

    //which token should we sell
    ERC20 token;

    // who sells his tokens
    address tokenSeller;

    uint256 public minimalTokens = 100000000000;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    function Sale(address tokenAddress, address calculatorAddress) {
        tokenSeller = msg.sender;
        token = ERC20(tokenAddress);
        setCalculatorAddress(calculatorAddress);
    }

    function () payable {
        buyTokens();
    }

    function buyTokens() payable {
        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = calculator.getAmount(weiAmount);
        assert(tokens >= minimalTokens);

        token.transferFrom(tokenSeller, msg.sender, tokens);
        TokenPurchase(msg.sender, weiAmount, tokens);
    }

    function setTokenSeller(address newTokenSeller) onlyOwner {
        tokenSeller = newTokenSeller;
    }

    function setCalculatorAddress(address calculatorAddress) onlyOwner {
        calculator = Calculator(calculatorAddress);
    }

    function setMinimalTokens(uint256 _minimalTokens) onlyOwner {
        minimalTokens = _minimalTokens;
    }

    function withdraw(address beneficiary, uint amount) onlyOwner {
        require(beneficiary != 0x0);

        beneficiary.transfer(amount);
    }
}