//SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;
import "./Ownable.sol";
import "./CrushCoin.sol";
import "./SafeMath.sol";
import "./staking.sol";
import "./HouseBankroll.sol";
import "./LiveWallet.sol";
contract BitcrushBankroll is Ownable {
    using SafeMath for uint256;

    uint256 public totalBankroll;
    uint256 public allTimeHigh;
    uint256 public availableProfit;
    bool poolDepleted = false;
    uint256 negativeBankroll;
    //address of the crush token
    CRUSHToken public crush;
    BitcrushStaking public stakingPool;
    BitcrushLiveWallet public liveWallet;
    address public reserve;
    address public lottery;
    uint256 gameIds = 1;
    uint256 constant public DIVISOR = 10000;
    uint256 constant public burnRate = 100;
    uint256 public profitThreshold = 0;
    //todo add configurable values for distribution of house profit
    //consistent 1% burn
    
    //todo house to housebankroll
    struct game {
        uint256 profit;
        bytes32 identifier;
        uint256 houseBankrollShare;
        uint256 lotteryShare;
        uint256 reserveShare;
        uint256 partnerShare;
        address profitAddress;
    }
    mapping (uint256 => game) public games;


    constructor (CRUSHToken _crush, BitcrushStaking _stakingPool,  address _reserve, address _lottery) public {
        crush = _crush;
        stakingPool = _stakingPool;
        reserve = _reserve;
        lottery = _lottery;
    }

    function setLiveWallet (BitcrushLiveWallet _liveWallet) public {
        liveWallet = _liveWallet;
    }

    function addGame (uint256 _profit, bytes32 _identifier, uint256 _houseBankrollShare, uint256 _lotteryShare, uint256 _reserveShare, uint256 _partnerShare,  address  _profitAddress) public onlyOwner {
        games[gameIds].profit = _profit;
        games[gameIds].identifier = _identifier;
        games[gameIds].houseBankrollShare = _houseBankrollShare;
        games[gameIds].lotteryShare = _lotteryShare;
        games[gameIds].reserveShare = _reserveShare;
        games[gameIds].profitAddress = _profitAddress;
        games[gameIds].partnerShare = _partnerShare;
        gameIds = gameIds.add(1);
    }

    function addToBankroll (uint256 _amount) public onlyOwner {
        crush.transferFrom(msg.sender, address(this), _amount);
        totalBankroll = totalBankroll.add(_amount);
    }

    function addUserLoss (uint256 _amount,  uint256 _gameId) public {
        require(msg.sender == address(liveWallet),"Caller must be bitcrush live wallet");
        //make game specific
        //check if bankroll is in negative 
        //uint is unsigned, keep a bool to track
        //if negative send to staking to replenish
        //otherwise add to bankroll and check for profit
        if (poolDepleted == true) {
            if(_amount >= negativeBankroll){
                uint256 remainder = _amount.sub(negativeBankroll);
                crush.transferFrom(msg.sender, address(stakingPool), negativeBankroll);
                stakingPool.unfreezeStaking(negativeBankroll);
                negativeBankroll = 0;
                poolDepleted = false;
                crush.transferFrom(msg.sender, address(this), remainder);
                totalBankroll = totalBankroll.add(remainder);
            }else {
                crush.transferFrom(msg.sender, address(stakingPool), _amount);
                stakingPool.unfreezeStaking(_amount);
                negativeBankroll = negativeBankroll.sub(_amount);
            }
        }else {
            crush.transferFrom(msg.sender, address(this), _amount);
            totalBankroll = totalBankroll.add(_amount);

        }
        checkForRewardPayOut(_gameId);
        

    }

    function payOutUserWinning (uint256 _amount, address _winner, uint256 _gameId) public {
        require(msg.sender == address(liveWallet),"Caller must be bitcrush live wallet");
        //check if bankroll has funds available
        //if not dip into staking pool for any remainder
        // update bankroll accordingly
        if(_amount > totalBankroll){
            
            uint256 remainder = _amount.sub(totalBankroll); 
            poolDepleted = true;
            stakingPool.freezeStaking(remainder, _winner, _gameId);
            negativeBankroll = negativeBankroll.add(remainder);
            transferWinnings(totalBankroll, _winner, _gameId);
            
            totalBankroll = 0;
        }else {
            totalBankroll = totalBankroll.sub(_amount);
            transferWinnings(_amount, _winner, _gameId);
            
        }
    }
    function transferWinnings (uint256 _amount, address _winner, uint256 _gameId) internal {
        crush.transfer(address(liveWallet), _amount);
        liveWallet.addToUserWinnings(_gameId,_amount, _winner);
    }

    function checkForRewardPayOut (uint256 _gameId) internal {
        if(totalBankroll > allTimeHigh) {
            //payout winning
            //todo add checks for 0 percent share
            //handle calculation
            //calculate share
            //update all time high
            allTimeHigh = totalBankroll;
            uint256 difference = totalBankroll.sub(allTimeHigh);
            totalBankroll = totalBankroll.sub(difference);
            if(games[_gameId].profit > 0 ){
                uint256 stakingBakrollProfit = difference.mul(games[_gameId].profit).div(DIVISOR);
                availableProfit = availableProfit.add(stakingBakrollProfit);
            }
            
            if(games[_gameId].reserveShare > 0 ){
                uint256 reserveCrush = difference.mul(games[_gameId].reserveShare).div(DIVISOR);
                crush.transfer(reserve, reserveCrush);
            }
            
            if(games[_gameId].lotteryShare > 0){
                uint256 lotteryCrush = difference.mul(games[_gameId].lotteryShare).div(DIVISOR);
                crush.transfer(lottery, lotteryCrush);
            }
            
            if(games[_gameId].partnerShare > 0 ){
                uint256 partnerShareCrush = difference.mul(games[_gameId].partnerShare).div(DIVISOR);
                crush.transfer(games[_gameId].profitAddress, partnerShareCrush);
            }

            if(games[_gameId].houseBankrollShare > 0){
                uint256 houseBankrollShare = difference.mul(games[_gameId].houseBankrollShare).div(DIVISOR);
                //todo dont add again, optimize
                totalBankroll = totalBankroll.add(houseBankrollShare); 
            }
            
            

            
            
            uint256 burn = difference.mul(burnRate).div(DIVISOR);
            crush.burn(burn);
            
            
            
            

        }
    }

    function transferProfit () public returns (uint256){
        require(msg.sender == address(stakingPool), "Caller must be staking pool");
        if(availableProfit >= profitThreshold){
            crush.transfer(address(stakingPool), availableProfit);
            uint256 profit = availableProfit;
            availableProfit = 0;
            return profit;
        }else {
            return 0;
        }
        
    }

    function setProfitThreshold (uint256 _threshold) public onlyOwner {
        profitThreshold = _threshold;
    }



}