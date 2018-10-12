pragma solidity ^0.4.20;


contract Investors {
    /*=================================
    =            MODIFIERS            =
    =================================*/
 
    modifier onlyAdmin(){
        require(msg.sender == ADMINISTRATOR);
        _;
    }
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    event onWithdraw(
        address customerAddress,
        uint256 amount
    );
    
    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "S3DInvestors";
    string public symbol = "S3DInvestors";
    address private ADMINISTRATOR;
    
        
    
   /*================================
    =            DATASETS            =
    ================================*/
    struct investor 
    {   
        address walletAddress;
        uint256 percent;
    }
    mapping(int256 => investor) internal investors_;
    address companyWallet = address(0xB789A1C6e916B20771583aB3Aa8341b054e2CCF9);
    address S3DContract;

    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --  
    */
    constructor()
        public
    {
        ADMINISTRATOR = address(msg.sender);

        // add investor addresses 
        investors_[0] = investor({walletAddress: address(0x6b9aB2e66f55B81f68Ed66787C3D47ae3EBcFED9), percent: 20}); //CG
        investors_[1] = investor({walletAddress: address(0xc53b3878b2c8f7bbc33b9a2f6ec30d7d7cff23b2), percent: 20}); //KP
        investors_[2] = investor({walletAddress: address(0xEb7741354A5682A1a0c4196C842a648Dd7D53E53), percent: 15}); //PA 
        investors_[3] = investor({walletAddress: address(0xf028a085e78c93FC2E549B8A4EfE5A08A453C86D), percent: 15}); //S
        investors_[4] = investor({walletAddress: address(0x074F21a36217d7615d0202faA926aEFEBB5a9999), percent: 10}); //P 
        investors_[5] = investor({walletAddress: companyWallet, percent: 20}); //companyWallet
    }
    
    
    /**
     * Fallback function to handle ethereum that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function()
        payable
        public
    {
        distributeRewards(msg.value);
    }
    
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
   
    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw(uint256 withdrawAmount)
        onlyAdmin()
        public
    {
        require(withdrawAmount < address(this).balance && withdrawAmount > 0.01 ether);
        
        companyWallet.transfer(withdrawAmount);
        
        // fire event
        emit onWithdraw(companyWallet, withdrawAmount);
    }
  

    
    /*----------  HELPERS AND CALCULATORS  ----------*/

     /**
     * This method serves as a way for anyone to spread some love to all tokenholders without buying tokens
     */
    function distributeRewards(uint256 rewards)
        payable
        public
    {   
        require(rewards > 10000 wei);

        uint256 percent1 = (investors_[0].percent * rewards) / 100;
        uint256 percent2 = (investors_[1].percent * rewards) / 100;
        uint256 percent3 = (investors_[2].percent * rewards) / 100;
        uint256 percent4 = (investors_[3].percent * rewards) / 100;
        uint256 percent5 = (investors_[4].percent * rewards) / 100;

        investors_[0].walletAddress.transfer(percent1);
        investors_[1].walletAddress.transfer(percent2);
        investors_[2].walletAddress.transfer(percent3);
        investors_[3].walletAddress.transfer(percent4);
        investors_[4].walletAddress.transfer(percent5);
        investors_[5].walletAddress.transfer(address(this).balance);
    }
    
    /**
     * Method to view the current Ethereum stored in the contract
     * Example: totalEthereumBalance()
     */
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
   
}