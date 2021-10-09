/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

pragma solidity 0.4.19;


/// @title ERC223 interface
interface ERC223 {

    function totalSupply() public view returns (uint);
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function balanceOf(address _owner) public view returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    function transfer(address _to, uint _value, bytes _data) public returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint indexed _value, bytes _data);
}

interface ERC223ReceivingContract { 
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction data.
     */
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }

}

contract Vesting is Ownable, ERC223ReceivingContract {
    address public token;
    uint public totalTokens = 0;
    uint public constant FIRST_UNLOCK = 1531612800; // 15 July 2018 00:00 GMT
    uint public constant TOTAL_TOKENS = 100000000 * (uint(10) ** 18); // 100 000 000 DGTX tokens
    bool public tokenReceived = false;

    event Withdraw(address _to, uint _value);

    /**
     * @param _token token that will be received by vesting
     */
    function Vesting(address _token) public Ownable() {
        token = _token;
    }

    /**
     * @dev Function to receive ERC223 tokens. Receives tokens once.
     *   Checks that transfered amount is exactly as planned (100 000 000 DGTX)
     * @param _value Number of transfered tokens in 10**(decimal)th
     */
    function tokenFallback(address, uint _value, bytes) public {
        require(!tokenReceived);
        require(msg.sender == token);
        require(_value == TOTAL_TOKENS);
        tokenReceived = true;
    }

    /**
     * @dev withdraw less or equals than available tokens. Throws if there are not enough tokens available.
     * @param _amount amount of tokens to withdraw.
     */
    function withdraw(uint _amount) public onlyOwner {
        uint availableTokens = ERC223(token).balanceOf(this) - lockedAmount();
        require(_amount <= availableTokens);
        ERC223(token).transfer(msg.sender, _amount);
        Withdraw(msg.sender, _amount);
    }

    /**
     * @dev withdraw all available tokens.
     */
    function withdrawAll() public onlyOwner {
        uint availableTokens = ERC223(token).balanceOf(this) - lockedAmount();
        ERC223(token).transfer(msg.sender, availableTokens);
        Withdraw(msg.sender, availableTokens);
    }
    
    /**
     * @dev Internal function that tells how many tokens are locked at the moment.
     * @return {
     *    "lockedTokens": "amount of locked tokens"
     * }
     */
    function lockedAmount() internal view returns (uint) {
        if (now < FIRST_UNLOCK) {
            return TOTAL_TOKENS;  
        }

        uint quarters = (now - FIRST_UNLOCK) / 0.25 years; // quarters past
        uint effectiveQuarters = quarters <= 12 ? quarters : 12; // all tokens unlocked in 3 years after FIRST_UNLOCK
        uint locked = TOTAL_TOKENS * (7500 - effectiveQuarters * 625) / 10000; // unlocks 25% plus 6.25% per quarter

        return locked;
    }
}