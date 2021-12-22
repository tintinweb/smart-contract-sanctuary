/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: MIT
// Author: 0xTycoon
// Repo: github.com/0xTycoon/punksceo

pragma solidity ^0.8.11;

//import "./safemath.sol"; // don't need since v0.8
//import "./ceo.sol";
/*

PUNKS CEO (and "Cigarette" token)
WEB: https://punksceo.eth.limo / https://punksceo.eth.link
IPFS: See content hash record for punksceo.eth
Token Address: cigtoken.eth

There is NO trade tax or any other fee in the standard ERC20 methods of this token.

The "CEO of CryptoPunks" game element is optional and implemented for your entertainment.

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
    // ERC20 stuff
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
    mapping(address => UserInfo) public userInfo; // keeps track of UserInfo for each staking address
    address public admin;                         // admin is used for deployment, burned after
    ILiquidityPoolERC20 public lpToken;           // lpToken is the address of LP token contract that's being staked.
    uint256 public lastRewardBlock;               // Last block number that cigarettes distribution occurs.
    uint256 public accCigPerShare;                // Accumulated cigarettes per share, times 1e12. See below.
    uint256 public cigPerBlock;                   // CIGs per-block rewarded and split with LPs
    bytes32 public graffiti;                      // a 32 character graffiti set when buying a CEO
    ICryptoPunk public punks;                     // a reference to the CryptoPunks contract
    event Deposit(address indexed user, uint256 amount);           // when depositing LP tokens to stake, or harvest
    event Withdraw(address indexed user, uint256 amount);          // when withdrawing LP tokens form staking
    event EmergencyWithdraw(address indexed user, uint256 amount); // when withdrawing LP tokens, no rewards claimed
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
    address public The_CEO;                       // address of CEO
    uint public CEO_punk_index;                   // which punk id the CEO is using
    uint256 public CEO_price = 50000 ether;       // price to buy the CEO title
    uint256 public CEO_state;                     // state has 3 states, described above.
    uint256 public CEO_tax_balance;               // deposit to be used to pay the CEO tax
    uint256 public taxBurnBlock;                  // The last block when the tax was burned
    uint256 public rewardsChangedBlock;           // which block was the last reward increase / decrease
    uint256 private immutable CEO_epoch_blocks;   // secs per day divided by 12 (86400 / 12), assuming 12 sec blocks
    uint256 private immutable CEO_auction_blocks; // 3600 blocks
    event NewCEO(address indexed user, uint indexed punk_id, uint256 new_price, bytes32 graffiti); // when a CEO is bought
    event TaxDeposit(address indexed user,  uint256 amount);                               // when tax is deposited
    event RevenueBurned(address indexed user,  uint256 amount);                            // when tax is burned
    event TaxBurned(address indexed user,  uint256 amount);                                // when tax is burned
    event CEODefaulted(address indexed called_by,  uint256 reward);                        // when CEO defaulted on tax
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
    /**
    * @dev constructor
    * @param _startBlock starting block when rewards start
    * @param _cigPerBlock Number of CIG tokens rewarded per block
    * @param _punks address of the cryptopunks contract
    * @param _CEO_epoch_blocks how many blocks between each epochs
    * @param _CEO_auction_blocks how many blocks between each auction discount
    * @param _CEO_price starting price to become CEO (in CIG)
    * @param _MASTERCHEF_V2 address of the MasterChefv2 contract
    */
    constructor(
        uint256 _startBlock,
        uint256 _cigPerBlock,
        address _punks,
        uint _CEO_epoch_blocks,
        uint _CEO_auction_blocks,
        uint256 _CEO_price,
        address _MASTERCHEF_V2,
        bytes32 _graffiti,
        address _NFT,
        address _V2ROUTER
    ) {
        lastRewardBlock    = _startBlock;
        cigPerBlock        = _cigPerBlock;
        admin              = msg.sender;                 // the admin key will be burned after deployment
        punks              = ICryptoPunk(_punks);
        CEO_epoch_blocks   = _CEO_epoch_blocks;
        CEO_auction_blocks = _CEO_auction_blocks;
        CEO_price          = _CEO_price;
        MASTERCHEF_V2      = _MASTERCHEF_V2;
        graffiti           = _graffiti;
        The_NFT            = ICEOERC721(_NFT);
        V2ROUTER           = IRouterV2(_V2ROUTER);
        // mint the tokens for the airdrop and place them in the CryptoPunks contract.
        mint(_punks, CLAIM_AMOUNT * 10000);
    }

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
        if (CEO_state == 1 && (taxBurnBlock != block.number)) {
            _burnTax();                                                    // _burnTax can change CEO_state to 2
        }
        if (CEO_state == 2) {
            // Auction state. The price goes down 10% every `CEO_auction_blocks` blocks
            CEO_price = _calcDiscount();
        }
        require (CEO_price + _tax_amount <= _max_spend, "overpaid");        // prevent CEO over-payment
        require (_new_price >= MIN_PRICE, "price 2 smol");                 // price cannot be under 0.000001 CIG
        require (_punk_index <= 9999, "invalid punk");                     // validate the punk index
        require (_tax_amount >= _new_price / 1000, "insufficient tax" );   // at least %0.1 fee paid for 1 epoch
        transfer(address(this), CEO_price);                                // pay for the CEO title
        burn(address(this), CEO_price);                                    // burn the revenue
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
        if (_oldCEO != _newCEO) {
            The_NFT.transferFrom(_oldCEO, _newCEO, 0);
        }
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
            burn(address(this), debt);                           // burn the tax
            emit TaxBurned(msg.sender, debt);
        } else {
            // CEO defaulted
            uint256 default_amount = debt - CEO_tax_balance;     // calculate how much defaulted
            burn(address(this), CEO_tax_balance);                // burn the tax
            emit TaxBurned(msg.sender, CEO_tax_balance);
            CEO_state = 2;                                       // initiate a Dutch auction.
            CEO_tax_balance = 0;
            _transferNFT(The_CEO, address(this));                // This contract holds the NFT temporarily
            The_CEO = address(this);                             // This contract is the "interim CEO"
            mint(msg.sender, default_amount);                    // reward the caller for reporting tax default
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
            CEO_price = _price; // set the new price
            emit CEOPriceChange(_price);
        }
    }

    /**
    * @dev rewardUp allows the CEO to increase the block rewards by %1
    * Can only be called by the CEO every 7 epochs
    * @return _amount increased by
    */
    function rewardUp() external onlyCEO returns (uint256)  {
        require(CEO_state == 1, "No CEO in charge");
        require(block.number > rewardsChangedBlock + (CEO_epoch_blocks*2), "wait more blocks");
        require (cigPerBlock <= MAX_REWARD, "reward already max");
        rewardsChangedBlock = block.number;
        uint256 _amount = cigPerBlock / 5;                // %20
        uint256 _new_reward = cigPerBlock + _amount;
        if (_new_reward > MAX_REWARD) {
            _amount = MAX_REWARD - cigPerBlock;
            _new_reward = MAX_REWARD; // cap
        }
        cigPerBlock = _new_reward;
        emit RewardUp(_new_reward, _amount);
        return _amount;
    }

    /**
    * @dev rewardDown decreases the block rewards by 1%
    * Can only be called by the CEO every 7 epochs
    */
    function rewardDown() external onlyCEO returns (uint256) {
        require(CEO_state == 1, "No CEO in charge");
        require(block.number > rewardsChangedBlock + (CEO_epoch_blocks*2), "wait more blocks");
        require(cigPerBlock >= MIN_REWARD, "reward already low");
        rewardsChangedBlock = block.number;
        uint256 _amount = cigPerBlock / 5;            // %20
        uint256 _new_reward = cigPerBlock - _amount;
        if (_new_reward < MIN_REWARD) {
            _amount = cigPerBlock - MIN_REWARD;
            _new_reward = MIN_REWARD;
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
            * (block.number - taxBurnBlock) / CEO_auction_blocks;
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

    /**
    * @dev getStats helps to fetch some stats for the GUI in a single web3 call
    * @param _user the address to return the report for
    * @return uint256[22] the stats
    * @return address of the current CEO
    * @return bytes32 Current graffiti
    */
    function getStats(address _user) external view returns(uint256[] memory, address, bytes32, uint112[] memory) {
        uint[] memory ret = new uint[](22);
        uint112[] memory reserves = new uint112[](2);
        uint256 tpb = (CEO_price / 1000) / (CEO_epoch_blocks); // 0.1% per epoch
        uint256 debt = (block.number - taxBurnBlock) * tpb;
        uint256 price = CEO_price;
        UserInfo memory info = userInfo[_user];
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
        }

        ret[9] = block.number;                     // current block number
        ret[10] = tpb;                             // "tax per block" (tpb)
        ret[11] = debt;                            // tax debt accrued
        ret[12] = lastRewardBlock;                 // the block of the last staking rewards payout update
        ret[13] = info.deposit;                    // amount of LP tokens staked by user
        ret[14] = info.rewardDebt;                 // amount of rewards paid out
        ret[15] = balanceOf[_user];                // amount of CIG held by user
        ret[20] = balanceOf[address(0)];           // amount of CIG burned
        ret[21] = balanceOf[address(punks)];       // amount of CIG to be claimed

        return (ret, The_CEO, graffiti, reserves);
    }

    /*
    * ************************ Token distribution and farming stuff ****************
    */

    /**
    * Claim claims the initial CIG airdrop using a punk
    * @param _punkIndex the index of the punk, number between 0-9999
    */
    function claim(uint256 _punkIndex) external returns(bool) {
        require (_punkIndex <= 9999, "invalid punk");
        require(claims[_punkIndex] == false, "punk already claimed");
        require(msg.sender == punks.punkIndexToAddress(_punkIndex), "punk 404");
        claims[_punkIndex] = true;
        balanceOf[address(punks)] = balanceOf[address(punks)] - CLAIM_AMOUNT; // deduct from the punks contract
        balanceOf[msg.sender] = balanceOf[msg.sender] + CLAIM_AMOUNT;         // deposit to the caller
        emit Transfer(address(punks), msg.sender, CLAIM_AMOUNT);
        emit Claim(msg.sender, _punkIndex, CLAIM_AMOUNT);
        return true;
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
        uint256 lpSupply = lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        // mint some new cigarette rewards to be distributed
        uint256 cigReward = (block.number - lastRewardBlock) * cigPerBlock;
        mint(address(this), cigReward);
        accCigPerShare = accCigPerShare + (
            cigReward * 1e12 / lpSupply
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
        UserInfo storage user = userInfo[_user];
        uint256 lpSupply = lpToken.balanceOf(address(this));
        if (block.number > lastRewardBlock && lpSupply != 0) {
            uint256 cigReward = (block.number - lastRewardBlock) * cigPerBlock;
            _acps = _acps + (
                cigReward * 1e12 / lpSupply
            );
        }
        return (user.deposit * _acps / 1e12) - user.rewardDebt;
    }

    /**
    * @dev deposit deposits LP tokens to be staked. It also harvests rewards.
    * @param _amount the amount of LP tokens to deposit. Assumes this contract has been approved for the _amount.
    */
    function deposit(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        update();
        if (user.deposit > 0) {
            uint256 pending =
            (user.deposit * (accCigPerShare) / 1e12) - user.rewardDebt;
            safeSendPayout(msg.sender, pending);
        }
        if (_amount > 0) {
            lpToken.transferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.deposit = user.deposit + _amount;
            emit Deposit(msg.sender, _amount);
        }
        user.rewardDebt = user.deposit * accCigPerShare / 1e12;
    }

    /**
    * @dev withdraw takes out the LP tokens and pending rewards
    * @param _amount the amount to withdraw
    */
    function withdraw(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.deposit >= _amount, "withdraw: not good");
        update();
        uint256 pending = (user.deposit * accCigPerShare / 1e12) - user.rewardDebt;
        safeSendPayout(msg.sender, pending);
        user.deposit = user.deposit - _amount;
        user.rewardDebt = user.deposit * accCigPerShare / 1e12;
        lpToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _amount);
    }
    /**
    * @dev emergencyWithdraw does a withdraw without caring about rewards. EMERGENCY ONLY.
    */
    function emergencyWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.deposit;
        user.deposit = 0;
        user.rewardDebt = 0;
        lpToken.transfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, amount);

    }
    /**
    * @dev safeSendPayout, just in case if rounding error causes pool to not have enough CIGs.
    * @param _to recipient address
    * @param _amount the value to send
    */
    function safeSendPayout(address _to, uint256 _amount) internal {
        uint256 cigBal = balanceOf[address(this)];
        if (_amount > cigBal) {
            _amount = cigBal;
        }
        balanceOf[address(this)] = balanceOf[address(this)] - _amount;
        balanceOf[_to] = balanceOf[_to] + _amount;
        emit Transfer(address(this), _to, _amount);
    }

    /*
    * ************************ ERC20 Token stuff ********************************
    */

    /**
    * @dev burn some tokens
    * @param _from The address to burn from
    * @param _amount The amount to burn
    */
   function burn(address _from, uint256 _amount) internal {
       balanceOf[_from] = balanceOf[_from] - _amount;
       totalSupply = totalSupply - _amount;
       emit Transfer(_from, address(0), _amount);
   }

   /**
   * @dev mint new tokens
   * @param _to The address to mint to.
   * @param _amount The amount to be minted.
   */
    function mint(address _to, uint256 _amount) internal {
        require(_to != address(0), "ERC20: mint to the zero address");
        totalSupply = totalSupply + _amount;
        balanceOf[_to] = balanceOf[_to] + _amount;
        emit Transfer(address(0), _to, _amount);
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        // require(_value <= balanceOf[msg.sender], "value exceeds balance"); // SafeMath already checks this
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
        //require(_value <= balanceOf[_from], "value exceeds balance"); // SafeMath already checks this
        require(_value <= allowance[_from][msg.sender], "not approved");
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
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /********************************************************************
    * @dev onSushiReward IRewarder methods to be called by the SushSwap MasterChefV2 contract
    */

    function onSushiReward (
        uint256 /* pid */,
        address _user,
        address _to,
        uint256 /* sushiAmount*/,
        uint256 _newLpAmount)  external onlyMCV2 {
        UserInfo storage user = userInfo[_user];
        update();
        if (user.deposit > 0) {
            uint256 pending = (user.deposit * accCigPerShare / 1e12) - user.rewardDebt;
            safeSendPayout(_to, pending);
        }
        user.deposit = _newLpAmount;
        user.rewardDebt = user.deposit * accCigPerShare / 1e12;
    }

    /**
    * pendingTokens returns the number of pending CIG rewards, implementing IRewarder
    * @param user it is the only parameter we look at
    */
    function pendingTokens(uint256 pid, address user, uint256 sushiAmount) external view returns (IERC20[] memory, uint256[] memory) {
        IERC20[] memory _rewardTokens = new IERC20[](1);
        _rewardTokens[0] = IERC20(address(this));
        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = pendingCig(user);
        return (_rewardTokens, _rewardAmounts);
    }
    // onlyMCV2 ensures only the MasterChefV2 contract can call this
    modifier onlyMCV2 {
        require(
            msg.sender == MASTERCHEF_V2,
            "Only MCV2"
        );
        _;
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
}

/**
* @dev sushi router 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
*/
interface IRouterV2 {
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns(uint256 amountOut);

}



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

// IRewarder allows the contract to be called by SushSwap MasterChefV2
// example impl https://etherscan.io/address/0x7519c93fc5073e15d89131fd38118d73a72370f8/advanced#code
interface IRewarder {
    function onSushiReward(uint256 pid, address user, address recipient, uint256 sushiAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 sushiAmount) external view returns (IERC20[] memory, uint256[] memory);
}

/*
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 is IRewarder {
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
}