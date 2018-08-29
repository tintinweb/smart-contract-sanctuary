// MUSystem is based of the mathematical algorithm created 
// by the Mavrodi brothers - Sergey and Vyacheslav. 
// The solidity code was written by the enthusiast and devoted MMM participant Andrew from Russia.
// According to these rules MMM worked in Russia in the nineties. 
// Today you help someone — Tomorrow you will be helped out!
// Mutual Uniting System (MUSystem) email: <span class="__cf_email__" data-cfemail="335e464746525f465d5a475a5d54404a4047565e73545e525a5f1d505c5e">[email&#160;protected]</span>
// http:// Musystem.online
// Hello from Russia with love! ;) Привет из России! ;)
// "MMM IS A FINANCIAL NUCLEAR WEAPON.
// They say Baba Vanga predicted, “Pyramid from Russia will travel the world.”
// When Sergey Mavrodi passed away, many people thought this prediction 
// wasn&#39;t going to come true. What if it&#39;s just started to materialize?"

// Financial apocalypse is inevitable! Together we can do a lot!
// Thank you Sergey Mavrodi. You&#39;ve opened my eyes.

pragma solidity ^0.4.21;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract MUSystem {
    
    using SafeMath for uint;
    
    string public constant name = "Mutual Uniting System";
    string public constant symbol = "MUS";
    uint public constant decimals = 15;
    uint public totalSupply;
    address private creatorOwner;
    address private userAddr;
    mapping (address => uint) balances;
    struct UserWhoBuy {
        uint UserAmt;
        uint UserTokenObtain;
        uint UserBuyDate;
        uint UserBuyFirstDate;
        uint UserBuyTokenPackNum;
        uint UserFirstAmt;
        uint UserContinued;
        uint UserTotalAmtDepositCurrentPack;
    }
    mapping (address => UserWhoBuy) usersWhoBuy;
    address[] private userWhoBuyDatas;
    struct UserWhoSell {
        uint UserAmtWithdrawal;
        uint UserTokenSell;
        uint UserSellDate;
        uint UserSellTokenPackNum;
        uint UserTotalAmtWithdrawal;
        uint UserTotalAmtWithdrawalCurrentPack;
    }
    mapping (address => UserWhoSell) usersWhoSell;
    address[] private userWhoSellDatas;

// The basic parameters of MUSystem that determine 
// the participant&#39;s income per package, 
// the initial price of one token, 
// the number of tokens in pack, Disparity mode percentage
// and another internal constants.

    uint private CoMargin = 101; 
    uint private CoOverlap = 110; 
    uint private Disparity = 70; 
    bool private DisparityMode;
    uint private RestartModeDate;
    bool private RestartMode;
    uint private PackVolume = 50;  
    uint private FirstPackTokenPriceSellout = 50;    
    uint private BigAmt = 250 * 1 ether; 
    bool private feeTransfered;
    uint private PrevPrevPackTokenPriceSellout;
    uint private PrevPackTokenPriceSellout;
    uint private PrevPackTokenPriceBuyout; 
    uint private PrevPackDelta; 
    uint private PrevPackCost;
    uint private PrevPackTotalAmt;
    uint private CurrentPackYield;
    uint private CurrentPackDelta;
    uint private CurrentPackCost;
    uint private CurrentPackTotalToPay;
    uint private CurrentPackTotalAmt;
    uint private CurrentPackRestAmt;
    uint private CurrentPackFee;
    uint private CurrentPackTotalToPayDisparity;
    uint private CurrentPackNumber; 
    uint private CurrentPackStartDate; 
    uint private CurrentPackTokenPriceSellout;  
    uint private CurrentPackTokenPriceBuyout;
    uint private CurrentPackTokenAvailablePercent;
    uint private NextPackTokenPriceBuyout; 
    uint private NextPackYield; 
    uint private NextPackDelta;
    uint private userContinued;
    uint private userAmt; 
    uint private userFirstAmt;
    uint private userTotalAmtDepositCurrentPack;
    uint private userBuyFirstDate;
    uint private userTotalAmtWithdrawal;
    uint private userTotalAmtWithdrawalCurrentPack;
    uint private UserTokensReturn;
    bool private returnTokenInCurrentPack;
    uint private withdrawAmtToCurrentPack;
    uint private withdrawAmtAboveCurrentPack;
    uint private UserTokensReturnToCurrentPack;
    uint private UserTokensReturnAboveCurrentPack;
    uint private bonus;
    uint private userAmtOverloadToSend;

// MUSystem is launched at the time of the contract deployment. 
// It all starts with the first package. 
// Settings are applied and the number of tokens is released.

    constructor () public payable {
        creatorOwner = msg.sender;
        PackVolume = (10 ** decimals).mul(PackVolume);
        DisparityMode = false;
        RestartMode = false;
        CurrentPackNumber = 1; 
        CurrentPackStartDate = now;
        mint(PackVolume);
        packSettings(CurrentPackNumber);
    }

// Write down participants who make deposits.

    function addUserWhoBuy (
    address _address, 
    uint _UserAmt, 
    uint _UserTokenObtain, 
    uint _UserBuyDate,
    uint _UserBuyFirstDate,
    uint _UserBuyTokenPackNum,
    uint _UserFirstAmt,
    uint _UserContinued,
    uint _UserTotalAmtDepositCurrentPack) internal {
        UserWhoBuy storage userWhoBuy = usersWhoBuy[_address];
        userWhoBuy.UserAmt = _UserAmt;
        userWhoBuy.UserTokenObtain = _UserTokenObtain;
        userWhoBuy.UserBuyDate = _UserBuyDate;
        userWhoBuy.UserBuyFirstDate = _UserBuyFirstDate;
        userWhoBuy.UserBuyTokenPackNum = _UserBuyTokenPackNum;
        userWhoBuy.UserFirstAmt = _UserFirstAmt;
        userWhoBuy.UserContinued = _UserContinued;
        userWhoBuy.UserTotalAmtDepositCurrentPack = _UserTotalAmtDepositCurrentPack;
        userWhoBuyDatas.push(_address) -1;
    }
// Write down also participants who make withdrawals.

    function addUserWhoSell (
    address _address, 
    uint _UserAmtWithdrawal, 
    uint _UserTokenSell, 
    uint _UserSellDate,
    uint _UserSellTokenPackNum,
    uint _UserTotalAmtWithdrawal,
    uint _UserTotalAmtWithdrawalCurrentPack) internal {
        UserWhoSell storage userWhoSell = usersWhoSell[_address];
        userWhoSell.UserAmtWithdrawal = _UserAmtWithdrawal;
        userWhoSell.UserTokenSell = _UserTokenSell;
        userWhoSell.UserSellDate = _UserSellDate;
        userWhoSell.UserSellTokenPackNum = _UserSellTokenPackNum;
        userWhoSell.UserTotalAmtWithdrawal = _UserTotalAmtWithdrawal; 
        userWhoSell.UserTotalAmtWithdrawalCurrentPack = _UserTotalAmtWithdrawalCurrentPack;
        userWhoSellDatas.push(_address) -1;
    }

// Calculation of pack&#39;s parameters "on the fly". 
// Course (price) of tokens is growing by a special technique, 
// which designed increases with the passage of time the size 
// of a possible return donations for the participants, 
// subject to a maximum system stability.

    function packSettings (uint _currentPackNumber) internal {
        CurrentPackNumber = _currentPackNumber;
        if(CurrentPackNumber == 1){
            PrevPackDelta = 0;
            PrevPackCost = 0;
            PrevPackTotalAmt = 0;
            CurrentPackStartDate = now;
            CurrentPackTokenPriceSellout = FirstPackTokenPriceSellout;
            CurrentPackTokenPriceBuyout = FirstPackTokenPriceSellout; 
            CurrentPackCost = PackVolume.mul(CurrentPackTokenPriceSellout);
            CurrentPackTotalToPay = 0;
            CurrentPackTotalToPayDisparity = 0;
            CurrentPackYield = 0;
            CurrentPackDelta = 0;
            CurrentPackTotalAmt = CurrentPackCost;
            CurrentPackFee = 0;
            CurrentPackRestAmt = CurrentPackCost.sub(CurrentPackTotalToPay);
            if (FirstPackTokenPriceSellout == 50){NextPackTokenPriceBuyout = 60;}else{NextPackTokenPriceBuyout = FirstPackTokenPriceSellout+5;}
        }
        if(CurrentPackNumber == 2){
            PrevPrevPackTokenPriceSellout = 0;
            PrevPackTokenPriceSellout = CurrentPackTokenPriceSellout;
            PrevPackTokenPriceBuyout = CurrentPackTokenPriceBuyout;
            PrevPackDelta = CurrentPackDelta;
            PrevPackCost = CurrentPackCost;
            PrevPackTotalAmt = CurrentPackTotalAmt;
            CurrentPackYield = 0;
            CurrentPackDelta = 0;
            NextPackTokenPriceBuyout = PrevPackTokenPriceSellout.mul(CoOverlap).div(100);
            NextPackYield = NextPackTokenPriceBuyout.sub(PrevPackTokenPriceSellout);
            NextPackDelta = NextPackYield;
            CurrentPackTokenPriceSellout = NextPackTokenPriceBuyout.add(NextPackDelta);
            CurrentPackTokenPriceBuyout = CurrentPackTokenPriceSellout;
            CurrentPackCost = PackVolume.mul(CurrentPackTokenPriceSellout);
            CurrentPackTotalToPay = 0;
            CurrentPackTotalAmt = CurrentPackCost.add(PrevPackTotalAmt);
            CurrentPackFee = 0;
            CurrentPackTotalToPayDisparity = PrevPackCost.mul(Disparity).div(100);
            CurrentPackRestAmt = CurrentPackCost.sub(CurrentPackTotalToPay);
        }
        if(CurrentPackNumber > 2){
            PrevPackTokenPriceSellout = CurrentPackTokenPriceSellout;
            PrevPackTokenPriceBuyout = CurrentPackTokenPriceBuyout;
            PrevPackDelta = CurrentPackDelta;
            PrevPackCost = CurrentPackCost;
            PrevPackTotalAmt = CurrentPackTotalAmt;
            CurrentPackYield = NextPackYield;
            CurrentPackDelta = NextPackDelta;
            CurrentPackTokenPriceBuyout = NextPackTokenPriceBuyout;
            NextPackTokenPriceBuyout = PrevPackTokenPriceSellout.mul(CoOverlap);
            if(NextPackTokenPriceBuyout<=100){  
                NextPackTokenPriceBuyout=PrevPackTokenPriceSellout.mul(CoOverlap).div(100);
            }
            if(NextPackTokenPriceBuyout>100){ 
                NextPackTokenPriceBuyout=NextPackTokenPriceBuyout*10**3;
                NextPackTokenPriceBuyout=((NextPackTokenPriceBuyout/10000)+5)/10;
            }
            NextPackYield = NextPackTokenPriceBuyout.sub(PrevPackTokenPriceSellout);
            NextPackDelta = NextPackYield.mul(CoMargin);
            if(NextPackDelta <= 100){ 
                NextPackDelta = CurrentPackDelta.add(NextPackYield.mul(CoMargin).div(100));
            }
            if(NextPackDelta > 100){
                NextPackDelta = NextPackDelta*10**3;
                NextPackDelta = ((NextPackDelta/10000)+5)/10;
                NextPackDelta = CurrentPackDelta.add(NextPackDelta);
            }
            CurrentPackTokenPriceSellout = NextPackTokenPriceBuyout.add(NextPackDelta);
            CurrentPackCost = PackVolume.mul(CurrentPackTokenPriceSellout);
            CurrentPackTotalToPay = PackVolume.mul(CurrentPackTokenPriceBuyout);
            CurrentPackTotalToPayDisparity = PrevPackCost.mul(Disparity).div(100);
            CurrentPackRestAmt = CurrentPackCost.sub(CurrentPackTotalToPay);
            CurrentPackTotalAmt = CurrentPackRestAmt.add(PrevPackTotalAmt);
            CurrentPackFee = PrevPackTotalAmt.sub(CurrentPackTotalToPay).sub(CurrentPackTotalToPayDisparity);
        }
        CurrentPackTokenAvailablePercent = balances[address(this)].mul(100).div(PackVolume);
        emit NextPack(CurrentPackTokenPriceSellout, CurrentPackTokenPriceBuyout);
    }

// The data of the current package can be obtained 
// by performing this function.
// Available tokens - the remaining number of available 
// tokens in the current package. 
// At onetime you can not buy more than this number of tokens.
// Available tokens in percentage - the percentage of 
// remaining available tokens in the current package.
// Available amount to deposit in wei - the maximum amount 
// that can be deposited in the current package.
// Attempt to exceed this amount too much 
// (i.e., an attempt to buy more tokens than the Available tokens 
// in the current package) will be rejected. 
// In case of a small excess of the amount, the unused leftover 
// will return to your Ethereum account.
// Current pack token price sellout -  the price at which 
// tokens are bought by a participant.
// Current pack token price buyout - the price at which 
// tokens are sold by a participant (are bought by the system).

    function aboutCurrentPack () public constant returns (uint availableTokens, uint availableTokensInPercentage, uint availableAmountToDepositInWei, uint tokenPriceSellout, uint tokenPriceBuyout){
        uint _availableTokens = balances[address(this)];
        uint _availableAmountToDepositInWei = _availableTokens.mul(CurrentPackTokenPriceSellout);
        return (_availableTokens, CurrentPackTokenAvailablePercent, _availableAmountToDepositInWei, CurrentPackTokenPriceSellout, CurrentPackTokenPriceBuyout);
    }

// Move to the next package. Sending a reward to the owner. 
// Minting of new tokens.

    function nextPack (uint _currentPackNumber) internal { 
        transferFee();
        feeTransfered = false;
        CurrentPackNumber=_currentPackNumber.add(1);
        CurrentPackStartDate = now;
        mint(PackVolume);
        packSettings(CurrentPackNumber);
    }

// Restart occurs if the Disparity mode is enabled and 
// there were no new donations within 14 days. 
// Everything will start with the first package. 
// After restart, the system saves the participant&#39;s tokens. 
// Moreover, by participating from the very beginning 
// (starting from the first package of the new cycle), 
// the participant can easily compensate for his 
// insignificant losses. And quickly achieve a good profit!

    function restart(bool _dm)internal{
        if(_dm==true){if(RestartMode==false){RestartMode=true;RestartModeDate=now;}
            else{if(now>RestartModeDate+14*1 days){RestartMode=false;DisparityMode=false;nextPack(0);}}}
        else{if(RestartMode==true){RestartMode=false;RestartModeDate=0;}}
    }

// Sending reward to the owner. 
// No more and no less - just as much as it does not hurt. 
// Exactly as much as provided by the algorithm.

    function transferFee()internal{
        if(CurrentPackNumber > 2 && feeTransfered == false){
            if(address(this).balance>=CurrentPackFee){
                creatorOwner.transfer(CurrentPackFee);
                feeTransfered = true;
            }
        }
    }

// Receiving a donation and calculating the number of participant tokens. 
// Bonuses, penalties.

    function deposit() public payable returns (uint UserTokenObtain){ 
        require(msg.sender != 0x0 && msg.sender != 0);
        require(msg.value < BigAmt); 
        uint availableTokens = balances[address(this)];
        require(msg.value <= availableTokens.mul(CurrentPackTokenPriceSellout).add(availableTokens.mul(CurrentPackTokenPriceSellout).mul(10).div(100)).add(10*1 finney)); 
        require(msg.value.div(CurrentPackTokenPriceSellout) > 0);
        userAddr = msg.sender;
        userAmt = msg.value;
        if(usersWhoBuy[userAddr].UserBuyTokenPackNum == CurrentPackNumber){
            userTotalAmtDepositCurrentPack = usersWhoBuy[userAddr].UserTotalAmtDepositCurrentPack;
        }
        else{
            userTotalAmtDepositCurrentPack = 0;
        }
        if(usersWhoBuy[userAddr].UserBuyTokenPackNum == CurrentPackNumber){
            require(userTotalAmtDepositCurrentPack.add(userAmt) < BigAmt);
        }

// If the participant making a donation in the current package 
// has already received a backward donation in the same package, 
// the amount of the new donation is reduced by 5% of the amount
// of the received donation; a kind of "penalty" is imposed in 
// the amount of 5% of the amount received earlier 
// by the participant in the same package.

        if(usersWhoSell[userAddr].UserSellTokenPackNum == CurrentPackNumber){
            uint penalty = usersWhoSell[userAddr].UserTotalAmtWithdrawalCurrentPack.mul(5).div(100);
            userAmt = userAmt.sub(penalty);
            require(userAmt.div(CurrentPackTokenPriceSellout) > 0);
            penalty=0;
        }
        UserTokenObtain = userAmt.div(CurrentPackTokenPriceSellout);
        bonus = 0;

// Participants who made donation amounting to at least  0.1 ether:
// In the 1st day of the current package is entitled to receive 
// the amount of possible backward donation to 0.75% more than usual.
// In the 2nd day of the current package - 0.5% more than usual.
// In the 3rd day of the current package - 0.25% more than usual.

        if(userAmt >= 100*1 finney){
            if(now <= (CurrentPackStartDate + 1*1 days)){
                bonus = UserTokenObtain.mul(75).div(10000);
            }
            if(now > (CurrentPackStartDate + 1*1 days) && now <= (CurrentPackStartDate + 2*1 days)){
                bonus = UserTokenObtain.mul(50).div(10000);
            }
            if(now > (CurrentPackStartDate + 2*1 days) && now <= (CurrentPackStartDate + 3*1 days)){
                bonus = UserTokenObtain.mul(25).div(10000);
            }
        }

// For continuous long-time participation, 
// starting from the second week of participation 
// (starting from the 4th participation package), 
// bonus incentives for the continuous participation 
// of 1% of the contributed amount for each subsequent 
// "own" package are accrued for the participant.

        if(userContinued > 4 && now > (userBuyFirstDate + 1 * 1 weeks)){
            bonus = bonus.add(UserTokenObtain.mul(1).div(100));
        }
        UserTokenObtain = UserTokenObtain.add(bonus);  
        if(UserTokenObtain > availableTokens){
            userAmtOverloadToSend = CurrentPackTokenPriceSellout.mul(UserTokenObtain.sub(availableTokens)); 
            transfer(address(this), userAddr, availableTokens);
            UserTokenObtain = availableTokens;
            if(address(this).balance>=userAmtOverloadToSend){
                userAddr.transfer(userAmtOverloadToSend);
            }
        }                
        else{                 
            transfer(address(this), userAddr, UserTokenObtain);
        }
        if(usersWhoBuy[userAddr].UserBuyTokenPackNum == 0){
            userFirstAmt = userAmt;
            userBuyFirstDate = now;
        }
        else{
            userFirstAmt = usersWhoBuy[userAddr].UserFirstAmt;
            userBuyFirstDate = usersWhoBuy[userAddr].UserBuyFirstDate;
        }
        if(usersWhoBuy[userAddr].UserContinued == 0){
            userContinued = 1;
        }
        else{
            if(usersWhoBuy[userAddr].UserBuyTokenPackNum == CurrentPackNumber.sub(1)){
                userContinued = userContinued.add(1);
            }
            else{
                userContinued = 1;
            }
        }
        userTotalAmtDepositCurrentPack = userTotalAmtDepositCurrentPack.add(userAmt);
        addUserWhoBuy(userAddr, userAmt, UserTokenObtain, now, userBuyFirstDate, CurrentPackNumber, userFirstAmt, userContinued, userTotalAmtDepositCurrentPack);
        CurrentPackTokenAvailablePercent = balances[address(this)].mul(100).div(PackVolume);
        bonus = 0;
        availableTokens = 0;
        userAmtOverloadToSend = 0;
        userAddr = 0;
        userAmt = 0;
        restart(false);
        DisparityMode = false;

// Move to the next pack, if all the tokens of the current one are over.

        if(balances[address(this)] == 0){nextPack(CurrentPackNumber);}
        return UserTokenObtain;
    } 

// And here the participant decided to sell his tokens (some or all at once) and sends us his withdrawal request.

    function withdraw(uint WithdrawAmount, uint WithdrawTokens) public returns (uint withdrawAmt){
        require(msg.sender != 0x0 && msg.sender != 0);
        require(WithdrawTokens > 0 || WithdrawAmount > 0);
        require(WithdrawTokens<=balances[msg.sender]); 
        require(WithdrawAmount.mul(1 finney)<=balances[msg.sender].mul(CurrentPackTokenPriceSellout).add(balances[msg.sender].mul(CurrentPackTokenPriceSellout).mul(5).div(100)));

// If the normal work is braked then Disparity mode is turning on.
// If Disparity mode is already enabled, then we check whether it&#39;s time to restart.

        if(RestartMode==true){restart(true);}
        if(address(this).balance<=CurrentPackTotalToPayDisparity){
            DisparityMode=true;}else{DisparityMode=false;}

// The participant can apply at any time for the selling 
// his tokens at the buyout price of the last realized (current) package.
// Let calculate how much tokens are returned in the current package, 
// and how much was purchased earlier.

        userTotalAmtWithdrawal = usersWhoSell[msg.sender].UserTotalAmtWithdrawal;
        if(usersWhoSell[msg.sender].UserSellTokenPackNum == CurrentPackNumber){
            userTotalAmtWithdrawalCurrentPack = usersWhoSell[msg.sender].UserTotalAmtWithdrawalCurrentPack;
        }
        else{
            userTotalAmtWithdrawalCurrentPack = 0;
        }
        if(usersWhoBuy[msg.sender].UserBuyTokenPackNum == CurrentPackNumber && userTotalAmtWithdrawalCurrentPack < usersWhoBuy[msg.sender].UserTotalAmtDepositCurrentPack){
            returnTokenInCurrentPack = true;
            withdrawAmtToCurrentPack = usersWhoBuy[msg.sender].UserTotalAmtDepositCurrentPack.sub(userTotalAmtWithdrawalCurrentPack);
        }
        else{ 
            returnTokenInCurrentPack = false;
        }
        if(WithdrawAmount > 0){
            withdrawAmt = WithdrawAmount.mul(1 finney);
            if(returnTokenInCurrentPack == true){
                UserTokensReturnToCurrentPack = withdrawAmtToCurrentPack.div(CurrentPackTokenPriceSellout);
                if(withdrawAmt>withdrawAmtToCurrentPack){ 
                    withdrawAmtAboveCurrentPack = withdrawAmt.sub(withdrawAmtToCurrentPack);
                    UserTokensReturnAboveCurrentPack = withdrawAmtAboveCurrentPack.div(CurrentPackTokenPriceBuyout);
                } 
                else{
                    withdrawAmtToCurrentPack = withdrawAmt;
                    UserTokensReturnToCurrentPack = withdrawAmtToCurrentPack.div(CurrentPackTokenPriceSellout);
                    withdrawAmtAboveCurrentPack = 0;
                    UserTokensReturnAboveCurrentPack = 0;
                }
            }
            else{
                withdrawAmtToCurrentPack = 0;
                UserTokensReturnToCurrentPack = 0;
                withdrawAmtAboveCurrentPack = withdrawAmt;
                UserTokensReturnAboveCurrentPack = withdrawAmtAboveCurrentPack.div(CurrentPackTokenPriceBuyout);
            }
        }
        else{
            UserTokensReturn = WithdrawTokens;
            if(returnTokenInCurrentPack == true){
                UserTokensReturnToCurrentPack = withdrawAmtToCurrentPack.div(CurrentPackTokenPriceSellout);
                if(UserTokensReturn>UserTokensReturnToCurrentPack){
                    UserTokensReturnAboveCurrentPack = UserTokensReturn.sub(UserTokensReturnToCurrentPack);
                    withdrawAmtAboveCurrentPack = UserTokensReturnAboveCurrentPack.mul(CurrentPackTokenPriceBuyout);
                }
                else{
                    withdrawAmtToCurrentPack = UserTokensReturn.mul(CurrentPackTokenPriceSellout);
                    UserTokensReturnToCurrentPack = UserTokensReturn;
                    withdrawAmtAboveCurrentPack = 0;
                    UserTokensReturnAboveCurrentPack = 0;
                }
            }
            else{
                withdrawAmtToCurrentPack = 0;
                UserTokensReturnToCurrentPack = 0;
                UserTokensReturnAboveCurrentPack = UserTokensReturn;
                withdrawAmtAboveCurrentPack = UserTokensReturnAboveCurrentPack.mul(CurrentPackTokenPriceBuyout);
            }    
        }
        withdrawAmt = withdrawAmtToCurrentPack.add(withdrawAmtAboveCurrentPack);

// When applying for a donation, if the remaining number 
// of available tokens of the current package is less than 10%, 
// participants are entitled to withdraw of 1% more than usual.

        if(balances[address(this)]<=(PackVolume.mul(10).div(100))){
            withdrawAmtAboveCurrentPack = withdrawAmtAboveCurrentPack.add(withdrawAmt.mul(1).div(100));
        }

// With each withdrawal, the system checks the total balance 
// and if the system is on the verge, when it can pay to each participant 
// 70% of his initial donation, the protection mode called "Disparity mode" is activated.
// In disparity mode: participant who made a donation in the current package 
// can withdraw up to 100% of his initial donation amount,
// participant who made a donation earlier (in previous packs) 
// can withdraw up to 70% of his initial donation amount.

        if(address(this).balance<CurrentPackTotalToPayDisparity || withdrawAmt > address(this).balance || DisparityMode == true){
            uint disparityAmt = usersWhoBuy[msg.sender].UserFirstAmt.mul(Disparity).div(100);
            if(userTotalAmtWithdrawal >= disparityAmt){
                withdrawAmtAboveCurrentPack = 0;
                UserTokensReturnAboveCurrentPack = 0;
            }
            else{
                if(withdrawAmtAboveCurrentPack.add(userTotalAmtWithdrawal) >= disparityAmt){
                    withdrawAmtAboveCurrentPack = disparityAmt.sub(userTotalAmtWithdrawal);
                    UserTokensReturnAboveCurrentPack = withdrawAmtAboveCurrentPack.div(CurrentPackTokenPriceBuyout);
                }
            }
            DisparityMode = true;
            if(CurrentPackNumber>2){restart(true);}
        }
        if(withdrawAmt>address(this).balance){
            withdrawAmt = address(this).balance;
            withdrawAmtAboveCurrentPack = address(this).balance.sub(withdrawAmtToCurrentPack);
            UserTokensReturnAboveCurrentPack = withdrawAmtAboveCurrentPack.div(CurrentPackTokenPriceBuyout);
            if(CurrentPackNumber>2){restart(true);}
        }
        withdrawAmt = withdrawAmtToCurrentPack.add(withdrawAmtAboveCurrentPack);
        UserTokensReturn = UserTokensReturnToCurrentPack.add(UserTokensReturnAboveCurrentPack);
        require(UserTokensReturn<=balances[msg.sender]); 
        transfer(msg.sender, address(this), UserTokensReturn);
        msg.sender.transfer(withdrawAmt);
        userTotalAmtWithdrawal = userTotalAmtWithdrawal.add(withdrawAmt);
        userTotalAmtWithdrawalCurrentPack = userTotalAmtWithdrawalCurrentPack.add(withdrawAmt);
        addUserWhoSell(msg.sender, withdrawAmt, UserTokensReturn, now, CurrentPackNumber, userTotalAmtWithdrawal, userTotalAmtWithdrawalCurrentPack);
        CurrentPackTokenAvailablePercent = balances[address(this)].mul(100).div(PackVolume);
        withdrawAmtToCurrentPack = 0;
        withdrawAmtAboveCurrentPack = 0;
        UserTokensReturnToCurrentPack = 0;
        UserTokensReturnAboveCurrentPack = 0;
        return withdrawAmt;
    }

// If tokens purchased in the current package are returned, 
// they are again available for purchase by other participants.
// If tokens purchased in previous packages are returned, 
// then such tokens are no longer available to anyone.

    function transfer(address _from, address _to, uint _value) internal returns (bool success) {
        balances[_from] = balances[_from].sub(_value); 
        if(_to == address(this)){ 
            if(returnTokenInCurrentPack == true){
                balances[_to] = balances[_to].add(UserTokensReturnToCurrentPack);
            }
            else{
                balances[_to] = balances[_to];
            }
            totalSupply = totalSupply.sub(UserTokensReturnAboveCurrentPack);
        }
        else{
            balances[_to] = balances[_to].add(_value);
        }
        emit Transfer(_from, _to, _value); 
        return true;
    }  

// BalanceOf — get balance of tokens.

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

// Minting new tokens if the moving to a new package occurred.

    function mint(uint _value) internal returns (bool) {
        balances[address(this)] = balances[address(this)].add(_value);
        totalSupply = totalSupply.add(_value);
        return true;
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event NextPack(uint indexed CurrentPackTokenPriceSellout, uint indexed CurrentPackTokenPriceBuyout);
}