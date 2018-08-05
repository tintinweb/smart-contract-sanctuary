pragma solidity ^0.4.21;

/* This contract is the Proof of Community whale contract that will buy and sell tokens to share dividends to token holders.
   This contract can also handle multiple games to donate ETH to it, which will be needed for future game developement.

    Kenny - Solidity developer
	Bungalogic - website developer, concept and design, graphics. 


   该合同是社区鲸鱼合同的证明，它将购买和出售代币以向代币持有者分享股息。
   该合同还可以处理多个游戏以向其捐赠ETH，这将是未来游戏开发所需要的。  

   Kenny  -  Solidity开发人员
   Bungalogic  - 网站开发人员，概念和设计，图形。
*/



contract Kujira 
{ 
    /*
      Modifiers
      修饰符
     */

    // Only the people that published this contract
    // 只有发布此合同的人才
    modifier onlyOwner()
    {
        require(msg.sender == owner || msg.sender == owner2);
        _;
    }
    
    // Only PoC token contract
    // 只有PoC令牌合同
    modifier notPoC(address aContract)
    {
        require(aContract != address(pocContract));
        _;
    }
   
    /*
      Events
      活动
     */
    event Deposit(uint256 amount, address depositer);
    event Purchase(uint256 amountSpent, uint256 tokensReceived);
    event Sell();
    event Payout(uint256 amount, address creditor);
    event Transfer(uint256 amount, address paidTo);

   /**
      Global Variables
      全局变量
     */
    address owner;
    address owner2;
    PoC pocContract;
    uint256 tokenBalance;
   
    
    /*
       Constructor
       施工人
     */
    constructor(address owner2Address) 
    public 
    {
        owner = msg.sender;
        owner2 = owner2Address;
        pocContract = PoC(address(0x1739e311ddBf1efdFbc39b74526Fd8b600755ADa));
        tokenBalance = 0;
    }
    
    function() payable public { }
     
    /*
      Only way to give contract ETH and have it immediately use it, is by using donate function
      给合同ETH并让它立即使用的唯一方法是使用捐赠功能
     */
    function donate() 
    public payable 
    {
        //You have to send more than 1000000 wei
        //你必须发送超过1000000 wei
        require(msg.value > 1000000 wei);
        uint256 ethToTransfer = address(this).balance;
        uint256 PoCEthInContract = address(pocContract).balance;
       
        // if PoC contract balance is less than 5 ETH, PoC is dead and there is no reason to pump it
        // 如果PoC合同余额低于5 ETH，PoC已经死亡，没有理由将其泵出
        if(PoCEthInContract < 5 ether)
        {
            pocContract.exit();
            tokenBalance = 0;
            ethToTransfer = address(this).balance;

            owner.transfer(ethToTransfer);
            emit Transfer(ethToTransfer, address(owner));
        }

        // let&#39;s buy and sell tokens to give dividends to PoC tokenholders
        // 让我们买卖代币给PoC代币持有人分红
        else
        {
            tokenBalance = myTokens();

             // if token balance is greater than 0, sell and rebuy 
             // 如果令牌余额大于0，则出售并重新购买

            if(tokenBalance > 0)
            {
                pocContract.exit();
                tokenBalance = 0; 

                ethToTransfer = address(this).balance;

                if(ethToTransfer > 0)
                {
                    pocContract.buy.value(ethToTransfer)(0x0);
                }
                else
                {
                    pocContract.buy.value(msg.value)(0x0);
                }
            }
            else
            {   
                // we have no tokens, let&#39;s buy some if we have ETH balance
                // 我们没有代币，如果我们有ETH余额，我们就买一些
                if(ethToTransfer > 0)
                {
                    pocContract.buy.value(ethToTransfer)(0x0);
                    tokenBalance = myTokens();
                    emit Deposit(msg.value, msg.sender);
                }
            }
        }
    }

    
    /**
       Number of tokens the contract owns.
       合同拥有的代币数量。
     */
    function myTokens() 
    public 
    view 
    returns(uint256)
    {
        return pocContract.myTokens();
    }
    
    /**
       Number of dividends owed to the contract.
       欠合同的股息数量。
     */
    function myDividends() 
    public 
    view 
    returns(uint256)
    {
        return pocContract.myDividends(true);
    }

    /**
       ETH balance of contract
       合约的ETH余额
     */
    function ethBalance() 
    public 
    view 
    returns (uint256)
    {
        return address(this).balance;
    }

    /**
       If someone sends tokens other than PoC tokens, the owner can return them.
       如果有人发送除PoC令牌以外的令牌，则所有者可以退回它们。
     */
    function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) 
    public 
    onlyOwner() 
    notPoC(tokenAddress) 
    returns (bool success) 
    {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }
    
}

// Define the PoC token for the contract
// 为合同定义PoC令牌
contract PoC 
{
    function buy(address) public payable returns(uint256);
    function exit() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
    function totalEthereumBalance() public view returns(uint);
}

// Define ERC20Interface.transfer, so contract can transfer tokens accidently sent to it.
// 定义ERC20 Interface.transfer，因此合同可以转移意外发送给它的令牌。
contract ERC20Interface 
{
    function transfer(address to, uint256 tokens) 
    public 
    returns (bool success);
}