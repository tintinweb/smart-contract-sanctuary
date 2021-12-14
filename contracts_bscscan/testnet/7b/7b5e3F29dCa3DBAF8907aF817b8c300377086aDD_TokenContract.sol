/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)
pragma solidity ^0.8.6;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Error: Strings: hex length insufficient");
        return string(buffer);
    }
}

/////////////////////////////////////////
//SafeMath
/////////////////////////////////////////
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Error: SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "Error: SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Error: SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "Error: SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "Error: SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/////////////////////////////////////////
//Contract standard interface
/////////////////////////////////////////
interface BaseInterface {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

/////////////////////////////////////////
//Token Contract
/////////////////////////////////////////
contract TokenContract is BaseInterface {
    using SafeMath for uint256;
    
    /////////////////////////////////////////
    //Maps
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromCommission;
    mapping(address => bool) private _isInInvestorsList;

    //Contract details
    string private constant _name = "Poverty Coin";
    string private constant _symbol = "PVTY";
    uint256 private         _totalSupply = 0;
    uint8 private constant  _decimals = 18;
    uint256 private         _totalBurned = 0;
    uint256 private         _totalRedistributed = 0;
    uint256 private         _totalCharity = 0;
    
    //Addresses (testnet)
    address public constant _adminAddress      = address(0x18785AEE023b7b3FB14e603724D0Db89b8edb27a);
    address public constant _charityAddress    = address(0x72290A428a915c6151867ACE8adc5b970B7A2AC8);
    address public constant _devAddress        = address(0x7ecf8A0615c4B7b6BF7D2c50028C9737B63b1b85);
    address public constant _marketingAddress  = address(0x4C8027f250a30CF6F802C0F0d4279414E33beb82);
    address public constant _liquidityAddress  = address(0x5AD388b8EaC05791893606F328e753deC95347A2);
    address public constant _reflectionAddress = address(0x6075373760A81dE3f022C0C4390938565b14819d);
    address public constant _burnerAddress     = address(0x9B9b1B71C490Da5Dc0Ae54675C318C47608cA1c9);

    address public constant _andreiAddress     = address(0x294A419CbC68dAa43A45e7ebf57581D99ef7Bfbd);
    address public constant _claudiaAddress    = address(0xF233cecEf3679Af17FC8937790654aD077D015de);
    address public constant _patrickAddress    = address(0x6B9B44d8916795a5E4AB2668022F61Edc99CcbdB);

    address[] private _investorsAddressList;
    
    //Commission
    uint256 private constant _liquidityCommission  = 200;   // 2.0%
    uint256 private constant _charityCommission    = 200;   // 2.0%
    uint256 private constant _reflectionCommission = 100;   // 1.0%
    uint256 private constant _burnCommission       = 100;   // 1.0%
    uint256 private constant _marketingCommission  = 50;    // 0.5%
    uint256 private constant _devCommission        = 50;    // 0.5%

    //Contract restrictions
    bool private _isTradingEnabled = false;
    bool private _isCommissionEnabled = true;
    
    //Sale 
    bool private    _isSellingCampaignOngoing = false;
    uint256 private _sellingCampaignOneBNBPriceInCoins; // eg: 1 BNB == 50000 Poverty Coins
    uint256 private _sellingCampaignLeftCoins;
    uint256 private _sellingCampaignTotalCoins;
    uint256 private _sellingCampaignMinTransactionCoins;
    uint256 private _sellingCampaignMaxTransactionCoins;
    uint256 private _sellingCampaignMaxBalance;
    uint256 private _sellingCampaignLiquidityCoef;
    mapping(address => uint256) private _sellingCampaignBalances;

    //Reflection
    uint256 private _reflectionMinAccountBalance = 20000 * (10 ** uint256(_decimals)); // min ballance of X amount of coins to be able to get reflection 
    
    //Staking
    struct StakeEntry{
        uint256 _balance;
        uint256 _releaseTime;
        uint256 _rate;
    }
    mapping(address => StakeEntry) private _stakingBalances;
    uint256 private _stakingRewardRate = 5;      //   5 - meaning 0.5%
    uint256 private _stakingRewardRateMax = 100; // 100 - meaning 10%

    //Staking bonus
    uint256 private _stakingBonusMinAccountBalance = 50000 * (10 ** uint256(_decimals)); // min ballance of X amount of coins to be able to claim staking bonus
    mapping(address => mapping(address => bool)) private _stakingBonusConnectionsMap;
    mapping(address => uint256) private _stakingBonusConnections;
    uint256 private _stakingBonusRate = 1; // 0.1%
    uint256 private _stakingBonusPerConnections = 10;
    uint256 private _stakingBonusMaxConnections = 150;

    mapping(address => string) private _stakingBonusAddressToCode;
    mapping(string => address) private _stakingBonusCodeToAddress;
    /////////////////////////////////////////

    /////////////////////////////////////////
    //Return codes
    /////////////////////////////////////////
    uint256 private constant CODE_CONNECTIONS_CODE_NOT_FOUND = 999;
    uint256 private constant STAKE_REMAINING_TIME_NO_STAKING = 999999999;
    
    /////////////////////////////////////////
    //Events
    /////////////////////////////////////////
    event Mint(address minter, uint256 amount);
    event Burn(address burner, uint256 amount);
    event TakeCommission(address fromAddress, uint256 amount);
    event ReflectionSentToInvestors(uint256 investorShare);
    //stake
    event Stake(address fromAddress, uint256 amount, uint256 rate, uint256 releaseTime);
    event StakeReward(address fromAddress, uint256 amount, uint256 rate);
    event CancelOngoingStake(address fromAddress, uint256 amount, uint256 rate);
    event StakeBonusClaimed(address fromAddress);
    event StakeBonusCodeSet(address fromAddress);
    //sale
    event StartSale(uint256 coinsPrice, uint256 totalCoinsToSell);
    event CoinsSold(address toAddress, uint256 amount);
    event EndSale(uint256 coinsLeft, uint256 totalCoinsToSell);

    /////////////////////////////////////////
    //Modifiers
    /////////////////////////////////////////
    modifier onlyAdmin { require(_adminAddress == msg.sender, "Error: Caller is not Admin !"); _; }
    modifier onlyBurner { require(_burnerAddress == msg.sender, "Error: Caller is not Burner !"); _; }
    modifier onlyReflection { require (_reflectionAddress == msg.sender, "Error: Caller is not Reflection !"); _; }
    modifier onlyLiquidity { require (_liquidityAddress == msg.sender, "Error: Caller is not Liquidity !"); _; }
    modifier tradingCheck { require(_isTradingEnabled == true, "Error: Trading is not enabled !"); _; }
    modifier addressCheck { 
        if(!_isInInvestorsList[msg.sender]) {
            _investorsAddressList.push(msg.sender); 
            _isInInvestorsList[msg.sender] = true;
        } 
        _; 
    }
    
    /////////////////////////////////////////
    //Getters
    /////////////////////////////////////////
    //BaseInterface
    function name() public pure override returns (string memory) { return _name; }
    function symbol() public pure override returns (string memory) { return _symbol; }
    function decimals() public pure override returns (uint8) { return _decimals; }
    function totalSupply() public view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) public view override returns (uint256) { return _allowances[owner][spender]; }
    //Trading
    function getIsTradingEnabled() public view returns (bool) { return _isTradingEnabled; }
    //Sale
    function getCoinsPrice() public view returns (uint256) { return _sellingCampaignOneBNBPriceInCoins; }
    function getIsSellingCampaignOngoing() public view returns (bool) { return _isSellingCampaignOngoing; }
    function getSellingCampaignLeftCoins() public view returns (uint256) { return _sellingCampaignLeftCoins; }
    function getSellingCampaignTotalCoins() public view returns (uint256) { return _sellingCampaignTotalCoins; }
    function getSellingCampaignBalanceLimit() public view returns (uint256) { return _sellingCampaignMaxBalance; }
    function getSellingCampaignMinTransactionCoins() public view returns (uint256) { return _sellingCampaignMinTransactionCoins; }
    function getSellingCampaignMaxTransactionCoins() public view returns (uint256) { return _sellingCampaignMaxTransactionCoins; }
    function getSellingCampaignBalance(address account) public view returns (uint256) { return _sellingCampaignBalances[account]; }
    //Staking
    function getStakeInvestedCoins() public view returns (uint256) { return _stakingBalances[msg.sender]._balance;}
    function getStakingRewardRate() public view returns (uint256) { return _stakingRewardRate; }
    function getStakingMyCurrentRate() public view returns (uint256) { return _stakingBalances[msg.sender]._rate; }
    function getStakingBonusMyRate() public view returns (uint256) { return _stakingBonusConnections[msg.sender].div(_stakingBonusPerConnections);}
    function getStakingBonusMyConnections() public view returns (uint256) { return _stakingBonusConnections[msg.sender]; }
    function getStakingBonusCodeConnections(string memory code) public view returns (uint256) { 
        if(_stakingBonusCodeToAddress[code] == address(0))
            return CODE_CONNECTIONS_CODE_NOT_FOUND;
        return _stakingBonusConnections[_stakingBonusCodeToAddress[code]]; 
    }
    function getStakingBonusMinAccountBalance() public view returns (uint256) { return _stakingBonusMinAccountBalance; }
    //Burn
    function getTotalBurned() public view returns (uint256) { return _totalBurned; }
    //Reflection
    function getTotalRedistributed() public view returns (uint256) { return _totalRedistributed; }
    function getRedistributionMinAccountBalance() public view returns (uint256) { return _reflectionMinAccountBalance; }
    //Charity
    function getTotalCharity() public view returns (uint256) { return _totalCharity; }
    //Code
    function getMyInvitationCode() public view returns (string memory) { return _stakingBonusAddressToCode[msg.sender]; }

