/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
// SYS 64738
// Version 2.0
// Author: 0xTycoon
// Contributor: Alphasoup <twitter: alphasoups>
// Special Thanks: straybits1, cryptopunkart, cyounessi1, ethereumdegen, Punk7572, sherone.eth,
//                 songadaymann, Redlioneye.eth, tw1tte7, PabloPunkasso, Kaprekar_Punk, aradtski,
//                 phantom_scribbs, Cryptopapa.eth, johnhenderson, thekriskay, PerfectoidPeter,
//                 uxt_exe, 0xUnicorn, dansickles.eth, Blon Dee#9649, VRPunk1, Don Seven Slices, hogo.eth,
//                 GeoCities#5700, "HP OfficeJet Pro 9015e #2676", gigiuz#0061, danpolko.eth, mariano.eth,
//                 0xfoobar, jakerockland, Mudit__Gupta, BokkyPooBah, 0xaaby.eth, and
//                 everyone at the discord, and all the awesome people who gave feedback for this project!
// Greetings to:   Punk3395, foxthepunk, bushleaf.eth, 570KylΞ.eth, bushleaf.eth, Tokyolife, Joshuad.eth (1641),
//                 markchesler_coinwitch, decideus.eth, zachologylol, punk8886, jony_bee, nfttank, DolAtoR, punk8886
//                 DonJon.eth, kilifibaobab, joked507, cryptoed#3040, DroScott#7162, 0xAllen.eth, Tschuuuly#5158,
//                 MetasNomadic#0349, punk8653, NittyB, heygareth.eth, Aaru.eth, robertclarke.eth, Acmonides#6299,
//                 Gustavus99 (1871), Foobazzler
// Repo: github.com/0xTycoon/punksceo

pragma solidity ^0.8.11;

//import "./safemath.sol"; // don't need since v0.8
//import "./ceo.sol";
//import "hardhat/console.sol";
/*

PUNKS CEO (and "Cigarette" token)
WEB: https://punksceo.eth.limo / https://punksceo.eth.link
IPFS: See content hash record for punksceo.eth
Token Address: cigtoken.eth

         , - ~ ~ ~ - ,
     , '               ' ,
   ,                    🚬  ,
  ,                     🚬   ,
 ,                      🚬    ,
 ,                      🚬    ,
 ,         =============     ,
  ,                   ||█   ,
   ,       =============   ,
     ,                  , '
       ' - , _ _ _ ,  '


### THE RULES OF THE GAME

1. Anybody can buy the CEO title at any time using Cigarettes. (The CEO of all cryptopunks)
2. When buying the CEO title, you must nominate a punk, set the price and pre-pay the tax.
3. The CEO title can be bought from the existing CEO at any time.
4. To remain a CEO, a daily tax needs to be paid.
5. The tax is 0.1% of the price to buy the CEO title, to be charged per epoch.
6. The CEO can be removed if they fail to pay the tax. A reward of CIGs is paid to the whistleblower.
7. After Removing a CEO: A dutch auction is held, where the price will decrease 10% every half-an-epoch.
8. The price can be changed by the CEO at any time. (Once per block)
9. An epoch is 7200 blocks.
10. All the Cigarettes from the sale are burned.
11. All tax is burned
12. After buying the CEO title, the old CEO will get their unspent tax deposit refunded

### CEO perk

13. The CEO can increase or decrease the CIG farming block reward by 20% every 2nd epoch!
However, note that the issuance can never be more than 1000 CIG per block, also never under 0.0001 CIG.
14. THE CEO gets to hold a NFT in their wallet. There will only be ever 1 this NFT.
The purpose of this NFT is so that everyone can see that they are the CEO.
IMPORTANT: This NFT will be revoked once the CEO title changes.
Also, the NFT cannot be transferred by the owner, the only way to transfer is for someone else to buy the CEO title! (Think of this NFT as similar to a "title belt" in boxing.)

END

* states
* 0 = initial
* 1 = CEO reigning
* 2 = Dutch auction
* 3 = Migration

Notes:
It was decided that whoever buys the CEO title does not have to hold a punk and can nominate any punk they wish.
This is because some may hold their punks in cold storage, plus checking ownership costs additional gas.
Besides, CEOs are usually appointed by the board.

Credits:
- LP Staking based on code from SushiSwap's MasterChef.sol
- ERC20 & SafeMath based on lib from OpenZeppelin

*/

