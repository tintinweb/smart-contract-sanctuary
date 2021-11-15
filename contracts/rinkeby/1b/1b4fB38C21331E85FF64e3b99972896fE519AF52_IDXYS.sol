// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;





library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
 
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface ILendingPool {

 function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;


  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);


  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;


  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);


  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  function getReserveNormalizedIncome(address asset) external view returns(uint);

}

interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

interface WETHGateway{
    
    function depositETH(address onBehalfOf, uint16 referralCode) external payable;
    
    function withdrawETH(uint256 amount, address to) external;
    
}

interface CErc20 {
    function mint(uint256 mintAmount) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function underlying() external view returns (address);

    function getCash() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function borrowRatePerBlock() external view returns (uint);

    function exchangeRateCurrent() external view returns (uint);

    function balanceOfUnderlying(address account) external view returns (uint);
}

interface CEther {
    function balanceOf(address owner) external view returns (uint);

    function approve(address spender, uint256 amount) external returns (bool);

    function mint() external payable;

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function repayBorrow() external payable;

    function getCash() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function borrowRatePerBlock() external view returns (uint);

    function totalBorrowsCurrent() external view returns (uint);

    function totalSupply() external view returns (uint);

    function totalReserves() external view returns (uint);

    function exchangeRateCurrent() external view returns (uint);

    function balanceOfUnderlying(address account) external view returns (uint);

    function exchangeRateStored() external view returns (uint256);

}


interface Comptroller {

    function enterMarkets(address[] calldata) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint);

    function claimComp(address holder) external;

    function getAssetsIn(address account) external view returns (address[] memory);

    function markets(address cTokenAddress) external view returns (bool, uint, bool);

    function getAccountLiquidity(address account) external view returns (uint, uint, uint);

    function liquidationIncentiveMantissa() external view returns (uint);

}