    /////////////////////////////////////////
    //Setters
    /////////////////////////////////////////
    //Min account balance to be able to claim staking bonus
    function setStakingBonusMinAccountBallanceToGetBonus(uint256 newMinBalance) public onlyAdmin { _stakingBonusMinAccountBalance = newMinBalance; } 
    //Min account balance to be able to get reflection
    function setReflectionMinAccountBallanceToGetBonus(uint256 newMinBalance) public onlyAdmin { _reflectionMinAccountBalance = newMinBalance; }
    //Staking reward rate
    function setStakingRewardRate(uint256 newRate) public onlyAdmin { require(newRate <= _stakingRewardRateMax, "Error: Stake rate too high !"); _stakingRewardRate = newRate; }
    //Global fee enabled/disabled
    function setCommissionEnabled(bool status) public onlyAdmin { _isCommissionEnabled = status; }
    
    
    /////////////////////////////////////////
    //Entry Point
    /////////////////////////////////////////
    constructor() {

        /////////////////////////////////////////
        //Minting 10.000.000.000 coins having 18 decimals
        /////////////////////////////////////////
        uint256 mintAmount = 10 * (10**9) * (10 ** uint256(_decimals)); 
        _totalSupply = _totalSupply.add(mintAmount);

        //put all coins on contract
        _balances[address(this)] = _balances[address(this)].add(mintAmount);

        //emit mint event
        emit Mint(_liquidityAddress, mintAmount);

        /////////////////////////////////////////
        //Send coins to Team, Marketing, Dev Wallets 
        /////////////////////////////////////////
        //10% to the team
        _balances[_andreiAddress]  = _balances[address(this)].div(20); // 100% / 20 = 5%
        _balances[_claudiaAddress] = _balances[address(this)].div(40); // 100% / 40 = 2.5%
        _balances[_patrickAddress] = _balances[address(this)].div(40); // 100% / 40 = 2.5%
        //5% to the marketing address
        _balances[_marketingAddress]  = _balances[address(this)].div(20); // 100% / 20 = 5%
        //5% to the dev address
        _balances[_devAddress]  = _balances[address(this)].div(20); // 100% / 20 = 5%

        //take out 20%
        _balances[address(this)] = _balances[address(this)].sub(_balances[address(this)].div(5)); //take 20% out 

        //emit transfer event
        emit Transfer(address(this), _andreiAddress, _balances[_andreiAddress]);
        emit Transfer(address(this), _claudiaAddress, _balances[_claudiaAddress]);
        emit Transfer(address(this), _patrickAddress, _balances[_patrickAddress]);
        emit Transfer(address(this), _marketingAddress, _balances[_marketingAddress]);
        emit Transfer(address(this), _devAddress, _balances[_devAddress]);


        /////////////////////////////////////////
        //Mark addresses as investors in order to be able to receive redistribution reward
        /////////////////////////////////////////
        _investorsAddressList.push(_charityAddress);
        _investorsAddressList.push(_liquidityAddress);
        _investorsAddressList.push(_marketingAddress);
        _investorsAddressList.push(_devAddress);
        _investorsAddressList.push(_andreiAddress);
        _investorsAddressList.push(_claudiaAddress);
        _investorsAddressList.push(_patrickAddress);

        //also update the maps
        _isInInvestorsList[_charityAddress] = true;
        _isInInvestorsList[_liquidityAddress] = true;
        _isInInvestorsList[_marketingAddress] = true;
        _isInInvestorsList[_devAddress] = true;
        _isInInvestorsList[_andreiAddress] = true;
        _isInInvestorsList[_claudiaAddress] = true;
        _isInInvestorsList[_patrickAddress] = true;

        //mark the contract as investor but don't put it in investors list
        //this helps to not add contract to investors list in the future by mistake
        _isInInvestorsList[address(this)] = true;


        /////////////////////////////////////////
        //Exclude liquidity, charity, redistribution, burn addresses from fees
        //team, marketing, dev address have to pay fees 
        /////////////////////////////////////////
        _isExcludedFromCommission[_liquidityAddress] = true;
        _isExcludedFromCommission[_charityAddress] = true;
    }

