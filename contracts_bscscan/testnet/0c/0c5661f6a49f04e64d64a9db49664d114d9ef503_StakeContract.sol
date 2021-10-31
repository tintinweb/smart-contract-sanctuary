/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract ERC20 {
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
    function decimals() external view virtual returns (uint8);
    function totalSupply() external view virtual returns (uint256);
    function balanceOf(address _owner) external view virtual returns (uint256);
    function allowance(address _owner, address _spender) external view virtual returns (uint256);
    function transfer(address _to, uint256 _value) external virtual returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external virtual returns (bool);

    function approve(address _spender, uint256 _value) external virtual returns (bool);
}

contract StakeContract
{
    uint256 ONE_HUNDRED     = 100000000000000000000;
    uint256 ONE             = 1000000000000000000;
    //uint    POWERUPDECIMALS = 18;
    
    address public networkcoinaddress;
    ERC20 internal networkcointoken;
    string public networkcoinsymbol;
    bool public stakeRewardByAmount; //By amount or by share

    struct Player{
        address id;
    }

    struct ParticipantInfo {
        uint deposits;
        uint withdrawals;
        uint stakes;
        uint unstakes;
        uint claims;
    }

    struct Balance {
        uint256 total;
        uint256 accumulatedEarning;
        uint256 playerIndex;
    }

    struct StakedBalance {
        uint256 total;
        uint playerIndex;
    }

    struct StakeRecord {
        uint256 total;
        uint time;
    }

    struct StakeFee {
        uint256 amount;
        uint time;
        address player;
    }

    struct PowerUpDepositRecord {
        address powerToken;
        uint time;
    }

    struct PowerUpRecord {
        uint256 multiply;
        uint durationInSeconds;
    }

    event OnDeposit(address from, address token, address tokenreceiving, uint256 total);
    event OnWithdraw(address to, address token, address tokenreceiving, uint256 total);
    event OnClaimEarnings(address to, address token, address tokenreceiving, uint256 total);
    event OnStake(address from, address token, address tokenreceiving, uint256 total);
    event OnUnstake(address from, address token, address tokenreceiving, uint256 total);
    event OnPowerUp(address from, address token, address tokenreceiving, address powertoken);

    address public owner;
    address public feeTo;

    //Participant list info by UserAddress
    mapping(address => ParticipantInfo) public participants;

    //Deposited Power-up by UserAddress/Token/TokenReceive
    mapping(address => mapping(address => mapping(address => PowerUpDepositRecord[]))) depositedPowerup;

    //Power-up token record by Token Address
    mapping(address => PowerUpRecord) poweruptokenlist;

    //Stake Players of Token/TokenReceive
    mapping(address => mapping(address => Player[])) internal players;

    //Deposit Players of Token/TokenReceive
    mapping(address => mapping(address => Player[])) internal depositplayers;

    //Earnings per Seconds per Share or Amount for each TokenStake/TokenReceive
    mapping(address => mapping(address => uint256)) earningspersecondspershareoramount;

    //Fee percent on stake action
    mapping(address => mapping(address => uint256)) feepercentonstake;

    //Stake Fee Records of Token/TokenReceive
    mapping(address => mapping(address => StakeFee[])) feeonstakerecords;
    
    //Max and Min Deposit for each TokenStake/TokenReceive
    mapping(address => mapping(address => uint256)) maxDeposit;
    mapping(address => mapping(address => uint256)) minDeposit;

    //Max and Min Withdrawal for each TokenStake/TokenReceive
    mapping(address => mapping(address => uint256)) maxWithdraw;
    mapping(address => mapping(address => uint256)) minWithdraw;

    //Active Stake for each TokenStake/TokenReceive
    mapping(address => mapping(address => bool)) activeStake;

    //Total staked for all users
    mapping(address => mapping(address => uint256)) totalStaked;

    //Total deposited for all users
    mapping(address => mapping(address => uint256)) totalDeposited;

    //User lists (1st mapping user, 2nd mapping token, 3rd mapping receiving token)
    mapping(address => mapping(address => mapping(address => Balance))) balances;
    mapping(address => mapping(address => mapping(address => StakedBalance))) stakedbalances;
    mapping(address => mapping(address => mapping(address => StakeRecord[]))) stakerecords;

    constructor() {
        owner = msg.sender;
        feeTo = owner;
        networkcoinaddress = address(0x1110000000000000000100000000000000000111);
        networkcointoken = ERC20(networkcoinaddress);
        networkcoinsymbol = "ETH";
        stakeRewardByAmount = true;
    }

    function setup(ERC20 token, ERC20 tokenReceiving, uint256 maxDepositAllowed, uint256 minDepositAllowed, uint256 maxWithdrawAllowed, uint256 minWithdrawAllowed, uint256 earningsPerSecondsPerShareOrAmount, uint256 feePercentOnStake, string memory networkCoinSymbol) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        require(feePercentOnStake <= ONE_HUNDRED, "IP"); //STAKE: Invalid percent fee value
        
        maxDeposit[address(token)][address(tokenReceiving)] = maxDepositAllowed;
        minDeposit[address(token)][address(tokenReceiving)] = minDepositAllowed;

        maxWithdraw[address(token)][address(tokenReceiving)] = maxWithdrawAllowed;
        minWithdraw[address(token)][address(tokenReceiving)] = minWithdrawAllowed;

        earningspersecondspershareoramount[address(token)][address(tokenReceiving)] = earningsPerSecondsPerShareOrAmount;
        feepercentonstake[address(token)][address(tokenReceiving)] = feePercentOnStake;
        networkcoinsymbol = networkCoinSymbol;
        activeStake[address(token)][address(tokenReceiving)] = true;
    }

    function depositToken(ERC20 token, ERC20 tokenReceiving, uint256 amountInWei, bool enterStaked) external 
    {
        require(activeStake[address(token)][address(tokenReceiving)] == true, "IN"); //STAKE: Inactive stake

        address tokenAddress = address(token);
        address tokenReceivingAddress = address(tokenReceiving);

        //Approve (outside): allowed[msg.sender][spender] (sender = my account, spender = stake token address)
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amountInWei, "AL"); //STAKE: Check the token allowance. Use approve function.

        require(amountInWei <= maxDeposit[address(token)][address(tokenReceiving)], "DH"); //STAKE: Deposit value is too high.
        require(amountInWei >= minDeposit[address(token)][address(tokenReceiving)], "DL"); //STAKE: Deposit value is too low.

        token.transferFrom(msg.sender, address(this), amountInWei);

        uint256 currentTotal = balances[msg.sender][tokenAddress][tokenReceivingAddress].total;

        //Increase +1 participant deposit counter
        participants[msg.sender].deposits = safeAdd(participants[msg.sender].deposits, 1);

        //If is a new player for deposit, register
        if(balances[msg.sender][tokenAddress][tokenReceivingAddress].total == 0)
        {
            depositplayers[tokenAddress][tokenReceivingAddress].push(Player({
                id: msg.sender
            }));

            balances[msg.sender][tokenAddress][tokenReceivingAddress].playerIndex = depositplayers[tokenAddress][tokenReceivingAddress].length -1;
        }

        //Increase/register deposit balance
        balances[msg.sender][tokenAddress][tokenReceivingAddress].total = safeAdd(currentTotal, amountInWei);

        //Increase general deposit amount
        totalDeposited[tokenAddress][tokenReceivingAddress] = safeAdd(totalDeposited[tokenAddress][tokenReceivingAddress], amountInWei);

        emit OnDeposit(msg.sender, tokenAddress, tokenReceivingAddress, amountInWei);

        if(enterStaked == true)
        {
            stakeToken(token, tokenReceiving, amountInWei);
        }
    }

    function depositNetworkCoin(ERC20 tokenReceiving, bool enterStaked) external payable 
    {
        require(msg.value > 0, "DL"); //STAKE: Deposit value is too low.

        ERC20 token = networkcointoken;
        require(activeStake[address(token)][address(tokenReceiving)] == true, "IN"); //STAKE: Inactive stake

        require(msg.value <= maxDeposit[address(token)][address(tokenReceiving)], "DH"); //STAKE: Deposit value is too high.
        require(msg.value >= minDeposit[address(token)][address(tokenReceiving)], "DL"); //STAKE: Deposit value is too low.

        uint256 currentTotal = balances[msg.sender][address(token)][address(tokenReceiving)].total;

        //Increase +1 participant deposit counter
        participants[msg.sender].deposits = safeAdd(participants[msg.sender].deposits, 1);

        //If is a new player for deposit, register
        if(balances[msg.sender][address(token)][address(tokenReceiving)].total == 0)
        {
            depositplayers[address(token)][address(tokenReceiving)].push(Player({
                id: msg.sender
            }));

            balances[msg.sender][address(token)][address(tokenReceiving)].playerIndex = depositplayers[address(token)][address(tokenReceiving)].length -1;
        }

        //Increase/register deposit balance
        balances[msg.sender][address(token)][address(tokenReceiving)].total = safeAdd(currentTotal, msg.value);

        //Increase general deposit amount
        totalDeposited[address(token)][address(tokenReceiving)] = safeAdd(totalDeposited[address(token)][address(tokenReceiving)], msg.value);

        emit OnDeposit(msg.sender, address(token), address(tokenReceiving), msg.value);

        if(enterStaked == true)
        {
            stakeToken(token, tokenReceiving, msg.value);
        }
    }

    function depositPowerUpOnPair(ERC20 token, ERC20 tokenReceiving, ERC20 powerToken) external 
    {
        require(activeStake[address(token)][address(tokenReceiving)] == true, "IN"); //STAKE: Inactive stake

        //address receiver = address(this);
        //address powerTokenAddress = address(powerToken);

        //Approve (outside): allowed[msg.sender][spender] (sender = my account, spender = stake token address)
        //uint256 allowance = powerToken.allowance(msg.sender, address(this));

        require(powerToken.allowance(msg.sender, address(this)) >= ONE, "PA"); //STAKE: Check the Powerup Token allowance. Use approve function.

        require(totalStaked[address(token)][address(tokenReceiving)] > 0, "ZS"); //STAKE: You need to have some staked value to apply an improvement.

        powerToken.transferFrom(msg.sender, address(this), ONE);

        depositedPowerup[msg.sender][address(token)][address(tokenReceiving)].push(PowerUpDepositRecord({
            powerToken: address(powerToken),
            time: block.timestamp
        }));

        emit OnPowerUp(msg.sender, address(token), address(tokenReceiving), address(powerToken));
    }

    function getDepositBalance(ERC20 token, ERC20 tokenReceiving) public view returns(uint256 result) 
    {
        return getDepositBalanceForPlayer(msg.sender, token, tokenReceiving);
    }

    function getDepositBalanceForPlayer(address playerAddress, ERC20 token, ERC20 tokenReceiving) public view returns(uint256 result) 
    {
        return balances[playerAddress][address(token)][address(tokenReceiving)].total;
    }

    //Amount of deposit at all - for all users
    function getDepositTotalAmount(ERC20 token, ERC20 tokenReceiving) public view returns(uint256 result) 
    {
        return totalDeposited[address(token)][address(tokenReceiving)];
    }

    function getDepositAccumulatedEarnings(ERC20 token, ERC20 tokenReceiving) public view returns(uint256 result) 
    {
        //Value when unstake earning token is different from stake token
        return balances[msg.sender][address(token)][address(tokenReceiving)].accumulatedEarning;
    }
    
    function withdrawToken(ERC20 token, ERC20 tokenReceiving, uint256 amountInWei, bool doClaimEarnings) external {
        withdrawTokenForPlayer(msg.sender, token, tokenReceiving, amountInWei, doClaimEarnings);
    }

    function withdrawTokenForPlayer(address playerAddress, ERC20 token, ERC20 tokenReceiving, uint256 amountInWei, bool doClaimEarnings) internal {

        require(amountInWei <= maxWithdraw[address(token)][address(tokenReceiving)], "WH"); //STAKE: Withdraw value is too high.
        require(amountInWei >= minWithdraw[address(token)][address(tokenReceiving)], "WL"); //STAKE: Withdraw value is too low.
        require(getDepositBalanceForPlayer(playerAddress, token, tokenReceiving) >= amountInWei, "ZD"); //STAKE: There is not enough deposit balance to withdraw the requested amount

        uint sourceBalance;
        if(address(token) != networkcoinaddress)
        {
            //Balance in Token
            sourceBalance = token.balanceOf(address(this));
        }
        else
        {
            //Balance in Network Coin
            sourceBalance = address(this).balance;
        }

        require(sourceBalance >= amountInWei, "LW"); //STAKE: Too low reserve to withdraw the requested amount

        if(doClaimEarnings == true)
        {
            claimEarnings(token, tokenReceiving);
        }

        //Withdraw of deposit value
        if(address(token) != networkcoinaddress)
        {
            //Withdraw token
            token.transfer(playerAddress, amountInWei);
        }
        else
        {
            //Withdraw Network Coin
            payable(playerAddress).transfer(amountInWei);
        }

        uint256 currentTotal = balances[playerAddress][address(token)][address(tokenReceiving)].total;
        balances[playerAddress][address(token)][address(tokenReceiving)].total = safeSub(currentTotal, amountInWei);

        //Increase +1 participant withdraw counter
        participants[playerAddress].withdrawals = safeAdd(participants[playerAddress].withdrawals, 1);

        //Reduce general deposit amount
        totalDeposited[address(token)][address(tokenReceiving)] = safeSub(totalDeposited[address(token)][address(tokenReceiving)], amountInWei);

        //If has no more deposit balances for this token, remove player
        if(balances[playerAddress][address(token)][address(tokenReceiving)].total == 0)
        {
            uint playerIndex = balances[playerAddress][address(token)][address(tokenReceiving)].playerIndex;

            //Swap index to last
            uint playersCount = depositplayers[address(token)][address(tokenReceiving)].length;
            if(playersCount > 1)
            {
                depositplayers[address(token)][address(tokenReceiving)][playerIndex] = depositplayers[address(token)][address(tokenReceiving)][playersCount - 1];
            }

            //Delete dirty last
            if(playersCount > 0)
            {
                depositplayers[address(token)][address(tokenReceiving)].pop();
            }

            //Reindex players
            if(depositplayers[address(token)][address(tokenReceiving)].length > 0)
            {
                for(uint ix = 0; ix < depositplayers[address(token)][address(tokenReceiving)].length; ix++)
                {
                    balances[  depositplayers[address(token)][address(tokenReceiving)][ix].id  ][address(token)][address(tokenReceiving)].playerIndex = ix;
                }
            }
        }

        emit OnWithdraw(playerAddress, address(token), address(tokenReceiving), amountInWei);
    }

    function claimEarnings(ERC20 token, ERC20 tokenReceiving) public {
        uint256 accumulatedEarning = balances[msg.sender][address(token)][address(tokenReceiving)].accumulatedEarning;

        if(address(token) != address(tokenReceiving))
        {
            uint sourceReceivingBalance;

            if(address(tokenReceiving) != networkcoinaddress)
            {
                //Balance in Token
                sourceReceivingBalance = tokenReceiving.balanceOf(address(this));
            }
            else
            {
                //Balance in Network Coin
                sourceReceivingBalance = address(this).balance;
            }

            require(sourceReceivingBalance >= accumulatedEarning, "LE"); //STAKE: Too low reserve to send earning
        }

        //Check accumulated earning when receiving token is different from stake token
        if(address(token) != address(tokenReceiving))
        {
            if(accumulatedEarning > 0)
            {
                balances[msg.sender][address(token)][address(tokenReceiving)].accumulatedEarning = 0;

                //Withdraw bonus
                if(address(tokenReceiving) != networkcoinaddress)
                {
                    //Withdraw bonus token
                    tokenReceiving.transfer(msg.sender, accumulatedEarning);
                }
                else
                {
                    //Withdraw bonus network coin
                    payable(msg.sender).transfer(accumulatedEarning);
                }

                //Increase +1 participant claim counter
                participants[msg.sender].claims = safeAdd(participants[msg.sender].claims, 1);

                emit OnClaimEarnings(msg.sender, address(token), address(tokenReceiving), accumulatedEarning);
            }
        }
    }

    function stakeToken(ERC20 token, ERC20 tokenReceiving, uint256 amountInWei) public {
        
        require(activeStake[address(token)][address(tokenReceiving)] == true, "IN"); //STAKE: Inactive stake

        require(balances[msg.sender][address(token)][address(tokenReceiving)].total >= amountInWei, 'ZD'); //STAKE: There is not enough deposit balance to stake the requested amount

        uint256 currentTotalStaked = stakedbalances[msg.sender][address(token)][address(tokenReceiving)].total;
        uint256 currentTotal = balances[msg.sender][address(token)][address(tokenReceiving)].total;

        //If is a new player (no staked balance for this token), register him/her
        if(stakedbalances[msg.sender][address(token)][address(tokenReceiving)].total == 0)
        {
            players[address(token)][address(tokenReceiving)].push(Player({
                id: msg.sender
            }));

            stakedbalances[msg.sender][address(token)][address(tokenReceiving)].playerIndex = players[address(token)][address(tokenReceiving)].length -1;
        }

        //Pay admin fee on stake
        uint256 feePercent = feepercentonstake[address(token)][address(tokenReceiving)]; //Eg 10 (10000000000000000000)

        uint256 fee = 0;

        if(feePercent > 0)
        {
            require(feePercent <= ONE_HUNDRED, "IP"); //STAKE: Invalid percent fee value

            fee = safeDiv(safeMul(amountInWei, feePercent), ONE_HUNDRED);

            amountInWei = safeSub(amountInWei, fee);

            feeonstakerecords[address(token)][address(tokenReceiving)].push(StakeFee({
                player: msg.sender,
                time: block.timestamp,
                amount: fee
            }));

            if(address(token) != networkcoinaddress)
            {
                //Withdraw token
                token.transfer(feeTo, fee);
            }
            else
            {
                //Withdraw Network Coin
                payable(feeTo).transfer(fee);
            }
        }

        //Reduce from deposit balance amount and fee
        balances[msg.sender][address(token)][address(tokenReceiving)].total = safeSub(currentTotal, safeAdd(amountInWei, fee));
        
        //Reduce from general deposit amount and fee
        totalDeposited[address(token)][address(tokenReceiving)] = safeSub(totalDeposited[address(token)][address(tokenReceiving)], safeAdd(amountInWei, fee));
        
        //Increse staked balance with amount
        stakedbalances[msg.sender][address(token)][address(tokenReceiving)].total = safeAdd(currentTotalStaked, amountInWei);
        //stakedbalances[msg.sender][address(token)][address(tokenReceiving)].symbol = symbol;

        //Increase total staked for token with amount
        totalStaked[address(token)][address(tokenReceiving)] = safeAdd(totalStaked[address(token)][address(tokenReceiving)], amountInWei);

        //Register stake
        stakerecords[msg.sender][address(token)][address(tokenReceiving)].push(
            StakeRecord({
                total: amountInWei,
                //symbol: symbol,
                time: block.timestamp
            })
        );

        //Increase +1 participant stake counter
        participants[msg.sender].stakes = safeAdd(participants[msg.sender].stakes, 1);

        emit OnStake(msg.sender, address(token), address(tokenReceiving), amountInWei);
    }

    function getStakeBalance(ERC20 token, ERC20 tokenReceiving) external view returns(uint256 result) 
    {
        return stakedbalances[msg.sender][address(token)][address(tokenReceiving)].total;
    }

    function getStakeBonus(ERC20 token, ERC20 tokenReceiving) external view returns(uint256 result) 
    {
        uint256 totalBonus = 0;

        if(earningspersecondspershareoramount[address(token)][address(tokenReceiving)] > 0)
        {
            for (uint i = 0; i < getStakeCount(token, tokenReceiving); i++) 
            {
                uint256 itemBonus = getStakeBonusByIndex(token, tokenReceiving, i);
                totalBonus = safeAdd(totalBonus, itemBonus);
            }
        }

        return totalBonus;
    }

    function getStakeBonusByIndex(ERC20 token, ERC20 tokenReceiving, uint i) public view returns(uint256 result) 
    {
        uint256 itemBonus = 0;

        if(i >= 0)
        {
            StakeRecord[] memory stakeList = stakerecords[msg.sender][address(token)][address(tokenReceiving)];

            if(stakeList.length > i)
            {
                uint256 earningsPerSecond = earningspersecondspershareoramount[address(token)][address(tokenReceiving)];

                if(earningsPerSecond > 0)
                {
                    uint256 stakeSeconds = safeSub(block.timestamp, stakeList[i].time);
                    stakeSeconds = getPoweredUpSeconds(stakeSeconds, msg.sender, address(token), address(tokenReceiving));

                    if(stakeRewardByAmount == false)
                    {
                        //Pay per share participation
                        uint256 share = getStakeShareFromStakeRecord(stakeList[i], address(token), address(tokenReceiving));
                        itemBonus = safeMul(earningsPerSecond, stakeSeconds);
                        itemBonus = safeMul(itemBonus, share);
                        itemBonus = safeDiv(itemBonus, ONE_HUNDRED); //getStakeShareFromStakeRecord function uses 100% scale, transform to 1 using div ONE_HUNDRED
                    }
                    else
                    {
                        //Pay per staked amount
                        uint decimals = 18;
                        if(address(token) != networkcoinaddress)
                        {
                            decimals = getTokenDecimals(token);
                        }
                        
                        itemBonus = safeMul(earningsPerSecond, stakeSeconds);
                        itemBonus = safeMulFloat(itemBonus, stakeList[i].total, decimals);
                    }
                }
            }
        }

        return itemBonus;
    }

    function getStakeBonusForecast(ERC20 token, ERC20 tokenReceiving, uint256 stakeAmount, uint256 stakeSecondsForecast) external view returns(uint256 result) 
    {
        uint256 earningsPerSecond = earningspersecondspershareoramount[address(token)][address(tokenReceiving)];

        uint256 itemBonus = 0;

        if(earningsPerSecond > 0)
        {
            if(stakeRewardByAmount == false)
            {
                //Pay per share participation
                uint256 share = getStakeShareForecast(stakeAmount, address(token), address(tokenReceiving));
                itemBonus = safeMul(earningsPerSecond, stakeSecondsForecast);
                itemBonus = safeMul(itemBonus, share);
                itemBonus = safeDiv(itemBonus, ONE_HUNDRED); //getStakeShareForecast function uses 100% scale, transform to 1 using div ONE_HUNDRED
            }
            else
            {
                //Pay per staked amount
                uint decimals = 18;
                if(address(token) != networkcoinaddress)
                {
                    decimals = getTokenDecimals(token);
                }

                itemBonus = safeMul(earningsPerSecond, stakeSecondsForecast);
                itemBonus = safeMulFloat(itemBonus, stakeAmount, decimals);
            }
        }

        return itemBonus;
    }

    function getStakeCount(ERC20 token, ERC20 tokenReceiving) public view returns(uint256 result) 
    {
        return getStakeCountForPlayer(msg.sender, token, tokenReceiving);
    }

    function getStakeCountForPlayer(address player, ERC20 token, ERC20 tokenReceiving) public view returns(uint256 result) 
    {
        return stakerecords[player][address(token)][address(tokenReceiving)].length;
    }

    //Amount of stake at all - for all users
    function getStakeTotalAmount(ERC20 token, ERC20 tokenReceiving) external view returns(uint256 result) 
    {
        return totalStaked[address(token)][address(tokenReceiving)];
    }

    function getStakeRecord(ERC20 token, ERC20 tokenReceiving, uint stakeIndex) external view returns(StakeRecord memory result) 
    {
        return getStakeRecordForPlayer(msg.sender, token, tokenReceiving, stakeIndex);
    }

    function getStakeRecordForPlayer(address player, ERC20 token, ERC20 tokenReceiving, uint stakeIndex) public view returns(StakeRecord memory result) 
    {
        require(stakerecords[player][address(token)][address(tokenReceiving)].length > stakeIndex, 'IX'); //STAKE: Invalid stake index record
        return stakerecords[player][address(token)][address(tokenReceiving)][stakeIndex];
    }

    /*
    function getStakeShare(ERC20 token, ERC20 tokenReceiving, uint stakeIndex) public view returns(uint256 result) 
    {
        require(stakerecords[msg.sender][address(token)][address(tokenReceiving)].length > stakeIndex, 'IX'); //STAKE: Invalid stake index record
        uint share = getStakeShareFromStakeRecord(stakerecords[msg.sender][address(token)][address(tokenReceiving)][stakeIndex], address(token), address(tokenReceiving));
        return share;
    }
    */

    function getStakeShareFromStakeRecord(StakeRecord memory stakeItem, address tokenAddress, address tokenReceivingAddress) internal view returns(uint256 result)
    {
        uint256 share = 0;
        if(totalStaked[tokenAddress][tokenReceivingAddress] > 0)
        {
            uint256 sharePercentPart = safeMul(stakeItem.total, ONE_HUNDRED);
            share = safeDiv(sharePercentPart, totalStaked[tokenAddress][tokenReceivingAddress]);
        }

        return share;
    }

    function getStakeShareForecast(uint256 stakeAmount, address tokenAddress, address tokenReceivingAddress) public view returns(uint256 result)
    {
        uint256 totalStakedSimulationForToken = safeAdd(totalStaked[tokenAddress][tokenReceivingAddress], stakeAmount);

        uint256 share = 0;
        uint256 sharePercentPart = safeMul(stakeAmount, ONE_HUNDRED);
        share = safeDiv(sharePercentPart, totalStakedSimulationForToken);

        return share;
    }

    function unstakeToken(ERC20 token, ERC20 tokenReceiving, uint stakeIndex) external 
    {
        unstakeTokenForPlayer(msg.sender, token, tokenReceiving, stakeIndex);
    }

    function unstakeTokenForPlayer(address playerAddress, ERC20 token, ERC20 tokenReceiving, uint stakeIndex) internal 
    {
        require(stakerecords[playerAddress][address(token)][address(tokenReceiving)].length > stakeIndex, 'IX'); //STAKE: Invalid stake index record

        uint256 stakeItemTotal = stakerecords[playerAddress][address(token)][address(tokenReceiving)][stakeIndex].total;

        require(stakedbalances[playerAddress][address(token)][address(tokenReceiving)].total >= stakeItemTotal, 'IB'); //STAKE: Invalid stake balance

        uint256 currentTotal = balances[playerAddress][address(token)][address(tokenReceiving)].total;
        uint256 currentTotalStaked = stakedbalances[playerAddress][address(token)][address(tokenReceiving)].total;

        uint256 stakeBonus = 0;

        //if(getStakeCount(token, tokenReceiving) > stakeIndex)
        if(getStakeCountForPlayer(playerAddress, token, tokenReceiving) > stakeIndex) //UPDATED: To test
        {
            //stakeBonus = getStakeBonusByIndex(token, tokenReceiving, stakeIndex);
            stakeBonus = getStakeBonusByIndexForPlayer(playerAddress, token, tokenReceiving, stakeIndex); //UPDATED: To test
        }

        //Reduce stake balance
        stakedbalances[playerAddress][address(token)][address(tokenReceiving)].total = safeSub(currentTotalStaked, stakeItemTotal);

        //Increase deposit balance with STAKE + BONUS when stake and profit is the same, otherwise separate increase for STAKE and BONUS as accumulated Earning
        if(address(token) == address(tokenReceiving))
        {
            balances[playerAddress][address(token)][address(tokenReceiving)].total = safeAdd(currentTotal, safeAdd(stakeItemTotal, stakeBonus) );

            //Increase general deposit amount + BONUS
            totalDeposited[address(token)][address(tokenReceiving)] = safeAdd(totalDeposited[address(token)][address(tokenReceiving)], safeAdd(stakeItemTotal, stakeBonus) );
        }
        else
        {
            balances[playerAddress][address(token)][address(tokenReceiving)].total = safeAdd(currentTotal, stakeItemTotal );

            //Increase general deposit amount
            totalDeposited[address(token)][address(tokenReceiving)] = safeAdd(totalDeposited[address(token)][address(tokenReceiving)], stakeItemTotal );

            uint256 accumulatedEarning = balances[playerAddress][address(token)][address(tokenReceiving)].accumulatedEarning;
            if(stakeBonus > 0)
            {
                accumulatedEarning = safeAdd(accumulatedEarning, stakeBonus);
            }

            balances[playerAddress][address(token)][address(tokenReceiving)].accumulatedEarning = accumulatedEarning;
        }

        //Reduce total staked for token
        totalStaked[address(token)][address(tokenReceiving)] = safeSub(totalStaked[address(token)][address(tokenReceiving)], stakeItemTotal);

        //Remove stake record
        uint stakesCount = stakerecords[playerAddress][address(token)][address(tokenReceiving)].length;

        //Swap last to index
        if(stakesCount > 1)
        {
            stakerecords[playerAddress][address(token)][address(tokenReceiving)][stakeIndex] = stakerecords[playerAddress][address(token)][address(tokenReceiving)][stakesCount - 1];
        }

        //Delete dirty last
        if(stakesCount > 0)
        {
            stakerecords[playerAddress][address(token)][address(tokenReceiving)].pop();
        }

        //If has no more staked balances for this token, remove player
        if(stakedbalances[playerAddress][address(token)][address(tokenReceiving)].total == 0)
        {
            uint playerIndex = stakedbalances[playerAddress][address(token)][address(tokenReceiving)].playerIndex;

            //Swap index to last
            if(players[address(token)][address(tokenReceiving)].length > 1)
            {
                players[address(token)][address(tokenReceiving)][playerIndex] = players[address(token)][address(tokenReceiving)][   players[address(token)][address(tokenReceiving)].length - 1  ];
            }

            //Delete dirty last
            if(players[address(token)][address(tokenReceiving)].length > 0)
            {
                players[address(token)][address(tokenReceiving)].pop();
            }

            //Reindex players
            if(players[address(token)][address(tokenReceiving)].length > 0)
            {
                for(uint ix = 0; ix < players[address(token)][address(tokenReceiving)].length; ix++)
                {
                    stakedbalances[  players[address(token)][address(tokenReceiving)][ix].id  ][address(token)][address(tokenReceiving)].playerIndex = ix;
                }
            }
        }
        
        //Increase +1 participant unstake counter
        participants[playerAddress].unstakes = safeAdd(participants[playerAddress].unstakes, 1);

        //Remove any applied powerup
        clearDepositedPowerUpOfPair(msg.sender, address(token), address(tokenReceiving));

        emit OnUnstake(playerAddress, address(token), address(tokenReceiving), stakeItemTotal);
    }

    function getEarningsPerSecondPerShareOrAmountInWei(ERC20 token, ERC20 tokenReceiving) external view returns (uint256 result)
    {
        return earningspersecondspershareoramount[address(token)][address(tokenReceiving)];
    }

    function setEarningsPerSecondPerShareOrAmountInWei(ERC20 token, ERC20 tokenReceiving, uint256 value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        earningspersecondspershareoramount[address(token)][address(tokenReceiving)] = value;
        return true;
    }

    function getFeePercentOnStake(ERC20 token, ERC20 tokenReceiving) external view returns (uint256 result)
    {
        return feepercentonstake[address(token)][address(tokenReceiving)];
    }

    function setFeePercentOnStake(ERC20 token, ERC20 tokenReceiving, uint256 value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        require(value <= ONE_HUNDRED, "IP"); //STAKE: Invalid percent fee value
        feepercentonstake[address(token)][address(tokenReceiving)] = value;
        return true;
    }

    function getMaxDepositTokenInWei(ERC20 token, ERC20 tokenReceiving) external view returns (uint256 result)
    {
        return maxDeposit[address(token)][address(tokenReceiving)];
    }

    function setMaxDepositTokenInWei(ERC20 token, ERC20 tokenReceiving, uint256 value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        maxDeposit[address(token)][address(tokenReceiving)] = value;
        return true;
    }

    function getMinDepositTokenInWei(ERC20 token, ERC20 tokenReceiving) external view returns (uint256 result)
    {
        return minDeposit[address(token)][address(tokenReceiving)];
    }

    function setMinDepositTokenInWei(ERC20 token, ERC20 tokenReceiving, uint256 value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        minDeposit[address(token)][address(tokenReceiving)] = value;
        return true;
    }

    function getMaxWithdrawTokenInWei(ERC20 token, ERC20 tokenReceiving) external view returns (uint256 result)
    {
        return maxWithdraw[address(token)][address(tokenReceiving)];
    }

    function setMaxWithdrawTokenInWei(ERC20 token, ERC20 tokenReceiving, uint256 value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        maxWithdraw[address(token)][address(tokenReceiving)] = value;
        return true;
    }

    function getMinWithdrawTokenInWei(ERC20 token, ERC20 tokenReceiving) external view returns (uint256 result)
    {
        return minWithdraw[address(token)][address(tokenReceiving)];
    }

    function setMinWithdrawTokenInWei(ERC20 token, ERC20 tokenReceiving, uint256 value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        minWithdraw[address(token)][address(tokenReceiving)] = value;
        return true;
    }

    function getDepositAccumulatedEarningsForPlayer(address playerAddress, ERC20 token, ERC20 tokenReceiving) external view returns(uint256 result) 
    {
        //Value when unstake earning token is different from stake token
        require(msg.sender == owner, 'FN'); //Forbidden
        return balances[playerAddress][address(token)][address(tokenReceiving)].accumulatedEarning;
    }

    function getStakeBalanceForPlayer(address playerAddress, ERC20 token, ERC20 tokenReceiving) external view returns(uint256 result) 
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        return stakedbalances[playerAddress][address(token)][address(tokenReceiving)].total;
    }

    function getStakeBonusByIndexForPlayer(address playerAddress, ERC20 token, ERC20 tokenReceiving, uint i) public view returns(uint256 result) 
    {
        uint256 itemBonus = 0;

        if(i >= 0)
        {
            if(stakerecords[playerAddress][address(token)][address(tokenReceiving)].length > i)
            {
                uint256 earningsPerSecond = earningspersecondspershareoramount[address(token)][address(tokenReceiving)];

                if(earningsPerSecond > 0)
                {
                    uint256 stakeSeconds = safeSub(block.timestamp, stakerecords[playerAddress][address(token)][address(tokenReceiving)][i].time);
                    stakeSeconds = getPoweredUpSeconds(stakeSeconds, playerAddress, address(token), address(tokenReceiving));

                    if(stakeRewardByAmount == false)
                    {
                        //Pay per share participation
                        uint256 share = getStakeShareFromStakeRecord(stakerecords[playerAddress][address(token)][address(tokenReceiving)][i], address(token), address(tokenReceiving));
                        itemBonus = safeMul(earningsPerSecond, stakeSeconds);
                        itemBonus = safeMul(itemBonus, share);
                        itemBonus = safeDiv(itemBonus, ONE_HUNDRED); //getStakeShareFromStakeRecord function uses 100% scale, transform to 1 using div ONE_HUNDRED
                    }
                    else
                    {
                        //Pay per staked amount
                        uint decimals = 18;
                        if(address(token) != networkcoinaddress)
                        {
                            decimals = getTokenDecimals(token);
                        }

                        itemBonus = safeMul(earningsPerSecond, stakeSeconds);
                        itemBonus = safeMulFloat(itemBonus, stakerecords[playerAddress][address(token)][address(tokenReceiving)][i].total, decimals);
                    }
                }
            }
        }

        return itemBonus;
    }

    function clearDepositBalanceForPlayer(address playerAddress, ERC20 token, ERC20 tokenReceiving) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        //Reduce general deposit amount
        totalDeposited[address(token)][address(tokenReceiving)] = safeSub(totalDeposited[address(token)][address(tokenReceiving)], balances[playerAddress][address(token)][address(tokenReceiving)].total);

        //Set user balance to Zero
        balances[playerAddress][address(token)][address(tokenReceiving)].total = 0;

        //Remove player
        //Swap index to last
        uint playersCount = depositplayers[address(token)][address(tokenReceiving)].length;
        if(playersCount > 1)
        {
            depositplayers[address(token)][address(tokenReceiving)][  balances[playerAddress][address(token)][address(tokenReceiving)].playerIndex  ] = depositplayers[address(token)][address(tokenReceiving)][playersCount - 1];
        }

        //Delete dirty last
        if(playersCount > 0)
        {
            depositplayers[address(token)][address(tokenReceiving)].pop();
        }
        
        //Reindex players
        if(depositplayers[address(token)][address(tokenReceiving)].length > 0)
        {
            for(uint ix = 0; ix < depositplayers[address(token)][address(tokenReceiving)].length; ix++)
            {
                balances[  depositplayers[address(token)][address(tokenReceiving)][ix].id  ][address(token)][address(tokenReceiving)].playerIndex = ix;
            }
        }
    }

    function clearStakeBalanceForPlayer(address playerAddress, ERC20 token, ERC20 tokenReceiving) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        //Set Stake Balance to Zero
        stakedbalances[playerAddress][address(token)][address(tokenReceiving)].total = 0;

        //Reduce total staked for token
        totalStaked[address(token)][address(tokenReceiving)] = safeSub(totalStaked[address(token)][address(tokenReceiving)], stakedbalances[playerAddress][address(token)][address(tokenReceiving)].total);

        //Clear stake records of user
        if(stakerecords[playerAddress][address(token)][address(tokenReceiving)].length > 0)
        {
            delete stakerecords[playerAddress][address(token)][address(tokenReceiving)];
        }

        //Remove player
        //Swap index to last
        if(players[address(token)][address(tokenReceiving)].length > 1)
        {
            players[address(token)][address(tokenReceiving)][   stakedbalances[playerAddress][address(token)][address(tokenReceiving)].playerIndex   ] = players[address(token)][address(tokenReceiving)][   players[address(token)][address(tokenReceiving)].length  - 1];
        }

        //Delete dirty last
        if(players[address(token)][address(tokenReceiving)].length > 0)
        {
            players[address(token)][address(tokenReceiving)].pop();
        }

        //Reindex players
        if(players[address(token)][address(tokenReceiving)].length > 0)
        {
            for(uint ix = 0; ix < players[address(token)][address(tokenReceiving)].length; ix++)
            {
                stakedbalances[  players[address(token)][address(tokenReceiving)][ix].id  ][address(token)][address(tokenReceiving)].playerIndex = ix;
            }
        }
    }

    function forcePlayerToUnstake(address playerAddress, ERC20 token, ERC20 tokenReceiving, uint stakeIndex) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        unstakeTokenForPlayer(playerAddress, token, tokenReceiving, stakeIndex);
    }

    function forceAllToUnstake(ERC20 token, ERC20 tokenReceiving) public
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        for(uint ix = 0; ix < players[address(token)][address(tokenReceiving)].length; ix++)
        {
            address currentPlayerInStake = players[address(token)][address(tokenReceiving)][ix].id;

            for(uint ixSt = 0; ixSt < stakerecords[currentPlayerInStake][address(token)][address(tokenReceiving)].length; ixSt++)
            {
                uint indexToUnstake = 0; //After unstake next item always remains at zero position
                unstakeTokenForPlayer(currentPlayerInStake, token, tokenReceiving, indexToUnstake);
            }
        }
    }

    function forcePlayerToClaimAndWithdraw(address playerAddress, ERC20 token, ERC20 tokenReceiving) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        if(balances[playerAddress][address(token)][address(tokenReceiving)].total > 0)
        {
            withdrawTokenForPlayer(playerAddress, token, tokenReceiving, balances[playerAddress][address(token)][address(tokenReceiving)].total, true);                
        }
    }

    function forceAllToClaimAndWithdraw(ERC20 token, ERC20 tokenReceiving) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        for(uint ix = 0; ix < depositplayers[address(token)][address(tokenReceiving)].length; ix++)
        {
            uint256 amountInDeposit = balances[   depositplayers[address(token)][address(tokenReceiving)][ix].id   ][address(token)][address(tokenReceiving)].total;
                                                   
            if(amountInDeposit > 0)
            {
                withdrawTokenForPlayer(depositplayers[address(token)][address(tokenReceiving)][ix].id, token, tokenReceiving, amountInDeposit, true);
            }
        }
    }

    function transferFund(ERC20 token, address to, uint256 amountInWei) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        //Withdraw of deposit value
        if(address(token) != networkcoinaddress)
        {
            //Withdraw token
            token.transfer(to, amountInWei);
        }
        else
        {
            //Withdraw Network Coin
            payable(to).transfer(amountInWei);
        }
    }

    function supplyNetworkCoin() payable external {
        require(msg.sender == owner, 'FN'); //Forbidden
        // nothing else to do!
    }

    function setActiveStake(ERC20 token, ERC20 tokenReceiving, bool value) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        activeStake[address(token)][address(tokenReceiving)] = value;
        if(value == false)
        {
            forceAllToUnstake(token, tokenReceiving);
        }
    }

    function getActiveStake(ERC20 token, ERC20 tokenReceiving) external view returns (bool result)
    {
        return activeStake[address(token)][address(tokenReceiving)];
    }

    function getStakeFeeCount(ERC20 token, ERC20 tokenReceiving) external view returns (uint256 result)
    {
        return feeonstakerecords[address(token)][address(tokenReceiving)].length;
    }

    /*
    function getStakeFeeByIndex(ERC20 token, ERC20 tokenReceiving, uint256 index) external view returns (StakeFee memory result)
    {
        return feeonstakerecords[address(token)][address(tokenReceiving)][index];
    }
    */

    function getStakePlayersCount(ERC20 token, ERC20 tokenReceiving) external view returns (uint256 result)
    {
        return players[address(token)][address(tokenReceiving)].length;
    }

    /*
    function getStakePlayersByIndex(ERC20 token, ERC20 tokenReceiving, uint256 index) external view returns (address result)
    {
        require(players[address(token)][address(tokenReceiving)].length > index, 'PX'); //STAKE: Index out of bounds
        return players[address(token)][address(tokenReceiving)][index].id;
    }
    */

    function getApprovedAllowance(ERC20 token) external view returns (uint256 result)
    {
        require(address(token) != networkcoinaddress, 'NA'); //STAKE: Network Coin could not be used with allowance.
        return token.allowance(msg.sender, address(this));
    }

    /*
    function getUserTokenBalance(ERC20 token) public view returns(uint256 result)
    {
        uint256 value;
        if(address(token) != networkcoinaddress)
        {
            value = token.balanceOf(msg.sender);
        }
        else
        {
            value = msg.sender.balance;
        }
        
        return value;
    }
    */

    /*
    function getTokenBalanceOf(ERC20 token) public view returns(uint256 result)
    {
        uint256 value;
        if(address(token) != networkcoinaddress)
        {
            value = token.balanceOf(address(this));
        }
        else
        {
            value = address(this).balance;
        }
        
        return value;
    }
    */

    function getTokenDecimals(ERC20 token) internal view returns(uint8 result)
    {
        uint8 defaultDecimals = 18;

        try token.decimals() returns (uint8 v) 
        {
            return (v);
        } 
        catch (bytes memory /*lowLevelData*/) 
        {
            return (defaultDecimals);
        }
    }

    /*
    function getMe() public view returns(address result)
    {
        return msg.sender;
    }
    */

    function setOwner(address newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        owner = newValue;
        return true;
    }

    function setFeeTo(address newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        feeTo = newValue;
        return true;
    }

    function setNetworkCoinAddress(address newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        networkcoinaddress = newValue;
        return true;
    }

    function setNetworkCoinSymbol(string memory newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        networkcoinsymbol = newValue;
        return true;
    }

    function setStakeRewardByAmount(bool newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        stakeRewardByAmount = newValue;
        return true;
    }

    function setPowerUpToken(address powerToken, uint256 multiply, uint durationInSeconds) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        poweruptokenlist[powerToken].multiply = multiply;
        poweruptokenlist[powerToken].durationInSeconds = durationInSeconds;

        return true;
    }

    function getPowerUpTokenMultiply(address powerToken) external view returns (uint256 value)
    {
        return poweruptokenlist[powerToken].multiply;
    }

    function getPowerUpTokenDuration(address powerToken) external view returns (uint value)
    {
        return poweruptokenlist[powerToken].durationInSeconds;
    }

    function getDepositedPowerUpCountForPair(address playerAddress, address tokenAddress, address tokenReceivingAddress) external view returns (uint256 value)
    {
        return depositedPowerup[playerAddress][tokenAddress][tokenReceivingAddress].length;
    }

    function getDepositedPowerUpToken(address playerAddress, address tokenAddress, address tokenReceivingAddress, uint256 ix) external view returns (address value)
    {
        return depositedPowerup[playerAddress][tokenAddress][tokenReceivingAddress][ix].powerToken;
    }

    function getDepositedPowerUpTime(address playerAddress, address tokenAddress, address tokenReceivingAddress, uint256 ix) external view returns (uint value)
    {
        return depositedPowerup[playerAddress][tokenAddress][tokenReceivingAddress][ix].time;
    }

    function getDepositedPowerUpTimeLeftToFinish(address playerAddress, address tokenAddress, address tokenReceivingAddress, uint256 ix) external view returns (uint value)
    {
        uint duration = poweruptokenlist[ depositedPowerup[playerAddress][tokenAddress][tokenReceivingAddress][ix].powerToken ].durationInSeconds;
        uint timeOut = safeAdd(depositedPowerup[playerAddress][tokenAddress][tokenReceivingAddress][ix].time, duration);
        uint result = 0;
        
        if(timeOut >= block.timestamp)
        {
            result = safeSub(timeOut, block.timestamp);
        }

        return result;
    }

    function clearDepositedPowerUpOfPair(address playerAddress, address tokenAddress, address tokenReceivingAddress) internal returns(bool result)
    {
        delete depositedPowerup[playerAddress][tokenAddress][tokenReceivingAddress];
        return true;
    }

    function getPoweredUpSeconds(uint stakeSeconds, address playerAddress, address tokenAddress, address tokenReceivingAddress) internal view returns (uint result)
    {
        uint newTime;
        uint fullBonusTime = 0;
        uint powerUpUsedTime = 0;
        
        for(uint ix = 0; ix < depositedPowerup[playerAddress][tokenAddress][tokenReceivingAddress].length; ix++)
        {
            address powerToken = depositedPowerup[playerAddress][tokenAddress][tokenReceivingAddress][ix].powerToken;
            uint startedAt = depositedPowerup[playerAddress][tokenAddress][tokenReceivingAddress][ix].time;

            uint usedTime;

            if(block.timestamp > safeAdd(startedAt, poweruptokenlist[powerToken].durationInSeconds))
            {
                usedTime = poweruptokenlist[powerToken].durationInSeconds; //100% of power-up card was used
            }
            else
            {
                usedTime = safeSub(block.timestamp, startedAt); //Add partial used time of power-up card
            }

            //Regitering used time
            powerUpUsedTime = safeAdd(powerUpUsedTime, usedTime); 

            //Empowering used time and add to bonus time
            fullBonusTime = safeAdd(fullBonusTime, safeMul(usedTime, poweruptokenlist[powerToken].multiply));
        }

        if(fullBonusTime > 0)
        {
            if(stakeSeconds > powerUpUsedTime)
            {
                //Swap powerUp UsedTime with bonusTime
                newTime = safeSub(stakeSeconds, powerUpUsedTime);
                newTime = safeAdd(stakeSeconds, fullBonusTime);
            }
            else 
            {
                //The sum of used time in powerup is greather than stake time, add everything to current stake time
                newTime = safeAdd(stakeSeconds, fullBonusTime);
                
                //newTime = fullBonusTime;
                
            }
        }
        else
        {
            //No power-up bonus
            newTime = stakeSeconds;
        }

        return newTime;
    }

    /*
    function simulateEarnings(ERC20 token, uint256 earningsPerSecond, uint256 stakeSeconds, uint256 totalStakedInWei) public view returns (uint256 result)
    {
        uint decimals = 18;
        if(address(token) != networkcoinaddress)
        {
            decimals = token.decimals();
        }
        uint256 itemBonus = safeMul(earningsPerSecond, stakeSeconds);
        itemBonus = safeMulFloat(itemBonus, totalStakedInWei, decimals);
        return itemBonus;
    }

    function simulateEarningsByTS(ERC20 token, uint256 earningsPerSecond, uint256 totalStakedInWei, uint256 startTS) public view returns (uint256 result)
    {
        uint decimals = 18;
        if(address(token) != networkcoinaddress)
        {
            decimals = token.decimals();
        }

        uint256 stakeSeconds = getTSDiffFrom(startTS);

        uint256 itemBonus = safeMul(earningsPerSecond, stakeSeconds);
        itemBonus = safeMulFloat(itemBonus, totalStakedInWei, decimals);
        return itemBonus;
    }

    function getTSDiffFrom(uint256 startTS) public view returns (uint256 result)
    {
        uint256 stakeSeconds = safeSub(block.timestamp, startTS);
        return stakeSeconds;
    }
    */

    //Safe Math Functions
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, "OADD"); //STAKE: SafeMath: addition overflow

        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeSub(a, b, "OSUB"); //STAKE: subtraction overflow
    }

    function safeSub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) 
        {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "OMUL"); //STAKE: multiplication overflow

        return c;
    }

    function safeMulFloat(uint256 a, uint256 b, uint decimals) internal pure returns(uint256)
    {
        if (a == 0 || decimals == 0)  
        {
            return 0;
        }

        uint result = safeDiv(safeMul(a, b), safePow(10, uint256(decimals)));

        return result;
    }

    function safePow(uint256 n, uint256 e) internal pure returns(uint256)
    {

        if (e == 0) 
        {
            return 1;
        } 
        else if (e == 1) 
        {
            return n;
        } 
        else 
        {
            uint256 p = safePow(n,  safeDiv(e, 2));
            p = safeMul(p, p);

            if (safeMod(e, 2) == 1) 
            {
                p = safeMul(p, n);
            }

            return p;
        }
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeDiv(a, b, "ZDIV"); //STAKE: division by zero
    }

    function safeDiv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeMod(a, b, "ZMOD"); //STAKE: modulo by zero
    }

    function safeMod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}