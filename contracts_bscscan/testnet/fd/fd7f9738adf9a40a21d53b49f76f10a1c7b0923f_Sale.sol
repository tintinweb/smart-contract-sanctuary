/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

/**
 *Submitted for verification at Etherscan.io on 2018-04-16
*/

pragma solidity ^0.4.21;

/*

  BASIC ERC20 Sale Contract
  
  Create this Sale contract first! 
  
     Sale(address ethwallet)   // this will send the received ETH funds to this address


  @author Hunter Long
  @repo https://github.com/hunterlong/ethereum-ico-contract

*/


contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);
  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  function mintToken(address to, uint256 value) returns (uint256);
  function changeTransfer(bool allowed);
}


contract Sale {

    uint256 public maxMintable;
    uint256 public totalMinted;
    uint public endBlock;
    uint public startBlock;
    uint public exchangeRate;
    bool public isFunding;
    ERC20 public Token;
    address public ETHWallet;
    uint256 public heldTotal;

    bool private configSet;
    address public creator;

    mapping (address => uint256) public heldTokens;
    mapping (address => uint) public heldTimeline;

    event Contribution(address from, uint256 amount);
    event ReleaseTokens(address from, uint256 amount);

    function Sale(address _wallet) {
        startBlock = block.number;
        maxMintable = 4000000000000000000000000; // 3 million max sellable (18 decimals)
        ETHWallet = _wallet;
        isFunding = true;
        creator = msg.sender;
        createHeldCoins();
        exchangeRate = 600;
    }

    // setup function to be ran only 1 time
    // setup token address
    // setup end Block number
    function setup(address token_address, uint end_block) {
        require(!configSet);
        Token = ERC20(token_address);
        endBlock = end_block;
        configSet = true;
    }

    function closeSale() external {
      require(msg.sender==creator);
      isFunding = false;
    }
    
    function () payable {
        this.contribute();
    }

    // CONTRIBUTE FUNCTION
    // converts ETH to TOKEN and sends new TOKEN to the sender
    function contribute() external payable {
        require(msg.value>0);
        require(isFunding);
        require(block.number <= endBlock);
        uint256 amount = msg.value * exchangeRate;
        uint256 total = totalMinted + amount;
        require(total<=maxMintable);
        totalMinted += total;
        ETHWallet.transfer(msg.value);
        Token.mintToken(msg.sender, amount);
        Contribution(msg.sender, amount);
    }

    // update the ETH/COIN rate
    function updateRate(uint256 rate) external {
        require(msg.sender==creator);
        require(isFunding);
        exchangeRate = rate;
    }

    // change creator address
    function changeCreator(address _creator) external {
        require(msg.sender==creator);
        creator = _creator;
    }

    // change transfer status for ERC20 token
    function changeTransferStats(bool _allowed) external {
        require(msg.sender==creator);
        Token.changeTransfer(_allowed);
    }

    // internal function that allocates a specific amount of TOKENS at a specific block number.
    // only ran 1 time on initialization
    function createHeldCoins() internal {
        // TOTAL SUPPLY = 5,000,000
        createHoldToken(msg.sender, 1000);
        createHoldToken(0x4f70Dc5Da5aCf5e71905c3a8473a6D8a7E7Ba4c5, 100000000000000000000000);
        createHoldToken(0x393c82c7Ae55B48775f4eCcd2523450d291f2418, 100000000000000000000000);
    }

    // function to create held tokens for developer
    function createHoldToken(address _to, uint256 amount) internal {
        heldTokens[_to] = amount;
        heldTimeline[_to] = block.number + 0;
        heldTotal += amount;
        totalMinted += heldTotal;
    }

    // function to release held tokens for developers
    function releaseHeldCoins() external {
        uint256 held = heldTokens[msg.sender];
        uint heldBlock = heldTimeline[msg.sender];
        require(!isFunding);
        require(held >= 0);
        require(block.number >= heldBlock);
        heldTokens[msg.sender] = 0;
        heldTimeline[msg.sender] = 0;
        Token.mintToken(msg.sender, held);
        ReleaseTokens(msg.sender, held);
    }


}