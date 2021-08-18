/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

pragma solidity 0.6.12;
contract Presale01{
    
    struct PresaleInfo {
        address payable PRESALE_OWNER;
        address S_TOKEN; // sale token
        address B_TOKEN; // base token // usually WETH (ETH)
        uint256 TOKEN_PRICE; // 1 base token = ? s_tokens, fixed price
        uint256 MAX_SPEND_PER_BUYER; // maximum base token BUY amount per account
        uint256 AMOUNT; // the amount of presale tokens up for presale
        uint256 HARDCAP;
        uint256 SOFTCAP;
        uint256 LIQUIDITY_PERCENT; // divided by 1000
        uint256 LISTING_RATE; // fixed rate at which the token will list on uniswap
        uint256 START_BLOCK;
        uint256 END_BLOCK;
        uint256 LOCK_PERIOD; // unix timestamp -> e.g. 2 weeks
        bool PRESALE_IN_ETH; // if this flag is true the presale is raising ETH, otherwise an ERC20 token such as DAI
      }
      
        struct PresaleStatus {
            bool WHITELIST_ONLY; // if set to true only whitelisted members may participate
            bool LP_GENERATION_COMPLETE; // final flag required to end a presale and enable withdrawls
            bool FORCE_FAILED; // set this flag to force fail the presale
            uint256 TOTAL_BASE_COLLECTED; // total base currency raised (usually ETH)
            uint256 TOTAL_TOKENS_SOLD; // total presale tokens sold
            uint256 TOTAL_TOKENS_WITHDRAWN; // total tokens withdrawn post successful presale
            uint256 TOTAL_BASE_WITHDRAWN; // total base tokens withdrawn on presale failure
            uint256 ROUND1_LENGTH; // in blocks
            uint256 NUM_BUYERS; // number of unique participants
  }
     
      PresaleInfo public PRESALE_INFO;
      PresaleStatus public STATUS;
      address private WETH  = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
      
       function init1 (
    address payable _presaleOwner, 
    uint256 _amount,
    uint256 _tokenPrice, 
    uint256 _maxEthPerBuyer, 
    uint256 _hardcap, 
    uint256 _softcap,
    uint256 _liquidityPercent,
    uint256 _listingRate,
    uint256 _startblock,
    uint256 _endblock,
    uint256 _lockPeriod
    ) external {
          
      
      PRESALE_INFO.PRESALE_OWNER = _presaleOwner;
      PRESALE_INFO.AMOUNT = _amount;
      PRESALE_INFO.TOKEN_PRICE = _tokenPrice;
      PRESALE_INFO.MAX_SPEND_PER_BUYER = _maxEthPerBuyer;
      PRESALE_INFO.HARDCAP = _hardcap;
      PRESALE_INFO.SOFTCAP = _softcap;
      PRESALE_INFO.LIQUIDITY_PERCENT = _liquidityPercent;
      PRESALE_INFO.LISTING_RATE = _listingRate;
      PRESALE_INFO.START_BLOCK = _startblock;
      PRESALE_INFO.END_BLOCK = _endblock;
      PRESALE_INFO.LOCK_PERIOD = _lockPeriod;
  }
  
  function init2 (
    address _baseToken,
    address _presaleToken
    ) external {
          
      
      // require(!PRESALE_LOCK_FORWARDER.uniswapPairIsInitialised(address(_presaleToken), address(_baseToken)), 'PAIR INITIALISED');
      
      PRESALE_INFO.PRESALE_IN_ETH = _baseToken == WETH;
      PRESALE_INFO.S_TOKEN = _presaleToken;
      PRESALE_INFO.B_TOKEN = _baseToken;
      
  }
  
      function presaleStatus () public view returns (uint256) {
    if (STATUS.FORCE_FAILED) {
      return 3; // FAILED - force fail
    }
    if ((block.number > PRESALE_INFO.END_BLOCK) && (STATUS.TOTAL_BASE_COLLECTED < PRESALE_INFO.SOFTCAP)) {
      return 3; // FAILED - softcap not met by end block
    }
    if (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.HARDCAP) {
      return 2; // SUCCESS - hardcap met
    }
    if ((block.number > PRESALE_INFO.END_BLOCK) && (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.SOFTCAP)) {
      return 2; // SUCCESS - endblock and soft cap reached
    }
    if ((block.number >= PRESALE_INFO.START_BLOCK) && (block.number <= PRESALE_INFO.END_BLOCK)) {
      return 1; // ACTIVE - deposits enabled
    }
    return 0; // QUED - awaiting start block
  }
  
   // accepts msg.value for eth or _amount for ERC20 tokens
  function userDeposit (uint256 _amount) external payable  {
    require(presaleStatus() == 1, 'NOT ACTIVE'); // ACTIVE
    // Presale Round 1 - require participant to hold a certain token and balance
    
    
    uint256 amount_in = PRESALE_INFO.PRESALE_IN_ETH ? msg.value : _amount;
    require(PRESALE_INFO.START_BLOCK < block.number, "Not started yet");
    
  }
  
  function changeBlock(uint256 number) public{
      PRESALE_INFO.START_BLOCK = number;
  }
  
}