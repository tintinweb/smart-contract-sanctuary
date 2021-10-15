// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ReentrancyGuard.sol";


interface CreamYield {
    
    function mint(uint mintAmount) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getCash() external view returns (uint);
}


contract Jackpot is ERC20, ReentrancyGuard {

    address public constant EMPTY_ADDRESS = address(0);
    
    uint public LOCK_PLAYERS;
    uint public LOCK_LOTTERY;
    uint public immutable TICKET_PRICE;

    CreamYield public marketcream;
    ERC20 public underlying;

    uint public reservevalue;
    uint public totalreservepaid;
    
    uint public totalplayers;
    
    uint public lockdeposits;
    uint public jackpotvalue;
    
    uint private nonce;
    uint private blockNumber;
    
    bool public spinning;
    bool public picking;

    uint public jackpotsettled;
    uint public timejackpot;
    
    uint public jackpotspaid;
    uint public lastjackpotresult;
    address public lastjackpotwinner;
    uint public lastjackpotamount;
    uint public lastjackpotdate;
    
    uint public lastjackpotcounter;
    
    address public owner;
    address public burner;

    uint public lotterycounter;
    
    struct Lottery {
        uint lotteryid;
        uint lotterydate;
        uint lotteryresult;
        address lotterywinner;
        uint lotteryamount;
    }    
    
    Lottery[] public LotteryResults;

    struct Player {
        address addressplayer;
        uint timeplayer;
    }
    
    Player[] private players;
    
    mapping(address => uint) public balanceplayers;
    mapping(uint => uint) public indexcrossplayers;
    mapping(address => uint[]) public indexplayers;
    
    mapping(address => uint) public balancesponsors;
    
    uint public totaltickets;
    uint public balancepool;
    uint public balancepoolsponsors;
    
    uint public maxticketsperplayer;
    uint public maxticketspertransaction;
    
    mapping(address => uint256) public startTime;
    mapping(address => uint256) public balancerewards;
    mapping(address => uint256) public rewardscollected;

    uint public starttimepool;
    uint public balancerewardspool;
    uint public rewardscollectedpool;

    uint public yieldrate;
    uint public lotterypercentage;
    
    uint public closepool;


    event Stake(address indexed sender, uint amount);
    event Unstake(address indexed to, uint amount);
    event StakeSponsor(address indexed sender, uint amount);
    event UnstakeSponsor(address indexed to, uint amount);
    event CollectReserve(address indexed to, uint amount);
    event PayWinner(address indexed to, uint amount);
    event ChangeOwner(address indexed old, address indexed newer);
    event ChangePoolLock(address indexed sender, uint old, uint newer);
    event ChangeTicketsPerTransaction(address indexed sender, uint old, uint newer);
    event ChangeTicketsPerPlayer(address indexed sender, uint old, uint newer);
    event LotteryAwarded(uint counter, uint date, address indexed thewinner, uint amount, uint result);
    event TransferRewards(address indexed to, uint amount);
    event ChangeLotteryAge(address indexed sender, uint old, uint newer);
    event ChangeDepositsAge(address indexed sender, uint old, uint newer);
    event ChangeBurner(address indexed old, address indexed newer);
    event RedeemRewards(address indexed sender, uint amount);
    event ChangePercentageLottery(address indexed sender, uint old, uint newer);
    event EmergencyWithdraw(address indexed to, uint amount);
    
    
    constructor
    (address _owner, address _marketcream, address _underlying, uint _agedeposit, uint _agelottery, uint _ticketprice, uint _maxticketstransaction, uint _maxticketsplayers,
    uint _yield, string memory _nameerc20, string memory _symbolerc20)
    ERC20(_nameerc20, _symbolerc20) {
        
        marketcream = CreamYield(_marketcream);
        underlying = ERC20(_underlying);
        lockdeposits = 0;
        owner = _owner;
        spinning = false;
        picking = false;
        LOCK_PLAYERS = _agedeposit;
        LOCK_LOTTERY = _agelottery;
        TICKET_PRICE = _ticketprice;
        maxticketsperplayer = _maxticketsplayers;
        maxticketspertransaction = _maxticketstransaction;
        yieldrate = _yield;
        burner = _owner;
        lotterypercentage = 70;
    }


    // this modifier checks if msg.sender is the owner
    
    modifier onlyowner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }


    // this modifier checks if msg.sender is authorized to burn tokens

    modifier onlyBurner() {
        require(msg.sender == burner, "Caller is not the burner");
        _;
    }

    
    // this function modifies the address of the owner
    
    function transferowner(address _newowner) public onlyowner {
        require(msg.sender != EMPTY_ADDRESS);
        require(_newowner != EMPTY_ADDRESS, "New owner is the zero address");
        address oldowner = owner;
        owner = _newowner;
    
        emit ChangeOwner(oldowner, owner);
    }


    // this function modifies the address of the burner
        
    function transferburner(address _newburner) public onlyBurner {
        require(msg.sender != EMPTY_ADDRESS);
        require(_newburner != EMPTY_ADDRESS, "New burner is the zero address");
        address old = burner;
        burner = _newburner;
    
        emit ChangeBurner(old, burner);
    }


    // this function locks or unlocks functions BuyTickets() and RedeemTickets()
    // 1 = lock
    // 0 = unlock 

    function lockpool(uint _lockdeposits) public onlyowner {
        require(closepool == 0);
        require(_lockdeposits == 1 || _lockdeposits == 0, "Invalid lock parameter");
        uint old = lockdeposits;
        lockdeposits = _lockdeposits;
    
        emit ChangePoolLock(owner, old, lockdeposits);
    }
    

    // this function changes maximum tickets allowed to buy or redeem per transaction

    function changemaxticketspertransaction(uint _maxticketstransaction) public onlyowner {
        require(_maxticketstransaction > 0, "Must be greater than zero");
        uint old = maxticketspertransaction;
        maxticketspertransaction = _maxticketstransaction;
    
        emit ChangeTicketsPerTransaction(owner, old, maxticketspertransaction);
    }
    
    
    // this function changes maximum tickets allowed to buy per player
    
    function changemaxticketsperplayer(uint _maxticketsplayer) public onlyowner {
        require(_maxticketsplayer > 0, "Must be greater than zero");
        uint old = maxticketsperplayer;
        maxticketsperplayer = _maxticketsplayer;
    
        emit ChangeTicketsPerPlayer(owner, old, maxticketsperplayer);
    }
    
    
    // this function changes the epoch of each lottery drawn
    
    function changeagelottery(uint _agelottery) public onlyowner {
        require(spinning == false, "Lottery is being drawn");
        require(_agelottery > 0, "Must be greater than zero");
        uint old = LOCK_LOTTERY;
        LOCK_LOTTERY = _agelottery;
    
        emit ChangeLotteryAge(owner, old, LOCK_LOTTERY);
    }
    
    
    // this function changes the age a deposit needs to participate in the lottery
    
    function changeagedeposits(uint _agedeposits) public onlyowner {
        require(spinning == false, "Lottery is being drawn");
        require(_agedeposits > 0, "Must be greater than zero");
        uint old = LOCK_PLAYERS;
        LOCK_PLAYERS = _agedeposits;
    
        emit ChangeDepositsAge(owner, old, LOCK_PLAYERS);
    }
    
    
    // this function changes the percentage of the yield is split for lottery prizes
    
    function changelotterypercentage(uint _newpercentage) public onlyowner {
        require(_newpercentage >= 50 && _newpercentage <=100, "Percentage is not correct");
        splityield();
        uint old = lotterypercentage;
        lotterypercentage = _newpercentage;
    
        emit ChangePercentageLottery(owner, old, lotterypercentage);
    }
    
    
    // this function is used to deposit underlying token to buy lottery tickets and transfers it to yield source

    function BuyTickets(uint _tickets) external nonReentrant {
        require(spinning == false, "Lottery is being drawn");
        require(lockdeposits == 0, "Deposits are suspended");
        require(msg.sender != EMPTY_ADDRESS);
        
        require((_tickets + indexplayers[msg.sender].length) <= maxticketsperplayer, "Exceeds  tickets per player");
        require(_tickets > 0 && _tickets <= maxticketspertransaction, "Exceeds tickets per transaction");
        
        uint amount = (TICKET_PRICE * (_tickets * 10 ** 18)) / 10 ** 18;
        
        require(amount <= underlying.balanceOf(msg.sender), "Not enough amount");
        require(underlying.allowance(msg.sender, address(this)) >= amount, "Allowance is less than spending");
        
        require(underlying.transferFrom(msg.sender, address(this), amount) == true, "Something went wrong");
        
        uint end = block.timestamp;
        
        if (balancepool == 0) {
            starttimepool = end;
        }

        if (balanceplayers[msg.sender] == 0) {
            totalplayers += 1;
            startTime[msg.sender] = end;
        }

        if (balancepool > 0) {
            uint256 rewardsaccruedpool = calculateYieldTotalPool(end);
            starttimepool = end;
            balancerewardspool += rewardsaccruedpool;
        }

        if (balanceplayers[msg.sender] > 0) {
            
            uint256 rewardsaccrued = calculateYieldTotal(msg.sender, end);
            startTime[msg.sender] = end;
            balancerewards[msg.sender] += rewardsaccrued;
        }

        for (uint i = 0; i < _tickets; i++) {
        players.push(Player(msg.sender, block.timestamp));    
        uint index = players.length - 1;
        indexplayers[msg.sender].push(index);
        uint indexcross =  indexplayers[msg.sender].length - 1;
        indexcrossplayers[index] = indexcross;
        }
        
        totaltickets += _tickets;
        
        if (totaltickets > 0 && timejackpot == 0 && spinning == false) {
            timejackpot = block.timestamp;
        }
        
        require(underlying.approve(address(marketcream), amount) == true);
        
        balancepool += amount;
        balanceplayers[msg.sender] += amount; 
        
        uint checkamount = (TICKET_PRICE * (indexplayers[msg.sender].length * 10 ** 18)) / 10 ** 18;
        assert(checkamount == balanceplayers[msg.sender]);
    
        uint checkamount1 = (TICKET_PRICE * (players.length * 10 ** 18)) / 10 ** 18;
        assert(checkamount1 == balancepool);
    
    
        require(marketcream.mint(amount) == 0);   
        
        emit Stake(msg.sender, amount);
    }
    
    
    // this function is used to deposit underlying token to sponsor the lottery without lottery participation and transfers it to yield source
  
    function DepositSponsor(uint _amount) external nonReentrant {
        require(lockdeposits == 0, "Deposits are suspended");
        require(msg.sender != EMPTY_ADDRESS);
        require(_amount > 0 && underlying.balanceOf(msg.sender) >= _amount, "Amount cannot be 0");
        require(underlying.allowance(msg.sender, address(this)) >= _amount, "Allowance is less than spending");
        
        require(underlying.transferFrom(msg.sender, address(this), _amount) == true, "Something went wrong");
        
        require(underlying.approve(address(marketcream), _amount) == true);
        
        balancesponsors[msg.sender] += _amount;
        balancepoolsponsors += _amount;
        
        require(marketcream.mint(_amount) == 0);   
        
        emit StakeSponsor(msg.sender, _amount);
    }
    
    
    // this function is used to withdraw the principal of the underlying token from yield source by redeeming lottery tickets and transfers it to the player
    
    function RedeemTickets(uint _tickets) external nonReentrant {
        require(closepool == 0);
        require(spinning == false, "Lottery is being drawn");
        require(msg.sender != EMPTY_ADDRESS);
        require(_tickets > 0 && _tickets <= maxticketspertransaction, "Exceeds tickets per transaction");
        
        uint amount = (TICKET_PRICE * (_tickets * 10 ** 18)) / 10 ** 18;
        
        require(amount <= balanceplayers[msg.sender], "Not enough balance");
        require(marketcream.getCash() >= amount, "Not enough market liquidity");
        
        require(marketcream.redeemUnderlying(amount) == 0, "something went wrong");

        uint end = block.timestamp;
        uint256 rewardsaccrued = calculateYieldTotal(msg.sender, end);
        startTime[msg.sender] = end;
        balancerewards[msg.sender] += rewardsaccrued;
        
        uint256 rewardsaccruedpool = calculateYieldTotalPool(end);
        starttimepool = end;
        balancerewardspool += rewardsaccruedpool;

        balancepool -= amount;
        balanceplayers[msg.sender] -= amount; 
        totaltickets -= _tickets;
        
        if (balanceplayers[msg.sender] == 0) {
            totalplayers -= 1;
        }

        for (uint i = 0; i < _tickets; i++) {
            
        uint indextowithdraw = indexplayers[msg.sender].length - 1;
        uint indextoremove = indexplayers[msg.sender][indextowithdraw];
        indexplayers[msg.sender].pop();
    
        uint indexmove = players.length - 1;
        address addressmove = players[indexmove].addressplayer;
        uint timemove = players[indexmove].timeplayer;
        
            if (indexmove ==  indextoremove) {
                players.pop();
                delete indexcrossplayers[indexmove];
        
            } else { 

            players[indextoremove] = Player(addressmove, timemove);
            players.pop();
        
        
            uint indextoreplace = indexcrossplayers[indexmove];
            indexplayers[addressmove][indextoreplace] = indextoremove;
            indexcrossplayers[indextoremove] = indextoreplace;
        
            delete indexcrossplayers[indexmove];
            }
        }

        if (totaltickets == 0) {
            timejackpot = 0;
            spinning = false;
            picking = false;
            jackpotsettled = 0;
        }    
        
        uint checkamount = (TICKET_PRICE * (indexplayers[msg.sender].length * 10 ** 18)) / 10 ** 18;
        assert(checkamount == balanceplayers[msg.sender]);

        uint checkamount1 = (TICKET_PRICE * (players.length * 10 ** 18)) / 10 ** 18;
        assert(checkamount1 == balancepool);

        require(underlying.transfer(msg.sender, amount) == true, "Something went wrong");
    
        emit Unstake(msg.sender, amount);
    }


    // this function splits the yield between lottery prize and reserves
    
    function splityield() internal {
        uint interest = interestaccrued();
        
        uint jackpotinterest = interest * (lotterypercentage * 10 ** 18 / 100);
        jackpotinterest = jackpotinterest / 10 ** 18;
        jackpotvalue += jackpotinterest;
        
        uint reserveinterest = interest - jackpotinterest;
        reservevalue += reserveinterest;
        
        assert(interest == (jackpotinterest + reserveinterest));
        assert(marketcream.balanceOfUnderlying(address(this)) >= (jackpotvalue + reservevalue + balancepool + balancepoolsponsors));
    }


    // this function is used to calculate the interest accrued in yield source
    
    function interestaccrued() internal returns (uint) {
        uint interest = (marketcream.balanceOfUnderlying(address(this)) - balancepool - balancepoolsponsors - reservevalue - jackpotvalue); 
        return interest;
    }


    // this function is used to seed and settle the lottery prize to enable the pick a winner function 
    
    function settlejackpot() external nonReentrant {
        
        require(spinning == false);
        require(totaltickets > 0);
        require(timejackpot > 0);
        require(block.number - blockNumber > 0);
        
        uint end = block.timestamp;
        uint totaltime = end - timejackpot;
        require(totaltime >= LOCK_LOTTERY);

        spinning = true;
        timejackpot = 0;
        blockNumber = block.number;

        splityield();
    
        require(jackpotvalue > 0, "No interest accrued");
        
        jackpotsettled = jackpotvalue;
        
        nonce += 1;
        picking = true;
    }
    
    
    // this function generates a random number using future Blockhash
    
    function generaterandomnumber() internal view returns (uint) {
        uint randnum = uint(keccak256(abi.encode(blockhash(blockNumber), nonce))) % players.length;
        return randnum;  
    }


    // this function is used to pick the lottery winner, redeem underlying token from yield source and transfer it to the winner
    
    function pickawinner() external nonReentrant {
        
        require(spinning == true);
        require(picking == true);
        picking = false;
        require(block.number - blockNumber > 0);
        uint toredeem = jackpotsettled;
        require(marketcream.getCash() >= toredeem, "Not enough market liquidity");  
        require(totaltickets > 0);
        
        uint totransferbeneficiary = jackpotsettled;
        
        jackpotsettled = 0;
        
        lotterycounter++;
        uint end = block.timestamp;
        
        if (block.number - blockNumber > 250) {
    
            lastjackpotresult = 2;
            
            LotteryResults.push(Lottery(lotterycounter, end, 2, EMPTY_ADDRESS, 0));

            emit LotteryAwarded(lotterycounter, end, EMPTY_ADDRESS, 0, 2);
        
        } else {
        
        uint w = 0;
        uint winner = 0;
        address beneficiary;
        
        uint randomnumber;
        
        while(w < players.length && winner < 1 ) {
        
            w++;
        
            randomnumber = generaterandomnumber();
        
            address candidate = players[randomnumber].addressplayer;
            
            uint totaltime = end - players[randomnumber].timeplayer;
                if (totaltime >= LOCK_PLAYERS) {
                    winner = 1;
                    beneficiary = candidate;
                }
            
            nonce++; 
        }        

        if (winner == 1) {
            
            jackpotspaid += totransferbeneficiary;
            
            require(marketcream.redeemUnderlying(toredeem) == 0, "Something went wrong");
            jackpotvalue -= toredeem;
            
            require(underlying.transfer(beneficiary, totransferbeneficiary) == true, "Something went wrong");
        
            lastjackpotresult = 1;
            lastjackpotwinner = beneficiary;
            lastjackpotamount = totransferbeneficiary;
            lastjackpotdate = end;
            lastjackpotcounter = lotterycounter;
        
            LotteryResults.push(Lottery(lotterycounter, end, 1, beneficiary, totransferbeneficiary));
        
            emit PayWinner(beneficiary, totransferbeneficiary);
            
            emit LotteryAwarded(lotterycounter, end, beneficiary, totransferbeneficiary, 1);
            
        } else {
        
            lastjackpotresult = 2;
            
            LotteryResults.push(Lottery(lotterycounter, end, 2, EMPTY_ADDRESS, 0));
            
            emit LotteryAwarded(lotterycounter, end, EMPTY_ADDRESS, 0, 2);
        }    
          
        }
          
        timejackpot = block.timestamp;
        spinning = false;
    }
        
    
    // this function returns the timeleft to draw the lottery

    function calculatetimeleft() public view returns (uint) {
        uint end = block.timestamp;
        uint totaltime = end - timejackpot;
        
        if(totaltime < LOCK_LOTTERY) {
            uint timeleft = LOCK_LOTTERY - totaltime;
            return timeleft;
        } else {
            return 0;
        }
    }
    
    
    // this function returns if conditions are met to execute function settlejackpot()
    // 1 = met
    // 2 = not met 
    
    function calculatesettlejackpot() public view returns (uint) {
        
        uint end = block.timestamp;
        uint totaltime = end - timejackpot;

        if (spinning == false && totaltickets > 0 && timejackpot > 0 && (block.number - blockNumber) > 0 && totaltime >= LOCK_LOTTERY) {
            return 1;
    
        } else {
            return 2;
        }    
    }        
            
    
    // this function returns if conditions are met to execute function pickawinner()
    // 1 = met
    // 2 = not met
        
    function calculatepickawinner() public view returns (uint) {
        
        uint toredeem = jackpotsettled;
        uint metwinner;
        
            
            if (spinning == true && block.number - blockNumber > 0 && totaltickets > 0 && marketcream.getCash() >= toredeem) {
                metwinner = 1;
        
            } else {
                metwinner = 2;
            }
        
        
        return metwinner;
    }
    
    
    // this function returns if account is the owner
    // 1 is owner
    // 2 is not owner
    
    function verifyowner(address _account) public view returns (uint) {
        
        if (_account == owner) {
            return 1;
        } else {
            return 2;
        }
    }
    
  
    // this function returns an array of struct of jackpots drawn results
  
    function getLotteryResults() public view returns (Lottery[] memory) {
    return LotteryResults;
    }
  
    
    // this function is used to redeem underlying token from yield source and withdraw reserves     
    
    function WithdrawReserves(uint _amount) external nonReentrant onlyowner {
        
        splityield();
        
        require(_amount > 0, "Amount can not be zero");
        require(_amount <= reservevalue, "Not enough reserves accrued");
        
        require(marketcream.getCash() >= _amount, "Not enough market liquidity");  
        
        uint totransferinterestnet = _amount;
        totalreservepaid += _amount;
        
        require(marketcream.redeemUnderlying(totransferinterestnet) == 0, "Something went wrong");
        reservevalue -= _amount;
        
        require(underlying.transfer(owner, totransferinterestnet) == true, "Something went wrong");
    
        if (closepool == 1) {
            reservevalue += jackpotvalue;
            jackpotvalue = 0;
        }
    
        emit CollectReserve(owner, totransferinterestnet);
    }
    
    
    // this function is used to redeem underlying token from yield source and withdraw the sponsorship
    
    function WithdrawSponsor(uint _amount) external nonReentrant {
        
        require(msg.sender != EMPTY_ADDRESS);
        require(_amount > 0 , "Amount cannot be zero");
        require(balancesponsors[msg.sender] >= _amount, "Not enough donations balance");
        require(marketcream.getCash() >= _amount, "Not enough market liquidity");  
        
        require(marketcream.redeemUnderlying(_amount) == 0, "Something went wrong");
        balancesponsors[msg.sender] -= _amount;
        balancepoolsponsors -= _amount;
        
        require(underlying.transfer(msg.sender, _amount) == true, "Something went wrong");

        emit UnstakeSponsor(msg.sender, _amount);
    }
    

    // this function returns yield generated. Parameter should be balance of underlying of yield source
    
    function calculateinterest(uint _amount) external view returns(uint, uint) {
        
        uint yield = (_amount - balancepool - balancepoolsponsors - reservevalue - jackpotvalue);
        
        uint jackpot = yield * (lotterypercentage * 10 ** 18 / 100);
        jackpot = jackpot / 10 ** 18;
        
        uint reserve = yield - jackpot;
        
        jackpot = jackpot + jackpotvalue - jackpotsettled;
        reserve = reserve + reservevalue;
        
        return (jackpot, reserve);
    }
    

    // this function returns data to the front end

    function calculatedata() external view returns (uint [] memory) {
        
        uint deposits = balancepool + balancepoolsponsors;
        uint liquidity = marketcream.getCash();
        uint lefttime = calculatetimeleft();
        uint metsettlejackpot = calculatesettlejackpot();
        uint metpickawinner =  calculatepickawinner();
        
        uint spinningstate;
        if (spinning == false) {
            spinningstate = 2;
        } 
        if (spinning == true) {
            spinningstate = 1;
        }
        
        uint end = block.timestamp;
        uint256 rewardsaccruedpool = calculateYieldTotalPool(end);
        
        uint[] memory datafront = new uint[](29);
        
        datafront[0] = deposits;
        datafront[1] = liquidity;
        datafront[2] = lefttime;
        datafront[3] = metsettlejackpot;
        datafront[4] = metpickawinner;
        
        datafront[5] = balancepool;
        datafront[6] = totalreservepaid;
        datafront[7] = balancepoolsponsors;
        datafront[8] = totalplayers;
        
        datafront[9] = lotterycounter;
        datafront[10] = jackpotsettled;
        datafront[11] = jackpotspaid;
        
        datafront[12] = lastjackpotamount;
        datafront[13] = spinningstate;
        datafront[14] = totaltickets;
        
        datafront[15] = lastjackpotresult;
        datafront[16] = lastjackpotdate;
        datafront[17] = lastjackpotcounter;
        
        datafront[18] = TICKET_PRICE;
        datafront[19] = LOCK_PLAYERS;
        datafront[20] = LOCK_LOTTERY;
        
        datafront[21] = maxticketsperplayer;
        datafront[22] = maxticketspertransaction;
        datafront[23] = lockdeposits;
        datafront[24] = yieldrate;
        datafront[25] = totalSupply();
    
        datafront[26] = rewardscollectedpool;
        datafront[27] = balancerewardspool + rewardsaccruedpool;
        
        datafront[28] = lotterypercentage;
        
        return (datafront);
    }

   
   // this function returns data to the front end
    
    function calculatedataaccount(address _account) external view returns (uint [] memory) {
        require(_account != EMPTY_ADDRESS);
        uint staked = balanceplayers[_account];
        uint balwallet = underlying.balanceOf(_account);
        uint allow = underlying.allowance(_account, address(this));
        uint balsponsors = balancesponsors[_account];
        uint isowner = verifyowner(_account);
        
        uint end = block.timestamp;
        uint256 rewardsaccrued = calculateYieldTotal(_account, end);
        
        uint[] memory datafrontaccount = new uint[](9);
        
        datafrontaccount[0] = staked;
        datafrontaccount[1] = balwallet;
        datafrontaccount[2] = allow;
        datafrontaccount[3] = indexplayers[_account].length;
        datafrontaccount[4] = balsponsors;
        datafrontaccount[5] = isowner;
        datafrontaccount[6] = balancerewards[_account] + rewardsaccrued;
        datafrontaccount[7] = balanceOf(_account);
        datafrontaccount[8] = rewardscollected[_account];
        
        return (datafrontaccount);
    }


    // this function is used by the front end to check buy tickets conditions

    function checkbuytickets(uint _tickets, address _account) external view returns (uint) {
        require(_account != EMPTY_ADDRESS);
        require(_tickets > 0);
        
        uint result = 0;
        uint amount = ((_tickets * 10 ** 18) * TICKET_PRICE) / 10 ** 18;
        
        if (lockdeposits == 1) {
            result = 1;
        } else {
            if (spinning == true) {
                result = 2;
            } else {
                if ((_tickets + indexplayers[_account].length) > maxticketsperplayer) {
                    result = 3;
                } else {
                    if (_tickets > maxticketspertransaction) {
                        result = 4;
                    } else {
                        if (amount > underlying.balanceOf(_account)) {
                            result = 5;
                        } else {
                            if (amount > underlying.allowance(_account, address(this))) {
                                result = 6;
                            }    
                        }
                    }
                }                        
            }   
        }
        
        return result;
    }
    
    
    // this function is used in the front end to check sponsor deposits conditions
    
    function checkdepositsponsor(uint _amount, address _account) external view returns (uint) {
        require(_account != EMPTY_ADDRESS);
        require(_amount > 0);
        
        uint result = 0;
        
        if (lockdeposits == 1) {
            result = 1;
        } else {
            if (_amount > underlying.balanceOf(_account)) {
                result = 2;
            } else {
                if (_amount > underlying.allowance(_account, address(this))) {
                    result = 3;
                }    
            }                        
        }   

        return result;
    }
    
    
    // this function is used in the front end to check redeem tickets conditions
    
    function checkredeemtickets(uint _tickets, address _account) external view returns (uint) {
        require(_account != EMPTY_ADDRESS);
        require(_tickets > 0);
        
        uint result = 0;
        uint amount = ((_tickets * 10 ** 18) * TICKET_PRICE) / 10 ** 18;
        
        if (spinning == true) {
            result = 1;
        } else {
            if (_tickets > indexplayers[_account].length || amount > balanceplayers[_account]) {
                result = 2;
            } else {
                if (_tickets > maxticketspertransaction) {
                    result = 3;
                } else {
                    if (amount > marketcream.getCash()) {
                        result  = 4;
                    }
                }   
            }                        
        }   

        return result;
    }
    
    
    // this function is used in the front end to check sponsor withdraw conditions
    
    function checkwithdrawsponsor(uint _amount, address _account) external view returns (uint) {
        require(_account != EMPTY_ADDRESS);
        require(_amount > 0);
        
        uint result = 0;
        
        if (_amount > balancesponsors[_account]) {
            result = 1;
        } else {
            if (_amount > marketcream.getCash()) {
                result = 2;
            } 
        }   

        return result;
    }
    

    // this function is used in the front end to check reserves withdraw conditions

    function checkwithdrawreserves(uint _amount1, uint _amount2, address _account) external view returns (uint) {
        require(_account != EMPTY_ADDRESS);
        require(_amount1 > 0);
    
        uint result = 0;
    
        if (_account != owner) {
            result = 1;
        } else {
            if (_amount1 > _amount2) {
                result = 2;
            } else {
                if (_amount1 > marketcream.getCash()) {
                    result = 3;
                }
            } 
        }
        
        return result;
    }


    // this function is used in the front end to check rewards withdraw conditions

    function checkwithdrawrewards(address _account) external view returns (uint) {
        require(_account != EMPTY_ADDRESS);
        uint end = block.timestamp;
        uint256 rewardsaccrued = calculateYieldTotal(_account, end);
        
        uint result = 0;
    
        if (rewardsaccrued + balancerewards[_account] == 0) {
            result = 1;
        } 
        
        return result;
    }


    // this function is used to calculate players rewards

    function calculateYieldTotal(address user, uint _end) internal view returns(uint256) {
        uint256 time = calculateYieldTime(user, _end) * 10 ** 18;
        uint256 rate = yieldrate;
        uint256 timeRate = time / rate;
        uint256 rawYield = (balanceplayers[user] * timeRate) / 10 ** 18;
        return rawYield;
    }     
    
    
    // this function is used to calculate the time elapsed of players deposits to calculate rewards
    
    function calculateYieldTime(address user, uint _end) internal view returns(uint256){
        uint256 end = _end;
        uint256 totalTime = end - startTime[user];
        return totalTime;
    }    
    
    
    // this function is used to calculate total pool rewards
    
    function calculateYieldTotalPool(uint _end) internal view returns(uint256) {
        uint256 time = calculateYieldTimePool(_end) * 10 ** 18;
        uint256 rate = yieldrate;
        uint256 timeRate = time / rate;
        uint256 rawYield = (balancepool * timeRate) / 10 ** 18;
        return rawYield;
    }
    
    
    // this function is used to calculate the time elapsed of deposits to calculate pool rewards
    
    function calculateYieldTimePool(uint _end) internal view returns(uint256){
        uint256 end = _end;
        uint256 totalTime = end - starttimepool;
        return totalTime;
    }
    
    
    // this function is used to mint rewards token
    
    function WithdrawRewards() external nonReentrant {
        require(msg.sender != EMPTY_ADDRESS);
        uint end = block.timestamp;
        uint256 rewardsaccrued = calculateYieldTotal(msg.sender, end);
        
        require(rewardsaccrued + balancerewards[msg.sender] > 0, "No rewards accrued");
        
        uint256 rewardsaccruedpool = calculateYieldTotalPool(end);
        starttimepool = end;
        startTime[msg.sender] = end;
        
        uint totransfer = balancerewards[msg.sender] + rewardsaccrued;
        balancerewards[msg.sender] = 0;
        rewardscollected[msg.sender] += totransfer; 
        balancerewardspool = balancerewardspool + rewardsaccruedpool - totransfer;
        rewardscollectedpool += totransfer; 
        
        _mint(msg.sender, totransfer);
        
        emit TransferRewards(msg.sender, totransfer);
        
    }
 
 
    // this function is used to burn rewards token
    
    function BurnRewards(uint _amount) external onlyBurner {
        require(_amount > 0, "amount cannot be 0");
        _burn(msg.sender, _amount);
        
        emit RedeemRewards(msg.sender, _amount);
    }


    // this function should be used in the extreme case the correlation tickets * price is not equal to balance
    // Pool will be closed.

    function EmergencyWithdrawDepositors() external nonReentrant {
        require(msg.sender != EMPTY_ADDRESS);
        
        uint tickets = indexplayers[msg.sender].length;
        uint amount = (TICKET_PRICE * (tickets * 10 ** 18)) / 10 ** 18;
        
        if (closepool == 0) {
        require(amount != balanceplayers[msg.sender]);
        }
        
        uint totransfer = balanceplayers[msg.sender];
        balanceplayers[msg.sender] = 0;
        balancepool -= totransfer;
        lockdeposits = 1;
        closepool = 1;
        timejackpot = 0;
        spinning = false;
        picking = false;
        jackpotsettled = 0;
        lotterypercentage = 0;
        
        require(marketcream.getCash() >= totransfer, "Not enough market liquidity");
        require(marketcream.redeemUnderlying(totransfer) == 0, "something went wrong");
        require(underlying.transfer(msg.sender, totransfer) == true, "Something went wrong");
    
        emit EmergencyWithdraw(msg.sender, totransfer);
    }

}