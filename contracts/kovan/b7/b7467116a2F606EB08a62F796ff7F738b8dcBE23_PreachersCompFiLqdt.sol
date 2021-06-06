/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

// SPDX-License-Identifier: GPL-3.0-or-later

/**********************************************************
 * Main Contract: PreachersCompFiLqdt v1.0.9 AH
 **********************************************************/
pragma solidity ^0.8.4;

interface IKyberNetworkProxy {

    event ExecuteTrade(
        address indexed trader,
        ERC20 src,
        ERC20 dest,
        address destAddress,
        uint256 actualSrcAmount,
        uint256 actualDestAmount,
        address platformWallet,
        uint256 platformFeeBps
    );

    /// @notice Backward compatible function
    /// @notice Use token address ETH_TOKEN_ADDRESS for ether
    /// @dev Trade from src to dest token and sends dest token to destAddress
    /// @param src Source token
    /// @param srcAmount Amount of src tokens in twei
    /// @param dest Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens in twei
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade reverts
    /// @param walletId Platform wallet address for receiving fees
    /// @param hint Advanced instructions for running the trade 
    /// @return Amount of actual dest tokens in twei
    function tradeWithHint(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable walletId,
        bytes calldata hint
    ) external payable returns (uint256);

    /// @notice Use token address ETH_TOKEN_ADDRESS for ether
    /// @dev Trade from src to dest token and sends dest token to destAddress
    /// @param src Source token
    /// @param srcAmount Amount of src tokens in twei
    /// @param dest Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens in twei
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade reverts
    /// @param platformWallet Platform wallet address for receiving fees
    /// @param platformFeeBps Part of the trade that is allocated as fee to platform wallet. Ex: 10000 = 100%, 100 = 1%
    /// @param hint Advanced instructions for running the trade 
    /// @return destAmount Amount of actual dest tokens in twei
    function tradeWithHintAndFee(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable returns (uint256 destAmount);

    /// @notice Backward compatible function
    /// @notice Use token address ETH_TOKEN_ADDRESS for ether
    /// @dev Trade from src to dest token and sends dest token to destAddress
    /// @param src Source token
    /// @param srcAmount Amount of src tokens in twei
    /// @param dest Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens in twei
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade reverts
    /// @param platformWallet Platform wallet address for receiving fees
    /// @return Amount of actual dest tokens in twei
    function trade(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet
    ) external payable returns (uint256);

    /// @notice backward compatible
    /// @notice Rate units (10 ** 18) => destQty (twei) / srcQty (twei) * 10 ** 18
    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint256 srcQty
    ) external view returns (uint256 expectedRate, uint256 worstRate);

