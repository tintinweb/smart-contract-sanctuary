pragma solidity ^0.4.18;
/*

0xBitcoin Token Faucet in a Smart Contract (ver 0.0.0)

Any tokens sent to this contract may be withdrawn by other users through use
of the dispense() function. The dispensed amount is dependant on the
transaction&#39;s gas price. This means a transaction sent at 4 gwei will dispense
twice as many tokens as a transaction sent at 2 gwei.

The dispensing "rate" is changable by the contract owner and allows the rate to
be changed over time to follow the token&#39;s price. The intention of this ratio is
to ensure that the value of ether spent as gas is roughly equal to the value of
the tokens received.

Typically calls to dispense() cost about 41879 gas total.

*/


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract GasFaucet is Owned {
    using SafeMath for uint256;

    address public faucetTokenAddress;
    uint256 public priceInWeiPerSatoshi;

    event Dispense(address indexed destination, uint256 sendAmount);

    constructor() public {
        // 0xBitcoin Token Address (Ropsten)
        // faucetTokenAddress = 0x9D2Cc383E677292ed87f63586086CfF62a009010;
        // 0xBitcoin Token Address (Mainnet)
        faucetTokenAddress = 0xB6eD7644C69416d67B522e20bC294A9a9B405B31;

        // Set rate to 0 satoshis / wei. Calls to &#39;dispense&#39; will send 0 tokens
        // until the rate is manually changed.
        priceInWeiPerSatoshi = 0;
    }

    // ------------------------------------------------------------------------
    // Dispense some free tokens. The more gas you spend, the more tokens you
    // recieve. 
    // 
    // Tokens recieved (in satoshi) = gasprice / priceInWeiPerSatoshi
    // ------------------------------------------------------------------------
    function dispense(address destination) public {
        uint256 sendAmount = calculateDispensedTokensForGasPrice(tx.gasprice);
        require(tokenBalance() > sendAmount);

        ERC20Interface(faucetTokenAddress).transfer(destination, sendAmount);

        emit Dispense(destination, sendAmount);
    }
    
    // ------------------------------------------------------------------------
    // Retrieve the current dispensing rate in satoshis per gwei
    // ------------------------------------------------------------------------
    function calculateDispensedTokensForGasPrice(uint256 gasprice) public view returns (uint256) {
        if(priceInWeiPerSatoshi == 0){ 
            return 0; 
        }
        return gasprice.div(priceInWeiPerSatoshi);
    }
    
    // ------------------------------------------------------------------------
    // Retrieve Faucet&#39;s balance 
    // ------------------------------------------------------------------------
    function tokenBalance() public view returns (uint)  {
        return ERC20Interface(faucetTokenAddress).balanceOf(this);
    }
    
    // ------------------------------------------------------------------------
    // Retrieve the current dispensing rate in satoshis per gwei
    // ------------------------------------------------------------------------
    function getWeiPerSatoshi() public view returns (uint256) {
        return priceInWeiPerSatoshi;
    }
    
    // ------------------------------------------------------------------------
    // Set the current dispensing rate in satoshis per gwei
    // ------------------------------------------------------------------------
    function setWeiPerSatoshi(uint256 price) public onlyOwner {
        priceInWeiPerSatoshi = price;
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

    // ------------------------------------------------------------------------
    // Owner can withdraw any accidentally sent eth
    // ------------------------------------------------------------------------
    function withdrawEth(uint256 amount) public onlyOwner {
        require(amount < address(this).balance);
        owner.transfer(amount);
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner {
        
        // Note: Owner has full control of priceInWeiPerSatoshi, so preventing
        // withdrawal of the faucetTokenAddress token serves no purpose. It
        // would merely be misleading.
        //
        // if(tokenAddress == faucetTokenAddress){ 
        //     revert(); 
        // }

        ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}