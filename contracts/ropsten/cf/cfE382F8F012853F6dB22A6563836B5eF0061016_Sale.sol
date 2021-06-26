/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

pragma solidity ^0.4.21;

/*

  Create this Sale contract first!

     Sale(address ethwallet)   // this will send the received ETH funds to this address




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
        
//uint256 public constant totalSupply = 1000000*10**uint256(decimals); // 1000000000000

        maxMintable = 100000000000000*10**2; // 3 million max sellable (2 decimals)
        ETHWallet = _wallet;
        isFunding = true;
        creator = msg.sender;
        createHeldCoins();
        exchangeRate = 6000000000;
    }

    // setup function to be ran only 1 time
    // setup token address
    // setup end Block number
    function setup(address token_address) {
        require(!configSet);
        Token = ERC20(token_address);
        configSet = true;
    }

    function closeSale() external {
      require(msg.sender==creator);
      isFunding = false;
    }

    function () payable {
        require(msg.value>0);
        require(isFunding);
        uint256 amount = msg.value * exchangeRate;
        uint256 total = totalMinted + amount;
        require(total<=maxMintable);
        totalMinted += total;
        ETHWallet.transfer(msg.value);
        Token.mintToken(msg.sender, amount);
        Contribution(msg.sender, amount);
    }

    // CONTRIBUTE FUNCTION
    // converts ETH to TOKEN and sends new TOKEN to the sender
    function contribute() external payable {
        require(msg.value>0);
        require(isFunding);
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
        createHoldToken(0x2069012BC245d8f9bcF1455A1c61791BE053794f, 15000000000000*10**2);
        createHoldToken(0x0EE1814619784A4618C65964c134653039F742f3, 15000000000000*10**2);
    }

//0x0EE1814619784A4618C65964c134653039F742f3

    // public function to get the amount of tokens held for an address
    function getHeldCoin(address _address) public constant returns (uint256) {
        return heldTokens[_address];
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