    function getExpectedRateAfterFee(
        ERC20 src,
        ERC20 dest,
        uint256 srcQty,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external view returns (uint256 expectedRate);
}

interface ERC20 {
  function liquidateBorrow ( address borrower, uint256 repayAmount, address cTokenCollateral ) external returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address owner ) external view returns ( uint256 );
  function balanceOfUnderlying ( address owner ) external returns ( uint256 );
  function decimals (  ) external view returns ( uint256 );
  function mint ( uint256 mintAmount ) external returns ( uint256 );
  function symbol (  ) external view returns ( string memory );
  function totalSupply ( ) external view returns (uint256 supply);
  function transfer ( address dst, uint256 amount ) external returns ( bool );
  function transferFrom ( address src, address dst, uint256 amount ) external returns ( bool );
  function underlying (  ) external view returns ( address );
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

address constant kUnitroller = 0x5eAe89DC1C671724A672ff0630122ee834098657; // Kovan
address constant kComptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B; // Kovan
address constant kcUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;   // Kovan
address constant kcETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;   // Kovan
address constant kUSDC = 0x03226d9241875DbFBfE0e814ADF54151e4F3fd4B;   // Kovan

// Kyber Kovan Test Network
address constant kKyberNetworkProxy = 0xc153eeAD19e0DBbDb3462Dcc2B703cC6D738A37c; // KOVAN
	// IKyberNetworkProxy: Fetch rates and execute trades
address constant kKyberNetworkProxyV1 = 0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D; // KOVAN

address constant kKyberStorage = 0xB18D90bE9ADD2a6c9F2c3943B264c3dC86E30cF5; // KOVAN
	// IKyberStorage: Get reserve IDs for building hints

address constant kKyberHintHandler = 0x9Cf739155941A3A7964E711543A8BC902613fF17; // KOVAN
	// IKyberHint: Building and parsing hints

address constant kKyberFeeHandlerETH = 0xA943b542D1d5683d3454bD0D7EE86C48F36eCFd5; // KOVAN
	// IKyberFeeHandler: Claim staker rewards, reserve rebates or platform fees

address constant kKyberReserve = 0x45460BD0f9a68b98Bf1f5c478B7584E057e32eF5; // KOVAN
	// IKyberReserve: Fetch rates of a specific reserve

address constant kConversionRates = 0x6B2e614977F893baddf3AA704698BD71BEf9CeFF; // KOVAN

address constant kETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;	// Kovan
address constant kBAT = 0x9f8cFB61D3B2aF62864408DD703F9C3BEB55dff7;	// Kovan
address constant kKNC = 0xad67cB4d63C9da94AcA37fDF2761AaDF780ff4a2;	// Kovan
address constant kDAI = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;	// Kovan
address constant kMANA = 0xcb78b457c1F79a06091EAe744aA81dc75Ecb1183;	// Kovan
address constant kMKR = 0xAaF64BFCC32d0F15873a02163e7E500671a4ffcD;	// Kovan
address constant kOMG = 0xdB7ec4E4784118D9733710e46F7C83fE7889596a;	// Kovan
address constant kPOLY = 0xd92266fd053161115163a7311067F0A4745070b5;	// Kovan
address constant kREP = 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa;	// Kovan
address constant kSAI = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;	// Kovan
address constant kSALT = 0x6fEE5727EE4CdCBD91f3A873ef2966dF31713A04;	// Kovan
address constant kSNT = 0x4c99B04682fbF9020Fcb31677F8D8d66832d3322;	// Kovan
address constant kWETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;	// Kovan
address constant kZIL = 0xAb74653cac23301066ABa8eba62b9Abd8a8c51d6;	// Kovan

/**********************************************************
 * Main Contract: PreachersCompFiLqdt v1.0.9
 **********************************************************/
contract PreachersCompFiLqdt {

    // Contract owner
    address payable public owner;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner!");
        _;
    }

