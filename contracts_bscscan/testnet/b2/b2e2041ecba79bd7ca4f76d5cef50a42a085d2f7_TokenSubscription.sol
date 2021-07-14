/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

pragma solidity ^0.4.18;


// ----------------------------------------------------------------------------

// Token Subscription contract

// Stores dates of premium service, enabled by micropayments

//  A Mapping stores subscription states from streamers to the contract balance
//  A Mapping stores subscription states from users to streamers

//


// ----------------------------------------------------------------------------



// ----------------------------------------------------------------------------

// Safe maths

// ----------------------------------------------------------------------------

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {

        c = a + b;

        require(c >= a);

    }

    function sub(uint a, uint b) internal pure returns (uint c) {

        require(b <= a);

        c = a - b;

    }

    function mul(uint a, uint b) internal pure returns (uint c) {

        c = a * b;

        require(a == 0 || c / a == b);

    }

    function div(uint a, uint b) internal pure returns (uint c) {

        require(b > 0);

        c = a / b;

    }

}



library ExtendedMath {


    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {

        if(a > b) return b;

        return a;

    }
}

// ----------------------------------------------------------------------------

// ERC Token Standard #20 Interface

// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

// ----------------------------------------------------------------------------

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


    constructor() public {

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

        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;

        newOwner = address(0);

    }

}




// ----------------------------------------------------------------------------

// ERC20 Token, with the addition of symbol, name and decimals and an

// initial fixed supply

// ----------------------------------------------------------------------------

contract TokenSubscription is Owned {

    using SafeMath for uint;
    using ExtendedMath for uint;


    uint subscriptionPriceFactor;


    address public tokenCurrency;

    event SubscriptionExtended(address from, address to, uint amount);


    mapping(address => mapping(address => uint256)) subscribedUntil;


    address public originalContractAddress;


    // ------------------------------------------------------------------------

    // Constructor

    // ------------------------------------------------------------------------

    constructor() public  {

        tokenCurrency = 0x6c1717e8517b024b49982e2135be217f7d0014f9;

        subscriptionPriceFactor = 1000000;

    }

    function setSubscriptionPriceFactor(uint newFactor) public onlyOwner returns (bool success)
    {
        require(newFactor > 0);

        subscriptionPriceFactor = newFactor;

        return true;
    }

    function subscribeToAccount(address from, address to, uint amount) public returns (bool success)
    {
      //The 'from' address pays the 'to' address
      require(ERC20Interface(tokenCurrency).transferFrom(from,to,amount));

      //Additional subscription time is calculated based on the amount spent
      uint additionalSubscriptionSeconds = amount.mul(1000).div(subscriptionPriceFactor);

      uint currentSubscriptionTime = getSubscribedUntilTime(from,to).sub(now);

      if(currentSubscriptionTime < 0)
      {
        currentSubscriptionTime = 0;
      }


      //set the new date mapping, the new subscription expiration time
      subscribedUntil[from][to] = (now.add(currentSubscriptionTime).add( additionalSubscriptionSeconds ));

      emit SubscriptionExtended(from,to,amount);

      return true;
    }


    function getSubscribedUntilTime(address from, address to) public view returns (uint time)
    {

      return subscribedUntil[from][to]; //Unix timestamp

    }




    // ------------------------------------------------------------------------

    // Token owner can approve for `spender` to transferFrom(...) `tokens`

    // from the token owner's account. The `spender` contract function

    // `receiveApproval(...)` is then executed

    // ------------------------------------------------------------------------

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {

        subscribeToAccount(spender,this,tokens);

        return true;

    }



    // ------------------------------------------------------------------------

    // Don't accept ETH

    // ------------------------------------------------------------------------

    function () public payable {

        revert();

    }



    // ------------------------------------------------------------------------

    // Owner can transfer out any accidentally sent ERC20 tokens

    // ------------------------------------------------------------------------

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {

        return ERC20Interface(tokenAddress).transfer(owner, tokens);

    }


}