pragma solidity ^0.4.21;

/*
  
    ****************************************************************
    AVALANCHE BLOCKCHAIN GENESIS BLOCK COIN ALLOCATION SALE CONTRACT
    ****************************************************************

    The Genesis Block in the Avalanche will deploy with pre-filled addresses
    according to the results of this token sale.
    
    The Avalanche tokens will be sent to the Ethereum address that buys them.
    
    When the Avalanche blockchain deploys, all ethereum addresses that contains
    Avalanche tokens will be credited with the equivalent AVALANCHE ICE (XAI) in the Genesis Block.

    There will be no developer premine. There will be no private presale. This is it.

    @author CHRIS DCOSTA For Meek Inc 2018.
    
    Reference Code by Hunter Long
    @repo https://github.com/hunterlong/ethereum-ico-contract

*/


contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  function mintToken(address to, uint256 value) public returns (uint256);
  function changeTransfer(bool allowed) public;
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

    event Contribution(address from, uint256 amount);

    constructor(address _wallet) public {
        startBlock = block.number; // imediate start 
        maxMintable = 4045084999529091000000000000; // max sellable (18 decimals)
        ETHWallet = _wallet; // 0x696863b0099394384cd595468b8b6270ea77fC68
        isFunding = true;
        creator = msg.sender;
        exchangeRate = 13483;
    }

    // setup function to be ran only 1 time
    // setup token address
    // setup end Block number
    function setup(address token_address, uint end_block) public {
        require(!configSet);
        Token = ERC20(token_address);
        endBlock = end_block;
        configSet = true;
    }

    function closeSale() external {
      require(msg.sender==creator);
      isFunding = false;
    }

    function () payable public {
        require(msg.value>0);
        require(isFunding);
        require(block.number <= endBlock);
        uint256 amount = msg.value * exchangeRate;
        uint256 total = totalMinted + amount;
        require(total<=maxMintable);
        totalMinted += total;
        ETHWallet.transfer(msg.value);
        Token.mintToken(msg.sender, amount);
        emit Contribution(msg.sender, amount);
    }

    // CONTRIBUTE FUNCTION
    // converts ETH to Avalanche Genesis Block TOKEN and sends new Avalanche TOKEN to the sender
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
        emit Contribution(msg.sender, amount);
    }

    // update the ETH/XAIT rate
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

    // change transfer ability for ERC20 token (toggle on/off) 
    function changeTransferStats(bool _allowed) external {
        require(msg.sender==creator);
        Token.changeTransfer(_allowed);
    }

}