contract Cig {
    //using SafeMath for uint256; // no need since Solidity 0.8
    string public constant name = "Cigarette Token";
    string public constant symbol = "CIG";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 0;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    // UserInfo keeps track of user LP deposits and withdrawals
    struct UserInfo {
        uint256 deposit;    // How many LP tokens the user has deposited.
        uint256 rewardDebt; // keeps track of how much reward was paid out
    }
    mapping(address => UserInfo) public farmers;  // keeps track of UserInfo for each staking address with own pool
    mapping(address => UserInfo) public farmersMasterchef;  // keeps track of UserInfo for each staking address with masterchef pool
    mapping(address => uint256) public wBal;      // keeps tracked of wrapped old cig
    address public admin;                         // admin is used for deployment, burned after
    ILiquidityPoolERC20 public lpToken;           // lpToken is the address of LP token contract that's being staked.
    uint256 public lastRewardBlock;               // Last block number that cigarettes distribution occurs.
    uint256 public accCigPerShare;                // Accumulated cigarettes per share, times 1e12. See below.
    uint256 public masterchefDeposits;            // How much has been deposited onto the masterchef contract
    uint256 public cigPerBlock;                   // CIGs per-block rewarded and split with LPs
    bytes32 public graffiti;                      // a 32 character graffiti set when buying a CEO
    ICryptoPunk public punks;                     // a reference to the CryptoPunks contract
    event Deposit(address indexed user, uint256 amount);           // when depositing LP tokens to stake
    event Harvest(address indexed user, address to, uint256 amount);// when withdrawing LP tokens form staking
    event Withdraw(address indexed user, uint256 amount); // when withdrawing LP tokens, no rewards claimed
    event EmergencyWithdraw(address indexed user, uint256 amount); // when withdrawing LP tokens, no rewards claimed
    event ChefDeposit(address indexed user, uint256 amount);       // when depositing LP tokens to stake
    event ChefWithdraw(address indexed user, uint256 amount);      // when withdrawing LP tokens, no rewards claimed
    event RewardUp(uint256 reward, uint256 upAmount);              // when cigPerBlock is increased
    event RewardDown(uint256 reward, uint256 downAmount);          // when cigPerBlock is decreased
    event Claim(address indexed owner, uint indexed punkIndex, uint256 value); // when a punk is claimed
    mapping(uint => bool) public claims;                           // keep track of claimed punks
    modifier onlyAdmin {
        require(
            msg.sender == admin,
            "Only admin can call this"
        );
        _;
    }
    uint256 constant MIN_PRICE = 1e12;            // 0.000001 CIG
    uint256 constant CLAIM_AMOUNT = 100000 ether; // claim amount for each punk
    uint256 constant MIN_REWARD = 1e14;           // minimum block reward of 0.0001 CIG (1e14 wei)
    uint256 constant MAX_REWARD = 1000 ether;     // maximum block reward of 1000 CIG
    uint256 constant STARTING_REWARDS = 512 ether;// starting rewards at end of migration
    address public The_CEO;                       // address of CEO
    uint public CEO_punk_index;                   // which punk id the CEO is using
    uint256 public CEO_price = 50000 ether;       // price to buy the CEO title
    uint256 public CEO_state;                     // state has 3 states, described above.
    uint256 public CEO_tax_balance;               // deposit to be used to pay the CEO tax
    uint256 public taxBurnBlock;                  // The last block when the tax was burned
    uint256 public rewardsChangedBlock;           // which block was the last reward increase / decrease
    uint256 private immutable CEO_epoch_blocks;   // secs per day divided by 12 (86400 / 12), assuming 12 sec blocks
    uint256 private immutable CEO_auction_blocks; // 3600 blocks
    // NewCEO 0x09b306c6ea47db16bdf4cc36f3ea2479af494cd04b4361b6485d70f088658b7e
    event NewCEO(address indexed user, uint indexed punk_id, uint256 new_price, bytes32 graffiti); // when a CEO is bought
    // TaxDeposit 0x2ab3b3b53aa29a0599c58f343221e29a032103d015c988fae9a5cdfa5c005d9d
    event TaxDeposit(address indexed user,  uint256 amount);                               // when tax is deposited
    // RevenueBurned 0x1b1be00a9ca19f9c14f1ca5d16e4aba7d4dd173c2263d4d8a03484e1c652c898
    event RevenueBurned(address indexed user,  uint256 amount);                            // when tax is burned
    // TaxBurned 0x9ad3c710e1cc4e96240264e5d3cd5aeaa93fd8bd6ee4b11bc9be7a5036a80585
    event TaxBurned(address indexed user,  uint256 amount);                                // when tax is burned
    // CEODefaulted b69f2aeff650d440d3e7385aedf764195cfca9509e33b69e69f8c77cab1e1af1
    event CEODefaulted(address indexed called_by,  uint256 reward);                        // when CEO defaulted on tax
    // CEOPriceChange 0x10c342a321267613a25f77d4273d7f2688bef174a7214bc3dde44b31c5064ff6
    event CEOPriceChange(uint256 price);                                                   // when CEO changed price
    modifier onlyCEO {
        require(
            msg.sender == The_CEO,
            "only CEO can call this"
        );
        _;
    }
    IRouterV2 private immutable V2ROUTER;    // address of router used to get the price quote
    ICEOERC721 private immutable The_NFT;    // reference to the CEO NFT token
    address private immutable MASTERCHEF_V2; // address pointing to SushiSwap's MasterChefv2 contract
    IOldCigtoken private immutable OC;       // Old Contract
    /**
    * @dev constructor
    * @param _cigPerBlock Number of CIG tokens rewarded per block
    * @param _punks address of the cryptopunks contract
    * @param _CEO_epoch_blocks how many blocks between each epochs
    * @param _CEO_auction_blocks how many blocks between each auction discount
    * @param _CEO_price starting price to become CEO (in CIG)
    * @param _graffiti bytes32 initial graffiti message
    * @param _NFT address pointing to the NFT contract
    * @param _V2ROUTER address pointing to the SushiSwap router
    * @param _OC address pointing to the original Cig Token contract
    * @param _MASTERCHEF_V2 address for the sushi masterchef v2 contract
    */
    constructor(
        uint256 _cigPerBlock,
        address _punks,
        uint _CEO_epoch_blocks,
        uint _CEO_auction_blocks,
        uint256 _CEO_price,
        bytes32 _graffiti,
        address _NFT,
        address _V2ROUTER,
        address _OC,
        uint256 _migration_epochs,
        address _MASTERCHEF_V2
    ) {
        cigPerBlock        = _cigPerBlock;
        admin              = msg.sender;             // the admin key will be burned after deployment
        punks              = ICryptoPunk(_punks);
        CEO_epoch_blocks   = _CEO_epoch_blocks;
        CEO_auction_blocks = _CEO_auction_blocks;
        CEO_price          = _CEO_price;
        graffiti           = _graffiti;
        The_NFT            = ICEOERC721(_NFT);
        V2ROUTER           = IRouterV2(_V2ROUTER);
        OC                 = IOldCigtoken(_OC);
        lastRewardBlock =
            block.number + (CEO_epoch_blocks * _migration_epochs); // set the migration window end
        MASTERCHEF_V2 = _MASTERCHEF_V2;
        CEO_state = 3;                               // begin in migration state
    }

    /**
    * @dev buyCEO allows anybody to be the CEO
    * @param _max_spend the total CIG that can be spent
    * @param _new_price the new price for the punk (in CIG)
    * @param _tax_amount how much to pay in advance (in CIG)
    * @param _punk_index the id of the punk 0-9999
    * @param _graffiti a little message / ad from the buyer
    */
    function buyCEO(
        uint256 _max_spend,
        uint256 _new_price,
        uint256 _tax_amount,
        uint256 _punk_index,
        bytes32 _graffiti
    ) external  {
        require (CEO_state != 3); // disabled in in migration state
        if (CEO_state == 1 && (taxBurnBlock != block.number)) {
            _burnTax();                                                    // _burnTax can change CEO_state to 2
        }
        if (CEO_state == 2) {
            // Auction state. The price goes down 10% every `CEO_auction_blocks` blocks
            CEO_price = _calcDiscount();
        }
        require (CEO_price + _tax_amount <= _max_spend, "overpaid");       // prevent CEO over-payment
        require (_new_price >= MIN_PRICE, "price 2 smol");                 // price cannot be under 0.000001 CIG
        require (_punk_index <= 9999, "invalid punk");                     // validate the punk index
        require (_tax_amount >= _new_price / 1000, "insufficient tax" );   // at least %0.1 fee paid for 1 epoch
        transfer(address(this), CEO_price);                                // pay for the CEO title
        _burn(address(this), CEO_price);                                   // burn the revenue
        emit RevenueBurned(msg.sender, CEO_price);
        _returnDeposit(The_CEO, CEO_tax_balance);                          // return deposited tax back to old CEO
        transfer(address(this), _tax_amount);                              // deposit tax (reverts if not enough)
        CEO_tax_balance = _tax_amount;                                     // store the tax deposit amount
        _transferNFT(The_CEO, msg.sender);                                 // yank the NFT to the new CEO
        CEO_price = _new_price;                                            // set the new price
        CEO_punk_index = _punk_index;                                      // store the punk id
        The_CEO = msg.sender;                                              // store the CEO's address
        taxBurnBlock = block.number;                                       // store the block number
        // (tax may not have been burned if the
        // previous state was 0)
        CEO_state = 1;
        graffiti = _graffiti;
        emit TaxDeposit(msg.sender, _tax_amount);
        emit NewCEO(msg.sender, _punk_index, _new_price, _graffiti);
    }

    /**
    * @dev _returnDeposit returns the tax deposit back to the CEO
    * @param _to address The address which you want to transfer to
    * remember to update CEO_tax_balance after calling this
    */
    function _returnDeposit(
        address _to,
        uint256 _amount
    )
    internal
    {
        if (_amount == 0) {
            return;
        }
        balanceOf[address(this)] = balanceOf[address(this)] - _amount;
        balanceOf[_to] = balanceOf[_to] + _amount;
        emit Transfer(address(this), _to, _amount);
        //CEO_tax_balance = 0; // can be omitted since value gets overwritten by caller
    }

    /**
    * @dev transfer the NFT to a new wallet
    */
    function _transferNFT(address _oldCEO, address _newCEO) internal {
        The_NFT.transferFrom(_oldCEO, _newCEO, 0);
    }

    /**
    * @dev depositTax pre-pays tax for the existing CEO.
    * It may also burn any tax debt the CEO may have.
    * @param _amount amount of tax to pre-pay
    */
    function depositTax(uint256 _amount) external onlyCEO {
        require (CEO_state == 1, "no CEO");
        if (_amount > 0) {
            transfer(address(this), _amount);                   // place the tax on deposit
            CEO_tax_balance = CEO_tax_balance + _amount;        // record the balance
            emit TaxDeposit(msg.sender, _amount);
        }
        if (taxBurnBlock != block.number) {
            _burnTax();                                         // settle any tax debt
            taxBurnBlock = block.number;
        }
    }

    /**
    * @dev burnTax is called to burn tax.
    * It removes the CEO if tax is unpaid.
    * 1. deduct tax, update last update
    * 2. if not enough tax, remove & begin auction
    * 3. reward the caller by minting a reward from the amount indebted
    * A Dutch auction begins where the price decreases 10% every hour.
    */

    function burnTax() external  {
        if (taxBurnBlock == block.number) return;
        if (CEO_state == 1) {
            _burnTax();
            taxBurnBlock = block.number;
        }
    }

    /**
    * @dev _burnTax burns any tax debt. Boots the CEO if defaulted, paying a reward to the caller
    */
    function _burnTax() internal {
        // calculate tax per block (tpb)
        uint256 tpb = CEO_price / 1000 / CEO_epoch_blocks;       // 0.1% per epoch
        uint256 debt = (block.number - taxBurnBlock) * tpb;
        if (CEO_tax_balance !=0 && CEO_tax_balance >= debt) {    // Does CEO have enough deposit to pay debt?
            CEO_tax_balance = CEO_tax_balance - debt;            // deduct tax
            _burn(address(this), debt);                          // burn the tax
            emit TaxBurned(msg.sender, debt);
        } else {
            // CEO defaulted
            uint256 default_amount = debt - CEO_tax_balance;     // calculate how much defaulted
            _burn(address(this), CEO_tax_balance);               // burn the tax
            emit TaxBurned(msg.sender, CEO_tax_balance);
            CEO_state = 2;                                       // initiate a Dutch auction.
            CEO_tax_balance = 0;
            _transferNFT(The_CEO, address(this));                // This contract holds the NFT temporarily
            The_CEO = address(this);                             // This contract is the "interim CEO"
            _mint(msg.sender, default_amount);                   // reward the caller for reporting tax default
            emit CEODefaulted(msg.sender, default_amount);
        }
    }

    /**
     * @dev setPrice changes the price for the CEO title.
     * @param _price the price to be paid. The new price most be larger tan MIN_PRICE and not default on debt
     */
    function setPrice(uint256 _price) external onlyCEO  {
        require(CEO_state == 1, "No CEO in charge");
        require (_price >= MIN_PRICE, "price 2 smol");
        require (CEO_tax_balance >= _price / 1000, "price would default"); // need at least 0.1% for tax
        if (block.number != taxBurnBlock) {
            _burnTax();
            taxBurnBlock = block.number;
        }
        // The state is 1 if the CEO hasn't defaulted on tax
        if (CEO_state == 1) {
            CEO_price = _price;                                   // set the new price
            emit CEOPriceChange(_price);
        }
    }

    /**
    * @dev rewardUp allows the CEO to increase the block rewards by %20
    * Can only be called by the CEO every 2 epochs
    * @return _amount increased by
    */
    function rewardUp() external onlyCEO returns (uint256)  {
        require(CEO_state == 1, "No CEO in charge");
        require(block.number > rewardsChangedBlock + (CEO_epoch_blocks*2), "wait more blocks");
        require (cigPerBlock < MAX_REWARD, "reward already max");
        rewardsChangedBlock = block.number;
        uint256 _amount = cigPerBlock / 5;            // %20
        uint256 _new_reward = cigPerBlock + _amount;
        if (_new_reward > MAX_REWARD) {
            _amount = MAX_REWARD - cigPerBlock;
            _new_reward = MAX_REWARD;                 // cap
        }
        cigPerBlock = _new_reward;
        emit RewardUp(_new_reward, _amount);
        return _amount;
    }

    /**
    * @dev rewardDown decreases the block rewards by 20%
    * Can only be called by the CEO every 2 epochs
    */
    function rewardDown() external onlyCEO returns (uint256) {
        require(CEO_state == 1, "No CEO in charge");
        require(block.number > rewardsChangedBlock + (CEO_epoch_blocks*2), "wait more blocks");
        require(cigPerBlock > MIN_REWARD, "reward already low");
        rewardsChangedBlock = block.number;
        uint256 _amount = cigPerBlock / 5;            // %20
        uint256 _new_reward = cigPerBlock - _amount;
        if (_new_reward < MIN_REWARD) {
            _amount = cigPerBlock - MIN_REWARD;
            _new_reward = MIN_REWARD;                 // limit
        }
        cigPerBlock = _new_reward;
        emit RewardDown(_new_reward, _amount);
        return _amount;
    }

    /**
    * @dev _calcDiscount calculates the discount for the CEO title based on how many blocks passed
    */
    function _calcDiscount() internal view returns (uint256) {
        unchecked {
            uint256 d = (CEO_price / 10)           // 10% discount
            // multiply by the number of discounts accrued
            * ((block.number - taxBurnBlock) / CEO_auction_blocks);
            if (d > CEO_price) {
                // overflow assumed, reset to MIN_PRICE
                return MIN_PRICE;
            }
            uint256 price = CEO_price - d;
            if (price < MIN_PRICE) {
                price = MIN_PRICE;
            }
            return price;
        }
    }

    /*
    * 🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬 Information used by the UI 🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬
    */

    /**
    * @dev getStats helps to fetch some stats for the GUI in a single web3 call
    * @param _user the address to return the report for
    * @return uint256[27] the stats
    * @return address of the current CEO
    * @return bytes32 Current graffiti
    */
    function getStats(address _user) external view returns(uint256[] memory, address, bytes32, uint112[] memory) {
        uint[] memory ret = new uint[](27);
        uint112[] memory reserves = new uint112[](2);
        uint256 tpb = (CEO_price / 1000) / (CEO_epoch_blocks); // 0.1% per epoch
        uint256 debt = (block.number - taxBurnBlock) * tpb;
        uint256 price = CEO_price;
        UserInfo memory info = farmers[_user];
        if (CEO_state == 2) {
            price = _calcDiscount();
        }
        ret[0] = CEO_state;
        ret[1] = CEO_tax_balance;
        ret[2] = taxBurnBlock;                     // the block number last tax burn
        ret[3] = rewardsChangedBlock;              // the block of the last staking rewards change
        ret[4] = price;                            // price of the CEO title
        ret[5] = CEO_punk_index;                   // punk ID of CEO
        ret[6] = cigPerBlock;                      // staking reward per block
        ret[7] = totalSupply;                      // total supply of CIG
        if (address(lpToken) != address(0)) {
            ret[8] = lpToken.balanceOf(address(this)); // Total LP staking
            ret[16] = lpToken.balanceOf(_user);        // not staked by user
            ret[17] = pendingCig(_user);               // pending harvest
            (reserves[0], reserves[1], ) = lpToken.getReserves();        // uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast
            ret[18] = V2ROUTER.getAmountOut(1 ether, uint(reserves[0]), uint(reserves[1])); // CIG price in ETH
            if (isContract(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2))) { // are we on mainnet?
                ILiquidityPoolERC20 ethusd = ILiquidityPoolERC20(address(0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f));  // sushi DAI-WETH pool
                uint112 r0;
                uint112 r1;
                (r0, r1, ) = ethusd.getReserves();
                // get the price of ETH in USD
                ret[19] =  V2ROUTER.getAmountOut(1 ether, uint(r0), uint(r1));      // ETH price in USD
            }
            ret[22] = lpToken.totalSupply();       // total supply
        }
        ret[9] = block.number;                       // current block number
        ret[10] = tpb;                               // "tax per block" (tpb)
        ret[11] = debt;                              // tax debt accrued
        ret[12] = lastRewardBlock;                   // the block of the last staking rewards payout update
        ret[13] = info.deposit;                      // amount of LP tokens staked by user
        ret[14] = info.rewardDebt;                   // amount of rewards paid out
        ret[15] = balanceOf[_user];                  // amount of CIG held by user
        ret[20] = accCigPerShare;                    // Accumulated cigarettes per share
        ret[21] = balanceOf[address(punks)];         // amount of CIG to be claimed
        ret[23] = wBal[_user];                       // wrapped cig balance
        ret[24] = OC.balanceOf(_user);               // balance of old cig in old isContract
        ret[25] = OC.allowance(_user, address(this));// is old contract approved
        (ret[26], ) = OC.userInfo(_user);            // old contract stake bal
        return (ret, The_CEO, graffiti, reserves);
    }

    /**
     * @dev Returns true if `account` is a contract.
     *
     * credits https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /*
    * 🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬 Token distribution and farming stuff 🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬
    */

    /**
    * @dev isClaimed checks to see if a punk was claimed
    * @param _punkIndex the punk number
    */
    function isClaimed(uint256 _punkIndex) external view returns (bool) {
        if (claims[_punkIndex]) {
            return true;
        }
        if (OC.claims(_punkIndex)) {
            return true;
        }
        return false;
    }

    /**
    * Claim claims the initial CIG airdrop using a punk
    * @param _punkIndex the index of the punk, number between 0-9999
    */
    function claim(uint256 _punkIndex) external returns(bool) {
        require (CEO_state != 3, "invalid state");                            // disabled in migration state
        require (_punkIndex <= 9999, "invalid punk");
        require(claims[_punkIndex] == false, "punk already claimed");
        require(OC.claims(_punkIndex) == false, "punk already claimed");      // claimed in old contract
        require(msg.sender == punks.punkIndexToAddress(_punkIndex), "punk 404");
        claims[_punkIndex] = true;
        balanceOf[address(punks)] = balanceOf[address(punks)] - CLAIM_AMOUNT; // deduct from the punks contract
        balanceOf[msg.sender] = balanceOf[msg.sender] + CLAIM_AMOUNT;         // deposit to the caller
        emit Transfer(address(punks), msg.sender, CLAIM_AMOUNT);
        emit Claim(msg.sender, _punkIndex, CLAIM_AMOUNT);
        return true;
    }

    /**
    * @dev Gets the LP supply, with masterchef deposits taken into account.
    */
    function stakedlpSupply() public view returns(uint256)
    {
        return lpToken.balanceOf(address(this)) + masterchefDeposits;
    }
    /**
    * @dev update updates the accCigPerShare value and mints new CIG rewards to be distributed to LP stakers
    * Credits go to MasterChef.sol
    * Modified the original by removing poolInfo as there is only a single pool
    * Removed totalAllocPoint and pool.allocPoint
    * pool.lastRewardBlock moved to lastRewardBlock
    * There is no need for getMultiplier (rewards are adjusted by the CEO)
    *
    */
    function update() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 supply = stakedlpSupply();
        if (supply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        // mint some new cigarette rewards to be distributed
        uint256 cigReward = (block.number - lastRewardBlock) * cigPerBlock;
        _mint(address(this), cigReward);
        accCigPerShare = accCigPerShare + (
        cigReward * 1e12 / supply
        );
        lastRewardBlock = block.number;
    }

    /**
    * @dev pendingCig displays the amount of cig to be claimed
    * @param _user the address to report
    */
    function pendingCig(address _user) view public returns (uint256) {
        uint256 _acps = accCigPerShare;
        // accumulated cig per share
        UserInfo storage user = farmers[_user];
        uint256 supply = stakedlpSupply();
        if (block.number > lastRewardBlock && supply != 0) {
            uint256 cigReward = (block.number - lastRewardBlock) * cigPerBlock;
            _acps = _acps + (
            cigReward * 1e12 / supply
            );
        }
        return (user.deposit * _acps / 1e12) - user.rewardDebt;
    }


    /**
    * @dev userInfo is added for compatibility with the Snapshot.org interface.
    */
    function userInfo(uint256, address _user) view external returns (uint256, uint256 depositAmount) {
        return (0,farmers[_user].deposit + farmersMasterchef[_user].deposit);
    }
    /**
    * @dev deposit deposits LP tokens to be staked.
    * @param _amount the amount of LP tokens to deposit. Assumes this contract has been approved for the _amount.
    */
    function deposit(uint256 _amount) external {
        require(_amount != 0, "You cannot deposit only 0 tokens"); // Check how many bytes
        UserInfo storage user = farmers[msg.sender];

        update();
        _deposit(user, _amount);
        require(lpToken.transferFrom(
                address(msg.sender),
                address(this),
                _amount
            ));
        emit Deposit(msg.sender, _amount);
    }
    
    function _deposit(UserInfo storage _user, uint256 _amount) internal {
        _user.deposit += _amount;
        _user.rewardDebt += _amount * accCigPerShare / 1e12;
    }
    /**
    * @dev withdraw takes out the LP tokens
    * @param _amount the amount to withdraw
    */
    function withdraw(uint256 _amount) external {
        UserInfo storage user = farmers[msg.sender];
        update();
        /* harvest beforehand, so _withdraw can safely decrement their reward count */
        _harvest(user, msg.sender);
        _withdraw(user, _amount);
        /* Interact */
        require(lpToken.transferFrom(
            address(this),
            address(msg.sender),
            _amount
        ));
        emit Withdraw(msg.sender, _amount);
    }
    
    /**
    * @dev Internal withdraw, updates internal accounting after withdrawing LP
    * @param _amount to subtract
    */
    function _withdraw(UserInfo storage _user, uint256 _amount) internal {
        require(_user.deposit >= _amount, "Balance is too low");
        _user.deposit -= _amount;
        uint256 _rewardAmount = _amount * accCigPerShare / 1e12;
        _user.rewardDebt -= _rewardAmount;
    }

    /**
    * @dev harvest redeems pending rewards & updates state
    */
    function harvest() external {
        UserInfo storage user = farmers[msg.sender];
        update();
        _harvest(user, msg.sender);
    }

    /**
    * @dev Internal harvest
    * @param _to the amount to harvest
    */
    function _harvest(UserInfo storage _user, address _to) internal {
        uint256 potentialValue = (_user.deposit * accCigPerShare / 1e12);
        uint256 delta = potentialValue - _user.rewardDebt;
        safeSendPayout(_to, delta);
        // Recalculate their reward debt now that we've given them their reward
        _user.rewardDebt = _user.deposit * accCigPerShare / 1e12;
        emit Harvest(msg.sender, _to, delta);
    }

    /**
    * @dev safeSendPayout, just in case if rounding error causes pool to not have enough CIGs.
    * @param _to recipient address
    * @param _amount the value to send
    */
    function safeSendPayout(address _to, uint256 _amount) internal {
        uint256 cigBal = balanceOf[address(this)];
        require(cigBal >= _amount, "insert more tobacco leaves...");
        unchecked {
            balanceOf[address(this)] = balanceOf[address(this)] - _amount;
            balanceOf[_to] = balanceOf[_to] + _amount;
        }
        emit Transfer(address(this), _to, _amount);
    }

    /**
    * @dev emergencyWithdraw does a withdraw without caring about rewards. EMERGENCY ONLY.
    */
    function emergencyWithdraw() external {
        UserInfo storage user = farmers[msg.sender];
        uint256 amount = user.deposit;
        user.deposit = 0;
        user.rewardDebt = 0;
        // Interact
        require(lpToken.transfer(
                address(msg.sender),
                amount
            ));
        emit EmergencyWithdraw(msg.sender, amount);
    }

    /*
    * 🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬 Migration 🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬
    */

    /**
    * @dev renounceOwnership burns the admin key, so this contract is unruggable
    */
    function renounceOwnership() external onlyAdmin {
        admin = address(0);
    }

    /**
    * @dev setStartingBlock sets the starting block for LP staking rewards
    * Admin only, used only for initial configuration.
    * @param _startBlock the block to start rewards for
    */
    function setStartingBlock(uint256 _startBlock) external onlyAdmin {
        lastRewardBlock = _startBlock;
    }

    /**
    * @dev setPool address to an LP pool. Only Admin. (used only in testing/deployment)
    */
    function setPool(ILiquidityPoolERC20 _addr) external onlyAdmin {
        require(address(lpToken) == address(0), "pool already set");
        lpToken = _addr;
    }

    /**
    * @dev setReward sets the reward. Admin only (used only in testing/deployment)
    */
    function setReward(uint256 _value) public onlyAdmin {
        cigPerBlock = _value;
    }

    /**
    * @dev migrationComplete completes the migration
    */
    function migrationComplete() external  {
        require (CEO_state == 3);
        require (OC.CEO_state() == 1);
        require (block.number > lastRewardBlock, "cannot end migration yet");
        CEO_state = 1;                         // CEO is in charge state
        OC.burnTax();                          // before copy, burn the old CEO's tax
        /* copy the state over to this contract */
        _mint(address(punks), OC.balanceOf(address(punks))); // CIG to be set aside for the remaining airdrop
        uint256 taxDeposit = OC.CEO_tax_balance();
        The_CEO = OC.The_CEO();                // copy the CEO
        if (taxDeposit > 0) {                  // copy the CEO's outstanding tax
            _mint(address(this), taxDeposit);  // mint tax that CEO had locked in previous contract (cannot be migrated)
            CEO_tax_balance =  taxDeposit;
        }
        taxBurnBlock = OC.taxBurnBlock();
        CEO_price = OC.CEO_price();
        graffiti = OC.graffiti();
        CEO_punk_index = OC.CEO_punk_index();
        cigPerBlock = STARTING_REWARDS;        // set special rewards
        lastRewardBlock = OC.lastRewardBlock();// start rewards
        rewardsChangedBlock = OC.rewardsChangedBlock();
        /* Historical records */
        _transferNFT(
            address(0),
            address(0x1e32a859d69dde58d03820F8f138C99B688D132F)
        );
        emit NewCEO(
            address(0x1e32a859d69dde58d03820F8f138C99B688D132F),
            0x00000000000000000000000000000000000000000000000000000000000015c9,
            0x000000000000000000000000000000000000000000007618fa42aac317900000,
            0x41732043454f2049206465636c617265204465632032322050756e6b20446179
        );
        _transferNFT(
            address(0x1e32a859d69dde58d03820F8f138C99B688D132F),
            address(0x72014B4EEdee216E47786C4Ab27Cc6344589950d)
        );
        emit NewCEO(
            address(0x72014B4EEdee216E47786C4Ab27Cc6344589950d),
            0x0000000000000000000000000000000000000000000000000000000000000343,
            0x00000000000000000000000000000000000000000001a784379d99db42000000,
            0x40617a756d615f626974636f696e000000000000000000000000000000000000
        );
        _transferNFT(
            address(0x72014B4EEdee216E47786C4Ab27Cc6344589950d),
            address(0x4947DA4bEF9D79bc84bD584E6c12BfFa32D1bEc8)
        );
        emit NewCEO(
            address(0x4947DA4bEF9D79bc84bD584E6c12BfFa32D1bEc8),
            0x00000000000000000000000000000000000000000000000000000000000007fa,
            0x00000000000000000000000000000000000000000014adf4b7320334b9000000,
            0x46697273742070756e6b7320746f6b656e000000000000000000000000000000
        );
    }

    /**
    * @dev wrap wraps old CIG and issues new CIG 1:1
    * @param _value how much old cig to wrap
    */
    function wrap(uint256 _value) external {
        require (CEO_state == 3);
        OC.transferFrom(msg.sender, address(this), _value); // transfer old cig to here
        _mint(msg.sender, _value);                          // give user new cig
        wBal[msg.sender] = wBal[msg.sender] + _value;       // record increase of wrapped old cig for caller
    }

    /**
    * @dev unwrap unwraps old CIG and burns new CIG 1:1
    */
    function unwrap(uint256 _value) external {
        require (CEO_state == 3);
        _burn(msg.sender, _value);                          // burn new cig
        OC.transfer(msg.sender, _value);                    // give back old cig
        wBal[msg.sender] = wBal[msg.sender] - _value;       // record decrease of wrapped old cig for caller
    }
    /*
    * 🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬 ERC20 Token stuff 🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬
    */

    /**
    * @dev burn some tokens
    * @param _from The address to burn from
    * @param _amount The amount to burn
    */
    function _burn(address _from, uint256 _amount) internal {
        balanceOf[_from] = balanceOf[_from] - _amount;
        totalSupply = totalSupply - _amount;
        emit Transfer(_from, address(0), _amount);
    }

    /**
    * @dev mint new tokens
   * @param _to The address to mint to.
   * @param _amount The amount to be minted.
   */
    function _mint(address _to, uint256 _amount) internal {
        require(_to != address(0), "ERC20: mint to the zero address");
        unchecked {
            totalSupply = totalSupply + _amount;
            balanceOf[_to] = balanceOf[_to] + _amount;
        }
        emit Transfer(address(0), _to, _amount);
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        //require(_value <= balanceOf[msg.sender], "value exceeds balance"); // SafeMath already checks this
        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        uint256 a = allowance[_from][msg.sender]; // read allowance
        //require(_value <= balanceOf[_from], "value exceeds balance"); // SafeMath already checks this
        if (a != type(uint256).max) {             // not infinite approval
            require(_value <= a, "not approved");
            unchecked {
                allowance[_from][msg.sender] = a - _value;
            }
        }
        balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve tokens of mount _value to be spent by _spender
    * @param _spender address The spender
    * @param _value the stipend to spend
    */
    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
    * 🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬 Masterchef v2 integration 🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬
    */

    /**
    * @dev onSushiReward implements the SushiSwap masterchefV2 callback, guarded by the onlyMCV2 modifier
    * @param _user address called on behalf of
    * @param _to address who send rewards to
    * @param _sushiAmount uint256, if not 0 then the rewards will be harvested
    * @param _newLpAmount uint256, amount of LP tokens staked at Sushi
    */
    function onSushiReward (
        uint256 /* pid */,
        address _user,
        address _to,
        uint256 _sushiAmount,
        uint256 _newLpAmount)  external onlyMCV2 {
        UserInfo storage user = farmersMasterchef[_user];
        update();
        // Harvest sushi when there is sushiAmount passed through as this only comes in the event of the masterchef contract harvesting
        if(_sushiAmount != 0) _harvest(user, _to); // send outstanding CIG to _to
        uint256 delta;
        // Withdraw stake
        if(user.deposit >= _newLpAmount) { // Delta is withdraw
            delta = user.deposit - _newLpAmount;
            masterchefDeposits -= delta;   // subtract from staked total
            _withdraw(user, delta);
            emit ChefWithdraw(_user, delta);
        }
        // Deposit stake
        else if(user.deposit != _newLpAmount) { // Delta is deposit
            delta = _newLpAmount - user.deposit;
            masterchefDeposits += delta;        // add to staked total
            _deposit(user, delta);
            emit ChefDeposit(_user, delta);
        }
    }

    // onlyMCV2 ensures only the MasterChefV2 contract can call this
    modifier onlyMCV2 {
        require(
            msg.sender == MASTERCHEF_V2,
            "Only MCV2"
        );
        _;
    }
}