contract IDXYS {
  using SafeMath for uint;

  address payable public receiver; // this could be you!

  address constant ETHER = address(0);
  address payable owner;
  // wrapped ETH address
  // mainnet 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
  // kovan Aave 0x87b1f4cf9BD63f7BBD3eE1aD04E8F52540349347
 // address wrappedETH = 0x87b1f4cf9BD63f7BBD3eE1aD04E8F52540349347;

  // Compound Controller
  // mainnet 0x3d9819210a31b4961b30ef54be2aed79b9c9cd3b
  // kovan 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B
  // Rinkeby 0x2EAa9D77AE4D8f9cdD9FAAcd44016E746485bddb
  address comptrollerAddress = 0x2EAa9D77AE4D8f9cdD9FAAcd44016E746485bddb;
  Comptroller comptroller = Comptroller(comptrollerAddress);
    
    
    // Aave
    // address prodivder 
    // kovan 
    //0x88757f2f99175387ab4c6a4b3067c77a695b0349
    
  //ILendingPoolAddressesProvider provider;
  //address lendingPoolAddr;

  //WETHGateway for Aave ETH
  // mainnet 0xDcD33426BA191383f1c9B431A342498fdac73488
  // kovan 0xf8aC10E65F2073460aAD5f28E1EABE807DC287CF
 // address wethGatewayAddr = 0xf8aC10E65F2073460aAD5f28E1EABE807DC287CF;
 // WETHGateway weth = WETHGateway(wethGatewayAddr);

  // Yearn Dai Vault
  // mainnet 0x19D3364A399d251E894aC732651be8B0E4e85001
  // testnet None
  
  //address yvDai = 0x19D3364A399d251E894aC732651be8B0E4e85001;
  

  uint256 protocolFees;

  /// @notice Events
  /// @dev  

  event Deposit(address token, address user, uint256 amount);
  event Withdraw(address token, address user, uint256 amount);
  event assetRegister(address _asset);

  /**
    ///////////////////////////////// ASSET TRACKING //////////////////////////////
  */

  uint256 public assetCount;
  mapping(uint256 => _Assets) public assets; 
  mapping(uint256 => _Profile) public profiles;                             // an interest rate model
  mapping(address => bool) public assetRegistered; 

  event Assets(
    address asset,               
    address[] protocols,      
    uint256 score,           
    bool active 
  );

  struct _Assets{
        uint256 id;
        address assetAddr;                                                   // The asset address
        address[] protocols;
        address[] pTokens;                                                   // adress of protocol interface ex COMP
        bool active;                                                         // Safety. 
     }

 struct _Profile{
        uint256 id;                                                          // The asset address
        uint[] protocolShare;                                                // adress of protocol interface ex [COMP%,AAVE%,YEARN%]
        bool active;                                                         // Safety. 
     }

     
    mapping(address => mapping(uint256 => bool)) public userAccessLevel;     // user => market  => true or false
    mapping(address => mapping(address => uint256)) public balances;         // user => asset => balance in Underlying
    mapping(address => mapping(address => uint256)) public pBalances;        // user => pAsset => balance in collateral
    mapping(address => uint256) public feesTracker;                          // asset => balance
    mapping(uint256 => _Deposits) public deposits;                           // depositId map => Struct Deposit
                            
    uint256 depositCount;                                                    // counter

    event Deposits(
      address asset,                                                              
      address protocols,      
      uint256 amount            
    );
    
    struct _Deposits{
        uint256 id;                                                          // map deposit 
        address owner;                                                       // msg.sender is owner
        uint256 amount;                                                      // Protocol assets?
        address asset;                                                       // Protocol   
        uint256 end;                                                         // if needed;
        uint256 timestamp;                                                   // now
     }
    

    /// @notice Modifier Basic security
    /// @dev  
    modifier onlyOwner() {
        require(msg.sender == owner, "Owner?");
        _;
    }
    
    /// @notice CONSTRUCTOR
    /// @dev 
  
    /// @param _protocolFees uint the protocol fees 
   
  constructor(uint256 _protocolFees) {
    
    owner = payable(msg.sender);
    protocolFees = _protocolFees;  
   // provider = _addressProvider;
   // lendingPoolAddr = provider.getLendingPool();
  }

  /**
    ///////////////////////  ADMINISTRATIVE FUNCTIONS ///////////////////////////////////
  */

    /// @notice Register and unregister Assets
    /// @dev We check if true on deposit

  function registerAsset(address _asset, address[] memory _pTokens) public onlyOwner{
      require(!assetRegistered[_asset],'Asset Present ?');
         assetRegistered[_asset] = true;
        _Assets storage _newAsset = assets[assetCount];
        _newAsset.id = assetCount;
        _newAsset.assetAddr = _asset;
        _newAsset.active = true;    
        _newAsset.pTokens = _pTokens;              
        assetCount = assetCount+1;
        emit assetRegister(_asset);
  }
  function unRegisterAsset(address _asset) public onlyOwner{
      assetRegistered[_asset] = false;
  }

    /// @notice Set protocol access for user
    /// @dev We check if true on deposit

  function setProtocolAcces(address _user, uint256 _ProtocolId, bool _haveAccess) public onlyOwner{

      userAccessLevel[_user][_ProtocolId] = _haveAccess;
  }
    /// @notice Set protocol Fees
    /// @dev We check if true on deposit
    /// 

  function setProtocolFees(uint256 _protocolFees) public onlyOwner{

      protocolFees = _protocolFees;
  }

   function setAcces(address _user, uint256 _protocol) public onlyOwner{

      userAccessLevel[_user][_protocol] = true;
  }


  /**
     /////////////////////////////////// PUBLIC TRANSACTIONAL  ///////////////////////////////
  */

    /// @notice DEPOSIT INTO IDXYS 
    /// @dev require approval 
    /// @param _assetId  ERC20 asset to deposit. id 0 is ETH
    /// @param _amount uint the amount to deposit
 
    function deposit(uint256 _assetId, uint256 _amount)  public payable {
                                                                             
        
        _Assets memory _asset = assets[_assetId];                                                        // load the asset in memory                                                                           
        require(assetRegistered[_asset.assetAddr],'Asset Unknown?');                                     // is registered
        if(_assetId == 0){             
                                                                                  
            require(msg.value > 0,'Zero amount?');                                                       // require an amount of ETH
            _amount = msg.value;
           

        }else{
            require(_amount > 0,'Zero amount?');                                                         // require an amount of ERC
            IERC20 asset = IERC20(_asset.assetAddr);
            require(asset.transferFrom(msg.sender, address(this), _amount),'Available Funds?');          // require that the transfer worked
        } 
        
        _Deposits storage _deposit = deposits[depositCount];                                             // load deposits storage (might be removed depending on strategy) 
        _deposit.id = depositCount;                
        _deposit.owner = msg.sender;
        _deposit.amount = _amount;                
        _deposit.asset = _asset.assetAddr;                                        
        _deposit.timestamp = block.timestamp;
        depositCount = depositCount + 1; 
    
        _depositOnComp(_asset.assetAddr, _asset.pTokens[0], _amount);                                     // deposit to protocol
    
        emit Deposit(_asset.assetAddr, msg.sender, _amount);
    }




    /// @notice WITHDRAW FROM IDXYS
    /// @dev The amount to withdraw
    /// @param _assetId The deposit in position
    /// @param _amount the amount to withdraw

    function withdraw(uint _assetId, uint256 _amount)  public payable {
        
                   
        _Assets memory _asset = assets[_assetId];                                         
        require(balances[msg.sender][_asset.assetAddr] >= _amount, 'Assets Funds?');                         // Have the funds                                         
        _withdrawFromComp(_asset.assetAddr,_asset.pTokens[0], _amount);
        emit Withdraw(_asset.assetAddr, msg.sender, _amount);
    }

    /// @notice COMPOUND DEPOSIT.
    /// @dev Called by controller
    /// @param _asset adresse of ERC20 asset
    /// @param _cToken CToken address
    /// @param _amount The amount to deposit

    function _depositOnComp(address _asset,address _cToken, uint256 _amount) internal {
        uint256 balanceB;                                                                                    // the balance of collateral before
        uint256 balanceA;                                                                                    // the balance of collateral after
        if(_asset == ETHER){
            CEther cToken = CEther(_cToken);
            balanceB = cToken.balanceOf(address(this));
            cToken.mint{value : msg.value }(); 
            balanceA = cToken.balanceOf(address(this));
        }else {
            IERC20 underlying = IERC20(_asset);                                                              // get a handle for the underlying asset contract
            CErc20 cToken = CErc20(_cToken);                                                                 // get a handle for the corresponding cToken contract
            balanceB = cToken.balanceOf(address(this));                                                      // the balance of collateral before
            underlying.approve(address(cToken), _amount);                                                    // approve the transfer
                                                              
            assert(cToken.mint(_amount) == 0);                                                               // mint the cTokens and assert there is no error
            balanceA = cToken.balanceOf(address(this));                                                      // the balance of collateral before
        }
        uint256 userAmount = balanceA.sub(balanceB);                                                         
        
        pBalances[msg.sender][_cToken] = pBalances[msg.sender][_cToken].add(userAmount);                      // ajust balance in collateral token
        balances[msg.sender][_asset] = balances[msg.sender][_asset].add(_amount);                             // ajust balance in underlying token
    }
    
    /// @notice COMPOUND WITHDRAW 
    /// @dev this call the redeem function and is called with the amount of Protocol token
    /// @param _cToken CToken address
    /// @param _amount Must be Ctoken amount with 8 decimals

    function _withdrawFromComp(address _asset,address _cToken,uint256 _amount) internal {
                                                                                    // the balance of underlying before
                                                                                           
        IERC20 input = IERC20(_cToken);
        uint256 decimals = input.decimals();
        uint256 pTokenAmount = partialReturn(                                                                 // will return the same % of token  ex if 100 Dai represent 1% or the user balance
            _amount,                                                                                          // we will use 1% of his collatereal and get the rate
            balances[msg.sender][_asset],                                                                       
            pBalances[msg.sender][_cToken],
            decimals
         );  
                                                                       
        uint256 withdrawn;                                                                   // what we will withdraw
                                                                     
        if(_asset == ETHER){                                                                  // THIS IS WHERE YOU MAKE MONEY
           
            uint256 balanceBefore = address(this).balance;
            CEther cToken = CEther(_cToken);
            uint256 rate = cToken.exchangeRateCurrent();
            withdrawn = _Computation(_cToken,msg.value, pTokenAmount);
            cToken.approve(address(cToken), withdrawn);                        
            require(cToken.redeem(withdrawn) == 0, "CEther Withdraw?");
           uint256 balanceAfter = address(this).balance;
            uint256 userReturn = balanceAfter.sub(balanceBefore);                                     // the amount of dai going back to the user
            balances[msg.sender][_asset] = balances[msg.sender][ETHER].sub(_amount);
            pBalances[msg.sender][_cToken] = pBalances[msg.sender][_cToken].sub(pTokenAmount);  // we adjust the balance of both asset and left the 
           
            payable(msg.sender).transfer(userReturn);
       
            
        }else {                                                                               // SAME PROCES AS ABOVE BUT FOR ERC20

            IERC20 asset = IERC20(_asset);  
            uint balanceBefore = asset.balanceOf(address(this));                                                                   
            CErc20 cToken = CErc20(_cToken);
         
            withdrawn = _Computation(_cToken,_amount, pTokenAmount);
            cToken.approve(address(cToken), withdrawn);                                    
           
            require(cToken.redeem(withdrawn) == 0, "CToken Withdraw?");
   
            uint balanceAfter = asset.balanceOf(address(this));

           // require(balanceAfter.sub(balanceBefore) == withdrawn, 'Balances Mismatch');          // require that the amount of ptoken withdraw reflect the balance after tx
            uint256 userReturn = balanceAfter.sub(balanceBefore);                                     // the amount of dai going back to the user

            balances[msg.sender][_asset] = balances[msg.sender][_asset].sub(_amount);
            pBalances[msg.sender][_cToken] = pBalances[msg.sender][_cToken].sub(pTokenAmount);  // we adjust the balance of both asset and left the 

            asset.transfer(msg.sender, userReturn);
            
        }
            // need safety for eventual rounding error

            
        
    }
    


     /// @notice WITHDRAW ERC AMOUNT.
    /// @dev Called by controller


    function _Computation(address _cToken, uint256 _amount, uint256 pTokenAmount) internal view returns (uint256){

            uint256 price = getCompRate(_cToken, _amount);
            uint256 userAdvantage = pTokenAmount.sub(price);                                 
            uint256 fees = (userAdvantage / 10000) * protocolFees;
            uint256 netProfit = userAdvantage.sub(fees);                                           
            return (price.add(netProfit)); 
     
    }

    /// @notice WITHDRAW ERC AMOUNT.
    /// @dev Called by controller
    /// @param _cToken CToken address
    /// @param _amount Must be Ctoken amount with 8 decimals

    function _withdrawCUnderlying(address _cToken,uint256 _amount) public {
        CErc20 cToken = CErc20(_cToken);
        require(cToken.redeemUnderlying(_amount) == 0, "ERC Withdraw?");
    }



        /// @notice CLAIM COMP TOKEN.
        /// @param _holder Must be Ctoken amount with 8 decimals

    function _claimComp(address _holder) public {
        require(msg.sender == owner);
        comptroller.claimComp(_holder);
    }


    /// @notice ENTER COMPOUND MARKET.
    /// @param _cToken The collatereral token address

    function _enterCompMarket(address _cToken) public {
        address[] memory cTokens = new address[](1);                                                                                 // we enter one market at a time
        //  entering MArket with ctoken
        cTokens[0] = address(_cToken);
        uint[] memory errors = comptroller.enterMarkets(cTokens);
        require(errors[0] == 0);
    }


    /// @notice ENTER COMPOUND MARKET.
    /// @param _cToken Exiting market will lower the TX cost with Compound

    function _exitCompMarket(address _cToken) public {                                                                               // we exit Comp Market
        uint256 errors = comptroller.exitMarket(_cToken);
        require(errors == 0,"Exit CMarket?");
    }

    function getCompRate(address asset, uint256 _amount) public view returns (uint256){
        CErc20 token = CErc20(asset);
        uint256 rate = token.exchangeRateStored();
        return _amount / (rate/1e18);
    }
    

    /// @notice Aave DEPOSIT.
    /// @dev Called by controller, ACCEPT ETH and ERC
    /// @param _asset adresse of ERC20 asset
    /// @param _amount The amount to deposit

        // function _depositOnAave(address _asset, uint256 _amount) payable public {
        //     require(msg.sender == owner);
        //     ILendingPool lendingPool = ILendingPool(lendingPoolAddr);
  
        //     if(_asset == ETHER){
        //         // ETHER
        //       weth.depositETH{value : msg.value}(address(this), 0);
        
        //     }else {
        //         // ERC20
        //         IERC20 underlying = IERC20(_asset);
        //         underlying.approve(address(lendingPool), _amount);
        //       lendingPool.deposit(_asset, _amount, address(this), 0);
        //     }
        // }
        
    /// @notice AAVE WITHDRAW.
    /// @dev Called by controller, acces ETH and ERC
    /// @param _asset adresse of ERC20 asset
    /// @param _amount The amount to deposit   

        //   function _WithdrawOnAave(address _asset, uint256 _amount) public {
        //     require(msg.sender == owner);
        //     ILendingPool lendingPool = ILendingPool(lendingPoolAddr);
        //     if(_asset == ETHER){
        //         // ETHER
        //         IERC20 underlying = IERC20(wrappedETH);
        //         underlying.approve(address(weth),_amount);
        //         weth.withdrawETH(_amount, address(this));
        
        //     }else {
        //         // ERC20
        //       lendingPool.withdraw(_asset, _amount, address(this));
        //     }
            
        // }




        
    /// @notice YEARN DEPOSIT.
    /// @dev Called by controller, acces ETH and ERC
    /// @param _amount The amount to deposit 
    /// we need a vault param from assets
    
   // function _depositOnYearn(address _vault, uint _amount) public {
   //      yVault vault = yVault(_vault);
   //     vault.deposit(_amount);
   // }

    /// @notice YEARN WITHDRAW.
    /// @dev Called by controller, acces ETH and ERC
    /// @param _amount The amount  
    
    
   // function _withdrawOnYearn(address _vault, uint _amount) public {
   //      yVault vault = yVault(_vault);
   //      vault.withdraw(_amount);
   // }
     




    /// @notice returns a quotient
    /// @dev this function assumed you checked the values already 
    /// @param numerator the amount filled
    /// @param denominator the amount in order 
    /// @param precision the decimal places we keep
    /// @return _quotient

    function quotient(uint256 numerator, uint256 denominator, uint256 precision) pure public  returns(uint256 _quotient) {
        uint256 _numerator  = numerator * 10 ** (precision+1);
        _quotient =  ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }
    
    /// @notice returns the percentage of the filled amount
    /// @dev this function assumed you checked the values already 
    /// @param _withdrawAmount the amount to withdraw
    /// @param _balance the balance 
    /// @param _pBalance the protocol balance
    /// @return _calcReturn

    function partialReturn(uint256 _withdrawAmount, uint256 _balance, uint256 _pBalance, uint256 _decimals) pure public returns (uint256 _calcReturn) {
         uint256 _quotient = quotient(_withdrawAmount,_balance,_decimals);
         _calcReturn = (_pBalance.mul(_quotient)).div( 10 ** _decimals );
         return (_calcReturn);
        
    }


    /// @notice Utility function for dev mode only
    /// @dev WithDraw token safety
    /// @param _user The token we want to withdraw
    /// @param _amount The token we want to withdraw
    
    function sendEther(address _user ,uint256 _amount) internal {
     
        
    }

    /// @notice Utility function for dev mode only
    /// @dev WithDraw token safety
    /// @param _token The token we want to withdraw
    
    function withdrawTokens(IERC20 _token) public onlyOwner {

        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(msg.sender, balance);
    }
    
    /// @notice receive Allow contract to receive Ether
    /// @dev Receive Ether
    
    receive() external payable {}

    /// @notice withdrawEther will withdraw the balance of Ether to msg.sender
    /// @dev WithDraw ether safety
   
    
    function withdrawEther() public payable onlyOwner {
     
        address self = address(this); // workaround for a possible solidity bug
        uint256 balance = self.balance;
        owner.transfer(balance);
    }
    /// @notice Give Ownership of the contract to the owner.
    /// @dev OnlyOnwner
   function setOwner(address _newOwner) public  onlyOwner {
     
      owner = payable(_newOwner);
    }










}