    constructor() payable {

        // Track the contract owner
        owner = payable(msg.sender);
        
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /***************************************************************************
     * KyberSwap functions
    ****************************************************************************/
    /// Swap from srcToken to destToken (including ether)
    function executeKyberSwap( ERC20 cSrcToken, uint256 srcQty, ERC20 cDestToken, 
        address payable destAddress, uint256 maxDestAmount
    ) public  returns ( uint256 ) {

        emit KyberSwapETH( destAddress, address(cSrcToken), srcQty, address(cDestToken), maxDestAmount);

        IKyberNetworkProxy cKyberProxy = IKyberNetworkProxy( kKyberNetworkProxy );
        

        // If the source token is not ETH (ie. an ERC20 token), the user is 
		// required to first call the ERC20 approve function to give an allowance
		// to the smart contract executing the transferFrom function.
        if (address(cSrcToken) != kETH) {

            // mitigate ERC20 Approve front-running attack, by initially setting
            // allowance to 0
            require(cSrcToken.approve(address(this), 0), "approval to 0 failed");

            // set the spender's token allowance to srcQty
            require(cSrcToken.approve(address(this), srcQty), "approval to srcQty failed");
            emit ApprovedSrcSwap( address(cSrcToken), srcQty );
        }

        // Get the minimum conversion rate
		// https://developer.kyber.network/docs/Integrations-SmartContractGuide/#fetching-rates

        uint256 minConversionRate = kyberGetExpectedRate( cSrcToken, srcQty,  cDestToken );


        /*********************************************************************************
         * function trade(ERC20 src, uint256 srcAmount,
         *  ERC20 dest, address payable destAddress,
         *  uint256 maxDestAmount,    // wei
         * 
         *  uint256 minConversionRate,
         *      Minimum conversion rate (in wei). Trade is canceled if actual rate is lower
         *      Should match makerAssetAmount/takerAssetAmount
         *      This rate means for every 1 srcAmount, a Minimum
         *      of X target Tokens are expected. 
         *      (Source token value / Target Token value) * 10**18 
         * 
         *  address payable platformWallet ) external payable returns (uint256);
        **********************************************************************************/
        // Execute the trade and send to this contract to use to pay down the unsafe account

        /*********************************************************************************
        uint256 destAmount = cKyberProxy.trade(
            cSrcToken, srcQty, 
            cDestToken, payable(address(this)),
            maxDestAmount, 
            minConversionRate,
            payable(address(this)) );
        **********************************************************************************/


    /// @notice Use token address ETH_TOKEN_ADDRESS for ether
    /// @dev Trade from src to dest token and sends dest token to destAddress
    /// @param src Source token
    /// @param srcAmount Amount of src tokens in twei
    /// @param dest Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens in twei
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade reverts
    /// @param walletId Platform wallet address for receiving fees
    /// @param hint Advanced instructions for running the trade 
    /// @return Amount of actual dest tokens in twei
        /*********************************************************************************
        function tradeWithHint(
            ERC20 src,
            uint256 srcAmount,
            ERC20 dest,
            address payable destAddress,
            uint256 maxDestAmount,
            uint256 minConversionRate,
            address payable walletId,
            bytes calldata hint
        ) external payable returns (uint256);
        **********************************************************************************/
        uint256 destAmount = cKyberProxy.tradeWithHint(
            cSrcToken,
            srcQty, 
            cDestToken,
            destAddress,
            maxDestAmount, 
            minConversionRate,
            destAddress,
            '');



        /*********************************************************************************
        uint256 destAmount = cKyberProxy.trade(
            cSrcToken, srcQty, 
            cDestToken, payable(address(this)), 
            maxDestAmount, 
            minConversionRate,
            destAddress);
        **********************************************************************************/
          
        emit KyberSwapped( address(cSrcToken), srcQty, address(cDestToken), destAmount, minConversionRate );
		
        return destAmount;
    }
    

    function kyberGetExpectedRate( ERC20 cSrcToken, uint256 srcQty,  ERC20 cDestToken
        ) public returns ( uint256 ) 
    {
        IKyberNetworkProxy cKyberProxy = IKyberNetworkProxy( kKyberNetworkProxy );
        

        // If the source token is not ETH (ie. an ERC20 token), the user is 
		// required to first call the ERC20 approve function to give an allowance
		// to the smart contract executing the transferFrom function.
        if (address(cSrcToken) != kETH) {

            // mitigate ERC20 Approve front-running attack, by initially setting
            // allowance to 0
            require(cSrcToken.approve(address(this), 0), "approval to 0 failed");

            // set the spender's token allowance to srcQty
            require(cSrcToken.approve(address(this), srcQty), "approval to srcQty failed");
        }

        // Get the minimum conversion rate
		// https://developer.kyber.network/docs/Integrations-SmartContractGuide/#fetching-rates
        uint256 platformFeeBps = 25;    // unwanted complication
        
        uint256 minConversionRate = cKyberProxy.getExpectedRateAfterFee(
            cSrcToken,
            cDestToken,
            srcQty,
            platformFeeBps,
            '');
		emit MinKyberConversionRate(srcQty, minConversionRate);

        
        return minConversionRate;
    }
    
    event ChangedOwner( address payable owner, address payable newOwner );
    event Liquidated( address account, address token, uint256 amount );
    event PassThru( uint256 liquidateampount );
    event Withdrawn( address token, uint256 amount );
    event Borrowed( address tokenborrowed, uint256 amount );
    event Received( address, uint );
    event KyberSwapped( address fromtoken, uint256 fromamount, address totoken, uint256 toamount, uint256 minConversionRate );
	event MinKyberConversionRate(uint256 srcQty, uint256 minConversionRate );
	event KyberSwapETH( address payable destAddress, address SrcToken, uint256 srcQty,
        address DestToken, uint256 maxDestAmount );
    event ApprovedSrcSwap( address SrcToken, uint256 srcQty );

    
    function fWithdraw(address token, uint iApprove) public onlyOwner returns(bool) {
        uint256 tokenBalance;
        // withdrawing Ether
        if (token == kETH) {
            if (address(this).balance > 0){
                tokenBalance = address(this).balance;
                payable(msg.sender).transfer(address(this).balance);
            }

        } else {
            ERC20 cWithdrawToken = ERC20(token);
            if (cWithdrawToken.balanceOf(address(this)) > 0){
                tokenBalance = cWithdrawToken.balanceOf(address(this));
                if (iApprove == 1) {
                    require(cWithdrawToken.approve(address(this), tokenBalance) == true,
                        "fWithdraw approval failed.");
                }
                
                require(cWithdrawToken.transfer(msg.sender, 
                    cWithdrawToken.balanceOf( address(this) )));
            }
        }
        emit Withdrawn(token, tokenBalance);
        return true;
    }

    
}