    /////////////////////////////////////////
    //Coins sell
    /////////////////////////////////////////
    function startSellingCampaign(
        uint256 oneBNBPriceInCoins, 
        uint256 totalCoinsToSell, 
        uint256 minTransactionCoins,
        uint256 maxTransactionCoins,
        uint256 maxBalance,
        uint256 liqCoef) 
        public onlyAdmin {
        
        require(_isSellingCampaignOngoing == false, "Error: Sale in progress !");
        require(totalCoinsToSell <= _balances[address(this)], "Error: Not enough coins on contract to start a sale !");
            
        _sellingCampaignMaxBalance = maxBalance;
        _sellingCampaignMinTransactionCoins = minTransactionCoins;
        _sellingCampaignMaxTransactionCoins = maxTransactionCoins;
        _sellingCampaignLiquidityCoef = liqCoef;
            
        _sellingCampaignTotalCoins = totalCoinsToSell;
        _sellingCampaignLeftCoins = totalCoinsToSell;
        _sellingCampaignOneBNBPriceInCoins = oneBNBPriceInCoins;

        _isSellingCampaignOngoing = true;
        _isTradingEnabled = false;
        
        emit StartSale(oneBNBPriceInCoins, totalCoinsToSell);
    }

    receive() external payable
    {
        //addresses not allowed to use this function
        if (msg.sender == _adminAddress) return;
        if (msg.sender == _liquidityAddress) return;
        if (msg.sender == _charityAddress) return;
        if (msg.sender == _reflectionAddress) return;
        if (msg.sender == _burnerAddress) return;
        if (msg.sender == _marketingAddress) return;
        if (msg.sender == _devAddress) return;

        uint256 coinsAmount = msg.value.div(_sellingCampaignOneBNBPriceInCoins); //in wei

        require(_isSellingCampaignOngoing == true, "Error: No selling campaign !");
        require(coinsAmount >= _sellingCampaignMinTransactionCoins, "Error: You are under the Min transaction coins requirement !");
        require(coinsAmount <= _sellingCampaignMaxTransactionCoins, "Error: You are over the Max transaction coins requirement !");
        require(coinsAmount + _sellingCampaignBalances[msg.sender] <= _sellingCampaignMaxBalance, "Error: Over Max balance limit !");
        require(coinsAmount <= _sellingCampaignLeftCoins, "Error: Over the coins left in the sale !");
        
        //97% to liquidity
        payable(_liquidityAddress).transfer(msg.value.mul(97).div(100));
        //1% charity
        payable(_charityAddress).transfer(msg.value.div(100));
        //2% marketing
        payable(_marketingAddress).transfer(msg.value.div(50));

        _sellingCampaignBalances[msg.sender] = _sellingCampaignBalances[msg.sender].add(coinsAmount);
        _sellingCampaignLeftCoins = _sellingCampaignLeftCoins.sub(coinsAmount);

        //send the equivalent amount of coins to the liquidity address
        _balances[_liquidityAddress] = _balances[_liquidityAddress].add(coinsAmount * _sellingCampaignLiquidityCoef);

        //subtract liquidity coins from the contract
        _balances[address(this)] = _balances[address(this)].sub(coinsAmount * _sellingCampaignLiquidityCoef);
        
        //if everything was ok, add msg.sender to investors list
        if(!_isInInvestorsList[msg.sender]) {
            _investorsAddressList.push(msg.sender); 
            _isInInvestorsList[msg.sender] = true;
        } 

        emit CoinsSold(msg.sender, coinsAmount);
    }
     
