pragma solidity ^0.4.24;

//  _______  .______        ___      .__   __.  __  ___
// |       \ |   _  \      /   \     |  \ |  | |  |/  /
// |  .--.  ||  |_)  |    /  ^  \    |   \|  | |  &#39;  /
// |  |  |  ||   _  <    /  /_\  \   |  . `  | |    <
// |  &#39;--&#39;  ||  |_)  |  /  _____  \  |  |\   | |  .  \
// |_______/ |______/  /__/     \__\ |__| \__| |__|\__\
// 
// VISIT => http://dbank.money
// 
// The first global decentralized bank.
// 
// 1. GAIN 4% PER 24 HOURS (every 5900 blocks)
// 2. [FREE BONUS] New users get a 0.1 ETH bonus immediately!
// 3. [REFERRAL BONUS] If you invite your friend to invest, you both get a 10% bonus.
// 4. NO COMMISSION. NO FEES.
// 
// Contracts reviewed and approved by pros!

contract DBank {
    uint256 dbk_;   // total investment in DBank
    mapping (address => uint256) invested; // address => investment
    mapping (address => uint256) atBlock; // address => user&#39;s investment at block
    uint256 public r_ = 2; //profit ratio，every 5900 blocks(1 day) you earn 4%
    uint256 public blocks_ = 5900; //blocks in every cycle

    // Player and referral bonus
    uint256 public pID_;    // total number of players
    mapping (address => uint256) public pIDxAddr_;  // (addr => pID) returns player id by address
    mapping (uint256 => address) public plyr_;   // (pID => data) player data

    // New User Bonus
    bool public bonusOn_ = true;    // give bonus or not
    uint256 public bonusAmount_ = 1 * 10**16;   // 0.01 ETH

    // this function called every time anyone sends a transaction to this contract
    function ()
        external 
        payable
    {
        buyCore(msg.sender, msg.value);
    }

    // buy with refferal ID
    function buy(uint256 refID)
        public
        payable
    {
        buyCore(msg.sender, msg.value);

        // bonus for refferal 10%
        if (plyr_[refID] != address(0)) {
            invested[plyr_[refID]] += msg.value / 10;
        }

        // bonus for user self 10%
        invested[msg.sender] += msg.value / 10;
    }

    // Reinvest
    function reinvest()
        public
    {
        if (invested[msg.sender] != 0) {
            uint256 amount = invested[msg.sender] * r_ / 100 * (block.number - atBlock[msg.sender]) / blocks_;
            
            atBlock[msg.sender] = block.number;
            invested[msg.sender] += amount;
        }
    }

    // === Getters ===

    // get investment and profit
    // returns: base, profit, playerID, players
    function getMyInvestment()
        public
        view
        returns (uint256, uint256, uint256, uint256)
    {
        uint256 amount = 0;
        if (invested[msg.sender] != 0) {
            amount = invested[msg.sender] * r_ / 100 * (block.number - atBlock[msg.sender]) / blocks_;
        }
        return (invested[msg.sender], amount, pIDxAddr_[msg.sender], pID_);
    }

    // === Private Methods ===

    // Core Logic of Buying
    function buyCore(address _addr, uint256 _value)
        private
    {
        // New user check
        bool isNewPlayer = determinePID(_addr);

        // If you have investment
        if (invested[_addr] != 0) {
            uint256 amount = invested[_addr] * r_ / 100 * (block.number - atBlock[_addr]) / blocks_;
            
            // send calculated amount of ether directly to sender (aka YOU)
            if (amount <= dbk_){
                _addr.transfer(amount);
                dbk_ -= amount;
            }
        }

        // record block number and invested amount (msg.value) of this transaction
        atBlock[_addr] = block.number;
        invested[_addr] += _value;
        dbk_ += _value;
        
        // if bonus is On and you&#39;re a new player, then you&#39;ll get bonus
        if (bonusOn_ && isNewPlayer) {
            invested[_addr] += bonusAmount_;
        }
    }

    // get players ID by address
    // If doesn&#39;t exist, then create one.
    // returns: is new player or not
    function determinePID(address _addr)
        private
        returns (bool)
    {
        if (pIDxAddr_[_addr] == 0)
        {
            pID_++;
            pIDxAddr_[_addr] = pID_;
            plyr_[pID_] = _addr;
            
            return (true);  // New Player
        } else {
            return (false);
        }
    }

    // === Only owner ===

    address owner;
    constructor() public {
        owner = msg.sender;
        pID_ = 500;
    }

    // Only owner modifier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Set new user bonus on/off
    function setBonusOn(bool _on)
        public
        onlyOwner()
    {
        bonusOn_ = _on;
    }

    // Set new user bonus amount
    function setBonusAmount(uint256 _amount)
        public
        onlyOwner()
    {
        bonusAmount_ = _amount;
    }

    // Set profit ratio
    function setProfitRatio(uint256 _r)
        public
        onlyOwner()
    {
        r_ = _r;
    }

    // Set profit ratio
    function setBlocks(uint256 _blocks)
        public
        onlyOwner()
    {
        blocks_ = _blocks;
    }

    // ======= Deprecated Version of DBank =======

    // *** Deprecated. ***
    // deposit in dbank
    mapping (address => uint256) public deposit_; 

    // *** Deprecated. ***
    // deposit in dbk deposit(no reward)
    function dbkDeposit()
        public
        payable
    {
        deposit_[msg.sender] += msg.value;
    }

    // *** Deprecated. ***
    // withdraw from dbk deposit
    function dbkWithdraw()
        public
    {
        uint256 _eth = deposit_[msg.sender];
        if (_eth > 0) {
            msg.sender.transfer(_eth);
            deposit_[msg.sender] = 0;
        }
    }
}