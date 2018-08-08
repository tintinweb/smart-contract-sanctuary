pragma solidity ^0.4.11;

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }
}


contract IndorsePreSale is SafeMath{
    // Fund deposit address
    address public ethFundDeposit = "0x1c82ee5b828455F870eb2998f2c9b6Cc2d52a5F6";                              
    address public owner;                                       // Owner of the pre sale contract
    mapping (address => uint256) public whiteList;

    // presale parameters
    bool public isFinalized;                                    // switched to true in operational state
    uint256 public constant maxLimit =  14000 ether;            // Maximum limit for taking in the money
    uint256 public constant minRequired = 100 ether;            // Minimum contribution per person
    uint256 public totalSupply;
    mapping (address => uint256) public balances;
    
    // events
    event Contribution(address indexed _to, uint256 _value);
    
    modifier onlyOwner() {
      require (msg.sender == owner);
      _;
    }

    // @dev constructor
    function IndorsePreSale() {
      isFinalized = false;                                      //controls pre through crowdsale state
      owner = msg.sender;
      totalSupply = 0;
    }

    // @dev this function accepts Ether and increases the balances of the contributors
    function() payable {           
      uint256 checkedSupply = safeAdd(totalSupply, msg.value);
      require (msg.value >= minRequired);                        // The contribution needs to be above 100 Ether
      require (!isFinalized);                                    // Cannot accept Ether after finalizing the contract
      require (checkedSupply <= maxLimit);
      require (whiteList[msg.sender] == 1);
      balances[msg.sender] = safeAdd(balances[msg.sender], msg.value);
      
      totalSupply = safeAdd(totalSupply, msg.value);
      Contribution(msg.sender, msg.value);
      ethFundDeposit.transfer(this.balance);                     // send the eth to Indorse multi-sig
    }
    
    // @dev adds an Ethereum address to whitelist
    function setWhiteList(address _whitelisted) onlyOwner {
      whiteList[_whitelisted] = 1;
    }

    // @dev removed an Ethereum address from whitelist
    function removeWhiteList(address _whitelisted) onlyOwner {
      whiteList[_whitelisted] = 0;
    }

    /// @dev Ends the funding period and sends the ETH home
    function finalize() external onlyOwner {
      require (!isFinalized);
      // move to operational
      isFinalized = true;
      ethFundDeposit.transfer(this.balance);                     // send the eth to Indorse multi-sig
    }
}