    function endSellingCampaign() public onlyAdmin {
        require(_isSellingCampaignOngoing == true, "Error: No sale ongoing !");
        _isSellingCampaignOngoing = false;
        
        _balances[address(this)] = _balances[address(this)].sub(_sellingCampaignTotalCoins).add(_sellingCampaignLeftCoins);
        
        for(uint256 i = 0; i < _investorsAddressList.length; i++) {
            if (_sellingCampaignBalances[_investorsAddressList[i]] > 0) {
                _balances[_investorsAddressList[i]] = _balances[_investorsAddressList[i]].add(_sellingCampaignBalances[_investorsAddressList[i]]);
                _sellingCampaignBalances[_investorsAddressList[i]] = 0;
            }
        }

        _isTradingEnabled = true;

        _sellingCampaignMaxBalance = 0;
        _sellingCampaignMinTransactionCoins = 0;
        _sellingCampaignMaxTransactionCoins = 0;
        _sellingCampaignLiquidityCoef = 0;
            
        _sellingCampaignTotalCoins = 0;
        _sellingCampaignLeftCoins = 0;
        _sellingCampaignOneBNBPriceInCoins = 0;
        
        emit EndSale(_sellingCampaignLeftCoins, _sellingCampaignTotalCoins);
    }
    
    
    /////////////////////////////////////////
    //Transfer
    /////////////////////////////////////////
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        //addresses not allowed to use this function
        if (msg.sender == _adminAddress) return false;
        if (msg.sender == _liquidityAddress) return false;
        if (msg.sender == _reflectionAddress) return false;
        if (msg.sender == _burnerAddress) return false;

        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        //addresses not allowed to use this function
        if (msg.sender == _adminAddress) return false;
        if (msg.sender == _reflectionAddress) return false;
        if (msg.sender == _burnerAddress) return false;

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) private addressCheck tradingCheck {
        _beforeContractOperation(sender, recipient, amount);
        
        //take commission 
        uint256 remainingAmount = _takeCommission(sender, recipient, amount);
        
        _balances[sender]    = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(remainingAmount);

        //add direct donations to total charity amount
        if(recipient == _charityAddress)
            _totalCharity = _totalCharity.add(remainingAmount);
        
        emit Transfer(sender, recipient, remainingAmount);
    }


    /////////////////////////////////////////
    //Before & After Transfer
    /////////////////////////////////////////
    function _beforeContractOperation(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Error: zero address");
        require(recipient != address(0), "Error: zero address");
        require(amount > 0, "Error: zero amount");
        
        //Add sender & recipent to investors list
        if(!_isInInvestorsList[sender]) {
            _investorsAddressList.push(sender);
            _isInInvestorsList[sender] = true;
        }
        if(!_isInInvestorsList[recipient]) {
            _investorsAddressList.push(recipient);
            _isInInvestorsList[recipient] = true;
        }
    }


    /////////////////////////////////////////
    //Staking
    /////////////////////////////////////////
    function collectStakingBonus(string memory code) public
    {
        require(_stakingBonusCodeToAddress[code] != address(0), "Error: This code is not valid !");
        require(_stakingBonusCodeToAddress[code] != msg.sender, "Error: You can't redeem your personal code !");
        require(_stakingBonusConnectionsMap[msg.sender][_stakingBonusCodeToAddress[code]] == false, "Error: Code already redeemed !");
        require(_stakingBonusConnections[_stakingBonusCodeToAddress[code]] < _stakingBonusMaxConnections, "Error: Code has max number of connections !");
        require(_stakingBonusConnections[msg.sender] < _stakingBonusMaxConnections, "Error: You have max number of connections !");
        require(_balances[_stakingBonusCodeToAddress[code]] >= _stakingBonusMinAccountBalance, "Error: Code has bellow min account balance!");
        require(_balances[msg.sender] >= _stakingBonusMinAccountBalance, "Error: You have bellow min account balance!");
        
        //map connection
        _stakingBonusConnectionsMap[msg.sender][_stakingBonusCodeToAddress[code]] = true;
        _stakingBonusConnectionsMap[_stakingBonusCodeToAddress[code]][msg.sender] = true;

        //increase connections number
        _stakingBonusConnections[_stakingBonusCodeToAddress[code]] = _stakingBonusConnections[_stakingBonusCodeToAddress[code]].add(1);
        _stakingBonusConnections[msg.sender] = _stakingBonusConnections[msg.sender].add(1);

        emit StakeBonusClaimed(msg.sender);
    }

    function setStakingBonusCode(string memory myCode) public  {
        require(bytes(myCode).length >= 4, "Error: Code must be at least 4 characters !");
        require(_stakingBonusCodeToAddress[myCode] == address(0), "Error: This code is used !");

        _stakingBonusAddressToCode[msg.sender] = myCode;
        _stakingBonusCodeToAddress[myCode] = msg.sender;

        emit StakeBonusCodeSet(msg.sender);
    }

    function getStakeRemainingTime() public view returns (uint256) {

        if (_stakingBalances[msg.sender]._releaseTime == 0 && _stakingBalances[msg.sender]._balance == 0)
            return STAKE_REMAINING_TIME_NO_STAKING;

        if (_stakingBalances[msg.sender]._releaseTime != 0 && _stakingBalances[msg.sender]._balance != 0){
            if (_stakingBalances[msg.sender]._releaseTime <= block.timestamp){
                return 0;
            }
            else{
                return (_stakingBalances[msg.sender]._releaseTime - block.timestamp);
            }
        }

        return 1;
    }

    function stakeCoins(uint256 amount) public tradingCheck {
        //addresses not allowed to use this function
        if (msg.sender == _adminAddress) return;
        if (msg.sender == _liquidityAddress) return;
        if (msg.sender == _charityAddress) return;
        if (msg.sender == _reflectionAddress) return;
        if (msg.sender == _burnerAddress) return;
        if (msg.sender == _marketingAddress) return;
        if (msg.sender == _devAddress) return;

        require(amount >= 1000, "Error: Amount must be at least 1000 wei !");
        require(amount <= _balances[msg.sender], "Error: You do not have enough balance !");
        require(_stakingBalances[msg.sender]._balance == 0 && _stakingBalances[msg.sender]._releaseTime == 0, "Error: There is already a stake on this address !");

        uint256 totalRewardRate = _stakingRewardRate.add(getStakingBonusMyRate());
        uint256 expectedReward = amount.mul(totalRewardRate).div(1000);

        _balances[address(this)] = _balances[address(this)].sub(expectedReward, "Not enough supply to provide reward !"); //subtract expected reward from contract
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _stakingBalances[msg.sender] = StakeEntry(amount, block.timestamp + 60 seconds, totalRewardRate);
        emit Stake(msg.sender, amount, totalRewardRate, block.timestamp + 60 seconds);
    }
    function getStakeReward() public {
        require(_stakingBalances[msg.sender]._balance != 0 && _stakingBalances[msg.sender]._releaseTime != 0, "Error: No staking on this address !");
        require(block.timestamp >= _stakingBalances[msg.sender]._releaseTime, "Error: Staking not finished yet !");
        
        uint256 reward = _stakingBalances[msg.sender]._balance;
        uint256 rate = _stakingBalances[msg.sender]._rate;
        _stakingBalances[msg.sender]._balance = 0;
        _stakingBalances[msg.sender]._releaseTime = 0;
        _stakingBalances[msg.sender]._rate = 0;

        reward = reward.add(reward.mul(rate).div(1000));
        
        _balances[msg.sender] = _balances[msg.sender].add(reward);
        emit StakeReward(msg.sender, reward, rate);
    }
    
    function cancelOngoingStake() public {
        require(_stakingBalances[msg.sender]._balance != 0 && _stakingBalances[msg.sender]._releaseTime != 0, "Error: No staking on this address !");
        
        uint256 balance = _stakingBalances[msg.sender]._balance;
        uint256 rate = _stakingBalances[msg.sender]._rate;
        _stakingBalances[msg.sender]._balance = 0;
        _stakingBalances[msg.sender]._releaseTime = 0;
        _stakingBalances[msg.sender]._rate = 0;

        uint256 expectedReward = balance.mul(rate).div(1000);

        _balances[address(this)] = _balances[address(this)].add(expectedReward); //put expected reward back on contract
        _balances[msg.sender] = _balances[msg.sender].add(balance);
        emit CancelOngoingStake(msg.sender, balance, rate);
    }

    /////////////////////////////////////////
    //Allowance & Approve
    /////////////////////////////////////////
    function approve(address spender, uint256 amount) public override returns (bool) {
        //addresses not allowed to use this function
        if (msg.sender == _adminAddress) return false;
        if (msg.sender == _reflectionAddress) return false;
        if (msg.sender == _burnerAddress) return false;

        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Error: approve from the zero address");
        require(spender != address(0), "Error: approve to the zero address");
        require(amount > 0, "Error: zero amount");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    /////////////////////////////////////////
    //Commision   (Liquidity, Burn, Reflection, Charity, Marketing, Dev)
    /////////////////////////////////////////
    function _takeCommission(address spender, address recipient, uint256 amount) private  returns (uint256) {
        if (_isExcludedFromCommission[spender] || _isExcludedFromCommission[recipient])
            return amount;
        
        if(_isCommissionEnabled == false)
            return amount;

        //no commission for transactions bellow 0.000000000000001000 Pvty coins
        if (amount < 1000)
            return amount;

        uint256 liquidity  = amount.mul(_liquidityCommission).div(10**4); //ex: liq = amount * 250 / 10 ** 4  => liq = amount * 0.025 
        uint256 burning    = amount.mul(_burnCommission).div(10**4);
        uint256 reflection = amount.mul(_reflectionCommission).div(10**4);
        uint256 charity    = amount.mul(_charityCommission).div(10**4);
        uint256 marketing  = amount.mul(_marketingCommission).div(10**4);
        uint256 dev        = amount.mul(_devCommission).div(10**4);
        
        uint256 totalCommission = 0;
        totalCommission = totalCommission.add(liquidity).add(burning).add(reflection);
        totalCommission = totalCommission.add(charity).add(marketing).add(dev);
        
        _balances[_liquidityAddress]  = _balances[_liquidityAddress].add(liquidity);
        _balances[_burnerAddress]     = _balances[_burnerAddress].add(burning);
        _balances[_reflectionAddress] = _balances[_reflectionAddress].add(reflection);
        _balances[_charityAddress]    = _balances[_charityAddress].add(charity);
        _balances[_marketingAddress]  = _balances[_marketingAddress].add(marketing);
        _balances[_devAddress]        = _balances[_devAddress].add(dev);

        //keep track of total charity amount
        _totalCharity = _totalCharity.add(charity);
        
        emit TakeCommission(spender, totalCommission);
        
        return amount.sub(totalCommission);
    }

    
    /////////////////////////////////////////
    //Reflection
    /////////////////////////////////////////
    function sendReflection() public onlyReflection {
        uint256 minRequiredWallets = 0;
        for (uint256 i = 0; i < _investorsAddressList.length; i++) 
            if (_balances[_investorsAddressList[i]] > _reflectionMinAccountBalance)
                minRequiredWallets += 1;
        
        if (minRequiredWallets == 0)
            minRequiredWallets = 1;
        
        uint256 reflectionAmount = _balances[_reflectionAddress];
        _totalRedistributed = _totalRedistributed.add(reflectionAmount);
        _balances[_reflectionAddress] = 0;

        uint256 investorShare = reflectionAmount.div(minRequiredWallets);
        for (uint256 i = 0; i < _investorsAddressList.length; i++) 
            if (_balances[_investorsAddressList[i]] > _reflectionMinAccountBalance)
                _balances[_investorsAddressList[i]] = _balances[_investorsAddressList[i]].add(investorShare);
        
        emit ReflectionSentToInvestors(investorShare);
    }
    
    /////////////////////////////////////////
    //Supply
    /////////////////////////////////////////
    function getCirculatingSupply() public view returns (uint256) {
        uint256 circulatingSupply = 0;
        for (uint256 i = 0; i < _investorsAddressList.length; i++) 
                circulatingSupply = circulatingSupply.add(_balances[_investorsAddressList[i]]);
            
        return circulatingSupply;
    }


    /////////////////////////////////////////
    //Burn
    /////////////////////////////////////////
    function burn(uint256 amount) public onlyBurner {
        require(_balances[_burnerAddress] >= amount, "Error: Amount bigger than balance !");
         
        _balances[_burnerAddress] = _balances[_burnerAddress].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        _totalBurned = _totalBurned.add(amount);
        emit Burn(_burnerAddress, amount);
    }
    
    
    /////////////////////////////////////////
    //Fallback
    /////////////////////////////////////////
    fallback() external payable {}
    
    
    
}