/*
* 🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬 interfaces 🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬🚬
*/

/**
* @dev IRouterV2 is the sushi router 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
*/
interface IRouterV2 {
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns(uint256 amountOut);
}

/**
* @dev ICryptoPunk used to query the cryptopunks contract to verify the owner
*/
interface ICryptoPunk {
    //function balanceOf(address account) external view returns (uint256);
    function punkIndexToAddress(uint256 punkIndex) external returns (address);
    //function punksOfferedForSale(uint256 punkIndex) external returns (bool, uint256, address, uint256, address);
    //function buyPunk(uint punkIndex) external payable;
    //function transferPunk(address to, uint punkIndex) external;
}

interface ICEOERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
}

/*
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * 0xTycoon was here
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
* @dev from UniswapV2Pair.sol
*/
interface ILiquidityPoolERC20 is IERC20 {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function totalSupply() external view returns(uint);
}

interface IOldCigtoken is IERC20 {
    function claims(uint256) external view returns (bool);
    function graffiti() external view returns (bytes32);
    function cigPerBlock() external view returns (uint256);
    function The_CEO() external view returns (address);
    function CEO_punk_index() external view returns (uint);
    function CEO_price() external view returns (uint256);
    function CEO_state() external view returns (uint256);
    function CEO_tax_balance() external view returns (uint256);
    function taxBurnBlock() external view returns (uint256);
    function lastRewardBlock() external view returns (uint256);
    function rewardsChangedBlock() external view returns (uint256);
    function userInfo(address) external view returns (uint256, uint256);
    function burnTax() external;
}

// 🚬